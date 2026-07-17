#!/bin/bash
#YBATCH -r a4500_1
#SBATCH --time=00:10:00
#SBATCH --job-name=t251flocal3
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

set -eu
export HARNESS_LOGICAL_HOST=local
export HARNESS_READINESS_RUN_TAG=v3
export HARNESS_EXPECTED_REV=195b26cbe4d6454cb7d62635debb306c1200214d
exec "$HOME/harness/tests/smoke/jobs/pytorch-readiness.sh"
