#!/usr/bin/env bash
set -euo pipefail

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
python3 "$ROOT/tests/test_productive_idle_pilot.py"
