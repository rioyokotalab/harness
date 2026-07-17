#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/harness-remote-session-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEMP_DIR" ]; then
        "$CLEANUP" "$HARNESS" "${TMPDIR:-/tmp}" "$TEMP_DIR" \
            "${TMPDIR:-/tmp}" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then
        printf '%s\n' 'FAIL: guarded remote-session cleanup' >&2
        status=1
    fi
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

if grep -Eq 'harness_login_sync|harness_publish_staged|^exit\(\)|git .*fetch|git .*push' \
    "$ROOT/shell/remote-session.sh"; then
    fail "remote-session source retains an automatic Git lifecycle hook"
fi

profile_home=$TEMP_DIR/home
git_log=$TEMP_DIR/git.log
mkdir -p "$profile_home/harness/.git" "$profile_home/.local/bin"
cp -R "$ROOT/shell" "$profile_home/harness/"
cat >"$profile_home/.local/bin/git" <<'EOF'
#!/bin/sh
printf '%s\n' invoked >>"$LOGIN_GIT_LOG"
exit 99
EOF
chmod 755 "$profile_home/.local/bin/git"

direct_output=$(env -u SHLVL -u IGNOREEOF -u TMUX \
    -u HARNESS_INTERACTIVE_LOADED -u HARNESS_REMOTE_SESSION_LOADED \
    HOME="$profile_home" PATH=/usr/bin:/bin SSH_TTY=/dev/pts/test \
    SSH_AUTH_SOCK=/tmp/forwarded-agent.sock HARNESS_LOGICAL_HOST=ab \
    LOGIN_GIT_LOG="$git_log" bash --noprofile --norc -ic \
    '. "$HOME/harness/shell/profile.sh"; printf "%s|%s\n" "$(type -t exit)" "${IGNOREEOF-unset}"' \
    2>/dev/null)
[ "$direct_output" = 'builtin|1' ] || fail "direct SSH policy"
[ ! -e "$git_log" ] || fail "direct SSH startup invoked Git"

tmux_output=$(env -u SHLVL -u IGNOREEOF \
    -u HARNESS_INTERACTIVE_LOADED -u HARNESS_REMOTE_SESSION_LOADED \
    HOME="$profile_home" PATH=/usr/bin:/bin SSH_TTY=/dev/pts/test \
    TMUX=/tmp/tmux HARNESS_LOGICAL_HOST=ab LOGIN_GIT_LOG="$git_log" \
    bash --noprofile --norc -ic \
    '. "$HOME/harness/shell/profile.sh"; printf "%s|%s\n" "$(type -t exit)" "${IGNOREEOF-unset}"' \
    2>/dev/null)
[ "$tmux_output" = 'builtin|unset' ] || fail "tmux exclusion"
[ ! -e "$git_log" ] || fail "tmux startup invoked Git"

nested_output=$(env -u IGNOREEOF -u TMUX \
    -u HARNESS_INTERACTIVE_LOADED -u HARNESS_REMOTE_SESSION_LOADED \
    SHLVL=1 HOME="$profile_home" PATH=/usr/bin:/bin SSH_TTY=/dev/pts/test \
    HARNESS_LOGICAL_HOST=ab LOGIN_GIT_LOG="$git_log" \
    bash --noprofile --norc -ic \
    '. "$HOME/harness/shell/profile.sh"; printf "%s|%s\n" "$(type -t exit)" "${IGNOREEOF-unset}"' \
    2>/dev/null)
[ "$nested_output" = 'builtin|unset' ] || fail "nested-shell exclusion"
[ ! -e "$git_log" ] || fail "nested startup invoked Git"

printf '%s\n' 'PASS: remote-session lifecycle contract'
