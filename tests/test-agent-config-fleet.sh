#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/harness-agent-config-fleet-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    if [ -d "$TEMP_DIR" ]; then
        "$CLEANUP" "$HARNESS" "${TMPDIR:-/tmp}" "$TEMP_DIR" \
            "${TMPDIR:-/tmp}" >/dev/null || status=1
    fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
fail() { echo "FAIL: $*" >&2; exit 1; }

CONTROL=$TEMP_DIR/control
FAKE_BIN=$TEMP_DIR/fake-bin
LOG=$TEMP_DIR/order.log
mkdir -p "$CONTROL/libexec" "$FAKE_BIN"
cp "$ROOT/libexec/harness-agent-config-fleet" "$CONTROL/libexec/"
cp "$ROOT/libexec/harness-common" "$CONTROL/libexec/"
cat >"$CONTROL/libexec/harness-fleet-sync" <<'EOF'
#!/bin/sh
printf 'fleet|%s\n' "$*" >>"$AGENT_FLEET_TEST_LOG"
EOF
cat >"$CONTROL/libexec/harness-agent-config" <<'EOF'
#!/bin/sh
printf 'local|%s\n' "$*" >>"$AGENT_FLEET_TEST_LOG"
echo 'END synthetic_agent_config status=ready'
EOF
cat >"$FAKE_BIN/ssh" <<'EOF'
#!/bin/sh
[ "$1" = -x ] || exit 89
[ "$2" = -o ] && [ "$3" = BatchMode=yes ] || exit 90
[ "$4" = -o ] && [ "$5" = ConnectTimeout=15 ] || exit 91
host=$6
shift 6
printf 'remote|%s|%s\n' "$host" "$*" >>"$AGENT_FLEET_TEST_LOG"
[ "${AGENT_FLEET_FAIL_HOST:-}" != "$host" ] || exit 73
echo 'END synthetic_remote status=ready'
EOF
chmod 755 "$CONTROL/libexec/harness-agent-config-fleet" \
    "$CONTROL/libexec/harness-fleet-sync" \
    "$CONTROL/libexec/harness-agent-config" "$FAKE_BIN/ssh"

old=1111111111111111111111111111111111111111
new=2222222222222222222222222222222222222222
AGENT_FLEET_TEST_LOG=$LOG HARNESS_ROOT=$CONTROL \
    PATH="$FAKE_BIN:/usr/bin:/bin" \
    "$CONTROL/libexec/harness-agent-config-fleet" \
    --from "$old" --to "$new" --hosts n1,n2 --adopt --apply --drill \
    >"$TEMP_DIR/apply.out"
sed -n '1p' "$LOG" | grep -F -x \
    "fleet|--from $old --to $new --hosts n1,n2 --apply" >/dev/null ||
    fail "fleet synchronization order"
sed -n '2p' "$LOG" | grep -F -x 'local|--apply --adopt --drill' >/dev/null ||
    fail "local-first apply"
sed -n '3p' "$LOG" | grep -F 'remote|n1|' >/dev/null || fail "first remote"
sed -n '4p' "$LOG" | grep -F 'remote|n2|' >/dev/null || fail "second remote"
grep -F 'status=complete' "$TEMP_DIR/apply.out" >/dev/null ||
    fail "controller completion"
grep -F 'NATIVE ssh -x n1 harness-agent-config-apply' \
    "$TEMP_DIR/apply.out" >/dev/null || fail "X11-disabled agent transport"

: >"$LOG"
if AGENT_FLEET_TEST_LOG=$LOG AGENT_FLEET_FAIL_HOST=n2 \
    HARNESS_ROOT=$CONTROL PATH="$FAKE_BIN:/usr/bin:/bin" \
    "$CONTROL/libexec/harness-agent-config-fleet" \
    --from "$old" --to "$new" --hosts n1,n2,n3 --plan \
    >"$TEMP_DIR/fail.out" 2>&1; then
    fail "remote failure accepted"
fi
grep -F 'remote|n1|' "$LOG" >/dev/null || fail "pre-failure first remote"
grep -F 'remote|n2|' "$LOG" >/dev/null || fail "failing remote"
if grep -F 'remote|n3|' "$LOG" >/dev/null; then fail "controller did not stop"; fi
grep -F 'stopped at host: n2' "$TEMP_DIR/fail.out" >/dev/null ||
    fail "stop-on-first-failure report"

echo 'agent configuration fleet tests: PASS'
