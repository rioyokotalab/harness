#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
PROBE=$ROOT/tools/hpc-result-hygiene.sh
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/hpc-result-hygiene.XXXXXX")

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    "$ROOT/tests/guarded-test-cleanup.sh" "$ROOT/bin/harness" \
        "${TMPDIR:-/tmp}" "$TEST_ROOT" "${TMPDIR:-/tmp}" >/dev/null || status=1
    exit "$status"
}
trap cleanup EXIT HUP INT TERM

sh -n "$PROBE"
output=$(HOME=$TEST_ROOT HARNESS_LOGICAL_HOST=local "$PROBE")
printf '%s\n' "$output" | grep -F 'state=absent state_ok=1 results=0 invalid=0 temporary=0 status=pass' >/dev/null
state=$TEST_ROOT/.local/state/harness/hpc-readiness
mkdir -p "$state"
chmod 700 "$state"
touch "$state/t200-ok.out"
chmod 600 "$state/t200-ok.out"
output=$(HOME=$TEST_ROOT HARNESS_LOGICAL_HOST=local "$PROBE")
printf '%s\n' "$output" | grep -F 'state=present state_ok=1 results=1 invalid=0 temporary=0 status=pass' >/dev/null
chmod 644 "$state/t200-ok.out"
if HOME=$TEST_ROOT HARNESS_LOGICAL_HOST=local "$PROBE" >"$TEST_ROOT/failure.out"; then
    printf '%s\n' 'FAIL: mode-0644 result accepted' >&2
    exit 1
fi
grep -F 'results=1 invalid=1 temporary=0 status=fail' "$TEST_ROOT/failure.out" >/dev/null
chmod 600 "$state/t200-ok.out"
touch "$state/.t200-active"
chmod 600 "$state/.t200-active"
output=$(HOME=$TEST_ROOT HARNESS_LOGICAL_HOST=local "$PROBE")
printf '%s\n' "$output" | grep -F 'results=1 invalid=0 temporary=1 status=pass' >/dev/null
printf '%s\n' 'HPC result hygiene tests: PASS'
