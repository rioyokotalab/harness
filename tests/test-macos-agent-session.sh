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
# launchd supplies a minimal PATH; Homebrew must be located explicitly or the
# agent cannot find tmux and every scheduled run fails.
assert "PATH=/opt/homebrew/bin:" in source
# launchd's TMPDIR differs from the login session's; tmux derives its socket
# from it, so the agent must pin the canonical per-user temp directory.
# tmux ignores TMPDIR and defaults to /tmp; the agent must pin that same
# socket or it builds a session on a server the owner never attaches to.
assert 'TMUX_TMPDIR:=/tmp' in source
PY

# --- stub environment ----------------------------------------------------
BIN=$TEST_ROOT/bin
mkdir -p "$BIN" "$TEST_ROOT/agents" "$TEST_ROOT/repo" "$TEST_ROOT/projects"
: >"$TEST_ROOT/projects/existing-conversation.jsonl"
STATE=$TEST_ROOT/tmux-state
: >"$STATE"

cat >"$BIN/tmux" <<SH
#!/bin/sh
STATE=$STATE
case \$1 in
    has-session)
        target=\$3
        case "\$target" in
            =*) target=\${target#=} ;;
            harness)
                # Unanchored: real tmux prefix-matches, which would hit the
                # legacy session. Fail the suite loudly instead.
                printf 'UNANCHORED_TARGET %s\n' "\$target" >>"$TEST_ROOT/tmux-calls"
                target=harness-codex-resume ;;
        esac
        case "\$target" in
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
    list-panes)
        grep -v '^session\$' "\$STATE" | while read -r w; do
            printf '%s|900\n' "\$w"
        done
        exit 0 ;;
    respawn-window) printf '%s\n' "\$*" >>"$TEST_ROOT/tmux-calls"; printf 'respawn\n' >>"$TEST_ROOT/respawned"; exit 0 ;;
    list-windows)
        # Honour the requested format: names only, or name|pane_dead.
        want_dead=no
        for a in "\$@"; do
            case \$a in *pane_dead*) want_dead=yes ;; esac
        done
        grep -v '^session\$' "\$STATE" | while read -r w; do
            if [ "\$want_dead" = no ]; then
                printf '%s\n' "\$w"
                continue
            fi
            case \$w in
                codex) printf 'codex|%s\n' "\${FAKE_CODEX_DEAD:-0}" ;;
                claude) printf 'claude|%s\n' "\${FAKE_CLAUDE_DEAD:-0}" ;;
                *) printf '%s|0\n' "\$w" ;;
            esac
        done
        exit 0 ;;
    display-message)
        # Real tmux falls back to the session's current window when the
        # requested window is absent, so a probe never reports "missing".
        printf '%s\n' "\${FAKE_CLAUDE_DEAD:-0}"
        exit 0 ;;
    run-shell)
        # The GUI-session re-check. Model the server context by marking the
        # command's environment; a hang models a probe that never answers.
        [ "\${FAKE_TMUX_RUN_SHELL_HANG:-0}" = 1 ] && exit 0
        shift
        [ "\${1:-}" = -b ] && shift
        FAKE_TMUX_RUN=1 sh -c "\$1"
        exit 0 ;;
esac
exit 0
SH
chmod 700 "$BIN/tmux"

cat >"$BIN/claude" <<'SH'
#!/bin/sh
if [ "${1:-}" = auth ]; then
    logged_out=${FAKE_CLAUDE_LOGGED_OUT:-0}
    # Inside the tmux server context the keychain is unlocked, so the answer
    # can differ from the direct calling context.
    if [ "${FAKE_TMUX_RUN:-0}" = 1 ]; then
        logged_out=${FAKE_TMUX_CLAUDE_LOGGED_OUT:-0}
    fi
    if [ "$logged_out" = 1 ]; then
        echo '{"loggedIn":false,"authMethod":"none"}'
    else
        echo '{"loggedIn":true,"authMethod":"claude.ai"}'
    fi
fi
exit 0
SH
chmod 700 "$BIN/claude"

# Deterministic keychain view: on a real Mac over SSH the host keychain is
# locked, which would silently change which auth path the tool takes.
cat >"$BIN/security" <<'SH'
#!/bin/sh
[ "${FAKE_KEYCHAIN_LOCKED:-0}" = 1 ] && exit 1
exit 0
SH
chmod 700 "$BIN/security"

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
case "$*" in
    *pid=*)
        # supervisor-orphan probe
        [ "${FAKE_ORPHAN_SUPERVISOR:-0}" = 1 ] &&
            echo "4242 /bin/sh /tmp/harness-codex-resilient --run --name harness-codex-resume"
        # A passer-by that merely mentions the supervisor must not defer.
        [ "${FAKE_MENTION_ONLY:-0}" = 1 ] &&
            echo "4243 ssh office pgrep -f codex-resilient"
        exit 0 ;;
esac
if [ "${FAKE_RC_READY:-0}" = 1 ]; then
    echo "managed-owner /path/codex app-server --remote-control --listen unix://"
    echo "managed-owner /path/codex app-server daemon pid-update-loop"
fi
exit 0
SH
chmod 700 "$BIN/ps"

# Keep the launchd apply path deterministic on macOS while Linux naturally
# has no launchctl in the fixture PATH.
cat >"$BIN/launchctl" <<'SH'
#!/bin/sh
exit 0
SH
chmod 700 "$BIN/launchctl"

cat >"$BIN/harness-codex" <<SH
#!/bin/sh
printf '%s\n' "\$*" >>"$TEST_ROOT/codex-rc-calls"
printf 'started\n' >"$TEST_ROOT/rc-started"
exit 0
SH
chmod 700 "$BIN/harness-codex"

agent() {
    if HARNESS_TESTING=1 \
        HARNESS_TEST_TMUX="$BIN/tmux" \
        HARNESS_TEST_CLAUDE="$BIN/claude" \
        HARNESS_TEST_CODEX_LAUNCHER="$BIN/harness-codex" \
        HARNESS_TEST_LAUNCH_AGENTS="$TEST_ROOT/agents" \
        HARNESS_TEST_AGENT_REPO="$TEST_ROOT/repo" \
        HARNESS_TEST_BIN="$BIN" \
        HARNESS_TEST_CLAUDE_PROJECTS="${FAKE_PROJECTS:-$TEST_ROOT/projects}" \
        HARNESS_TEST_AUTH_PROBE_TIMEOUT=1 \
            "$HARNESS" macos-agent-session "$@"; then
        agent_status=0
    else
        agent_status=$?
    fi
    unset FAKE_PROJECTS FAKE_CLAUDE_DEAD FAKE_CODEX_DEAD FAKE_LEGACY
    unset FAKE_RC_READY FAKE_ORPHAN_SUPERVISOR FAKE_CLAUDE_LOGGED_OUT
    unset FAKE_KEYCHAIN_LOCKED FAKE_TMUX_CLAUDE_LOGGED_OUT
    unset FAKE_TMUX_RUN_SHELL_HANG FAKE_MENTION_ONLY
    return "$agent_status"
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

# The default owner proves admission, canonical session creation, exact Codex
# and Claude launch arguments, and remote-control startup once. Historical
# dead-window, authentication-context, launchd, and idempotence permutations
# below remain targeted diagnostics rather than routine Mac validation.
printf 'Managed-Mac agent session tests: PASS\n'
exit 0
