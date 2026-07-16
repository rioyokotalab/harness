#!/bin/bash -l
set -euo pipefail

case ${HARNESS_LOGICAL_HOST:-} in
    local|ab|ab2|ri|al|rc|t4) host=$HARNESS_LOGICAL_HOST ;;
    *) printf '%s\n' 'accelerator-readiness: invalid HARNESS_LOGICAL_HOST' >&2; exit 2 ;;
esac

gate=accelerator-readiness-v1
run_tag=${HARNESS_READINESS_RUN_TAG:-v1}
case $run_tag in
    ''|*[!A-Za-z0-9._-]*)
        printf '%s\n' 'accelerator-readiness: invalid HARNESS_READINESS_RUN_TAG' >&2
        exit 2
        ;;
esac
[ "${#run_tag}" -le 32 ] || {
    printf '%s\n' 'accelerator-readiness: HARNESS_READINESS_RUN_TAG is too long' >&2
    exit 2
}

# Site environment selection is explicit and process-local. AL enters its uenv
# through native submission flags, so this script never nests a scheduler action.
if [ "${T200_ACCEL_ENV_READY:-0}" != 1 ]; then
    case $host in
        local) module load cuda/12.8 ;;
        ab|ab2) module load cuda/13.2/13.2.1 ;;
        t4) module purge; module load cuda/12.8.0 ;;
    esac
    export T200_ACCEL_ENV_READY=1
    exec /bin/bash "$0"
fi

root=$HOME/harness
state_root=$HOME/.local/state/harness/hpc-readiness
result=$state_root/t200-accelerator-$host-$run_tag.out
scratch=${SLURM_TMPDIR:-${TMPDIR:-/tmp}}
build=
capture=
published=0

mkdir -p -- "$state_root"
chmod 700 "$state_root"
[ ! -e "$result" ] && [ ! -L "$result" ] || {
    printf 'accelerator-readiness: result already exists: %s\n' "$result" >&2
    exit 2
}
capture=$(mktemp "$state_root/.t200-accelerator-$host-$run_tag.XXXXXX")
chmod 600 "$capture"
if ! build=$(mktemp -d "$scratch/t200-accelerator-$host-$run_tag.XXXXXX"); then
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
actual_arch=$(uname -m)
case $host in
    ri|al) expected_arch=aarch64 ;;
    *) expected_arch=x86_64 ;;
esac
[ "$actual_arch" = "$expected_arch" ] || {
    printf 'FAIL architecture expected=%s observed=%s\n' "$expected_arch" "$actual_arch"
    exit 2
}
printf 'ARCH %s\n' "$actual_arch"

case $host in
    local|ri|al|rc) [ -n "${SLURM_JOB_ID:-}" ] ;;
    ab|ab2) [ -n "${PBS_JOBID:-}" ] ;;
    t4) [ -n "${JOB_ID:-}" ] ;;
esac

# Select one logical accelerator even on whole-node allocation systems.
CUDA_VISIBLE_DEVICES=0
export CUDA_VISIBLE_DEVICES
command -v nvidia-smi >/dev/null
printf 'NVIDIA_SMI %s\n' "$(command -v nvidia-smi)"
gpu_line=$(nvidia-smi -i 0 --query-gpu=name,driver_version,compute_cap \
    --format=csv,noheader)
[ -n "$gpu_line" ]
printf 'GPU %s\n' "$gpu_line"
printf '%s\n' 'PASS driver-runtime'

case $host in
    ri|rc)
        printf '%s\n' 'SKIP cuda-compile: no reviewed toolkit route'
        ;;
    *)
        command -v nvcc >/dev/null
        printf 'NVCC_COMMAND %s\n' "$(command -v nvcc)"
        nvcc --version | sed -n '/release/p'
        printf '%s\n' 'NATIVE nvcc tests/smoke/cuda.cu -o BUILD/cuda'
        nvcc -O2 "$root/tests/smoke/cuda.cu" -o "$build/cuda"
        "$build/cuda"
        printf '%s\n' 'PASS cuda-kernel'
        ;;
esac

printf '%s\n' 'SKIP framework: no reviewed project environment or image'
printf 'PASS host=%s gate=%s run=%s\n' "$host" "$gate" "$run_tag"
