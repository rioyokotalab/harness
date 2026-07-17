#!/bin/bash
#SBATCH --job-name=t251frc
#SBATCH --account=cloud-users
#SBATCH --partition=qc-gh200
#SBATCH --gres=gpu:1
#SBATCH --nodes=1
#SBATCH --time=00:10:00
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

set -eu
export HARNESS_LOGICAL_HOST=rc
export HARNESS_READINESS_RUN_TAG=v1
export HARNESS_EXPECTED_REV=3eccb8010edc2605e826957c6a55594e1144461a
exec "$HOME/harness/tests/smoke/jobs/pytorch-readiness.sh"
