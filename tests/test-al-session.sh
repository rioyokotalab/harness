#!/bin/sh
set -eu

if [ "$(uname -s)" != Linux ]; then
    echo "SKIP: AL session helper requires Linux"
    exit 0
fi

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
RUNNER=$ROOT/libexec/harness-al-session-runner
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
        [ ! -f "$HOME/.ssh/master-unusable" ] &&
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

unit_value() {
    key=$1
    sed -n "s/^$key=//p" "$HOME/.ssh/fake-unit"
}

[ "$1" = --user ] || exit 2
shift
command_name=$1
shift
case "$command_name" in
    show-environment) exit 0 ;;
    show)
        property=
        while [ "$#" -gt 0 ]; do
            case "$1" in
                --property=*) property=${1#--property=} ;;
            esac
            shift
        done
        if [ ! -f "$HOME/.ssh/fake-unit" ]; then
            [ "$property" != LoadState ] || echo not-found
            exit 0
        fi
        case "$property" in
            LoadState) unit_value load ;;
            ActiveState) unit_value active ;;
            SubState) unit_value sub ;;
            Result) unit_value result ;;
            ExecMainStatus) unit_value status ;;
            Description) unit_value description ;;
            NRestarts) unit_value restarts ;;
            *) exit 2 ;;
        esac
        ;;
    is-active)
        [ -f "$HOME/.ssh/fake-unit" ] &&
            [ "$(unit_value active)" = active ]
        ;;
    reset-failed)
        [ ! -f "$HOME/.ssh/fake-unit" ] ||
            unlink "$HOME/.ssh/fake-unit"
        ;;
    stop)
        if [ -f "$HOME/.ssh/cm-al.pid" ] &&
            [ -S "$HOME/.ssh/cm-al" ]; then
            "$FAKE_SSH_COMMAND" -O stop al >/dev/null 2>&1
        elif [ -f "$HOME/.ssh/cm-al.pid" ]; then
            unlink "$HOME/.ssh/cm-al.pid"
        fi
        [ ! -f "$HOME/.ssh/fake-unit" ] ||
            unlink "$HOME/.ssh/fake-unit"
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
description=
for argument in "$@"; do
    case "$argument" in
        --description=*) description=${argument#--description=} ;;
    esac
done
[ -n "$description" ] || exit 1
python3 "$FAKE_SOCKET_DAEMON" "$HOME/.ssh/cm-al" >/dev/null 2>&1 &
pid=$!
printf '%s\n' "$pid" >"$HOME/.ssh/cm-al.pid"
printf '%s\n' \
    load=loaded active=active sub=running result=success status=0 \
    "description=$description" restarts=0 >"$HOME/.ssh/fake-unit"
attempts=0
while [ ! -S "$HOME/.ssh/cm-al" ] && [ "$attempts" -lt 50 ]; do
    sleep 0.1
    attempts=$((attempts + 1))
done
[ -S "$HOME/.ssh/cm-al" ]
EOF
chmod 755 "$fake_bin/systemd-run"

cat >"$fake_bin/runner-ssh" <<'EOF'
#!/bin/sh
set -eu

generate=no
operation=
while [ "$#" -gt 0 ]; do
    case "$1" in
        -G) generate=yes; shift; shift ;;
        -O) shift; operation=$1; shift ;;
        -o) shift; shift ;;
        -M|-N) shift ;;
        *) shift ;;
    esac
done
if [ "$generate" = yes ]; then
    printf '%s\n' "controlpath $HOME/.ssh/cm-al"
    exit 0
fi
if [ "$operation" = check ]; then
    [ "${FAKE_RUNNER_MASTER_READY:-no}" = yes ]
    exit
fi

case $(sed -n '1p' "$FAKE_SSH_MODE_FILE") in
    auth)
        echo 'Permission denied (publickey).' >&2
        exit 255
        ;;
    unavailable)
        echo 'Connection timed out.' >&2
        exit 255
        ;;
    permanent)
        echo 'Bad configuration option: invalid-fixture' >&2
        exit 255
        ;;
    success) exit 0 ;;
    *) exit 2 ;;
esac
EOF
chmod 755 "$fake_bin/runner-ssh"

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

runner_home=$(new_home runner)
for runner_case in auth unavailable permanent success; do
    printf '%s\n' "$runner_case" >"$TEST_ROOT/ssh-mode"
    expected=0
    case "$runner_case" in
        auth) expected=77 ;;
        unavailable) expected=75 ;;
        permanent) expected=78 ;;
    esac
    set +e
    HOME="$runner_home" FAKE_SSH_MODE_FILE="$TEST_ROOT/ssh-mode" \
        "$RUNNER" "$fake_bin/runner-ssh" >/dev/null 2>&1
    actual=$?
    set -e
    [ "$actual" -eq "$expected" ] ||
        fail "runner $runner_case classification"
    [ -z "$(find "$runner_home/.ssh" -maxdepth 1 \
        -name '.harness-al-session.log.*' -print)" ] ||
        fail "runner $runner_case left private log"
done

printf '%s\n' schema=2 alias=al \
    "control_path=$runner_home/.ssh/cm-al" \
    unit=harness-al-session.service marker=runner-stale \
    >"$runner_home/.ssh/.harness-al-session.state"
chmod 600 "$runner_home/.ssh/.harness-al-session.state"
python3 "$TEST_ROOT/socket-daemon.py" "$runner_home/.ssh/cm-al" \
    >/dev/null 2>&1 &
runner_stale_pid=$!
attempts=0
while [ ! -S "$runner_home/.ssh/cm-al" ] && [ "$attempts" -lt 50 ]; do
    sleep 0.1
    attempts=$((attempts + 1))
done
printf '%s\n' success >"$TEST_ROOT/ssh-mode"
HOME="$runner_home" FAKE_SSH_MODE_FILE="$TEST_ROOT/ssh-mode" \
    HARNESS_AL_SESSION_MARKER=runner-stale \
    "$RUNNER" "$fake_bin/runner-ssh" >/dev/null 2>&1 ||
    fail "runner stale socket recovery"
[ ! -e "$runner_home/.ssh/cm-al" ] &&
    [ ! -L "$runner_home/.ssh/cm-al" ] ||
    fail "runner retained receipt-matched stale socket"
kill "$runner_stale_pid"
wait "$runner_stale_pid" 2>/dev/null || true

python3 "$TEST_ROOT/socket-daemon.py" "$runner_home/.ssh/cm-al" \
    >/dev/null 2>&1 &
runner_collision_pid=$!
attempts=0
while [ ! -S "$runner_home/.ssh/cm-al" ] && [ "$attempts" -lt 50 ]; do
    sleep 0.1
    attempts=$((attempts + 1))
done
set +e
HOME="$runner_home" FAKE_SSH_MODE_FILE="$TEST_ROOT/ssh-mode" \
    HARNESS_AL_SESSION_MARKER=other-marker \
    "$RUNNER" "$fake_bin/runner-ssh" >/dev/null 2>&1
runner_collision_status=$?
set -e
[ "$runner_collision_status" -eq 78 ] ||
    fail "runner mismatched stale socket classification"
[ -S "$runner_home/.ssh/cm-al" ] ||
    fail "runner removed mismatched stale socket"
kill "$runner_collision_pid"
wait "$runner_collision_pid" 2>/dev/null || true
unlink "$runner_home/.ssh/.harness-al-session.state"

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
if grep -F -- '--collect' "$home/.ssh/systemd-run.args" >/dev/null; then
    fail "transient unit must remain inspectable"
fi
grep -F -- '--property=Restart=on-failure' \
    "$home/.ssh/systemd-run.args" >/dev/null ||
    fail "transient unit restart policy"
grep -F -- '--property=RestartSec=60s' \
    "$home/.ssh/systemd-run.args" >/dev/null ||
    fail "transient unit restart delay"
grep -F -- '--property=RestartPreventExitStatus=77 78' \
    "$home/.ssh/systemd-run.args" >/dev/null ||
    fail "transient unit terminal exit policy"
grep -E -- '--setenv=HARNESS_AL_SESSION_MARKER=al-session-[A-Za-z0-9._-]+' \
    "$home/.ssh/systemd-run.args" >/dev/null ||
    fail "transient unit marker environment"
grep -F -- '--property=StandardError=null' \
    "$home/.ssh/systemd-run.args" >/dev/null ||
    fail "transient unit private-output policy"
grep -F -- "$RUNNER" "$home/.ssh/systemd-run.args" >/dev/null ||
    fail "tracked runner policy"
grep -F -x 'schema=2' "$home/.ssh/.harness-al-session.state" >/dev/null ||
    fail "schema-2 receipt"
grep -F -x 'unit=harness-al-session.service' \
    "$home/.ssh/.harness-al-session.state" >/dev/null ||
    fail "receipt unit"
grep -E -x 'marker=[A-Za-z0-9._-]+' \
    "$home/.ssh/.harness-al-session.state" >/dev/null ||
    fail "receipt marker"
if grep -F 'socket_id=' "$home/.ssh/.harness-al-session.state" >/dev/null; then
    fail "schema-2 receipt retained socket identity"
fi
grep -F -- '-o BatchMode=yes -o ConnectionAttempts=1' "$RUNNER" >/dev/null ||
    fail "foreground master batch policy"
grep -F -- '-o ControlPersist=no -M -N al' "$RUNNER" >/dev/null ||
    fail "foreground master policy"

managed=$(run_harness "$home" --status)
[ "$managed" = \
    'AL_SESSION mode=status target=ready ownership=managed jump=ready action=none' ] ||
    fail "managed status"

printf '%s\n' yes >"$home/.ssh/master-unusable"
sed -i 's/^active=.*/active=activating/; s/^sub=.*/sub=auto-restart/' \
    "$home/.ssh/fake-unit"
stale_recovering=$(run_harness "$home" --status)
[ "$stale_recovering" = \
    'AL_SESSION mode=status target=recovering ownership=managed jump=ready action=retrying' ] ||
    fail "recovering status with stale socket"
unlink "$home/.ssh/master-unusable"
sed -i 's/^active=.*/active=active/; s/^sub=.*/sub=running/' \
    "$home/.ssh/fake-unit"

idempotent=$(run_harness "$home" --start)
[ "$idempotent" = \
    'AL_SESSION mode=start target=ready ownership=managed jump=ready action=none' ] ||
    fail "idempotent start"

old_socket_id=$(stat -c '%d:%i' "$home/.ssh/cm-al")
old_pid=$(sed -n '1p' "$home/.ssh/cm-al.pid")
kill "$old_pid"
attempts=0
while [ -S "$home/.ssh/cm-al" ] && [ "$attempts" -lt 50 ]; do
    sleep 0.1
    attempts=$((attempts + 1))
done
[ ! -S "$home/.ssh/cm-al" ] || fail "restart fixture old socket cleanup"
sed -i 's/^active=.*/active=activating/; s/^sub=.*/sub=auto-restart/' \
    "$home/.ssh/fake-unit"
recovering=$(run_harness "$home" --status)
[ "$recovering" = \
    'AL_SESSION mode=status target=recovering ownership=managed jump=ready action=retrying' ] ||
    fail "recovering status"
restart_start=$(run_harness "$home" --start)
[ "$restart_start" = \
    'AL_SESSION mode=start target=recovering ownership=managed jump=ready action=retrying' ] ||
    fail "recovering idempotent start"

python3 "$TEST_ROOT/socket-daemon.py" "$home/.ssh/cm-al" \
    >/dev/null 2>&1 &
new_pid=$!
printf '%s\n' "$new_pid" >"$home/.ssh/cm-al.pid"
attempts=0
while [ ! -S "$home/.ssh/cm-al" ] && [ "$attempts" -lt 50 ]; do
    sleep 0.1
    attempts=$((attempts + 1))
done
[ -S "$home/.ssh/cm-al" ] || fail "restart fixture replacement socket"
sed -i \
    's/^active=.*/active=active/; s/^sub=.*/sub=running/; s/^restarts=.*/restarts=1/' \
    "$home/.ssh/fake-unit"
new_socket_id=$(stat -c '%d:%i' "$home/.ssh/cm-al")
[ "$new_socket_id" != "$old_socket_id" ] ||
    fail "restart fixture did not replace socket identity"
restarted=$(run_harness "$home" --status)
[ "$restarted" = \
    'AL_SESSION mode=status target=ready ownership=managed jump=ready action=none' ] ||
    fail "restart-aware ownership"

stopped=$(run_harness "$home" --stop)
[ "$stopped" = \
    'AL_SESSION mode=stop target=absent ownership=managed jump=ready action=stopped' ] ||
    fail "managed stop"
[ ! -e "$home/.ssh/.harness-al-session.state" ] ||
    fail "managed stop left receipt"

auth_home=$(new_home terminal-auth)
printf '%s\n' success >"$TEST_ROOT/ssh-mode"
run_harness "$auth_home" --start >/dev/null
auth_pid=$(sed -n '1p' "$auth_home/.ssh/cm-al.pid")
kill "$auth_pid"
attempts=0
while [ -S "$auth_home/.ssh/cm-al" ] && [ "$attempts" -lt 50 ]; do
    sleep 0.1
    attempts=$((attempts + 1))
done
sed -i \
    's/^active=.*/active=failed/; s/^sub=.*/sub=failed/; s/^result=.*/result=exit-code/; s/^status=.*/status=77/' \
    "$auth_home/.ssh/fake-unit"
auth_status=$(run_harness "$auth_home" --status)
[ "$auth_status" = \
    'AL_SESSION mode=status target=absent ownership=managed jump=ready action=renewal-required' ] ||
    fail "terminal authentication status"
if run_harness "$auth_home" --start >"$TEST_ROOT/auth-restart.out" 2>&1; then
    fail "terminal authentication failure restarted"
fi
grep -F -x \
    'AL_SESSION mode=start target=absent ownership=managed jump=ready action=renewal-required' \
    "$TEST_ROOT/auth-restart.out" >/dev/null ||
    fail "terminal authentication start classification"
run_harness "$auth_home" --stop >/dev/null

permanent_home=$(new_home terminal-permanent)
printf '%s\n' success >"$TEST_ROOT/ssh-mode"
run_harness "$permanent_home" --start >/dev/null
permanent_pid=$(sed -n '1p' "$permanent_home/.ssh/cm-al.pid")
kill "$permanent_pid"
attempts=0
while [ -S "$permanent_home/.ssh/cm-al" ] && [ "$attempts" -lt 50 ]; do
    sleep 0.1
    attempts=$((attempts + 1))
done
sed -i \
    's/^active=.*/active=failed/; s/^sub=.*/sub=failed/; s/^result=.*/result=exit-code/; s/^status=.*/status=78/' \
    "$permanent_home/.ssh/fake-unit"
permanent_status=$(run_harness "$permanent_home" --status)
[ "$permanent_status" = \
    'AL_SESSION mode=status target=absent ownership=managed jump=ready action=repair-required' ] ||
    fail "terminal permanent status"
run_harness "$permanent_home" --stop >/dev/null

stale_home=$(new_home stale-schema2)
printf '%s\n' success >"$TEST_ROOT/ssh-mode"
run_harness "$stale_home" --start >/dev/null
stale_pid=$(sed -n '1p' "$stale_home/.ssh/cm-al.pid")
kill "$stale_pid"
attempts=0
while [ -S "$stale_home/.ssh/cm-al" ] && [ "$attempts" -lt 50 ]; do
    sleep 0.1
    attempts=$((attempts + 1))
done
sed -i 's/^active=.*/active=inactive/; s/^sub=.*/sub=dead/' \
    "$stale_home/.ssh/fake-unit"
stale_stopped=$(run_harness "$stale_home" --stop)
[ "$stale_stopped" = \
    'AL_SESSION mode=stop target=absent ownership=stale jump=ready action=stopped' ] ||
    fail "schema-2 stale stop"
[ ! -e "$stale_home/.ssh/fake-unit" ] &&
    [ ! -e "$stale_home/.ssh/.harness-al-session.state" ] ||
    fail "schema-2 stale stop residue"

collision_home=$(new_home collision)
printf '%s\n' success >"$TEST_ROOT/ssh-mode"
run_harness "$collision_home" --start >/dev/null
original_description=$(sed -n 's/^description=//p' \
    "$collision_home/.ssh/fake-unit")
sed -i 's/^description=.*/description=Harness AL session collision/' \
    "$collision_home/.ssh/fake-unit"
if run_harness "$collision_home" --status \
    >"$TEST_ROOT/collision.out" 2>&1; then
    fail "colliding unit marker accepted"
fi
grep -F 'AL session marked unit does not match the receipt' \
    "$TEST_ROOT/collision.out" >/dev/null ||
    fail "colliding unit marker refusal"
sed -i "s|^description=.*|description=$original_description|" \
    "$collision_home/.ssh/fake-unit"
run_harness "$collision_home" --stop >/dev/null

schema1_home=$(new_home schema1)
printf '%s\n' success >"$TEST_ROOT/ssh-mode"
HOME="$schema1_home" FAKE_SSH_MODE_FILE="$TEST_ROOT/ssh-mode" \
    FAKE_SOCKET_DAEMON="$TEST_ROOT/socket-daemon.py" \
    PATH="$fake_bin:/usr/bin:/bin" ssh -MNf al
schema1_socket_id=$(stat -c '%d:%i' "$schema1_home/.ssh/cm-al")
printf '%s\n' schema=1 alias=al \
    "control_path=$schema1_home/.ssh/cm-al" \
    "socket_id=$schema1_socket_id" \
    >"$schema1_home/.ssh/.harness-al-session.state"
chmod 600 "$schema1_home/.ssh/.harness-al-session.state"
schema1_status=$(run_harness "$schema1_home" --status)
[ "$schema1_status" = \
    'AL_SESSION mode=status target=ready ownership=managed jump=ready action=none' ] ||
    fail "schema-1 receipt compatibility"
run_harness "$schema1_home" --stop >/dev/null

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
