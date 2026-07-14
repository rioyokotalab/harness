#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
RULES=$ROOT/.codex/rules/default.rules
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/guarded-delete-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

token_from() {
    sed -n 's/^TOKEN sha256=//p' "$1"
}

expect_failure() {
    expected=$1
    output=$2
    shift 2
    if "$@" >"$output" 2>&1; then
        fail "command unexpectedly succeeded: $*"
    fi
    grep -F -- "$expected" "$output" >/dev/null ||
        fail "missing failure evidence '$expected': $*"
}

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEST_ROOT" ]; then
        "$CLEANUP" "$HARNESS" "${TMPDIR:-/tmp}" "$TEST_ROOT" \
            "${TMPDIR:-/tmp}" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then
        echo "FAIL: guarded-delete suite cleanup" >&2
        status=1
    fi
    exit "$status"
}

trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

sh -n "$ROOT/shared/skills/guarded-bulk-delete/scripts/guarded-delete" ||
    fail "guarded-delete shell syntax"
sh -n "$CLEANUP" || fail "guarded test cleanup shell syntax"

expect_failure '--within is too broad and contains a protected anchor' \
    "$TEST_ROOT/cleanup-home.out" "$CLEANUP" "$HARNESS" /home "$HOME" \
    "${TMPDIR:-/tmp}"
[ -d "$HOME" ] || fail "adversarial cleanup removed the account home"

for command in \
    'rm -rf /home/rioyokota' \
    'rm -r generated' \
    'rm -f -r cache' \
    '/bin/rm -Rf build' \
    '/usr/bin/rm --recursive output'
do
    # These fixed test strings contain no expansion and are split intentionally.
    set -- $command
    codex execpolicy check --pretty --rules "$RULES" -- "$@" \
        >"$TEST_ROOT/rule.out" 2>/dev/null || fail "execpolicy check: $command"
    grep '"decision": "forbidden"' "$TEST_ROOT/rule.out" >/dev/null ||
        fail "execpolicy did not forbid: $command"
done
codex execpolicy check --pretty --rules "$RULES" -- rm -f exact-file \
    >"$TEST_ROOT/rule-safe.out" 2>/dev/null || fail "non-recursive execpolicy check"
if grep '"decision": "forbidden"' "$TEST_ROOT/rule-safe.out" >/dev/null; then
    fail "execpolicy forbade exact non-recursive removal"
fi

mkdir -p "$TEST_ROOT/root/success target/nested" "$TEST_ROOT/root/keep"
printf '%s\n' delete >"$TEST_ROOT/root/success target/nested/file"
printf '%s\n' keep >"$TEST_ROOT/root/keep/file"
success_manifest="$TEST_ROOT/success manifest"
(cd "$ROOT" && "$HARNESS" guarded-delete plan \
    --within "$TEST_ROOT/root" --manifest "$success_manifest" -- \
    "$TEST_ROOT/root/success target") >"$TEST_ROOT/success.plan"
success_token=$(token_from "$TEST_ROOT/success.plan")
[ -n "$success_token" ] || fail "success plan token"
[ "$(stat -c '%a' "$success_manifest")" = 600 ] || fail "manifest mode"
grep -F "NEXT harness guarded-delete apply --manifest '$success_manifest' --token $success_token" \
    "$TEST_ROOT/success.plan" >/dev/null || fail "shell-quoted next command"
(cd "$ROOT" && "$HARNESS" guarded-delete apply \
    --manifest "$success_manifest" --token "$success_token") \
    >"$TEST_ROOT/success.apply"
[ ! -e "$TEST_ROOT/root/success target" ] || fail "success target remains"
[ -f "$TEST_ROOT/root/keep/file" ] || fail "success removed retained sibling"
grep 'VERIFIED protected_anchors=unchanged targets=absent' \
    "$TEST_ROOT/success.apply" >/dev/null || fail "success verification marker"

expect_failure 'HOME differs from the account database' "$TEST_ROOT/home.out" \
    env HOME=/tmp "$HARNESS" guarded-delete plan \
    --within "$TEST_ROOT/root" --manifest "$TEST_ROOT/home.manifest" -- \
    "$TEST_ROOT/root/keep"
[ ! -e "$TEST_ROOT/home.manifest" ] || fail "HOME mismatch created manifest"

expect_failure '--within is too broad and contains a protected anchor' \
    "$TEST_ROOT/protected-home.out" "$HARNESS" guarded-delete plan \
    --within /home --manifest "$TEST_ROOT/protected-home.manifest" -- "$HOME"
[ -d "$HOME" ] || fail "protected home disappeared"

expect_failure 'target is not a strict descendant of --within' \
    "$TEST_ROOT/root-equality.out" "$HARNESS" guarded-delete plan \
    --within "$TEST_ROOT/root" --manifest "$TEST_ROOT/root-equality.manifest" -- \
    "$TEST_ROOT/root"

mkdir -p "$TEST_ROOT/root/cwd-target/inside"
expect_failure 'target is or contains a protected anchor' "$TEST_ROOT/cwd.out" \
    sh -c 'cd "$1" && exec "$2" guarded-delete plan --within "$3" --manifest "$4" -- "$5"' \
    sh "$TEST_ROOT/root/cwd-target/inside" "$HARNESS" "$TEST_ROOT/root" \
    "$TEST_ROOT/cwd.manifest" "$TEST_ROOT/root/cwd-target"

mkdir -p "$TEST_ROOT/root/manifest-target"
expect_failure 'manifest cannot be stored inside a deletion target' \
    "$TEST_ROOT/manifest-inside.out" "$HARNESS" guarded-delete plan \
    --within "$TEST_ROOT/root" \
    --manifest "$TEST_ROOT/root/manifest-target/delete.manifest" -- \
    "$TEST_ROOT/root/manifest-target"

mkdir -p "$TEST_ROOT/root/real-target"
ln -s "$TEST_ROOT/root/real-target" "$TEST_ROOT/root/symlink-target"
expect_failure 'symlink directories are not recursive-delete targets' \
    "$TEST_ROOT/symlink.out" "$HARNESS" guarded-delete plan \
    --within "$TEST_ROOT/root" --manifest "$TEST_ROOT/symlink.manifest" -- \
    "$TEST_ROOT/root/symlink-target"

mkdir -p "$TEST_ROOT/root/unreadable-target/private"
printf '%s\n' hidden >"$TEST_ROOT/root/unreadable-target/private/file"
chmod 000 "$TEST_ROOT/root/unreadable-target/private"
expect_failure 'cannot inventory every target entry' "$TEST_ROOT/unreadable.out" \
    "$HARNESS" guarded-delete plan --within "$TEST_ROOT/root" \
    --manifest "$TEST_ROOT/unreadable.manifest" -- \
    "$TEST_ROOT/root/unreadable-target"
chmod 700 "$TEST_ROOT/root/unreadable-target/private"
[ ! -e "$TEST_ROOT/unreadable.manifest" ] || fail "partial inventory created manifest"

mkdir -p "$TEST_ROOT/root/overlap/child"
expect_failure 'overlapping deletion targets are forbidden' "$TEST_ROOT/overlap.out" \
    "$HARNESS" guarded-delete plan --within "$TEST_ROOT/root" \
    --manifest "$TEST_ROOT/overlap.manifest" -- \
    "$TEST_ROOT/root/overlap" "$TEST_ROOT/root/overlap/child"

mkdir -p "$TEST_ROOT/root/token-target"
token_manifest=$TEST_ROOT/token.manifest
"$HARNESS" guarded-delete plan --within "$TEST_ROOT/root" \
    --manifest "$token_manifest" -- "$TEST_ROOT/root/token-target" \
    >"$TEST_ROOT/token.plan"
token=$(token_from "$TEST_ROOT/token.plan")
expect_failure 'manifest token mismatch; re-plan' "$TEST_ROOT/token.out" \
    "$HARNESS" guarded-delete apply --manifest "$token_manifest" \
    --token 0000000000000000000000000000000000000000000000000000000000000000
[ -d "$TEST_ROOT/root/token-target" ] || fail "bad token deleted target"

mkdir -p "$TEST_ROOT/root/drift-target"
drift_manifest=$TEST_ROOT/drift.manifest
"$HARNESS" guarded-delete plan --within "$TEST_ROOT/root" \
    --manifest "$drift_manifest" -- "$TEST_ROOT/root/drift-target" \
    >"$TEST_ROOT/drift.plan"
drift_token=$(token_from "$TEST_ROOT/drift.plan")
printf '%s\n' changed >"$TEST_ROOT/root/drift-target/new-file"
expect_failure 'target entry count changed; re-plan' "$TEST_ROOT/drift.out" \
    "$HARNESS" guarded-delete apply --manifest "$drift_manifest" \
    --token "$drift_token"
[ -f "$TEST_ROOT/root/drift-target/new-file" ] || fail "drift failure deleted target"

echo 'guarded-delete tests: PASS'
