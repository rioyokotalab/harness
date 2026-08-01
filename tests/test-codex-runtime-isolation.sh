#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/harness-codex-runtime-test.XXXXXX")
harness_pid=
students_pid=
personal_pid=
harness_release=
students_release=
personal_release=
canonical_release=
harness_payload=
students_payload=
personal_payload=

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
    stop_process "$personal_pid"
    stop_process "$students_pid"
    stop_process "$harness_pid"
    for runtime_release in \
        "$harness_release" "$students_release" "$personal_release" \
        "$canonical_release"
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

[ "$(grep -Ec '^[[:space:]]*python3 "\$ROOT/tools/run-focused-tests.py"' \
    "$ROOT/tests/test-phase1.sh")" = 1 ] ||
    fail "phase-1 retains divergent focused-suite execution"
grep -F '        focused_jobs=1' "$ROOT/tests/test-phase1.sh" >/dev/null &&
    grep -F '        overlap_gates=no' "$ROOT/tests/test-phase1.sh" >/dev/null ||
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
git_wrapper_dir=$TEST_ROOT/git-wrapper
git_log=$TEST_ROOT/git.log
target_harness=$TEST_ROOT/target-harness
target_students=$TEST_ROOT/target-students
target_personal=$TEST_ROOT/target-personal
mkdir -m 700 "$control" "$release_root" "$runtime" "$capture" \
    "$git_wrapper_dir"
mkdir "$control/libexec" "$control/profiles"

for repository in "$target_harness" "$target_students" "$target_personal"; do
    mkdir -p "$repository/.codex"
    git -C "$repository" init -q -b main
    printf '%s\n' 'model = "gpt-5.6-sol"' \
        'model_reasoning_effort = "high"' \
        >"$repository/.codex/config.toml"
done
mkdir "$target_harness/nested"

direct_home=$TEST_ROOT/direct-home
direct_capture=$TEST_ROOT/direct-cwd
mkdir -p "$direct_home/.local/bin"
cat >"$direct_home/.local/bin/codex" <<'EOF'
#!/bin/sh
pwd -P >"$DIRECT_CAPTURE"
EOF
chmod 700 "$direct_home/.local/bin/codex"
(
    cd "$ROOT/docs"
    env -u HARNESS_ROOT -u HARNESS_CONTROL_ROOT -u HARNESS_TARGET_ROOT \
        HOME="$direct_home" DIRECT_CAPTURE="$direct_capture" \
            "$ROOT/bin/harness-codex" --version
)
[ "$(cat "$direct_capture")" = "$ROOT" ] ||
    fail "direct Codex launcher retained a repository subdirectory"

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
printf '# target\twindow_index\twindow_name\tpane_index\tcanonical_repository\n' \
    >"$control/profiles/codex-session-targets.tsv"
printf 'harness\t0\tcowork\t0\t%s\n' "$target_harness" \
    >>"$control/profiles/codex-session-targets.tsv"
printf 'personal\t1\tcodex\t0\t%s\n' "$target_personal" \
    >>"$control/profiles/codex-session-targets.tsv"
printf 'students\t1\tcodex\t1\t%s\n' "$target_students" \
    >>"$control/profiles/codex-session-targets.tsv"
chmod 755 "$control"/libexec/*
chmod 644 "$control"/profiles/*
git -C "$control" init -q -b main
git -C "$control" config user.name 'Harness Runtime Test'
git -C "$control" config user.email 'harness-runtime@example.invalid'
git -C "$control" add libexec profiles
git -C "$control" commit -q -m 'runtime fixture'
commit=$(git -C "$control" rev-parse HEAD)
real_git=$(command -v git)

cat >"$git_wrapper_dir/git" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$*" >>"$HARNESS_TEST_GIT_LOG"
exec "$HARNESS_TEST_REAL_GIT" "$@"
EOF
chmod 700 "$git_wrapper_dir/git"

fake_launcher=$TEST_ROOT/fake-launcher
cat >"$fake_launcher" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$$" >"$FAKE_LAUNCH_PID_FILE"
pwd -P >"$FAKE_LAUNCH_CWD_FILE"
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
            PATH="$git_wrapper_dir:$PATH" \
            HARNESS_TESTING=1 \
            HARNESS_TEST_GIT_LOG="$git_log" \
            HARNESS_TEST_REAL_GIT="$real_git" \
            HARNESS_TEST_FORCE_CODEX_RELEASE=1 \
            HARNESS_TEST_CODEX_RELEASE_ROOT="$release_root" \
            HARNESS_TEST_RUNTIME_DIR="$runtime" \
            HARNESS_TEST_CODEX_LAUNCHER="$fake_launcher" \
            FAKE_LAUNCH_PID_FILE="$TEST_ROOT/$target.launcher.pid" \
            FAKE_LAUNCH_CWD_FILE="$TEST_ROOT/$target.launcher.cwd" \
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

release_for_target() {
    release_target=$1
    set -- "$release_root/releases/$release_target"/*
    [ "$#" -eq 1 ] && [ -d "$1" ] && [ ! -L "$1" ] ||
        fail "$release_target does not have one exact immutable release"
    printf '%s\n' "$1"
}

launch_supervisor "$target_harness/nested" harness "$TEST_ROOT/harness.out"
harness_pid=$launched_pid
wait_for_file "$runtime/harness/shared.state" "$harness_pid"
wait_for_file "$TEST_ROOT/harness.launcher.cwd" "$harness_pid"
[ "$(cat "$TEST_ROOT/harness.launcher.cwd")" = "$target_harness" ] ||
    fail "resilient launcher retained a repository subdirectory"
harness_release=$(release_for_target harness)
harness_payload=${harness_release##*/}
[ "$(grep -c ' ls-tree -r ' "$git_log")" -eq 1 ] ||
    fail "runtime payload objects were not resolved in one Git invocation"
[ "$(grep -c ' hash-object -- ' "$git_log")" -eq 1 ] ||
    fail "runtime release files were not hashed in one Git invocation"
awk '
    / ls-tree -r / { if (NF != 13) exit 1; tree = 1 }
    / hash-object -- / { if (NF != 11) exit 1; hashes = 1 }
    END { if (!tree || !hashes) exit 1 }
' "$git_log" ||
    fail "runtime Git batches did not carry exactly seven safe path arguments"
[ -f "$harness_release/.codex-runtime-release" ] ||
    fail "payload-addressed runtime release was not created"
grep -F "payload=$harness_payload" \
    "$harness_release/.codex-runtime-release" >/dev/null ||
    fail "runtime release marker lost payload identity"
grep -F "source_commit=$commit" \
    "$harness_release/.codex-runtime-release" >/dev/null ||
    fail "runtime release marker lost creation provenance"
grep -F 'target=harness' "$harness_release/.codex-runtime-release" >/dev/null ||
    fail "runtime release marker lost target identity"
[ "$harness_payload" != "$commit" ] ||
    fail "runtime release remained keyed by the whole commit"
[ "$(file_mode "$harness_release")" = 500 ] &&
    [ "$(file_mode "$harness_release/.codex-runtime-release")" = 400 ] &&
[ "$(file_mode \
        "$harness_release/libexec/harness-codex-resilient")" = 555 ] ||
    fail "runtime release is not read-only"

canonical_parent=$TEST_ROOT/canonical-parent
canonical_alias=$TEST_ROOT/canonical-alias
canonical_root=$canonical_alias/private-control
mkdir -m 700 "$canonical_parent" "$canonical_parent/private-control"
ln -s "$canonical_parent" "$canonical_alias"
canonical_release=$canonical_parent/private-control/releases/harness/$harness_payload
(
    cd "$target_harness"
    HARNESS_TESTING=1 \
    HARNESS_TEST_CODEX_RELEASE_ROOT="$canonical_root" \
    HARNESS_CODEX_RELEASE_TARGET=harness \
    HARNESS_TARGET_ROOT="$target_harness" \
        "$control/libexec/harness-codex-runtime-release" \
            --exec-resilient --plan --target harness \
            --name canonical-parent --last
) >"$TEST_ROOT/canonical-parent.out"
grep -F 'name=canonical-parent target=harness selector=last status=ready' \
    "$TEST_ROOT/canonical-parent.out" >/dev/null ||
    fail "runtime release did not survive a canonical parent-path change"
[ -d "$canonical_release" ] ||
    fail "runtime release was not created under its canonical parent"

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

launch_supervisor "$target_students" students "$TEST_ROOT/students.out"
students_pid=$launched_pid
wait_for_file "$runtime/students/shared.state" "$students_pid"
students_release=$(release_for_target students)
students_payload=${students_release##*/}
[ -f "$students_release/.codex-runtime-release" ] ||
    fail "Students target-scoped runtime release was not created"
grep -F 'target=students' "$runtime/students/shared.state" >/dev/null ||
    fail "Students supervisor state lost target identity"
[ -d "$runtime/students/shared.lock" ] ||
    fail "Students target lock is absent"
[ -d "$runtime/harness/shared.lock" ] ||
    fail "same-name Students supervisor interfered with Harness lock"

launch_supervisor "$target_personal" personal "$TEST_ROOT/personal.out"
personal_pid=$launched_pid
wait_for_file "$runtime/personal/shared.state" "$personal_pid"
personal_release=$(release_for_target personal)
personal_payload=${personal_release##*/}
[ -f "$personal_release/.codex-runtime-release" ] ||
    fail "Personal target-scoped runtime release was not created"
grep -F 'target=personal' "$runtime/personal/shared.state" >/dev/null ||
    fail "Personal supervisor state lost target identity"
[ -d "$runtime/personal/shared.lock" ] ||
    fail "Personal target lock is absent"
[ -d "$runtime/harness/shared.lock" ] &&
    [ -d "$runtime/students/shared.lock" ] ||
    fail "same-name Personal supervisor interfered with another target lock"
[ "$harness_payload" = "$students_payload" ] &&
    [ "$harness_payload" = "$personal_payload" ] ||
    fail "identical payload changed identity across target-scoped releases"

status_output=$(
    HARNESS_CONTROL_ROOT="$harness_release" \
    HARNESS_TARGET_ROOT="$target_harness" \
    HARNESS_CODEX_RELEASE_COMMIT="$commit" \
    HARNESS_CODEX_RELEASE_PAYLOAD="$harness_payload" \
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
    HARNESS_CODEX_RELEASE_PAYLOAD="$students_payload" \
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
    HARNESS_CODEX_RELEASE_PAYLOAD="$harness_payload" \
    HARNESS_CODEX_RELEASE_TARGET=harness \
    HARNESS_TESTING=1 \
    HARNESS_TEST_RUNTIME_DIR="$runtime" \
        "$harness_release/libexec/harness-codex-resilient" \
            --status --name shared >"$TEST_ROOT/ambiguous.out" 2>&1; then
    fail "same-name cross-target status was accepted without a target"
fi
grep -F 'status requires --target' "$TEST_ROOT/ambiguous.out" >/dev/null ||
    fail "cross-target status ambiguity was not classified"
if env -u HARNESS_CODEX_RELEASE_PAYLOAD \
    HARNESS_CONTROL_ROOT="$harness_release" \
    HARNESS_TARGET_ROOT="$target_harness" \
    HARNESS_CODEX_RELEASE_COMMIT="$commit" \
    HARNESS_CODEX_RELEASE_TARGET=harness \
    HARNESS_TESTING=1 \
    HARNESS_TEST_RUNTIME_DIR="$runtime" \
        "$harness_release/libexec/harness-codex-resilient" \
            --status --target harness --name shared \
            >"$TEST_ROOT/missing-payload.out" 2>&1; then
    fail "released runtime accepted missing payload identity"
fi
grep -F 'Codex runtime release marker is invalid' \
    "$TEST_ROOT/missing-payload.out" >/dev/null ||
    fail "missing payload identity did not fail closed"

git -C "$control" commit -q --allow-empty -m 'unrelated fixture change'
unrelated_commit=$(git -C "$control" rev-parse HEAD)
[ "$unrelated_commit" != "$commit" ] ||
    fail "unrelated fixture commit did not advance provenance"
(
    cd "$target_harness"
    HARNESS_TESTING=1 \
    HARNESS_TEST_CODEX_RELEASE_ROOT="$release_root" \
    HARNESS_TEST_RUNTIME_DIR="$runtime" \
    HARNESS_CODEX_RELEASE_TARGET=harness \
    HARNESS_TARGET_ROOT="$target_harness" \
        "$control/libexec/harness-codex-runtime-release" \
            --exec-resilient --plan --target harness \
            --name unrelated-reuse --last
) >"$TEST_ROOT/unrelated-reuse.out"
[ "$(release_for_target harness)" = "$harness_release" ] ||
    fail "unrelated commit created a second Harness runtime release"
grep -F "source_commit=$commit" \
    "$harness_release/.codex-runtime-release" >/dev/null ||
    fail "warm reuse changed immutable creation provenance"
if grep -F "source_commit=$unrelated_commit" \
    "$harness_release/.codex-runtime-release" >/dev/null; then
    fail "warm reuse rewrote immutable creation provenance"
fi

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
            HARNESS_CODEX_RELEASE_PAYLOAD="$harness_payload" \
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
run_released_launcher personal "$personal_release" "$target_personal"

# Harness and Personal intentionally share one repository in the live Local
# profile. The immutable release target, not reverse lookup by cwd, must select
# between them.
same_root_release=$TEST_ROOT/same-root-release
mkdir -p "$same_root_release/libexec" "$same_root_release/profiles"
cp "$personal_release/libexec/harness-codex-runtime-launch" \
    "$personal_release/libexec/harness_codex_targets.py" \
    "$same_root_release/libexec/"
{
    printf '# target\twindow_index\twindow_name\tpane_index\tcanonical_repository\n'
    printf 'harness\t0\tcowork\t0\t@HARNESS_ROOT@\n'
    printf 'personal\t1\tcodex\t0\t@HARNESS_ROOT@\n'
    printf 'students\t1\tcodex\t1\t%s\n' "$target_students"
} >"$same_root_release/profiles/codex-session-targets.tsv"
chmod 755 "$same_root_release/libexec/"*
chmod 644 "$same_root_release/profiles/codex-session-targets.tsv"
same_root_capture=$capture/same-root-personal
mkdir "$same_root_capture"
(
    cd "$target_harness"
    env \
        HARNESS_CONTROL_ROOT="$same_root_release" \
        HARNESS_TARGET_ROOT="$target_harness" \
        HARNESS_CODEX_RELEASE_COMMIT="$commit" \
        HARNESS_CODEX_RELEASE_TARGET=personal \
        HARNESS_TESTING=1 \
        HARNESS_TEST_NATIVE_CODEX="$fake_native" \
        CODEX_LAUNCH_CAPTURE="$same_root_capture" \
        CODEX_EXPECTED_REPOSITORY="$target_harness" \
        "$same_root_release/libexec/harness-codex-runtime-launch" \
            --probe same-root-personal
)
[ -f "$same_root_capture/native-executed" ] ||
    fail "same-root Personal release did not reach native Codex"

subdir_capture=$capture/released-subdirectory
mkdir "$subdir_capture"
(
    cd "$target_harness/nested"
    env \
        HARNESS_CONTROL_ROOT="$harness_release" \
        HARNESS_TARGET_ROOT="$target_harness" \
        HARNESS_CODEX_RELEASE_COMMIT="$commit" \
        HARNESS_CODEX_RELEASE_PAYLOAD="$harness_payload" \
        HARNESS_CODEX_RELEASE_TARGET=harness \
        HARNESS_TESTING=1 \
        HARNESS_TEST_NATIVE_CODEX="$fake_native" \
        CODEX_LAUNCH_CAPTURE="$subdir_capture" \
        CODEX_EXPECTED_REPOSITORY="$target_harness" \
        "$harness_release/libexec/harness-codex-runtime-launch" \
            --probe subdirectory
)
[ -f "$subdir_capture/native-environment" ] ||
    fail "released launcher did not normalize a repository subdirectory"

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
    harness "$harness_release" personal "$target_personal"
assert_wrong_release_repository \
    students "$students_release" harness "$target_harness"
assert_wrong_release_repository \
    students "$students_release" personal "$target_personal"
assert_wrong_release_repository \
    personal "$personal_release" harness "$target_harness"
assert_wrong_release_repository \
    personal "$personal_release" students "$target_students"

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

stop_process "$personal_pid"
personal_pid=
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

held_release=$release_root/held-harness-release
chmod 700 "$harness_release"
mv "$harness_release" "$held_release"
chmod 500 "$held_release"
release_lock=$release_root/releases/harness/.$harness_payload.lock
mkdir "$release_lock"
chmod 700 "$release_lock"
printf '99999999\n' >"$release_lock/pid"
chmod 600 "$release_lock/pid"
(
    cd "$target_harness"
    HARNESS_TESTING=1 \
    HARNESS_TEST_CODEX_RELEASE_ROOT="$release_root" \
    HARNESS_CODEX_RELEASE_TARGET=harness \
    HARNESS_TARGET_ROOT="$target_harness" \
        "$control/libexec/harness-codex-runtime-release" \
            --exec-resilient --plan --target harness \
            --name stale-release-lock --last
) >"$TEST_ROOT/stale-release-lock.out"
[ -d "$harness_release" ] && [ ! -e "$release_lock" ] ||
    fail "stale runtime release lock was not recovered"

incomplete_release=$release_root/incomplete-harness-release
chmod 700 "$harness_release"
mv "$harness_release" "$incomplete_release"
chmod 500 "$incomplete_release"
mkdir "$release_lock"
chmod 700 "$release_lock"
(
    cd "$target_harness"
    HARNESS_TESTING=1 \
    HARNESS_TEST_CODEX_RELEASE_ROOT="$release_root" \
    HARNESS_CODEX_RELEASE_TARGET=harness \
    HARNESS_TARGET_ROOT="$target_harness" \
        "$control/libexec/harness-codex-runtime-release" \
            --exec-resilient --plan --target harness \
            --name incomplete-release-lock --last
) >"$TEST_ROOT/incomplete-release-lock.out"
[ -d "$harness_release" ] && [ ! -e "$release_lock" ] ||
    fail "incomplete runtime release lock was not recovered"

delayed_release=$release_root/delayed-harness-release
chmod 700 "$harness_release"
mv "$harness_release" "$delayed_release"
chmod 700 "$delayed_release"
mkdir "$release_lock"
chmod 700 "$release_lock"
printf '%s\n' "$$" >"$release_lock/pid"
chmod 600 "$release_lock/pid"
wait_bin=$TEST_ROOT/wait-bin
mkdir "$wait_bin"
cat >"$wait_bin/sleep" <<'EOF'
#!/bin/sh
set -eu
count=0
[ ! -f "$RELEASE_WAIT_COUNT" ] ||
    count=$(sed -n '1p' "$RELEASE_WAIT_COUNT")
count=$((count + 1))
printf '%s\n' "$count" >"$RELEASE_WAIT_COUNT"
if [ "$count" -eq 30 ]; then
    mv "$DELAYED_RELEASE" "$EXPECTED_RELEASE"
    chmod 500 "$EXPECTED_RELEASE"
fi
EOF
chmod 700 "$wait_bin/sleep"
(
    cd "$target_harness"
    PATH="$wait_bin:$PATH" \
    RELEASE_WAIT_COUNT="$TEST_ROOT/release-wait.count" \
    DELAYED_RELEASE="$delayed_release" \
    EXPECTED_RELEASE="$harness_release" \
    HARNESS_TESTING=1 \
    HARNESS_TEST_CODEX_RELEASE_ROOT="$release_root" \
    HARNESS_CODEX_RELEASE_TARGET=harness \
    HARNESS_TARGET_ROOT="$target_harness" \
        "$control/libexec/harness-codex-runtime-release" \
            --exec-resilient --plan --target harness \
            --name final-poll-release --last
) >"$TEST_ROOT/final-poll-release.out"
[ "$(cat "$TEST_ROOT/release-wait.count")" = 30 ] ||
    fail "final-poll release fixture did not reach the boundary"
grep -F 'name=final-poll-release target=harness selector=last status=ready' \
    "$TEST_ROOT/final-poll-release.out" >/dev/null ||
    fail "final-poll concurrent release lost validated provenance"
unlink "$release_lock/pid"
rmdir "$release_lock"

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
