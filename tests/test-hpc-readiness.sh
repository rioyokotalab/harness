#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
JOB=$ROOT/tests/smoke/jobs/cpu-readiness.sh
LOCAL=$ROOT/tests/smoke/jobs/local-cpu.slurm

bash -n "$JOB" "$LOCAL"
grep -Fx '#YBATCH -r thrp_1' "$LOCAL" >/dev/null
grep -Fx '#SBATCH --time=00:05:00' "$LOCAL" >/dev/null
grep -F 'uenv run prgenv-gnu/25.11:v1 --view=default' "$JOB" >/dev/null
grep -F 'module load gcc/15.2.0' "$JOB" >/dev/null
grep -F 'module load gcc/14.2.0' "$JOB" >/dev/null
grep -F 'HARNESS_READINESS_RUN_TAG' "$JOB" >/dev/null
grep -F 'exec /bin/bash "$0"' "$JOB" >/dev/null
grep -F 'CC=$(command -v gcc)' "$JOB" >/dev/null
grep -F 'CXX=$(command -v g++)' "$JOB" >/dev/null
grep -F 'FC=$(command -v gfortran)' "$JOB" >/dev/null
grep -F 'export HARNESS_READINESS_RUN_TAG=v2' "$LOCAL" >/dev/null
for source in cpu.c cpu.cpp cpu.f90; do
    grep -F "$source" "$ROOT/tests/smoke/CMakeLists.txt" >/dev/null
done
for source in cpp20.cpp python.py sanitizer.c; do
    grep -F "$source" "$JOB" >/dev/null
done
if grep -E 'rm[[:space:]]+(-[^[:space:]]*)*[rR]|--recursive|rsync[[:space:]].*--delete' \
    "$JOB" "$LOCAL" >/dev/null; then
    printf '%s\n' 'FAIL: unsafe cleanup in readiness job' >&2
    exit 1
fi
if grep -E '(^|[^A-Za-z0-9_])(qsub|sbatch|srun|yrun|ybatch|scancel|qdel)([^A-Za-z0-9_]|$)' \
    "$JOB" >/dev/null; then
    printf '%s\n' 'FAIL: generic readiness job hides scheduler action' >&2
    exit 1
fi
printf '%s\n' 'HPC readiness job tests passed'
