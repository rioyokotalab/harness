#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/harness-personal-agent-test.XXXXXX")

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

personal=$TEST_ROOT/personal
runtime=$TEST_ROOT/runtime
capture=$TEST_ROOT/capture
mkdir -m 700 "$personal" "$runtime" "$capture"
mkdir -m 700 "$personal/.codex" "$personal/.claude" "$personal/config"
for required in AGENTS.md CLAUDE.md TODO.md; do
    printf '%s\n' fixture >"$personal/$required"
done
printf '%s\n' 'model = "gpt-5.6-sol"' >"$personal/.codex/config.toml"
printf '%s\n' '{}' >"$personal/.claude/settings.json"
printf '%s\n' \
    '# client	domain	status	reason' \
    'codex	email	blocked	test' \
    'codex	calendar	blocked	test' \
    'codex	research-budget	blocked	test' \
    'claude	email	blocked	test' \
    'claude	calendar	blocked	test' \
    'claude	research-budget	blocked	test' \
    >"$personal/config/connector-readiness.tsv"
printf '%s\n' '{"mcpServers":{}}' >"$personal/config/empty-mcp.json"
git -C "$personal" init -q -b main

fake_codex=$TEST_ROOT/codex
fake_claude=$TEST_ROOT/claude
cat >"$fake_codex" <<'EOF'
#!/bin/sh
set -eu
env | sed -n '/^HARNESS_/p' >"$PERSONAL_CAPTURE/codex.env"
printf '%s\n' "$@" >"$PERSONAL_CAPTURE/codex.args"
sed -n '1,20p' >"$PERSONAL_CAPTURE/codex.stdin"
printf 'codex-result\n'
EOF
cat >"$fake_claude" <<'EOF'
#!/bin/sh
set -eu
env | sed -n '/^HARNESS_/p' >"$PERSONAL_CAPTURE/claude.env"
env | sed -n \
    -e '/^CLAUDE_CODE_DISABLE_AUTO_MEMORY=/p' \
    -e '/^CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=/p' \
    -e '/^DISABLE_TELEMETRY=/p' \
    -e '/^DISABLE_ERROR_REPORTING=/p' \
    -e '/^DISABLE_BUG_COMMAND=/p' \
    -e '/^CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=/p' \
    >"$PERSONAL_CAPTURE/claude.retention"
printf '%s\n' "$@" >"$PERSONAL_CAPTURE/claude.args"
sed -n '1,20p' >"$PERSONAL_CAPTURE/claude.stdin"
printf 'claude-result\n'
EOF
chmod 700 "$fake_codex" "$fake_claude"

run_agent() {
    HARNESS_TESTING=1 \
    HARNESS_TEST_PERSONAL_ROOT="$personal" \
    HARNESS_TEST_RUNTIME_ROOT="$runtime" \
    HARNESS_TEST_NATIVE_CODEX="$fake_codex" \
    HARNESS_TEST_NATIVE_CLAUDE="$fake_claude" \
    PERSONAL_CAPTURE="$capture" \
        "$HARNESS" personal-agent "$@"
}

run_agent --status >"$TEST_ROOT/status.out"
grep -F 'status=ready root=ready lock=free connectors=blocked managed_target=false' \
    "$TEST_ROOT/status.out" >/dev/null || fail status

printf '%s\n' 'bounded codex fixture' |
    run_agent --run --client codex --task P-TEST-1 --domain local \
        >"$TEST_ROOT/codex.out" 2>"$TEST_ROOT/codex.err"
grep -Fx codex-result "$TEST_ROOT/codex.out" >/dev/null ||
    fail 'Codex output'
grep -Fx 'bounded codex fixture' "$capture/codex.stdin" >/dev/null ||
    fail 'Codex stdin'
[ ! -s "$capture/codex.env" ] || fail 'Codex Harness environment leak'
for argument in exec --ephemeral --ignore-user-config --strict-config \
    gpt-5.6-sol danger-full-access 'history.persistence="none"' \
    'web_search="disabled"'; do
    grep -Fx -- "$argument" "$capture/codex.args" >/dev/null ||
        fail "Codex argument: $argument"
done

printf '%s\n' 'bounded claude fixture' |
    run_agent --run --client claude --task P-TEST-2 --domain local \
        >"$TEST_ROOT/claude.out" 2>"$TEST_ROOT/claude.err"
grep -Fx claude-result "$TEST_ROOT/claude.out" >/dev/null ||
    fail 'Claude output'
grep -Fx 'bounded claude fixture' "$capture/claude.stdin" >/dev/null ||
    fail 'Claude stdin'
[ ! -s "$capture/claude.env" ] || fail 'Claude Harness environment leak'
for argument in --print --no-session-persistence --no-chrome \
    --strict-mcp-config fable high opus dontAsk Read Grep Glob Edit Write \
    'Bash(git *)' 'Bash(./bin/validate)' 'Bash(harness *)'; do
    grep -Fx -- "$argument" "$capture/claude.args" >/dev/null ||
        fail "Claude argument: $argument"
done
[ "$(wc -l <"$capture/claude.retention" | tr -d ' ')" = 6 ] ||
    fail 'Claude retention environment'

grep -Fx 'state=complete' "$runtime/harness-personal-agent/last.receipt" \
    >/dev/null || fail receipt-state
grep -Fx 'result=success' "$runtime/harness-personal-agent/last.receipt" \
    >/dev/null || fail receipt-result
if grep -F 'bounded' "$runtime/harness-personal-agent/last.receipt" >/dev/null; then
    fail 'prompt leaked into receipt'
fi

if printf '%s\n' blocked |
    run_agent --run --client codex --task P-TEST-3 --domain email \
        >"$TEST_ROOT/blocked.out" 2>&1; then
    fail 'blocked connector domain executed'
fi
grep -F 'reason=connector-not-ready' "$TEST_ROOT/blocked.out" >/dev/null ||
    fail 'blocked connector classification'

lock_file=$runtime/harness-personal-agent/operation.lock
flock "$lock_file" sleep 1 &
lock_pid=$!
sleep 0.1
if printf '%s\n' blocked |
    run_agent --run --client claude --task P-TEST-4 --domain local \
        >"$TEST_ROOT/locked.out" 2>&1; then
    fail 'concurrent operation executed'
fi
wait "$lock_pid"
grep -F 'reason=operation-locked' "$TEST_ROOT/locked.out" >/dev/null ||
    fail 'lock classification'

HARNESS_CONTROL_ROOT="$ROOT" HARNESS_TARGET_ROOT="$ROOT" \
    python3 "$ROOT/libexec/harness_codex_targets.py" validate-all \
    >"$TEST_ROOT/targets.out"
grep -F 'CODEX_TARGETS status=ready count=3' "$TEST_ROOT/targets.out" \
    >/dev/null || fail 'managed target count changed'

printf 'PASS: bounded Personal agent launcher\n'
