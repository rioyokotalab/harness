#!/bin/bash
#YBATCH -r a4500_1
#SBATCH --time=00:10:00
#SBATCH --job-name=t251flocal
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

set -eu
export HARNESS_LOGICAL_HOST=local
export HARNESS_READINESS_RUN_TAG=v1
export HARNESS_EXPECTED_REV=0000000000000000000000000000000000000000
exec "$HOME/harness/tests/smoke/jobs/pytorch-readiness.sh"
