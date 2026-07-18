#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
SOURCE=$ROOT/tests/smoke/mpi-multinode.c
JOB=$ROOT/tests/smoke/jobs/multinode-mpi-readiness.sh
LOCAL_JOB=$ROOT/tests/smoke/jobs/local-multinode-mpi.slurm
AB_JOB=$ROOT/tests/smoke/jobs/ab-multinode-mpi.pbs
AB2_JOB=$ROOT/tests/smoke/jobs/ab2-multinode-mpi.pbs
T4_JOB=$ROOT/tests/smoke/jobs/t4-multinode-mpi.sh

bash -n "$JOB" "$LOCAL_JOB" "$AB_JOB" "$AB2_JOB" "$T4_JOB"
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
    '.$task-multinode-build-$host-$run_tag.XXXXXX' \
    '"$build_root" "$build" "$build_root"' \
    'shared-executable-visibility.sh' \
    'SHARED_EXECUTABLE ranks=2 sha256=%s status=pass' \
    'srun --nodes=2 --ntasks=2 --ntasks-per-node=1' \
    'mpirun -n 2 --map-by ppr:1:node' \
    'mpirun -np 2 --map-by ppr:1:node --hostfile "$PBS_NODEFILE"' \
    'mpirun -npernode 1 -n 2 -x LD_LIBRARY_PATH' \
    'guarded-test-cleanup.sh' \
    'RESULT host=%s status=%s'
do
    grep -F "$token" "$JOB" >/dev/null
done
for pair in \
    "$LOCAL_JOB|#YBATCH -r thrp_1|#SBATCH --job-name=t251mlocal" \
    "$AB_JOB|#PBS -q rt_HF|#PBS -l select=2:mpiprocs=1" \
    "$AB2_JOB|#PBS -q rt_HF|#PBS -l select=2:mpiprocs=1" \
    "$T4_JOB|#$ -l node_f=2|#$ -N t251mt4"
do
    file=${pair%%|*}; rest=${pair#*|}; first=${rest%%|*}; second=${rest#*|}
    grep -Fx "$first" "$file" >/dev/null
    grep -Fx "$second" "$file" >/dev/null
    grep -F 'export HARNESS_READINESS_RUN_TAG=v1' "$file" >/dev/null
done
for file in "$AB_JOB" "$AB2_JOB"; do
    [ "$(grep -Fxc '#PBS -m n' "$file")" -eq 1 ]
done
if grep -F 'SLURM_TMPDIR' "$JOB" >/dev/null; then
    printf '%s\n' 'FAIL: multi-node executable returned to node-local scratch' >&2
    exit 1
fi
if grep -E 'rm[[:space:]]+(-[^[:space:]]*)*[rR]|--recursive|find[[:space:]].*-delete|rsync[[:space:]].*--delete' \
    "$JOB" "$LOCAL_JOB" "$AB_JOB" "$AB2_JOB" "$T4_JOB" >/dev/null; then
    printf '%s\n' 'FAIL: unsafe multi-node MPI cleanup' >&2
    exit 1
fi
if HARNESS_LOGICAL_HOST=ri HARNESS_EXPECTED_REV=0000000000000000000000000000000000000000 \
    "$JOB" >/dev/null 2>&1; then
    printf '%s\n' 'FAIL: unsupported host accepted' >&2
    exit 1
fi
printf '%s\n' 'multi-node MPI readiness tests: PASS'
