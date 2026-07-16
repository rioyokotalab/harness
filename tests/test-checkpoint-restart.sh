#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
SOURCE=$ROOT/tests/smoke/checkpoint_restart.cpp
JOB=$ROOT/tests/smoke/jobs/checkpoint-restart-readiness.sh
LOCAL_JOB=$ROOT/tests/smoke/jobs/local-checkpoint-restart.slurm
FORMAT_DOC=$ROOT/docs/checkpoint-restart-format.md
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/checkpoint-restart-test.XXXXXX")

fail() { echo "FAIL: $*" >&2; exit 1; }
cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEST_ROOT" ]; then
        "$CLEANUP" "$ROOT/bin/harness" "${TMPDIR:-/tmp}" "$TEST_ROOT" \
            "${TMPDIR:-/tmp}" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then status=1; fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

bash -n "$JOB"
bash -n "$LOCAL_JOB"
grep -F '#YBATCH -r thrp_1' "$LOCAL_JOB" >/dev/null || fail "local native resource"
if grep -E '^#SBATCH --(partition|resource)=' "$LOCAL_JOB" >/dev/null; then
    fail "local resource was expressed as a Slurm option"
fi
c++ -std=c++20 -O2 -Wall -Wextra -Werror "$SOURCE" -o "$TEST_ROOT/checkpoint_restart"
reference=$("$TEST_ROOT/checkpoint_restart" reference 1000)
checkpoint=$TEST_ROOT/state.chk
"$TEST_ROOT/checkpoint_restart" checkpoint "$checkpoint" 400 >/dev/null
[ "$(stat -c %a "$checkpoint")" = 600 ] || fail "checkpoint mode"
[ "$(stat -c %s "$checkpoint")" = 40 ] || fail "checkpoint size"
resumed=$("$TEST_ROOT/checkpoint_restart" resume "$checkpoint" 400 1000)
[ "$reference" = "$resumed" ] || fail "restart equivalence"
original_sha=$(sha256sum "$checkpoint" | cut -d' ' -f1)
[ "$original_sha" = 0cc4aab240009663fdc78161d523446dc3a71330e7b445b77aa7aa3cdb4dbfe1 ] ||
    fail "frozen architecture-neutral checkpoint bytes"
if "$TEST_ROOT/checkpoint_restart" checkpoint "$checkpoint" 400 >/dev/null 2>&1; then
    fail "checkpoint collision accepted"
fi
[ "$(sha256sum "$checkpoint" | cut -d' ' -f1)" = "$original_sha" ] ||
    fail "collision changed checkpoint"

dd if="$checkpoint" of="$TEST_ROOT/truncated.chk" bs=1 count=39 status=none
if "$TEST_ROOT/checkpoint_restart" resume "$TEST_ROOT/truncated.chk" 400 1000 \
    >/dev/null 2>&1; then fail "truncated checkpoint accepted"; fi
cp "$checkpoint" "$TEST_ROOT/corrupt.chk"
printf '\377' | dd of="$TEST_ROOT/corrupt.chk" bs=1 seek=24 conv=notrunc status=none
if "$TEST_ROOT/checkpoint_restart" resume "$TEST_ROOT/corrupt.chk" 400 1000 \
    >/dev/null 2>&1; then fail "corrupt checkpoint accepted"; fi
cp "$checkpoint" "$TEST_ROOT/version.chk"
printf '\000\000\000\002' | dd of="$TEST_ROOT/version.chk" bs=1 seek=8 conv=notrunc status=none
if "$TEST_ROOT/checkpoint_restart" resume "$TEST_ROOT/version.chk" 400 1000 \
    >/dev/null 2>&1; then fail "wrong version accepted"; fi
if "$TEST_ROOT/checkpoint_restart" resume "$checkpoint" 399 1000 \
    >/dev/null 2>&1; then fail "wrong step accepted"; fi

race=$TEST_ROOT/race.chk
"$TEST_ROOT/checkpoint_restart" checkpoint "$race" 400 \
    >"$TEST_ROOT/race-400.out" 2>&1 &
race_400_pid=$!
"$TEST_ROOT/checkpoint_restart" checkpoint "$race" 500 \
    >"$TEST_ROOT/race-500.out" 2>&1 &
race_500_pid=$!
set +e
wait "$race_400_pid"; race_400_status=$?
wait "$race_500_pid"; race_500_status=$?
set -e
if [ "$race_400_status" -eq 0 ] && [ "$race_500_status" -ne 0 ]; then
    race_step=400
elif [ "$race_500_status" -eq 0 ] && [ "$race_400_status" -ne 0 ]; then
    race_step=500
else
    fail "checkpoint race did not produce exactly one writer"
fi
[ "$(stat -c %a "$race")" = 600 ] && [ "$(stat -c %s "$race")" = 40 ] ||
    fail "checkpoint race file identity"
"$TEST_ROOT/checkpoint_restart" resume "$race" "$race_step" 1000 >/dev/null ||
    fail "checkpoint race winner is invalid"

grep -F 'fsync(fd)' "$SOURCE" >/dev/null || fail "checkpoint fsync"
grep -F '0x7f7cadf8669fc055' "$JOB" >/dev/null || fail "frozen final state"
grep -F '48434b505430303100000001000000000000000000000190f228968bea039c89a12045f4cbcc95d1' \
    "$FORMAT_DOC" >/dev/null || fail "documented golden bytes"
grep -F 'not cryptographic authentication' "$FORMAT_DOC" >/dev/null ||
    fail "checksum scope boundary"
grep -F 'exactly one writer wins' "$FORMAT_DOC" >/dev/null ||
    fail "writer collision scope"
grep -F 'O_EXCL' "$SOURCE" >/dev/null || fail "checkpoint collision refusal"
grep -F 'unlink -- "$checkpoint"' "$JOB" >/dev/null || fail "exact live cleanup"
if grep -E 'rm[[:space:]]+(-[^[:space:]]*)*[rR]|--recursive|find[[:space:]].*-delete|rsync[[:space:]].*--delete' \
    "$JOB" "$LOCAL_JOB"; then fail "unsafe cleanup"; fi
printf '%s\n' 'checkpoint restart tests: PASS'
