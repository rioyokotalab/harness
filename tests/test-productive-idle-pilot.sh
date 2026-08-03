#!/usr/bin/env bash
set -euo pipefail

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
PYTHONDONTWRITEBYTECODE=1 python3 -B "$ROOT/tests/test_productive_idle_pilot.py"
[ ! -d "$ROOT/tools/__pycache__" ] || {
    printf '%s\n' 'FAIL: productive-idle tests wrote repository bytecode' >&2
    exit 1
}
