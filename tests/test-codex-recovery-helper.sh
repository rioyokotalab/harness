#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/harness-codex-recovery-helper-test.XXXXXX")
RUNTIME=$TEST_ROOT/runtime
CAPTURE=$TEST_ROOT/capture
FAKE_CODEX=$TEST_ROOT/fake-codex

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEST_ROOT" ]; then
        "$CLEANUP" "$HARNESS" "$TEMP_BASE" "$TEST_ROOT" "$TEMP_BASE" \
            >/dev/null || cleanup_failed=1
    fi
    [ "$status" -ne 0 ] || [ "$cleanup_failed" -eq 0 ] || status=1
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

mkdir -m 700 "$RUNTIME" "$CAPTURE"
cat >"$FAKE_CODEX" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$*" >>"$HARNESS_TEST_CAPTURE/arguments"
cat >"$HARNESS_TEST_CAPTURE/prompt"
printf '%s\n' 'RECOVERY_RESULT status=accepted'
EOF
chmod 700 "$FAKE_CODEX"

SOURCE=$ROOT/libexec/harness-codex-recovery-helper
python3 -B - "$SOURCE" <<'PY'
import ast
import pathlib
import sys

source = pathlib.Path(sys.argv[1]).read_text()
ast.parse(source, feature_version=(3, 6))
assert "capture-pane" not in source
assert "read-pane" not in source
assert "SIGKILL" in source
assert "--ephemeral" in source
assert '"sol"' in source
assert 'model_reasoning_effort="high"' in source
assert "rejected prompt" in source
assert "first recorded unverified action" in source
assert "remote-control start --json" in source
assert "If any live server identity exists" in source
assert "codex unarchive" not in source
PY

helper() {
    HARNESS_TESTING=1 \
    HARNESS_TEST_RUNTIME_DIR="$RUNTIME" \
    HARNESS_TEST_CODEX="$FAKE_CODEX" \
    HARNESS_TEST_CAPTURE="$CAPTURE" \
    HARNESS_TEST_SKIP_DETECTION=1 \
        "$HARNESS" codex-recovery-helper "$@"
}

helper --enqueue-blocked \
    --target swallow \
    --runtime swallow-recovery-t345 \
    --thread 019fafef-5ebf-72f1-b1ce-2444e7570dc1 \
    --watcher-pid 4242 \
    --watcher-start 123456 \
    --app-server-pid 4343 \
    --app-server-start 654321 \
    --window-id @93 \
    --window-index 2 >"$TEST_ROOT/enqueue.out"
grep -F 'enqueue=queued' "$TEST_ROOT/enqueue.out" >/dev/null ||
    fail "blocked event was not queued"

helper --once >"$TEST_ROOT/once.out"
grep -F 'completed=1' "$TEST_ROOT/once.out" >/dev/null ||
    fail "ephemeral worker did not complete"
[ "$(wc -l <"$CAPTURE/arguments" | tr -d ' ')" = 1 ] ||
    fail "unexpected worker invocation count"
grep -F 'exec --ephemeral' "$CAPTURE/arguments" >/dev/null ||
    fail "worker is not ephemeral"
grep -F -- '-m sol' "$CAPTURE/arguments" >/dev/null ||
    fail "worker model is not Sol"
grep -F 'model_reasoning_effort="high"' "$CAPTURE/arguments" >/dev/null ||
    fail "worker reasoning effort is not high"
grep -F 'Healthy sibling threads may be active' "$CAPTURE/prompt" >/dev/null ||
    fail "active sibling contract is absent"
grep -F 'submit exactly one' "$CAPTURE/prompt" >/dev/null ||
    fail "continuation contract is absent"
grep -F 'codex remote-control start --json' \
    "$CAPTURE/prompt" >/dev/null ||
    fail "absent-only remote-control contract is absent"
grep -F 'Reversibly archive only roots' "$CAPTURE/prompt" >/dev/null ||
    fail "reversible archive contract is absent"

helper --once >"$TEST_ROOT/repeat.out"
[ "$(wc -l <"$CAPTURE/arguments" | tr -d ' ')" = 1 ] ||
    fail "completed event was retried"

helper --enqueue-blocked \
    --target swallow \
    --runtime swallow-recovery-t345 \
    --thread 019fafef-5ebf-72f1-b1ce-2444e7570dc1 \
    --watcher-pid 4242 \
    --watcher-start 123456 \
    --app-server-pid 4343 \
    --app-server-start 654321 \
    --window-id @93 \
    --window-index 2 >"$TEST_ROOT/duplicate.out"
grep -F 'enqueue=already-queued' "$TEST_ROOT/duplicate.out" >/dev/null ||
    fail "duplicate event was not deduplicated"

if helper --status >"$TEST_ROOT/status.out"; then
    fail "one-shot helper was reported live"
fi
grep -F 'phase=stale' "$TEST_ROOT/status.out" >/dev/null ||
    fail "one-shot helper status is not stale"
grep -F 'completed=1' "$TEST_ROOT/status.out" >/dev/null ||
    fail "helper status lost completion"

receipt=$(find "$RUNTIME/receipts" -type f -name '*.json')
[ -n "$receipt" ] || fail "event receipt is absent"
python3 - "$receipt" <<'PY'
import json
import pathlib
import stat
import sys

path = pathlib.Path(sys.argv[1])
value = json.loads(path.read_text())
assert value["phase"] == "completed"
assert value["returncode"] == 0
assert stat.S_IMODE(path.stat().st_mode) == 0o600
PY

printf '%s\n' "Codex recovery helper tests: PASS"
