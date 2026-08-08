#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
exec "$ROOT/tests/test-phase1-orchestrator.sh"
