#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
JOB=$ROOT/tests/smoke/locked-venv-readiness.sh
PROJECT=$ROOT/tests/fixtures/offline-project

bash -n "$JOB"
python3 - "$PROJECT/pyproject.toml" "$PROJECT/uv.lock" <<'PY'
import pathlib
import sys
import tomllib

project = tomllib.loads(pathlib.Path(sys.argv[1]).read_text())
lock = tomllib.loads(pathlib.Path(sys.argv[2]).read_text())
assert project["project"]["name"] == "harness-offline-lock-probe"
assert project["project"]["dependencies"] == []
assert lock["version"] == 1
assert lock["requires-python"] == project["project"]["requires-python"]
assert lock["package"] == [{
    "name": project["project"]["name"],
    "version": project["project"]["version"],
    "source": {"virtual": "."},
}]
PY
for token in \
    'UV_PROJECT_ENVIRONMENT=$build/venv' \
    'UV_OFFLINE=1' \
    'UV_PYTHON_DOWNLOADS=never' \
    '--frozen --offline' \
    '--no-python-downloads --no-install-project --no-editable --no-config' \
    'site.ENABLE_USER_SITE is False' \
    'guarded-test-cleanup.sh'
do
    grep -F -- "$token" "$JOB" >/dev/null
done
if grep -E 'rm[[:space:]]+(-[^[:space:]]*)*[rR]|--recursive|find[[:space:]].*-delete|rsync[[:space:]].*--delete' \
    "$JOB" >/dev/null; then
    printf '%s\n' 'FAIL: unsafe locked-venv cleanup' >&2
    exit 1
fi
printf '%s\n' 'locked venv readiness tests: PASS'
