#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
SITES=$ROOT/shared/skills/operate-native-hpc/references/sites.md
JOB=$ROOT/tests/smoke/jobs/cpu-readiness.sh
LOCAL=$ROOT/tests/smoke/jobs/local-cpu.slurm
CACHE_JOB=$ROOT/tests/smoke/jobs/cache-startup-readiness.sh
CACHE_LOCAL=$ROOT/tests/smoke/jobs/local-cache-startup.slurm
ACCEL_JOB=$ROOT/tests/smoke/jobs/accelerator-readiness.sh
ACCEL_LOCAL=$ROOT/tests/smoke/jobs/local-accelerator.slurm
MPI_JOB=$ROOT/tests/smoke/jobs/mpi-readiness.sh
MPI_LOCAL=$ROOT/tests/smoke/jobs/local-mpi.slurm
NUMERICAL_JOB=$ROOT/tests/smoke/jobs/numerical-readiness.sh
NUMERICAL_LOCAL=$ROOT/tests/smoke/jobs/local-numerical.slurm
NUMERICAL_EPYC=$ROOT/tests/smoke/jobs/local-numerical-epyc.slurm
COMPUTE_DEBUG_JOB=$ROOT/tests/smoke/jobs/compute-debugger-readiness.sh
AFFINITY_JOB=$ROOT/tests/smoke/jobs/affinity-readiness.sh
AFFINITY_LOCAL=$ROOT/tests/smoke/jobs/local-affinity.slurm
AFFINITY_EPYC=$ROOT/tests/smoke/jobs/local-affinity-epyc.slurm

bash -n "$JOB" "$LOCAL" "$CACHE_JOB" "$CACHE_LOCAL" "$ACCEL_JOB" "$ACCEL_LOCAL" \
    "$MPI_JOB" "$MPI_LOCAL" "$NUMERICAL_JOB" "$NUMERICAL_LOCAL" \
    "$NUMERICAL_EPYC" "$COMPUTE_DEBUG_JOB" \
    "$AFFINITY_JOB" "$AFFINITY_LOCAL" "$AFFINITY_EPYC"
grep -F 'Suppress PBS lifecycle email by default for every agent-run job.' "$SITES" >/dev/null
grep -F '`#PBS -m n`' "$SITES" >/dev/null
for pbs_job in "$ROOT"/tests/smoke/jobs/ab*.pbs; do
    [ -f "$pbs_job" ]
    [ "$(grep -Fxc '#PBS -m n' "$pbs_job")" -eq 1 ]
done
grep -Fx '#YBATCH -r thrp_1' "$LOCAL" >/dev/null
grep -Fx '#SBATCH --time=00:05:00' "$LOCAL" >/dev/null
grep -F 'uenv run prgenv-gnu/25.11:v1 --view=default' "$JOB" >/dev/null
grep -F 'module load gcc/15.2.0' "$JOB" >/dev/null
grep -F 'module load gcc/14.2.0' "$JOB" >/dev/null
grep -F 'HARNESS_READINESS_RUN_TAG' "$JOB" >/dev/null
grep -F 'exec /bin/bash "$0"' "$JOB" >/dev/null
grep -F 'CC=$(command -v gcc)' "$JOB" >/dev/null
grep -F 'CXX=$(command -v g++)' "$JOB" >/dev/null
grep -F 'FC=$(command -v gfortran)' "$JOB" >/dev/null
grep -F 'export HARNESS_READINESS_RUN_TAG=v2' "$LOCAL" >/dev/null
grep -Fx '#YBATCH -r thrp_1' "$CACHE_LOCAL" >/dev/null
grep -Fx '#SBATCH --time=00:05:00' "$CACHE_LOCAL" >/dev/null
grep -F 'unset HARNESS_LOGICAL_HOST HARNESS_PERSISTENT_ROOT HARNESS_CACHE_ROOT' "$CACHE_JOB" >/dev/null
grep -F 'exec /bin/bash -l "$0"' "$CACHE_JOB" >/dev/null
grep -F 'exec /bin/bash "$0"' "$CACHE_JOB" >/dev/null
grep -F 'gate=cache-startup-v1' "$CACHE_JOB" >/dev/null
grep -Fx '#YBATCH -r a4500_1' "$ACCEL_LOCAL" >/dev/null
grep -Fx '#SBATCH --time=00:05:00' "$ACCEL_LOCAL" >/dev/null
grep -Fx '#SBATCH --job-name=t200glocal2' "$ACCEL_LOCAL" >/dev/null
grep -F 'export HARNESS_READINESS_RUN_TAG=v2' "$ACCEL_LOCAL" >/dev/null
grep -F 'module load cuda/13.2/13.2.1' "$ACCEL_JOB" >/dev/null
grep -F 'module load cuda/12.8.0' "$ACCEL_JOB" >/dev/null
grep -F 'module load cuda/12.8' "$ACCEL_JOB" >/dev/null
grep -F 'module unload cuda/12.8' "$ACCEL_JOB" >/dev/null
grep -F 'ri|al|rc) expected_arch=aarch64' "$ACCEL_JOB" >/dev/null
grep -F 'CUDA_VISIBLE_DEVICES=0' "$ACCEL_JOB" >/dev/null
grep -F 'cuda-compile: no reviewed toolkit route' "$ACCEL_JOB" >/dev/null
grep -F 'framework: no reviewed project environment or image' "$ACCEL_JOB" >/dev/null
grep -F 'cudaGetDeviceCount' "$ROOT/tests/smoke/cuda.cu" >/dev/null
grep -Fx '#YBATCH -r thrp_1' "$MPI_LOCAL" >/dev/null
grep -Fx '#SBATCH --ntasks=2' "$MPI_LOCAL" >/dev/null
grep -F 'module load hpcx/2.26' "$MPI_JOB" >/dev/null
grep -F 'module load ylab/hpcx/2.21.0' "$MPI_JOB" >/dev/null
grep -F 'NATIVE srun --ntasks=2 BUILD/mpi 2' "$MPI_JOB" >/dev/null
grep -F 'NATIVE mpirun -n 2 BUILD/mpi 2' "$MPI_JOB" >/dev/null
grep -F 'no reviewed base MPI route' "$MPI_JOB" >/dev/null
grep -Fx '#YBATCH -r thrp_1' "$NUMERICAL_LOCAL" >/dev/null
grep -Fx '#YBATCH -r epyc-7502_1' "$NUMERICAL_EPYC" >/dev/null
grep -Fx '#SBATCH --job-name=t210nepyc3' "$NUMERICAL_EPYC" >/dev/null
grep -F 'export HARNESS_READINESS_RUN_TAG=v3' "$NUMERICAL_EPYC" >/dev/null
if grep -F '#SBATCH --ntasks=' "$NUMERICAL_EPYC" >/dev/null; then
    printf '%s\n' 'FAIL: Epyc job overrides native task count' >&2
    exit 1
fi
grep -F 'tests/smoke/jobs/source-contract.sh' "$NUMERICAL_EPYC" >/dev/null
grep -F 'module load gcc/15.2.0' "$NUMERICAL_JOB" >/dev/null
grep -F 'module load gcc/14.2.0' "$NUMERICAL_JOB" >/dev/null
grep -F -- '-fno-fast-math -ffp-contract=off -frounding-math' "$NUMERICAL_JOB" >/dev/null
grep -F 'expected_numerator = -14036' "$ROOT/tests/smoke/numerical.cpp" >/dev/null
grep -F '0x3ff0000000000001' "$ROOT/tests/smoke/numerical.cpp" >/dev/null
grep -F 't213-debugger-compute-$host-$run_tag.out' "$COMPUTE_DEBUG_JOB" >/dev/null
grep -F 'HARNESS_LOGICAL_HOST=$host' "$COMPUTE_DEBUG_JOB" >/dev/null
grep -Fx '#YBATCH -r thrp_1' "$AFFINITY_LOCAL" >/dev/null
grep -Fx '#SBATCH --cpus-per-task=2' "$AFFINITY_LOCAL" >/dev/null
grep -Fx '#YBATCH -r epyc-7502_1' "$AFFINITY_EPYC" >/dev/null
grep -Fx '#SBATCH --cpus-per-task=2' "$AFFINITY_EPYC" >/dev/null
grep -Fx '#SBATCH --job-name=t237aepyc2' "$AFFINITY_EPYC" >/dev/null
if grep -F '#SBATCH --ntasks=' "$AFFINITY_EPYC" >/dev/null; then
    printf '%s\n' 'FAIL: Epyc affinity job overrides native task count' >&2
    exit 1
fi
grep -F 'tests/smoke/jobs/source-contract.sh' "$AFFINITY_EPYC" >/dev/null
grep -F 'tests/smoke/jobs/source-contract.sh' "$AFFINITY_JOB" >/dev/null
grep -F '"$build/affinity" 2' "$AFFINITY_JOB" >/dev/null
for source in cpu.c cpu.cpp cpu.f90; do
    grep -F "$source" "$ROOT/tests/smoke/CMakeLists.txt" >/dev/null
done
for source in cpp20.cpp python.py sanitizer.c; do
    grep -F "$source" "$JOB" >/dev/null
done
if grep -E 'rm[[:space:]]+(-[^[:space:]]*)*[rR]|--recursive|rsync[[:space:]].*--delete' \
    "$JOB" "$LOCAL" "$CACHE_JOB" "$CACHE_LOCAL" "$ACCEL_JOB" "$ACCEL_LOCAL" \
    "$MPI_JOB" "$MPI_LOCAL" "$NUMERICAL_JOB" "$NUMERICAL_LOCAL" \
    "$NUMERICAL_EPYC" \
    "$COMPUTE_DEBUG_JOB" "$AFFINITY_JOB" "$AFFINITY_LOCAL" "$AFFINITY_EPYC" >/dev/null; then
    printf '%s\n' 'FAIL: unsafe cleanup in readiness job' >&2
    exit 1
fi
if grep -E '(^|[^A-Za-z0-9_])(qsub|sbatch|srun|yrun|ybatch|scancel|qdel)([^A-Za-z0-9_]|$)' \
    "$JOB" "$CACHE_JOB" "$ACCEL_JOB" "$NUMERICAL_JOB" "$COMPUTE_DEBUG_JOB" \
    "$AFFINITY_JOB" >/dev/null; then
    printf '%s\n' 'FAIL: generic readiness job hides scheduler action' >&2
    exit 1
fi
if grep -E '(^|[^A-Za-z0-9_])(qsub|sbatch|yrun|ybatch|scancel|qdel)([^A-Za-z0-9_]|$)' \
    "$MPI_JOB" >/dev/null; then
    printf '%s\n' 'FAIL: MPI readiness job hides submission or cancellation' >&2
    exit 1
fi
printf '%s\n' 'HPC readiness job tests passed'
