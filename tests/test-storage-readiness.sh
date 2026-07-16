#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/storage-readiness-test.XXXXXX")

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEST_ROOT" ]; then
        "$CLEANUP" "$HARNESS" "${TMPDIR:-/tmp}" "$TEST_ROOT" \
            "${TMPDIR:-/tmp}" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then status=1; fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

home=$TEST_ROOT/home
persistent=$TEST_ROOT/persistent
cache=$TEST_ROOT/cache
mkdir -p "$home" "$persistent" "$cache"
chmod 700 "$home" "$persistent" "$cache"
layout=$TEST_ROOT/layout.tsv
profile=$TEST_ROOT/host.conf
printf '%s\n' 'schema=1' >"$profile"
printf 'local|%s|%s|none|none|none|none\n' "$persistent" "$cache" >"$layout"

run() {
    env HOME="$home" HARNESS_TESTING=1 HARNESS_LOGICAL_HOST=local \
        HARNESS_HOME_LAYOUT="$layout" HARNESS_HOST_PROFILE="$profile" \
        "$HARNESS" storage-readiness "$@" --host local
}

run >"$TEST_ROOT/plan.out" || fail "read-only plan"
[ "$(grep -c '^STORAGE ' "$TEST_ROOT/plan.out")" -eq 2 ] || fail "root count"
[ -z "$(find "$persistent" "$cache" -maxdepth 1 -name '.harness-storage-readiness.*' -print -quit)" ] ||
    fail "read-only plan created a probe"

run --write-probe >"$TEST_ROOT/probe.out" || fail "write probe"
[ "$(grep -c '^STORAGE_WRITE .*bytes=4096 fsync=pass cleanup=absent$' "$TEST_ROOT/probe.out")" -eq 2 ] ||
    fail "write probe result"
[ -z "$(find "$persistent" "$cache" -maxdepth 1 -name '.harness-storage-readiness.*' -print -quit)" ] ||
    fail "write probe remained"

inside=$home/inside
mkdir "$inside"
printf 'local|%s|%s|none|none|none|none\n' "$inside" "$cache" >"$layout"
if run >"$TEST_ROOT/inside.out" 2>&1; then fail "accepted root inside HOME"; fi
grep -F 'persistent root is inside HOME' "$TEST_ROOT/inside.out" >/dev/null ||
    fail "inside-HOME evidence"

outside=$TEST_ROOT/outside
mkdir "$outside"
ln -s "$outside" "$TEST_ROOT/root-link"
printf 'local|%s|%s|none|none|none|none\n' "$TEST_ROOT/root-link" "$cache" >"$layout"
if run >"$TEST_ROOT/symlink.out" 2>&1; then fail "accepted symlink root"; fi
grep -F 'persistent root is not a real directory' "$TEST_ROOT/symlink.out" >/dev/null ||
    fail "symlink evidence"

real_parent=$TEST_ROOT/real-parent
real_persistent=$real_parent/persistent
mkdir -p "$real_persistent"
ln -s "$real_parent" "$TEST_ROOT/alias-parent"
alias_persistent=$TEST_ROOT/alias-parent/persistent
printf 'local|%s|%s|none|none|none|none\n' "$alias_persistent" "$cache" >"$layout"
printf '%s\n' 'schema=1' >"$profile"
if run >"$TEST_ROOT/undeclared-alias.out" 2>&1; then fail "accepted undeclared canonical alias"; fi
grep -F 'persistent root canonical identity is not explicitly declared' \
    "$TEST_ROOT/undeclared-alias.out" >/dev/null || fail "undeclared alias evidence"
printf 'schema=1\npersistent_canonical_root=%s\n' "$real_persistent" >"$profile"
run --write-probe >"$TEST_ROOT/declared-alias.out" || fail "declared canonical alias"
grep '^STORAGE host=local label=persistent .*canonical_alias=1$' \
    "$TEST_ROOT/declared-alias.out" >/dev/null || fail "declared alias evidence"
[ -z "$(find "$real_persistent" -maxdepth 1 -name '.harness-storage-readiness.*' -print -quit)" ] ||
    fail "declared alias probe remained"

printf '%s\n' 'storage readiness tests: PASS'
