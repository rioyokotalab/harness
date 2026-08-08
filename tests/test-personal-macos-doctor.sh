#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS_TEST_CASE=doctor exec "$ROOT/tests/test-personal-macos-plan-doctor.sh"
