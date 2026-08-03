#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HELPER=$ROOT/shared/skills/remote-agent-communication/scripts/agent-message
SKILL=$ROOT/shared/skills/remote-agent-communication/SKILL.md
DELIVERY=$ROOT/shared/skills/remote-agent-communication/references/delivery.md
LOCAL_CODEX=$ROOT/shared/skills/remote-agent-communication/references/local-codex.md
REQUEST=$ROOT/shared/skills/remote-agent-communication/references/request.md
FALLBACK=$ROOT/shared/skills/remote-agent-communication/references/fallback.md
RUNTIME_POLICY=$ROOT/docs/agent-policy/managed-codex.md
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

for path in "$SKILL" "$DELIVERY" "$LOCAL_CODEX" "$REQUEST" "$FALLBACK" \
    "$RUNTIME_POLICY"; do
    [ -f "$path" ] && [ ! -L "$path" ] ||
        fail "missing routed communication resource: $path"
done
if grep -E 'capture-pane|pipe-pane|show-buffer' "$HELPER" >/dev/null; then
    fail "message transport may inspect pane content"
fi
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
grep -F 'send-local-claude --source local' "$DELIVERY" >/dev/null ||
    fail "Local Codex-to-Claude route guidance"
grep -F 'send-local-codex' "$LOCAL_CODEX" >/dev/null ||
    fail "Local Codex consumer route guidance"
grep -F 'read-local-codex-report' "$LOCAL_CODEX" >/dev/null ||
    fail "Local Codex report recovery guidance"
grep -F 'codex-thread-recovery --check --target personal' \
    "$LOCAL_CODEX" >/dev/null || fail "Local Codex active-turn preflight"
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
{
    printf '# target\twindow_index\twindow_name\tpane_index\tcanonical_repository\n'
    printf 'harness\t0\tcowork\t0\t@HARNESS_ROOT@\n'
    printf 'personal\t1\tcodex\t0\t%s/personal\n' "$home"
    printf 'students\t1\tcodex\t1\t%s/students\n' "$home"
} >"$state/codex-targets.tsv"

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
cp /dev/stdin "$FAKE_STATE/ssh-message"
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
    printf 'AGENT_MESSAGE_RECEIVE source=%s target_role=%s client=%s status=submitted\n' \
        "${FAKE_SOURCE:?}" "${FAKE_TARGET_ROLE:?}" "${FAKE_CLIENT:-codex}"
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
cp /dev/stdin "$FAKE_STATE/fallback-prompt"
printf '{"request_id":"%s","status":"complete","response":"verified clean"}\n' \
    "${FAKE_REPLY_REQUEST_ID:?}" >"$output"
EOF
chmod 755 "$home/.local/bin/harness-codex"

run_helper() {
    HOME=$home FAKE_STATE=$state \
        FAKE_SESSION=${FAKE_SESSION:-harness} \
        FAKE_ATTACHED=${FAKE_ATTACHED:-0} \
        FAKE_AMBIGUOUS=${FAKE_AMBIGUOUS:-0} \
        FAKE_CODEX_COUNT=${FAKE_CODEX_COUNT:-1} \
        FAKE_CLAUDE_COUNT=${FAKE_CLAUDE_COUNT:-1} \
        FAKE_TARGET_CLIENT=${FAKE_TARGET_CLIENT:-codex} \
        FAKE_CLIENT=${FAKE_CLIENT:-codex} \
        FAKE_REQUIRE_ALL=${FAKE_REQUIRE_ALL:-0} \
        FAKE_PANE_ROLE=${FAKE_PANE_ROLE:-harness} \
        FAKE_CLAUDE_ROLE=${FAKE_CLAUDE_ROLE:-harness} \
        FAKE_WINDOW_INDEX=${FAKE_WINDOW_INDEX:-} \
        FAKE_WINDOW_NAME=${FAKE_WINDOW_NAME:-} \
        FAKE_PANE_INDEX=${FAKE_PANE_INDEX:-} \
        FAKE_PANE_PATH=${FAKE_PANE_PATH:-} \
        FAKE_TTY=${FAKE_TTY:-/dev/pts/7} \
        FAKE_PASTE_FAIL=${FAKE_PASTE_FAIL:-0} \
        HARNESS_TESTING=1 \
        HARNESS_TEST_AGENT_MESSAGE_SETTLE_SECONDS=0 \
        HARNESS_TEST_AGENT_MESSAGE_TARGETS_FILE=$state/codex-targets.tsv \
        PATH="$fake_bin:/usr/bin:/bin" \
        python3 -B "$HELPER" "$@"
}

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
    'AGENT_MESSAGE_RECEIVE source=riken target_role=controller client=codex status=submitted' \
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

FAKE_SESSION=harness FAKE_ATTACHED=0 FAKE_TTY=/dev/ttys000 \
    FAKE_REQUIRE_ALL=1 \
    FAKE_WINDOW_INDEX=1 FAKE_WINDOW_NAME=codex FAKE_PANE_INDEX=0 \
    run_helper receive --source riken --target-role mac \
    <"$state/message" >"$state/modern-mac.out"
grep -F -x \
    'AGENT_MESSAGE_RECEIVE source=riken target_role=mac client=codex status=submitted' \
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
    'AGENT_MESSAGE_SEND source=riken target=login target_role=controller client=codex status=submitted' \
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
    'AGENT_MESSAGE_SEND source=riken target=login target_role=controller client=claude status=submitted' \
    "$state/claude-send.out" >/dev/null || fail "Claude send output"
grep -F -- '--client claude' "$state/ssh-arguments" >/dev/null ||
    fail "Claude client was not carried over SSH"

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
grep -F 'send-keys -t %0 C-m' "$state/operations" >/dev/null ||
    fail "local Claude separate submit"
if grep -F "$local_claude_message" "$state/operations" >/dev/null; then
    fail "local Claude message leaked into tmux arguments"
fi

if printf '%s\n' '[Agent: Riken Codex] wrong local source' |
    FAKE_TARGET_CLIENT=claude run_helper send-local-claude --source riken \
    >"$state/local-claude-source.out" 2>&1; then
    fail "non-Local source reached Local Claude"
fi
grep -F 'local Claude source must be local' \
    "$state/local-claude-source.out" >/dev/null ||
    fail "local Claude source rejection"

if printf '%s\n' '[Agent: Local Claude] false Codex attribution' |
    FAKE_TARGET_CLIENT=claude run_helper send-local-claude --source local \
    >"$state/local-claude-client.out" 2>&1; then
    fail "Claude-labelled message accepted from Codex route"
fi

if printf '%s\n' "$local_claude_message" |
    FAKE_TARGET_CLIENT=claude FAKE_CLAUDE_ROLE=students \
    run_helper send-local-claude --source local \
    >"$state/local-claude-role.out" 2>&1; then
    fail "wrong Local Claude pane role accepted"
fi
if printf '%s\n' "$local_claude_message" |
    FAKE_TARGET_CLIENT=claude FAKE_WINDOW_NAME=claude \
    run_helper send-local-claude --source local \
    >"$state/local-claude-window.out" 2>&1; then
    fail "wrong Local Claude window accepted"
fi
if printf '%s\n' "$local_claude_message" |
    FAKE_TARGET_CLIENT=claude FAKE_PANE_PATH=/tmp/not-harness \
    run_helper send-local-claude --source local \
    >"$state/local-claude-path.out" 2>&1; then
    fail "wrong Local Claude repository accepted"
fi
if printf '%s\n' "$local_claude_message" |
    FAKE_TARGET_CLIENT=claude FAKE_CLAUDE_COUNT=2 \
    run_helper send-local-claude --source local \
    >"$state/local-claude-process.out" 2>&1; then
    fail "ambiguous Local Claude process accepted"
fi
if printf '%s\n' "$local_claude_message" |
    FAKE_TARGET_CLIENT=claude FAKE_AMBIGUOUS=1 \
    run_helper send-local-claude --source local \
    >"$state/local-claude-ambiguous.out" 2>&1; then
    fail "ambiguous Local Claude pane accepted"
fi

local_codex_message='[Agent: Local Codex] diagnose the selected Personal queue'
ssh_calls_before=$(wc -l <"$state/ssh-calls")
(
    cd "$home/harness"
    printf '%s\n' "$local_codex_message" |
        FAKE_WINDOW_INDEX=1 FAKE_WINDOW_NAME=codex FAKE_PANE_INDEX=0 \
        FAKE_PANE_ROLE=personal FAKE_PANE_PATH=$home/personal \
        run_helper send-local-codex --source local --target personal \
        >"$state/local-codex.out"
)
grep -F -x \
    'AGENT_MESSAGE_LOCAL_CODEX_SEND source=local target=personal client=codex status=submitted' \
    "$state/local-codex.out" >/dev/null || fail "Local Personal output"
ssh_calls_after=$(wc -l <"$state/ssh-calls")
[ "$ssh_calls_before" -eq "$ssh_calls_after" ] ||
    fail "Local Personal delivery used SSH"
if grep -F "$local_codex_message" "$state/operations" >/dev/null; then
    fail "Local Personal message leaked into tmux arguments"
fi

ssh_calls_before=$(wc -l <"$state/ssh-calls")
(
    cd "$home/harness"
    FAKE_WINDOW_INDEX=1 FAKE_WINDOW_NAME=codex FAKE_PANE_INDEX=0 \
        FAKE_PANE_ROLE=personal FAKE_PANE_PATH=$home/personal \
        run_helper confirm-local-codex --source local --target personal \
        --request-id har388-stage-one --status accepted \
        --next-request-id har388-stage-two \
        >"$state/local-confirmation.out"
)
grep -F -x \
    'AGENT_MESSAGE_LOCAL_CODEX_CONFIRM source=local target=personal client=codex request_id=har388-stage-one confirmation=accepted next_request_id=har388-stage-two status=submitted' \
    "$state/local-confirmation.out" >/dev/null ||
    fail "Local confirmation output"
printf '%s\n%s' '[Agent: Local Codex]' \
    'confirmation request_id=har388-stage-one status=accepted next_request_id=har388-stage-two' \
    >"$state/expected-confirmation"
cmp -s "$state/expected-confirmation" "$state/last-message" ||
    fail "Local confirmation envelope changed"
ssh_calls_after=$(wc -l <"$state/ssh-calls")
[ "$ssh_calls_before" -eq "$ssh_calls_after" ] ||
    fail "Local confirmation used SSH"
if grep -F 'confirmation request_id=' "$state/operations" >/dev/null; then
    fail "Local confirmation leaked into tmux arguments"
fi

if (
    cd "$home/harness"
    FAKE_WINDOW_INDEX=1 FAKE_WINDOW_NAME=codex FAKE_PANE_INDEX=0 \
        FAKE_PANE_ROLE=personal FAKE_PANE_PATH=$home/personal \
        run_helper confirm-local-codex --source local --target personal \
        --request-id har388-stage-one --status accepted \
        >"$state/local-confirmation-missing-next.out" 2>&1
); then
    fail "continuing confirmation omitted its next request"
fi
if (
    cd "$home/harness"
    FAKE_WINDOW_INDEX=1 FAKE_WINDOW_NAME=codex FAKE_PANE_INDEX=0 \
        FAKE_PANE_ROLE=personal FAKE_PANE_PATH=$home/personal \
        run_helper confirm-local-codex --source local --target personal \
        --request-id har388-stage-one --status rejected \
        --next-request-id har388-stage-two \
        >"$state/local-confirmation-rejected-next.out" 2>&1
); then
    fail "rejected confirmation named a next request"
fi
if (
    cd "$home/harness"
    FAKE_WINDOW_INDEX=1 FAKE_WINDOW_NAME=codex FAKE_PANE_INDEX=0 \
        FAKE_PANE_ROLE=personal FAKE_PANE_PATH=$home/personal \
        run_helper confirm-local-codex --source personal --target personal \
        --request-id har388-stage-one --status accepted \
        --next-request-id har388-stage-two \
        >"$state/local-confirmation-source.out" 2>&1
); then
    fail "consumer sent a producer confirmation"
fi

if (
    cd "$home/harness"
    printf '%s\n' "$local_codex_message" |
        FAKE_WINDOW_INDEX=1 FAKE_WINDOW_NAME=codex FAKE_PANE_INDEX=0 \
        FAKE_PANE_ROLE=students FAKE_PANE_PATH=$home/personal \
        run_helper send-local-codex --source local --target personal \
        >"$state/local-codex-role.out" 2>&1
); then
    fail "wrong Local Personal pane role accepted"
fi

if (
    cd "$home/personal"
    printf '%s\n' '[Agent: Personal Codex] peer request' |
        FAKE_WINDOW_INDEX=1 FAKE_WINDOW_NAME=codex FAKE_PANE_INDEX=1 \
        FAKE_PANE_ROLE=students FAKE_PANE_PATH=$home/students \
        run_helper send-local-codex --source personal --target students \
        >"$state/local-codex-peer.out" 2>&1
); then
    fail "Local consumer-to-consumer route accepted"
fi

local_reply_id=har388-local-report-test
cat >"$state/local-report" <<EOF
[Agent: Personal Codex] request_id=$local_reply_id status=complete confirmation_required=yes
subtask: queue-diagnosis
result: selector is idle
evidence: six packets are gated
next_action: reconcile the first gate
EOF
(
    cd "$home/personal"
    FAKE_WINDOW_INDEX=0 FAKE_WINDOW_NAME=cowork FAKE_PANE_INDEX=0 \
    FAKE_PANE_ROLE=harness FAKE_PANE_PATH=$home/harness \
        run_helper reply-local-codex --source personal --target harness \
        --request-id "$local_reply_id" <"$state/local-report" \
        >"$state/local-report.out"
)
grep -F -x \
    "AGENT_MESSAGE_LOCAL_CODEX_REPLY source=personal target=harness client=codex request_id=$local_reply_id status=submitted" \
    "$state/local-report.out" >/dev/null || fail "Local report output"
local_report_state=$home/.local/state/harness/local-codex-reports/personal--$local_reply_id.report
LOCAL_REPORT_STATE=$local_report_state EXPECTED_REPORT=$state/local-report \
    python3 -B - <<'PY'
import os
import stat
from pathlib import Path

path = Path(os.environ["LOCAL_REPORT_STATE"])
expected = Path(os.environ["EXPECTED_REPORT"]).read_bytes().rstrip(b"\n")
info = path.lstat()
assert stat.S_ISREG(info.st_mode)
assert stat.S_IMODE(info.st_mode) == 0o600
assert info.st_nlink == 1
assert path.read_bytes() == expected
PY
(
    cd "$home/harness"
    run_helper read-local-codex-report --source personal --target harness \
        --request-id "$local_reply_id" >"$state/local-report-read.out"
)
cmp -s "$state/local-report" "$state/local-report-read.out" ||
    fail "preserved Local report readback changed"

# Retrying the exact report is idempotent, but changing bytes under the same
# request ID cannot silently replace the controller's recovery copy.
(
    cd "$home/personal"
    FAKE_WINDOW_INDEX=0 FAKE_WINDOW_NAME=cowork FAKE_PANE_INDEX=0 \
    FAKE_PANE_ROLE=harness FAKE_PANE_PATH=$home/harness \
        run_helper reply-local-codex --source personal --target harness \
        --request-id "$local_reply_id" <"$state/local-report" \
        >"$state/local-report-duplicate.out"
)
if (
    cd "$home/personal"
    sed 's/selector is idle/selector changed/' "$state/local-report" |
        FAKE_WINDOW_INDEX=0 FAKE_WINDOW_NAME=cowork FAKE_PANE_INDEX=0 \
        FAKE_PANE_ROLE=harness FAKE_PANE_PATH=$home/harness \
        run_helper reply-local-codex --source personal --target harness \
        --request-id "$local_reply_id" \
        >"$state/local-report-changed.out" 2>&1
); then
    fail "changed Local report replaced an existing request ID"
fi
grep -F 'Local Codex report id already has different bytes' \
    "$state/local-report-changed.out" >/dev/null ||
    fail "changed Local report rejection reason"

if (
    cd "$home/personal"
    sed '/^evidence:/d' "$state/local-report" |
        FAKE_WINDOW_INDEX=0 FAKE_WINDOW_NAME=cowork FAKE_PANE_INDEX=0 \
        FAKE_PANE_ROLE=harness FAKE_PANE_PATH=$home/harness \
        run_helper reply-local-codex --source personal --target harness \
        --request-id "$local_reply_id" >"$state/local-report-shape.out" 2>&1
); then
    fail "malformed Local subtask report accepted"
fi

if (
    cd "$home/harness"
    FAKE_WINDOW_INDEX=0 FAKE_WINDOW_NAME=cowork FAKE_PANE_INDEX=0 \
    FAKE_PANE_ROLE=harness FAKE_PANE_PATH=$home/harness \
        run_helper reply-local-codex --source personal --target harness \
        --request-id "$local_reply_id" <"$state/local-report" \
        >"$state/local-report-cwd.out" 2>&1
); then
    fail "false Local consumer source repository accepted"
fi

if (
    cd "$home/personal"
    run_helper read-local-codex-report --source personal --target harness \
        --request-id "$local_reply_id" \
        >"$state/local-report-read-cwd.out" 2>&1
); then
    fail "Local report reader accepted a consumer cwd"
fi

(
    cd "$home/harness"
    FAKE_WINDOW_INDEX=1 FAKE_WINDOW_NAME=codex FAKE_PANE_INDEX=0 \
    FAKE_PANE_ROLE=personal FAKE_PANE_PATH=$home/personal \
        run_helper confirm-local-codex --source local --target personal \
        --request-id "$local_reply_id" --status accepted \
        --next-request-id har388-local-report-next \
        >"$state/local-report-confirmation.out"
)
[ ! -e "$local_report_state" ] ||
    fail "matching Local confirmation retained report state"
if (
    cd "$home/harness"
    run_helper read-local-codex-report --source personal --target harness \
        --request-id "$local_reply_id" \
        >"$state/local-report-read-missing.out" 2>&1
); then
    fail "acknowledged Local report remained readable"
fi
grep -F 'Local Codex report is unavailable' \
    "$state/local-report-read-missing.out" >/dev/null ||
    fail "missing Local report recovery reason"

# Preserve the validated report before a failed terminal insertion so the
# controller can recover it without another consumer prompt.
failed_reply_id=har388-local-report-injection-failure
sed "s/$local_reply_id/$failed_reply_id/" "$state/local-report" \
    >"$state/local-report-failed"
if (
    cd "$home/personal"
    FAKE_PASTE_FAIL=1 FAKE_WINDOW_INDEX=0 FAKE_WINDOW_NAME=cowork \
    FAKE_PANE_INDEX=0 FAKE_PANE_ROLE=harness \
    FAKE_PANE_PATH=$home/harness \
        run_helper reply-local-codex --source personal --target harness \
        --request-id "$failed_reply_id" <"$state/local-report-failed" \
        >"$state/local-report-injection-failed.out" 2>&1
); then
    fail "failed Local report insertion returned success"
fi
(
    cd "$home/harness"
    run_helper read-local-codex-report --source personal --target harness \
        --request-id "$failed_reply_id" \
        >"$state/local-report-failed-read.out"
)
cmp -s "$state/local-report-failed" "$state/local-report-failed-read.out" ||
    fail "failed Local insertion lost the preserved report"
(
    cd "$home/harness"
    FAKE_WINDOW_INDEX=1 FAKE_WINDOW_NAME=codex FAKE_PANE_INDEX=0 \
    FAKE_PANE_ROLE=personal FAKE_PANE_PATH=$home/personal \
        run_helper confirm-local-codex --source local --target personal \
        --request-id "$failed_reply_id" --status rejected \
        >"$state/local-report-failed-confirmation.out"
)

reply_id=t307-home-request-test
request='[Agent: Local Codex] inspect the current revision and worktree'
printf %s "$request" >"$state/request-message"
(
    cd "$home/harness"
    FAKE_SESSION=harness-codex-resume FAKE_TTY=/dev/ttys000 \
        FAKE_REPLY_REQUEST_ID=$reply_id \
        run_helper request-reply --source home --controller-source local \
        --request-id "$reply_id" <"$state/request-message" \
        >"$state/request-reply.out"
)
grep -F -x \
    "[Agent: Home Codex] request_id=$reply_id status=complete responder=exec-request" \
    "$state/request-reply.out" >/dev/null || fail "request reply prefix"
grep -F -x 'verified clean' "$state/request-reply.out" >/dev/null ||
    fail "request reply body"
grep -F 'Process the following identified Local-agent request' \
    "$state/fallback-prompt" >/dev/null || fail "request execution prompt"
grep -F -x "$request" "$state/fallback-prompt" >/dev/null ||
    fail "request payload missing from prompt"
if [ -s "$state/ssh-message" ] &&
    grep -F "$request" "$state/ssh-arguments" >/dev/null; then
    fail "request leaked into SSH arguments"
fi
if find "$home/.local/state/harness" -maxdepth 1 \
    -name '.agent-reply-*' -print -quit | grep . >/dev/null; then
    fail "request private residue"
fi

FAKE_SSH_MODE=response FAKE_RESPONSE_NAME=Home \
    FAKE_REPLY_REQUEST_ID=$reply_id FAKE_RESPONDER=exec-request \
    run_helper request --source local --target home \
    --request-id "$reply_id" <"$state/request-message" \
    >"$state/request.out"
grep -F -x \
    "AGENT_MESSAGE_REQUEST source=local target=home request_id=$reply_id status=submitted" \
    "$state/request.out" >/dev/null || fail "request controller output"
cmp -s "$state/request-message" "$state/ssh-message" ||
    fail "same-channel request message changed"
grep -F 'request-reply --source home --controller-source local' \
    "$state/ssh-arguments" >/dev/null || fail "request native command"
grep -F -- '-o ForwardAgent=no home' "$state/ssh-arguments" >/dev/null ||
    fail "request disabled agent forwarding"
if grep -F 'reply-target' "$state/ssh-arguments" >/dev/null ||
    grep -F 'reply-role' "$state/ssh-arguments" >/dev/null; then
    fail "request retained reverse reply route"
fi

fallback_id=t307-home-fallback-test
(
    cd "$home/harness"
    FAKE_SESSION=harness-codex-resume FAKE_TTY=/dev/ttys000 \
        FAKE_REPLY_REQUEST_ID=$fallback_id \
        run_helper fallback-reply --source home --request-id "$fallback_id" \
        >"$state/fallback-reply.out"
)
grep -F -x \
    "[Agent: Home Codex] request_id=$fallback_id status=complete responder=exec-fallback" \
    "$state/fallback-reply.out" >/dev/null || fail "fallback reply prefix"
grep -F -x 'verified clean' "$state/fallback-reply.out" >/dev/null ||
    fail "fallback reply body"
grep -F 'Do not redo work, call tools, or modify files' \
    "$state/fallback-prompt" >/dev/null || fail "fallback read-only prompt"
if find "$home/.local/state/harness" -maxdepth 1 \
    -name '.agent-reply-*' -print -quit | grep . >/dev/null; then
    fail "fallback private residue"
fi

FAKE_SSH_MODE=response FAKE_RESPONSE_NAME=Home \
    FAKE_REPLY_REQUEST_ID=$fallback_id FAKE_RESPONDER=exec-fallback \
    run_helper fallback --source local --target home \
    --request-id "$fallback_id" >"$state/fallback.out"
grep -F -x \
    "AGENT_MESSAGE_FALLBACK source=local target=home request_id=$fallback_id status=submitted" \
    "$state/fallback.out" >/dev/null || fail "fallback controller output"
grep -F 'fallback-reply --source home' "$state/ssh-arguments" >/dev/null ||
    fail "fallback native command"
if grep -F 'reply-target' "$state/ssh-arguments" >/dev/null ||
    grep -F 'reply-role' "$state/ssh-arguments" >/dev/null; then
    fail "fallback retained reverse reply route"
fi
FAKE_SSH_MODE=response FAKE_RESPONSE_NAME=Home \
    FAKE_REPLY_REQUEST_ID=$fallback_id FAKE_RESPONDER=exec-fallback \
    FAKE_SSH_FAIL=1 \
    run_helper fallback --source local --target home \
    --request-id "$fallback_id" >"$state/fallback-classified.out" 2>&1 &&
    fail "failed fallback accepted"
grep -F 'remote same-channel response failed (unclassified)' \
    "$state/fallback-classified.out" >/dev/null ||
    fail "fallback failure classification"
FAKE_SSH_MODE=response FAKE_RESPONSE_NAME=Home \
    FAKE_REPLY_REQUEST_ID=wrong-request FAKE_RESPONDER=exec-request \
    run_helper request --source local --target home \
    --request-id "$reply_id" <"$state/request-message" \
    >"$state/request-wrong-id.out" 2>&1 &&
    fail "request accepted changed response id"
grep -F 'remote response request id changed' \
    "$state/request-wrong-id.out" >/dev/null ||
    fail "request id mismatch classification"
if run_helper fallback --source local --target home \
    --request-id '../unsafe' >"$state/fallback-unsafe.out" 2>&1; then
    fail "unsafe fallback request id accepted"
fi

python3 -m json.tool \
    "$ROOT/shared/skills/remote-agent-communication/references/reply.schema.json" \
    >/dev/null || fail "fallback response schema"

# A Claude sender may address a Codex thread, but only with honest
# attribution: the prefix client must match the declared --client.
if printf '%s\n' '[Agent: Riken Claude] claude sender' |
    run_helper receive --source riken --target-role controller \
    --client claude >"$state/claude-ok.out" 2>&1; then
    grep -F 'client=claude' "$state/claude-ok.out" >/dev/null ||
        fail "claude receive did not report its client"
else
    fail "an honestly attributed Claude message was rejected"
fi

if printf '%s\n' '[Agent: Riken Claude] mislabelled' |
    run_helper receive --source riken --target-role controller \
    >"$state/claude-as-codex.out" 2>&1; then
    fail "a Claude message was accepted as Codex"
fi
grep -F 'message client does not match the declared sender client' \
    "$state/claude-as-codex.out" >/dev/null || fail "client mismatch rejection"

if printf '%s\n' '[Agent: Riken Codex] mislabelled' |
    run_helper receive --source riken --target-role controller \
    --client claude >"$state/codex-as-claude.out" 2>&1; then
    fail "a Codex message was accepted as Claude"
fi

printf '%s\n' 'remote agent communication tests: PASS'
