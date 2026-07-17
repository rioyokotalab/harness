#!/bin/bash
#YBATCH -r epyc-7502_1
#SBATCH --time=00:05:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --job-name=t210nepyc3
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

set -eu
export HARNESS_LOGICAL_HOST=local
export HARNESS_READINESS_RUN_TAG=v3
export HARNESS_EXPECTED_REV=afef3d64a93696d1a55019ac28395d94ed83e3e6
"$HOME/harness/tests/smoke/jobs/source-contract.sh" "$HARNESS_EXPECTED_REV" \
    tests/smoke/numerical.cpp \
    tests/smoke/jobs/numerical-readiness.sh \
    tests/smoke/jobs/source-contract.sh \
    tests/guarded-test-cleanup.sh
exec "$HOME/harness/tests/smoke/jobs/numerical-readiness.sh"
