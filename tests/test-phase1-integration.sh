#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS_PHASE1_COMPONENT=integration exec "$ROOT/tests/test-phase1.sh"
