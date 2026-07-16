#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
PROBE=$ROOT/tests/smoke/scientific-library-readiness.sh
FIXTURE=$ROOT/tests/fixtures/scientific-library-bin
OUTPUT=$(mktemp "${TMPDIR:-/tmp}/scientific-library-test.XXXXXX")
trap 'unlink -- "$OUTPUT"' EXIT HUP INT TERM

sh -n "$PROBE"
PATH=$FIXTURE:/usr/bin:/bin HARNESS_LOGICAL_HOST=local "$PROBE" >"$OUTPUT"
grep -Fx 'SCIENTIFIC_LIBRARY_SCHEMA 1' "$OUTPUT" >/dev/null
grep -Fx 'HOST local' "$OUTPUT" >/dev/null
grep -Fx 'WRAPPER h5cc present' "$OUTPUT" >/dev/null
grep -Fx 'WRAPPER h5pcc absent' "$OUTPUT" >/dev/null
grep -Fx 'WRAPPER nc-config present' "$OUTPUT" >/dev/null
grep -Fx 'PACKAGE hdf5 present 1.14.3' "$OUTPUT" >/dev/null
grep -Fx 'PACKAGE blas present 3.11.0' "$OUTPUT" >/dev/null
grep -Fx 'PACKAGE fftw3 absent' "$OUTPUT" >/dev/null
grep -Fx 'PASS host=local gate=scientific-library-login-surface-v1 scope=visible-login-environment' "$OUTPUT" >/dev/null
[ "$(wc -l <"$OUTPUT" | tr -d ' ')" -eq 19 ]
if PATH=$FIXTURE:/usr/bin:/bin HARNESS_LOGICAL_HOST=invalid "$PROBE" >/dev/null 2>&1; then
    printf '%s\n' 'FAIL: invalid host accepted' >&2
    exit 1
fi
printf '%s\n' 'scientific library readiness tests: PASS'
