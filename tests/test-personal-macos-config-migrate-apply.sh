#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS_TEST_CASE=apply exec "$ROOT/tests/test-personal-macos-config-migrate.sh"
