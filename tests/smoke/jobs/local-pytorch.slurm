#!/bin/bash
#YBATCH -r a4500_1
#SBATCH --time=00:10:00
#SBATCH --job-name=t251flocal2
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

set -eu
export HARNESS_LOGICAL_HOST=local
export HARNESS_READINESS_RUN_TAG=v2
export HARNESS_EXPECTED_REV=3eccb8010edc2605e826957c6a55594e1144461a
exec "$HOME/harness/tests/smoke/jobs/pytorch-readiness.sh"
