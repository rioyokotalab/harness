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
fields = ["S", "17"] + ["0"] * 17 + ["424242"] + ["0"] * 3
value = "23 (codex TUI) " + " ".join(fields)
parsed = module.parse_proc_stat(23, value)
assert parsed == {
    "pid": 23,
    "parent": 17,
    "start": "424242",
    "comm": "codex TUI",
}

module.tmux_clients = lambda: []
module.read_thread = lambda _module, _backend, _thread: ("idle", True)
module.process_info = lambda pid: {
    "pid": pid,
    "parent": 1,
    "start": "server-start",
    "comm": "codex.real",
    "argv": [],
}
mapping = {
    "harness": {
        "runtime": "saved-runtime",
        "thread": "saved-thread",
        "app_server_pid": 99,
        "app_server_start": "server-start",
    }
}
health = {
    "harness": {
        "reason": "watcher-absent",
        "app_server_pid": 99,
        "identity": {"runtime": "different-runtime", "thread": "different-thread"},
        "tui": {"pid": 23, "start": "tui-start"},
    }
}
assert module.repair_once([], health, mapping, object(), object()) == "none"
mapping["harness"]["app_server_start"] = "reused-pid"
health["harness"]["identity"] = {
    "runtime": "saved-runtime",
    "thread": "saved-thread",
}
assert module.repair_once([], health, mapping, object(), object()) == "none"

mapping["harness"]["app_server_start"] = "server-start"
def process_after_signal(pid):
    if pid == 23:
        if process_after_signal.tui_live:
            process_after_signal.tui_live = False
            return {
                "pid": 23,
                "parent": 1,
                "start": "tui-start",
                "comm": "codex.real",
                "argv": [],
            }
        return None
    return {
        "pid": pid,
        "parent": 1,
        "start": "server-start",
        "comm": "codex.real",
        "argv": [],
    }

process_after_signal.tui_live = True
module.process_info = process_after_signal
thread_reads = iter((("idle", True), ("active", True)))
module.read_thread = lambda _module, _backend, _thread: next(thread_reads)
module.os.kill = lambda pid, signum: None
module.time.sleep = lambda _seconds: None
module.tmux_windows = lambda: []
launches = []
module.launch_window = lambda name, index, saved: launches.append(
    (name, index, saved)
)
assert (
    module.repair_once([], health, mapping, object(), object())
    == "retired-harness"
)
assert launches == []

process_after_signal.tui_live = True
module.tmux_clients = lambda: [("client", "@attached")]
module.read_thread = lambda _module, _backend, _thread: ("idle", True)
module.os.kill = lambda _pid, _signum: (_ for _ in ()).throw(
    AssertionError("attached TUI was signaled")
)
health["harness"]["window"] = {"window_id": "@attached"}
assert module.repair_once([], health, mapping, object(), object()) == "none"
PY

cat >"$TEST_ROOT/healthy.json" <<'EOF'
{"windows":[{"name":"harness","index":0},{"name":"students","index":1},{"name":"swallow","index":2}],"health":{"harness":{"state":"healthy"},"students":{"state":"healthy"},"swallow":{"state":"healthy"}}}
EOF
run_fixture "$TEST_ROOT/healthy.json" --enforce-order --repair \
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

cat >"$TEST_ROOT/repair.json" <<'EOF'
{"windows":[{"name":"harness","index":0},{"name":"students","index":1},{"name":"swallow","index":2}],"health":{"harness":{"state":"unhealthy","reason":"watcher-absent","thread_status":"active","mapping":true},"students":{"state":"unhealthy","reason":"watcher-absent","thread_status":"idle","mapping":true},"swallow":{"state":"healthy"}}}
EOF
if run_fixture "$TEST_ROOT/repair.json" --repair \
    >"$TEST_ROOT/repair.out"; then
    fail "degraded repair fixture returned healthy"
fi
grep -F 'repair_action=repair-eligible-students' \
    "$TEST_ROOT/repair.out" >/dev/null ||
    fail "safe idle repair selection"

cat >"$TEST_ROOT/unsafe.json" <<'EOF'
{"windows":[{"name":"harness","index":0},{"name":"students","index":1},{"name":"swallow","index":2}],"health":{"harness":{"state":"unhealthy","reason":"window-missing","thread_status":"systemError","mapping":true},"students":{"state":"unhealthy","reason":"watcher-absent","thread_status":"idle","mapping":false},"swallow":{"state":"healthy"}}}
EOF
if run_fixture "$TEST_ROOT/unsafe.json" --repair \
    >"$TEST_ROOT/unsafe.out"; then
    fail "unsafe repair fixture returned healthy"
fi
grep -F 'repair_action=none' "$TEST_ROOT/unsafe.out" >/dev/null ||
    fail "unsafe or unmapped state selected repair"

if HARNESS_TEST_TMUX_CODEX_FIXTURE="$TEST_ROOT/healthy.json" \
    "$HARNESS" tmux-codex-monitor --once >"$TEST_ROOT/no-test.out" 2>&1; then
    fail "test fixture bypassed testing gate"
fi

printf '%s\n' "tmux Codex monitor tests: PASS"
