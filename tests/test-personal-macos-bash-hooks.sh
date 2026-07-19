#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/harness-macos-bash-hooks-test.XXXXXX")
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

fake_bin=$TEMP_DIR/bin
home=$TEMP_DIR/home
mkdir "$fake_bin" "$home"
cat >"$fake_bin/uname" <<'EOF'
#!/bin/sh
echo Darwin
EOF
chmod 755 "$fake_bin/uname"
printf '%s\n' 'export MAC_LOCAL=profile' >"$home/.bash_profile"
printf '%s\n' 'export MAC_LOCAL=bashrc' >"$home/.bashrc"
cat "$ROOT/shell/personal-macos-startup.block" >>"$home/.bashrc"
chmod 640 "$home/.bash_profile" "$home/.bashrc"
cp "$home/.bash_profile" "$TEMP_DIR/profile.before"
cp "$home/.bashrc" "$TEMP_DIR/bashrc.before"

PATH="$fake_bin:$PATH" HARNESS_TEST_ALLOW_NONMAIN=1 HOME="$home" \
    "$ROOT/libexec/harness-macos-bash-hooks" --host office --plan >"$TEMP_DIR/plan.out"
grep -F 'state=legacy action=wrap' "$TEMP_DIR/plan.out" >/dev/null || fail "legacy plan"
PATH="$fake_bin:$PATH" HARNESS_TEST_ALLOW_NONMAIN=1 HOME="$home" \
    "$ROOT/libexec/harness-macos-bash-hooks" --host office --apply >"$TEMP_DIR/apply.out"
for startup in .bash_profile .bashrc; do
    [ "$(sed -n '1p' "$home/$startup")" = '# >>> harness early managed >>>' ] || fail "$startup prefix"
    grep -F 'HARNESS_LOGICAL_HOST=office' "$home/$startup" >/dev/null || fail "$startup identity"
    tail -n 6 "$home/$startup" | grep -F '# <<< harness managed <<<' >/dev/null || fail "$startup suffix"
done
grep -F 'export MAC_LOCAL=bashrc' "$home/.bashrc" >/dev/null || fail "local middle retained"
if grep -F 'personal macOS Bash v1' "$home/.bashrc" >/dev/null; then fail "legacy loader retained"; fi
[ "$(stat -c %a "$home/.bashrc")" = 640 ] || fail "mode retained"
transaction=$(sed -n 's/.*transaction=\([^ ]*\).*/\1/p' "$TEMP_DIR/apply.out")
[ -n "$transaction" ] || fail "transaction identifier"
PATH="$fake_bin:$PATH" HARNESS_TEST_ALLOW_NONMAIN=1 HOME="$home" \
    "$ROOT/libexec/harness-macos-bash-hooks" --rollback "$transaction" >"$TEMP_DIR/rollback.out"
cmp -s "$home/.bash_profile" "$TEMP_DIR/profile.before" || fail "profile rollback"
cmp -s "$home/.bashrc" "$TEMP_DIR/bashrc.before" || fail "bashrc rollback"
echo 'personal macOS Bash-hook tests: PASS'
