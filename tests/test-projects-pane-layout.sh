#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/harness-projects-pane-layout-test.XXXXXX")
SOCKET_DIR=$TEST_ROOT/socket
SOCKET_NAME=projects-pane-layout
mkdir "$SOCKET_DIR"

tmux_test() {
    TMUX_TMPDIR=$SOCKET_DIR tmux -L "$SOCKET_NAME" "$@"
}

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if TMUX_TMPDIR=$SOCKET_DIR tmux -L "$SOCKET_NAME" has-session \
        -t projects 2>/dev/null; then
        TMUX_TMPDIR=$SOCKET_DIR tmux -L "$SOCKET_NAME" kill-server ||
            cleanup_failed=1
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
    pane=$1
    format=$2
    tmux_test display-message -p -t "$pane" "$format"
}

assert_pane_identity() {
    pane=$1
    expected_id=$2
    expected_pid=$3
    [ "$(pane_field "$pane" '#{pane_id}')" = "$expected_id" ] ||
        fail "$pane pane ID changed"
    [ "$(pane_field "$pane" '#{pane_pid}')" = "$expected_pid" ] ||
        fail "$pane process changed"
}

command -v tmux >/dev/null 2>&1 || fail "tmux unavailable"
grep -F -x 'bind-key z resize-pane -Z' "$ROOT/config/tmux/tmux.conf" \
    >/dev/null || fail "managed pane zoom binding"

tmux_test -f /dev/null new-session -d -s projects -n harness 'exec sleep 600'
tmux_test new-window -d -t projects:1 -n students 'exec sleep 600'
tmux_test new-window -d -t projects:2 -n swallow 'exec sleep 600'

harness_id=$(pane_field projects:harness.0 '#{pane_id}')
harness_pid=$(pane_field "$harness_id" '#{pane_pid}')
students_id=$(pane_field projects:students.0 '#{pane_id}')
students_pid=$(pane_field "$students_id" '#{pane_pid}')
swallow_id=$(pane_field projects:swallow.0 '#{pane_id}')
swallow_pid=$(pane_field "$swallow_id" '#{pane_pid}')

tmux_test join-pane -d -s "$students_id" -t "$harness_id"
tmux_test join-pane -d -s "$swallow_id" -t "$harness_id"
tmux_test rename-window -t "$harness_id" codex
tmux_test set-option -p -t "$harness_id" @harness_target harness
tmux_test set-option -p -t "$students_id" @harness_target students
tmux_test set-option -p -t "$swallow_id" @harness_target swallow
tmux_test select-pane -t "$harness_id" -T harness
tmux_test select-pane -t "$students_id" -T students
tmux_test select-pane -t "$swallow_id" -T swallow
tmux_test swap-pane -d -s "$harness_id" -t projects:codex.0
tmux_test swap-pane -d -s "$students_id" -t projects:codex.1
tmux_test select-layout -t projects:codex main-vertical >/dev/null
tmux_test set-option -w -t projects:codex pane-border-status top
tmux_test set-option -w -t projects:codex pane-border-format \
    ' #{pane_index}:#{@harness_target} '

[ "$(tmux_test list-windows -t projects -F '#{window_index}:#{window_name}')" = \
    '0:codex' ] || fail "canonical sole window"
[ "$(tmux_test list-panes -t projects:codex \
    -F '#{pane_index}:#{pane_title}:#{@harness_target}' | tr '\n' ' ')" = \
    '0:harness:harness 1:students:students 2:swallow:swallow ' ] ||
    fail "canonical pane order and roles"
[ "$(tmux_test list-panes -t projects:codex \
    -F '#{pane_index}:#{pane_title}' | tr '\n' ' ')" = \
    '0:harness 1:students 2:swallow ' ] || fail "canonical pane order"
[ "$(tmux_test display-message -p -t projects:codex \
    '#{pane-border-status}|#{pane-border-format}')" = \
    'top| #{pane_index}:#{@harness_target} ' ] || fail "stable pane labels"
assert_pane_identity projects:codex.0 "$harness_id" "$harness_pid"
assert_pane_identity projects:codex.1 "$students_id" "$students_pid"
assert_pane_identity projects:codex.2 "$swallow_id" "$swallow_pid"

[ "$(pane_field "$harness_id" '#{window_zoomed_flag}')" = 0 ] ||
    fail "initial pane zoom state"
tmux_test resize-pane -Z -t "$harness_id"
[ "$(pane_field "$harness_id" '#{window_zoomed_flag}')" = 1 ] ||
    fail "pane zoom activation"
tmux_test resize-pane -Z -t "$harness_id"
[ "$(pane_field "$harness_id" '#{window_zoomed_flag}')" = 0 ] ||
    fail "pane zoom restoration"

tmux_test break-pane -d -s "$students_id" -t projects:1 -n students
tmux_test break-pane -d -s "$swallow_id" -t projects:2 -n swallow
tmux_test rename-window -t "$harness_id" harness

[ "$(tmux_test list-windows -t projects \
    -F '#{window_index}:#{window_name}' | tr '\n' ' ')" = \
    '0:harness 1:students 2:swallow ' ] || fail "rollback window topology"
assert_pane_identity projects:harness.0 "$harness_id" "$harness_pid"
assert_pane_identity projects:students.0 "$students_id" "$students_pid"
assert_pane_identity projects:swallow.0 "$swallow_id" "$swallow_pid"
[ "$(tmux_test list-panes -s -t projects -F '#{@harness_target}' |
    sort | tr '\n' ' ')" = 'harness students swallow ' ] ||
    fail "rollback pane roles"

echo 'projects pane layout tests: PASS'
