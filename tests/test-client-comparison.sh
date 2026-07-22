#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

python3 "$ROOT/evaluation/compare_clients.py" validate >/dev/null
pilot=$(python3 "$ROOT/evaluation/compare_clients.py" plan --stage pilot)
full=$(python3 "$ROOT/evaluation/compare_clients.py" plan --stage full)

printf '%s\n' "$pilot" | grep -F 'runs_per_client=9 total_runs=18' >/dev/null
printf '%s\n' "$full" | grep -F 'runs_per_client=35 total_runs=70' >/dev/null
printf '%s\n' "$pilot" | grep -F 'CLIENT codex ' >/dev/null
printf '%s\n' "$pilot" | grep -F 'CLIENT claude ' >/dev/null

printf 'client comparison tests passed\n'
