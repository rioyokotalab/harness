#!/bin/sh
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS_TEST_CASE=compute-debugger exec "$ROOT/tests/test-hpc-readiness.sh"
