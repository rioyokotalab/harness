#!/bin/bash
#$ -N t251mt4
#$ -l node_f=2
#$ -l h_rt=00:05:00
#$ -cwd
#$ -j y
#$ -o /dev/null

set -eu
export HARNESS_LOGICAL_HOST=t4
export HARNESS_READINESS_RUN_TAG=v1
export HARNESS_EXPECTED_REV=62229208500ffb150953e580ba508167aba52eb0
exec "$HOME/harness/tests/smoke/jobs/multinode-mpi-readiness.sh"
