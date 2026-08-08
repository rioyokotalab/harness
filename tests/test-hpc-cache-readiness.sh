#!/bin/sh
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS_TEST_CASE=cache exec "$ROOT/tests/test-hpc-readiness.sh"
