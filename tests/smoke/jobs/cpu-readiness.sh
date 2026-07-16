#!/bin/bash -l
set -eu

case ${HARNESS_LOGICAL_HOST:-} in
    local|ab|ab2|ri|al|rc|t4) host=$HARNESS_LOGICAL_HOST ;;
    *) printf '%s\n' 'cpu-readiness: invalid HARNESS_LOGICAL_HOST' >&2; exit 2 ;;
esac

gate=cpu-readiness-v2
run_tag=${HARNESS_READINESS_RUN_TAG:-v2}
case $run_tag in
    ''|*[!A-Za-z0-9._-]*)
        printf '%s\n' 'cpu-readiness: invalid HARNESS_READINESS_RUN_TAG' >&2
        exit 2
        ;;
esac
[ "${#run_tag}" -le 32 ] || {
    printf '%s\n' 'cpu-readiness: HARNESS_READINESS_RUN_TAG is too long' >&2
    exit 2
}

# Scheduler entry may require a login shell to expose site environment tools,
# but the test body and its EXIT trap must not inherit site login-shell defects.
if [ "${T200_ENV_READY:-0}" != 1 ]; then
    case $host in
        ab|ab2)
            module load gcc/15.2.0
            CC=$(command -v gcc)
            CXX=$(command -v g++)
            FC=$(command -v gfortran)
            export CC CXX FC
            ;;
        al)
            export T200_ENV_READY=1
            exec uenv run prgenv-gnu/25.11:v1 --view=default -- \
                env T200_ENV_READY=1 /bin/bash "$0"
            ;;
        t4)
            module load gcc/14.2.0
            CC=$(command -v gcc)
            CXX=$(command -v g++)
            FC=$(command -v gfortran)
            export CC CXX FC
            ;;
    esac
    export T200_ENV_READY=1
    exec /bin/bash "$0"
fi

root=$HOME/harness
smoke=$root/tests/smoke
state_root=$HOME/.local/state/harness/hpc-readiness
result=$state_root/t200-cpu-$host-$run_tag.out
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
capture=$(mktemp "$state_root/.t200-cpu-$host-$run_tag.XXXXXX")
chmod 600 "$capture"
if ! build=$(mktemp -d "$scratch/t200-cpu-$host-$run_tag.XXXXXX"); then
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
printf 'CPUS %s\n' "$(getconf _NPROCESSORS_ONLN)"

case $host in
    ab|ab2)
        printf '%s\n' 'ENV module=gcc/15.2.0'
        ;;
    al)
        printf '%s\n' 'ENV uenv=prgenv-gnu/25.11:v1 view=default'
        ;;
    t4)
        printf '%s\n' 'ENV module=gcc/14.2.0'
        ;;
esac

: "${CC:=cc}" "${CXX:=c++}" "${FC:=gfortran}"
export CC CXX FC
printf 'CC_COMMAND %s\n' "$(command -v "$CC")"
printf 'CXX_COMMAND %s\n' "$(command -v "$CXX")"
printf 'FC_COMMAND %s\n' "$(command -v "$FC")"
printf 'CC %s\n' "$("$CC" --version | sed -n '1p')"
printf 'CXX %s\n' "$("$CXX" --version | sed -n '1p')"
printf 'FORTRAN %s\n' "$("$FC" --version | sed -n '1p')"
printf 'CMAKE %s\n' "$(cmake --version | sed -n '1p')"
printf 'NINJA %s\n' "$(ninja --version | sed -n '1p')"
printf 'PYTHON %s\n' "$(python3 --version)"

printf '%s\n' 'NATIVE cmake -S tests/smoke -B BUILD/cmake -G Ninja'
cmake -S "$smoke" -B "$build/cmake" -G Ninja
printf '%s\n' 'NATIVE cmake --build BUILD/cmake'
cmake --build "$build/cmake"
printf '%s\n' 'NATIVE ctest --test-dir BUILD/cmake --output-on-failure'
ctest --test-dir "$build/cmake" --output-on-failure

printf '%s\n' 'NATIVE $CXX -std=c++20 -O2 tests/smoke/cpp20.cpp -o BUILD/cpp20'
"$CXX" -std=c++20 -O2 "$smoke/cpp20.cpp" -o "$build/cpp20"
"$build/cpp20"

printf '%s\n' 'NATIVE python3 tests/smoke/python.py'
python3 "$smoke/python.py"

case $host in
    rc)
        printf '%s\n' 'SKIP sanitizer: declared RC base-toolchain runtime gap'
        ;;
    ab|ab2)
        printf '%s\n' 'NATIVE $CC -fsanitize=address,undefined (ASAN_OPTIONS=detect_leaks=0)'
        "$CC" -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer \
            "$smoke/sanitizer.c" -o "$build/sanitizer"
        ASAN_OPTIONS=detect_leaks=0 "$build/sanitizer"
        ;;
    *)
        printf '%s\n' 'NATIVE $CC -fsanitize=address,undefined tests/smoke/sanitizer.c'
        "$CC" -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer \
            "$smoke/sanitizer.c" -o "$build/sanitizer"
        "$build/sanitizer"
        ;;
esac

printf 'PASS host=%s gate=%s run=%s\n' "$host" "$gate" "$run_tag"
