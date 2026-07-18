#!/bin/bash -l
set -euo pipefail

case ${HARNESS_LOGICAL_HOST:-} in
    local|ab|ab2|al|t4) host=$HARNESS_LOGICAL_HOST ;;
    ri|rc)
        printf '%s\n' 'mpi-readiness: no reviewed base MPI route for this compute architecture' >&2
        exit 2
        ;;
    *) printf '%s\n' 'mpi-readiness: invalid HARNESS_LOGICAL_HOST' >&2; exit 2 ;;
esac

gate=mpi-readiness-v2
run_tag=${HARNESS_READINESS_RUN_TAG:-v1}
case $run_tag in
    ''|*[!A-Za-z0-9._-]*)
        printf '%s\n' 'mpi-readiness: invalid HARNESS_READINESS_RUN_TAG' >&2
        exit 2
        ;;
esac
[ "${#run_tag}" -le 32 ] || {
    printf '%s\n' 'mpi-readiness: HARNESS_READINESS_RUN_TAG is too long' >&2
    exit 2
}

root=$HOME/harness
state_root=$HOME/.local/state/harness/hpc-readiness
result=$state_root/t207-mpi-$host-$run_tag.out
scratch=${SLURM_TMPDIR:-${TMPDIR:-/tmp}}
build=
capture=
published=0

mkdir -p -- "$state_root"
chmod 700 "$state_root"
[ ! -e "$result" ] && [ ! -L "$result" ] || {
    printf 'mpi-readiness: result already exists: %s\n' "$result" >&2
    exit 2
}
capture=$(mktemp "$state_root/.t207-mpi-$host-$run_tag.XXXXXX")
chmod 600 "$capture"
if ! build=$(mktemp -d "$scratch/t207-mpi-$host-$run_tag.XXXXXX"); then
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

printf 'GATE host=%s kind=%s run=%s\n' "$host" "$gate" "$run_tag"
case $host in
    local)
        # shellcheck source=/dev/null
        . "$root/shell/module-stack.sh" local
        ;;
    ab|ab2)
        module unload hpcx/2.26 >/dev/null 2>&1 || true
        module load hpcx/2.26
        ;;
    t4)
        module unload ylab/hpcx/2.21.0 >/dev/null 2>&1 || true
        module load ylab/hpcx/2.21.0
        ;;
esac
actual_arch=$(uname -m)
case $host in al) expected_arch=aarch64 ;; *) expected_arch=x86_64 ;; esac
[ "$actual_arch" = "$expected_arch" ] || {
    printf 'FAIL architecture expected=%s observed=%s\n' "$expected_arch" "$actual_arch"
    exit 2
}
printf 'ARCH %s\n' "$actual_arch"
case $host in
    local|al) [ -n "${SLURM_JOB_ID:-}" ] ;;
    ab|ab2) [ -n "${PBS_JOBID:-}" ] ;;
    t4) [ -n "${JOB_ID:-}" ] ;;
esac

command -v mpicc >/dev/null
printf 'MPICC_COMMAND %s\n' "$(command -v mpicc)"
case $host in
    al) mpicc --version | sed -n '1p' ;;
    *) mpicc --showme:version ;;
esac
printf '%s\n' 'NATIVE mpicc -O2 tests/smoke/mpi.c -o BUILD/mpi'
mpicc -O2 "$root/tests/smoke/mpi.c" -o "$build/mpi"

OMP_NUM_THREADS=1
export OMP_NUM_THREADS
case $host in
    al)
        printf 'LAUNCHER %s\n' "$(srun --version | sed -n '1p')"
        printf '%s\n' 'NATIVE srun --ntasks=2 BUILD/mpi 2'
        srun --ntasks=2 "$build/mpi" 2
        ;;
    *)
        printf 'LAUNCHER %s\n' "$(mpirun --version | sed -n '1p')"
        printf '%s\n' 'NATIVE mpirun -n 2 BUILD/mpi 2'
        mpirun -n 2 "$build/mpi" 2
        ;;
esac

printf 'PASS host=%s gate=%s run=%s ranks=2\n' "$host" "$gate" "$run_tag"
