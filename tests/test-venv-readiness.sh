#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
JOB=$ROOT/tests/smoke/venv-readiness.sh

bash -n "$JOB"
grep -F 'UV_OFFLINE=1' "$JOB" >/dev/null
grep -F 'UV_PYTHON_DOWNLOADS=never' "$JOB" >/dev/null
grep -F 'uv=$HOME/.local/bin/uv' "$JOB" >/dev/null
grep -F 'python=$HOME/.local/bin/python3.12' "$JOB" >/dev/null
grep -F '"$uv" --offline --no-python-downloads venv --no-project' "$JOB" >/dev/null
grep -F 'site.ENABLE_USER_SITE is False' "$JOB" >/dev/null
grep -F 'guarded-test-cleanup.sh' "$JOB" >/dev/null
if grep -E 'rm[[:space:]]+(-[^[:space:]]*)*[rR]|--recursive|find[[:space:]].*-delete|rsync[[:space:]].*--delete' \
    "$JOB" >/dev/null; then
    printf '%s\n' 'FAIL: unsafe venv cleanup' >&2
    exit 1
fi
printf '%s\n' 'venv readiness tests: PASS'
