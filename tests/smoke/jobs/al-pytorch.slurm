#!/bin/bash
#SBATCH --job-name=t251fal3
#SBATCH --account=g177-1
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --gpus=1
#SBATCH --time=00:10:00
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null
#SBATCH --uenv=prgenv-gnu/25.11:v1
#SBATCH --view=default

set -eu
export HARNESS_LOGICAL_HOST=al
export HARNESS_READINESS_RUN_TAG=v3
export HARNESS_EXPECTED_REV=207fbe9d7fe074ab7fd1eddb6335fe257f0c66fb
exec "$HOME/harness/tests/smoke/jobs/pytorch-readiness.sh"
