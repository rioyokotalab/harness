#!/bin/bash
#YBATCH -r epyc-7502_1
#SBATCH --time=00:05:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --job-name=t210nepyc2
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

set -eu
export HARNESS_LOGICAL_HOST=local
export HARNESS_READINESS_RUN_TAG=v2
export HARNESS_EXPECTED_REV=0000000000000000000000000000000000000000
"$HOME/harness/tests/smoke/jobs/source-contract.sh" "$HARNESS_EXPECTED_REV" \
    tests/smoke/numerical.cpp \
    tests/smoke/jobs/numerical-readiness.sh \
    tests/smoke/jobs/source-contract.sh \
    tests/guarded-test-cleanup.sh
exec "$HOME/harness/tests/smoke/jobs/numerical-readiness.sh"
