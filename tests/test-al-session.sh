#!/bin/sh
set -eu

if [ "$(uname -s)" != Linux ]; then
    echo "SKIP: AL session helper requires Linux"
    exit 0
fi

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/harness-al-session-test.XXXXXX")

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

stop_fixture_master() {
    home=$1
    if [ -f "$home/.ssh/cm-al.pid" ]; then
        HOME="$home" PATH="$fake_bin:/usr/bin:/bin" \
            ssh -O stop al >/dev/null 2>&1 || true
    fi
    if [ -f "$home/.ssh/agent.pid" ]; then
        pid=$(sed -n '1p' "$home/.ssh/agent.pid")
        kill "$pid" >/dev/null 2>&1 || true
        attempts=0
        while [ -S "$home/.ssh/agent.sock" ] && [ "$attempts" -lt 50 ]; do
            sleep 0.1
            attempts=$((attempts + 1))
        done
        unlink "$home/.ssh/agent.pid"
    fi
}

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    for fixture_home in "$TEST_ROOT"/home-*; do
        [ -d "$fixture_home" ] || continue
        stop_fixture_master "$fixture_home"
    done
    cleanup_failed=0
    if [ -d "$TEST_ROOT" ]; then
        "$CLEANUP" "$HARNESS" "$TEMP_BASE" "$TEST_ROOT" \
            "$TEMP_BASE" >/dev/null || cleanup_failed=1
    fi
    [ "$status" -ne 0 ] || [ "$cleanup_failed" -eq 0 ] || status=1
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

fake_bin=$TEST_ROOT/fake-bin
mkdir "$fake_bin"

cat >"$TEST_ROOT/socket-daemon.py" <<'PY'
import os
import signal
import socket
import sys
import time

path = sys.argv[1]
sock = socket.socket(socket.AF_UNIX)
sock.bind(path)
sock.listen(1)

def stop(_signum, _frame):
    sock.close()
    try:
        os.unlink(path)
    except FileNotFoundError:
        pass
    raise SystemExit(0)

signal.signal(signal.SIGTERM, stop)
signal.signal(signal.SIGINT, stop)
while True:
    time.sleep(60)
PY

cat >"$fake_bin/ssh" <<'EOF'
#!/bin/sh
set -eu

operation=
alias_name=
generate=no
fresh=no
while [ "$#" -gt 0 ]; do
    case "$1" in
        -G) generate=yes; shift; alias_name=$1; shift ;;
        -O) shift; operation=$1; shift ;;
        -o)
            shift
            [ "$1" != ControlMaster=no ] || fresh=yes
            shift
            ;;
        -M|-N|-f|-MN|-Mf|-Nf|-MNf) shift ;;
        --) shift; break ;;
        -*) shift ;;
        *)
            [ -n "$alias_name" ] || alias_name=$1
            shift
            ;;
    esac
done

if [ "$generate" = yes ]; then
    case "$alias_name" in
        al)
            printf '%s\n' \
                'hostname daint.invalid' \
                'controlmaster auto' \
                "controlpath $HOME/.ssh/cm-al" \
                'controlpersist yes' \
                'proxyjump alps_login' \
                'serveraliveinterval 15' \
                'serveralivecountmax 3'
            ;;
        alps_login)
            printf '%s\n' \
                'hostname ela.invalid' \
                'controlmaster auto' \
                "controlpath $HOME/.ssh/cm-jump" \
                'controlpersist yes' \
                'serveraliveinterval 15' \
                'serveralivecountmax 3'
            ;;
        *) exit 255 ;;
    esac
    exit 0
fi

case "$operation:$alias_name" in
    check:al)
        [ -S "$HOME/.ssh/cm-al" ]
        ;;
    check:alps_login)
        [ "${FAKE_JUMP_READY:-yes}" = yes ]
        ;;
    stop:al)
        pid_file=$HOME/.ssh/cm-al.pid
        [ -f "$pid_file" ] || exit 255
        pid=$(sed -n '1p' "$pid_file")
        kill "$pid"
        attempts=0
        while [ -S "$HOME/.ssh/cm-al" ] && [ "$attempts" -lt 50 ]; do
            sleep 0.1
            attempts=$((attempts + 1))
        done
        unlink "$pid_file"
        if [ -f "$HOME/.ssh/fake-unit" ]; then
            unlink "$HOME/.ssh/fake-unit"
        fi
        [ ! -S "$HOME/.ssh/cm-al" ]
        ;;
    :al)
        mode=$(sed -n '1p' "$FAKE_SSH_MODE_FILE")
        case "$mode" in
            auth)
                echo 'Permission denied (publickey).' >&2
                exit 255
                ;;
            unavailable)
                echo 'Connection timed out.' >&2
                exit 255
                ;;
            success)
                [ "$fresh" = no ] || exit 0
                python3 "$FAKE_SOCKET_DAEMON" "$HOME/.ssh/cm-al" \
                    >/dev/null 2>&1 &
                pid=$!
                printf '%s\n' "$pid" >"$HOME/.ssh/cm-al.pid"
                attempts=0
                while [ ! -S "$HOME/.ssh/cm-al" ] && [ "$attempts" -lt 50 ]; do
                    sleep 0.1
                    attempts=$((attempts + 1))
                done
                [ -S "$HOME/.ssh/cm-al" ]
                ;;
            *) exit 255 ;;
        esac
        ;;
    *) exit 255 ;;
esac
EOF
chmod 755 "$fake_bin/ssh"

cat >"$fake_bin/systemctl" <<'EOF'
#!/bin/sh
set -eu

[ "$1" = --user ] || exit 2
shift
command_name=$1
shift
case "$command_name" in
    show-environment) exit 0 ;;
    show)
        if [ -f "$HOME/.ssh/fake-unit" ]; then
            echo loaded
        else
            echo not-found
        fi
        ;;
    is-active)
        [ -f "$HOME/.ssh/fake-unit" ]
        ;;
    reset-failed) exit 0 ;;
    stop)
        if [ -f "$HOME/.ssh/cm-al.pid" ]; then
            "$FAKE_SSH_COMMAND" -O stop al >/dev/null 2>&1
        fi
        ;;
    *) exit 2 ;;
esac
EOF
chmod 755 "$fake_bin/systemctl"

cat >"$fake_bin/systemd-run" <<'EOF'
#!/bin/sh
set -eu

[ "$(sed -n '1p' "$FAKE_SSH_MODE_FILE")" = success ] || exit 1
printf '%s\n' "$*" >"$HOME/.ssh/systemd-run.args"
python3 "$FAKE_SOCKET_DAEMON" "$HOME/.ssh/cm-al" >/dev/null 2>&1 &
pid=$!
printf '%s\n' "$pid" >"$HOME/.ssh/cm-al.pid"
printf '%s\n' active >"$HOME/.ssh/fake-unit"
attempts=0
while [ ! -S "$HOME/.ssh/cm-al" ] && [ "$attempts" -lt 50 ]; do
    sleep 0.1
    attempts=$((attempts + 1))
done
[ -S "$HOME/.ssh/cm-al" ]
EOF
chmod 755 "$fake_bin/systemd-run"

new_home() {
    name=$1
    path=$TEST_ROOT/home-$name
    mkdir -p "$path/.ssh"
    chmod 700 "$path" "$path/.ssh"
    python3 "$TEST_ROOT/socket-daemon.py" "$path/.ssh/agent.sock" \
        >/dev/null 2>&1 &
    agent_pid=$!
    printf '%s\n' "$agent_pid" >"$path/.ssh/agent.pid"
    attempts=0
    while [ ! -S "$path/.ssh/agent.sock" ] && [ "$attempts" -lt 50 ]; do
        sleep 0.1
        attempts=$((attempts + 1))
    done
    [ -S "$path/.ssh/agent.sock" ] || fail "agent socket fixture"
    printf '%s\n' "$path"
}

run_harness() {
    home=$1
    shift
    HOME="$home" HARNESS_LOGICAL_HOST=local \
        SSH_AUTH_SOCK="$home/.ssh/agent.sock" \
        FAKE_SSH_MODE_FILE="$TEST_ROOT/ssh-mode" \
        FAKE_SOCKET_DAEMON="$TEST_ROOT/socket-daemon.py" \
        FAKE_SSH_COMMAND="$fake_bin/ssh" \
        PATH="$fake_bin:/usr/bin:/bin" "$HARNESS" al-session "$@"
}

home=$(new_home basic)
printf '%s\n' auth >"$TEST_ROOT/ssh-mode"
status=$(run_harness "$home" --status)
[ "$status" = \
    'AL_SESSION mode=status target=absent ownership=none jump=ready action=start' ] ||
    fail "absent status"

if run_harness "$home" --start >"$TEST_ROOT/auth.out" 2>&1; then
    fail "authentication failure accepted"
fi
grep -F -x \
    'AL_SESSION mode=start target=absent ownership=none jump=ready action=renewal-required' \
    "$TEST_ROOT/auth.out" >/dev/null || fail "renewal-required classification"
[ ! -e "$home/.ssh/.harness-al-session.state" ] ||
    fail "authentication failure left receipt"
[ -z "$(find "$home/.ssh" -maxdepth 1 -name '.harness-al-session.log.*' -print)" ] ||
    fail "authentication failure left private log"

printf '%s\n' unavailable >"$TEST_ROOT/ssh-mode"
if run_harness "$home" --start >"$TEST_ROOT/unavailable.out" 2>&1; then
    fail "availability failure accepted"
fi
grep -F -x \
    'AL_SESSION mode=start target=absent ownership=none jump=ready action=unavailable' \
    "$TEST_ROOT/unavailable.out" >/dev/null || fail "availability classification"

printf '%s\n' success >"$TEST_ROOT/ssh-mode"
started=$(run_harness "$home" --start)
[ "$started" = \
    'AL_SESSION mode=start target=ready ownership=managed jump=ready action=created' ] ||
    fail "managed start"
[ -f "$home/.ssh/.harness-al-session.state" ] &&
    [ ! -L "$home/.ssh/.harness-al-session.state" ] ||
    fail "managed receipt type"
[ "$(stat -c %a "$home/.ssh/.harness-al-session.state")" = 600 ] ||
    fail "managed receipt mode"
grep -F -- '--collect' "$home/.ssh/systemd-run.args" >/dev/null ||
    fail "transient unit collection policy"
grep -F -- '--property=Restart=no' "$home/.ssh/systemd-run.args" >/dev/null ||
    fail "transient unit restart policy"
grep -F -- '--property=StandardError=null' \
    "$home/.ssh/systemd-run.args" >/dev/null ||
    fail "transient unit private-output policy"
grep -F -- '-o ControlPersist=no -M -N al' \
    "$home/.ssh/systemd-run.args" >/dev/null ||
    fail "foreground master policy"

managed=$(run_harness "$home" --status)
[ "$managed" = \
    'AL_SESSION mode=status target=ready ownership=managed jump=ready action=none' ] ||
    fail "managed status"
idempotent=$(run_harness "$home" --start)
[ "$idempotent" = \
    'AL_SESSION mode=start target=ready ownership=managed jump=ready action=none' ] ||
    fail "idempotent start"
stopped=$(run_harness "$home" --stop)
[ "$stopped" = \
    'AL_SESSION mode=stop target=absent ownership=managed jump=ready action=stopped' ] ||
    fail "managed stop"
[ ! -e "$home/.ssh/.harness-al-session.state" ] ||
    fail "managed stop left receipt"

external_home=$(new_home external)
HOME="$external_home" FAKE_SSH_MODE_FILE="$TEST_ROOT/ssh-mode" \
    FAKE_SOCKET_DAEMON="$TEST_ROOT/socket-daemon.py" \
    PATH="$fake_bin:/usr/bin:/bin" ssh -MNf al
ln "$external_home/.ssh/cm-al" "$external_home/.ssh/cm-al.second-link"
[ "$(stat -c %h "$external_home/.ssh/cm-al")" = 2 ] ||
    fail "two-link socket fixture"
external=$(run_harness "$external_home" --status)
[ "$external" = \
    'AL_SESSION mode=status target=ready ownership=external jump=ready action=none' ] ||
    fail "external status"
if run_harness "$external_home" --stop >"$TEST_ROOT/external-stop.out" 2>&1; then
    fail "external master stop accepted"
fi
grep -F 'refusing to stop an AL master not created by this helper' \
    "$TEST_ROOT/external-stop.out" >/dev/null || fail "external stop refusal"
stop_fixture_master "$external_home"
unlink "$external_home/.ssh/cm-al.second-link"

unsafe_home=$(new_home unsafe)
printf '%s\n' unsafe >"$unsafe_home/receipt-target"
ln -s "$unsafe_home/receipt-target" \
    "$unsafe_home/.ssh/.harness-al-session.state"
if run_harness "$unsafe_home" --status >"$TEST_ROOT/unsafe.out" 2>&1; then
    fail "unsafe receipt accepted"
fi
grep -F 'AL session receipt is unsafe' "$TEST_ROOT/unsafe.out" >/dev/null ||
    fail "unsafe receipt refusal"

echo "AL session tests passed"
