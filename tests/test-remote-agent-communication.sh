#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HELPER=$ROOT/shared/skills/remote-agent-communication/scripts/agent-message
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/remote-agent-communication-test.XXXXXX")

fail() { echo "FAIL: $*" >&2; exit 1; }
cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEST_ROOT" ]; then
        "$CLEANUP" "$ROOT/bin/harness" "${TMPDIR:-/tmp}" "$TEST_ROOT" \
            "${TMPDIR:-/tmp}" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then status=1; fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

home=$TEST_ROOT/home
fake_bin=$TEST_ROOT/bin
state=$TEST_ROOT/state
mkdir -p "$home/harness" "$fake_bin" "$state"

cat >"$fake_bin/tmux" <<'EOF'
#!/bin/sh
set -eu
: "${FAKE_STATE:?}"
command=$1
shift
case "$command" in
    list-sessions)
        printf '%s\n' "${FAKE_SESSION:-harness}"
        ;;
    list-panes)
        tty=${FAKE_TTY:-/dev/pts/7}
        if [ "${FAKE_AMBIGUOUS:-0}" -eq 1 ]; then
            printf '%%0\t0\t%s/harness\t%s\n' "$HOME" "$tty"
            printf '%%1\t0\t%s/harness\t/dev/pts/8\n' "$HOME"
        else
            printf '%%0\t0\t%s/harness\t%s\n' "$HOME" "$tty"
        fi
        ;;
    display-message)
        printf '%s\n' "${FAKE_ATTACHED:-0}"
        ;;
    load-buffer)
        printf 'load-buffer %s\n' "$*" >>"$FAKE_STATE/operations"
        wc -c >"$FAKE_STATE/message-bytes"
        ;;
    paste-buffer)
        printf 'paste-buffer %s\n' "$*" >>"$FAKE_STATE/operations"
        ;;
    delete-buffer)
        printf 'delete-buffer %s\n' "$*" >>"$FAKE_STATE/operations"
        ;;
    send-keys)
        printf 'send-keys %s\n' "$*" >>"$FAKE_STATE/operations"
        ;;
    *)
        exit 1
        ;;
esac
EOF
chmod 755 "$fake_bin/tmux"

cat >"$fake_bin/ps" <<'EOF'
#!/bin/sh
set -eu
if [ "${FAKE_CODEX_COUNT:-1}" -eq 2 ]; then
    printf 'codex.real\ncodex.real\n'
elif [ "${FAKE_TTY:-}" = /dev/ttys000 ]; then
    printf '/opt/homebrew/bin/codex\n'
else
    printf 'sh\ncodex\ncodex.real\n'
fi
EOF
chmod 755 "$fake_bin/ps"

cat >"$fake_bin/ssh" <<'EOF'
#!/bin/sh
set -eu
: "${FAKE_STATE:?}"
printf '%s\n' "$*" >"$FAKE_STATE/ssh-arguments"
cp /dev/stdin "$FAKE_STATE/ssh-message"
printf 'AGENT_MESSAGE_RECEIVE source=%s target_role=%s status=submitted\n' \
    "${FAKE_SOURCE:?}" "${FAKE_TARGET_ROLE:?}"
EOF
chmod 755 "$fake_bin/ssh"

run_helper() {
    HOME=$home FAKE_STATE=$state \
        FAKE_SESSION=${FAKE_SESSION:-harness} \
        FAKE_ATTACHED=${FAKE_ATTACHED:-0} \
        FAKE_AMBIGUOUS=${FAKE_AMBIGUOUS:-0} \
        FAKE_CODEX_COUNT=${FAKE_CODEX_COUNT:-1} \
        FAKE_TTY=${FAKE_TTY:-/dev/pts/7} \
        PATH="$fake_bin:/usr/bin:/bin" \
        python3 -B "$HELPER" "$@"
}

message='[Agent: Riken Codex] controller experiment'
printf %s "$message" >"$state/message"
printf '%s\n' "$message" |
    run_helper receive --source riken --target-role controller \
    >"$state/controller.out"
grep -F -x \
    'AGENT_MESSAGE_RECEIVE source=riken target_role=controller status=submitted' \
    "$state/controller.out" >/dev/null || fail "controller receive output"
grep -F 'load-buffer ' "$state/operations" >/dev/null ||
    fail "private buffer load"
grep -F 'paste-buffer ' "$state/operations" >/dev/null ||
    fail "private buffer paste"
grep -F 'send-keys -t %0 C-m' "$state/operations" >/dev/null ||
    fail "separate submit"
if grep -F "$message" "$state/operations" >/dev/null; then
    fail "message leaked into tmux arguments"
fi
[ "$(tr -d ' ' <"$state/message-bytes")" -eq "${#message}" ] ||
    fail "message byte delivery"

if printf '%s\n' 'message without identity' |
    run_helper receive --source riken --target-role controller \
    >"$state/unidentified.out" 2>&1; then
    fail "unidentified message accepted"
fi
grep -F 'message does not identify the declared agent' \
    "$state/unidentified.out" >/dev/null || fail "identity rejection"

if printf '%s\n' '[Agent: Home Codex] wrong source' |
    run_helper receive --source riken --target-role controller \
    >"$state/wrong-source.out" 2>&1; then
    fail "misidentified source accepted"
fi

oversized=$TEST_ROOT/oversized
awk 'BEGIN {
    printf "[Agent: Riken Codex] "
    for (i = 0; i < 5000; i++) printf "x"
    printf "\n"
}' >"$oversized"
if run_helper receive --source riken --target-role controller \
    <"$oversized" >"$state/oversized.out" 2>&1; then
    fail "oversized message accepted"
fi

FAKE_SESSION=harness-codex-resume FAKE_ATTACHED=1 FAKE_TTY=/dev/ttys000 \
    run_helper receive --source riken --target-role mac \
    <"$state/message" >"$state/attached.out" 2>&1 &&
    fail "attached Mac accepted without override"
FAKE_SESSION=harness-codex-resume FAKE_ATTACHED=1 FAKE_TTY=/dev/ttys000 \
    run_helper receive --source riken --target-role mac --allow-attached \
    <"$state/message" >"$state/attached-allowed.out"

if FAKE_AMBIGUOUS=1 run_helper receive --source riken \
    --target-role controller <"$state/message" \
    >"$state/ambiguous.out" 2>&1; then
    fail "ambiguous controller pane accepted"
fi
if FAKE_CODEX_COUNT=2 run_helper receive --source riken \
    --target-role controller <"$state/message" \
    >"$state/process-ambiguous.out" 2>&1; then
    fail "ambiguous Codex process accepted"
fi

FAKE_SOURCE=riken FAKE_TARGET_ROLE=controller \
    run_helper send --source riken --target login --target-role controller \
    <"$state/message" >"$state/send.out"
grep -F -x \
    'AGENT_MESSAGE_SEND source=riken target=login target_role=controller status=submitted' \
    "$state/send.out" >/dev/null || fail "send output"
cmp -s "$state/message" "$state/ssh-message" ||
    fail "send message changed"
grep -F -- \
    '-x -o BatchMode=yes -o ClearAllForwardings=yes -o ForwardAgent=no login' \
    "$state/ssh-arguments" >/dev/null || fail "native SSH policy"
if grep -F "$message" "$state/ssh-arguments" >/dev/null; then
    fail "message leaked into SSH arguments"
fi

if run_helper send --source riken --target '../unsafe' \
    --target-role controller <"$state/message" \
    >"$state/unsafe-target.out" 2>&1; then
    fail "unsafe target accepted"
fi

printf '%s\n' 'remote agent communication tests: PASS'
