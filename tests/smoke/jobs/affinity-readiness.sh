#!/bin/bash -l
set -euo pipefail

case ${HARNESS_LOGICAL_HOST:-} in
    local|ab|ab2|ri|al|rc|t4) host=$HARNESS_LOGICAL_HOST ;;
    *) printf '%s\n' 'affinity-readiness: invalid HARNESS_LOGICAL_HOST' >&2; exit 2 ;;
esac

run_tag=${HARNESS_READINESS_RUN_TAG:-v1}
case $run_tag in
    ''|*[!A-Za-z0-9._-]*)
        printf '%s\n' 'affinity-readiness: invalid HARNESS_READINESS_RUN_TAG' >&2
        exit 2
        ;;
esac
[ "${#run_tag}" -le 32 ] || {
    printf '%s\n' 'affinity-readiness: HARNESS_READINESS_RUN_TAG is too long' >&2
    exit 2
}
case ${HARNESS_EXPECTED_REV:-} in
    ''|*[!0-9a-f]*)
        printf '%s\n' 'affinity-readiness: invalid HARNESS_EXPECTED_REV' >&2
        exit 2
        ;;
esac
[ "${#HARNESS_EXPECTED_REV}" -eq 40 ] || {
    printf '%s\n' 'affinity-readiness: invalid HARNESS_EXPECTED_REV' >&2
    exit 2
}

if [ "${T237_ENV_READY:-0}" != 1 ]; then
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
    export T237_ENV_READY=1
    exec /bin/bash "$0"
fi

root=$HOME/harness
state_root=$HOME/.local/state/harness/hpc-readiness
result=$state_root/t237-affinity-$host-$run_tag.out
scratch=${SLURM_TMPDIR:-${TMPDIR:-/tmp}}
build=
capture=
published=0

mkdir -p -- "$state_root"
chmod 700 "$state_root"
[ ! -e "$result" ] && [ ! -L "$result" ] || {
    printf 'affinity-readiness: result already exists: %s\n' "$result" >&2
    exit 2
}
capture=$(mktemp "$state_root/.t237-affinity-$host-$run_tag.XXXXXX")
chmod 600 "$capture"
if ! build=$(mktemp -d "$scratch/t237-affinity-$host-$run_tag.XXXXXX"); then
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

case $host in
    local|ri|al|rc) [ -n "${SLURM_JOB_ID:-}" ] ;;
    ab|ab2) [ -n "${PBS_JOBID:-}" ] ;;
    t4) [ -n "${JOB_ID:-}" ] ;;
esac

"$root/tests/smoke/jobs/source-contract.sh" "$HARNESS_EXPECTED_REV" \
    tests/smoke/affinity.cpp \
    tests/smoke/jobs/affinity-readiness.sh \
    tests/smoke/jobs/source-contract.sh \
    tests/guarded-test-cleanup.sh

: "${CXX:=c++}"
printf 'GATE host=%s kind=affinity-readiness-v1 run=%s\n' "$host" "$run_tag"
printf 'CXX_COMMAND %s\n' "$(command -v "$CXX")"
printf 'CXX %s\n' "$("$CXX" --version | sed -n '1p')"
printf '%s\n' 'NATIVE $CXX -std=c++20 -O2 -pthread tests/smoke/affinity.cpp'
"$CXX" -std=c++20 -O2 -pthread -Wall -Wextra -Werror \
    "$root/tests/smoke/affinity.cpp" -o "$build/affinity"
"$build/affinity" 2
printf 'PASS host=%s gate=affinity-readiness-v1 run=%s\n' "$host" "$run_tag"
