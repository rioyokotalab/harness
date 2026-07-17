#!/bin/bash
#$ -N t251ft4
#$ -l gpu_h=1
#$ -l h_rt=00:10:00
#$ -cwd
#$ -j y
#$ -o /dev/null

set -eu
export HARNESS_LOGICAL_HOST=t4
export HARNESS_READINESS_RUN_TAG=v1
export HARNESS_EXPECTED_REV=0000000000000000000000000000000000000000
exec "$HOME/harness/tests/smoke/jobs/pytorch-readiness.sh"
