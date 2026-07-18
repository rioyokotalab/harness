#!/bin/bash
#YBATCH -r a4500_1
#SBATCH --time=00:02:00
#SBATCH --job-name=harness-smoke
#SBATCH --output=.harness-smoke/%j.out
#SBATCH --error=.harness-smoke/%j.out

set -eu
build=$(mktemp -d "${SLURM_TMPDIR:-/tmp}/harness-smoke.XXXXXX")
cleanup=$HOME/harness/tests/guarded-test-cleanup.sh

# shellcheck source=/dev/null
. "$HOME/harness/shell/module-stack.sh" local

cleanup_build() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$build" ]; then
        "$cleanup" "$HOME/.local/bin/harness" "${SLURM_TMPDIR:-/tmp}" \
            "$build" "${SLURM_TMPDIR:-/tmp}" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then
        echo "FAIL: guarded native-smoke cleanup" >&2
        status=1
    fi
    exit "$status"
}

trap cleanup_build EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

echo "NATIVE podman --version"
podman --version
echo "NATIVE docker --version"
docker --version

nvidia-smi --query-gpu=name,driver_version,compute_cap --format=csv,noheader

echo "NATIVE nvcc -O2 tests/smoke/cuda.cu"
nvcc -O2 "$HOME/harness/tests/smoke/cuda.cu" -o "$build/cuda"
"$build/cuda"

echo "NATIVE mpicc -O2 tests/smoke/mpi.c"
mpicc -O2 "$HOME/harness/tests/smoke/mpi.c" -o "$build/mpi"
echo "NATIVE mpirun -n 2 MPI_SMOKE"
mpirun -n 2 "$build/mpi"

echo "NATIVE python3.12 tests/smoke/python.py"
python3.12 "$HOME/harness/tests/smoke/python.py"
