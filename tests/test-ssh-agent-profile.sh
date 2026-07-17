#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/harness-agent-profile-test.XXXXXX")
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
        printf '%s\n' 'FAIL: guarded SSH agent profile cleanup' >&2
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

profile_home=$TEMP_DIR/home
mkdir -p "$profile_home/harness"
cp -R "$ROOT/shell" "$profile_home/harness/"

local_agent_output=$(env -u SSH_AUTH_SOCK HOME="$profile_home" PATH=/usr/bin:/bin \
    XDG_RUNTIME_DIR="$TEMP_DIR/runtime-local" HARNESS_LOGICAL_HOST=local sh -c \
    '. "$HOME/harness/shell/profile.sh"; printf "%s\n" "$SSH_AUTH_SOCK"')
[ "$local_agent_output" = "$TEMP_DIR/runtime-local/openssh_agent" ] ||
    fail "local fixed SSH agent socket"

forwarded_agent_output=$(HOME="$profile_home" PATH=/usr/bin:/bin \
    XDG_RUNTIME_DIR="$TEMP_DIR/runtime-remote" HARNESS_LOGICAL_HOST=ab \
    SSH_AUTH_SOCK=/tmp/forwarded-agent.sock sh -c \
    '. "$HOME/harness/shell/profile.sh"; printf "%s\n" "$SSH_AUTH_SOCK"')
[ "$forwarded_agent_output" = /tmp/forwarded-agent.sock ] ||
    fail "remote forwarded SSH agent socket preservation"

printf '%s\n' 'PASS: SSH agent profile contract'
