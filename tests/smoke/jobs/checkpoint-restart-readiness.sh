#!/bin/bash -l
set -euo pipefail

case ${HARNESS_LOGICAL_HOST:-} in
    local|ab|ab2|ri|al|rc|t4) host=$HARNESS_LOGICAL_HOST ;;
    *) printf '%s\n' 'checkpoint-restart-readiness: invalid host' >&2; exit 2 ;;
esac
run_tag=${HARNESS_READINESS_RUN_TAG:-v1}
case $run_tag in ''|*[!A-Za-z0-9._-]*) exit 2 ;; esac
[ "${#run_tag}" -le 32 ] || exit 2

if [ "${T217_ENV_READY:-0}" != 1 ]; then
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
    export T217_ENV_READY=1
    exec /bin/bash "$0"
fi

root=$HOME/harness
state_root=$HOME/.local/state/harness/hpc-readiness
result=$state_root/t217-checkpoint-restart-$host-$run_tag.out
profile=$root/profiles/hosts/$host.conf
[ "$(grep -c '^persistent_root=' "$profile")" -eq 1 ] || exit 2
persistent_root=$(sed -n 's/^persistent_root=//p' "$profile")
case $persistent_root in /*) ;; *) exit 2 ;; esac
[ -d "$persistent_root" ] && [ ! -L "$persistent_root" ] || exit 2
checkpoint=$persistent_root/.harness-t217-$host-$run_tag.chk
[ ! -e "$checkpoint" ] && [ ! -L "$checkpoint" ] || {
    printf '%s\n' 'checkpoint-restart-readiness: checkpoint collision' >&2
    exit 2
}

scratch=${SLURM_TMPDIR:-${TMPDIR:-/tmp}}
build=
capture=
published=0
checkpoint_identity=
uid=$(id -u)
mkdir -p -- "$state_root"
chmod 700 "$state_root"
[ ! -e "$result" ] && [ ! -L "$result" ] || {
    printf '%s\n' 'checkpoint-restart-readiness: result collision' >&2
    exit 2
}
capture=$(mktemp "$state_root/.t217-checkpoint-restart-$host-$run_tag.XXXXXX")
chmod 600 "$capture"
build=$(mktemp -d "$scratch/t217-checkpoint-restart-$host-$run_tag.XXXXXX")

finish() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -e "$checkpoint" ] || [ -L "$checkpoint" ]; then
        if [ -f "$checkpoint" ] && [ ! -L "$checkpoint" ] &&
           [ "$(stat -c %u -- "$checkpoint")" = "$uid" ]; then
            current=$(stat -c '%d:%i:%u:%a:%s' -- "$checkpoint")
            if [ -z "$checkpoint_identity" ] || [ "$current" = "$checkpoint_identity" ]; then
                unlink -- "$checkpoint" || cleanup_failed=1
            else
                cleanup_failed=1
            fi
        else
            cleanup_failed=1
        fi
    fi
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

actual_arch=$(uname -m)
case $host in ri|al) expected_arch=aarch64 ;; *) expected_arch=x86_64 ;; esac
[ "$actual_arch" = "$expected_arch" ] || exit 2
case $host in
    local|ri|al|rc) [ -n "${SLURM_JOB_ID:-}" ] ;;
    ab|ab2) [ -n "${PBS_JOBID:-}" ] ;;
    t4) [ -n "${JOB_ID:-}" ] ;;
esac

: "${CXX:=c++}"
printf 'GATE host=%s kind=checkpoint-restart-v1 run=%s\n' "$host" "$run_tag"
printf 'ARCH %s\n' "$actual_arch"
printf 'CXX %s\n' "$("$CXX" --version | sed -n '1p')"
printf '%s\n' 'NATIVE $CXX -std=c++20 -O2 tests/smoke/checkpoint_restart.cpp'
"$CXX" -std=c++20 -O2 -Wall -Wextra -Werror \
    "$root/tests/smoke/checkpoint_restart.cpp" -o "$build/checkpoint_restart"

total=1000000
stop=400000
reference=$("$build/checkpoint_restart" reference "$total")
[ "$reference" = 'FINAL step=1000000 state=0x7f7cadf8669fc055' ] || exit 2
"$build/checkpoint_restart" checkpoint "$checkpoint" "$stop"
checkpoint_identity=$(stat -c '%d:%i:%u:%a:%s' -- "$checkpoint")
case $checkpoint_identity in *:600:40) ;; *) exit 2 ;; esac
resumed=$("$build/checkpoint_restart" resume "$checkpoint" "$stop" "$total")
[ "$reference" = "$resumed" ] || exit 2
printf '%s\n' "$resumed"
unlink -- "$checkpoint"
checkpoint_identity=
[ ! -e "$checkpoint" ] && [ ! -L "$checkpoint" ] || exit 2
printf 'PASS host=%s gate=checkpoint-restart-v1 run=%s processes=2 cleanup=exact\n' \
    "$host" "$run_tag"
