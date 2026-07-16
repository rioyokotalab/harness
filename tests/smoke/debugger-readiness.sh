#!/bin/bash
set -euo pipefail

case ${HARNESS_LOGICAL_HOST:-} in
    local|ab|ab2|ri|al|rc|t4) host=$HARNESS_LOGICAL_HOST ;;
    *) printf '%s\n' 'debugger-readiness: invalid HARNESS_LOGICAL_HOST' >&2; exit 2 ;;
esac

root=$HOME/harness
scratch=${TMPDIR:-/tmp}
build=$(mktemp -d "$scratch/t212-debugger-$host.XXXXXX")
capture=$build/gdb.out
cleanup=$root/tests/guarded-test-cleanup.sh

finish() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$build" ]; then
        "$cleanup" "$HOME/.local/bin/harness" "$scratch" "$build" "$scratch" \
            >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then status=1; fi
    exit "$status"
}
trap finish EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

umask 077
actual_arch=$(uname -m)
case $host in ri|al) expected_arch=aarch64 ;; *) expected_arch=x86_64 ;; esac
[ "$actual_arch" = "$expected_arch" ] || {
    printf 'FAIL host=%s gate=debugger-readiness-v1 reason=architecture\n' "$host"
    exit 2
}
command -v cc >/dev/null
command -v gdb >/dev/null
printf 'CC %s\n' "$(cc --version | sed -n '1p')"
printf 'GDB %s\n' "$(gdb --version | sed -n '1p')"
cc -g3 -O0 -fno-omit-frame-pointer -Wall -Wextra -Werror \
    "$root/tests/smoke/debugger.c" -o "$build/debugger"
: >"$capture"
chmod 600 "$capture"
if ! gdb --batch --nx --nh \
    -ex 'set pagination off' \
    -ex 'break checkpoint' \
    -ex run \
    -ex 'print value' \
    -ex continue \
    "$build/debugger" >"$capture" 2>&1; then
    printf 'FAIL host=%s gate=debugger-readiness-v1 reason=gdb-exit\n' "$host"
    exit 2
fi
grep -F 'Breakpoint 1, checkpoint' "$capture" >/dev/null || {
    printf 'FAIL host=%s gate=debugger-readiness-v1 reason=breakpoint\n' "$host"
    exit 2
}
grep -F '$1 = 35' "$capture" >/dev/null || {
    printf 'FAIL host=%s gate=debugger-readiness-v1 reason=argument\n' "$host"
    exit 2
}
grep -F 'exited normally' "$capture" >/dev/null || {
    printf 'FAIL host=%s gate=debugger-readiness-v1 reason=program-exit\n' "$host"
    exit 2
}
printf 'PASS host=%s gate=debugger-readiness-v1 arch=%s cleanup=guarded\n' \
    "$host" "$actual_arch"
