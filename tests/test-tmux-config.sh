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
