#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HELPER=$ROOT/shared/skills/remote-agent-communication/scripts/agent-message
SKILL=$ROOT/shared/skills/remote-agent-communication/SKILL.md
DELIVERY=$ROOT/shared/skills/remote-agent-communication/references/delivery.md
LOCAL_AGENT=$ROOT/shared/skills/remote-agent-communication/references/local-agent.md
LOCAL_PROTOCOL=$ROOT/shared/skills/remote-agent-communication/references/local-agent.protocol
REQUEST=$ROOT/shared/skills/remote-agent-communication/references/request.md
FALLBACK=$ROOT/shared/skills/remote-agent-communication/references/fallback.md
RUNTIME_POLICY=$ROOT/docs/agent-policy/managed-codex.md
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/remote-agent-communication-test.XXXXXX")

fail() { echo "FAIL: $*" >&2; exit 1; }
cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEST_ROOT" ]; then
        "$CLEANUP" "$ROOT/bin/harness" "$TEMP_BASE" "$TEST_ROOT" \
            "$TEMP_BASE" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then status=1; fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

for path in "$SKILL" "$DELIVERY" "$LOCAL_AGENT" "$LOCAL_PROTOCOL" "$REQUEST" "$FALLBACK" \
    "$RUNTIME_POLICY"; do
    [ -f "$path" ] && [ ! -L "$path" ] ||
        fail "missing routed communication resource: $path"
done
if grep -E 'capture-pane|pipe-pane|show-buffer' "$HELPER" >/dev/null; then
    fail "message transport may inspect pane content"
fi
grep -F 'Producer pane inspection is a separate' "$SKILL" >/dev/null ||
    fail "producer inspection and content-blind transport are conflated"
HELPER_PATH=$HELPER python3 -B - <<'PY'
import os
import runpy

namespace = runpy.run_path(os.environ["HELPER_PATH"])
settle = namespace["injection_settle_seconds"]
error = namespace["MessageError"]
assert settle(namespace["PASTE_SETTLE_SECONDS"]) == 1
os.environ["HARNESS_TEST_AGENT_MESSAGE_SETTLE_SECONDS"] = "0"
try:
    settle(namespace["SUBMIT_SETTLE_SECONDS"])
except error:
    pass
else:
    raise AssertionError("test settle override escaped production boundary")
os.environ["HARNESS_TESTING"] = "1"
assert settle(namespace["SUBMIT_SETTLE_SECONDS"]) == 0
PY

grep -F 'REPLY_REQUIRED request_id=ID reply_target=ALIAS reply_role=ROLE' \
    "$RUNTIME_POLICY" >/dev/null || fail "shared required-reply policy"
grep -F 'report the status and reason' "$RUNTIME_POLICY" >/dev/null ||
    fail "blocked reply policy"
grep -F '`submission=succeeded` in the response payload' "$DELIVERY" \
    >/dev/null ||
    fail "reply submission semantics"
grep -F 'same-channel `request`' "$RUNTIME_POLICY" >/dev/null ||
    fail "required-response same-channel policy"
grep -F '`[Agent: NAME Claude]`' "$RUNTIME_POLICY" >/dev/null ||
    fail "Claude-originated attribution policy"
grep -F 'send-local-agent --source local --source-client codex' \
    "$DELIVERY" >/dev/null || fail "Local cross-client route guidance"
grep -F 'reply-local-agent' "$LOCAL_AGENT" >/dev/null ||
    fail "Local agent consumer route guidance"
grep -F 'read-local-agent-report' "$LOCAL_AGENT" >/dev/null ||
    fail "Local agent report recovery guidance"
grep -F 'LOCAL_REPLY_REQUIRED request_id=ID reply_target=harness max_replies=1' \
    "$RUNTIME_POLICY" >/dev/null || fail "Local consumer reply policy"
grep -F 'does not use `ssh login`' \
    "$REQUEST" >/dev/null ||
    fail "request reverse-route independence"
grep -F 'Never invoke it twice' "$FALLBACK" >/dev/null ||
    fail "fallback replay refusal"

home=$TEST_ROOT/home
fake_bin=$TEST_ROOT/bin
state=$TEST_ROOT/state
mkdir -p "$home/harness" "$home/personal" "$home/students" \
    "$home/.local/bin" "$fake_bin" "$state"
for repository in harness personal students; do
    mkdir -p "$home/$repository/.agents/skills" \
        "$home/$repository/.claude/skills"
    ln -s "$ROOT/shared/skills/remote-agent-communication" \
        "$home/$repository/.agents/skills/remote-agent-communication"
    ln -s "$ROOT/shared/skills/remote-agent-communication" \
        "$home/$repository/.claude/skills/remote-agent-communication"
done
{
    printf '# target\tclient\twindow_index\twindow_name\tpane_index\tcanonical_repository\n'
    printf 'harness\tcodex\t0\tcowork\t0\t@HARNESS_ROOT@\n'
    printf 'harness\tclaude\t0\tcowork\t1\t@HARNESS_ROOT@\n'
    printf 'personal\tcodex\t1\tcodex\t0\t%s/personal\n' "$home"
    printf 'personal\tclaude\t2\tclaude\t0\t%s/personal\n' "$home"
    printf 'students\tcodex\t1\tcodex\t1\t%s/students\n' "$home"
    printf 'students\tclaude\t2\tclaude\t1\t%s/students\n' "$home"
} >"$state/agent-targets.tsv"

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
        all_session=0
        [ "${1:-}" = -s ] && all_session=1
        tty=${FAKE_TTY:-/dev/pts/7}
        pane_path=${FAKE_PANE_PATH:-$HOME/harness}
        if [ "${FAKE_REQUIRE_ALL:-0}" -eq 1 ] && [ "$all_session" -ne 1 ]; then
            window_index=0
            window_name=claude
            pane_index=0
            role=
            claude_role=harness
        elif [ "${FAKE_TARGET_CLIENT:-codex}" = claude ]; then
            window_index=${FAKE_WINDOW_INDEX:-0}
            window_name=${FAKE_WINDOW_NAME:-cowork}
            pane_index=${FAKE_PANE_INDEX:-1}
            role=
            claude_role=${FAKE_CLAUDE_ROLE:-harness}
        else
            window_index=${FAKE_WINDOW_INDEX:-0}
            window_name=${FAKE_WINDOW_NAME:-cowork}
            pane_index=${FAKE_PANE_INDEX:-0}
            role=${FAKE_PANE_ROLE:-harness}
            claude_role=
        fi
        if [ "${FAKE_AMBIGUOUS:-0}" -eq 1 ]; then
            printf '%%0\t0\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
                "$pane_path" "$tty" "$window_index" "$window_name" \
                "$pane_index" "$role" "$claude_role"
            printf '%%1\t0\t%s\t/dev/pts/8\t%s\t%s\t%s\t%s\t%s\n' \
                "$pane_path" "$window_index" "$window_name" "$pane_index" \
                "$role" "$claude_role"
        else
            printf '%%0\t0\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
                "$pane_path" "$tty" "$window_index" "$window_name" \
                "$pane_index" "$role" "$claude_role"
        fi
        ;;
    display-message)
        printf '%s\n' "${FAKE_ATTACHED:-0}"
        ;;
    load-buffer)
        printf 'load-buffer %s\n' "$*" >>"$FAKE_STATE/operations"
        tee "$FAKE_STATE/last-message" | wc -c >"$FAKE_STATE/message-bytes"
        ;;
    paste-buffer)
        printf 'paste-buffer %s\n' "$*" >>"$FAKE_STATE/operations"
        [ "${FAKE_PASTE_FAIL:-0}" -eq 0 ] || exit 1
        if ! mkdir "$FAKE_STATE/injection-active" 2>/dev/null; then
            : >"$FAKE_STATE/injection-overlap"
        fi
        ;;
    delete-buffer)
        printf 'delete-buffer %s\n' "$*" >>"$FAKE_STATE/operations"
        ;;
    send-keys)
        printf 'send-keys %s\n' "$*" >>"$FAKE_STATE/operations"
        rmdir "$FAKE_STATE/injection-active" 2>/dev/null || :
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
if [ "${FAKE_TARGET_CLIENT:-codex}" = claude ]; then
    if [ "${4:-}" = args= ]; then
        printf 'claude --permission-mode %s --model fable\ncodex\n' \
            "${FAKE_CLAUDE_PERMISSION_MODE:-bypassPermissions}"
        exit 0
    fi
    if [ "${FAKE_CLAUDE_COUNT:-1}" -eq 2 ]; then
        printf 'claude\nclaude\n'
    elif [ "${FAKE_CLAUDE_COUNT:-1}" -eq 0 ]; then
        printf 'sh\n'
    else
        printf 'claude\ncodex\n'
    fi
elif [ "${FAKE_CODEX_COUNT:-1}" -eq 2 ]; then
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
printf 'call\n' >>"$FAKE_STATE/ssh-calls"
cp -f /dev/stdin "$FAKE_STATE/ssh-message"
if [ "${FAKE_SSH_FAIL:-0}" -eq 1 ]; then
    printf 'unexpected remote failure\n' >&2
    exit 1
fi
if [ "${FAKE_SSH_MODE:-send}" = response ]; then
    printf '[Agent: %s Codex] request_id=%s status=complete responder=%s\n' \
        "${FAKE_RESPONSE_NAME:?}" "${FAKE_REPLY_REQUEST_ID:?}" \
        "${FAKE_RESPONDER:?}"
    printf 'verified clean\n'
else
    remote_command=
    for argument in "$@"; do remote_command=$argument; done
    set -f
    set -- $remote_command
    response_client=codex
    response_target_client=codex
    previous=
    for argument in "$@"; do
        case "$previous" in
            --client) response_client=$argument ;;
            --target-client) response_target_client=$argument ;;
        esac
        previous=$argument
    done
    printf 'AGENT_MESSAGE_RECEIVE source=%s target_role=%s client=%s target_client=%s status=submitted\n' \
        "${FAKE_SOURCE:?}" "${FAKE_TARGET_ROLE:?}" "$response_client" \
        "$response_target_client"
fi
EOF
chmod 755 "$fake_bin/ssh"

cat >"$home/.local/bin/harness-codex" <<'EOF'
#!/bin/sh
set -eu
: "${FAKE_STATE:?}"
output=
while [ "$#" -gt 0 ]; do
    case "$1" in
        -o) output=$2; shift 2 ;;
        *) shift ;;
    esac
done
[ -n "$output" ]
cp -f /dev/stdin "$FAKE_STATE/fallback-prompt"
printf '{"request_id":"%s","status":"complete","response":"verified clean"}\n' \
    "${FAKE_REPLY_REQUEST_ID:?}" >"$output"
EOF
chmod 755 "$home/.local/bin/harness-codex"

cat >"$fake_bin/run_helper" <<'EOF'
#!/bin/sh
resolved_client=${FAKE_CLIENT:-codex}
resolved_target_client=${FAKE_TARGET_CLIENT:-codex}
previous=
for argument in "$@"; do
    case "$previous" in
        --client) resolved_client=$argument ;;
        --target-client) resolved_target_client=$argument ;;
    esac
    previous=$argument
done
exec env \
    HOME="$HARNESS_TEST_HELPER_HOME" \
    FAKE_STATE="$HARNESS_TEST_HELPER_STATE" \
    FAKE_SESSION="${FAKE_SESSION:-harness}" \
    FAKE_ATTACHED="${FAKE_ATTACHED:-0}" \
    FAKE_AMBIGUOUS="${FAKE_AMBIGUOUS:-0}" \
    FAKE_CODEX_COUNT="${FAKE_CODEX_COUNT:-1}" \
    FAKE_CLAUDE_COUNT="${FAKE_CLAUDE_COUNT:-1}" \
    FAKE_CLAUDE_PERMISSION_MODE="${FAKE_CLAUDE_PERMISSION_MODE:-bypassPermissions}" \
    FAKE_TARGET_CLIENT="$resolved_target_client" \
    FAKE_CLIENT="$resolved_client" \
    FAKE_REQUIRE_ALL="${FAKE_REQUIRE_ALL:-0}" \
    FAKE_PANE_ROLE="${FAKE_PANE_ROLE:-harness}" \
    FAKE_CLAUDE_ROLE="${FAKE_CLAUDE_ROLE:-harness}" \
    FAKE_WINDOW_INDEX="${FAKE_WINDOW_INDEX:-}" \
    FAKE_WINDOW_NAME="${FAKE_WINDOW_NAME:-}" \
    FAKE_PANE_INDEX="${FAKE_PANE_INDEX:-}" \
    FAKE_PANE_PATH="${FAKE_PANE_PATH:-}" \
    FAKE_TTY="${FAKE_TTY:-/dev/pts/7}" \
    FAKE_PASTE_FAIL="${FAKE_PASTE_FAIL:-0}" \
    HARNESS_TESTING=1 \
    HARNESS_TEST_AGENT_MESSAGE_SETTLE_SECONDS=0 \
    HARNESS_TEST_AGENT_MESSAGE_TARGETS_FILE="$HARNESS_TEST_HELPER_TARGETS" \
    PATH="$HARNESS_TEST_HELPER_BIN:/usr/bin:/bin" \
    python3 -B "$HARNESS_TEST_HELPER" "$@"
EOF
chmod 755 "$fake_bin/run_helper"
HARNESS_TEST_HELPER_HOME=$home
HARNESS_TEST_HELPER_STATE=$state
HARNESS_TEST_HELPER_TARGETS=$state/agent-targets.tsv
HARNESS_TEST_HELPER_BIN=$fake_bin
HARNESS_TEST_HELPER=$HELPER
export HARNESS_TEST_HELPER_HOME HARNESS_TEST_HELPER_STATE
export HARNESS_TEST_HELPER_TARGETS HARNESS_TEST_HELPER_BIN HARNESS_TEST_HELPER
PATH=$fake_bin:/usr/bin:/bin
export PATH

message='[Agent: Riken Codex] controller experiment'
printf %s "$message" >"$state/message"
if HOME=$home FAKE_STATE=$state FAKE_SESSION=harness \
    FAKE_PANE_ROLE=harness FAKE_TTY=/dev/pts/7 \
    HARNESS_TEST_AGENT_MESSAGE_SETTLE_SECONDS=0 \
    PATH="$fake_bin:/usr/bin:/bin" \
    python3 -B "$HELPER" receive --source riken --target-role controller \
    <"$state/message" >"$state/test-settle-production.out" 2>&1; then
    fail "test settle override was accepted outside test mode"
fi
grep -F 'agent-message settle override is test-only' \
    "$state/test-settle-production.out" >/dev/null ||
    fail "test settle override boundary"
printf '%s\n' "$message" |
    run_helper receive --source riken --target-role controller \
    >"$state/controller.out"
grep -F -x \
    'AGENT_MESSAGE_RECEIVE source=riken target_role=controller client=codex target_client=codex status=submitted' \
    "$state/controller.out" >/dev/null || fail "controller receive output"
grep -F 'load-buffer ' "$state/operations" >/dev/null ||
    fail "private buffer load"
grep -F 'paste-buffer ' "$state/operations" >/dev/null ||
    fail "private buffer paste"
grep -F 'send-keys -t %0 Enter' "$state/operations" >/dev/null ||
    fail "separate submit"
if grep -F "$message" "$state/operations" >/dev/null; then
    fail "message leaked into tmux arguments"
fi
[ "$(tr -d ' ' <"$state/message-bytes")" -eq "${#message}" ] ||
    fail "message byte delivery"

maximum=$state/maximum-message
awk 'BEGIN {
    prefix = "[Agent: Riken Codex] "
    printf "%s", prefix
    for (i = length(prefix); i < 4096; i++) printf "x"
}' >"$maximum"
: >"$state/operations"
run_helper receive --source riken --target-role controller \
    <"$maximum" >"$state/maximum.out"
[ "$(tr -d ' ' <"$state/message-bytes")" -eq 4096 ] ||
    fail "maximum message byte delivery"
[ "$(grep -F -c -x 'send-keys -t %0 Enter' "$state/operations")" -eq 2 ] ||
    fail "maximum Codex message two-step named submit"

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

FAKE_SESSION=harness FAKE_ATTACHED=0 FAKE_TTY=/dev/ttys000 \
    FAKE_REQUIRE_ALL=1 \
    FAKE_WINDOW_INDEX=1 FAKE_WINDOW_NAME=codex FAKE_PANE_INDEX=0 \
    run_helper receive --source riken --target-role mac \
    <"$state/message" >"$state/modern-mac.out"
grep -F -x \
    'AGENT_MESSAGE_RECEIVE source=riken target_role=mac client=codex target_client=codex status=submitted' \
    "$state/modern-mac.out" >/dev/null || fail "modern Mac receive output"
if FAKE_SESSION=harness FAKE_ATTACHED=0 FAKE_TTY=/dev/ttys000 \
    FAKE_WINDOW_INDEX=0 FAKE_WINDOW_NAME=cowork FAKE_PANE_INDEX=0 \
    run_helper receive --source riken --target-role mac \
    <"$state/message" >"$state/modern-mac-wrong-pane.out" 2>&1; then
    fail "wrong modern Mac pane accepted"
fi

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
if FAKE_PANE_ROLE=students run_helper receive --source riken \
    --target-role controller <"$state/message" \
    >"$state/wrong-pane-role.out" 2>&1; then
    fail "wrong controller pane role accepted"
fi

(
    printf '%s\n' '[Agent: Riken Codex] concurrent one' |
        run_helper receive --source riken --target-role controller \
        >"$state/concurrent-one.out"
) &
first_receive=$!
(
    printf '%s\n' '[Agent: Home Codex] concurrent two' |
        run_helper receive --source home --target-role controller \
        >"$state/concurrent-two.out"
) &
second_receive=$!
wait "$first_receive"
wait "$second_receive"
[ ! -e "$state/injection-overlap" ] ||
    fail "concurrent prompt injections overlapped"

FAKE_SOURCE=riken FAKE_TARGET_ROLE=controller \
    run_helper send --source riken --target login --target-role controller \
    <"$state/message" >"$state/send.out"
grep -F -x \
    'AGENT_MESSAGE_SEND source=riken target=login target_role=controller client=codex target_client=codex status=submitted' \
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

claude_sender='[Agent: Riken Claude] cross-client send'
FAKE_SOURCE=riken FAKE_TARGET_ROLE=controller FAKE_CLIENT=claude \
    run_helper send --source riken --target login --target-role controller \
    --client claude <<EOF >"$state/claude-send.out"
$claude_sender
EOF
grep -F -x \
    'AGENT_MESSAGE_SEND source=riken target=login target_role=controller client=claude target_client=codex status=submitted' \
    "$state/claude-send.out" >/dev/null || fail "Claude send output"
grep -F -- '--client claude' "$state/ssh-arguments" >/dev/null ||
    fail "Claude client was not carried over SSH"

remote_claude='[Agent: Local Claude] remote Claude destination'
FAKE_SOURCE=local FAKE_TARGET_ROLE=mac FAKE_CLIENT=claude \
    FAKE_TARGET_CLIENT=claude \
    run_helper send --source local --target riken --target-role mac \
    --client claude --target-client claude <<EOF >"$state/remote-claude.out"
$remote_claude
EOF
grep -F -x \
    'AGENT_MESSAGE_SEND source=local target=riken target_role=mac client=claude target_client=claude status=submitted' \
    "$state/remote-claude.out" >/dev/null || fail "remote Claude output"
grep -F -- '--target-client claude' "$state/ssh-arguments" >/dev/null ||
    fail "remote Claude destination was not carried over SSH"

local_claude_message='[Agent: Local Codex] review T-365 and reply once'
ssh_calls_before=$(wc -l <"$state/ssh-calls")
printf '%s\n' "$local_claude_message" |
    FAKE_TARGET_CLIENT=claude run_helper send-local-claude --source local \
    >"$state/local-claude.out"
grep -F -x \
    'AGENT_MESSAGE_LOCAL_CLAUDE source=local target=local client=codex status=submitted' \
    "$state/local-claude.out" >/dev/null || fail "local Claude output"
ssh_calls_after=$(wc -l <"$state/ssh-calls")
[ "$ssh_calls_before" -eq "$ssh_calls_after" ] ||
    fail "local Claude delivery used SSH"
grep -F 'send-keys -t %0 Enter' "$state/operations" >/dev/null ||
    fail "local Claude separate submit"
if grep -F "$local_claude_message" "$state/operations" >/dev/null; then
    fail "local Claude message leaked into tmux arguments"
fi

# The remaining historical mutation matrix is intentionally excluded from the
# default owner. Exact receive, remote send, cross-client send, local send,
# identity rejection, attachment refusal, and argument-confidentiality
# contracts above cover the live transport without replaying every equivalent
# malformed combination.
printf '%s\n' 'remote agent communication tests: PASS'
exit 0
