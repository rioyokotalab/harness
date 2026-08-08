#!/bin/sh
set -eu

if [ "$(uname -s)" != Linux ]; then
    echo 'FAIL: AL-session owner is Linux-only; selector admitted wrong platform' >&2
    exit 2
fi

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
RUNNER=$ROOT/libexec/harness-al-session-runner
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
# Linux AF_UNIX names include the complete pathname in a 108-byte field.
# Keep the fixture under the caller's isolated TMPDIR when its longest socket
# fits, and otherwise use a unique short /tmp root. This avoids a five-second
# false timeout before Python can bind an overlong fixture pathname.
socket_path_probe=$TEMP_BASE/harness-al-session-test.XXXXXX/home-terminal-permanent/.ssh/agent.sock
socket_path_bytes=$(printf '%s' "$socket_path_probe" | LC_ALL=C wc -c |
    tr -d ' ')
if [ "$socket_path_bytes" -gt 107 ]; then
    TEMP_BASE=$(CDPATH='' cd -- /tmp && pwd -P)
fi
if [ "${HARNESS_AL_SESSION_TEST_BASE_ONLY:-0}" = 1 ]; then
    printf '%s\n' "$TEMP_BASE"
    exit 0
fi
TEST_ROOT=$(mktemp -d "$TEMP_BASE/harness-al-session-test.XXXXXX")

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEST_ROOT" ]; then
        "$CLEANUP" "$HARNESS" "$TEMP_BASE" "$TEST_ROOT" \
            "$TEMP_BASE" >/dev/null || cleanup_failed=1
    fi
    [ "$status" -ne 0 ] || [ "$cleanup_failed" -eq 0 ] || status=1
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

long_tmp=$TEST_ROOT/long-temporary-directory-for-unix-socket-path-fallback
mkdir "$long_tmp"
short_tmp=$(CDPATH='' cd -- /tmp && pwd -P)
selected_tmp=$(HARNESS_AL_SESSION_TEST_BASE_ONLY=1 TMPDIR="$long_tmp" "$0")
[ "$selected_tmp" = "$short_tmp" ] ||
    fail "long TMPDIR did not select a socket-safe fixture root"
multibyte_tmp=$TEST_ROOT/界界界界界界界界界界界界界界界界界界界界
mkdir "$multibyte_tmp"
selected_tmp=$(HARNESS_AL_SESSION_TEST_BASE_ONLY=1 TMPDIR="$multibyte_tmp" "$0")
[ "$selected_tmp" = "$short_tmp" ] ||
    fail "multibyte TMPDIR did not use byte-length socket guard"

for contract in \
    '-o ControlMaster=no -o ControlPath=none' \
    'AL session start requires a current-user SSH agent socket' \
    'systemd-run --user' \
    'mode=start target=ready'
do
    grep -F -- "$contract" "$ROOT/libexec/harness-al-session" \
        "$ROOT/libexec/harness-al-session-runner" >/dev/null ||
        fail "missing AL-session contract: $contract"
done
echo 'PASS: AL session essential contract'
exit 0
