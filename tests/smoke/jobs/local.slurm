#!/bin/bash
#YBATCH -r a4500_1
#SBATCH --time=00:02:00
#SBATCH --job-name=harness-smoke
#SBATCH --output=.harness-smoke-%j.out
#SBATCH --error=.harness-smoke-%j.out

set -eu
build=$(mktemp -d "${SLURM_TMPDIR:-/tmp}/harness-smoke.XXXXXX")
trap 'rm -rf "$build"' EXIT HUP INT TERM

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
