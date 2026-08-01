#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/harness-tmux-claude-monitor-test.XXXXXX")

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

MONITOR=$ROOT/libexec/harness-tmux-claude-monitor
RECOVERY=$ROOT/libexec/harness-claude-pane-recovery

# --- source audits -------------------------------------------------------
python3 -B - "$MONITOR" "$RECOVERY" <<'PY'
import pathlib
import sys

monitor = pathlib.Path(sys.argv[1]).read_text()
recovery = pathlib.Path(sys.argv[2]).read_text()
for source in (monitor, recovery):
    assert "capture-pane" not in source
    assert "read-pane" not in source
    assert "send-keys" not in source
    assert "paste-buffer" not in source
    assert "kill-pane" not in source
assert "respawn-pane" not in monitor
assert "respawn-pane" in recovery
assert "-k" not in recovery.split("respawn-pane")[1].splitlines()[0]
assert "claude-pane-blocked" in monitor
assert "PANE_ROLE_OPTION" in monitor and "PANE_ROLE_OPTION" in recovery
PY

# --- synthetic target profile -------------------------------------------
PROFILE=$TEST_ROOT/claude-session-targets.tsv
REPO_A=$TEST_ROOT/repo-a
REPO_B=$TEST_ROOT/repo-b
REPO_C=$TEST_ROOT/repo-c
for repo in "$REPO_A" "$REPO_B" "$REPO_C"; do
    mkdir -p "$repo"
    git -C "$repo" init -q
    printf '@AGENTS.md\n' > "$repo/CLAUDE.md"
done
{
    printf '# target\twindow_index\twindow_name\tpane_index\tcanonical_repository\n'
    printf 'harness\t0\tcowork\t1\t%s\n' "$REPO_A"
    printf 'personal\t2\tclaude\t0\t%s\n' "$REPO_A"
    printf 'students\t2\tclaude\t1\t%s\n' "$REPO_C"
} > "$PROFILE"

# --- module unit tests ----------------------------------------------------
HARNESS_TESTING=1 \
HARNESS_TEST_CLAUDE_TARGETS_FILE="$PROFILE" \
HARNESS_TEST_RUNTIME_DIR="$TEST_ROOT/monitor-runtime" \
HARNESS_TEST_RECOVERY_RUNTIME_DIR="$TEST_ROOT/helper-runtime" \
python3 -B - "$MONITOR" "$TEST_ROOT" <<'PY'
import importlib.machinery
import json
import os
import sys
import time

module = importlib.machinery.SourceFileLoader(
    "claude_monitor", sys.argv[1]
).load_module()
test_root = sys.argv[2]

REPOS = {value["name"]: value["repository"] for value in module.TARGETS}
SESSIONS = {
    "harness": "00000000-0000-4000-8000-000000000001",
    "personal": "00000000-0000-4000-8000-000000000002",
    "students": "00000000-0000-4000-8000-000000000003",
}
PIDS = {"harness": 4000, "personal": 4001, "students": 4002}
PID_SESSIONS = {value: SESSIONS[name] for name, value in PIDS.items()}


def pane(name, index, **overrides):
    window_index, window_name, expected_index = module.TARGET_LOCATIONS[name]
    value = {
        "window_index": window_index,
        "window_id": "@9",
        "window_name": window_name,
        "pane_index": expected_index,
        "pane_id": "%{}".format(10 + PIDS[name] - 4000),
        "role": name,
        "session_id": SESSIONS[name],
        "pane_pid": PIDS[name],
        "path": REPOS[name],
        "dead": False,
        "remain_on_exit": True,
    }
    value.update(overrides)
    return value


HEALTHY = [pane("harness", 1), pane("personal", 0), pane("students", 1)]

# healthy matrix
module.process_identity = lambda pid: {
    "pid": pid,
    "uid": os.getuid(),
    "start": "1",
    "argv": ["claude", "--resume", PID_SESSIONS[pid]],
}
health = module.collect_health(HEALTHY)
assert all(value["state"] == "healthy" for value in health.values()), health

# Claude panes must survive process exit so the monitor can recover the exact
# saved session in place.
no_remain = [pane("harness", 1, remain_on_exit=False), pane("personal", 0), pane("students", 1)]
health = module.collect_health(no_remain)
assert health["harness"]["reason"] == "metadata"
assert not module.canonical_topology(no_remain)

# dead pane -> blocked/pane-dead (dead panes report an empty cwd)
dead = [pane("harness", 1, dead=True, path=""), pane("personal", 0), pane("students", 1)]
health = module.collect_health(dead)
assert health["harness"]["state"] == "blocked"
assert health["harness"]["reason"] == "pane-dead"

# wrong cwd -> native-cwd
wrong = [pane("harness", 1, path="/somewhere"), pane("personal", 0), pane("students", 1)]
health = module.collect_health(wrong)
assert health["harness"]["reason"] == "native-cwd"

# missing pane
health = module.collect_health(HEALTHY[1:])
assert health["harness"]["reason"] == "pane-missing"

# foreign process -> process-identity
module.process_identity = lambda pid: {
    "pid": pid,
    "uid": os.getuid(),
    "start": "1",
    "argv": ["bash"],
}
health = module.collect_health(HEALTHY)
assert health["harness"]["reason"] == "process-identity"
module.process_identity = lambda pid: {
    "pid": pid,
    "uid": os.getuid(),
    "start": "1",
    "argv": ["claude", "--resume", PID_SESSIONS[pid]],
}

ROOT_DIR = module.runtime_root()

# recovery candidates: attached pane deferred inside the grace window
module.tmux_clients = lambda: "client0\t%10\n"
candidates, selection = module.recovery_candidates(
    dead, module.collect_health(dead), ROOT_DIR
)
assert candidates == [] and selection == "deferred-target-attached", (
    candidates,
    selection,
)

# attached dead pane recovers once the bounded grace expires
grace_path = os.path.join(ROOT_DIR, "attached-dead.json")
with open(grace_path, "w") as stream:
    json.dump({"%10:4000": int(time.time()) - 3600}, stream)
os.chmod(grace_path, 0o600)
candidates, selection = module.recovery_candidates(
    dead, module.collect_health(dead), ROOT_DIR
)
assert selection == "candidates" and candidates, (candidates, selection)
os.unlink(grace_path)

# recovery candidates: unattached pane queues with continue relaunch
module.tmux_clients = lambda: ""
candidates, selection = module.recovery_candidates(
    dead, module.collect_health(dead), ROOT_DIR
)
assert selection == "candidates" and len(candidates) == 1
assert candidates[0]["target"] == "harness"
assert candidates[0]["relaunch"] == "exact"
assert candidates[0]["session_id"] == SESSIONS["harness"]

# rate limit: three recent events defer; exact resume never changes selector
events_dir = os.path.join(module.helper_runtime_root(), "events")
receipts_dir = os.path.join(module.helper_runtime_root(), "receipts")
os.makedirs(events_dir, mode=0o700, exist_ok=True)
os.makedirs(receipts_dir, mode=0o700, exist_ok=True)


def write_event(name, phase, offset=0):
    payload = {
        "schema": 1,
        "event": name,
        "identity": {"kind": "claude-pane-blocked", "target": "harness"},
        "created_ns": time.time_ns() - offset,
    }
    path = os.path.join(events_dir, "{}.json".format(name))
    with open(path, "w") as stream:
        json.dump(payload, stream)
    os.chmod(path, 0o600)
    receipt = os.path.join(receipts_dir, "{}.json".format(name))
    with open(receipt, "w") as stream:
        json.dump({"phase": phase}, stream)
    os.chmod(receipt, 0o600)


write_event("aa", "failed")
candidates, selection = module.recovery_candidates(
    dead, module.collect_health(dead), ROOT_DIR
)
assert candidates and candidates[0]["relaunch"] == "exact"

write_event("bb", "completed")
write_event("cc", "completed")
candidates, selection = module.recovery_candidates(
    dead, module.collect_health(dead), ROOT_DIR
)
assert candidates == [] and selection == "deferred-target-attached"

# enqueue argv shape
calls = []


class FakeResult:
    returncode = 0


def fake_run(arguments, **_kwargs):
    calls.append(arguments)
    return FakeResult()


module.subprocess.run = fake_run
assert module.enqueue_helper_recovery(
    {
        "target": "harness",
        "window_id": "@9",
        "window_index": 0,
        "pane_id": "%10",
        "pane_index": 1,
        "pane_pid": 4000,
        "relaunch": "exact",
        "session_id": SESSIONS["harness"],
    }
)
argv = calls[0]
assert argv[0].endswith("harness-codex-recovery-helper")
assert "--enqueue-claude-blocked" in argv
assert "--relaunch" in argv and "exact" in argv
assert "--session-id" in argv and SESSIONS["harness"] in argv
print("module unit tests: PASS")
PY

# --- fixture end-to-end ----------------------------------------------------
FIXTURE=$TEST_ROOT/fixture.json
cat > "$FIXTURE" <<'JSON'
{"health": {"harness": {"state": "healthy", "reason": "ready"},
            "personal": {"state": "healthy", "reason": "ready"},
            "students": {"state": "healthy", "reason": "ready"}}}
JSON
OUTPUT=$(HARNESS_TESTING=1 HARNESS_TEST_TMUX_CLAUDE_FIXTURE="$FIXTURE" \
    "$HARNESS" tmux-claude-monitor --once)
printf '%s\n' "$OUTPUT" | grep -Fq \
    "TMUX_CLAUDE_MONITOR phase=healthy healthy=3" ||
    fail "healthy fixture summary missing"

cat > "$FIXTURE" <<'JSON'
{"health": {"harness": {"state": "blocked", "reason": "pane-dead"},
            "personal": {"state": "healthy", "reason": "ready"},
            "students": {"state": "healthy", "reason": "ready"}},
 "repair_action": "helper-queued-1"}
JSON
if OUTPUT=$(HARNESS_TESTING=1 HARNESS_TEST_TMUX_CLAUDE_FIXTURE="$FIXTURE" \
    "$HARNESS" tmux-claude-monitor --once); then
    fail "degraded fixture should exit nonzero"
else
    :
fi
OUTPUT=$(HARNESS_TESTING=1 HARNESS_TEST_TMUX_CLAUDE_FIXTURE="$FIXTURE" \
    "$HARNESS" tmux-claude-monitor --once) || true
printf '%s\n' "$OUTPUT" | grep -Fq "repair_action=helper-queued-1" ||
    fail "degraded fixture repair action missing"
HARNESS_TEST_TMUX_CLAUDE_FIXTURE="$FIXTURE" \
    "$HARNESS" tmux-claude-monitor --once >/dev/null 2>&1 &&
    fail "fixture must require the test gate" || :

# --- helper end-to-end with stub recovery worker ---------------------------
CAPTURE=$TEST_ROOT/capture
mkdir -p "$CAPTURE"
FAKE_RECOVERY=$TEST_ROOT/fake-claude-recovery
cat > "$FAKE_RECOVERY" <<SH
#!/bin/sh
printf '%s\n' "\$*" > "$CAPTURE/recovery-arguments"
printf 'RECOVERY_RESULT status=accepted target=harness pane=%%10 relaunch=exact\n'
SH
chmod 700 "$FAKE_RECOVERY"
HELPER_RUNTIME=$TEST_ROOT/helper-e2e
mkdir -p "$HELPER_RUNTIME"
chmod 700 "$HELPER_RUNTIME"
helper() {
    HARNESS_TESTING=1 \
    HARNESS_TEST_RUNTIME_DIR="$HELPER_RUNTIME" \
    HARNESS_TEST_CLAUDE_RECOVERY="$FAKE_RECOVERY" \
    HARNESS_TEST_SKIP_DETECTION=1 \
        "$HARNESS" codex-recovery-helper "$@"
}
OUTPUT=$(helper --enqueue-claude-blocked --target harness \
    --window-id @9 --window-index 0 --pane-id %10 --pane-index 1 \
    --pane-pid 4000 --pane-start 12345 --relaunch exact \
    --session-id 00000000-0000-4000-8000-000000000001)
printf '%s\n' "$OUTPUT" | grep -Fq "enqueue=queued" || fail "claude enqueue failed"
OUTPUT=$(helper --enqueue-claude-blocked --target harness \
    --window-id @9 --window-index 0 --pane-id %10 --pane-index 1 \
    --pane-pid 4000 --pane-start 12345 --relaunch exact \
    --session-id 00000000-0000-4000-8000-000000000001)
printf '%s\n' "$OUTPUT" | grep -Fq "enqueue=already-queued" ||
    fail "claude enqueue dedup failed"
helper --once --interval 5 >/dev/null || fail "helper once failed"
grep -q -- "--relaunch exact" "$CAPTURE/recovery-arguments" ||
    fail "recovery worker arguments missing"
python3 -B - "$HELPER_RUNTIME" <<'PY'
import json
import os
import sys

root = sys.argv[1]
if not os.path.isdir(os.path.join(root, "receipts")):
    root = os.path.join(
        root, "harness-codex-recovery-helper-{}".format(os.getuid())
    )
receipts = os.listdir(os.path.join(root, "receipts"))
assert len(receipts) == 1, receipts
with open(os.path.join(root, "receipts", receipts[0])) as stream:
    receipt = json.load(stream)
assert receipt["phase"] == "completed", receipt
assert receipt["returncode"] == 0, receipt
print("helper claude event: PASS")
PY

# --- recovery worker unit test with stub tmux and claude -------------------
FAKE_TMUX=$TEST_ROOT/fake-tmux
STATE=$TEST_ROOT/tmux-state
printf 'dead\n' > "$STATE"
cat > "$FAKE_TMUX" <<SH
#!/bin/sh
if [ "\$1" = "display-message" ]; then
    if [ "\$(cat "$STATE")" = "dead" ]; then
        printf 'harness\t@9\tcowork\t0\t%%10\t1\t1\t0\t\tharness\t00000000-0000-4000-8000-000000000001\n'
    else
        printf 'harness\t@9\tcowork\t0\t%%10\t1\t0\t%s\t$REPO_A\tharness\t00000000-0000-4000-8000-000000000001\n' "\$PPID"
    fi
    exit 0
fi
if [ "\$1" = "respawn-pane" ]; then
    printf '%s\n' "\$*" >> "$CAPTURE/tmux-respawn"
    printf 'alive\n' > "$STATE"
    exit 0
fi
exit 1
SH
chmod 700 "$FAKE_TMUX"
FAKE_CLAUDE=$TEST_ROOT/fake-claude
printf '#!/bin/sh\nexit 0\n' > "$FAKE_CLAUDE"
chmod 700 "$FAKE_CLAUDE"
OUTPUT=$(HARNESS_TESTING=1 \
    HARNESS_TEST_CLAUDE_TARGETS_FILE="$PROFILE" \
    HARNESS_TEST_TMUX="$FAKE_TMUX" \
    HARNESS_TEST_CLAUDE="$FAKE_CLAUDE" \
    "$HARNESS" claude-pane-recovery --target harness --window-id @9 \
    --window-index 0 --pane-id %10 --pane-index 1 --pane-pid 4000 \
    --pane-start 12345 --relaunch exact \
    --session-id 00000000-0000-4000-8000-000000000001)
printf '%s\n' "$OUTPUT" | grep -Fq "RECOVERY_RESULT status=accepted" ||
    fail "recovery worker did not accept"
grep -q -- "--resume 00000000-0000-4000-8000-000000000001" \
    "$CAPTURE/tmux-respawn" || fail "respawn command missing exact resume"
grep -q "respawn-pane -t %10" "$CAPTURE/tmux-respawn" ||
    fail "respawn target missing"

# alive pane is rejected without respawn
printf 'alive\n' > "$STATE"
rm -f "$CAPTURE/tmux-respawn"
if OUTPUT=$(HARNESS_TESTING=1 \
    HARNESS_TEST_CLAUDE_TARGETS_FILE="$PROFILE" \
    HARNESS_TEST_TMUX="$FAKE_TMUX" \
    HARNESS_TEST_CLAUDE="$FAKE_CLAUDE" \
    "$HARNESS" claude-pane-recovery --target harness --window-id @9 \
    --window-index 0 --pane-id %10 --pane-index 1 --pane-pid 4000 \
    --pane-start 12345 --relaunch exact \
    --session-id 00000000-0000-4000-8000-000000000001); then
    fail "alive pane must be rejected"
else
    printf '%s\n' "$OUTPUT" | grep -Fq "status=rejected reason=pane-alive" ||
        fail "alive rejection reason missing"
fi
[ ! -f "$CAPTURE/tmux-respawn" ] || fail "alive pane must not be respawned"

printf 'Local tmux Claude monitor tests: PASS\n'
