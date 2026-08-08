#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
if ! command -v shellcheck >/dev/null 2>&1; then
    printf '%s\n' 'SKIP ShellCheck: command unavailable'
    exit 0
fi
git -C "$ROOT" grep -Il -z '^#!.*\(sh\|bash\)' -- . \
    ':(exclude)tests/fixtures/**' |
    xargs -0 shellcheck --severity=warning
printf '%s\n' 'ShellCheck tests: PASS'
