#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
SOURCE=$ROOT/tests/smoke/mpi-multinode.c
JOB=$ROOT/tests/smoke/jobs/multinode-mpi-readiness.sh

bash -n "$JOB"
for token in \
    'MPI_Get_processor_name' \
    'MPI_Gather' \
    'strcmp(names, names + MPI_MAX_PROCESSOR_NAME) != 0' \
    'mpi_multinode=pass ranks=2 hosts=2'
do
    grep -F "$token" "$SOURCE" >/dev/null
done
for token in \
    'source-contract.sh' \
    '[ "${SLURM_JOB_NUM_NODES:-}" = 2 ]' \
    'build_root=$state_root' \
    '.t230-multinode-build-al-v2.XXXXXX' \
    '"$build_root" "$build" "$build_root"' \
    'shared-executable-visibility.sh' \
    'SHARED_EXECUTABLE ranks=2 sha256=%s status=pass' \
    'srun --nodes=2 --ntasks=2 --ntasks-per-node=1' \
    'guarded-test-cleanup.sh' \
    'RESULT host=%s status=%s'
do
    grep -F "$token" "$JOB" >/dev/null
done
if grep -F 'SLURM_TMPDIR' "$JOB" >/dev/null; then
    printf '%s\n' 'FAIL: multi-node executable returned to node-local scratch' >&2
    exit 1
fi
if grep -E 'rm[[:space:]]+(-[^[:space:]]*)*[rR]|--recursive|find[[:space:]].*-delete|rsync[[:space:]].*--delete' \
    "$JOB" >/dev/null; then
    printf '%s\n' 'FAIL: unsafe multi-node MPI cleanup' >&2
    exit 1
fi
if HARNESS_LOGICAL_HOST=ri HARNESS_EXPECTED_REV=0000000000000000000000000000000000000000 \
    "$JOB" >/dev/null 2>&1; then
    printf '%s\n' 'FAIL: unsupported host accepted' >&2
    exit 1
fi
printf '%s\n' 'multi-node MPI readiness tests: PASS'
