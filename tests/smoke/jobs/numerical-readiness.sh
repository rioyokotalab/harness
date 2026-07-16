#!/bin/bash -l
set -euo pipefail

case ${HARNESS_LOGICAL_HOST:-} in
    local|ab|ab2|ri|al|rc|t4) host=$HARNESS_LOGICAL_HOST ;;
    *) printf '%s\n' 'numerical-readiness: invalid HARNESS_LOGICAL_HOST' >&2; exit 2 ;;
esac

gate=numerical-readiness-v1
run_tag=${HARNESS_READINESS_RUN_TAG:-v1}
case $run_tag in
    ''|*[!A-Za-z0-9._-]*)
        printf '%s\n' 'numerical-readiness: invalid HARNESS_READINESS_RUN_TAG' >&2
        exit 2
        ;;
esac
[ "${#run_tag}" -le 32 ] || {
    printf '%s\n' 'numerical-readiness: HARNESS_READINESS_RUN_TAG is too long' >&2
    exit 2
}

if [ "${T210_NUMERIC_ENV_READY:-0}" != 1 ]; then
    case $host in
        ab|ab2)
            module load gcc/15.2.0
            CXX=$(command -v g++)
            export CXX
            ;;
        t4)
            module load gcc/14.2.0
            CXX=$(command -v g++)
            export CXX
            ;;
    esac
    export T210_NUMERIC_ENV_READY=1
    exec /bin/bash "$0"
fi

root=$HOME/harness
state_root=$HOME/.local/state/harness/hpc-readiness
result=$state_root/t210-numerical-$host-$run_tag.out
scratch=${SLURM_TMPDIR:-${TMPDIR:-/tmp}}
build=
capture=
published=0

mkdir -p -- "$state_root"
chmod 700 "$state_root"
[ ! -e "$result" ] && [ ! -L "$result" ] || {
    printf 'numerical-readiness: result already exists: %s\n' "$result" >&2
    exit 2
}
capture=$(mktemp "$state_root/.t210-numerical-$host-$run_tag.XXXXXX")
chmod 600 "$capture"
if ! build=$(mktemp -d "$scratch/t210-numerical-$host-$run_tag.XXXXXX"); then
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
case $host in ri|al) expected_arch=aarch64 ;; *) expected_arch=x86_64 ;; esac
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

: "${CXX:=c++}"
printf 'CXX_COMMAND %s\n' "$(command -v "$CXX")"
printf 'CXX %s\n' "$("$CXX" --version | sed -n '1p')"
printf '%s\n' 'NATIVE $CXX -std=c++20 -O2 -fno-fast-math -ffp-contract=off -frounding-math tests/smoke/numerical.cpp'
"$CXX" -std=c++20 -O2 -fno-fast-math -ffp-contract=off -frounding-math \
    -Wall -Wextra -Werror "$root/tests/smoke/numerical.cpp" -o "$build/numerical"
first=$($build/numerical)
second=$($build/numerical)
[ "$first" = "$second" ] || {
    printf '%s\n' 'FAIL repeated output differs'
    exit 2
}
printf '%s\n' "$first"
printf 'PASS host=%s gate=%s run=%s repeated=identical\n' "$host" "$gate" "$run_tag"
