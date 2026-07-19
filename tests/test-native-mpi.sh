#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/harness-native-mpi-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    "$CLEANUP" "$ROOT/bin/harness" "$TEMP_BASE" "$TEMP_DIR" "$TEMP_BASE" \
        >/dev/null || status=1
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

[ "${HARNESS_NATIVE_MPI:-0}" = 1 ] || {
    printf '%s\n' 'native MPI test requires HARNESS_NATIVE_MPI=1 and a declared environment' >&2
    exit 2
}
command -v mpicc >/dev/null 2>&1 || {
    printf '%s\n' 'declared native MPI environment does not resolve mpicc' >&2
    exit 1
}

printf '%s\n' 'NATIVE mpicc -O2 tests/smoke/mpi.c -o BUILD/mpi'
mpicc -O2 "$ROOT/tests/smoke/mpi.c" -o "$TEMP_DIR/mpi"
[ "$("$TEMP_DIR/mpi" 1)" = 'mpi=pass ranks=1' ] || {
    printf '%s\n' 'native MPI singleton smoke failed' >&2
    exit 1
}
printf '%s\n' 'NATIVE mpicc -O2 tests/smoke/mpi-multinode.c -o BUILD/mpi-multinode'
mpicc -O2 "$ROOT/tests/smoke/mpi-multinode.c" -o "$TEMP_DIR/mpi-multinode"
printf '%s\n' 'native MPI tests: PASS'
