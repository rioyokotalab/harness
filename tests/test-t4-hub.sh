#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/harness-t4-hub-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEST_ROOT" ]; then
        TMPDIR="$TEMP_BASE" "$CLEANUP" "$ROOT/bin/harness" "$TEMP_BASE" "$TEST_ROOT" "$TEMP_BASE" \
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

PUBLIC=$TEST_ROOT/public
FAKE_BIN=$TEST_ROOT/bin
STATE=$TEST_ROOT/state
RUNTIME=$TEST_ROOT/runtime
mkdir -p "$PUBLIC/bin" "$PUBLIC/libexec" "$PUBLIC/profiles" \
    "$FAKE_BIN" "$STATE" "$RUNTIME"
cp "$ROOT/bin/harness" "$PUBLIC/bin/harness"
cp "$ROOT/libexec/harness-inventory" "$PUBLIC/libexec/harness-inventory"
cp "$ROOT/libexec/harness-t4-hub" "$PUBLIC/libexec/harness-t4-hub"
cp "$ROOT/profiles/t4-hub-routes.tsv" "$PUBLIC/profiles/t4-hub-routes.tsv"
chmod 755 "$PUBLIC/bin/harness" "$PUBLIC/libexec/harness-t4-hub"

cat >"$FAKE_BIN/ssh" <<'EOF'
#!/bin/sh
set -eu
socket=
operation=
query=
previous=
for argument do
    if [ "$previous" = S ]; then socket=$argument; previous=; continue; fi
    if [ "$previous" = O ]; then operation=$argument; previous=; continue; fi
    if [ "$previous" = G ]; then query=$argument; previous=; continue; fi
    case "$argument" in -S) previous=S ;; -O) previous=O ;; -G) previous=G ;; esac
done
if [ -n "$query" ]; then
    case "$query" in
        tunnel) printf '%s\n' 'remoteforward localhost:6101 localhost:22' ;;
        tunnel2) printf '%s\n' 'remoteforward localhost:6102 localhost:22' ;;
        riken) printf '%s\n' 'hostname localhost' 'port 6101' ;;
        riken2) printf '%s\n' 'hostname localhost' 'port 6102' ;;
        duplicate) printf '%s\n' 'remoteforward localhost:6101 localhost:22' 'remoteforward localhost:6102 localhost:22' ;;
        *) exit 1 ;;
    esac
    exit 0
fi
if [ "$operation" = check ]; then [ -S "$socket" ]; exit; fi
if [ "$operation" = exit ]; then
    [ ! -S "$socket" ] || unlink "$socket"
    exit 0
fi
printf '%s\n' "$*" >>"$HARNESS_T4_HUB_TEST_LOG"
case " $* " in *' -fNT '*)
    [ -n "$socket" ] || exit 2
    python3 - "$socket" <<'PY'
import socket
import sys
s = socket.socket(socket.AF_UNIX)
s.bind(sys.argv[1])
s.close()
PY
    ;;
esac
exit 0
EOF
chmod 755 "$FAKE_BIN/ssh"

cat >"$FAKE_BIN/ssh-keyscan" <<'EOF'
#!/bin/sh
set -eu
[ "${HARNESS_T4_HUB_KEYSCAN_FAIL:-0}" != 1 ] || exit 1
printf '%s\n' '[localhost]:6102 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFIXTURE'
EOF
chmod 755 "$FAKE_BIN/ssh-keyscan"

AGENT=$TEST_ROOT/agent.sock
python3 - "$AGENT" <<'PY'
import socket
import sys
s = socket.socket(socket.AF_UNIX)
s.bind(sys.argv[1])
s.close()
PY

export PATH="$FAKE_BIN:$PATH"
export HARNESS_ROOT="$PUBLIC"
export HARNESS_TESTING=1
export HARNESS_T4_HUB_PLATFORM=Darwin
export HARNESS_T4_HUB_STATE_PARENT="$STATE"
export HARNESS_T4_HUB_RUNTIME_PARENT=/tmp
export HARNESS_T4_HUB_SOCKET_SUFFIX=test$$
export HARNESS_T4_HUB_DURATION=2
export HARNESS_T4_HUB_TEST_LOG="$TEST_ROOT/ssh.log"
export TMPDIR="$RUNTIME"

"$PUBLIC/bin/harness" t4-hub --host riken --login-node login1 --plan \
    >"$TEST_ROOT/plan.out"
grep -F 'T4_HUB mode=plan host=riken login_node=login1 duration_seconds=2 local_topology=preserved' \
    "$TEST_ROOT/plan.out" >/dev/null || fail "plan output"
[ ! -e "$STATE/t4-hub" ] || fail "plan changed state"

"$PUBLIC/bin/harness" t4-hub --host riken --login-node login1 --apply \
    >"$TEST_ROOT/apply.out"
grep -F 'T4_HUB status=active host=riken login_node=login1 duration=bounded rollback=available' \
    "$TEST_ROOT/apply.out" >/dev/null || fail "apply output"
[ -f "$STATE/t4-hub/riken-login1.receipt" ] || fail "receipt absent"
"$PUBLIC/bin/harness" t4-hub --host riken --login-node login1 --status \
    >"$TEST_ROOT/status.out"
grep -F 'T4_HUB status=active host=riken login_node=login1 duration=bounded' \
    "$TEST_ROOT/status.out" >/dev/null || fail "active status"
grep -F -- '-o HostName=login1.t4.gsic.titech.ac.jp' "$TEST_ROOT/ssh.log" >/dev/null ||
    fail "pinned login hostname missing"
grep -F -- '-o HostKeyAlias=login.t4.gsic.titech.ac.jp' "$TEST_ROOT/ssh.log" >/dev/null ||
    fail "stable host-key identity missing"
grep -F -- '-R localhost:6101:localhost:22' "$TEST_ROOT/ssh.log" >/dev/null ||
    fail "source forward not preserved"

"$PUBLIC/bin/harness" t4-hub --host riken --login-node login1 --rollback \
    >"$TEST_ROOT/rollback.out"
[ ! -e "$STATE/t4-hub/riken-login1.receipt" ] || fail "rollback retained receipt"
[ ! -S "$(realpath /tmp)/harness-t4-hub-$(id -u)-riken-login1-test$$.sock" ] ||
    fail "rollback retained control socket"

SSH_AUTH_SOCK=$AGENT HARNESS_LOGICAL_HOST=t4 HARNESS_T4_HUB_HOSTNAME=login1 \
    "$PUBLIC/bin/harness" t4-hub --doctor --login-node login1 \
    >"$TEST_ROOT/doctor.out"
grep -F 'T4_HUB status=ready role=hub login_node=login1 auth=forwarded routes=declared' \
    "$TEST_ROOT/doctor.out" >/dev/null || fail "hub doctor"

: >"$TEST_ROOT/ssh.log"
SSH_AUTH_SOCK=$AGENT HARNESS_LOGICAL_HOST=t4 HARNESS_T4_HUB_HOSTNAME=login1 \
    "$PUBLIC/bin/harness" t4-hub --connect ab --login-node login1 -- true
grep -F -- '-o HostName=as.v3.abci.ai ab true' "$TEST_ROOT/ssh.log" >/dev/null ||
    fail "Linux global route"

: >"$TEST_ROOT/ssh.log"
SSH_AUTH_SOCK=$AGENT HARNESS_LOGICAL_HOST=t4 HARNESS_T4_HUB_HOSTNAME=login2 \
    "$PUBLIC/bin/harness" t4-hub --connect riken --login-node login2 -- true
grep -F -- '-o ControlMaster=no -o ControlPath=none -o StrictHostKeyChecking=yes -o CheckHostIP=no -o HostKeyAlias=t4-hub-riken' \
    "$TEST_ROOT/ssh.log" >/dev/null || fail "scoped Mac host-key policy"
grep -F -- 'riken2 true' \
    "$TEST_ROOT/ssh.log" >/dev/null || fail "secondary Mac route"
known_hosts=$(sed -n 's/.*UserKnownHostsFile=\([^ ]*\).*/\1/p' "$TEST_ROOT/ssh.log")
[ -n "$known_hosts" ] && [ ! -e "$known_hosts" ] ||
    fail "scoped Mac host-key state remained"

if HARNESS_T4_HUB_KEYSCAN_FAIL=1 SSH_AUTH_SOCK=$AGENT \
    HARNESS_LOGICAL_HOST=t4 HARNESS_T4_HUB_HOSTNAME=login2 \
    "$PUBLIC/bin/harness" t4-hub --connect riken --login-node login2 -- true \
    >"$TEST_ROOT/keyscan.out" 2>"$TEST_ROOT/keyscan.err"; then
    fail "Mac route accepted an unavailable host key"
fi
grep -F 'Mac tunnel host key is unavailable' "$TEST_ROOT/keyscan.err" >/dev/null ||
    fail "missing host-key failure class"

if SSH_AUTH_SOCK=$AGENT HARNESS_LOGICAL_HOST=t4 HARNESS_T4_HUB_HOSTNAME=login2 \
    "$PUBLIC/bin/harness" t4-hub --doctor --login-node login1 \
    >"$TEST_ROOT/mismatch.out" 2>"$TEST_ROOT/mismatch.err"; then
    fail "doctor accepted the wrong pinned node"
fi
grep -F 'selected login node differs from the current t4 host' \
    "$TEST_ROOT/mismatch.err" >/dev/null || fail "node mismatch class"

echo 't4 hub focused suite: pass'
