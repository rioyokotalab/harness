#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/harness-macos-agent-session-test.XXXXXX")

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

TOOL=$ROOT/libexec/harness-macos-agent-session

# --- source audit --------------------------------------------------------
python3 -B - "$TOOL" <<'PY'
import pathlib
import sys

source = pathlib.Path(sys.argv[1]).read_text()
for forbidden in ("capture-pane", "read-pane", "send-keys", "paste-buffer",
                  "kill-session", "kill-window", "kill-pane"):
    assert forbidden not in source, forbidden
# The frozen Claude launch contract must be present verbatim.
for required in ("--permission-mode bypassPermissions", "--model fable",
                 "--effort high", "--remote-control", "--continue",
                 "RunAtLoad", "StartInterval"):
    assert required in source, required
PY

# --- stub environment ----------------------------------------------------
BIN=$TEST_ROOT/bin
mkdir -p "$BIN" "$TEST_ROOT/agents" "$TEST_ROOT/repo"
STATE=$TEST_ROOT/tmux-state
: >"$STATE"

cat >"$BIN/tmux" <<SH
#!/bin/sh
STATE=$STATE
case \$1 in
    has-session)
        case "\$3" in
            harness-codex-resume) [ "\${FAKE_LEGACY:-0}" = 1 ] || exit 1; exit 0 ;;
        esac
        grep -q '^session\$' "\$STATE" || exit 1; exit 0 ;;
    new-session) printf 'session\ncodex\n' >>"\$STATE"; printf '%s\n' "\$*" >>"$TEST_ROOT/tmux-calls"; exit 0 ;;
    new-window)
        for a in "\$@"; do
            [ "\$prev" = "-n" ] && printf '%s\n' "\$a" >>"\$STATE"
            prev=\$a
        done
        printf '%s\n' "\$*" >>"$TEST_ROOT/tmux-calls"; exit 0 ;;
    respawn-window) printf '%s\n' "\$*" >>"$TEST_ROOT/tmux-calls"; printf 'respawn\n' >>"$TEST_ROOT/respawned"; exit 0 ;;
    list-windows) grep -v '^session\$' "\$STATE"; exit 0 ;;
    display-message)
        target=\$4
        case "\$target" in
            *:codex) printf '%s\n' "\${FAKE_CODEX_DEAD:-0}" ;;
            *:claude) printf '%s\n' "\${FAKE_CLAUDE_DEAD:-0}" ;;
            *) exit 1 ;;
        esac
        exit 0 ;;
esac
exit 0
SH
chmod 700 "$BIN/tmux"

cat >"$BIN/claude" <<'SH'
#!/bin/sh
exit 0
SH
chmod 700 "$BIN/claude"

# Deterministic process view: readiness must not depend on the host's real ps.
cat >"$BIN/id" <<'SH'
#!/bin/sh
case ${1:-} in
    -un) echo managed-owner ;;
    -u) echo 501 ;;
esac
SH
chmod 700 "$BIN/id"

cat >"$BIN/ps" <<'SH'
#!/bin/sh
if [ "${FAKE_RC_READY:-0}" = 1 ]; then
    echo "managed-owner /path/codex app-server --remote-control --listen unix://"
    echo "managed-owner /path/codex app-server daemon pid-update-loop"
fi
exit 0
SH
chmod 700 "$BIN/ps"

cat >"$BIN/harness-codex" <<SH
#!/bin/sh
printf '%s\n' "\$*" >>"$TEST_ROOT/codex-rc-calls"
printf 'started\n' >"$TEST_ROOT/rc-started"
exit 0
SH
chmod 700 "$BIN/harness-codex"

agent() {
    HARNESS_TESTING=1 \
    HARNESS_TEST_TMUX="$BIN/tmux" \
    HARNESS_TEST_CLAUDE="$BIN/claude" \
    HARNESS_TEST_CODEX_LAUNCHER="$BIN/harness-codex" \
    HARNESS_TEST_LAUNCH_AGENTS="$TEST_ROOT/agents" \
    HARNESS_TEST_AGENT_REPO="$TEST_ROOT/repo" \
    PATH="$BIN:$PATH" \
        "$HARNESS" macos-agent-session "$@"
}

# --- host allow-list -----------------------------------------------------
if agent --host bogus --status >/dev/null 2>&1; then
    fail "unmanaged host accepted"
fi

# --- first run creates the session and both windows ----------------------
OUT=$(agent --host office --run-once) || fail "run-once failed"
printf '%s\n' "$OUT" | grep -Fq 'session=harness' || fail "session name missing"
grep -q 'new-session' "$TEST_ROOT/tmux-calls" || fail "session not created"
grep -q 'claude' "$TEST_ROOT/tmux-calls" || fail "claude window not created"
grep -Fq -- '--permission-mode bypassPermissions' "$TEST_ROOT/tmux-calls" ||
    fail "bypass permissions flag missing from launch"
grep -Fq -- '--model fable' "$TEST_ROOT/tmux-calls" || fail "model flag missing"
grep -Fq -- '--effort high' "$TEST_ROOT/tmux-calls" || fail "effort flag missing"
grep -Fq -- '--remote-control office' "$TEST_ROOT/tmux-calls" ||
    fail "remote control flag missing"

# --- idempotence: a second run creates nothing ---------------------------
: >"$TEST_ROOT/tmux-calls"
OUT=$(agent --host office --run-once) || fail "second run-once failed"
printf '%s\n' "$OUT" | grep -Fq 'ensured= none' || fail "second run was not idempotent"
[ ! -s "$TEST_ROOT/tmux-calls" ] || fail "second run mutated tmux"

# --- a dead window is respawned, a live one is never touched -------------
: >"$TEST_ROOT/tmux-calls"
rm -f "$TEST_ROOT/respawned"
FAKE_CLAUDE_DEAD=1 agent --host office --run-once >/dev/null ||
    fail "respawn run failed"
[ -f "$TEST_ROOT/respawned" ] || fail "dead claude window was not respawned"
grep -Fq 'respawn-window' "$TEST_ROOT/tmux-calls" || fail "respawn call missing"
grep -Fq 'harness:codex' "$TEST_ROOT/tmux-calls" &&
    fail "live codex window must not be respawned"

# --- the codex window is deferred while the legacy session is alive ------
: >"$TEST_ROOT/tmux-calls"
printf 'session\n' >"$STATE"        # unified session exists, no windows yet
FAKE_LEGACY=1 agent --host office --run-once >"$TEST_ROOT/legacy.out" ||
    fail "legacy-aware run failed"
grep -Fq 'codex-deferred-legacy' "$TEST_ROOT/legacy.out" ||
    fail "codex window was not deferred while the legacy session lives"
grep -Fq 'codex-resilient' "$TEST_ROOT/tmux-calls" &&
    fail "a second codex supervisor was started under the same name"
printf 'session\ncodex\nclaude\n' >"$STATE"

# --- codex remote control is started only when absent --------------------
[ -f "$TEST_ROOT/rc-started" ] || fail "codex remote control was not started"

# --- an already-live daemon pair is never restarted ----------------------
rm -f "$TEST_ROOT/rc-started"
FAKE_RC_READY=1 agent --host office --run-once |
    grep -Fq 'codex_remote_control=ready' ||
    fail "a live daemon pair was not recognized"
[ ! -f "$TEST_ROOT/rc-started" ] ||
    fail "codex remote control was restarted while already live"

# --- launchd plan and apply ----------------------------------------------
OUT=$(agent --host office --plan) || fail "plan failed"
printf '%s\n' "$OUT" | grep -Fq 'org.rioyokota.harness.agent-session.office' ||
    fail "plan label missing"
printf '%s\n' "$OUT" | grep -Fq '<integer>30</integer>' ||
    fail "plan interval missing"

OUT=$(agent --host office --apply) || fail "apply failed"
PLIST=$TEST_ROOT/agents/org.rioyokota.harness.agent-session.office.plist
[ -f "$PLIST" ] || fail "plist not installed"
[ "$(stat -c '%a' "$PLIST" 2>/dev/null || stat -f '%Lp' "$PLIST")" = 600 ] ||
    fail "plist mode is not 600"
grep -Fq -- '--run-once' "$PLIST" || fail "plist does not invoke run-once"

# --- apply is repeatable and keeps a rollback point ----------------------
OUT=$(agent --host office --apply) || fail "second apply failed"
TXN=$(printf '%s\n' "$OUT" | sed -n 's/.*transaction=\([^ ]*\).*/\1/p')
[ -n "$TXN" ] || fail "transaction id missing"
ls "$TEST_ROOT/agents"/*.harness-backup-"$TXN" >/dev/null 2>&1 ||
    fail "backup not retained"
agent --rollback "$TXN" >/dev/null || fail "rollback failed"

if agent --rollback 'bad id' >/dev/null 2>&1; then
    fail "malformed transaction id accepted"
fi

printf 'Managed-Mac agent session tests: PASS\n'
