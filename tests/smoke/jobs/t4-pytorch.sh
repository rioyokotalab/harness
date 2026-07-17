#!/bin/bash
#$ -N t251ft42
#$ -l gpu_h=1
#$ -l h_rt=00:10:00
#$ -cwd
#$ -j y
#$ -o /dev/null

set -eu
export HARNESS_LOGICAL_HOST=t4
export HARNESS_READINESS_RUN_TAG=v2
export HARNESS_EXPECTED_REV=195b26cbe4d6454cb7d62635debb306c1200214d
exec "$HOME/harness/tests/smoke/jobs/pytorch-readiness.sh"
