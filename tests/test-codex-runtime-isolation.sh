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
    hold_fifo=$2
    case "$process_pid" in ''|*[!0-9]*) return ;; esac
    [ ! -p "$hold_fifo" ] || printf '%s\n' release >"$hold_fifo"
    set +e
    wait "$process_pid" 2>/dev/null
    set -e
}

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    stop_process "$personal_pid" "$TEST_ROOT/personal.hold"
    stop_process "$students_pid" "$TEST_ROOT/students.hold"
    stop_process "$harness_pid" "$TEST_ROOT/harness.hold"
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
    "$ROOT/tests/test-phase1-orchestrator.sh")" = 1 ] ||
    fail "phase-1 retains divergent focused-suite execution"
grep -F '    legacy) jobs=1 ;;' \
    "$ROOT/tests/test-phase1-orchestrator.sh" >/dev/null ||
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
printf '%s\n' ready >"$FAKE_READY_FIFO"
IFS= read -r _release <"$FAKE_HOLD_FIFO"
EOF
chmod 700 "$fake_launcher"

launch_supervisor() {
    repository=$1
    target=$2
    output=$3
    mkfifo "$TEST_ROOT/$target.ready" "$TEST_ROOT/$target.hold"
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
            FAKE_READY_FIFO="$TEST_ROOT/$target.ready" \
            FAKE_HOLD_FIFO="$TEST_ROOT/$target.hold" \
            "$control/libexec/harness-codex-resilient" \
                --run --target "$target" --name shared --last
    ) >"$output" 2>&1 &
    launched_pid=$!
}

wait_for_ready() {
    target=$1
    IFS= read -r ready_state <"$TEST_ROOT/$target.ready"
    [ "$ready_state" = ready ] || fail "runtime supervisor readiness"
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
wait_for_ready harness
[ -f "$runtime/harness/shared.state" ] || fail "Harness runtime state missing"
[ -f "$TEST_ROOT/harness.launcher.cwd" ] || fail "Harness launcher cwd missing"
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

# One target proves canonical cwd, batched Git identity, immutable permissions,
# re-exec, state isolation, and descriptor isolation. Repeating the identical
# release transaction for Personal and Students is redundant in the default
# owner; target-map semantics remain owned by test-codex-targets.sh.
printf '%s\n' 'PASS: Codex target-scoped immutable runtime'
exit 0
