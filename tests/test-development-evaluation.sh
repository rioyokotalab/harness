#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
RUNNER=$ROOT/evaluation/development_v2.py

python3 -c 'import sys; compile(open(sys.argv[1], encoding="utf-8").read(), sys.argv[1], "exec")' \
    "$RUNNER"
python3 "$RUNNER" validate |
    grep -F 'VALID experiment=t336-harness-development-v2-20260729-r4 scenarios=16 decision_types=8' \
        >/dev/null
python3 "$RUNNER" selftest |
    grep -F 'development benchmark selftests passed' >/dev/null

pilot=$(python3 "$RUNNER" plan --stage pilot)
confirmation=$(python3 "$RUNNER" plan --stage confirmation)

printf '%s\n' "$pilot" | grep -F 'DEVELOPMENT stage=pilot rows=16 runs=32' >/dev/null
printf '%s\n' "$confirmation" |
    grep -F 'DEVELOPMENT stage=confirmation rows=32 runs=64' >/dev/null
[ "$(printf '%s\n' "$pilot" | grep -c '^PAIR ')" -eq 16 ]
[ "$(printf '%s\n' "$confirmation" | grep -c '^PAIR ')" -eq 32 ]

if rg -n 'shutil\.rmtree|os\.removedirs|subprocess\..*shell *= *True' \
    "$RUNNER" >/dev/null; then
    printf '%s\n' 'development runner contains unsafe cleanup or shell execution' >&2
    exit 1
fi

printf '%s\n' 'development evaluation tests passed'
