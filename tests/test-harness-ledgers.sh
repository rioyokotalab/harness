#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

PYTHONDONTWRITEBYTECODE=1 python3 -B "$ROOT/tests/test_harness_ledgers.py"
PYTHONDONTWRITEBYTECODE=1 python3 -B "$ROOT/tools/harness-ledgers.py" validate
PYTHONDONTWRITEBYTECODE=1 python3 -B "$ROOT/tools/harness-ledgers.py" next-task \
    | grep -F 'status=idle' >/dev/null
PYTHONDONTWRITEBYTECODE=1 python3 -B "$ROOT/tools/harness-ledgers.py" next-nightly \
    | grep -F 'status=selected task=Nit-001' >/dev/null

printf '%s\n' 'HARNESS_LEDGER_TEST status=pass'
