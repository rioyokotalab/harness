#!/bin/bash
set -euo pipefail

case ${HARNESS_LOGICAL_HOST:-} in
    al) host=al ;;
    *) printf '%s\n' 'multinode-mpi-readiness: only the reviewed AL route is enabled' >&2; exit 2 ;;
esac
case ${HARNESS_EXPECTED_REV:-} in
    ''|*[!0-9a-f]*) printf '%s\n' 'multinode-mpi-readiness: invalid expected revision' >&2; exit 2 ;;
esac
[ "${#HARNESS_EXPECTED_REV}" -eq 40 ] || {
    printf '%s\n' 'multinode-mpi-readiness: invalid expected revision' >&2
    exit 2
}

root=$HOME/harness
state_root=$HOME/.local/state/harness/hpc-readiness
result=$state_root/t230-multinode-mpi-al-v1.out
scratch=${SLURM_TMPDIR:-${TMPDIR:-/tmp}}
build=
capture=
published=0

mkdir -p -- "$state_root"
chmod 700 "$state_root"
[ ! -e "$result" ] && [ ! -L "$result" ] || {
    printf 'multinode-mpi-readiness: result already exists: %s\n' "$result" >&2
    exit 2
}
capture=$(mktemp "$state_root/.t230-multinode-mpi-al-v1.XXXXXX")
chmod 600 "$capture"
if ! build=$(mktemp -d "$scratch/t230-multinode-mpi-al-v1.XXXXXX"); then
    unlink -- "$capture"
    exit 2
fi

finish() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -n "$build" ] && [ -d "$build" ]; then
        "$root/tests/guarded-test-cleanup.sh" "$HOME/.local/bin/harness" \
            "$scratch" "$build" "$scratch" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then status=1; fi
    if [ -n "$capture" ] && [ -f "$capture" ] && [ "$published" -eq 0 ]; then
        printf 'RESULT host=%s status=%s\n' "$host" "$status" >>"$capture"
        if ln -- "$capture" "$result"; then
            unlink -- "$capture"
            published=1
        else
            status=1
        fi
    fi
    exit "$status"
}
trap finish EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
exec >"$capture" 2>&1
umask 077

"$root/tests/smoke/jobs/source-contract.sh" "$HARNESS_EXPECTED_REV" \
    tests/smoke/mpi-multinode.c \
    tests/smoke/jobs/multinode-mpi-readiness.sh \
    tests/smoke/jobs/source-contract.sh \
    tests/guarded-test-cleanup.sh \
    profiles/hpc-multinode-mpi-routes.tsv \
    profiles/hosts/al.conf
[ "$(uname -m)" = aarch64 ] || exit 2
[ -n "${SLURM_JOB_ID:-}" ] || exit 2
[ "${SLURM_JOB_NUM_NODES:-}" = 2 ] || exit 2
command -v mpicc >/dev/null
printf '%s\n' 'NATIVE mpicc -O2 tests/smoke/mpi-multinode.c -o BUILD/mpi-multinode'
mpicc -O2 "$root/tests/smoke/mpi-multinode.c" -o "$build/mpi-multinode"
printf '%s\n' 'NATIVE srun --nodes=2 --ntasks=2 --ntasks-per-node=1 BUILD/mpi-multinode'
srun --nodes=2 --ntasks=2 --ntasks-per-node=1 "$build/mpi-multinode"
printf 'PASS host=%s gate=multinode-mpi-v1 ranks=2 hosts=2\n' "$host"
