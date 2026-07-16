#!/bin/bash
#YBATCH -r thrp_1
#SBATCH --time=00:05:00
#SBATCH --nodes=1
#SBATCH --ntasks=2
#SBATCH --cpus-per-task=1
#SBATCH --job-name=t207mlocal
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

set -eu
export HARNESS_LOGICAL_HOST=local
export HARNESS_READINESS_RUN_TAG=v1
exec "$HOME/harness/tests/smoke/jobs/mpi-readiness.sh"
