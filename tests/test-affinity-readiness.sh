#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
SOURCE=$ROOT/tests/smoke/affinity.cpp
JOB=$ROOT/tests/smoke/jobs/affinity-readiness.sh
LOCAL=$ROOT/tests/smoke/jobs/local-affinity.slurm
LOCAL_EPYC=$ROOT/tests/smoke/jobs/local-affinity-epyc.slurm
ROUTES=$ROOT/profiles/hpc-affinity-routes.tsv
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

bash -n "$JOB" "$LOCAL" "$LOCAL_EPYC"
c++ -std=c++20 -O2 -pthread -Wall -Wextra -Werror "$SOURCE" -o "$work/affinity"
"$work/affinity" 2 | grep -E '^affinity=pass allowed_cpus=[0-9]+ online_cpus=[0-9]+ physical_cores=[0-9]+ pinned_workers=2$' >/dev/null
if "$work/affinity" 1 >/dev/null 2>&1; then
    printf '%s\n' 'FAIL: affinity gate accepted fewer than two CPUs' >&2
    exit 1
fi
grep -Fx '#YBATCH -r thrp_1' "$LOCAL" >/dev/null
grep -Fx '#SBATCH --cpus-per-task=2' "$LOCAL" >/dev/null
grep -Fx '#YBATCH -r epyc-7502_1' "$LOCAL_EPYC" >/dev/null
grep -Fx '#SBATCH --cpus-per-task=2' "$LOCAL_EPYC" >/dev/null
grep -Fx '#SBATCH --job-name=t237aepyc2' "$LOCAL_EPYC" >/dev/null
grep -F 'export HARNESS_READINESS_RUN_TAG=v2' "$LOCAL_EPYC" >/dev/null
grep -E '^export HARNESS_EXPECTED_REV=[0-9a-f]{40}$' "$LOCAL_EPYC" >/dev/null
grep -F 'tests/smoke/jobs/source-contract.sh' "$LOCAL_EPYC" >/dev/null
if grep -F '#SBATCH --ntasks=' "$LOCAL_EPYC" >/dev/null; then
    printf '%s\n' 'FAIL: Epyc affinity job overrides native task count' >&2
    exit 1
fi
grep -F 'HARNESS_EXPECTED_REV' "$JOB" >/dev/null
grep -F 'export HARNESS_EXPECTED_REV=3b969366202f78f7f7b9d60f4d7c9671dc8b0ccd' "$LOCAL" >/dev/null
grep -F 'tests/smoke/jobs/source-contract.sh' "$JOB" >/dev/null
grep -F '"$build/affinity" 2' "$JOB" >/dev/null
[ "$(grep -cv '^#' "$ROUTES")" -eq 7 ]
for host in local ab ab2 ri al rc t4; do
    [ "$(awk -F '|' -v host="$host" '$1 == host { count++ } END { print count + 0 }' "$ROUTES")" -eq 1 ]
done
awk -F '|' '
    /^#/ { next }
    NF != 11 || $8 != 2 || $10 != "00:05:00" || $11 !~ /^t237a/ { bad=1 }
    END { exit bad }
' "$ROUTES"
if grep -E 'rm[[:space:]]+(-[^[:space:]]*)*[rR]|--recursive|find[[:space:]].*-delete|rsync[[:space:]].*--delete' \
    "$JOB" "$LOCAL" "$LOCAL_EPYC" "$ROOT/tests/guarded-test-cleanup.sh" >/dev/null; then
    printf '%s\n' 'FAIL: unsafe cleanup in affinity readiness gate' >&2
    exit 1
fi
printf '%s\n' 'Affinity readiness tests passed'
