#!/bin/bash -l
set -eu

case ${HARNESS_LOGICAL_HOST:-} in
    local|ab|ab2|ri|al|rc|t4) host=$HARNESS_LOGICAL_HOST ;;
    *) printf '%s\n' 'cpu-readiness: invalid HARNESS_LOGICAL_HOST' >&2; exit 2 ;;
esac

if [ "$host" = al ] && [ "${T200_IN_UENV:-0}" != 1 ]; then
    T200_IN_UENV=1
    export T200_IN_UENV
    exec uenv run prgenv-gnu/25.11:v1 --view=default -- "$0"
fi

root=$HOME/harness
smoke=$root/tests/smoke
state_root=$HOME/.local/state/harness/hpc-readiness
result=$state_root/t200-cpu-$host.out
scratch=${SLURM_TMPDIR:-${TMPDIR:-/tmp}}
build=
capture=
published=0

mkdir -p -- "$state_root"
chmod 700 "$state_root"
[ ! -e "$result" ] && [ ! -L "$result" ] || {
    printf 'cpu-readiness: result already exists: %s\n' "$result" >&2
    exit 2
}
capture=$(mktemp "$state_root/.t200-cpu-$host.XXXXXX")
chmod 600 "$capture"
if ! build=$(mktemp -d "$scratch/t200-cpu-$host.XXXXXX"); then
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

printf 'GATE host=%s kind=cpu-readiness-v1\n' "$host"
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
printf 'CPUS %s\n' "$(getconf _NPROCESSORS_ONLN)"

case $host in
    ab|ab2)
        printf '%s\n' 'NATIVE module load gcc/15.2.0'
        module load gcc/15.2.0
        ;;
    al)
        printf '%s\n' 'ENV uenv=prgenv-gnu/25.11:v1 view=default'
        ;;
    t4)
        printf '%s\n' 'NATIVE module load gcc/14.2.0'
        module load gcc/14.2.0
        ;;
esac

printf 'CC %s\n' "$(cc --version | sed -n '1p')"
printf 'CXX %s\n' "$(c++ --version | sed -n '1p')"
printf 'FORTRAN %s\n' "$(gfortran --version | sed -n '1p')"
printf 'CMAKE %s\n' "$(cmake --version | sed -n '1p')"
printf 'NINJA %s\n' "$(ninja --version | sed -n '1p')"
printf 'PYTHON %s\n' "$(python3 --version)"

printf '%s\n' 'NATIVE cmake -S tests/smoke -B BUILD/cmake -G Ninja'
cmake -S "$smoke" -B "$build/cmake" -G Ninja
printf '%s\n' 'NATIVE cmake --build BUILD/cmake'
cmake --build "$build/cmake"
printf '%s\n' 'NATIVE ctest --test-dir BUILD/cmake --output-on-failure'
ctest --test-dir "$build/cmake" --output-on-failure

printf '%s\n' 'NATIVE c++ -std=c++20 -O2 tests/smoke/cpp20.cpp -o BUILD/cpp20'
c++ -std=c++20 -O2 "$smoke/cpp20.cpp" -o "$build/cpp20"
"$build/cpp20"

printf '%s\n' 'NATIVE python3 tests/smoke/python.py'
python3 "$smoke/python.py"

case $host in
    rc)
        printf '%s\n' 'SKIP sanitizer: declared RC base-toolchain runtime gap'
        ;;
    ab|ab2)
        printf '%s\n' 'NATIVE cc -fsanitize=address,undefined (ASAN_OPTIONS=detect_leaks=0)'
        cc -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer \
            "$smoke/sanitizer.c" -o "$build/sanitizer"
        ASAN_OPTIONS=detect_leaks=0 "$build/sanitizer"
        ;;
    *)
        printf '%s\n' 'NATIVE cc -fsanitize=address,undefined tests/smoke/sanitizer.c'
        cc -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer \
            "$smoke/sanitizer.c" -o "$build/sanitizer"
        "$build/sanitizer"
        ;;
esac

printf 'PASS host=%s gate=cpu-readiness-v1\n' "$host"
