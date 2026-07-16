#!/bin/bash
#YBATCH -r thrp_1
#SBATCH --time=00:05:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --job-name=t237alocal
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

set -eu
export HARNESS_LOGICAL_HOST=local
export HARNESS_READINESS_RUN_TAG=v1
export HARNESS_EXPECTED_REV=REPLACE_WITH_IMPLEMENTATION_COMMIT
exec "$HOME/harness/tests/smoke/jobs/affinity-readiness.sh"
