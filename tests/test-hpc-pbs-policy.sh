#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
sites=$ROOT/shared/skills/operate-native-hpc/references/sites.md

grep -F 'Suppress PBS lifecycle email by default for every agent-run job.' \
    "$sites" >/dev/null
grep -F '`#PBS -m n`' "$sites" >/dev/null
for job in "$ROOT"/tests/smoke/jobs/*.pbs; do
    [ "$(grep -Fxc '#PBS -m n' "$job")" -eq 1 ]
done

printf '%s\n' 'HPC PBS policy tests: PASS'
