#!/bin/bash
#$ -N t251ft43
#$ -l gpu_h=1
#$ -l h_rt=00:10:00
#$ -cwd
#$ -j y
#$ -o /dev/null

set -eu
export HARNESS_LOGICAL_HOST=t4
export HARNESS_READINESS_RUN_TAG=v3
export HARNESS_EXPECTED_REV=207fbe9d7fe074ab7fd1eddb6335fe257f0c66fb
exec "$HOME/harness/tests/smoke/jobs/pytorch-readiness.sh"
