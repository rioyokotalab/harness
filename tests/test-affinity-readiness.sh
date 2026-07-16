#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
SOURCE=$ROOT/tests/smoke/affinity.cpp
JOB=$ROOT/tests/smoke/jobs/affinity-readiness.sh
LOCAL=$ROOT/tests/smoke/jobs/local-affinity.slurm
work=$(mktemp -d "${TMPDIR:-/tmp}/harness-affinity-test.XXXXXX")

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    if [ -f "$work/affinity" ] && [ ! -L "$work/affinity" ]; then
        unlink -- "$work/affinity" || status=1
    fi
    if [ -d "$work" ] && [ ! -L "$work" ]; then
        rmdir -- "$work" || status=1
    fi
    exit "$status"
}
trap cleanup EXIT HUP INT TERM

bash -n "$JOB" "$LOCAL"
c++ -std=c++20 -O2 -pthread -Wall -Wextra -Werror "$SOURCE" -o "$work/affinity"
"$work/affinity" 2 | grep -E '^affinity=pass allowed_cpus=[0-9]+ online_cpus=[0-9]+ physical_cores=[0-9]+ pinned_workers=2$' >/dev/null
if "$work/affinity" 1 >/dev/null 2>&1; then
    printf '%s\n' 'FAIL: affinity gate accepted fewer than two CPUs' >&2
    exit 1
fi
grep -Fx '#YBATCH -r thrp_1' "$LOCAL" >/dev/null
grep -Fx '#SBATCH --cpus-per-task=2' "$LOCAL" >/dev/null
grep -F 'HARNESS_EXPECTED_REV' "$JOB" >/dev/null
grep -F 'tests/smoke/jobs/source-contract.sh' "$JOB" >/dev/null
grep -F '"$build/affinity" 2' "$JOB" >/dev/null
if grep -E 'rm[[:space:]]+(-[^[:space:]]*)*[rR]|--recursive|find[[:space:]].*-delete|rsync[[:space:]].*--delete' \
    "$JOB" "$LOCAL" "$ROOT/tests/guarded-test-cleanup.sh" >/dev/null; then
    printf '%s\n' 'FAIL: unsafe cleanup in affinity readiness gate' >&2
    exit 1
fi
printf '%s\n' 'Affinity readiness tests passed'
