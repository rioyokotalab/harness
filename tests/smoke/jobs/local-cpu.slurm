#!/bin/bash
#YBATCH -r thrp_1
#SBATCH --time=00:05:00
#SBATCH --job-name=t200clocal
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

set -eu
export HARNESS_LOGICAL_HOST=local
export HARNESS_READINESS_RUN_TAG=v2
exec "$HOME/harness/tests/smoke/jobs/cpu-readiness.sh"
