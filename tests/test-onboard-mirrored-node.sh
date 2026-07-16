#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
PREFLIGHT=$ROOT/shared/skills/onboard-mirrored-node/scripts/onboard-preflight
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/onboard-test.XXXXXX")

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

expect_failure() {
    expected=$1
    output=$2
    shift 2
    if "$@" >"$output" 2>&1; then
        fail "command unexpectedly succeeded: $*"
    fi
    grep -F -- "$expected" "$output" >/dev/null ||
        fail "missing failure evidence '$expected': $*"
}

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEST_ROOT" ]; then
        "$CLEANUP" "$HARNESS" "${TMPDIR:-/tmp}" "$TEST_ROOT" \
            "${TMPDIR:-/tmp}" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then
        printf '%s\n' 'FAIL: guarded onboarding-test cleanup' >&2
        status=1
    fi
    exit "$status"
}

trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

sh -n "$PREFLIGHT" || fail "preflight shell syntax"

fixture_root=$TEST_ROOT/harness
fake_bin=$TEST_ROOT/bin
mkdir -p "$fixture_root/libexec" "$fixture_root/profiles/hosts" \
    "$fixture_root/shell/environments" "$fixture_root/tests/fixtures" "$fake_bin"
cp "$ROOT/libexec/harness-inventory" "$fixture_root/libexec/harness-inventory"
printf '%s\n' '# host|persistent-root|cache-root|move-large|move-fast|delete-after-backup|owner-action' \
    >"$fixture_root/profiles/home-layout.tsv"
printf '%s\n' '# host|primary-repository|independent-replica-root|password-file|replica-transport' \
    >"$fixture_root/profiles/restic-repositories.tsv"
printf '%s\n' '# host|scheduler|native-submit|state-root|warning-policy' \
    >"$fixture_root/profiles/restic-schedules.tsv"

HARNESS_ROOT="$fixture_root" "$PREFLIGHT" validate newnode9 \
    >"$TEST_ROOT/validate.out" || fail "valid new host rejected"
grep -F 'host=newnode9 boundary=ssh-alias-only status=accepted' \
    "$TEST_ROOT/validate.out" >/dev/null || fail "validation boundary marker"

for bad_host in local si web github abci_login alps_login Bad ../bad bad/name two..dots; do
    expect_failure '' "$TEST_ROOT/bad-host.out" env HARNESS_ROOT="$fixture_root" \
        "$PREFLIGHT" validate "$bad_host"
done

for profile in "$ROOT"/profiles/hosts/*.conf; do
    managed=${profile##*/}
    managed=${managed%.conf}
    if [ "$managed" = local ]; then
        expect_failure 'reserved or service' "$TEST_ROOT/managed.out" \
            "$PREFLIGHT" validate "$managed"
    else
        expect_failure 'already exists' "$TEST_ROOT/managed.out" \
            "$PREFLIGHT" validate "$managed"
    fi
done

: >"$fixture_root/shell/environments/shellnode.sh"
expect_failure 'already exists' "$TEST_ROOT/shell-collision.out" \
    env HARNESS_ROOT="$fixture_root" "$PREFLIGHT" validate shellnode
printf '%s\n' 'mapnode|/large|/cache|none|none|none|none' \
    >>"$fixture_root/profiles/home-layout.tsv"
expect_failure 'already exists' "$TEST_ROOT/map-collision.out" \
    env HARNESS_ROOT="$fixture_root" "$PREFLIGHT" validate mapnode

cat >"$fake_bin/ssh" <<'EOF'
#!/bin/sh
printf '%s\n' call >>"$FAKE_SSH_LOG"
[ "$#" -eq 4 ] || exit 90
[ "$1" = -o ] && [ "$2" = BatchMode=yes ] || exit 91
[ "$3" = newnode9 ] && [ "$4" = 'exec sh -s -- --host newnode9' ] || exit 92
case ${FAKE_SSH_MODE:-good} in
    good)
        printf '%s\n' schema=1 logical_host=newnode9 os_id=linux arch=x86_64 \
            login_shell=bash tool_sh=present tool_bash=present tool_git=present \
            harness_checkout=absent
        ;;
    duplicate)
        printf '%s\n' schema=1 schema=1 logical_host=newnode9 os_id=linux \
            arch=x86_64 login_shell=bash tool_sh=present tool_bash=present \
            tool_git=present harness_checkout=absent
        ;;
    wrong-host)
        printf '%s\n' schema=1 logical_host=other os_id=linux arch=x86_64 \
            login_shell=bash tool_sh=present tool_bash=present tool_git=present \
            harness_checkout=absent
        ;;
    hostile)
        printf '%s\n' schema=1 logical_host=newnode9 'os_id=linux value' \
            arch=x86_64 login_shell=bash tool_sh=present tool_bash=present \
            tool_git=present harness_checkout=absent
        ;;
    oversize)
        awk 'BEGIN { for (i=0; i<70000; i++) printf "x" }'
        ;;
    refused) exit 93 ;;
    *) exit 94 ;;
esac
EOF
chmod 700 "$fake_bin/ssh"

PATH="$fake_bin:/usr/bin:/bin" HARNESS_ROOT="$fixture_root" TMPDIR="$TEST_ROOT" \
    FAKE_SSH_LOG="$TEST_ROOT/ssh.log" \
    "$PREFLIGHT" inventory newnode9 >"$TEST_ROOT/inventory.out" ||
    fail "valid value-free inventory rejected"
[ "$(wc -l <"$TEST_ROOT/ssh.log" | tr -d ' ')" -eq 1 ] ||
    fail "inventory used more than one SSH connection"
grep -Fx 'logical_host=newnode9' "$TEST_ROOT/inventory.out" >/dev/null ||
    fail "inventory logical identity"
for mode in duplicate wrong-host hostile oversize; do
    expect_failure 'inventory' "$TEST_ROOT/inventory-$mode.out" env \
        PATH="$fake_bin:/usr/bin:/bin" HARNESS_ROOT="$fixture_root" TMPDIR="$TEST_ROOT" \
        FAKE_SSH_LOG="$TEST_ROOT/ssh.log" \
        FAKE_SSH_MODE="$mode" "$PREFLIGHT" inventory newnode9
done
expect_failure 'connection failed' "$TEST_ROOT/inventory-refused.out" env \
    PATH="$fake_bin:/usr/bin:/bin" HARNESS_ROOT="$fixture_root" TMPDIR="$TEST_ROOT" \
    FAKE_SSH_LOG="$TEST_ROOT/ssh.log" \
    FAKE_SSH_MODE=refused "$PREFLIGHT" inventory newnode9
if find "$TEST_ROOT" -maxdepth 1 -name 'harness-onboard.*' -print -quit |
    grep . >/dev/null 2>&1; then
    fail "preflight left a private inventory capture"
fi

SKILL=$ROOT/shared/skills/onboard-mirrored-node/SKILL.md
grep -F 'Plan–Interview–Execute skill' "$SKILL" >/dev/null || fail "PIE contract"
grep -F 'Do not enumerate `~/.ssh/config`' "$SKILL" >/dev/null || fail "SSH discovery boundary"
grep -F 'owner-only checkpoint' "$SKILL" >/dev/null || fail "password checkpoint"
grep -F 'guarded-bulk-delete skill' "$SKILL" >/dev/null || fail "guarded cleanup contract"
grep -F 'Scheduling is excluded' "$SKILL" >/dev/null || fail "schedule exclusion"
if grep -F '.ssh/config' "$PREFLIGHT" >/dev/null; then
    fail "preflight inspects SSH configuration"
fi

printf '%s\n' 'onboard mirrored node tests passed'
