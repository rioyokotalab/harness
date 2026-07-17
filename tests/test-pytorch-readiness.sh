#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
JOB=$ROOT/tests/smoke/jobs/pytorch-readiness.sh
ROUTES=$ROOT/profiles/pytorch-framework-routes.tsv

bash -n "$JOB"
[ "$(awk 'END {print NR}' "$ROUTES")" -eq 8 ]
for host in local ab ab2 ri al rc t4; do
    [ "$(awk -F '\t' -v host="$host" '$1 == host {count++} END {print count+0}' "$ROUTES")" -eq 1 ]
    grep -F "HARNESS_LOGICAL_HOST=$host" "$ROOT/tests/smoke/jobs/$host-pytorch."* >/dev/null
done
grep -F 'PIP_NO_INDEX=1' "$JOB" >/dev/null
grep -F -- '--require-hashes' "$JOB" >/dev/null
grep -F 'torch.cuda.device_count() == 1' "$JOB" >/dev/null
grep -F 'tests/smoke/llm_torch.py' "$JOB" >/dev/null
grep -F 'tests/guarded-test-cleanup.sh' "$JOB" >/dev/null
# Require the literal runtime assignment.
# shellcheck disable=SC2016
grep -F 'HOME=$real_home' "$JOB" >/dev/null
grep -F '/usr/bin/python3.12' "$JOB" >/dev/null
grep -F 'residue=%s' "$JOB" >/dev/null

printf '%s\n' 'test-pytorch-readiness: PASS'
