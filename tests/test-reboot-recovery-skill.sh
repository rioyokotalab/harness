#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HELPER=$ROOT/shared/skills/reboot-recovery/scripts/recover-mac-after-reboot
REMOTE=$ROOT/shared/skills/reboot-recovery/scripts/mac-reboot-state
SKILL=$ROOT/shared/skills/reboot-recovery/SKILL.md
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/reboot-recovery-test.XXXXXX")

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEST_ROOT" ]; then
        "$CLEANUP" "$HARNESS" "$TEMP_BASE" "$TEST_ROOT" \
            "$TEMP_BASE" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then
        echo "FAIL: guarded reboot-recovery test cleanup" >&2
        status=1
    fi
    exit "$status"
}

trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

assert_contains() {
    grep -F "$2" "$1" >/dev/null || fail "$3"
}

sh -n "$HELPER" || fail "controller helper syntax"
sh -n "$REMOTE" || fail "remote helper syntax"

grep -Fx 'name: reboot-recovery' "$SKILL" >/dev/null ||
    fail "skill name"
grep -F 'remote-control start' "$SKILL" >/dev/null ||
    fail "owner remote-control step"
grep -F 'Existing pairing normally persists' "$SKILL" >/dev/null ||
    fail "pairing persistence"
if ! grep -F 'Never remove, ignore, or specially classify' "$SKILL" >/dev/null ||
    ! grep -F '.DS_Store' "$SKILL" >/dev/null ||
    ! grep -F 'any dirty checkout is a blocker' "$SKILL" >/dev/null; then
    fail "repository cleanup boundary"
fi
if grep -E '(rm|unlink).*[.]DS_Store|[.]DS_Store.*(rm|unlink)' \
    "$SKILL" "$HELPER" "$REMOTE" >/dev/null; then
    fail "recovery contains DS_Store removal"
fi
grep -F 'Never read or capture tmux pane contents.' "$SKILL" >/dev/null ||
    fail "tmux privacy boundary"

fake_ssh=$TEST_ROOT/fake-ssh
cat >"$fake_ssh" <<'SH'
#!/bin/sh
set -eu
alias=
is_probe=no
last=
for argument do
    last=$argument
    case $argument in
        aist|aist2|home|home2|office|office2|riken|riken2)
            alias=$argument
            ;;
        /usr/bin/true)
            is_probe=yes
            ;;
    esac
done

if [ "$is_probe" = yes ]; then
    case ",${FAKE_DOWN:-}," in
        *",$alias,"*) exit 255 ;;
    esac
    exit 0
fi

cat >/dev/null
printf '%s\n' "${FAKE_REMOTE_OUTPUT:-MAC_REBOOT_STATE mode=status status=ready}"
exit "${FAKE_REMOTE_EXIT:-0}"
SH
chmod 755 "$fake_ssh"

if REBOOT_RECOVERY_SSH_BIN="$fake_ssh" "$HELPER" --host local --status \
    >"$TEST_ROOT/invalid.out" 2>&1; then
    fail "unsupported host accepted"
fi

if FAKE_DOWN=aist,aist2 REBOOT_RECOVERY_SSH_BIN="$fake_ssh" \
    "$HELPER" --host aist --status >"$TEST_ROOT/down.out" 2>&1; then
    fail "complete route loss accepted"
fi
assert_contains "$TEST_ROOT/down.out" \
    'routes=0/2 status=needs-owner action=restore-routes' \
    "route-loss owner handoff"

if FAKE_DOWN=aist2 REBOOT_RECOVERY_SSH_BIN="$fake_ssh" \
    "$HELPER" --host aist --start-tmux >"$TEST_ROOT/one-route.out" 2>&1; then
    fail "tmux start accepted one route"
fi
assert_contains "$TEST_ROOT/one-route.out" \
    'status=blocked reason=route-redundancy' \
    "one-route start refusal"

FAKE_REMOTE_OUTPUT='MAC_REBOOT_STATE mode=status tmux=absent status=needs-tmux' \
    REBOOT_RECOVERY_SSH_BIN="$fake_ssh" \
    "$HELPER" --host home --status >"$TEST_ROOT/status.out"
assert_contains "$TEST_ROOT/status.out" \
    'REBOOT_RECOVERY host=home routes=2/2 source=home' \
    "independent route count"
assert_contains "$TEST_ROOT/status.out" 'status=needs-tmux' \
    "remote status forwarding"

fake_bin=$TEST_ROOT/fake-bin
fake_home=$TEST_ROOT/home
state=$TEST_ROOT/state
mkdir -p "$fake_bin" "$fake_home/harness/.git" "$fake_home/.local/bin" "$state"

cat >"$fake_bin/uname" <<'SH'
#!/bin/sh
echo Darwin
SH
cat >"$fake_bin/id" <<'SH'
#!/bin/sh
[ "${1:-}" = -u ] && echo 502
SH
cat >"$fake_bin/git" <<'SH'
#!/bin/sh
case $1 in
    symbolic-ref)
        echo "${FAKE_BRANCH:-main}"
        ;;
    rev-parse)
        case $* in
            *refs/remotes/origin/main*) echo "${FAKE_UPSTREAM:-abc}" ;;
            *) echo abc ;;
        esac
        ;;
    status)
        [ "${FAKE_DIRTY:-no}" = yes ] && echo '?? unreported-path'
        ;;
    *)
        exit 2
        ;;
esac
SH
cat >"$fake_bin/launchctl" <<'SH'
#!/bin/sh
case $* in
    *"${FAKE_MISSING_LABEL:-never-match}"*) exit 1 ;;
esac
exit 0
SH
cat >"$fake_bin/ps" <<'SH'
#!/bin/sh
echo '1 /managed/codex.real'
[ "${FAKE_REMOTE_CONTROL_COUNT:-2}" -eq 2 ] &&
    echo '1 /managed/codex.real'
SH
cat >"$fake_bin/tmux" <<'SH'
#!/bin/sh
set -eu
command=$1
shift
case $command in
    list-sessions)
        if [ -f "$FAKE_STATE/created" ] ||
            [ "${FAKE_TMUX_STATE:-absent}" = ready ]; then
            echo 'harness-codex-resume|0'
        elif [ "${FAKE_TMUX_STATE:-absent}" = conflict ]; then
            echo 'harness-codex-resume|1'
        else
            exit 1
        fi
        ;;
    list-panes)
        echo "0|$HOME/harness|codex"
        ;;
    new-session)
        : >"$FAKE_STATE/created"
        ;;
    *)
        exit 2
        ;;
esac
SH
cat >"$fake_bin/sleep" <<'SH'
#!/bin/sh
exit 0
SH
cat >"$fake_home/.local/bin/harness-codex" <<'SH'
#!/bin/sh
exit 0
SH
chmod 755 "$fake_bin"/* "$fake_home/.local/bin/harness-codex"

# Replace only the helper's fixed production PATH in this disposable copy so
# each state transition can be exercised without macOS or live services.
sed "s|^PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin$|PATH=$fake_bin:/usr/bin:/bin|" \
    "$REMOTE" >"$TEST_ROOT/mac-reboot-state"
chmod 755 "$TEST_ROOT/mac-reboot-state"

HOME="$fake_home" FAKE_STATE="$state" \
    "$TEST_ROOT/mac-reboot-state" status >"$TEST_ROOT/needs-tmux.out"
assert_contains "$TEST_ROOT/needs-tmux.out" \
    'repo=clean branch=main synchronized=yes' "clean repository state"
assert_contains "$TEST_ROOT/needs-tmux.out" \
    'tmux=absent status=needs-tmux' "absent tmux classification"

if HOME="$fake_home" FAKE_STATE="$state" FAKE_DIRTY=yes \
    "$TEST_ROOT/mac-reboot-state" status >"$TEST_ROOT/dirty.out"; then
    fail "dirty repository accepted"
fi
assert_contains "$TEST_ROOT/dirty.out" 'repo=dirty' \
    "dirty repository blocks recovery"

if HOME="$fake_home" FAKE_STATE="$state" FAKE_UPSTREAM=def \
    "$TEST_ROOT/mac-reboot-state" start-tmux >"$TEST_ROOT/divergent.out"; then
    fail "divergent repository accepted"
fi
assert_contains "$TEST_ROOT/divergent.out" 'reason=repository-divergent' \
    "divergent repository refusal"

if HOME="$fake_home" FAKE_STATE="$state" \
    FAKE_MISSING_LABEL=org.rioyokota.harness.ssh.tunnel2 \
    "$TEST_ROOT/mac-reboot-state" start-tmux >"$TEST_ROOT/tunnel.out"; then
    fail "missing tunnel service accepted"
fi
assert_contains "$TEST_ROOT/tunnel.out" 'reason=tunnel-services' \
    "missing tunnel refusal"

if HOME="$fake_home" FAKE_STATE="$state" FAKE_REMOTE_CONTROL_COUNT=1 \
    "$TEST_ROOT/mac-reboot-state" start-tmux \
    >"$TEST_ROOT/remote-control.out"; then
    fail "unexpected remote-control topology accepted"
fi
assert_contains "$TEST_ROOT/remote-control.out" 'reason=remote-control' \
    "remote-control refusal"

if HOME="$fake_home" FAKE_STATE="$state" FAKE_TMUX_STATE=conflict \
    "$TEST_ROOT/mac-reboot-state" start-tmux >"$TEST_ROOT/conflict.out"; then
    fail "conflicting tmux accepted"
fi
assert_contains "$TEST_ROOT/conflict.out" 'reason=tmux-conflict' \
    "tmux conflict refusal"

HOME="$fake_home" FAKE_STATE="$state" \
    "$TEST_ROOT/mac-reboot-state" start-tmux >"$TEST_ROOT/create.out"
assert_contains "$TEST_ROOT/create.out" \
    'action=create status=complete' "tmux creation"
[ -f "$state/created" ] || fail "tmux creation was not invoked"

HOME="$fake_home" FAKE_STATE="$state" \
    "$TEST_ROOT/mac-reboot-state" start-tmux >"$TEST_ROOT/keep.out"
assert_contains "$TEST_ROOT/keep.out" \
    'action=keep status=complete' "idempotent tmux retention"

echo "Reboot recovery skill tests passed"
