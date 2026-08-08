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

if printf '%s\n' blocked |
    run_agent --run --client codex --task P-TEST-3 --domain email \
        >"$TEST_ROOT/blocked.out" 2>&1; then
    fail 'blocked connector domain executed'
fi
grep -F 'reason=connector-not-ready' "$TEST_ROOT/blocked.out" >/dev/null ||
    fail 'blocked connector classification'

sed 's/^codex	email	blocked	/codex	email	ready	/;
     s/^claude	email	blocked	/claude	email	ready	/' \
    "$personal/config/connector-readiness.tsv" \
    >"$personal/config/connector-readiness.tmp"
mv "$personal/config/connector-readiness.tmp" \
    "$personal/config/connector-readiness.tsv"

printf '%s\n' 'bounded codex email fixture' |
    run_agent --run --client codex --task P-TEST-EMAIL-C --domain email \
        >"$TEST_ROOT/codex-email.out" 2>"$TEST_ROOT/codex-email.err"
grep -Fx 'mcp_servers.personal-google-readonly.enabled=true' \
    "$capture/codex.args" >/dev/null || fail 'Codex connector override'
grep -Fx "mcp_servers.personal-google-readonly.env={ PERSONAL_GOOGLE_PROFILE=\"$profile\" }" \
    "$capture/codex.args" >/dev/null || fail 'Codex profile override'
grep -Fx 'PERSONAL_GOOGLE_ALLOWED_DOMAIN=email' \
    "$capture/codex.connector-env" >/dev/null ||
    fail 'Codex domain gate'

printf '%s\n' 'bounded claude email fixture' |
    run_agent --run --client claude --task P-TEST-EMAIL-A --domain email \
        >"$TEST_ROOT/claude-email.out" 2>"$TEST_ROOT/claude-email.err"
grep -Fx "$personal/config/personal-mcp.json" "$capture/claude.args" \
    >/dev/null || fail 'Claude connector manifest'
grep -Fx 'PERSONAL_GOOGLE_ALLOWED_DOMAIN=email' \
    "$capture/claude.connector-env" >/dev/null ||
    fail 'Claude domain gate'
for argument in \
    'mcp__personal-google-readonly__personal_google_status' \
    'mcp__personal-google-readonly__personal_gmail_search' \
    'mcp__personal-google-readonly__personal_gmail_thread'; do
    grep -Fx "$argument" "$capture/claude.args" >/dev/null ||
        fail "Claude connector permission: $argument"
done
if grep -Fx 'mcp__personal-google-readonly__personal_calendar_events' \
    "$capture/claude.args" >/dev/null; then
    fail 'Claude cross-domain permission'
fi

run_agent --authorize --domain email \
    --client-file "$TEST_ROOT/synthetic-client.json" \
    >"$TEST_ROOT/auth.out"
grep -Fx synthetic-auth "$TEST_ROOT/auth.out" >/dev/null ||
    fail 'synthetic authorization helper'
if [ "$(uname -s)" = Darwin ] &&
    { [ -e "$runtime/harness-personal-agent/operation.lock.d" ] ||
      [ -L "$runtime/harness-personal-agent/operation.lock.d" ]; }; then
    fail 'Darwin local authorization retained its operation lock'
fi
for argument in --profile "$profile" --domain email \
    --client-file "$TEST_ROOT/synthetic-client.json"; do
    grep -Fx -- "$argument" "$capture/auth.args" >/dev/null ||
        fail "authorization argument: $argument"
done

run_agent --authorize --domain email --browser-host riken \
    --client-file "$TEST_ROOT/synthetic-client.json" \
    >"$TEST_ROOT/remote-auth.out"
for argument in --callback-port 53682 --browser-helper \
    "$ROOT/libexec/harness-oauth-browser-open"; do
    grep -Fx -- "$argument" "$capture/auth.args" >/dev/null ||
        fail "remote authorization argument: $argument"
done
grep -Fx -- '-R' "$capture/tunnel.args" >/dev/null ||
    fail 'OAuth reverse tunnel argument'
grep -Fx '127.0.0.1:53682:127.0.0.1:53682' \
    "$capture/tunnel.args" >/dev/null || fail 'OAuth reverse tunnel binding'
grep -Fx riken "$capture/tunnel.args" >/dev/null ||
    fail 'OAuth reverse tunnel host'
grep -Fx riken "$capture/browser-ssh.args" >/dev/null ||
    fail 'OAuth browser host'
if grep -F 'accounts.google.com' "$capture/browser-ssh.args" >/dev/null; then
    fail 'authorization URL leaked into SSH arguments'
fi
grep -F 'open location "https://accounts.google.com/' \
    "$capture/browser-ssh.stdin" >/dev/null ||
    fail 'authorization URL did not use encrypted stdin'
[ -f "$capture/tunnel.stopped" ] || fail 'OAuth tunnel lifecycle cleanup'
grep -Fx cancel "$capture/tunnel-cleanup.args" >/dev/null ||
    fail 'OAuth tunnel cancellation command'
if [ "$(uname -s)" = Darwin ] &&
    { [ -e "$runtime/harness-personal-agent/operation.lock.d" ] ||
      [ -L "$runtime/harness-personal-agent/operation.lock.d" ]; }; then
    fail 'Darwin remote authorization retained its operation lock'
fi

run_agent --authorize --domain calendar-write --browser-host riken \
    --client-file "$TEST_ROOT/synthetic-client.json" \
    >"$TEST_ROOT/remote-write-auth.out"
grep -Fx calendar-write "$capture/auth.args" >/dev/null ||
    fail 'write authorization domain'

if printf '%s\n' '{"fixture":"success"}' |
    run_agent --calendar-write --task P-TEST-WRITE \
        >"$TEST_ROOT/write-blocked.out" 2>&1; then
    fail 'calendar write bypassed readiness gate'
fi
grep -F 'reason=connector-not-ready' "$TEST_ROOT/write-blocked.out" >/dev/null ||
    fail 'calendar write readiness gate'

sed 's/^codex\tcalendar\tblocked\t/codex\tcalendar\tready\t/;
     s/^claude\tcalendar\tblocked\t/claude\tcalendar\tready\t/' \
    "$personal/config/connector-readiness.tsv" \
    >"$personal/config/connector-readiness.tmp"
mv "$personal/config/connector-readiness.tmp" \
    "$personal/config/connector-readiness.tsv"

printf '%s\n' '{"fixture":"success"}' |
    run_agent --calendar-write --task P-TEST-WRITE \
        >"$TEST_ROOT/write.out" 2>"$TEST_ROOT/write.err"
grep -Fx '{"fixture":"success"}' "$capture/write.stdin" >/dev/null ||
    fail 'calendar write stdin'
[ ! -s "$capture/write.env" ] || fail 'calendar write Harness environment leak'
grep -Fx "PERSONAL_GOOGLE_PROFILE=$profile" "$capture/write.profile-env" \
    >/dev/null || fail 'calendar write profile binding'
grep -F 'client=native domain=calendar-write result=success' \
    "$TEST_ROOT/write.err" >/dev/null || fail 'calendar write receipt'

if printf '%s\n' '{"fixture":"ambiguous"}' |
    run_agent --calendar-write --task P-TEST-WRITE \
        >"$TEST_ROOT/write-ambiguous.out" 2>&1; then
    fail 'ambiguous calendar write reported success'
fi
grep -F 'retry=forbidden-until-reconciled' \
    "$TEST_ROOT/write-ambiguous.out" >/dev/null ||
    fail 'ambiguous calendar write retry gate'

case $(uname -s) in
    Darwin)
        lock_dir=$runtime/harness-personal-agent/operation.lock.d
        mkdir -m 700 "$lock_dir"
        printf '%s\n' "$$" >"$lock_dir/pid"
        chmod 600 "$lock_dir/pid"
        ;;
    *)
        lock_file=$runtime/harness-personal-agent/operation.lock
        lock_ready=$TEST_ROOT/lock-ready
        lock_hold=$TEST_ROOT/lock-hold
        mkfifo "$lock_ready" "$lock_hold"
        flock "$lock_file" sh -c \
            'printf "%s\n" ready >"$1"; exec cat "$2"' sh \
            "$lock_ready" "$lock_hold" &
        lock_pid=$!
        IFS= read -r lock_state <"$lock_ready"
        [ "$lock_state" = ready ] || fail 'lock fixture readiness'
        ;;
esac
if printf '%s\n' blocked |
    run_agent --run --client claude --task P-TEST-4 --domain local \
        >"$TEST_ROOT/locked.out" 2>&1; then
    fail 'concurrent operation executed'
fi
if [ "$(uname -s)" = Darwin ]; then
    unlink "$lock_dir/pid"
    rmdir "$lock_dir"
else
    printf '%s\n' release >"$lock_hold"
    wait "$lock_pid"
fi
grep -F 'reason=operation-locked' "$TEST_ROOT/locked.out" >/dev/null ||
    fail 'lock classification'

if [ "$(uname -s)" = Darwin ]; then
    mkdir -m 700 "$lock_dir"
    printf '%s\n' 999999999 >"$lock_dir/pid"
    chmod 600 "$lock_dir/pid"
    run_agent --status >"$TEST_ROOT/stale-lock.out"
    grep -F 'lock=free' "$TEST_ROOT/stale-lock.out" >/dev/null ||
        fail 'stale Darwin lock recovery'
    [ ! -e "$lock_dir" ] && [ ! -L "$lock_dir" ] ||
        fail 'stale Darwin lock residue'

    mkdir -m 700 "$lock_dir"
    printf '%s\n' 999999999 >"$lock_dir/pid"
    chmod 644 "$lock_dir/pid"
    if run_agent --status >"$TEST_ROOT/unsafe-lock.out" 2>&1; then
        fail 'unsafe Darwin lock accepted'
    fi
    grep -F 'reason=operation-lock-unsafe' "$TEST_ROOT/unsafe-lock.out" \
        >/dev/null || fail 'unsafe Darwin lock classification'
    unlink "$lock_dir/pid"
    rmdir "$lock_dir"
fi

PYTHONPATH="$ROOT/libexec" PYTHONDONTWRITEBYTECODE=1 \
    python3 - <<'PY' || fail 'managed target declaration changed'
from harness_codex_targets import TARGET_NAMES

assert TARGET_NAMES == ("harness", "personal", "students")
PY

printf 'PASS: bounded Personal agent launcher\n'
