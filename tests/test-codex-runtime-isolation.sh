#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/harness-codex-runtime-test.XXXXXX")
harness_pid=
students_pid=
harness_release=
students_release=

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
    stop_process "$students_pid"
    stop_process "$harness_pid"
    for runtime_release in "$harness_release" "$students_release"; do
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
for variable in HARNESS_ROOT HARNESS_CONTROL_ROOT HARNESS_TARGET_ROOT \
    HARNESS_CODEX_RELEASE_COMMIT HARNESS_CODEX_RELEASE_TARGET \
    HARNESS_TEST_CODEX_RELEASE_ROOT \
    HARNESS_TEST_FORCE_CODEX_RELEASE HARNESS_TEST_NATIVE_CODEX
do
    eval 'present=${'"$variable"'+yes}'
    [ -z "${present:-}" ] || {
        printf 'leaked=%s\n' "$variable" >"$HARNESS_TEST_CAPTURE/native-leak"
        exit 9
    }
done
[ "${RAYON_NUM_THREADS:-}" = 8 ]
[ "${TOKIO_WORKER_THREADS:-}" = 8 ]
printf '%s\n' "$*" >"$HARNESS_TEST_CAPTURE/native-arguments"
printf '%s\n' sanitized >"$HARNESS_TEST_CAPTURE/native-environment"
EOF
chmod 700 "$fake_native"
(
    cd "$target_harness"
    HARNESS_ROOT="$TEST_ROOT/ambient-root" \
    HARNESS_CONTROL_ROOT="$harness_release" \
    HARNESS_TARGET_ROOT="$target_harness" \
    HARNESS_CODEX_RELEASE_COMMIT="$commit" \
    HARNESS_CODEX_RELEASE_TARGET=harness \
    HARNESS_TESTING=1 \
    HARNESS_TEST_CODEX_RELEASE_ROOT="$release_root" \
    HARNESS_TEST_FORCE_CODEX_RELEASE=1 \
    HARNESS_TEST_NATIVE_CODEX="$fake_native" \
    HARNESS_TEST_CAPTURE="$capture" \
        "$harness_release/libexec/harness-codex-runtime-launch" resume --last
)
[ -f "$capture/native-environment" ] ||
    fail "native Codex environment was not checked"
[ ! -e "$capture/native-leak" ] ||
    fail "native Codex inherited a Harness control variable"
grep -F -- '--sandbox danger-full-access resume --last' \
    "$capture/native-arguments" >/dev/null ||
    fail "runtime launcher changed native Codex arguments"

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
(
    cd "$target_students"
    HARNESS_TESTING=1 \
    HARNESS_TEST_FORCE_CODEX_RELEASE=1 \
    HARNESS_TEST_CODEX_RELEASE_ROOT="$release_root" \
    HARNESS_TEST_RUNTIME_DIR="$runtime" \
    HARNESS_TEST_CODEX_LAUNCHER="$fake_once" \
    HARNESS_TEST_CAPTURE="$capture" \
        "$control/libexec/harness-codex-resilient" \
            --run --target students --name explicit-forward \
            --session session-explicit
) >"$TEST_ROOT/release-forwarding.out"
[ "$(cat "$capture/release-forwarding")" = 'resume session-explicit' ] ||
    fail "release handoff changed the explicit no-replay selector"

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
