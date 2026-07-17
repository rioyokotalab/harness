#!/bin/bash
#SBATCH --job-name=t251fri2
#SBATCH --account=rkp00015
#SBATCH --partition=gpu
#SBATCH --gpus=1
#SBATCH --nodes=1
#SBATCH --time=00:10:00
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

set -eu
export HARNESS_LOGICAL_HOST=ri
export HARNESS_READINESS_RUN_TAG=v2
export HARNESS_EXPECTED_REV=195b26cbe4d6454cb7d62635debb306c1200214d
exec "$HOME/harness/tests/smoke/jobs/pytorch-readiness.sh"
