#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/harness-thread-recovery-test.XXXXXX")
server_pid=
control_socket=

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -n "$server_pid" ] && kill -0 "$server_pid" 2>/dev/null; then
        kill -TERM "$server_pid" 2>/dev/null || true
        wait "$server_pid" 2>/dev/null || true
    fi
    if [ -n "$control_socket" ] && [ -S "$control_socket" ]; then
        unlink "$control_socket" || cleanup_failed=1
    fi
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

runtime=$TEST_ROOT/runtime
codex_home=$TEST_ROOT/codex
sessions=$codex_home/sessions/2026/07/27
message_state=$TEST_ROOT/message-state
target_harness=$TEST_ROOT/repositories/harness
target_students=$TEST_ROOT/repositories/students
target_personal=$TEST_ROOT/repositories/personal
target_profile=$TEST_ROOT/targets.tsv
mkdir -p "$runtime" "$sessions" "$message_state"
for repository in "$target_harness" "$target_students" "$target_personal"; do
    mkdir -p "$repository/.codex"
    git -C "$repository" init -q -b main
    printf '%s\n' 'model = "gpt-5.6-sol"' \
        >"$repository/.codex/config.toml"
done
{
    printf '# target\twindow_index\twindow_name\tpane_index\tcanonical_repository\n'
    printf 'harness\t0\tcowork\t0\t@HARNESS_ROOT@\n'
    printf 'personal\t1\tcodex\t0\t%s\n' "$target_personal"
    printf 'students\t1\tcodex\t1\t%s\n' "$target_students"
} >"$target_profile"
chmod 700 "$runtime" "$codex_home" "$codex_home/sessions" \
    "$codex_home/sessions/2026" "$codex_home/sessions/2026/07" \
    "$sessions" "$message_state"

backend=$TEST_ROOT/recovery-backend
cat >"$backend" <<'EOF'
#!/bin/sh
set -eu
case ${1:-} in
    read)
        if [ -n "${FAKE_READ_COUNT:-}" ]; then
            count=0
            [ ! -f "$FAKE_READ_COUNT" ] ||
                count=$(sed -n '1p' "$FAKE_READ_COUNT")
            count=$((count + 1))
            printf '%s\n' "$count" >"$FAKE_READ_COUNT"
            if [ "$count" -eq 2 ] &&
                [ -n "${FAKE_MUTATE_ROLLOUT:-}" ]; then
                printf '\n' >>"$FAKE_MUTATE_ROLLOUT"
            fi
        fi
        cat "$FAKE_READ_RESPONSE"
        ;;
    rollback)
        printf '%s\t%s\n' "$2" "$3" >>"$FAKE_ROLLBACK_CALLS"
        if [ "${FAKE_ROLLBACK_MODE:-ok}" = ambiguous ]; then
            exit 75
        fi
        if [ "${FAKE_ROLLBACK_MODE:-ok}" != sticky ]; then
            sed 's/"status":"systemError"/"status":"idle"/' \
                "$FAKE_READ_RESPONSE" >"$FAKE_READ_RESPONSE.next"
            mv "$FAKE_READ_RESPONSE.next" "$FAKE_READ_RESPONSE"
        fi
        printf '{"threadId":"%s","turnCount":37}\n' "$2"
        ;;
    *) exit 2 ;;
esac
EOF
chmod 755 "$backend"

HARNESS_THREAD_RECOVERY=$ROOT/libexec/harness-codex-thread-recovery \
python3 -B <<'PY'
from __future__ import print_function
import importlib.machinery
import os

module = importlib.machinery.SourceFileLoader(
    "harness_codex_thread_recovery",
    os.environ["HARNESS_THREAD_RECOVERY"],
).load_module()


class FakeClock(object):
    def __init__(self):
        self.values = iter((0.0, 0.9, 1.1))
        self.sleeps = []

    def monotonic(self):
        return next(self.values)

    def sleep(self, delay):
        if delay < 0:
            raise AssertionError("negative sleep")
        self.sleeps.append(delay)


clock = FakeClock()
module.time.monotonic = clock.monotonic
module.time.sleep = clock.sleep
module.wait_for_interval([False], 1)
if len(clock.sleeps) != 1 or not 0 < clock.sleeps[0] <= 0.2:
    raise AssertionError("watch interval did not clamp deadline crossing")
PY

run_recovery() {
    set -- --target "${RECOVERY_TARGET:-harness}" "$@"
    HARNESS_TESTING=1 \
    HARNESS_CONTROL_ROOT="$ROOT" \
    HARNESS_TARGET_ROOT="$target_harness" \
    HARNESS_TEST_CODEX_TARGETS_FILE="$target_profile" \
    HARNESS_TEST_RUNTIME_DIR="$runtime" \
    HARNESS_TEST_RECOVERY_BACKEND="$backend" \
    HARNESS_TEST_MESSAGE_LOCK="$message_state/agent-message.lock" \
    CODEX_HOME="$codex_home" \
    FAKE_READ_RESPONSE="$TEST_ROOT/read-response.json" \
    FAKE_ROLLBACK_CALLS="$TEST_ROOT/rollback.calls" \
        "$HARNESS" codex-thread-recovery "$@" && recovery_status=0 ||
        recovery_status=$?
    unset RECOVERY_TARGET FAKE_ROLLBACK_MODE
    return "$recovery_status"
}

write_read_response() {
    thread=$1
    status_value=$2
    rollout=$3
    thread_cwd=${4:-$target_harness}
    if ! sed -n '1p' "$rollout" | grep -F '"cwd":' >/dev/null; then
        sed "1s|}}$|,\"cwd\":\"$thread_cwd\"}}|" "$rollout" \
            >"$rollout.next"
        mv "$rollout.next" "$rollout"
        chmod 600 "$rollout"
    elif ! sed -n '1p' "$rollout" |
        grep -F "\"cwd\":\"$thread_cwd\"" >/dev/null; then
        fail "test rollout CWD changed across responses"
    fi
    printf '{"threadId":"%s","status":"%s","path":"%s","cwd":"%s"}\n' \
        "$thread" "$status_value" "$rollout" "$thread_cwd" \
        >"$TEST_ROOT/read-response.json"
}

safe_rollout=$sessions/safe.jsonl
cat >"$safe_rollout" <<'EOF'
{"timestamp":"1","type":"session_meta","payload":{"id":"thread-safe"}}
{"timestamp":"2","type":"event_msg","payload":{"type":"task_started"}}
{"timestamp":"3","type":"response_item","payload":{"type":"message","role":"user","content":[{"type":"input_text","text":"baseline"}]}}
{"timestamp":"4","type":"response_item","payload":{"type":"message","role":"assistant","content":[{"type":"output_text","text":"ok"}]}}
{"timestamp":"5","type":"event_msg","payload":{"type":"task_complete"}}
{"timestamp":"6","type":"event_msg","payload":{"type":"task_started"}}
{"timestamp":"7","type":"world_state","payload":{}}
{"timestamp":"8","type":"turn_context","payload":{}}
{"timestamp":"9","type":"response_item","payload":{"type":"message","role":"user","content":[{"type":"input_text","text":"blocked one"}]}}
{"timestamp":"10","type":"event_msg","payload":{"type":"user_message"}}
{"timestamp":"11","type":"event_msg","payload":{"type":"token_count"}}
{"timestamp":"12","type":"event_msg","payload":{"type":"task_complete","error":{"codex_error_info":"other"}}}
{"timestamp":"13","type":"event_msg","payload":{"type":"task_started"}}
{"timestamp":"14","type":"response_item","payload":{"type":"message","role":"developer","content":[{"type":"input_text","text":"policy"}]}}
{"timestamp":"15","type":"response_item","payload":{"type":"message","role":"user","content":[{"type":"input_text","text":"blocked two"}]}}
{"timestamp":"16","type":"event_msg","payload":{"type":"task_complete","error":{"codex_error_info":"other"}}}
EOF
chmod 600 "$safe_rollout"

: >"$TEST_ROOT/rollback.calls"
write_read_response thread-safe systemError "$safe_rollout"
run_recovery --recover --name safe --thread thread-safe \
    >"$TEST_ROOT/safe.out"
grep -F 'phase=recovered reason=system-error-safe-tail' \
    "$TEST_ROOT/safe.out" >/dev/null || fail "safe recovery status"
grep -F 'rolled_back=2' "$TEST_ROOT/safe.out" >/dev/null ||
    fail "safe rollback count"
[ "$(cat "$TEST_ROOT/rollback.calls")" = 'thread-safe	2' ] ||
    fail "safe rollback request"
case $(uname -s) in
    Darwin) recovery_mode=$(stat -f %Lp "$runtime/harness:safe.recovery.state") ;;
    *) recovery_mode=$(stat -c %a "$runtime/harness:safe.recovery.state") ;;
esac
[ "$recovery_mode" = 600 ] ||
    fail "recovery state mode"
grep -E 'blocked one|blocked two|baseline|policy' \
    "$runtime/harness:safe.recovery.state" >/dev/null &&
    fail "recovery state retained transcript content"

write_watching_state() {
    state_name=$1
    state_thread=$2
    state_pid=$3
    cat >"$runtime/$state_name.recovery.state" <<EOF
schema=1
name=$state_name
thread=$state_thread
owner_pid=$state_pid
phase=watching
reason=thread-active
recoveries=0
rolled_back=0
EOF
    chmod 600 "$runtime/$state_name.recovery.state"
}

write_read_response thread-safe active "$safe_rollout"
write_watching_state harness:preflight thread-safe "$$"
run_recovery --check >"$TEST_ROOT/target-check.out"
grep -F 'thread=thread-safe status=ready thread_status=active' \
    "$TEST_ROOT/target-check.out" >/dev/null ||
    fail "target-only check did not resolve the live watcher"
write_watching_state harness:stale thread-stale 999999
run_recovery --check >"$TEST_ROOT/stale-target-check.out"
grep -F 'thread=thread-safe status=ready thread_status=active' \
    "$TEST_ROOT/stale-target-check.out" >/dev/null ||
    fail "target-only check selected a stale watcher"
write_watching_state harness:second thread-second "$$"
if run_recovery --check >"$TEST_ROOT/ambiguous-target-check.out" 2>&1; then
    fail "target-only check accepted multiple live watchers"
fi
grep -F 'watcher is ambiguous' "$TEST_ROOT/ambiguous-target-check.out" \
    >/dev/null || fail "target-only ambiguity reason"
unlink "$runtime/harness:second.recovery.state"
unlink "$runtime/harness:stale.recovery.state"
unlink "$runtime/harness:preflight.recovery.state"
if run_recovery --check >"$TEST_ROOT/absent-target-check.out" 2>&1; then
    fail "target-only check accepted no live watcher"
fi
grep -F 'watcher is unavailable' "$TEST_ROOT/absent-target-check.out" \
    >/dev/null || fail "target-only absence reason"

student_parallel_rollout=$sessions/student-parallel.jsonl
cat >"$student_parallel_rollout" <<'EOF'
{"timestamp":"1","type":"session_meta","payload":{"id":"thread-student-parallel"}}
{"timestamp":"2","type":"event_msg","payload":{"type":"task_started"}}
{"timestamp":"3","type":"response_item","payload":{"type":"message","role":"user"}}
{"timestamp":"4","type":"response_item","payload":{"type":"message","role":"assistant"}}
{"timestamp":"5","type":"event_msg","payload":{"type":"task_complete"}}
EOF
chmod 600 "$student_parallel_rollout"
write_read_response thread-student-parallel idle "$student_parallel_rollout" \
    "$target_students"
RECOVERY_TARGET=students run_recovery \
    --recover --name parallel --thread thread-student-parallel \
    >"$TEST_ROOT/student-parallel.out"

harness_parallel_rollout=$sessions/harness-parallel.jsonl
cat >"$harness_parallel_rollout" <<'EOF'
{"timestamp":"1","type":"session_meta","payload":{"id":"thread-harness-parallel"}}
{"timestamp":"2","type":"event_msg","payload":{"type":"task_started"}}
{"timestamp":"3","type":"response_item","payload":{"type":"message","role":"user"}}
{"timestamp":"4","type":"response_item","payload":{"type":"message","role":"assistant"}}
{"timestamp":"5","type":"event_msg","payload":{"type":"task_complete"}}
EOF
chmod 600 "$harness_parallel_rollout"
write_read_response thread-harness-parallel idle "$harness_parallel_rollout"
run_recovery --recover --name parallel --thread thread-harness-parallel \
    >"$TEST_ROOT/harness-parallel.out"
[ -f "$runtime/students:parallel.recovery.state" ] &&
    [ -f "$runtime/harness:parallel.recovery.state" ] ||
    fail "same-name recovery state is not target-scoped"
grep -F 'thread=thread-student-parallel' \
    "$runtime/students:parallel.recovery.state" >/dev/null ||
    fail "Students recovery state was overwritten"
grep -F 'thread=thread-harness-parallel' \
    "$runtime/harness:parallel.recovery.state" >/dev/null ||
    fail "Harness recovery state was overwritten"

: >"$TEST_ROOT/rollback.calls"
write_read_response thread-safe systemError "$safe_rollout"
FAKE_ROLLBACK_MODE=sticky run_recovery \
    --recover --name sticky --thread thread-safe \
    >"$TEST_ROOT/sticky.out" 2>&1 &&
    fail "post-rollback systemError was reported recovered"
grep -F 'phase=blocked reason=post-rollback-system-error' \
    "$TEST_ROOT/sticky.out" >/dev/null ||
    fail "post-rollback systemError classification"
grep -F 'rolled_back=2' "$TEST_ROOT/sticky.out" >/dev/null ||
    fail "post-rollback count preservation"
[ "$(cat "$TEST_ROOT/rollback.calls")" = 'thread-safe	2' ] ||
    fail "post-rollback request cardinality"

marker_rollout=$sessions/marker.jsonl
cat >"$marker_rollout" <<'EOF'
{"timestamp":"1","type":"session_meta","payload":{"id":"thread-marker"}}
{"timestamp":"2","type":"event_msg","payload":{"type":"task_started"}}
{"timestamp":"3","type":"response_item","payload":{"type":"message","role":"user"}}
{"timestamp":"4","type":"response_item","payload":{"type":"message","role":"assistant"}}
{"timestamp":"5","type":"event_msg","payload":{"type":"task_complete"}}
{"timestamp":"6","type":"event_msg","payload":{"type":"task_started"}}
{"timestamp":"7","type":"response_item","payload":{"type":"message","role":"user"}}
{"timestamp":"8","type":"event_msg","payload":{"type":"task_complete"}}
{"timestamp":"9","type":"event_msg","payload":{"type":"task_started"}}
{"timestamp":"10","type":"response_item","payload":{"type":"message","role":"user"}}
{"timestamp":"11","type":"event_msg","payload":{"type":"task_complete"}}
{"timestamp":"12","type":"event_msg","payload":{"type":"thread_rolled_back","num_turns":2}}
{"timestamp":"13","type":"event_msg","payload":{"type":"task_started"}}
{"timestamp":"14","type":"response_item","payload":{"type":"message","role":"user"}}
{"timestamp":"15","type":"response_item","payload":{"type":"message","role":"assistant"}}
{"timestamp":"16","type":"event_msg","payload":{"type":"task_complete"}}
{"timestamp":"17","type":"event_msg","payload":{"type":"task_started"}}
{"timestamp":"18","type":"response_item","payload":{"type":"message","role":"user"}}
{"timestamp":"19","type":"event_msg","payload":{"type":"task_complete"}}
EOF
chmod 600 "$marker_rollout"
: >"$TEST_ROOT/rollback.calls"
write_read_response thread-marker systemError "$marker_rollout"
run_recovery --recover --name marker --thread thread-marker \
    >"$TEST_ROOT/marker.out"
[ "$(cat "$TEST_ROOT/rollback.calls")" = 'thread-marker	1' ] ||
    fail "durable rollback marker was ignored"

stale_marker_rollout=$sessions/stale-marker.jsonl
cat >"$stale_marker_rollout" <<'EOF'
{"timestamp":"1","type":"session_meta","payload":{"id":"thread-stale-marker"}}
{"timestamp":"2","type":"event_msg","payload":{"type":"task_started","turn_id":"completed-turn"}}
{"timestamp":"3","type":"response_item","payload":{"type":"message","role":"user"}}
{"timestamp":"4","type":"event_msg","payload":{"type":"task_complete","turn_id":"completed-turn"}}
{"timestamp":"5","type":"event_msg","payload":{"type":"task_started","turn_id":"stale-turn"}}
{"timestamp":"6","type":"response_item","payload":{"type":"message","role":"user"}}
{"timestamp":"7","type":"response_item","payload":{"type":"custom_tool_call","status":"completed"}}
{"timestamp":"8","type":"event_msg","payload":{"type":"thread_rolled_back","num_turns":1}}
{"timestamp":"9","type":"event_msg","payload":{"type":"task_started","turn_id":"safe-turn"}}
{"timestamp":"10","type":"response_item","payload":{"type":"message","role":"user"}}
{"timestamp":"11","type":"event_msg","payload":{"type":"task_complete","turn_id":"safe-turn"}}
EOF
chmod 600 "$stale_marker_rollout"
: >"$TEST_ROOT/rollback.calls"
write_read_response thread-stale-marker systemError "$stale_marker_rollout"
run_recovery --recover --name stale-marker --thread thread-stale-marker \
    >"$TEST_ROOT/stale-marker.out"
[ "$(cat "$TEST_ROOT/rollback.calls")" = 'thread-stale-marker	1' ] ||
    fail "durable rollback marker did not reset stale lifecycle state"

aborted_rollout=$sessions/aborted.jsonl
cat >"$aborted_rollout" <<'EOF'
{"timestamp":"1","type":"session_meta","payload":{"id":"thread-aborted"}}
{"timestamp":"2","type":"event_msg","payload":{"type":"task_started","turn_id":"aborted-turn"}}
{"timestamp":"3","type":"response_item","payload":{"type":"message","role":"user"}}
{"timestamp":"4","type":"event_msg","payload":{"type":"turn_aborted","turn_id":"aborted-turn"}}
{"timestamp":"5","type":"event_msg","payload":{"type":"task_started","turn_id":"safe-turn"}}
{"timestamp":"6","type":"response_item","payload":{"type":"message","role":"user"}}
{"timestamp":"7","type":"event_msg","payload":{"type":"task_complete","turn_id":"safe-turn"}}
EOF
chmod 600 "$aborted_rollout"
: >"$TEST_ROOT/rollback.calls"
write_read_response thread-aborted systemError "$aborted_rollout"
run_recovery --recover --name aborted --thread thread-aborted \
    >"$TEST_ROOT/aborted.out"
[ "$(cat "$TEST_ROOT/rollback.calls")" = 'thread-aborted	1' ] ||
    fail "aborted turn contaminated the safe recovery tail"

unsafe_rollout=$sessions/unsafe.jsonl
cat >"$unsafe_rollout" <<'EOF'
{"timestamp":"1","type":"session_meta","payload":{"id":"thread-unsafe"}}
{"timestamp":"2","type":"event_msg","payload":{"type":"task_started"}}
{"timestamp":"3","type":"response_item","payload":{"type":"message","role":"user"}}
{"timestamp":"4","type":"response_item","payload":{"type":"custom_tool_call","status":"completed"}}
{"timestamp":"5","type":"event_msg","payload":{"type":"task_complete"}}
EOF
chmod 600 "$unsafe_rollout"
: >"$TEST_ROOT/rollback.calls"
write_read_response thread-unsafe systemError "$unsafe_rollout"
run_recovery --recover --name unsafe --thread thread-unsafe \
    >"$TEST_ROOT/unsafe.out" 2>&1 &&
    fail "tool-bearing tail was rolled back"
grep -F 'phase=blocked reason=unsafe-tail' "$TEST_ROOT/unsafe.out" \
    >/dev/null || fail "unsafe tail classification"
[ ! -s "$TEST_ROOT/rollback.calls" ] ||
    fail "unsafe tail reached rollback"

active_rollout=$sessions/active.jsonl
cat >"$active_rollout" <<'EOF'
{"timestamp":"1","type":"session_meta","payload":{"id":"thread-active"}}
{"timestamp":"2","type":"event_msg","payload":{"type":"task_started"}}
{"timestamp":"3","type":"response_item","payload":{"type":"message","role":"user"}}
EOF
chmod 600 "$active_rollout"
: >"$TEST_ROOT/rollback.calls"
write_read_response thread-active systemError "$active_rollout"
run_recovery --recover --name active --thread thread-active \
    >"$TEST_ROOT/active.out" 2>&1 &&
    fail "active tail was rolled back"
grep -F 'phase=blocked reason=unsafe-tail' "$TEST_ROOT/active.out" \
    >/dev/null || fail "active tail classification"
[ ! -s "$TEST_ROOT/rollback.calls" ] ||
    fail "active tail reached rollback"

unknown_rollout=$sessions/unknown.jsonl
cat >"$unknown_rollout" <<'EOF'
{"timestamp":"1","type":"session_meta","payload":{"id":"thread-unknown"}}
{"timestamp":"2","type":"event_msg","payload":{"type":"task_started"}}
{"timestamp":"3","type":"response_item","payload":{"type":"message","role":"user"}}
{"timestamp":"4","type":"event_msg","payload":{"type":"future_event"}}
{"timestamp":"5","type":"event_msg","payload":{"type":"task_complete"}}
EOF
chmod 600 "$unknown_rollout"
: >"$TEST_ROOT/rollback.calls"
write_read_response thread-unknown systemError "$unknown_rollout"
run_recovery --recover --name unknown --thread thread-unknown \
    >"$TEST_ROOT/unknown.out" 2>&1 &&
    fail "unknown rollout event was accepted"
[ ! -s "$TEST_ROOT/rollback.calls" ] ||
    fail "unknown rollout event reached rollback"

excessive_rollout=$sessions/excessive.jsonl
printf '%s\n' \
    '{"timestamp":"1","type":"session_meta","payload":{"id":"thread-excessive"}}' \
    >"$excessive_rollout"
excessive_index=1
while [ "$excessive_index" -le 9 ]; do
    printf '%s\n' \
        '{"type":"event_msg","payload":{"type":"task_started"}}' \
        '{"type":"response_item","payload":{"type":"message","role":"user"}}' \
        '{"type":"event_msg","payload":{"type":"task_complete"}}' \
        >>"$excessive_rollout"
    excessive_index=$((excessive_index + 1))
done
chmod 600 "$excessive_rollout"
: >"$TEST_ROOT/rollback.calls"
write_read_response thread-excessive systemError "$excessive_rollout"
run_recovery --recover --name excessive --thread thread-excessive \
    >"$TEST_ROOT/excessive.out" 2>&1 &&
    fail "excessive recovery tail was accepted"
[ ! -s "$TEST_ROOT/rollback.calls" ] ||
    fail "excessive recovery tail reached rollback"

identity_rollout=$sessions/identity.jsonl
cat >"$identity_rollout" <<'EOF'
{"timestamp":"1","type":"session_meta","payload":{"id":"different-thread"}}
{"timestamp":"2","type":"event_msg","payload":{"type":"task_started"}}
{"timestamp":"3","type":"response_item","payload":{"type":"message","role":"user"}}
{"timestamp":"4","type":"event_msg","payload":{"type":"task_complete"}}
EOF
chmod 600 "$identity_rollout"
: >"$TEST_ROOT/rollback.calls"
write_read_response thread-identity systemError "$identity_rollout"
run_recovery --recover --name identity --thread thread-identity \
    >"$TEST_ROOT/identity.out" 2>&1 &&
    fail "rollout session identity mismatch was accepted"
[ ! -s "$TEST_ROOT/rollback.calls" ] ||
    fail "rollout session identity mismatch reached rollback"

drift_rollout=$sessions/drift.jsonl
cat >"$drift_rollout" <<'EOF'
{"timestamp":"1","type":"session_meta","payload":{"id":"thread-drift"}}
{"timestamp":"2","type":"event_msg","payload":{"type":"task_started"}}
{"timestamp":"3","type":"response_item","payload":{"type":"message","role":"user"}}
{"timestamp":"4","type":"event_msg","payload":{"type":"task_complete"}}
EOF
chmod 600 "$drift_rollout"
: >"$TEST_ROOT/rollback.calls"
: >"$TEST_ROOT/read-count"
write_read_response thread-drift systemError "$drift_rollout"
FAKE_READ_COUNT="$TEST_ROOT/read-count" \
FAKE_MUTATE_ROLLOUT="$drift_rollout" \
    run_recovery --recover --name drift --thread thread-drift \
        >"$TEST_ROOT/drift.out" 2>&1 &&
    fail "rollout identity drift was accepted"
[ ! -s "$TEST_ROOT/rollback.calls" ] ||
    fail "rollout identity drift reached rollback"

: >"$TEST_ROOT/rollback.calls"
write_read_response thread-safe idle "$safe_rollout"
run_recovery --recover --name idle --thread thread-safe \
    >"$TEST_ROOT/idle.out"
grep -F 'phase=watching reason=thread-idle' "$TEST_ROOT/idle.out" \
    >/dev/null || fail "idle thread classification"
[ ! -s "$TEST_ROOT/rollback.calls" ] ||
    fail "idle thread reached rollback"

cross_rollout=$sessions/cross-target.jsonl
cat >"$cross_rollout" <<'EOF'
{"timestamp":"1","type":"session_meta","payload":{"id":"thread-cross"}}
{"timestamp":"2","type":"event_msg","payload":{"type":"task_started"}}
{"timestamp":"3","type":"response_item","payload":{"type":"message","role":"user"}}
{"timestamp":"4","type":"event_msg","payload":{"type":"task_complete"}}
EOF
chmod 600 "$cross_rollout"
: >"$TEST_ROOT/rollback.calls"
write_read_response thread-cross idle "$cross_rollout" "$target_students"
run_recovery --check --name cross-idle --thread thread-cross \
    >"$TEST_ROOT/cross-idle.out" 2>&1 &&
    fail "cross-target idle thread passed exact-resume preflight"
[ ! -s "$TEST_ROOT/rollback.calls" ] ||
    fail "cross-target idle thread reached rollback"
write_read_response thread-cross systemError "$cross_rollout" "$target_students"
run_recovery --recover --name cross-error --thread thread-cross \
    >"$TEST_ROOT/cross-error.out" 2>&1 &&
    fail "cross-target systemError thread was accepted"
grep -F 'phase=blocked reason=target-mismatch' \
    "$TEST_ROOT/cross-error.out" >/dev/null ||
    fail "cross-target systemError was not classified"
[ ! -s "$TEST_ROOT/rollback.calls" ] ||
    fail "cross-target systemError thread reached rollback"

: >"$TEST_ROOT/rollback.calls"
write_read_response thread-safe systemError "$safe_rollout"
FAKE_ROLLBACK_MODE=ambiguous run_recovery \
    --recover --name ambiguous --thread thread-safe \
    >"$TEST_ROOT/ambiguous.out" 2>&1 &&
    fail "ambiguous rollback returned success"
grep -F 'do not retry' "$TEST_ROOT/ambiguous.out" >/dev/null ||
    fail "ambiguous rollback retry warning"
[ "$(wc -l <"$TEST_ROOT/rollback.calls" | tr -d ' ')" = 1 ] ||
    fail "ambiguous rollback call count"

run_recovery --plan --name planned --thread thread-planned \
    >"$TEST_ROOT/plan.out"
grep -F 'rollback=safe-tail-only max_turns=8 prompt=replay-disabled' \
    "$TEST_ROOT/plan.out" >/dev/null || fail "recovery plan boundary"
run_recovery --status --name safe >"$TEST_ROOT/status.out"
grep -F 'phase=recovered' "$TEST_ROOT/status.out" >/dev/null ||
    fail "recovery status readback"
if HARNESS_TESTING=1 HARNESS_TEST_RUNTIME_DIR="$runtime" \
    "$HARNESS" codex-thread-recovery --plan \
        --name missing-target --thread thread-missing \
        >"$TEST_ROOT/missing-target.out" 2>&1; then
    fail "targetless recovery plan was accepted"
fi

websocket_rollout=$sessions/websocket.jsonl
cat >"$websocket_rollout" <<'EOF'
{"timestamp":"1","type":"session_meta","payload":{"id":"thread-websocket"}}
{"timestamp":"2","type":"event_msg","payload":{"type":"task_started"}}
{"timestamp":"3","type":"response_item","payload":{"type":"message","role":"user"}}
{"timestamp":"4","type":"event_msg","payload":{"type":"task_complete"}}
EOF
chmod 600 "$websocket_rollout"
write_read_response thread-websocket systemError "$websocket_rollout"

websocket_server=$TEST_ROOT/fake-websocket-server.py
cat >"$websocket_server" <<'PY'
#!/usr/bin/env python3
from __future__ import print_function
import base64
import hashlib
import json
import os
import socket
import struct
import sys

socket_path, rollout_path, calls_path = sys.argv[1:4]
listener = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
listener.bind(socket_path)
listener.listen(1)
connection, _ = listener.accept()
buffer = bytearray()
while b"\r\n\r\n" not in buffer:
    buffer.extend(connection.recv(4096))
headers, remainder = bytes(buffer).split(b"\r\n\r\n", 1)
buffer = bytearray(remainder)
key = None
for line in headers.decode("latin-1").split("\r\n"):
    if line.lower().startswith("sec-websocket-key:"):
        key = line.split(":", 1)[1].strip()
if key is None:
    raise RuntimeError("missing websocket key")
accept = base64.b64encode(
    hashlib.sha1(
        (key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11").encode("ascii")
    ).digest()
).decode("ascii")
connection.sendall(
    (
        "HTTP/1.1 101 Switching Protocols\r\n"
        "Upgrade: websocket\r\n"
        "Connection: Upgrade\r\n"
        "Sec-WebSocket-Accept: {}\r\n\r\n"
    ).format(accept).encode("ascii")
)

def exact(size):
    while len(buffer) < size:
        chunk = connection.recv(max(4096, size - len(buffer)))
        if not chunk:
            raise RuntimeError("client closed")
        buffer.extend(chunk)
    value = bytes(buffer[:size])
    del buffer[:size]
    return value

def receive():
    first, second = exact(2)
    length = second & 0x7f
    if length == 126:
        length = struct.unpack("!H", exact(2))[0]
    elif length == 127:
        length = struct.unpack("!Q", exact(8))[0]
    mask = exact(4) if second & 0x80 else b""
    payload = exact(length)
    if mask:
        payload = bytes(
            value ^ mask[index % 4]
            for index, value in enumerate(payload)
        )
    return first & 0x0f, payload

def send(value):
    payload = json.dumps(value, separators=(",", ":")).encode("utf-8")
    header = bytearray([0x81])
    if len(payload) < 126:
        header.append(len(payload))
    elif len(payload) < 65536:
        header.append(126)
        header.extend(struct.pack("!H", len(payload)))
    else:
        header.append(127)
        header.extend(struct.pack("!Q", len(payload)))
    connection.sendall(header + payload)

methods = []
rolled_back = False
while True:
    opcode, payload = receive()
    if opcode == 8:
        break
    message = json.loads(payload.decode("utf-8"))
    method = message.get("method")
    methods.append(method)
    if method == "initialize":
        send({"id": message["id"], "result": {}})
    elif method == "initialized":
        continue
    elif method == "thread/read":
        send(
            {
                "id": message["id"],
                "result": {
                    "thread": {
                        "id": "thread-websocket",
                        "status": {
                            "type": "idle" if rolled_back else "systemError"
                        },
                        "path": rollout_path,
                    }
                },
            }
        )
    elif method == "thread/rollback":
        if message.get("params") != {
            "threadId": "thread-websocket",
            "numTurns": 1,
        }:
            raise RuntimeError("unexpected rollback params")
        send(
            {
                "id": message["id"],
                "result": {
                    "thread": {
                        "id": "thread-websocket",
                        "turns": [],
                    }
                },
            }
        )
        rolled_back = True
    else:
        raise RuntimeError("unexpected method")
with open(calls_path, "w") as output:
    output.write("\n".join(methods) + "\n")
connection.close()
listener.close()
os.unlink(socket_path)
PY
chmod 755 "$websocket_server"

# Keep the Unix-domain socket path below Darwin's short sun_path limit while
# retaining a parent that exists on both macOS and Linux runners.
control_socket=/tmp/harness-recovery-$$.sock
python3 "$websocket_server" "$control_socket" "$websocket_rollout" \
    "$TEST_ROOT/websocket.calls" &
server_pid=$!
socket_wait=0
while [ ! -S "$control_socket" ] && [ "$socket_wait" -lt 50 ]; do
    sleep 0.1
    socket_wait=$((socket_wait + 1))
done
[ -S "$control_socket" ] || fail "fake WebSocket server did not start"
HARNESS_TESTING=1 \
HARNESS_CONTROL_ROOT="$ROOT" \
HARNESS_TARGET_ROOT="$target_harness" \
HARNESS_TEST_CODEX_TARGETS_FILE="$target_profile" \
HARNESS_TEST_RUNTIME_DIR="$runtime" \
HARNESS_TEST_MESSAGE_LOCK="$message_state/agent-message.lock" \
HARNESS_CODEX_APP_SERVER_SOCKET="$control_socket" \
CODEX_HOME="$codex_home" \
    "$HARNESS" codex-thread-recovery --recover \
    --name websocket --target harness --thread thread-websocket \
    >"$TEST_ROOT/websocket.out"
wait "$server_pid"
server_pid=
expected_methods='initialize
initialized
thread/read
thread/read
thread/rollback
thread/read'
[ "$(cat "$TEST_ROOT/websocket.calls")" = "$expected_methods" ] ||
    fail "app-server WebSocket method sequence"
grep -F 'phase=recovered' "$TEST_ROOT/websocket.out" >/dev/null ||
    fail "app-server WebSocket recovery"

printf 'PASS: Codex thread systemError recovery\n'
