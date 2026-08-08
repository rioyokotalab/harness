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
printf '%s\n' 'venv readiness tests: PASS'
