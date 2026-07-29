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
    python3 -B - <<'PY'
import importlib.machinery
import os

module = importlib.machinery.SourceFileLoader(
    "tmux_monitor_test", os.environ["HARNESS_MONITOR_PATH"]
).load_module()
with open(os.environ["HARNESS_MONITOR_PATH"], "r") as stream:
    source = stream.read()
assert "Backend(" not in source
assert "def read_thread(" not in source
assert "def repair_once(" not in source
assert "def launch_window(" not in source
assert "os.kill(" not in source
fields = ["S", "17"] + ["0"] * 17 + ["424242"] + ["0"] * 3
value = "23 (codex TUI) " + " ".join(fields)
parsed = module.parse_proc_stat(23, value)
assert parsed == {
    "pid": 23,
    "parent": 17,
    "start": "424242",
    "comm": "codex TUI",
}

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
    }
}
assert module.mapping_snapshot(mapping, health) == {
    "students": {"preserved": True},
    "harness": {
        "runtime": "runtime",
        "thread": "thread",
        "app_server_pid": 99,
        "app_server_start": "server-start",
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
}
module.resilient_status = lambda _runtime: (
    {"phase": "running", "owner_pid": "10"},
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
            "path": os.environ["HARNESS_ROOT"],
            "dead": False,
        }
    ]
)
assert codex_0146["students"]["state"] == "healthy"
assert codex_0146["students"]["tui"]["pid"] == 11
assert codex_0146["students"]["app_server_pid"] == 99
PY

cat >"$TEST_ROOT/healthy.json" <<'EOF'
{"windows":[{"name":"harness","index":0},{"name":"students","index":1},{"name":"swallow","index":2}],"health":{"harness":{"state":"healthy"},"students":{"state":"healthy"},"swallow":{"state":"healthy"}}}
EOF
run_fixture "$TEST_ROOT/healthy.json" --enforce-order \
    >"$TEST_ROOT/healthy.out"
grep -F 'phase=healthy healthy=3 order_action=none repair_action=none' \
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
    fail "observe-only monitor selected repair"

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
