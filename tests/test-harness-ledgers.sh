#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

PYTHONDONTWRITEBYTECODE=1 python3 -B "$ROOT/tests/test_harness_ledgers.py"
PYTHONDONTWRITEBYTECODE=1 python3 -B "$ROOT/tools/harness-ledgers.py" validate
PYTHONDONTWRITEBYTECODE=1 python3 -B "$ROOT/tools/harness-ledgers.py" next-task \
    | grep -E 'HARNESS_TASK_SELECTION status=(idle|selected task=Har-[0-9]{3})$' >/dev/null
PYTHONDONTWRITEBYTECODE=1 python3 -B "$ROOT/tools/harness-ledgers.py" next-nightly \
    | grep -E 'status=(idle|selected task=Nit-[0-9]{3})$' >/dev/null

printf '%s\n' 'HARNESS_LEDGER_TEST status=pass'
