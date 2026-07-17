#!/bin/bash
#YBATCH -r epyc-7502_1
#SBATCH --time=00:05:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --job-name=t237aepyc2
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

set -eu
export HARNESS_LOGICAL_HOST=local
export HARNESS_READINESS_RUN_TAG=v2
export HARNESS_EXPECTED_REV=8c36d8b4a29992a80ed4a38efc4b08ad960423af
"$HOME/harness/tests/smoke/jobs/source-contract.sh" "$HARNESS_EXPECTED_REV" \
    tests/smoke/affinity.cpp \
    tests/smoke/jobs/affinity-readiness.sh \
    tests/smoke/jobs/source-contract.sh \
    tests/guarded-test-cleanup.sh
exec "$HOME/harness/tests/smoke/jobs/affinity-readiness.sh"
