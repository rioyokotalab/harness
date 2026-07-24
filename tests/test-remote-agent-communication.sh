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

grep -F 'REPLY_REQUIRED request_id=ID reply_target=ALIAS reply_role=ROLE' \
    "$ROOT/AGENTS.md" >/dev/null || fail "shared required-reply policy"
grep -F 'report that status and the' "$ROOT/AGENTS.md" >/dev/null ||
    fail "blocked reply policy"
grep -F 'Do not put `submission=succeeded` in the response payload' \
    "$ROOT/shared/skills/remote-agent-communication/SKILL.md" >/dev/null ||
    fail "reply submission semantics"
grep -F 'same-channel `request` flow' "$ROOT/AGENTS.md" >/dev/null ||
    fail "required-response same-channel policy"
grep -F 'does not use `ssh login`' \
    "$ROOT/shared/skills/remote-agent-communication/SKILL.md" >/dev/null ||
    fail "request reverse-route independence"

home=$TEST_ROOT/home
fake_bin=$TEST_ROOT/bin
state=$TEST_ROOT/state
mkdir -p "$home/harness" "$home/.local/bin" "$fake_bin" "$state"

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
    printf 'AGENT_MESSAGE_RECEIVE source=%s target_role=%s status=submitted\n' \
        "${FAKE_SOURCE:?}" "${FAKE_TARGET_ROLE:?}"
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

printf '%s\n' 'remote agent communication tests: PASS'
