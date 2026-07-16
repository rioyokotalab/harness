#!/bin/bash
set -euo pipefail

case ${HARNESS_LOGICAL_HOST:-} in
    ab|ab2|t4) host=$HARNESS_LOGICAL_HOST ;;
    *) printf '%s\n' 'compute-debugger-readiness: unsupported host' >&2; exit 2 ;;
esac
run_tag=${HARNESS_READINESS_RUN_TAG:-v1}
case $run_tag in
    ''|*[!A-Za-z0-9._-]*)
        printf '%s\n' 'compute-debugger-readiness: invalid run tag' >&2
        exit 2
        ;;
esac
[ "${#run_tag}" -le 32 ] || exit 2
case $host in
    ab|ab2) [ -n "${PBS_JOBID:-}" ] ;;
    t4) [ -n "${JOB_ID:-}" ] ;;
esac

state_root=$HOME/.local/state/harness/hpc-readiness
result=$state_root/t213-debugger-compute-$host-$run_tag.out
mkdir -p -- "$state_root"
chmod 700 "$state_root"
[ ! -e "$result" ] && [ ! -L "$result" ] || {
    printf 'compute-debugger-readiness: result already exists: %s\n' "$result" >&2
    exit 2
}
capture=$(mktemp "$state_root/.t213-debugger-compute-$host-$run_tag.XXXXXX")
chmod 600 "$capture"
published=0
finish() {
    status=$?
    trap - EXIT HUP INT TERM
    if [ -f "$capture" ] && [ ! -L "$capture" ] && [ "$published" -eq 0 ]; then
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

printf 'GATE host=%s kind=compute-debugger-readiness-v1 run=%s\n' "$host" "$run_tag"
HARNESS_LOGICAL_HOST=$host "$HOME/harness/tests/smoke/debugger-readiness.sh"
printf 'PASS host=%s gate=compute-debugger-readiness-v1 run=%s\n' "$host" "$run_tag"
