#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HELPER=$ROOT/shared/skills/reboot-recovery/scripts/recover-mac-after-reboot
REMOTE=$ROOT/shared/skills/reboot-recovery/scripts/mac-reboot-state
SKILL=$ROOT/shared/skills/reboot-recovery/SKILL.md
REFERENCES=$ROOT/shared/skills/reboot-recovery/references
STATUS_REFERENCE=$REFERENCES/status-discovery.md
RECOVERY_REFERENCE=$REFERENCES/recovery-start.md
VALIDATION_REFERENCE=$REFERENCES/validation-closeout.md
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

words() {
    wc -w <"$1" | tr -d ' '
}

assert_max() {
    [ "$1" -le "$2" ] || fail "$3 word budget exceeded: $1 > $2"
}

sh -n "$HELPER" || fail "controller helper syntax"
sh -n "$REMOTE" || fail "remote helper syntax"

grep -Fx 'name: reboot-recovery' "$SKILL" >/dev/null ||
    fail "skill name"

for reference in \
    "$STATUS_REFERENCE" \
    "$RECOVERY_REFERENCE" \
    "$VALIDATION_REFERENCE"; do
    [ -f "$reference" ] && [ ! -L "$reference" ] ||
        fail "missing regular phase reference: $reference"
done

for route in status-discovery recovery-start validation-closeout; do
    [ "$(grep -Fc "[$route.md](references/$route.md)" "$SKILL")" -eq 1 ] ||
        fail "$route route is not uniquely reachable"
done

if grep -E '\]\([^)]*[.]md\)' \
    "$STATUS_REFERENCE" "$RECOVERY_REFERENCE" "$VALIDATION_REFERENCE" \
    >/dev/null; then
    fail "phase reference selects another reference"
fi

# These gates must trigger from the mandatory router even when all references
# remain unloaded.
assert_contains "$SKILL" \
    "Set \`HOST\` only to \`aist\`, \`home\`, \`office\`, or \`riken\`" \
    "router host boundary"
assert_contains "$SKILL" \
    'Never inspect, expose, copy, hash, generate, or modify credentials' \
    "router credential boundary"
assert_contains "$SKILL" \
    'Never read or capture tmux pane or transcript contents.' \
    "router tmux privacy boundary"
assert_contains "$SKILL" 'Dirty, divergent, or non-current Git state' \
    "router dirty/divergent refusal"
assert_contains "$SKILL" 'an unavailable route pair' \
    "router route-pair refusal"
assert_contains "$SKILL" 'missing managed services' \
    "router service refusal"
assert_contains "$SKILL" 'Conflicting tmux state' \
    "router tmux-conflict refusal"
assert_contains "$SKILL" \
    "remove, ignore, or specially classify \`.DS_Store\`" \
    "router repository cleanup boundary"
assert_contains "$SKILL" \
    'A failed query is unknown state, not evidence of absence or readiness.' \
    "router unknown-state boundary"

assert_contains "$STATUS_REFERENCE" 'remote-control start' \
    "owner remote-control step"
assert_contains "$STATUS_REFERENCE" 'Existing pairing normally persists' \
    "pairing persistence"
assert_contains "$STATUS_REFERENCE" 'ask the owner to log into the Mac locally' \
    "owner local-login checkpoint"
assert_contains "$STATUS_REFERENCE" \
    'Do not recover through another identity.' \
    "unrelated identity refusal"
assert_contains "$STATUS_REFERENCE" \
    'guarded fleet sync only for a clean managed checkout.' \
    "clean fleet-sync boundary"

assert_contains "$RECOVERY_REFERENCE" \
    "both routes, clean/current \`main\`, both tunnel" \
    "start readiness gate"
assert_contains "$RECOVERY_REFERENCE" \
    'codex-resilient --run' \
    "resilient tmux command"
assert_contains "$RECOVERY_REFERENCE" \
    'never reconstructs or replays a prompt' \
    "prompt replay prohibition"

assert_contains "$VALIDATION_REFERENCE" \
    'Require both aliases to pass fresh independent probes.' \
    "fresh route validation"
assert_contains "$VALIDATION_REFERENCE" \
    'exactly one detached, live' \
    "exact tmux session topology"
assert_contains "$VALIDATION_REFERENCE" \
    "with one Codex pane rooted at \`~/harness\`" \
    "exact pane topology"
assert_contains "$VALIDATION_REFERENCE" \
    'require the live value-free supervisor receipt to match the tmux pane owner' \
    "supervisor receipt gate"
assert_contains "$VALIDATION_REFERENCE" \
    'Keep arg0 housekeeping separate from reboot recovery.' \
    "arg0 separation"
assert_contains "$VALIDATION_REFERENCE" \
    "fresh compact \`harness fleet-health\` check" \
    "fresh fleet-health closeout"

if grep -E '(rm|unlink).*[.]DS_Store|[.]DS_Store.*(rm|unlink)' \
    "$SKILL" "$STATUS_REFERENCE" "$RECOVERY_REFERENCE" \
    "$VALIDATION_REFERENCE" "$HELPER" "$REMOTE" >/dev/null; then
    fail "recovery contains DS_Store removal"
fi

BASELINE_AGGREGATE=599
BASELINE_LARGEST_ROUTE=599
entry_words=$(words "$SKILL")
status_words=$(words "$STATUS_REFERENCE")
recovery_words=$(words "$RECOVERY_REFERENCE")
validation_words=$(words "$VALIDATION_REFERENCE")
aggregate_words=$((entry_words + status_words + recovery_words +
    validation_words))
largest_reference=$status_words
[ "$recovery_words" -le "$largest_reference" ] ||
    largest_reference=$recovery_words
[ "$validation_words" -le "$largest_reference" ] ||
    largest_reference=$validation_words
largest_route=$((entry_words + largest_reference))
route_reduction=$(((BASELINE_LARGEST_ROUTE - largest_route) * 100 /
    BASELINE_LARGEST_ROUTE))

assert_max "$entry_words" 275 "router"
assert_max "$status_words" 160 "status/discovery reference"
assert_max "$recovery_words" 130 "recovery/start reference"
assert_max "$validation_words" 140 "validation/closeout reference"
assert_max "$aggregate_words" 675 "aggregate"
assert_max "$largest_route" 425 "largest selected route"
[ "$route_reduction" -ge 25 ] ||
    fail "largest selected route reduction is not material: $route_reduction%"

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
mkdir -p "$fake_bin" "$fake_home/harness/.git" \
    "$fake_home/harness/bin" "$fake_home/.local/bin" "$state"

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
        if [ "${FAKE_TMUX_STATE:-absent}" = supervisor ]; then
            echo "0|$HOME/harness|sleep|4242"
        else
            echo "0|$HOME/harness|codex|4242"
        fi
        ;;
    new-session)
        printf '%s\n' "$*" >"$FAKE_STATE/new-session.args"
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
cat >"$fake_home/harness/bin/harness" <<'SH'
#!/bin/sh
if [ "${FAKE_TMUX_STATE:-absent}" = supervisor ]; then
    echo 'CODEX_RESILIENT mode=status name=harness-codex-resume phase=backoff selector=last owner_pid=4242 attempt=2 delay=30 reason=transient-exit'
else
    echo 'CODEX_RESILIENT mode=status name=harness-codex-resume phase=absent'
fi
SH
chmod 755 "$fake_bin"/* "$fake_home/.local/bin/harness-codex" \
    "$fake_home/harness/bin/harness"

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
assert_contains "$state/new-session.args" \
    'codex-resilient --run --name harness-codex-resume --last' \
    "resilient tmux command"

HOME="$fake_home" FAKE_STATE="$state" \
    "$TEST_ROOT/mac-reboot-state" start-tmux >"$TEST_ROOT/keep.out"
assert_contains "$TEST_ROOT/keep.out" \
    'action=keep status=complete' "idempotent tmux retention"

HOME="$fake_home" FAKE_STATE="$state" FAKE_TMUX_STATE=supervisor \
    "$TEST_ROOT/mac-reboot-state" status >"$TEST_ROOT/supervisor.out"
assert_contains "$TEST_ROOT/supervisor.out" \
    'tmux=ready status=ready' "supervisor backoff readiness"

printf '%s\n' \
    "Reboot recovery skill tests passed: aggregate $BASELINE_AGGREGATE->$aggregate_words words; largest selected route $BASELINE_LARGEST_ROUTE->$largest_route words (-$route_reduction%)"
