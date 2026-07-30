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

for repository in "$test_harness" "$students" "$swallow"; do
    mkdir -p "$repository/.codex"
    git -C "$repository" init -q -b main
    printf '%s\n' 'model = "gpt-5.6-sol"' \
        >"$repository/.codex/config.toml"
done
printf '# target\tindex\tcanonical_repository\n' >"$profile"
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
from harness_codex_targets import cwd_allowed

harness, students = sys.argv[1:]
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

printf '%s\n' 'PASS: repository-native Codex target map'
