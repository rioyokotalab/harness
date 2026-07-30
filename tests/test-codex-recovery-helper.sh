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
for variable in HARNESS_ROOT HARNESS_CONTROL_ROOT HARNESS_TARGET_ROOT \
    HARNESS_CODEX_RELEASE_COMMIT HARNESS_CODEX_RELEASE_TARGET \
    HARNESS_TEST_CODEX_RELEASE_ROOT \
    HARNESS_TEST_FORCE_CODEX_RELEASE
do
    eval 'present=${'"$variable"'+yes}'
    [ -z "${present:-}" ] || {
        printf 'leaked=%s\n' "$variable" >"$HARNESS_TEST_CAPTURE/control-leak"
        exit 9
    }
done
printf '%s\n' sanitized >"$HARNESS_TEST_CAPTURE/control-environment"
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

HARNESS_ROOT=$ROOT python3 -B - "$SOURCE" "$TEST_ROOT" <<'PY'
import importlib.machinery
import os
import pathlib
import sqlite3
import sys

source, test_root = sys.argv[1:3]
module = importlib.machinery.SourceFileLoader(
    "recovery_helper_phone_test", source
).load_module()
assert module.SESSION_NAME == "projects"
for kind in module.TARGETLESS_EVENT_KINDS:
    prompt = module.worker_prompt({"identity": {"kind": kind}})
    assert "Exact managed target: harness" in prompt
try:
    module.worker_prompt(
        {"identity": {"kind": "blocked-root", "target": "unknown"}}
    )
except module.HelperError:
    pass
else:
    raise AssertionError("unknown explicit target fell back")
try:
    module.worker_prompt({"identity": {"kind": "blocked-root"}})
except module.HelperError:
    pass
else:
    raise AssertionError("targetless blocked event was accepted")
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
target_paths = {
    "harness": harness_root,
    "students": str(base / "students"),
    "swallow": str(base / "swallow"),
}
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
        "cwd": harness_root,
        "native_cwd": role == "harness",
    }
connection.commit()
processes = [{"pid": os.getpid(), "start": "remote-start"}]

legacy_cwd, drift = module.phone_mirror_snapshot(
    mapping, str(database), processes, target_paths, str(codex_home)
)
assert legacy_cwd["status"] == "degraded"
assert legacy_cwd["active_top_level_count"] == 3
assert "native_cwd:students" in legacy_cwd["mismatch_classes"]
assert "native_cwd:swallow" in legacy_cwd["mismatch_classes"]
assert legacy_cwd["roles"]["harness"]["native_cwd"] is True
assert legacy_cwd["roles"]["students"]["native_cwd"] is False
assert legacy_cwd["roles"]["swallow"]["native_cwd"] is False
assert drift["kind"] == "phone-mirror-drift"

connection.execute(
    "UPDATE threads SET cwd = ? WHERE id = 'thread-students'",
    (target_paths["students"],),
)
connection.commit()
mapping["students"]["cwd"] = target_paths["students"]
mapping["students"]["native_cwd"] = True
partially_native, _drift = module.phone_mirror_snapshot(
    mapping, str(database), processes, target_paths, str(codex_home)
)
assert partially_native["status"] == "degraded"
assert partially_native["active_top_level_count"] == 3
assert partially_native["roles"]["students"]["exact_cwd"] is True
assert partially_native["roles"]["students"]["native_cwd"] is True
assert partially_native["roles"]["swallow"]["native_cwd"] is False
assert "native_cwd:swallow" in partially_native["mismatch_classes"]

connection.execute(
    "UPDATE threads SET cwd = ? WHERE id = 'thread-swallow'",
    (target_paths["swallow"],),
)
connection.commit()
mapping["swallow"]["cwd"] = target_paths["swallow"]
mapping["swallow"]["native_cwd"] = True
healthy, _drift = module.phone_mirror_snapshot(
    mapping, str(database), processes, target_paths, str(codex_home)
)
assert healthy["status"] == "healthy"
assert healthy["mismatch_classes"] == []

connection.execute(
    "UPDATE threads SET source = 'exec' WHERE id = 'thread-swallow'"
)
connection.commit()
ineligible, _drift = module.phone_mirror_snapshot(
    mapping, str(database), processes, target_paths, str(codex_home)
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
    mapping, str(database), processes, target_paths, str(codex_home)
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
    mapping, str(database), processes, target_paths, str(codex_home)
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
connection.execute(
    "INSERT INTO threads VALUES (?, ?, ?, ?, ?, ?, ?)",
    (
        "thread-exec",
        str(extra_rollout),
        "exec",
        harness_root,
        "exec",
        0,
        "exec",
    ),
)
connection.commit()
extra, drift = module.phone_mirror_snapshot(
    mapping, str(database), processes, target_paths, str(codex_home)
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

unknown_status=0
helper --enqueue-blocked \
    --target unknown \
    --runtime unknown-recovery-t351 \
    --thread thread-unknown \
    --watcher-pid 4249 \
    --watcher-start 123459 \
    --app-server-pid 4349 \
    --app-server-start 654329 \
    --window-id @99 \
    --window-index 9 >"$TEST_ROOT/unknown.out" 2>"$TEST_ROOT/unknown.err" ||
    unknown_status=$?
[ "$unknown_status" -eq 2 ] ||
    fail "unknown target did not exit 2"
for area in events receipts logs
do
    [ ! -e "$RUNTIME/$area" ] ||
        fail "unknown target created $area state"
done
[ -z "$(find "$CAPTURE" -mindepth 1 -print -quit)" ] ||
    fail "unknown target invoked the worker"

completed=0
for target in harness students swallow
do
    case "$target" in
        harness)
            index=0
            repository=$ROOT
            ;;
        students)
            index=1
            repository=/mnt/nfs-03/safe/Users/rioyokota/codex-workspaces/students
            ;;
        swallow)
            index=2
            repository=/mnt/nfs-03/safe/Users/rioyokota/codex-workspaces/swallow
            ;;
    esac
    helper --enqueue-blocked \
        --target "$target" \
        --runtime "$target-recovery-t351" \
        --thread "thread-$target" \
        --watcher-pid "$((4240 + index))" \
        --watcher-start "12345$index" \
        --app-server-pid "$((4340 + index))" \
        --app-server-start "65432$index" \
        --window-id "@9$index" \
        --window-index "$index" >"$TEST_ROOT/enqueue-$target.out"
    grep -F 'enqueue=queued' "$TEST_ROOT/enqueue-$target.out" >/dev/null ||
        fail "$target blocked event was not queued"

    completed=$((completed + 1))
    helper --once >"$TEST_ROOT/once-$target.out"
    grep -F "completed=$completed" "$TEST_ROOT/once-$target.out" >/dev/null ||
        fail "$target ephemeral worker did not complete"
    grep -F "Exact managed target: $target" "$CAPTURE/prompt" >/dev/null ||
        fail "$target recovery prompt identity is absent"
    grep -F "Exact target repository: $repository" \
        "$CAPTURE/prompt" >/dev/null ||
        fail "$target recovery prompt repository is absent"
done

[ -f "$CAPTURE/control-environment" ] ||
    fail "worker control environment was not checked"
[ ! -e "$CAPTURE/control-leak" ] ||
    fail "worker inherited a Harness control variable"
[ "$(wc -l <"$CAPTURE/arguments" | tr -d ' ')" = 3 ] ||
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
[ "$(wc -l <"$CAPTURE/arguments" | tr -d ' ')" = 3 ] ||
    fail "completed event was retried"

helper --enqueue-blocked \
    --target swallow \
    --runtime swallow-recovery-t351 \
    --thread thread-swallow \
    --watcher-pid 4242 \
    --watcher-start 123452 \
    --app-server-pid 4342 \
    --app-server-start 654322 \
    --window-id @92 \
    --window-index 2 >"$TEST_ROOT/duplicate.out"
grep -F 'enqueue=already-queued' "$TEST_ROOT/duplicate.out" >/dev/null ||
    fail "duplicate event was not deduplicated"

if helper --status >"$TEST_ROOT/status.out"; then
    fail "one-shot helper was reported live"
fi
grep -F 'phase=stale' "$TEST_ROOT/status.out" >/dev/null ||
    fail "one-shot helper status is not stale"
grep -F 'completed=3' "$TEST_ROOT/status.out" >/dev/null ||
    fail "helper status lost completion"

python3 - "$RUNTIME/receipts" <<'PY'
import json
import pathlib
import stat
import sys

paths = sorted(pathlib.Path(sys.argv[1]).glob("*.json"))
assert len(paths) == 3
for path in paths:
    value = json.loads(path.read_text())
    assert value["phase"] == "completed"
    assert value["returncode"] == 0
    assert stat.S_IMODE(path.stat().st_mode) == 0o600
PY

printf '%s\n' "Codex recovery helper tests: PASS"
