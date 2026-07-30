#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/harness-tmux-codex-monitor-test.XXXXXX")

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

run_fixture() {
    fixture=$1
    shift
    HARNESS_TESTING=1 HARNESS_TEST_TMUX_CODEX_FIXTURE="$fixture" \
        "$HARNESS" tmux-codex-monitor --once "$@"
}

HARNESS_MONITOR_PATH="$ROOT/libexec/harness-tmux-codex-monitor" \
HARNESS_MONITOR_ROOT="$ROOT" \
    python3 -B - <<'PY'
import importlib.machinery
import os
import tempfile

os.environ["HARNESS_ROOT"] = os.environ["HARNESS_MONITOR_ROOT"]
module = importlib.machinery.SourceFileLoader(
    "tmux_monitor_test", os.environ["HARNESS_MONITOR_PATH"]
).load_module()
assert module.SESSION_NAME == "projects"
with open(os.environ["HARNESS_MONITOR_PATH"], "r") as stream:
    source = stream.read()
assert "Backend(" not in source
assert "def read_thread(" not in source
assert "def repair_once(" not in source
assert "def launch_window(" not in source
assert "os.kill(" not in source
assert "capture-pane" not in source
assert "read-pane" not in source
assert "thread/read" not in source
assert "paste-buffer" not in source
assert "send-keys" not in source
fields = ["S", "17"] + ["0"] * 17 + ["424242"] + ["0"] * 3
value = "23 (codex TUI) " + " ".join(fields)
parsed = module.parse_proc_stat(23, value)
assert parsed == {
    "pid": 23,
    "parent": 17,
    "start": "424242",
    "comm": "codex TUI",
}
snapshot_fixture = {
    1: {"pid": 1, "parent": 0},
    2: {"pid": 2, "parent": 1},
    3: {"pid": 3, "parent": 2},
    4: {"pid": 4, "parent": 9},
}
assert [
    item["pid"]
    for item in module.snapshot_descendants(1, snapshot_fixture)
] == [2, 3]
module.socket_pairs = lambda: [
    (101, 202, 11),
    (202, 101, 99),
    (303, 404, 12),
]
assert module.reciprocal_socket_snapshot() == {11: 99, 99: 11}

with tempfile.TemporaryDirectory() as helper_root:
    os.environ["HARNESS_TESTING"] = "1"
    os.environ["HARNESS_TEST_RECOVERY_RUNTIME_DIR"] = helper_root
    current = module.process_info(os.getpid())
    roles = {
        name: {
            "tmux_mapping": True,
            "unarchived": True,
            "exact_name": True,
            "exact_cwd": True,
            "native_cwd": True,
            "rollout_location": True,
            "rollout_exists": True,
            "interactive_source": True,
        }
        for name, _index in module.EXPECTED
    }
    receipt = {
        "schema": 1,
        "epoch": int(module.time.time()),
        "owner_pid": os.getpid(),
        "owner_start": current["start"],
        "status": "healthy",
        "remote_control": {
            "exactly_one": True,
            "pid": os.getpid(),
            "start": current["start"],
        },
        "canonical_count": 3,
        "active_top_level_count": 3,
        "roles": roles,
        "mismatch_classes": [],
    }
    module.atomic_json(os.path.join(helper_root, "phone-mirror.json"), receipt)
    assert module.phone_mirror_health() == "healthy"
    assert module.phone_mirror_health(processes={os.getpid(): current}) == "healthy"
    receipt["status"] = "degraded"
    receipt["roles"]["swallow"]["interactive_source"] = False
    receipt["mismatch_classes"] = ["interactive_source:swallow"]
    module.atomic_json(os.path.join(helper_root, "phone-mirror.json"), receipt)
    assert module.phone_mirror_health() == "degraded"
    receipt["epoch"] -= 121
    module.atomic_json(os.path.join(helper_root, "phone-mirror.json"), receipt)
    assert module.phone_mirror_health() == "unavailable"

module.process_info = lambda pid: {
    "pid": pid,
    "parent": 1,
    "start": "server-start",
    "comm": "codex.real",
    "argv": [],
}
mapping = {
    "students": {"preserved": True}
}
health = {
    "harness": {
        "state": "healthy",
        "app_server_pid": 99,
        "identity": {"runtime": "runtime", "thread": "thread"},
        "window": {
            "index": 0,
            "window_id": "@0",
            "path": os.environ["HARNESS_MONITOR_ROOT"],
        },
    }
}
assert module.mapping_snapshot(mapping, health) == {
    "students": {"preserved": True},
    "harness": {
        "runtime": "runtime",
        "thread": "thread",
        "app_server_pid": 99,
        "app_server_start": "server-start",
        "index": 0,
        "window_id": "@0",
        "cwd": os.environ["HARNESS_MONITOR_ROOT"],
        "native_cwd": True,
    },
}

def process(pid):
    values = {
        10: {
            "pid": 10,
            "parent": 1,
            "start": "supervisor-start",
            "comm": "harness-codex-r",
            "argv": [],
            "uid": os.getuid(),
        },
        12: {
            "pid": 12,
            "parent": 10,
            "start": "watcher-start",
            "comm": "python3",
            "argv": [],
            "uid": os.getuid(),
        },
        99: {
            "pid": 99,
            "parent": 1,
            "start": "app-server-start",
            "comm": "codex",
            "argv": [],
            "uid": os.getuid(),
        },
    }
    return values.get(pid)

module.process_info = process
module.parse_supervisor = lambda _info: {
    "runtime": "students-t338",
    "thread": "thread-students",
    "start": "supervisor-start",
    "target": "students",
}
module.resilient_status = lambda _target, _runtime: (
    {"target": "students", "phase": "running", "owner_pid": "10"},
    {
        "phase": "watching",
        "owner_pid": "12",
        "thread": "thread-students",
    },
)
module.descendants = lambda _pid: [
    {
        "pid": 11,
        "parent": 10,
        "start": "tui-start",
        "comm": "codex",
        "argv": [],
        "uid": os.getuid(),
    }
]
module.reciprocal_socket = lambda pid: 99 if pid == 11 else None
codex_0146 = module.collect_health(
    [
        {
            "index": 1,
            "window_id": "@fixture",
            "name": "students",
            "panes": 1,
            "pane_id": "%fixture",
            "pane_pid": 10,
            "path": os.environ["HARNESS_MONITOR_ROOT"],
            "dead": False,
        }
    ]
)
assert codex_0146["students"]["state"] == "unhealthy"
assert codex_0146["students"]["reason"] == "native-cwd"
native_window = [
    {
        "index": 1,
        "window_id": "@fixture",
        "name": "students",
        "panes": 1,
        "pane_id": "%fixture",
        "pane_pid": 10,
        "path": module.TARGET_PATHS["students"],
        "dead": False,
    }
]
module.parse_supervisor = lambda _info: {
    "runtime": "students-t338",
    "thread": "thread-students",
    "start": "supervisor-start",
    "target": None,
}
native_missing_target = module.collect_health(native_window)
assert native_missing_target["students"]["state"] == "unhealthy"
assert native_missing_target["students"]["reason"] == "supervisor-target"
module.parse_supervisor = lambda _info: {
    "runtime": "students-t338",
    "thread": "thread-students",
    "start": "supervisor-start",
    "target": "students",
}
native_targeted = module.collect_health(native_window)
assert native_targeted["students"]["state"] == "healthy"
assert native_targeted["students"]["tui"]["pid"] == 11
assert native_targeted["students"]["app_server_pid"] == 99
snapshot_processes = {
    10: process(10),
    11: {
        "pid": 11,
        "parent": 10,
        "start": "tui-start",
        "comm": "codex",
        "argv": [],
        "uid": os.getuid(),
    },
    12: process(12),
    99: process(99),
}
snapshot_targeted = module.collect_health(
    native_window, snapshot_processes, {11: 99, 99: 11}
)
assert snapshot_targeted["students"]["state"] == "healthy"
assert module.mapping_snapshot(
    {},
    snapshot_targeted,
    snapshot_processes,
)["students"]["app_server_start"] == "app-server-start"
module.resilient_status = lambda _target, _runtime: (
    {"target": "students", "phase": "running", "owner_pid": "10"},
    {
        "phase": "blocked",
        "reason": "unsafe-tail",
        "owner_pid": "12",
        "thread": "thread-students",
        "recoveries": "0",
        "rolled_back": "1",
    },
)
unsafe_0146 = module.collect_health(
    [
        {
            "index": 1,
            "window_id": "@fixture",
            "name": "students",
            "panes": 1,
            "pane_id": "%fixture",
            "pane_pid": 10,
            "path": module.TARGET_PATHS["students"],
            "dead": False,
        }
    ]
)
assert unsafe_0146["students"]["state"] == "blocked"
assert unsafe_0146["students"]["reason"] == "unsafe-tail"
module.resilient_status = lambda _target, _runtime: (
    {"target": "students", "phase": "running", "owner_pid": "10"},
    {
        "phase": "blocked",
        "reason": "post-rollback-system-error",
        "owner_pid": "12",
        "thread": "thread-students",
    },
)
other_blocked = module.collect_health(
    [
        {
            "index": 1,
            "window_id": "@fixture",
            "name": "students",
            "panes": 1,
            "pane_id": "%fixture",
            "pane_pid": 10,
            "path": module.TARGET_PATHS["students"],
            "dead": False,
        }
    ]
)
assert other_blocked["students"]["state"] == "unhealthy"
assert other_blocked["students"]["reason"] == "watcher-state"

windows = [
    {
        "index": index,
        "window_id": "@{}".format(index),
        "name": name,
        "panes": 1,
        "pane_id": "%{}".format(index),
        "pane_pid": 10 + index,
        "path": module.TARGET_PATHS[name],
        "dead": False,
    }
    for name, index in module.EXPECTED
]
health = {
    name: {
        "state": "healthy",
        "reason": "ready",
        "window": windows[index],
        "app_server_pid": 99,
        "identity": {
            "runtime": "{}-runtime".format(name),
            "thread": "{}-thread".format(name),
        },
        "recovery": {"phase": "watching", "reason": "thread-idle"},
    }
    for name, index in module.EXPECTED
}
health["swallow"] = {
    "state": "blocked",
    "reason": "unsafe-tail",
    "window": windows[2],
    "app_server_pid": 99,
    "identity": {"runtime": "swallow-runtime", "thread": "swallow-thread"},
    "watcher": {"pid": 42, "start": "watcher-start"},
    "recovery": {
        "phase": "blocked",
        "reason": "unsafe-tail",
        "recoveries": "0",
        "rolled_back": "1",
    },
}
candidates, selection = module.recovery_candidates(windows, health, [])
assert selection == "candidates"
assert len(candidates) == 1
assert candidates[0]["target"] == "swallow"
assert candidates[0]["window_id"] == "@2"
assert module.recovery_candidates(windows, health, [("7", "@2")]) == (
    [],
    "deferred-target-attached",
)
health["harness"]["recovery"]["reason"] = "thread-active"
assert len(module.recovery_candidates(windows, health, [])[0]) == 1
health["harness"]["recovery"]["reason"] = "thread-idle"
health["harness"] = {
    "state": "blocked",
    "reason": "unsafe-tail",
    "window": windows[0],
    "app_server_pid": 99,
    "identity": {"runtime": "harness-runtime", "thread": "harness-thread"},
    "watcher": {"pid": 12, "start": "watcher-start"},
    "recovery": {
        "phase": "blocked",
        "reason": "unsafe-tail",
        "recoveries": "0",
        "rolled_back": "1",
    },
}
candidates, selection = module.recovery_candidates(windows, health, [])
assert selection == "candidates"
assert [value["target"] for value in candidates] == ["harness", "swallow"]
assert module.recovery_candidates(windows, health, [("7", "@0")])[0][0][
    "target"
] == "swallow"

class Result:
    returncode = 0

calls = []
module.subprocess.run = lambda arguments, **_kwargs: calls.append(arguments) or Result()
assert module.enqueue_helper_recovery(candidates[0])
assert len(calls) == 1
assert calls[0][0].endswith("/libexec/harness-codex-recovery-helper")
assert "--enqueue-blocked" in calls[0]
assert "--thread" in calls[0]
PY

cat >"$TEST_ROOT/healthy.json" <<'EOF'
{"windows":[{"name":"harness","index":0},{"name":"students","index":1},{"name":"swallow","index":2}],"health":{"harness":{"state":"healthy"},"students":{"state":"healthy"},"swallow":{"state":"healthy"}}}
EOF
run_fixture "$TEST_ROOT/healthy.json" --enforce-order \
    >"$TEST_ROOT/healthy.out"
grep -F 'phase=healthy healthy=3 phone_mirror=healthy order_action=none repair_action=none' \
    "$TEST_ROOT/healthy.out" >/dev/null || fail "healthy classification"

cat >"$TEST_ROOT/ordered.json" <<'EOF'
{"out_of_order":true,"windows":[{"name":"swallow","index":0},{"name":"harness","index":1},{"name":"students","index":2}],"health":{"harness":{"state":"healthy"},"students":{"state":"healthy"},"swallow":{"state":"healthy"}}}
EOF
run_fixture "$TEST_ROOT/ordered.json" --enforce-order \
    >"$TEST_ROOT/ordered.out"
grep -F 'order_action=ordered' "$TEST_ROOT/ordered.out" >/dev/null ||
    fail "order correction classification"

cat >"$TEST_ROOT/extra.json" <<'EOF'
{"windows":[{"name":"harness","index":0},{"name":"students","index":1},{"name":"swallow","index":2},{"name":"extra","index":3}],"health":{"harness":{"state":"healthy"},"students":{"state":"healthy"},"swallow":{"state":"healthy"},"extra":{"state":"healthy"}}}
EOF
if run_fixture "$TEST_ROOT/extra.json" --enforce-order \
    >"$TEST_ROOT/extra.out"; then
    fail "extra window was accepted healthy"
fi
grep -F 'order_action=deferred-ambiguous' "$TEST_ROOT/extra.out" >/dev/null ||
    fail "extra window did not fail closed"

cat >"$TEST_ROOT/degraded.json" <<'EOF'
{"windows":[{"name":"harness","index":0},{"name":"students","index":1},{"name":"swallow","index":2}],"health":{"harness":{"state":"healthy"},"students":{"state":"unhealthy","reason":"watcher-absent"},"swallow":{"state":"healthy"}}}
EOF
if run_fixture "$TEST_ROOT/degraded.json" \
    >"$TEST_ROOT/degraded.out"; then
    fail "degraded fixture returned healthy"
fi
grep -F 'repair_action=none' "$TEST_ROOT/degraded.out" >/dev/null ||
    fail "generic degradation selected recovery"

cat >"$TEST_ROOT/phone-degraded.json" <<'EOF'
{"phone_mirror":"degraded","windows":[{"name":"harness","index":0},{"name":"students","index":1},{"name":"swallow","index":2}],"health":{"harness":{"state":"healthy"},"students":{"state":"healthy"},"swallow":{"state":"healthy"}}}
EOF
if run_fixture "$TEST_ROOT/phone-degraded.json" \
    >"$TEST_ROOT/phone-degraded.out"; then
    fail "phone-ineligible fixture returned healthy"
fi
grep -F 'phase=degraded healthy=3 phone_mirror=degraded' \
    "$TEST_ROOT/phone-degraded.out" >/dev/null ||
    fail "phone eligibility did not degrade monitor"

cat >"$TEST_ROOT/requested.json" <<'EOF'
{"repair_action":"helper-queued-1","windows":[{"name":"harness","index":0},{"name":"students","index":1},{"name":"swallow","index":2}],"health":{"harness":{"state":"healthy"},"students":{"state":"healthy"},"swallow":{"state":"blocked","reason":"unsafe-tail"}}}
EOF
if run_fixture "$TEST_ROOT/requested.json" \
    >"$TEST_ROOT/requested.out"; then
    fail "requested fixture returned healthy"
fi
grep -F 'repair_action=helper-queued-1' "$TEST_ROOT/requested.out" \
    >/dev/null || fail "helper queue classification"

if run_fixture "$TEST_ROOT/degraded.json" --repair \
    >"$TEST_ROOT/repair-flag.out" 2>&1; then
    fail "retired repair flag was accepted"
fi
grep -F 'unrecognized arguments: --repair' "$TEST_ROOT/repair-flag.out" \
    >/dev/null || fail "retired repair flag diagnostic"

if HARNESS_TEST_TMUX_CODEX_FIXTURE="$TEST_ROOT/healthy.json" \
    "$HARNESS" tmux-codex-monitor --once >"$TEST_ROOT/no-test.out" 2>&1; then
    fail "test fixture bypassed testing gate"
fi

printf '%s\n' "tmux Codex monitor tests: PASS"
