#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HELPER_SOURCE=$ROOT/tests/smoke/jobs/source-contract.sh
DOC=$ROOT/docs/queued-job-source-contract.md
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/source-contract-test.XXXXXX")

fail() { echo "FAIL: $*" >&2; exit 1; }
cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEST_ROOT" ]; then
        "$CLEANUP" "$ROOT/bin/harness" "${TMPDIR:-/tmp}" "$TEST_ROOT" \
            "${TMPDIR:-/tmp}" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then status=1; fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

repo=$TEST_ROOT/repo
mkdir -p "$repo/tests/smoke/jobs" "$repo/tests/smoke"
git -C "$repo" init -q
git -C "$repo" config user.name harness-test
git -C "$repo" config user.email harness-test.invalid
cp "$HELPER_SOURCE" "$repo/tests/smoke/jobs/source-contract.sh"
chmod 755 "$repo/tests/smoke/jobs/source-contract.sh"
printf '%s\n' source-v1 >"$repo/tests/smoke/source.cpp"
printf '%s\n' unrelated-v1 >"$repo/README.md"
git -C "$repo" add .
git -C "$repo" commit -q -m base
base=$(git -C "$repo" rev-parse HEAD)
helper=$repo/tests/smoke/jobs/source-contract.sh

"$helper" "$base" tests/smoke/jobs/source-contract.sh tests/smoke/source.cpp \
    >"$TEST_ROOT/base.out"
grep -F 'paths=2 status=pass' "$TEST_ROOT/base.out" >/dev/null || fail "base pass"

printf '%s\n' unrelated-v2 >"$repo/README.md"
git -C "$repo" commit -q -am unrelated
"$helper" "$base" tests/smoke/jobs/source-contract.sh tests/smoke/source.cpp \
    >"$TEST_ROOT/successor.out" || fail "unrelated successor"

printf '%s\n' dirty >"$repo/tests/smoke/source.cpp"
if "$helper" "$base" tests/smoke/source.cpp >"$TEST_ROOT/dirty.out" 2>&1; then
    fail "dirty relevant path accepted"
fi
printf '%s\n' source-v1 >"$repo/tests/smoke/source.cpp"

printf '%s\n' source-v2 >"$repo/tests/smoke/source.cpp"
git -C "$repo" commit -q -am relevant
if "$helper" "$base" tests/smoke/source.cpp >"$TEST_ROOT/relevant.out" 2>&1; then
    fail "committed relevant change accepted"
fi

if "$helper" "$base" ../outside >"$TEST_ROOT/unsafe.out" 2>&1; then
    fail "unsafe path accepted"
fi
if "$helper" "$base" missing >"$TEST_ROOT/missing.out" 2>&1; then
    fail "missing path accepted"
fi
if "$helper" 0000000000000000000000000000000000000000 tests/smoke/source.cpp \
    >"$TEST_ROOT/invalid.out" 2>&1; then fail "invalid revision accepted"; fi

other=$TEST_ROOT/other
git clone -q --no-hardlinks "$repo" "$other"
git -C "$other" config user.name harness-test
git -C "$other" config user.email harness-test.invalid
git -C "$other" switch -q --detach "$base"
printf '%s\n' divergent >"$other/divergent"
git -C "$other" add divergent
git -C "$other" commit -q -m divergent
divergent=$(git -C "$other" rev-parse HEAD)
git -C "$repo" fetch -q "$other" "$divergent"
if "$helper" "$divergent" tests/smoke/source.cpp >"$TEST_ROOT/divergent.out" 2>&1; then
    fail "non-ancestor revision accepted"
fi

grep -F 'does not freeze modules' "$DOC" >/dev/null || fail "scope boundary"
grep -F 'every relevant path explicitly listed' "$DOC" >/dev/null ||
    fail "explicit path documentation"

printf '%s\n' 'source contract tests: PASS'
