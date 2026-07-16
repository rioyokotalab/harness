#!/bin/bash
#YBATCH -r a4500_1
#SBATCH --time=00:05:00
#SBATCH --job-name=t200glocal
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

set -eu
export HARNESS_LOGICAL_HOST=local
export HARNESS_READINESS_RUN_TAG=v1
exec "$HOME/harness/tests/smoke/jobs/accelerator-readiness.sh"
