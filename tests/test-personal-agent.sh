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

path_mode() {
    case $(uname -s) in
        Darwin) stat -f '%Lp' "$1" ;;
        *) stat -c '%a' -- "$1" ;;
    esac
}

personal=$TEST_ROOT/personal
runtime=$TEST_ROOT/runtime
capture=$TEST_ROOT/capture
state=$TEST_ROOT/state
profile=$state/harness-personal-agent/google
mkdir -m 700 "$personal" "$runtime" "$capture" "$state"
mkdir -m 700 "$personal/.codex" "$personal/.claude" "$personal/config" \
    "$personal/bin"
for required in AGENTS.md CLAUDE.md TODO.md; do
    printf '%s\n' fixture >"$personal/$required"
done
printf '%s\n' 'model = "gpt-5.6-sol"' \
    '[mcp_servers.personal-google-readonly]' \
    'enabled = false' >"$personal/.codex/config.toml"
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
printf '%s\n' '{"mcpServers":{"personal-google-readonly":{"command":"fixture"}}}' \
    >"$personal/config/personal-mcp.json"
printf '%s\n' '#!/bin/sh' 'exit 0' >"$personal/bin/personal-google-mcp"
# The single quotes intentionally preserve fixture-runtime expansion.
# shellcheck disable=SC2016
printf '%s\n' \
    '#!/bin/sh' \
    'set -eu' \
    'env | sed -n '\''/^HARNESS_/p'\'' >"$PERSONAL_CAPTURE/write.env"' \
    'env | sed -n '\''/^PERSONAL_GOOGLE_/p'\'' >"$PERSONAL_CAPTURE/write.profile-env"' \
    'cat >"$PERSONAL_CAPTURE/write.stdin"' \
    'if grep -F ambiguous "$PERSONAL_CAPTURE/write.stdin" >/dev/null; then' \
    '    exit 3' \
    'fi' \
    'if grep -F rejected "$PERSONAL_CAPTURE/write.stdin" >/dev/null; then' \
    '    exit 2' \
    'fi' \
    'printf '\''PERSONAL_CALENDAR_WRITE status=complete operation=fixture result=deleted\n'\'' >&2' \
    >"$personal/bin/personal-google-calendar-write"
# The single quotes intentionally preserve fixture-runtime expansion.
# shellcheck disable=SC2016
printf '%s\n' \
    '#!/bin/sh' \
    'set -eu' \
    'printf "%s\n" "$@" >"$PERSONAL_CAPTURE/auth.args"' \
    'helper=' \
    'while [ "$#" -gt 0 ]; do' \
    '    if [ "$1" = --browser-helper ]; then helper=$2; shift 2; else shift; fi' \
    'done' \
    'if [ -n "$helper" ]; then' \
    '    printf "%s" "https://accounts.google.com/o/oauth2/v2/auth?fixture=1" | "$helper"' \
    'fi' \
    'printf "synthetic-auth\n"' \
    >"$personal/bin/personal-google-auth"
chmod 700 "$personal/bin/personal-google-mcp" \
    "$personal/bin/personal-google-auth" \
    "$personal/bin/personal-google-calendar-write"
git -C "$personal" init -q -b main

fake_codex=$TEST_ROOT/codex
fake_claude=$TEST_ROOT/claude
cat >"$fake_codex" <<'EOF'
#!/bin/sh
set -eu
env | sed -n '/^HARNESS_/p' >"$PERSONAL_CAPTURE/codex.env"
env | sed -n '/^PERSONAL_GOOGLE_/p' \
    >"$PERSONAL_CAPTURE/codex.connector-env"
printf '%s\n' "$@" >"$PERSONAL_CAPTURE/codex.args"
sed -n '1,20p' >"$PERSONAL_CAPTURE/codex.stdin"
printf 'codex-result\n'
EOF
cat >"$fake_claude" <<'EOF'
#!/bin/sh
set -eu
env | sed -n '/^HARNESS_/p' >"$PERSONAL_CAPTURE/claude.env"
env | sed -n '/^PERSONAL_GOOGLE_/p' \
    >"$PERSONAL_CAPTURE/claude.connector-env"
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

fake_ssh=$TEST_ROOT/ssh
cat >"$fake_ssh" <<'EOF'
#!/bin/sh
set -eu
case " $* " in
    *' -O forward '*)
        printf '%s\n' "$@" >"$PERSONAL_CAPTURE/tunnel.args"
        printf active >"$PERSONAL_CAPTURE/tunnel.active"
        exit 0
        ;;
    *' -O cancel '*)
        printf '%s\n' "$@" >"$PERSONAL_CAPTURE/tunnel-cleanup.args"
        printf stopped >"$PERSONAL_CAPTURE/tunnel.stopped"
        exit 0
        ;;
esac
printf '%s\n' "$@" >"$PERSONAL_CAPTURE/browser-ssh.args"
cat >"$PERSONAL_CAPTURE/browser-ssh.stdin"
EOF
chmod 700 "$fake_ssh"

run_agent() {
    HARNESS_TESTING=1 \
    HARNESS_TEST_PERSONAL_ROOT="$personal" \
    HARNESS_TEST_RUNTIME_ROOT="$runtime" \
    HARNESS_TEST_PROFILE_ROOT="$profile" \
    HARNESS_TEST_NATIVE_CODEX="$fake_codex" \
    HARNESS_TEST_NATIVE_CLAUDE="$fake_claude" \
    HARNESS_TEST_SSH="$fake_ssh" \
    PERSONAL_GOOGLE_BACKEND=fixture \
    PERSONAL_GOOGLE_FIXTURE=/unexpected \
    PERSONAL_CAPTURE="$capture" \
        "$HARNESS" personal-agent "$@"
}

run_agent --status >"$TEST_ROOT/status.out"
grep -F 'status=ready root=ready lock=free profile=absent privacy=blocked connectors=blocked managed_target=false' \
    "$TEST_ROOT/status.out" >/dev/null || fail status
if [ "$(uname -s)" = Darwin ] &&
    { [ -e "$runtime/harness-personal-agent/operation.lock.d" ] ||
      [ -L "$runtime/harness-personal-agent/operation.lock.d" ]; }; then
    fail 'Darwin status retained its operation lock'
fi

run_agent --profile-bootstrap >"$TEST_ROOT/bootstrap.out"
[ -d "$profile" ] && [ ! -L "$profile" ] ||
    fail 'profile bootstrap type'
[ "$(path_mode "$profile")" = 700 ] ||
    fail 'profile bootstrap permissions'
run_agent --privacy-attest --provider openai --value off \
    >"$TEST_ROOT/openai.out"
run_agent --privacy-attest --provider anthropic --value off \
    >"$TEST_ROOT/anthropic.out"
[ "$(path_mode "$profile/privacy.tsv")" = 600 ] ||
    fail 'privacy marker permissions'

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
if grep -Fx 'mcp_servers.personal-google-readonly.enabled=true' \
    "$capture/codex.args" >/dev/null; then
    fail 'local Codex connector enabled'
fi
[ ! -s "$capture/codex.connector-env" ] ||
    fail 'local Codex connector environment'

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
[ ! -s "$capture/claude.connector-env" ] ||
    fail 'local Claude connector environment'

grep -Fx 'state=complete' "$runtime/harness-personal-agent/last.receipt" \
    >/dev/null || fail receipt-state
grep -Fx 'result=success' "$runtime/harness-personal-agent/last.receipt" \
    >/dev/null || fail receipt-result
if grep -F 'bounded' "$runtime/harness-personal-agent/last.receipt" >/dev/null; then
    fail 'prompt leaked into receipt'
fi

grep -F 'kill -0 "$existing_pid"' "$ROOT/libexec/harness-personal-agent" \
    >/dev/null || fail 'live lock-owner contract'
grep -F 'fail operation-locked' "$ROOT/libexec/harness-personal-agent" \
    >/dev/null || fail 'concurrent operation refusal contract'

# Status, privacy gates, bounded Codex/Claude launches, environment isolation,
# and value-free receipts are the essential default surface. Connector-domain,
# OAuth, write, and lock mutation matrices below are targeted integration
# diagnostics and no longer run for every launcher change.
printf 'PASS: bounded Personal agent launcher\n'
exit 0
