#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/hardening-audit-test.XXXXXX")

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEST_ROOT" ]; then
        "$CLEANUP" "$HARNESS" "$TEMP_BASE" "$TEST_ROOT" \
            "$TEMP_BASE" >/dev/null || cleanup_failed=1
    fi
    [ "$status" -ne 0 ] || [ "$cleanup_failed" -eq 0 ] || status=1
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

repo=$TEST_ROOT/private-repository-name
mkdir -p "$repo/.github/workflows" "$repo/private"
git -C "$repo" init -q
git -C "$repo" config user.name audit-test
git -C "$repo" config user.email audit-test.invalid
printf '%s\n' '# instructions' >"$repo/AGENTS.md"
printf '%s\n' '# ledger' >"$repo/TODO.md"
printf '%s\n' 'version: 2' >"$repo/.github/dependabot.yml"
printf '%s\n' 'steps:' '  - uses: actions/checkout@main' \
    >"$repo/.github/workflows/ci.yml"
printf '%s\n' 'synthetic' >"$repo/private/example.txt"
git -C "$repo" add .
git -C "$repo" commit -qm baseline
printf '%s\n' 'dirty' >>"$repo/TODO.md"

output=$("$HARNESS" hardening-audit --repo "$repo")
printf '%s\n' "$output" | grep -F \
    'repo=ready worktree=dirty dirty_entries=1 branch=attached upstream=absent ahead=0 behind=0 instructions=present todo=present' \
    >/dev/null || fail "state summary"
printf '%s\n' "$output" | grep -F \
    'workflows=1 unpinned_actions=1 dependabot=present tracked_sensitive_paths=1' \
    >/dev/null || fail "security summary"
printf '%s\n' "$output" | grep -F 'END hardening_audit findings=3' \
    >/dev/null || fail "finding count"
printf '%s\n' "$output" | grep -F 'private-repository-name' >/dev/null &&
    fail "repository name leaked"

unknown=$("$HARNESS" definitely-not-a-command 2>&1 || true)
[ "$(printf '%s\n' "$unknown" | grep -c '^unknown harness command:')" -eq 1 ] ||
    fail "unknown command diagnostic cardinality"

printf 'hardening_audit_tests=pass\n'
