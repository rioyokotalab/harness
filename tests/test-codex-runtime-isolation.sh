#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/harness-codex-runtime-test.XXXXXX")
harness_pid=
students_pid=
swallow_pid=
harness_release=
students_release=
swallow_release=

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

file_mode() {
    case $(uname -s) in
        Darwin) stat -f '%Lp' "$1" ;;
        *) stat -c '%a' "$1" ;;
    esac
}

stop_process() {
    process_pid=$1
    case "$process_pid" in ''|*[!0-9]*) return ;; esac
    : >"$TEST_ROOT/stop-launchers"
    set +e
    wait "$process_pid" 2>/dev/null
    set -e
}

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    stop_process "$swallow_pid"
    stop_process "$students_pid"
    stop_process "$harness_pid"
    for runtime_release in \
        "$harness_release" "$students_release" "$swallow_release"
    do
        if [ -n "$runtime_release" ] && [ -d "$runtime_release" ] &&
            [ ! -L "$runtime_release" ]; then
            chmod 700 "$runtime_release" \
                "$runtime_release/libexec" "$runtime_release/profiles" ||
                status=1
        fi
    done
    cleanup_failed=0
    if [ -d "$TEST_ROOT" ]; then
        "$CLEANUP" "$HARNESS" "$TEMP_BASE" "$TEST_ROOT" "$TEMP_BASE" \
            >/dev/null || cleanup_failed=1
    fi
    [ "$status" -ne 0 ] || [ "$cleanup_failed" -eq 0 ] || status=1
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

[ "$(grep -c '^python3 "\$ROOT/tools/run-focused-tests.py"' \
    "$ROOT/tests/test-phase1.sh")" = 1 ] ||
    fail "phase-1 retains divergent focused-suite execution"
grep -F 'legacy) focused_jobs=1' "$ROOT/tests/test-phase1.sh" >/dev/null ||
    fail "legacy compatibility does not select the normal manifest serially"
[ "$(grep -c '^tests/test-codex-targets.sh|' \
    "$ROOT/tests/focused-suites.tsv")" = 1 ] ||
    fail "Codex target suite is not in the normal manifest exactly once"
[ "$(grep -c '^tests/test-codex-runtime-isolation.sh|' \
    "$ROOT/tests/focused-suites.tsv")" = 1 ] ||
    fail "Codex runtime suite is not in the normal manifest exactly once"

control=$TEST_ROOT/control
release_root=$TEST_ROOT/private-control
runtime=$TEST_ROOT/runtime
capture=$TEST_ROOT/capture
target_harness=$TEST_ROOT/target-harness
target_students=$TEST_ROOT/target-students
target_swallow=$TEST_ROOT/target-swallow
mkdir -m 700 "$control" "$release_root" "$runtime" "$capture"
mkdir "$control/libexec" "$control/profiles"

for repository in "$target_harness" "$target_students" "$target_swallow"; do
    mkdir -p "$repository/.codex"
    git -C "$repository" init -q -b main
    printf '%s\n' 'model = "gpt-5.6-sol"' \
        'model_reasoning_effort = "high"' \
        >"$repository/.codex/config.toml"
done

for path in \
    libexec/harness-common \
    libexec/harness-codex-resilient \
    libexec/harness-codex-runtime-launch \
    libexec/harness-codex-runtime-release \
    libexec/harness-codex-thread-recovery \
    libexec/harness_codex_targets.py \
    profiles/codex-runtime-release.tsv
do
    cp "$ROOT/$path" "$control/$path"
done
printf '# target\tindex\tcanonical_repository\n' \
    >"$control/profiles/codex-session-targets.tsv"
printf 'harness\t0\t%s\n' "$target_harness" \
    >>"$control/profiles/codex-session-targets.tsv"
printf 'students\t1\t%s\n' "$target_students" \
    >>"$control/profiles/codex-session-targets.tsv"
printf 'swallow\t2\t%s\n' "$target_swallow" \
    >>"$control/profiles/codex-session-targets.tsv"
chmod 755 "$control"/libexec/*
chmod 644 "$control"/profiles/*
git -C "$control" init -q -b main
git -C "$control" config user.name 'Harness Runtime Test'
git -C "$control" config user.email 'harness-runtime@example.invalid'
git -C "$control" add libexec profiles
git -C "$control" commit -q -m 'runtime fixture'
commit=$(git -C "$control" rev-parse HEAD)

fake_launcher=$TEST_ROOT/fake-launcher
cat >"$fake_launcher" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$$" >"$FAKE_LAUNCH_PID_FILE"
while [ ! -e "$FAKE_STOP_FILE" ]; do
    /bin/sleep 0.05
done
EOF
chmod 700 "$fake_launcher"

launch_supervisor() {
    repository=$1
    target=$2
    output=$3
    (
        cd "$repository"
        exec env \
            HARNESS_TESTING=1 \
            HARNESS_TEST_FORCE_CODEX_RELEASE=1 \
            HARNESS_TEST_CODEX_RELEASE_ROOT="$release_root" \
            HARNESS_TEST_RUNTIME_DIR="$runtime" \
            HARNESS_TEST_CODEX_LAUNCHER="$fake_launcher" \
            FAKE_LAUNCH_PID_FILE="$TEST_ROOT/$target.launcher.pid" \
            FAKE_STOP_FILE="$TEST_ROOT/stop-launchers" \
            "$control/libexec/harness-codex-resilient" \
                --run --target "$target" --name shared --last
    ) >"$output" 2>&1 &
    launched_pid=$!
}

wait_for_file() {
    path=$1
    process_pid=$2
    attempts=0
    while [ "$attempts" -lt 100 ]; do
        [ -f "$path" ] && return 0
        kill -0 "$process_pid" 2>/dev/null ||
            fail "runtime supervisor exited before readiness"
        /bin/sleep 0.05
        attempts=$((attempts + 1))
    done
    fail "runtime supervisor readiness timed out"
}

harness_release=$release_root/releases/harness/$commit
launch_supervisor "$target_harness" harness "$TEST_ROOT/harness.out"
harness_pid=$launched_pid
wait_for_file "$runtime/harness/shared.state" "$harness_pid"
[ -f "$harness_release/.codex-runtime-release" ] ||
    fail "commit-addressed runtime release was not created"
grep -F "commit=$commit" "$harness_release/.codex-runtime-release" >/dev/null ||
    fail "runtime release marker lost commit identity"
grep -F 'target=harness' "$harness_release/.codex-runtime-release" >/dev/null ||
    fail "runtime release marker lost target identity"
[ "$(file_mode "$harness_release")" = 500 ] &&
    [ "$(file_mode "$harness_release/.codex-runtime-release")" = 400 ] &&
    [ "$(file_mode \
        "$harness_release/libexec/harness-codex-resilient")" = 555 ] ||
    fail "runtime release is not read-only"
grep -F 'target=harness' "$runtime/harness/shared.state" >/dev/null ||
    fail "Harness supervisor state lost target identity"
[ -d "$runtime/harness/shared.lock" ] ||
    fail "Harness target lock is absent"

case $(uname -s) in
    Linux) command_line=$(tr '\000' '\n' <"/proc/$harness_pid/cmdline") ;;
    *) command_line=$(ps -o command= -p "$harness_pid") ;;
esac
printf '%s\n' "$command_line" |
    grep -F "$harness_release/libexec/harness-codex-resilient" >/dev/null ||
    fail "supervisor did not re-exec from its immutable release"
if printf '%s\n' "$command_line" |
    grep -F "$control/libexec/harness-codex-resilient" >/dev/null; then
    fail "supervisor command line retains the tracked control script"
fi
if [ "$(uname -s)" = Linux ]; then
    for descriptor in /proc/"$harness_pid"/fd/*; do
        destination=$(readlink "$descriptor" 2>/dev/null || true)
        case "$destination" in
            "$control"/*)
                fail "supervisor retained a tracked-checkout descriptor"
                ;;
        esac
    done
fi

students_release=$release_root/releases/students/$commit
launch_supervisor "$target_students" students "$TEST_ROOT/students.out"
students_pid=$launched_pid
wait_for_file "$runtime/students/shared.state" "$students_pid"
[ -f "$students_release/.codex-runtime-release" ] ||
    fail "Students target-scoped runtime release was not created"
grep -F 'target=students' "$runtime/students/shared.state" >/dev/null ||
    fail "Students supervisor state lost target identity"
[ -d "$runtime/students/shared.lock" ] ||
    fail "Students target lock is absent"
[ -d "$runtime/harness/shared.lock" ] ||
    fail "same-name Students supervisor interfered with Harness lock"

swallow_release=$release_root/releases/swallow/$commit
launch_supervisor "$target_swallow" swallow "$TEST_ROOT/swallow.out"
swallow_pid=$launched_pid
wait_for_file "$runtime/swallow/shared.state" "$swallow_pid"
[ -f "$swallow_release/.codex-runtime-release" ] ||
    fail "Swallow target-scoped runtime release was not created"
grep -F 'target=swallow' "$runtime/swallow/shared.state" >/dev/null ||
    fail "Swallow supervisor state lost target identity"
[ -d "$runtime/swallow/shared.lock" ] ||
    fail "Swallow target lock is absent"
[ -d "$runtime/harness/shared.lock" ] &&
    [ -d "$runtime/students/shared.lock" ] ||
    fail "same-name Swallow supervisor interfered with another target lock"

status_output=$(
    HARNESS_CONTROL_ROOT="$harness_release" \
    HARNESS_TARGET_ROOT="$target_harness" \
    HARNESS_CODEX_RELEASE_COMMIT="$commit" \
    HARNESS_CODEX_RELEASE_TARGET=harness \
    HARNESS_TESTING=1 \
    HARNESS_TEST_RUNTIME_DIR="$runtime" \
        "$harness_release/libexec/harness-codex-resilient" \
            --status --target harness --name shared
)
printf '%s\n' "$status_output" |
    grep -F 'target=harness phase=running' >/dev/null ||
    fail "Harness target status is not independently addressable"
status_output=$(
    HARNESS_CONTROL_ROOT="$students_release" \
    HARNESS_TARGET_ROOT="$target_harness" \
    HARNESS_CODEX_RELEASE_COMMIT="$commit" \
    HARNESS_CODEX_RELEASE_TARGET=students \
    HARNESS_TESTING=1 \
    HARNESS_TEST_RUNTIME_DIR="$runtime" \
        "$students_release/libexec/harness-codex-resilient" \
            --status --target students --name shared
)
printf '%s\n' "$status_output" |
    grep -F 'target=students phase=running' >/dev/null ||
    fail "Students target status is not independently addressable"
if HARNESS_CONTROL_ROOT="$harness_release" \
    HARNESS_TARGET_ROOT="$target_harness" \
    HARNESS_CODEX_RELEASE_COMMIT="$commit" \
    HARNESS_CODEX_RELEASE_TARGET=harness \
    HARNESS_TESTING=1 \
    HARNESS_TEST_RUNTIME_DIR="$runtime" \
        "$harness_release/libexec/harness-codex-resilient" \
            --status --name shared >"$TEST_ROOT/ambiguous.out" 2>&1; then
    fail "same-name cross-target status was accepted without a target"
fi
grep -F 'status requires --target' "$TEST_ROOT/ambiguous.out" >/dev/null ||
    fail "cross-target status ambiguity was not classified"

fake_native=$TEST_ROOT/fake-native-codex
cat >"$fake_native" <<'EOF'
#!/bin/sh
set -eu

printf '%s\n' executed >"$CODEX_LAUNCH_CAPTURE/native-executed"
leaked=$(
    env | sed -n \
        -e 's/^\(HARNESS_ROOT\)=.*/\1/p' \
        -e 's/^\(HARNESS_CONTROL_ROOT\)=.*/\1/p' \
        -e 's/^\(HARNESS_TARGET_ROOT\)=.*/\1/p' \
        -e 's/^\(HARNESS_CODEX_RELEASE_[A-Z0-9_]*\)=.*/\1/p' \
        -e 's/^\(HARNESS_TEST[A-Z0-9_]*\)=.*/\1/p' |
        sed -n '1p'
)
if [ -n "$leaked" ]; then
    printf 'leaked=%s\n' "$leaked" >"$CODEX_LAUNCH_CAPTURE/native-leak"
    exit 9
fi
case $(uname -s) in
    Linux)
        [ "${RAYON_NUM_THREADS:-}" = 8 ] || exit 10
        [ "${TOKIO_WORKER_THREADS:-}" = 8 ] || exit 11
        ;;
esac
[ "$(pwd -P)" = "$CODEX_EXPECTED_REPOSITORY" ] || exit 12
grep -F -x 'model = "gpt-5.6-sol"' .codex/config.toml >/dev/null ||
    exit 13
grep -F -x 'model_reasoning_effort = "high"' .codex/config.toml \
    >/dev/null || exit 14
printf '%s\n' "$*" >"$CODEX_LAUNCH_CAPTURE/native-arguments"
printf '%s\n' sanitized >"$CODEX_LAUNCH_CAPTURE/native-environment"
EOF
chmod 700 "$fake_native"

run_released_launcher() {
    released_target=$1
    released_root=$2
    released_repository=$3
    released_capture=$capture/valid-$released_target
    mkdir "$released_capture"
    (
        cd "$released_repository"
        env \
            HARNESS_ROOT="$TEST_ROOT/ambient-root" \
            HARNESS_CONTROL_ROOT="$released_root" \
            HARNESS_TARGET_ROOT="$target_harness" \
            HARNESS_CODEX_RELEASE_COMMIT="$commit" \
            HARNESS_CODEX_RELEASE_FUTURE=ambient-release \
            HARNESS_CODEX_RELEASE_TARGET="$released_target" \
            HARNESS_TESTING=1 \
            HARNESS_TEST_CODEX_RELEASE_ROOT="$release_root" \
            HARNESS_TEST_FORCE_CODEX_RELEASE=1 \
            HARNESS_TEST_NATIVE_CODEX="$fake_native" \
            HARNESS_TEST_FUTURE_VARIABLE=ambient-test \
            CODEX_LAUNCH_CAPTURE="$released_capture" \
            CODEX_EXPECTED_REPOSITORY="$released_repository" \
            "$released_root/libexec/harness-codex-runtime-launch" \
                resume --last
    )
    [ -f "$released_capture/native-environment" ] ||
        fail "$released_target native Codex environment was not checked"
    [ ! -e "$released_capture/native-leak" ] ||
        fail "$released_target native Codex inherited Harness state"
    grep -F -- '--sandbox danger-full-access resume --last' \
        "$released_capture/native-arguments" >/dev/null ||
        fail "$released_target runtime launcher changed native arguments"
}

run_released_launcher harness "$harness_release" "$target_harness"
run_released_launcher students "$students_release" "$target_students"
run_released_launcher swallow "$swallow_release" "$target_swallow"

assert_wrong_release_repository() {
    wrong_release_target=$1
    wrong_release_root=$2
    wrong_repository_target=$3
    wrong_repository=$4
    wrong_capture=$capture/wrong-$wrong_release_target-$wrong_repository_target
    mkdir "$wrong_capture"
    if (
        cd "$wrong_repository"
        env \
            HARNESS_CONTROL_ROOT="$wrong_release_root" \
            HARNESS_TARGET_ROOT="$target_harness" \
            HARNESS_CODEX_RELEASE_COMMIT="$commit" \
            HARNESS_CODEX_RELEASE_TARGET="$wrong_release_target" \
            HARNESS_TESTING=1 \
            HARNESS_TEST_NATIVE_CODEX="$fake_native" \
            CODEX_LAUNCH_CAPTURE="$wrong_capture" \
            CODEX_EXPECTED_REPOSITORY="$wrong_repository" \
            "$wrong_release_root/libexec/harness-codex-runtime-launch" \
                --probe wrong-target
    ) >"$TEST_ROOT/wrong-$wrong_release_target-$wrong_repository_target.out" \
        2>&1; then
        fail "$wrong_release_target release accepted $wrong_repository_target"
    fi
    grep -F 'released runtime target does not match current repository' \
        "$TEST_ROOT/wrong-$wrong_release_target-$wrong_repository_target.out" \
        >/dev/null ||
        fail "$wrong_release_target release mismatch was not classified"
    [ ! -e "$wrong_capture/native-executed" ] ||
        fail "$wrong_release_target release reached native Codex from $wrong_repository_target"
}

assert_wrong_release_repository \
    harness "$harness_release" students "$target_students"
assert_wrong_release_repository \
    harness "$harness_release" swallow "$target_swallow"
assert_wrong_release_repository \
    students "$students_release" harness "$target_harness"
assert_wrong_release_repository \
    students "$students_release" swallow "$target_swallow"
assert_wrong_release_repository \
    swallow "$swallow_release" harness "$target_harness"
assert_wrong_release_repository \
    swallow "$swallow_release" students "$target_students"

invalid_capture=$capture/invalid-release-target
mkdir "$invalid_capture"
if (
    cd "$target_harness"
    env \
        HARNESS_CONTROL_ROOT="$harness_release" \
        HARNESS_TARGET_ROOT="$target_harness" \
        HARNESS_CODEX_RELEASE_COMMIT="$commit" \
        HARNESS_CODEX_RELEASE_TARGET=invalid \
        HARNESS_TESTING=1 \
        HARNESS_TEST_NATIVE_CODEX="$fake_native" \
        CODEX_LAUNCH_CAPTURE="$invalid_capture" \
        CODEX_EXPECTED_REPOSITORY="$target_harness" \
        "$harness_release/libexec/harness-codex-runtime-launch" --probe
) >"$TEST_ROOT/invalid-release-target.out" 2>&1; then
    fail "released runtime launcher accepted an invalid target"
fi
grep -F 'released runtime target is invalid' \
    "$TEST_ROOT/invalid-release-target.out" >/dev/null ||
    fail "invalid released runtime target was not classified"
[ ! -e "$invalid_capture/native-executed" ] ||
    fail "invalid released runtime target reached native Codex"

missing_capture=$capture/missing-release-target
mkdir "$missing_capture"
if (
    cd "$target_harness"
    env -u HARNESS_CODEX_RELEASE_TARGET \
        HARNESS_CONTROL_ROOT="$harness_release" \
        HARNESS_TARGET_ROOT="$target_harness" \
        HARNESS_CODEX_RELEASE_COMMIT="$commit" \
        HARNESS_TESTING=1 \
        HARNESS_TEST_NATIVE_CODEX="$fake_native" \
        CODEX_LAUNCH_CAPTURE="$missing_capture" \
        CODEX_EXPECTED_REPOSITORY="$target_harness" \
        "$harness_release/libexec/harness-codex-runtime-launch" --probe
) >"$TEST_ROOT/missing-release-target.out" 2>&1; then
    fail "released runtime launcher accepted a missing target"
fi
grep -F 'released runtime target is invalid' \
    "$TEST_ROOT/missing-release-target.out" >/dev/null ||
    fail "missing released runtime target was not classified"
[ ! -e "$missing_capture/native-executed" ] ||
    fail "missing released runtime target reached native Codex"

stop_process "$swallow_pid"
swallow_pid=
stop_process "$students_pid"
students_pid=
stop_process "$harness_pid"
harness_pid=

fake_once=$TEST_ROOT/fake-once-launcher
cat >"$fake_once" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$*" >"$HARNESS_TEST_CAPTURE/release-forwarding"
EOF
chmod 700 "$fake_once"
fake_thread_check=$TEST_ROOT/fake-thread-check
cat >"$fake_thread_check" <<'EOF'
#!/bin/sh
set -eu
[ "$1" = --check ]
printf '%s\n' "$*" >"$HARNESS_TEST_CAPTURE/thread-check"
EOF
chmod 700 "$fake_thread_check"
(
    cd "$target_students"
    HARNESS_TESTING=1 \
    HARNESS_TEST_FORCE_CODEX_RELEASE=1 \
    HARNESS_TEST_CODEX_RELEASE_ROOT="$release_root" \
    HARNESS_TEST_RUNTIME_DIR="$runtime" \
    HARNESS_TEST_CODEX_LAUNCHER="$fake_once" \
    HARNESS_TEST_THREAD_RECOVERY="$fake_thread_check" \
    HARNESS_TEST_CAPTURE="$capture" \
        "$control/libexec/harness-codex-resilient" \
            --run --target students --name explicit-forward \
            --session session-explicit
) >"$TEST_ROOT/release-forwarding.out"
[ "$(cat "$capture/release-forwarding")" = 'resume session-explicit' ] ||
    fail "release handoff changed the explicit no-replay selector"
grep -F -- '--target students --thread session-explicit' \
    "$capture/thread-check" >/dev/null ||
    fail "release handoff omitted explicit thread target preflight"

chmod 700 "$harness_release" "$harness_release/libexec"
chmod 755 "$harness_release/libexec/harness-codex-resilient"
printf '%s\n' '# test-only mutation' \
    >>"$harness_release/libexec/harness-codex-resilient"
if (
    cd "$target_harness"
    HARNESS_TESTING=1 \
    HARNESS_TEST_FORCE_CODEX_RELEASE=1 \
    HARNESS_TEST_CODEX_RELEASE_ROOT="$release_root" \
    HARNESS_TEST_RUNTIME_DIR="$runtime" \
    HARNESS_TEST_CODEX_LAUNCHER="$fake_launcher" \
        "$control/libexec/harness-codex-resilient" \
            --run --target harness --name invalid-release --last
) >"$TEST_ROOT/invalid-release.out" 2>&1; then
    fail "mutated immutable release was accepted"
fi
grep -F 'existing Codex runtime release is invalid' \
    "$TEST_ROOT/invalid-release.out" >/dev/null ||
    fail "mutated release did not fail closed"

printf '%s\n' 'PASS: Codex target-scoped immutable runtime'
