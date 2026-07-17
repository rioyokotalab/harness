#!/bin/bash
#YBATCH -r epyc-7502_1
#SBATCH --job-name=t217repyc2
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:05:00
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

set -eu
export HARNESS_LOGICAL_HOST=local
export HARNESS_READINESS_RUN_TAG=v2
export HARNESS_EXPECTED_REV=afef3d64a93696d1a55019ac28395d94ed83e3e6
"$HOME/harness/tests/smoke/jobs/source-contract.sh" "$HARNESS_EXPECTED_REV" \
    profiles/hosts/local.conf \
    tests/smoke/checkpoint_restart.cpp \
    tests/smoke/jobs/checkpoint-restart-readiness.sh \
    tests/smoke/jobs/source-contract.sh \
    tests/guarded-test-cleanup.sh
exec "$HOME/harness/tests/smoke/jobs/checkpoint-restart-readiness.sh"
