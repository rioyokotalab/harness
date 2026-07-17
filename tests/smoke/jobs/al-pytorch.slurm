#!/bin/bash
#SBATCH --job-name=t251fal
#SBATCH --account=g177-1
#SBATCH --partition=normal
#SBATCH --nodes=1
#SBATCH --time=00:10:00
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null
#SBATCH --uenv=prgenv-gnu/25.11:v1
#SBATCH --view=default

set -eu
export HARNESS_LOGICAL_HOST=al
export HARNESS_READINESS_RUN_TAG=v1
export HARNESS_EXPECTED_REV=3eccb8010edc2605e826957c6a55594e1144461a
exec "$HOME/harness/tests/smoke/jobs/pytorch-readiness.sh"
