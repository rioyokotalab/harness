#!/bin/bash
#SBATCH --job-name=t251frc3
#SBATCH --account=cloud-users
#SBATCH --partition=qc-gh200
#SBATCH --gres=gpu:1
#SBATCH --nodes=1
#SBATCH --time=00:10:00
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

set -eu
export HARNESS_LOGICAL_HOST=rc
export HARNESS_READINESS_RUN_TAG=v3
export HARNESS_EXPECTED_REV=207fbe9d7fe074ab7fd1eddb6335fe257f0c66fb
exec "$HOME/harness/tests/smoke/jobs/pytorch-readiness.sh"
