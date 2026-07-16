#!/bin/bash
#YBATCH -r thrp_1
#SBATCH --time=00:05:00
#SBATCH --job-name=t201clocal
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

set -eu
export HARNESS_EXPECTED_HOST=local
exec "$HOME/harness/tests/smoke/jobs/cache-startup-readiness.sh"
