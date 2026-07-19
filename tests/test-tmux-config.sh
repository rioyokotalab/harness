#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/harness-tmux-config-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    if [ -d "$TEMP_DIR" ]; then
        "$CLEANUP" "$HARNESS" "${TMPDIR:-/tmp}" "$TEMP_DIR" "${TMPDIR:-/tmp}" >/dev/null || status=1
    fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
fail() { echo "FAIL: $*" >&2; exit 1; }

command -v tmux >/dev/null 2>&1 || fail "tmux unavailable"
home=$TEMP_DIR/home
mkdir "$home"
long_tmp=$TEMP_DIR/long-default-temporary-directory/with-enough-components/to-exceed-the-tmux-socket-path-limit
mkdir -p "$long_tmp"
HARNESS_TEST_ALLOW_NONMAIN=1 HOME="$home" TMPDIR="$long_tmp" \
    "$ROOT/libexec/harness-tmux-config" --plan >"$TEMP_DIR/long-tmp-plan.out" ||
    fail "long TMPDIR tmux validation"
grep -F 'state=absent action=link' "$TEMP_DIR/long-tmp-plan.out" >/dev/null ||
    fail "long TMPDIR plan"
HARNESS_TEST_ALLOW_NONMAIN=1 HOME="$home" "$ROOT/libexec/harness-tmux-config" --plan \
    >"$TEMP_DIR/plan.out"
grep -F 'state=absent action=link' "$TEMP_DIR/plan.out" >/dev/null || fail "absent plan"
HARNESS_TEST_ALLOW_NONMAIN=1 HOME="$home" "$ROOT/libexec/harness-tmux-config" --apply \
    >"$TEMP_DIR/apply.out"
[ -L "$home/.tmux.conf" ] &&
    [ "$(readlink "$home/.tmux.conf")" = "$ROOT/config/tmux/tmux.conf" ] || fail "canonical symlink"
transaction=$(sed -n 's/.*transaction=\([^ ]*\).*/\1/p' "$TEMP_DIR/apply.out")
[ -n "$transaction" ] || fail "transaction identifier"
HARNESS_TEST_ALLOW_NONMAIN=1 HOME="$home" "$ROOT/libexec/harness-tmux-config" --rollback "$transaction" \
    >"$TEMP_DIR/rollback.out"
[ ! -e "$home/.tmux.conf" ] && [ ! -L "$home/.tmux.conf" ] || fail "absent rollback"

alias_physical=$TEMP_DIR/alias-physical
alias_parent=$TEMP_DIR/alias-parent
mkdir -p "$alias_physical/home"
ln -s "$alias_physical" "$alias_parent"
alias_home=$alias_parent/home
HARNESS_TESTING=1 HARNESS_TEST_ALLOW_NONMAIN=1 HOME="$alias_home" \
    HARNESS_LOGICAL_HOST=rc HARNESS_HOME_ROOT="$alias_home" \
    HARNESS_HOME_CANONICAL_ROOT="$alias_physical/home" \
    "$ROOT/libexec/harness-tmux-config" --apply >"$TEMP_DIR/alias-apply.out"
[ -L "$alias_home/.tmux.conf" ] || fail "declared HOME alias apply"
alias_transaction=$(sed -n 's/.*transaction=\([^ ]*\).*/\1/p' "$TEMP_DIR/alias-apply.out")
HARNESS_TESTING=1 HARNESS_TEST_ALLOW_NONMAIN=1 HOME="$alias_home" \
    HARNESS_LOGICAL_HOST=rc HARNESS_HOME_ROOT="$alias_home" \
    HARNESS_HOME_CANONICAL_ROOT="$alias_physical/home" \
    "$ROOT/libexec/harness-tmux-config" --rollback "$alias_transaction" \
    >"$TEMP_DIR/alias-rollback.out"
[ ! -e "$alias_home/.tmux.conf" ] && [ ! -L "$alias_home/.tmux.conf" ] ||
    fail "declared HOME alias rollback"
if HARNESS_TESTING=1 HARNESS_TEST_ALLOW_NONMAIN=1 HOME="$alias_home" \
    HARNESS_LOGICAL_HOST=rc HARNESS_HOME_ROOT="$alias_home" \
    HARNESS_HOME_CANONICAL_ROOT="$TEMP_DIR/wrong-home" \
    "$ROOT/libexec/harness-tmux-config" --plan >"$TEMP_DIR/alias-refuse.out" 2>&1; then
    fail "mismatched HOME alias accepted"
fi
grep -F 'tmux configuration HOME is unsafe or ambiguous' "$TEMP_DIR/alias-refuse.out" >/dev/null ||
    fail "mismatched HOME alias refusal"

layout_home=$TEMP_DIR/layout-home
layout_root=$TEMP_DIR/layout-persistent
mkdir -p "$layout_home" "$layout_root/local-state"
ln -s "$layout_root/local-state" "$layout_home/.local"
layout_file=$TEMP_DIR/home-layout.tsv
printf '%s\n' '# host|persistent-root|cache-root|move-large|move-fast|delete-after-backup|owner-action' \
    "local-test|$layout_root|$layout_root/cache|.local|none|none|none" >"$layout_file"
HARNESS_TEST_ALLOW_NONMAIN=1 HOME="$layout_home" HARNESS_LOGICAL_HOST=local-test \
    HARNESS_HOME_LAYOUT_FILE="$layout_file" "$ROOT/libexec/harness-tmux-config" --apply \
    >"$TEMP_DIR/layout-apply.out"
[ -L "$layout_home/.tmux.conf" ] || fail "declared local symlink apply"
layout_transaction=$(sed -n 's/.*transaction=\([^ ]*\).*/\1/p' "$TEMP_DIR/layout-apply.out")
HARNESS_TEST_ALLOW_NONMAIN=1 HOME="$layout_home" HARNESS_LOGICAL_HOST=local-test \
    HARNESS_HOME_LAYOUT_FILE="$layout_file" "$ROOT/libexec/harness-tmux-config" \
    --rollback "$layout_transaction" >"$TEMP_DIR/layout-rollback.out"
[ ! -e "$layout_home/.tmux.conf" ] && [ ! -L "$layout_home/.tmux.conf" ] ||
    fail "declared local symlink rollback"
escape_root=$TEMP_DIR/layout-escape
mkdir -p "$escape_root"
unlink "$layout_home/.local"
ln -s "$escape_root" "$layout_home/.local"
if HARNESS_TEST_ALLOW_NONMAIN=1 HOME="$layout_home" HARNESS_LOGICAL_HOST=local-test \
    HARNESS_HOME_LAYOUT_FILE="$layout_file" "$ROOT/libexec/harness-tmux-config" --apply \
    >"$TEMP_DIR/layout-escape.out" 2>&1; then
    fail "escaping local symlink accepted"
fi
grep -F 'tmux transaction state path is unsafe' "$TEMP_DIR/layout-escape.out" >/dev/null ||
    fail "escaping local symlink refusal"
[ ! -e "$layout_home/.tmux.conf" ] && [ ! -L "$layout_home/.tmux.conf" ] ||
    fail "escaping local symlink mutated live config"

printf '%s\n' 'set -g mouse on' >"$home/.tmux.conf"
chmod 640 "$home/.tmux.conf"
cp "$home/.tmux.conf" "$TEMP_DIR/prior"
if HARNESS_TEST_ALLOW_NONMAIN=1 HOME="$home" "$ROOT/libexec/harness-tmux-config" --apply \
    >"$TEMP_DIR/refuse.out" 2>&1; then
    fail "regular config accepted without adopt"
fi
HARNESS_TEST_ALLOW_NONMAIN=1 HOME="$home" "$ROOT/libexec/harness-tmux-config" --adopt --apply \
    >"$TEMP_DIR/adopt.out"
transaction=$(sed -n 's/.*transaction=\([^ ]*\).*/\1/p' "$TEMP_DIR/adopt.out")
HARNESS_TEST_ALLOW_NONMAIN=1 HOME="$home" "$ROOT/libexec/harness-tmux-config" --rollback "$transaction" \
    >"$TEMP_DIR/adopt-rollback.out"
cmp -s "$home/.tmux.conf" "$TEMP_DIR/prior" || fail "regular rollback bytes"
[ "$(stat -c %a "$home/.tmux.conf")" = 640 ] || fail "regular rollback mode"
echo 'personal tmux configuration tests: PASS'
