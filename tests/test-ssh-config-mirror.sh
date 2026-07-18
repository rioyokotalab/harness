#!/bin/sh
set -eu
umask 077

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
MIRROR=$ROOT/libexec/harness-ssh-config-mirror
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/harness-ssh-mirror-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
socket_pid=

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    if [ -n "$socket_pid" ]; then
        kill "$socket_pid" 2>/dev/null || true
        wait "$socket_pid" 2>/dev/null || true
    fi
    cleanup_failed=0
    if [ -d "$TEMP_DIR" ]; then
        "$CLEANUP" "$ROOT/bin/harness" "${TMPDIR:-/tmp}" "$TEMP_DIR" \
            "${TMPDIR:-/tmp}" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then
        echo "FAIL: guarded SSH mirror cleanup" >&2
        status=1
    fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

fail() { echo "FAIL: $*" >&2; exit 1; }

local_home=$TEMP_DIR/local-home
remote_home=$TEMP_DIR/remote-home
fake_bin=$TEMP_DIR/fake-bin
mkdir -p "$local_home/.ssh" "$remote_home/.ssh" "$fake_bin"
chmod 700 "$local_home" "$local_home/.ssh" "$remote_home" "$remote_home/.ssh"
printf '%s\n' 'Host synthetic-source.invalid' '    HostName 192.0.2.71' \
    '    User synthetic-source' >"$local_home/.ssh/config"
printf '%s\n' 'Host synthetic-prior.invalid' '    HostName 192.0.2.72' \
    '    User synthetic-prior' >"$remote_home/.ssh/config"
chmod 600 "$local_home/.ssh/config" "$remote_home/.ssh/config"
cp "$remote_home/.ssh/config" "$TEMP_DIR/original-remote"

agent_socket=$TEMP_DIR/agent.sock
python3 -c 'import socket,sys,time
s=socket.socket(socket.AF_UNIX)
s.bind(sys.argv[1])
s.listen(1)
time.sleep(300)' "$agent_socket" &
socket_pid=$!
socket_wait=0
while [ ! -S "$agent_socket" ] && [ "$socket_wait" -lt 50 ]; do
    socket_wait=$((socket_wait + 1))
    sleep 0.02
done
[ -S "$agent_socket" ] || fail "synthetic agent socket"

cat >"$fake_bin/ssh" <<'EOF'
#!/bin/sh
for ssh_argument do
    [ "$ssh_argument" != -G ] || exec "$REAL_SSH" "$@"
done
if [ "${MIRROR_TEST_OFFLINE:-0}" = 1 ]; then
    exit 255
fi
target=
last=
while [ "$#" -gt 0 ]; do
    case "$1" in
        -o) shift 2 ;;
        *)
            if [ -z "$target" ]; then target=$1; else last=$1; fi
            shift
            ;;
    esac
done
printf 'target=%s\n' "$target" >>"$MIRROR_TEST_LOG"
[ "$target" = t4 ] || exit 93
[ -n "$last" ] || exit 94
HOME="$REMOTE_HOME" /bin/sh -c "$last"
EOF
cat >"$fake_bin/mv" <<'EOF'
#!/bin/sh
last=
for argument do last=$argument; done
if [ -n "${MIRROR_TEST_FAIL_REMOTE_DEST:-}" ] &&
   [ "$last" = "$MIRROR_TEST_FAIL_REMOTE_DEST" ] &&
   [ ! -e "$MIRROR_TEST_FAIL_MARKER" ]; then
    : >"$MIRROR_TEST_FAIL_MARKER"
    exit 42
fi
exec /usr/bin/mv "$@"
EOF
chmod 755 "$fake_bin/ssh" "$fake_bin/mv"
real_ssh=$(command -v ssh)
mirror_log=$TEMP_DIR/ssh-targets.log
: >"$mirror_log"

run_mirror() {
    HOME="$local_home" HARNESS_LOGICAL_HOST=local \
        SSH_AUTH_SOCK="$agent_socket" REMOTE_HOME="$remote_home" \
        REAL_SSH="$real_ssh" MIRROR_TEST_LOG="$mirror_log" \
        PATH="$fake_bin:/usr/bin:/bin" "$MIRROR" "$@"
}

if HOME="$local_home" HARNESS_LOGICAL_HOST=ab SSH_AUTH_SOCK="$agent_socket" \
    PATH="$fake_bin:/usr/bin:/bin" "$MIRROR" --plan \
    >"$TEMP_DIR/wrong-source.out" 2>&1; then
    fail "non-local mirror source accepted"
fi
grep -F 'restricted to the declared local profile' \
    "$TEMP_DIR/wrong-source.out" >/dev/null || fail "fixed local source refusal"

plan_output=$(run_mirror --plan)
[ "$plan_output" = \
    'SSH_CONFIG_MIRROR class=current agreement=no action=replace apply=not-requested' ] ||
    fail "changed destination plan"
cmp -s "$remote_home/.ssh/config" "$TEMP_DIR/original-remote" ||
    fail "plan changed remote configuration"

apply_output=$(run_mirror --apply)
[ "$apply_output" = \
    'SSH_CONFIG_MIRROR class=current agreement=yes action=applied rollback=available' ] ||
    fail "fixed mirror apply"
cmp -s "$local_home/.ssh/config" "$remote_home/.ssh/config" ||
    fail "mirror content mismatch"
[ "$(stat -c %a "$remote_home/.ssh/config")" = 600 ] ||
    fail "mirror destination mode"
cmp -s "$remote_home/.local/state/harness/ssh-config-mirror/previous" \
    "$TEMP_DIR/original-remote" || fail "single prior rollback image"

current_output=$(run_mirror --plan)
[ "$current_output" = \
    'SSH_CONFIG_MIRROR class=current agreement=yes action=none' ] ||
    fail "current mirror no-op"

rollback_output=$(run_mirror --rollback)
[ "$rollback_output" = \
    'SSH_CONFIG_MIRROR class=current agreement=no action=rolled-back' ] ||
    fail "fixed mirror rollback"
cmp -s "$remote_home/.ssh/config" "$TEMP_DIR/original-remote" ||
    fail "mirror rollback did not restore prior configuration"
run_mirror --apply >/dev/null || fail "mirror reapply after rollback"

source_sentinel=PRIVATE_MIRROR_SENTINEL
printf '%s\n' 'Host privacy.invalid' '    HostName 192.0.2.81' \
    "    User $source_sentinel" >"$local_home/.ssh/config"
chmod 600 "$local_home/.ssh/config"
privacy_output=$(run_mirror --plan)
case "$privacy_output" in
    *"$source_sentinel"*|*"$local_home"*|*"$remote_home"*)
        fail "mirror output exposed private content"
        ;;
esac

printf '%s\n' 'Host invalid.invalid' '    ProxyCommand "unterminated' \
    >"$local_home/.ssh/config"
chmod 600 "$local_home/.ssh/config"
if run_mirror --plan >"$TEMP_DIR/invalid-source.out" 2>&1; then
    fail "invalid mirror source grammar accepted"
fi
grep -F 'SSH mirror source grammar is invalid' \
    "$TEMP_DIR/invalid-source.out" >/dev/null || fail "invalid source refusal"

printf '%s\n' 'Host valid-again.invalid' '    HostName 192.0.2.91' \
    >"$local_home/.ssh/config"
chmod 666 "$local_home/.ssh/config"
if run_mirror --plan >"$TEMP_DIR/unsafe-source.out" 2>&1; then
    fail "unsafe mirror source mode accepted"
fi
grep -F 'SSH mirror source has unsafe mode' \
    "$TEMP_DIR/unsafe-source.out" >/dev/null || fail "unsafe source mode refusal"
chmod 600 "$local_home/.ssh/config"

chmod 666 "$remote_home/.ssh/config"
if run_mirror --plan >"$TEMP_DIR/invalid-remote.out" 2>&1; then
    fail "unsafe remote destination accepted"
fi
grep -F 'class=invalid agreement=no action=stopped' \
    "$TEMP_DIR/invalid-remote.out" >/dev/null || fail "unsafe remote classification"
chmod 600 "$remote_home/.ssh/config"

if HOME="$local_home" HARNESS_LOGICAL_HOST=local SSH_AUTH_SOCK="$TEMP_DIR/missing.sock" \
    TMUX='' XDG_RUNTIME_DIR='' \
    REMOTE_HOME="$remote_home" REAL_SSH="$real_ssh" \
    MIRROR_TEST_LOG="$mirror_log" PATH="$fake_bin:/usr/bin:/bin" \
    "$MIRROR" --plan >"$TEMP_DIR/no-agent.out" 2>&1; then
    fail "missing agent socket accepted"
fi
grep -F 'class=auth-failed agreement=no' "$TEMP_DIR/no-agent.out" >/dev/null ||
    fail "missing-agent classification"

if HOME="$local_home" HARNESS_LOGICAL_HOST=local SSH_AUTH_SOCK="$agent_socket" \
    REMOTE_HOME="$remote_home" REAL_SSH="$real_ssh" \
    MIRROR_TEST_LOG="$mirror_log" MIRROR_TEST_OFFLINE=1 \
    PATH="$fake_bin:/usr/bin:/bin" "$MIRROR" --plan \
    >"$TEMP_DIR/offline.out" 2>&1; then
    fail "offline transport accepted"
fi
grep -F 'class=offline agreement=no' "$TEMP_DIR/offline.out" >/dev/null ||
    fail "offline classification"

cp "$remote_home/.ssh/config" "$TEMP_DIR/before-atomic"
printf '%s\n' 'Host atomic.invalid' '    HostName 192.0.2.101' \
    >"$local_home/.ssh/config"
chmod 600 "$local_home/.ssh/config"
atomic_marker=$TEMP_DIR/remote-atomic-failed-once
if HOME="$local_home" HARNESS_LOGICAL_HOST=local SSH_AUTH_SOCK="$agent_socket" \
    REMOTE_HOME="$remote_home" REAL_SSH="$real_ssh" \
    MIRROR_TEST_LOG="$mirror_log" \
    MIRROR_TEST_FAIL_REMOTE_DEST="$remote_home/.ssh/config" \
    MIRROR_TEST_FAIL_MARKER="$atomic_marker" PATH="$fake_bin:/usr/bin:/bin" \
    "$MIRROR" --apply >"$TEMP_DIR/atomic.out" 2>&1; then
    fail "injected remote atomic failure succeeded"
fi
grep -F 'class=offline agreement=no' "$TEMP_DIR/atomic.out" >/dev/null ||
    fail "remote atomic failure classification"
cmp -s "$remote_home/.ssh/config" "$TEMP_DIR/before-atomic" ||
    fail "remote atomic failure changed live configuration"
run_mirror --apply >/dev/null || fail "retry after remote atomic failure"

[ "$(awk -F= '$1 == "target" && $2 == "t4" { n++ } END { print n + 0 }' \
    "$mirror_log")" -gt 0 ] || fail "fixed t4 target not exercised"
if grep -E 'target=(ab|ab2|ri|al|rc)$' "$mirror_log" >/dev/null; then
    fail "excluded Linux host was targeted"
fi

echo "SSH config mirror tests passed"
