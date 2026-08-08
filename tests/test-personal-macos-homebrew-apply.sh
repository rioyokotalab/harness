#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
SOURCE=$ROOT/libexec/harness-macos-homebrew

fail() { echo "FAIL: $*" >&2; exit 1; }

for contract in \
    'private profile changed before managed Homebrew apply' \
    'managed Homebrew plan changed before apply' \
    'status=running' \
    'status=failed' \
    'status=complete' \
    'automatic rollback is unavailable' \
    'managed Homebrew post-state did not converge'
do
    grep -F "$contract" "$SOURCE" >/dev/null ||
        fail "missing irreversible-apply contract: $contract"
done
grep -F 'chmod 600 "$manifest" "$status_file"' "$SOURCE" >/dev/null ||
    fail "private transaction evidence mode"
grep -F "echo 'END macos_homebrew applied=yes rollback=manual-review-only metadata_refresh=separate'" \
    "$SOURCE" >/dev/null || fail "bounded apply completion contract"

echo 'personal macOS Homebrew apply contract: PASS'
