#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
case ${HARNESS_TEST_CASE:-cpu} in
    cpu)
        job=$ROOT/tests/smoke/jobs/cpu-readiness.sh
        local_job=$ROOT/tests/smoke/jobs/local-cpu.slurm
        bash -n "$job" "$local_job"
        grep -Fx '#YBATCH -r thrp_1' "$local_job" >/dev/null
        grep -Fx '#SBATCH --time=00:05:00' "$local_job" >/dev/null
        grep -F 'uenv run prgenv-gnu/25.11:v1 --view=default' "$job" >/dev/null
        grep -F 'module load gcc/15.2.0' "$job" >/dev/null
        grep -F 'module load gcc/14.2.0' "$job" >/dev/null
        grep -F 'exec /bin/bash "$0"' "$job" >/dev/null
        grep -F 'CC=$(command -v gcc)' "$job" >/dev/null
        grep -F 'CXX=$(command -v g++)' "$job" >/dev/null
        grep -F 'FC=$(command -v gfortran)' "$job" >/dev/null
        for source in cpu.c cpu.cpp cpu.f90; do
            grep -F "$source" "$ROOT/tests/smoke/CMakeLists.txt" >/dev/null
        done
        for source in cpp20.cpp python.py sanitizer.c; do
            grep -F "$source" "$job" >/dev/null
        done
        ;;
    cache)
        job=$ROOT/tests/smoke/jobs/cache-startup-readiness.sh
        local_job=$ROOT/tests/smoke/jobs/local-cache-startup.slurm
        bash -n "$job" "$local_job"
        grep -Fx '#YBATCH -r thrp_1' "$local_job" >/dev/null
        grep -Fx '#SBATCH --time=00:05:00' "$local_job" >/dev/null
        grep -F 'unset HARNESS_LOGICAL_HOST HARNESS_PERSISTENT_ROOT HARNESS_CACHE_ROOT' "$job" >/dev/null
        grep -F 'exec /bin/bash -l "$0"' "$job" >/dev/null
        grep -F 'gate=cache-startup-v1' "$job" >/dev/null
        ;;
    accelerator)
        job=$ROOT/tests/smoke/jobs/accelerator-readiness.sh
        local_job=$ROOT/tests/smoke/jobs/local-accelerator.slurm
        bash -n "$job" "$local_job"
        grep -Fx '#YBATCH -r a4500_1' "$local_job" >/dev/null
        grep -Fx '#SBATCH --job-name=t200glocal2' "$local_job" >/dev/null
        grep -F 'module load cuda/13.2/13.2.1' "$job" >/dev/null
        grep -F 'module load cuda/12.8.0' "$job" >/dev/null
        grep -F 'ri|al|rc) expected_arch=aarch64' "$job" >/dev/null
        grep -F 'CUDA_VISIBLE_DEVICES=0' "$job" >/dev/null
        grep -F 'cudaGetDeviceCount' "$ROOT/tests/smoke/cuda.cu" >/dev/null
        ;;
    mpi)
        job=$ROOT/tests/smoke/jobs/mpi-readiness.sh
        local_job=$ROOT/tests/smoke/jobs/local-mpi.slurm
        bash -n "$job" "$local_job"
        grep -Fx '#SBATCH --ntasks=2' "$local_job" >/dev/null
        grep -F 'module load hpcx/2.26' "$job" >/dev/null
        grep -F 'module load ylab/hpcx/2.21.0' "$job" >/dev/null
        grep -F 'NATIVE srun --ntasks=2 BUILD/mpi 2' "$job" >/dev/null
        grep -F 'NATIVE mpirun -n 2 BUILD/mpi 2' "$job" >/dev/null
        grep -F 'no reviewed base MPI route' "$job" >/dev/null
        ;;
    numerical)
        job=$ROOT/tests/smoke/jobs/numerical-readiness.sh
        local_job=$ROOT/tests/smoke/jobs/local-numerical.slurm
        epyc_job=$ROOT/tests/smoke/jobs/local-numerical-epyc.slurm
        source=$ROOT/tests/smoke/numerical.cpp
        bash -n "$job" "$local_job" "$epyc_job"
        grep -Fx '#YBATCH -r thrp_1' "$local_job" >/dev/null
        grep -Fx '#YBATCH -r epyc-7502_1' "$epyc_job" >/dev/null
        grep -Fx '#SBATCH --job-name=t210nepyc3' "$epyc_job" >/dev/null
        grep -F 'tests/smoke/jobs/source-contract.sh' "$epyc_job" >/dev/null
        if grep -F '#SBATCH --ntasks=' "$epyc_job" >/dev/null; then exit 1; fi
        grep -F -- '-fno-fast-math -ffp-contract=off -frounding-math' "$job" >/dev/null
        grep -F 'expected_numerator = -14036' "$source" >/dev/null
        grep -F '0x3ff0000000000001' "$source" >/dev/null
        ;;
    compute-debugger)
        job=$ROOT/tests/smoke/jobs/compute-debugger-readiness.sh
        bash -n "$job"
        grep -F 't213-debugger-compute-$host-$run_tag.out' "$job" >/dev/null
        grep -F 'HARNESS_LOGICAL_HOST=$host' "$job" >/dev/null
        ;;
    *) printf 'FAIL: unknown HPC readiness case: %s\n' "$HARNESS_TEST_CASE" >&2; exit 1 ;;
esac

printf 'HPC_READINESS case=%s status=pass\n' "${HARNESS_TEST_CASE:-cpu}"
