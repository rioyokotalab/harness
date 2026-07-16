#!/bin/bash
set -eu

case ${HARNESS_EXPECTED_HOST:-} in
    local|ab|ab2|ri|al|rc|t4) expected_host=$HARNESS_EXPECTED_HOST ;;
    *) printf '%s\n' 'cache-startup-readiness: invalid HARNESS_EXPECTED_HOST' >&2; exit 2 ;;
esac

# Remove the submit shell's values before login startup. The inner process can
# pass only if the first-line managed bootstrap reconstructs them.
if [ "${T201_IN_LOGIN:-0}" != 1 ]; then
    unset HARNESS_LOGICAL_HOST HARNESS_PERSISTENT_ROOT HARNESS_CACHE_ROOT
    unset XDG_CACHE_HOME PIP_CACHE_DIR UV_CACHE_DIR npm_config_cache
    unset CUDA_CACHE_PATH CUPY_CACHE_DIR TRITON_CACHE_DIR
    unset APPTAINER_CACHEDIR SINGULARITY_CACHEDIR
    export T201_IN_LOGIN=1
    exec /bin/bash -l "$0"
fi
if [ "${T201_BODY_READY:-0}" != 1 ]; then
    export T201_BODY_READY=1
    exec /bin/bash "$0"
fi

case $expected_host in
    local) expected_cache=/mnt/nfs-03/fast/Users/rioyokota/home-cache ;;
    ab) expected_cache=/groups/gag51395/yokota/cache ;;
    ab2) expected_cache=/groups/gah51624/yokota/cache ;;
    ri) expected_cache=/data1/rkp00015/rku00075/cache ;;
    al) expected_cache=/capstor/scratch/cscs/ryokota/home-cache ;;
    rc) expected_cache=/lvs0/rccs-asfm/rio.yokota/cache ;;
    t4) expected_cache=/gs/fs/jh250019/yokota/home-cache ;;
esac

state_root=$HOME/.local/state/harness/hpc-readiness
result=$state_root/t201-cache-startup-$expected_host.out
mkdir -p -- "$state_root"
chmod 700 "$state_root"
[ ! -e "$result" ] && [ ! -L "$result" ] || {
    printf 'cache-startup-readiness: result already exists: %s\n' "$result" >&2
    exit 2
}
capture=$(mktemp "$state_root/.t201-cache-startup-$expected_host.XXXXXX")
chmod 600 "$capture"
published=0
finish() {
    status=$?
    trap - EXIT HUP INT TERM
    if [ -f "$capture" ] && [ "$published" -eq 0 ]; then
        printf 'RESULT host=%s status=%s\n' "$expected_host" "$status" >>"$capture"
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

printf 'GATE host=%s kind=cache-startup-v1\n' "$expected_host"
[ "${HARNESS_LOGICAL_HOST:-}" = "$expected_host" ] || exit 2
[ "${HARNESS_CACHE_ROOT:-}" = "$expected_cache" ] || exit 2
[ "${XDG_CACHE_HOME:-}" = "$expected_cache/xdg" ] || exit 2
[ "${PIP_CACHE_DIR:-}" = "$expected_cache/pip" ] || exit 2
[ "${CUDA_CACHE_PATH:-}" = "$expected_cache/cuda" ] || exit 2
[ "${TRITON_CACHE_DIR:-}" = "$expected_cache/triton" ] || exit 2
[ "${APPTAINER_CACHEDIR:-}" = "$expected_cache/apptainer" ] || exit 2
printf 'PASS host=%s gate=cache-startup-v1\n' "$expected_host"
