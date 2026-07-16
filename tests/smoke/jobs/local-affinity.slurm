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
export HARNESS_EXPECTED_REV=3b969366202f78f7f7b9d60f4d7c9671dc8b0ccd
exec "$HOME/harness/tests/smoke/jobs/affinity-readiness.sh"
