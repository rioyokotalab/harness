#!/bin/sh
set -eu
platform=$(uname -s)
state_metadata() {
    case "$platform" in Darwin) stat -f '%Lp %u' "$1" ;; *) stat -c '%a %u' -- "$1" ;; esac
}

case ${HARNESS_LOGICAL_HOST:-} in
    local|ab|ab2|ri|al|rc|t4) host=$HARNESS_LOGICAL_HOST ;;
    *) printf '%s\n' 'hpc-job-preflight: invalid HARNESS_LOGICAL_HOST' >&2; exit 2 ;;
esac
[ "$#" -eq 3 ] || {
    printf '%s\n' 'Usage: hpc-job-preflight.sh JOB_NAME RESULT_BASENAME TEMP_PREFIX' >&2
    exit 2
}
job_name=$1
result_name=$2
temp_prefix=$3
case $job_name in ''|*[!A-Za-z0-9._-]*) printf '%s\n' 'hpc-job-preflight: unsafe job name' >&2; exit 2 ;; esac
case $result_name in ''|*[!A-Za-z0-9._-]*) printf '%s\n' 'hpc-job-preflight: unsafe result basename' >&2; exit 2 ;; esac
case $result_name in t[0-9][0-9][0-9]-*.out) ;; *) printf '%s\n' 'hpc-job-preflight: unsafe result basename' >&2; exit 2 ;; esac
case $temp_prefix in ''|*[!A-Za-z0-9._-]*) printf '%s\n' 'hpc-job-preflight: unsafe temporary prefix' >&2; exit 2 ;; esac
case $temp_prefix in .t[0-9][0-9][0-9]-*) ;; *) printf '%s\n' 'hpc-job-preflight: unsafe temporary prefix' >&2; exit 2 ;; esac
[ "${#job_name}" -le 32 ] && [ "${#result_name}" -le 96 ] && [ "${#temp_prefix}" -le 96 ] || {
    printf '%s\n' 'hpc-job-preflight: input is too long' >&2
    exit 2
}

state=$HOME/.local/state/harness/hpc-readiness
result=$state/$result_name
result_state=absent
temporary=0
if [ -e "$state" ] || [ -L "$state" ]; then
    [ -d "$state" ] && [ ! -L "$state" ] || {
        printf '%s\n' 'hpc-job-preflight: invalid state directory' >&2
        exit 1
    }
    owner=$(id -u)
    IFS=' ' read -r mode state_owner <<EOF
$(state_metadata "$state")
EOF
    [ "$mode" = 700 ] && [ "$state_owner" = "$owner" ] || {
        printf '%s\n' 'hpc-job-preflight: unsafe state directory metadata' >&2
        exit 1
    }
    if [ -e "$result" ] || [ -L "$result" ]; then result_state=present; fi
    for path in "$state/$temp_prefix".*; do
        [ -e "$path" ] || [ -L "$path" ] || continue
        temporary=$((temporary + 1))
    done
fi

user=$(id -un)
case $user in ''|*[!A-Za-z0-9._-]*) printf '%s\n' 'hpc-job-preflight: unsafe account name' >&2; exit 2 ;; esac
jobs=0
case $host in
    local|ri|al|rc)
        printf 'NATIVE squeue -h -u %s -n %s -o %%i|%%.100j|%%.100u\n' "$user" "$job_name"
        if ! scheduler_output=$(squeue -h -u "$user" -n "$job_name" -o '%i|%.100j|%.100u'); then
            printf '%s\n' 'hpc-job-preflight: native Slurm query failed' >&2
            exit 1
        fi
        if ! jobs=$(printf '%s\n' "$scheduler_output" | awk -F '|' -v name="$job_name" -v user="$user" '
            NF == 0 { next }
            {
                for (field = 1; field <= NF; field++) {
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $field)
                }
            }
            NF != 3 || $1 !~ /^[0-9]+([_.+][0-9]+)*$/ || $2 != name || $3 != user { exit 2 }
            { count++ }
            END { if (!failed) print count + 0 }
        '); then
            printf '%s\n' 'hpc-job-preflight: malformed Slurm query output' >&2
            exit 1
        fi
        ;;
    ab|ab2)
        printf 'NATIVE qselect -u %s -N %s\n' "$user" "$job_name"
        if ! scheduler_output=$(qselect -u "$user" -N "$job_name"); then
            printf '%s\n' 'hpc-job-preflight: native PBS query failed' >&2
            exit 1
        fi
        if ! jobs=$(printf '%s\n' "$scheduler_output" | awk '
            NF == 0 { next }
            NF != 1 || $1 !~ /^[0-9]+([.][A-Za-z0-9._-]+)?$/ { exit 2 }
            { count++ }
            END { print count + 0 }
        '); then
            printf '%s\n' 'hpc-job-preflight: malformed PBS query output' >&2
            exit 1
        fi
        ;;
    t4)
        printf 'NATIVE qstat -u %s (exact name/user filter)\n' "$user"
        if ! scheduler_output=$(qstat -u "$user"); then
            printf '%s\n' 'hpc-job-preflight: native AGE query failed' >&2
            exit 1
        fi
        header=$(printf '%s\n' "$scheduler_output" | sed -n '1p')
        case $header in
            *job-ID*name*user*state*) ;;
            *) printf '%s\n' 'hpc-job-preflight: unrecognized AGE query header' >&2; exit 1 ;;
        esac
        jobs=$(printf '%s\n' "$scheduler_output" | awk -v name="$job_name" -v user="$user" '
            NR <= 2 { next }
            NF >= 5 && $3 == name && $4 == user { count++ }
            END { print count + 0 }
        ')
        ;;
esac
case $jobs in ''|*[!0-9]*) printf '%s\n' 'hpc-job-preflight: invalid job count' >&2; exit 1 ;; esac

if [ "$result_state" = absent ] && [ "$temporary" -eq 0 ] && [ "$jobs" -eq 0 ]; then
    status=pass
    code=0
else
    status=fail
    code=1
fi
printf 'HPC_JOB_PREFLIGHT host=%s job=%s result=%s jobs=%s temporary=%s status=%s\n' \
    "$host" "$job_name" "$result_state" "$jobs" "$temporary" "$status"
exit "$code"
