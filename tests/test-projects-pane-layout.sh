#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
# tmux Unix socket paths have a small platform limit; Darwin's TMPDIR alone
# can consume most of it.
TEMP_BASE=$(CDPATH='' cd -- /tmp && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/hpl.XXXXXX")
SOCKET_DIR=$TEST_ROOT/socket
SOCKET_PATH=$SOCKET_DIR/tmux.sock
mkdir -m 700 "$SOCKET_DIR"

# The explicit private socket and removal of inherited TMUX are both mandatory.
# This fixture must be incapable of discovering or mutating the user's server.
tmux_test() {
    env -u TMUX tmux -S "$SOCKET_PATH" "$@"
}

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -S "$SOCKET_PATH" ] && tmux_test has-session -t harness 2>/dev/null; then
        tmux_test kill-server || cleanup_failed=1
    fi
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

pane_field() {
    tmux_test display-message -p -t "$1" "$2"
}

assert_even() {
    widths=$(tmux_test list-panes -t "$1" -F '#{pane_width}')
    minimum=$(printf '%s\n' "$widths" | sort -n | head -n 1)
    maximum=$(printf '%s\n' "$widths" | sort -n | tail -n 1)
    [ $((maximum - minimum)) -le 1 ] || fail "$1 panes are not even-horizontal"
}

set_codex_role() {
    pane=$1
    role=$2
    tmux_test set-option -p -t "$pane" @harness_target "$role"
    tmux_test select-pane -t "$pane" -T "$role"
}

set_claude_role() {
    pane=$1
    role=$2
    session_id=$3
    tmux_test set-option -p -t "$pane" @harness_claude_target "$role"
    tmux_test set-option -p -t "$pane" @harness_claude_session_id "$session_id"
    tmux_test set-option -p -t "$pane" remain-on-exit on
    tmux_test select-pane -t "$pane" -T "$role"
}

label_window() {
    window=$1
    format=$2
    tmux_test select-layout -t "$window" even-horizontal >/dev/null
    tmux_test set-option -w -t "$window" pane-border-status top
    tmux_test set-option -w -t "$window" pane-border-format "$format"
}

command -v tmux >/dev/null 2>&1 || fail "tmux unavailable"
grep -F -x 'bind-key z resize-pane -Z' "$ROOT/config/tmux/tmux.conf" \
    >/dev/null || fail "managed pane zoom binding"

mkfifo "$TEST_ROOT/pane-hold"
hold="exec cat '$TEST_ROOT/pane-hold'"
tmux_test -f /dev/null new-session -d -s harness -n cowork "$hold"
tmux_test split-window -d -h -t harness:cowork "$hold"
tmux_test new-window -d -t harness:1 -n codex "$hold"
tmux_test split-window -d -h -t harness:codex "$hold"
tmux_test new-window -d -t harness:2 -n claude "$hold"
tmux_test split-window -d -h -t harness:claude "$hold"

set_codex_role harness:cowork.0 harness
set_claude_role harness:cowork.1 harness 00000000-0000-4000-8000-000000000001
set_codex_role harness:codex.0 personal
set_codex_role harness:codex.1 students
set_claude_role harness:claude.0 personal 00000000-0000-4000-8000-000000000002
set_claude_role harness:claude.1 students 00000000-0000-4000-8000-000000000003

label_window harness:cowork \
    ' #{pane_index}:#{?#{@harness_target},codex/#{@harness_target},claude/#{@harness_claude_target}} '
label_window harness:codex ' #{pane_index}:codex/#{@harness_target} '
label_window harness:claude ' #{pane_index}:claude/#{@harness_claude_target} '

[ "$(tmux_test list-windows -t harness -F '#{window_index}:#{window_name}' | tr '\n' ' ')" = \
    '0:cowork 1:codex 2:claude ' ] || fail "canonical window topology"
[ "$(tmux_test list-panes -s -t harness \
    -F '#{window_index}:#{pane_index}:#{@harness_target}:#{@harness_claude_target}' | tr '\n' ' ')" = \
    '0:0:harness: 0:1::harness 1:0:personal: 1:1:students: 2:0::personal 2:1::students ' ] ||
    fail "canonical pane roles"
[ "$(tmux_test list-panes -s -t harness \
    -F '#{@harness_claude_target}:#{remain-on-exit}' | sed -n '/^[^:]/p' | tr '\n' ' ')" = \
    'harness:on personal:on students:on ' ] || fail "Claude dead-pane durability"

assert_even harness:cowork
assert_even harness:codex
assert_even harness:claude

[ "$(pane_field harness:cowork.0 '#{window_zoomed_flag}')" = 0 ] ||
    fail "initial pane zoom state"
tmux_test resize-pane -Z -t harness:cowork.0
[ "$(pane_field harness:cowork.0 '#{window_zoomed_flag}')" = 1 ] ||
    fail "pane zoom activation"
tmux_test resize-pane -Z -t harness:cowork.0
[ "$(pane_field harness:cowork.0 '#{window_zoomed_flag}')" = 0 ] ||
    fail "pane zoom restoration"

[ "$(tmux_test list-sessions -F '#{session_name}')" = harness ] ||
    fail "private fixture session"

echo 'final harness pane layout tests: PASS'
