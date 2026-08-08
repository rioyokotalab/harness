#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
unset HARNESS_ROOT HARNESS_CONTROL_ROOT HARNESS_TARGET_ROOT
unset HARNESS_CODEX_RELEASE_COMMIT HARNESS_CODEX_RELEASE_PAYLOAD
unset HARNESS_CODEX_RELEASE_TARGET
HARNESS=$ROOT/bin/harness
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/harness-phase1.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TIMINGS=${HARNESS_TEST_TIMINGS_FILE:-$TEMP_DIR/focused-timings.json}

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

case ${HARNESS_TEST_JOBS:-auto} in
    legacy) jobs=1 ;;
    auto) jobs=auto ;;
    ''|*[!0-9]*)
        printf '%s\n' 'FAIL: HARNESS_TEST_JOBS must be auto, legacy, or an integer' >&2
        exit 1
        ;;
    *) jobs=$HARNESS_TEST_JOBS ;;
esac

python3 "$ROOT/tools/run-focused-tests.py" \
    --root "$ROOT" \
    --manifest "$ROOT/tests/focused-suites.tsv" \
    --log-dir "$TEMP_DIR/focused-logs" \
    --timings-file "$TIMINGS" \
    --jobs "$jobs"
printf '%s\n' 'phase-1 harness tests passed'
