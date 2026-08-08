#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
if [ "$(uname -s)" != Darwin ]; then
    printf '%s\n' 'darwin preflight: SKIP (requires Darwin)'
    exit 0
fi

HARNESS=$ROOT/bin/harness
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/harness-darwin-preflight.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TIMINGS=${HARNESS_TEST_TIMINGS_FILE:-$TEMP_DIR/timings.json}

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEMP_DIR" ]; then
        "$CLEANUP" "$HARNESS" "$TEMP_BASE" "$TEMP_DIR" "$TEMP_BASE" \
            >/dev/null || cleanup_failed=1
    fi
    [ "$status" -ne 0 ] || [ "$cleanup_failed" -eq 0 ] || status=1
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

python3 "$ROOT/tools/run-focused-tests.py" \
    --root "$ROOT" \
    --manifest "$ROOT/tests/darwin-preflight.tsv" \
    --log-dir "$TEMP_DIR/logs" \
    --timings-file "$TIMINGS" \
    --jobs auto \
    --reserve-cpus 1 \
    --heavy-jobs 1
printf '%s\n' 'darwin preflight: PASS (full tests/test-phase1.sh still required)'
