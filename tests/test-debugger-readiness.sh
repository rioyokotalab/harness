#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
JOB=$ROOT/tests/smoke/debugger-readiness.sh
SOURCE=$ROOT/tests/smoke/debugger.c

bash -n "$JOB"
grep -F 'gdb --batch --nx --nh' "$JOB" >/dev/null
grep -F -- "-ex 'break checkpoint'" "$JOB" >/dev/null
grep -F -- "-ex 'print value'" "$JOB" >/dev/null
grep -F 'guarded-test-cleanup.sh' "$JOB" >/dev/null
grep -F 'reason=ptrace-policy' "$JOB" >/dev/null
grep -F 'reason=process-limit' "$JOB" >/dev/null
grep -F 'reason=temporary-storage' "$JOB" >/dev/null
grep -F '__attribute__((noinline))' "$SOURCE" >/dev/null
grep -F 'checkpoint(35) == 42' "$SOURCE" >/dev/null
printf '%s\n' 'debugger readiness tests: PASS'
