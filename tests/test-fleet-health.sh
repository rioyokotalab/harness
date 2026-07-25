#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HEALTH=$ROOT/libexec/harness-fleet-health
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/harness-fleet-health-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
AGENT_PID=

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    if [ -n "$AGENT_PID" ]; then
        kill "$AGENT_PID" 2>/dev/null || true
        wait "$AGENT_PID" 2>/dev/null || true
    fi
    cleanup_failed=0
    if [ -d "$TEMP_DIR" ]; then
        "$CLEANUP" "$ROOT/bin/harness" "$TEMP_BASE" "$TEMP_DIR" "$TEMP_BASE" \
            >/dev/null || cleanup_failed=1
    fi
    [ "$status" -ne 0 ] || [ "$cleanup_failed" -eq 0 ] || status=1
    exit "$status"
}
trap cleanup EXIT HUP INT TERM

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

PUBLIC=$TEMP_DIR/public
FAKE_BIN=$TEMP_DIR/fake-bin
STATE=$TEMP_DIR/state
mkdir -p "$PUBLIC/bin" "$PUBLIC/libexec" "$FAKE_BIN" "$STATE"
cp "$ROOT/bin/harness" "$PUBLIC/bin/harness"
cp "$ROOT/libexec/harness-inventory" "$PUBLIC/libexec/harness-inventory"
cp "$HEALTH" "$PUBLIC/libexec/harness-fleet-health"

cat >"$PUBLIC/libexec/harness-al-session" <<'EOF'
#!/bin/sh
printf '%s\n' al-session >>"$HARNESS_FLEET_HEALTH_STATE/calls"
[ ! -e "$HARNESS_FLEET_HEALTH_STATE/al-session.fail" ]
EOF
chmod 755 "$PUBLIC/libexec/harness-al-session"

cat >"$FAKE_BIN/ssh" <<'EOF'
#!/bin/sh
route=
for argument do
    case "$argument" in
        ab|ab2|ri|al|rc|t4|abq|abq2|aist|aist2|home|home2|office|office2|riken|riken2)
            route=$argument
            ;;
    esac
done
[ -n "$route" ] || exit 2
printf '%s %s\n' "$route" "$*" >>"$HARNESS_FLEET_HEALTH_STATE/calls"
[ "$route" != ab ] || sleep 0.2
if [ -e "$HARNESS_FLEET_HEALTH_STATE/$route.fail" ]; then
    echo 'PRIVATE-SSH-DIAGNOSTIC' >&2
    exit 1
fi
exit 0
EOF
chmod 755 "$FAKE_BIN/ssh"

SSH_AUTH_SOCK=$TEMP_DIR/agent.sock
export SSH_AUTH_SOCK
ssh-agent -a "$SSH_AUTH_SOCK" -s >"$TEMP_DIR/agent.env"
AGENT_PID=$(sed -n 's/^SSH_AGENT_PID=\([0-9][0-9]*\);.*/\1/p' "$TEMP_DIR/agent.env")
[ -n "$AGENT_PID" ] || fail "test SSH agent PID"

PATH="$FAKE_BIN:/usr/bin:/bin" HARNESS_ROOT="$PUBLIC" \
    HARNESS_FLEET_HEALTH_STATE="$STATE" "$HEALTH" >"$TEMP_DIR/healthy.out"
expected='local ab ab2 ri al rc t4 abq aist home office riken'
observed=$(sed -n 's/^FLEET_HEALTH node=\([^ ]*\).*/\1/p' "$TEMP_DIR/healthy.out" |
    tr '\n' ' ' | sed 's/ $//')
[ "$observed" = "$expected" ] || fail "fleet result order"
grep -F -x 'Fleet: Linux pass; Macs pass.' "$TEMP_DIR/healthy.out" >/dev/null ||
    fail "healthy compact summary"

grep '^al ' "$STATE/calls" | grep -F 'ControlMaster=' >/dev/null &&
    fail "AL probe overrode ControlMaster"
grep '^al ' "$STATE/calls" | grep -F 'ControlPath=' >/dev/null &&
    fail "AL probe overrode ControlPath"
[ "$(grep -c '^al-session$' "$STATE/calls")" -eq 1 ] ||
    fail "AL managed status was not checked"
for excluded in login login2 abci_login alps_login web; do
    grep -F "$excluded" "$STATE/calls" >/dev/null &&
        fail "excluded transport was probed"
done
for route in abq abq2 aist aist2 home home2 office office2 riken riken2; do
    grep "^$route " "$STATE/calls" | grep -F 'ControlMaster=no' >/dev/null ||
        fail "independent route contract missing for $route"
    grep "^$route " "$STATE/calls" | grep -F 'ControlPath=none' >/dev/null ||
        fail "independent route path contract missing for $route"
done

: >"$STATE/abq2.fail"
: >"$STATE/riken.fail"
if PATH="$FAKE_BIN:/usr/bin:/bin" HARNESS_ROOT="$PUBLIC" \
    HARNESS_FLEET_HEALTH_STATE="$STATE" "$HEALTH" \
    >"$TEMP_DIR/failed.out" 2>"$TEMP_DIR/failed.err"; then
    fail "fleet health accepted failed routes"
fi
grep -F -x 'Fleet: Linux fail nodes=abq; Macs fail nodes=riken.' \
    "$TEMP_DIR/failed.out" >/dev/null || fail "failed compact summary"
grep -F 'PRIVATE-SSH-DIAGNOSTIC' "$TEMP_DIR/failed.out" "$TEMP_DIR/failed.err" \
    >/dev/null && fail "private SSH diagnostic escaped"

echo "fleet health tests: PASS"
