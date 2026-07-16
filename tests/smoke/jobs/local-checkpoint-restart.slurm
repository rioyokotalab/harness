#!/bin/bash
#YBATCH -r thrp_1
#SBATCH --job-name=t217rlocal
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=00:05:00
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null
set -eu
export HARNESS_LOGICAL_HOST=local
export HARNESS_READINESS_RUN_TAG=v1
exec "$HOME/harness/tests/smoke/jobs/checkpoint-restart-readiness.sh"
