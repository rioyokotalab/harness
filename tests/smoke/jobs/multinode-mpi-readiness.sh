#!/bin/bash
set -euo pipefail

case ${HARNESS_LOGICAL_HOST:-} in
    local|ab|ab2|al|t4) host=$HARNESS_LOGICAL_HOST ;;
    *) printf '%s\n' 'multinode-mpi-readiness: host has no reviewed route' >&2; exit 2 ;;
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
case $host in
    al) task=t230; default_run_tag=v2 ;;
    *) task=t251; default_run_tag=v1 ;;
esac
run_tag=${HARNESS_READINESS_RUN_TAG:-$default_run_tag}
case $run_tag in ''|*[!A-Za-z0-9._-]*) exit 2 ;; esac
[ "${#run_tag}" -le 32 ] || exit 2
result=$state_root/$task-multinode-mpi-$host-$run_tag.out
build_root=$state_root
build=
capture=
published=0

mkdir -p -- "$state_root"
chmod 700 "$state_root"
[ ! -e "$result" ] && [ ! -L "$result" ] || {
    printf 'multinode-mpi-readiness: result already exists: %s\n' "$result" >&2
    exit 2
}
capture=$(mktemp "$state_root/.$task-multinode-mpi-$host-$run_tag.XXXXXX")
chmod 600 "$capture"
if ! build=$(mktemp -d "$build_root/.$task-multinode-build-$host-$run_tag.XXXXXX"); then
    unlink -- "$capture"
    exit 2
fi
chmod 700 "$build"

finish() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -n "$build" ] && [ -d "$build" ]; then
        "$root/tests/guarded-test-cleanup.sh" "$HOME/.local/bin/harness" \
            "$build_root" "$build" "$build_root" >/dev/null || cleanup_failed=1
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
    tests/smoke/jobs/shared-executable-visibility.sh \
    tests/smoke/jobs/source-contract.sh \
    tests/guarded-test-cleanup.sh \
    profiles/hpc-multinode-mpi-routes.tsv \
    "profiles/hosts/$host.conf"
case $host in al) expected_arch=aarch64 ;; *) expected_arch=x86_64 ;; esac
[ "$(uname -m)" = "$expected_arch" ] || exit 2
case $host in
    local|al)
        [ -n "${SLURM_JOB_ID:-}" ] || exit 2
        [ "${SLURM_JOB_NUM_NODES:-}" = 2 ] || exit 2
        ;;
    ab|ab2)
        [ -n "${PBS_JOBID:-}" ] || exit 2
        [ -f "${PBS_NODEFILE:-}" ] || exit 2
        [ "$(sort -u "$PBS_NODEFILE" | wc -l)" -eq 2 ] || exit 2
        module load hpcx/2.26
        ;;
    t4)
        [ -n "${JOB_ID:-}" ] || exit 2
        module load ylab/hpcx/2.21.0
        ;;
esac
command -v mpicc >/dev/null
printf '%s\n' 'NATIVE mpicc -O2 tests/smoke/mpi-multinode.c -o BUILD/mpi-multinode'
mpicc -O2 "$root/tests/smoke/mpi-multinode.c" -o "$build/mpi-multinode"
digest=$(sha256sum "$build/mpi-multinode" | awk '{ print $1 }')
case $host in
    local)
        run_launcher() { mpirun -n 2 --map-by ppr:1:node "$@"; }
        ;;
    ab|ab2)
        run_launcher() {
            mpirun -np 2 --map-by ppr:1:node --hostfile "$PBS_NODEFILE" "$@"
        }
        ;;
    al)
        run_launcher() { srun --nodes=2 --ntasks=2 --ntasks-per-node=1 "$@"; }
        ;;
    t4)
        run_launcher() { mpirun -npernode 1 -n 2 -x LD_LIBRARY_PATH "$@"; }
        ;;
esac
visibility=$(run_launcher \
    "$root/tests/smoke/jobs/shared-executable-visibility.sh" \
    "$build_root" "$build/mpi-multinode" "$digest")
[ "$(printf '%s\n' "$visibility" | grep -Fxc \
    "SHARED_EXECUTABLE sha256=$digest status=pass")" -eq 2 ] || exit 2
printf 'SHARED_EXECUTABLE ranks=2 sha256=%s status=pass\n' "$digest"
case $host in
    local) printf '%s\n' 'NATIVE mpirun -n 2 --map-by ppr:1:node BUILD/mpi-multinode' ;;
    ab|ab2) printf '%s\n' 'NATIVE mpirun -np 2 --map-by ppr:1:node --hostfile $PBS_NODEFILE BUILD/mpi-multinode' ;;
    al) printf '%s\n' 'NATIVE srun --nodes=2 --ntasks=2 --ntasks-per-node=1 BUILD/mpi-multinode' ;;
    t4) printf '%s\n' 'NATIVE mpirun -npernode 1 -n 2 -x LD_LIBRARY_PATH BUILD/mpi-multinode' ;;
esac
run_launcher "$build/mpi-multinode"
printf 'PASS host=%s gate=multinode-mpi-v3 run=%s ranks=2 hosts=2 build=shared-private-state\n' \
    "$host" "$run_tag"
