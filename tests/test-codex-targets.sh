#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/harness-codex-targets-test.XXXXXX")

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
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

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

resolver=$ROOT/libexec/harness_codex_targets.py
test_harness=$TEST_ROOT/harness
students=$TEST_ROOT/students
swallow=$TEST_ROOT/swallow
profile=$TEST_ROOT/targets.tsv
fake_home=$TEST_ROOT/home
launcher_capture=$TEST_ROOT/launcher-capture
poison_control=$TEST_ROOT/poison-control
mkdir -p "$fake_home/.local/bin" "$launcher_capture" \
    "$poison_control/libexec"

for repository in "$test_harness" "$students" "$swallow"; do
    mkdir -p "$repository/.codex"
    git -C "$repository" init -q -b main
    printf '%s\n' 'model = "gpt-5.6-sol"' \
        'model_reasoning_effort = "high"' \
        >"$repository/.codex/config.toml"
done
printf '# target\tpane_index\tcanonical_repository\n' >"$profile"
printf 'harness\t0\t@HARNESS_ROOT@\n' >>"$profile"
printf 'students\t1\t%s\n' "$students" >>"$profile"
printf 'swallow\t2\t%s\n' "$swallow" >>"$profile"

run_resolver() {
    PYTHONDONTWRITEBYTECODE=1 HARNESS_TESTING=1 \
        HARNESS_ROOT="$TEST_ROOT/ambient-must-not-win" \
        HARNESS_CONTROL_ROOT="$ROOT" \
        HARNESS_TARGET_ROOT="$test_harness" \
        HARNESS_TEST_CODEX_TARGETS_FILE="$profile" \
        python3 "$resolver" "$@"
}

run_resolver validate-all >"$TEST_ROOT/ready.out"
grep -F 'CODEX_TARGETS status=ready count=3' "$TEST_ROOT/ready.out" \
    >/dev/null || fail "closed target map validation"
[ "$(run_resolver repository students)" = "$students" ] ||
    fail "Students target lookup"
[ "$(run_resolver target-for-repository "$swallow")" = swallow ] ||
    fail "Swallow reverse target lookup"
PYTHONPATH="$ROOT/libexec" PYTHONDONTWRITEBYTECODE=1 HARNESS_TESTING=1 \
    HARNESS_CONTROL_ROOT="$ROOT" HARNESS_TARGET_ROOT="$test_harness" \
    HARNESS_TEST_CODEX_TARGETS_FILE="$profile" \
    python3 - "$test_harness" "$students" <<'PY' ||
import sys
from harness_codex_targets import (
    INITIAL_LAYOUT,
    PANE_ROLE_OPTION,
    SESSION_NAME,
    WINDOW_INDEX,
    WINDOW_NAME,
    cwd_allowed,
)

harness, students = sys.argv[1:]
assert SESSION_NAME == "projects"
assert WINDOW_INDEX == 0
assert WINDOW_NAME == "codex"
assert INITIAL_LAYOUT == "main-vertical"
assert PANE_ROLE_OPTION == "@harness_target"
assert cwd_allowed("students", students)
assert not cwd_allowed("students", harness)
assert not cwd_allowed("swallow", harness)
PY
    fail "target-native CWD eligibility"
if run_resolver target-for-repository "$TEST_ROOT" \
    >"$TEST_ROOT/outside.out" 2>&1; then
    fail "outside repository admitted"
fi

cp "$profile" "$TEST_ROOT/targets.valid"
printf 'swallow\t2\t%s\n' "$students" \
    >"$TEST_ROOT/duplicate-line"
sed '$d' "$profile" >"$TEST_ROOT/profile-prefix"
cp "$TEST_ROOT/profile-prefix" "$profile"
cat "$TEST_ROOT/duplicate-line" >>"$profile"
if run_resolver validate-all >"$TEST_ROOT/duplicate.out" 2>&1; then
    fail "duplicate repository admitted"
fi
cp "$TEST_ROOT/targets.valid" "$profile"

ln -s "$students" "$TEST_ROOT/students-link"
sed "s|$students|$TEST_ROOT/students-link|" \
    "$TEST_ROOT/targets.valid" >"$profile"
if run_resolver validate-all >"$TEST_ROOT/symlink.out" 2>&1; then
    fail "symlinked repository admitted"
fi
cp "$TEST_ROOT/targets.valid" "$profile"

chmod 666 "$profile"
if run_resolver validate-all >"$TEST_ROOT/profile-mode.out" 2>&1; then
    fail "world-writable profile admitted"
fi
chmod 644 "$profile"
chmod 666 "$students/.codex/config.toml"
if run_resolver validate-all >"$TEST_ROOT/config-mode.out" 2>&1; then
    fail "world-writable project configuration admitted"
fi
chmod 644 "$students/.codex/config.toml"
run_resolver validate-all >/dev/null ||
    fail "valid target map did not recover after hostile cases"

cp "$resolver" "$poison_control/libexec/harness_codex_targets.py"
chmod 755 "$poison_control/libexec/harness_codex_targets.py"
cat >"$fake_home/.local/bin/codex" <<'EOF'
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
[ "$(pwd -P)" = "$CODEX_EXPECTED_REPOSITORY" ] || exit 10
grep -F -x 'model = "gpt-5.6-sol"' .codex/config.toml >/dev/null ||
    exit 11
grep -F -x 'model_reasoning_effort = "high"' .codex/config.toml \
    >/dev/null || exit 12
printf '%s\n' "$*" >"$CODEX_LAUNCH_CAPTURE/native-arguments"
EOF
chmod 700 "$fake_home/.local/bin/codex"
installed_launcher=$fake_home/.local/bin/harness-codex
ln -s "$ROOT/bin/harness-codex" "$installed_launcher"

assert_poison_rejected() {
    poison_label=$1
    poison_repository=$2
    poison_variable=$3
    poison_value=$4
    poison_error=$5
    poison_capture=$launcher_capture/poison-$poison_label
    mkdir "$poison_capture"
    if (
        cd "$poison_repository"
        env \
            HOME="$fake_home" \
            HARNESS_ROOT="$ROOT" \
            HARNESS_CONTROL_ROOT="$ROOT" \
            HARNESS_TARGET_ROOT="$ROOT" \
            HARNESS_TESTING=1 \
            HARNESS_TEST_CODEX_TARGETS_FILE="$profile" \
            CODEX_LAUNCH_CAPTURE="$poison_capture" \
            CODEX_EXPECTED_REPOSITORY="$poison_repository" \
            "$poison_variable=$poison_value" \
            "$installed_launcher" --probe "$poison_label"
    ) >"$TEST_ROOT/poison-$poison_label.out" 2>&1; then
        fail "direct launcher accepted poisoned $poison_variable"
    fi
    grep -F "$poison_error" "$TEST_ROOT/poison-$poison_label.out" \
        >/dev/null ||
        fail "direct launcher did not classify poisoned $poison_variable"
    [ ! -e "$poison_capture/native-executed" ] ||
        fail "poisoned $poison_variable reached native Codex"
}

assert_poison_rejected root "$ROOT" HARNESS_ROOT "$poison_control" \
    'HARNESS_ROOT does not match its launcher'
assert_poison_rejected control "$ROOT" HARNESS_CONTROL_ROOT "$poison_control" \
    'control root does not match its launcher'
assert_poison_rejected target "$test_harness" HARNESS_TARGET_ROOT \
    "$test_harness" 'target root does not match its launcher'

run_direct_launcher() {
    direct_target=$1
    direct_repository=$2
    direct_capture=$launcher_capture/$direct_target
    mkdir "$direct_capture"
    (
        cd "$direct_repository"
        HOME="$fake_home" \
        HARNESS_ROOT="$ROOT" \
        HARNESS_CONTROL_ROOT="$ROOT" \
        HARNESS_TARGET_ROOT="$ROOT" \
        HARNESS_CODEX_RELEASE_COMMIT=ambient-commit \
        HARNESS_CODEX_RELEASE_FUTURE=ambient-release \
        HARNESS_CODEX_RELEASE_TARGET=ambient-target \
        HARNESS_TESTING=1 \
        HARNESS_TEST_ALLOW_NONMAIN=1 \
        HARNESS_TEST_CODEX_TARGETS_FILE="$profile" \
        HARNESS_TEST_FUTURE_VARIABLE=ambient-test \
        CODEX_LAUNCH_CAPTURE="$direct_capture" \
        CODEX_EXPECTED_REPOSITORY="$direct_repository" \
            "$installed_launcher" --probe "$direct_target"
    )
    [ -f "$direct_capture/native-executed" ] ||
        fail "$direct_target direct launcher did not reach native Codex"
    [ ! -e "$direct_capture/native-leak" ] ||
        fail "$direct_target direct launcher leaked Harness state"
    grep -F -- "--sandbox danger-full-access --probe $direct_target" \
        "$direct_capture/native-arguments" >/dev/null ||
        fail "$direct_target direct launcher changed native arguments"
}

run_direct_launcher harness "$ROOT"
run_direct_launcher students "$students"
run_direct_launcher swallow "$swallow"

printf '%s\n' 'PASS: repository-native Codex target map'
