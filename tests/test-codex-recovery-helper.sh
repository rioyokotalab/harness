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
assert "phone-mirror-drift" in source
assert "physical-phone visibility" in source
assert "never rewrite it" in source
PY

python3 -B - "$SOURCE" "$TEST_ROOT" <<'PY'
import importlib.machinery
import os
import pathlib
import sqlite3
import sys

source, test_root = sys.argv[1:3]
module = importlib.machinery.SourceFileLoader(
    "recovery_helper_phone_test", source
).load_module()
phone_event = {"identity": {"kind": "phone-mirror-drift"}}
assert module.event_pending(phone_event, {}, False) is False
assert module.event_pending(phone_event, {}, True) is True
assert module.event_pending(phone_event, {"phase": "ambiguous"}, True) is False
base = pathlib.Path(test_root)
event_root = base / "event-state"
for name in ("events", "receipts", "logs"):
    (event_root / name).mkdir(parents=True, mode=0o700)
event_id, action = module.enqueue_event(
    str(event_root),
    {"schema": 1, "kind": "phone-mirror-drift", "canonical": []},
)
assert action == "queued"
pending = module.pending_event_for_kind(
    str(event_root), "phone-mirror-drift"
)
assert pending["event"] == event_id
assert module.defer_queued_event(
    str(event_root), pending, "drift-resolved"
) is True
assert module.pending_event_for_kind(
    str(event_root), "phone-mirror-drift"
) is None
codex_home = base / "codex-home"
sessions = codex_home / "sessions"
sessions.mkdir(parents=True)
database = codex_home / "state_5.sqlite"
harness_root = str(base / "harness")
mapping = {}
connection = sqlite3.connect(str(database))
connection.execute(
    "CREATE TABLE threads ("
    "id TEXT PRIMARY KEY, rollout_path TEXT, source TEXT, cwd TEXT, "
    "title TEXT, archived INTEGER, name TEXT)"
)
for index, role in enumerate(("harness", "students", "swallow")):
    thread = "thread-{}".format(role)
    rollout = sessions / "{}.jsonl".format(role)
    rollout.write_text("{}\n")
    os.chmod(str(rollout), 0o600)
    connection.execute(
        "INSERT INTO threads VALUES (?, ?, ?, ?, ?, ?, ?)",
        (
            thread,
            str(rollout),
            "vscode",
            harness_root,
            role,
            0,
            role,
        ),
    )
    mapping[role] = {
        "index": index,
        "window_id": "@{}".format(index),
        "thread": thread,
    }
connection.commit()
processes = [{"pid": os.getpid(), "start": "remote-start"}]

healthy, drift = module.phone_mirror_snapshot(
    mapping, str(database), processes, harness_root, str(codex_home)
)
assert healthy["status"] == "healthy"
assert healthy["active_top_level_count"] == 3
assert healthy["mismatch_classes"] == []
assert drift["kind"] == "phone-mirror-drift"

connection.execute(
    "UPDATE threads SET source = 'exec' WHERE id = 'thread-swallow'"
)
connection.commit()
ineligible, _drift = module.phone_mirror_snapshot(
    mapping, str(database), processes, harness_root, str(codex_home)
)
assert ineligible["status"] == "degraded"
assert ineligible["roles"]["swallow"]["interactive_source"] is False
assert "interactive_source:swallow" in ineligible["mismatch_classes"]

connection.execute(
    "UPDATE threads SET source = 'vscode', rollout_path = ? "
    "WHERE id = 'thread-swallow'",
    (str(sessions / "absent.jsonl"),),
)
connection.commit()
missing_rollout, _drift = module.phone_mirror_snapshot(
    mapping, str(database), processes, harness_root, str(codex_home)
)
assert missing_rollout["status"] == "degraded"
assert missing_rollout["roles"]["swallow"]["rollout_location"] is True
assert missing_rollout["roles"]["swallow"]["rollout_exists"] is False

connection.execute(
    "UPDATE threads SET archived = 1, name = 'wrong', rollout_path = ? "
    "WHERE id = 'thread-swallow'",
    (str(sessions / "swallow.jsonl"),),
)
connection.commit()
metadata_drift, _drift = module.phone_mirror_snapshot(
    mapping, str(database), processes, harness_root, str(codex_home)
)
assert metadata_drift["status"] == "degraded"
assert metadata_drift["roles"]["swallow"]["unarchived"] is False
assert metadata_drift["roles"]["swallow"]["exact_name"] is False

connection.execute(
    "UPDATE threads SET archived = 0, name = 'swallow' "
    "WHERE id = 'thread-swallow'"
)
extra_rollout = sessions / "extra.jsonl"
extra_rollout.write_text("{}\n")
connection.execute(
    "INSERT INTO threads VALUES (?, ?, ?, ?, ?, ?, ?)",
    (
        "thread-extra",
        str(extra_rollout),
        "vscode",
        harness_root,
        "extra",
        0,
        "extra",
    ),
)
connection.execute(
    "INSERT INTO threads VALUES (?, ?, ?, ?, ?, ?, ?)",
    (
        "thread-subagent",
        str(extra_rollout),
        '{"subagent":{"kind":"review"}}',
        harness_root,
        "subagent",
        0,
        "subagent",
    ),
)
connection.commit()
extra, drift = module.phone_mirror_snapshot(
    mapping, str(database), processes, harness_root, str(codex_home)
)
assert extra["active_top_level_count"] == 4
assert "extra-active-root" in extra["mismatch_classes"]
assert drift["extras"] == ["thread-extra"]
connection.close()
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
