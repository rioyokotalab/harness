#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/harness-macos-bash-hooks-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    if [ -d "$TEMP_DIR" ]; then
        "$CLEANUP" "$HARNESS" "$TEMP_BASE" "$TEMP_DIR" "$TEMP_BASE" >/dev/null || status=1
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
real_stat=$(command -v stat)
cat >"$fake_bin/stat" <<'EOF'
#!/bin/sh
case "$1:$2" in
    -f:%u) format=%u ;;
    -f:%Lp) format=%a ;;
    -f:%l) format=%h ;;
    *) exec "$MACOS_TEST_REAL_STAT" "$@" ;;
esac
shift 2
case "$MACOS_TEST_REAL_PLATFORM" in
    Darwin)
        case "$format" in %a) format=%Lp ;; %h) format=%l ;; esac
        exec "$MACOS_TEST_REAL_STAT" -f "$format" "$@"
        ;;
    *) exec "$MACOS_TEST_REAL_STAT" -c "$format" "$@" ;;
esac
EOF
chmod 755 "$fake_bin/uname" "$fake_bin/stat"
real_platform=$(uname -s)
printf '%s\n' 'export MAC_LOCAL=profile' >"$home/.bash_profile"
printf '%s\n' 'export MAC_LOCAL=bashrc' >"$home/.bashrc"
cat "$ROOT/shell/personal-macos-startup.block" >>"$home/.bashrc"
chmod 640 "$home/.bash_profile" "$home/.bashrc"
cp "$home/.bash_profile" "$TEMP_DIR/profile.before"
cp "$home/.bashrc" "$TEMP_DIR/bashrc.before"

PATH="$fake_bin:$PATH" MACOS_TEST_REAL_STAT="$real_stat" MACOS_TEST_REAL_PLATFORM="$real_platform" HARNESS_TEST_ALLOW_NONMAIN=1 HOME="$home" \
    "$ROOT/libexec/harness-macos-bash-hooks" --host office --plan >"$TEMP_DIR/plan.out"
grep -F 'state=legacy action=wrap' "$TEMP_DIR/plan.out" >/dev/null || fail "legacy plan"
PATH="$fake_bin:$PATH" MACOS_TEST_REAL_STAT="$real_stat" MACOS_TEST_REAL_PLATFORM="$real_platform" HARNESS_TEST_ALLOW_NONMAIN=1 HOME="$home" \
    "$ROOT/libexec/harness-macos-bash-hooks" --host office --apply >"$TEMP_DIR/apply.out"
for startup in .bash_profile .bashrc; do
    [ "$(sed -n '1p' "$home/$startup")" = '# >>> harness early managed >>>' ] || fail "$startup prefix"
    grep -F 'HARNESS_LOGICAL_HOST=office' "$home/$startup" >/dev/null || fail "$startup identity"
    tail -n 6 "$home/$startup" | grep -F '# <<< harness managed <<<' >/dev/null || fail "$startup suffix"
done
grep -F 'export MAC_LOCAL=bashrc' "$home/.bashrc" >/dev/null || fail "local middle retained"
if grep -F 'personal macOS Bash v1' "$home/.bashrc" >/dev/null; then fail "legacy loader retained"; fi
case "$real_platform" in
    Darwin) bashrc_mode=$(stat -f %Lp "$home/.bashrc") ;;
    *) bashrc_mode=$(stat -c %a "$home/.bashrc") ;;
esac
[ "$bashrc_mode" = 640 ] || fail "mode retained"
transaction=$(sed -n 's/.*transaction=\([^ ]*\).*/\1/p' "$TEMP_DIR/apply.out")
[ -n "$transaction" ] || fail "transaction identifier"
PATH="$fake_bin:$PATH" MACOS_TEST_REAL_STAT="$real_stat" MACOS_TEST_REAL_PLATFORM="$real_platform" HARNESS_TEST_ALLOW_NONMAIN=1 HOME="$home" \
    "$ROOT/libexec/harness-macos-bash-hooks" --rollback "$transaction" >"$TEMP_DIR/rollback.out"
cmp -s "$home/.bash_profile" "$TEMP_DIR/profile.before" || fail "profile rollback"
cmp -s "$home/.bashrc" "$TEMP_DIR/bashrc.before" || fail "bashrc rollback"

# Owner content appended after an otherwise exact managed suffix can be moved
# back into the preserved local middle without changing its bytes.
PATH="$fake_bin:$PATH" MACOS_TEST_REAL_STAT="$real_stat" MACOS_TEST_REAL_PLATFORM="$real_platform" HARNESS_TEST_ALLOW_NONMAIN=1 HOME="$home" \
    "$ROOT/libexec/harness-macos-bash-hooks" --host office --apply >"$TEMP_DIR/reapply.out"
printf '%s\n' 'export OWNER_AFTER_SUFFIX=retained' >>"$home/.bash_profile"
cp "$home/.bash_profile" "$TEMP_DIR/profile.drifted"
PATH="$fake_bin:$PATH" MACOS_TEST_REAL_STAT="$real_stat" MACOS_TEST_REAL_PLATFORM="$real_platform" HARNESS_TEST_ALLOW_NONMAIN=1 HOME="$home" \
    "$ROOT/libexec/harness-macos-bash-hooks" --host office --plan >"$TEMP_DIR/relocate-plan.out"
grep -F 'file=.bash_profile state=relocatable action=rewrap' "$TEMP_DIR/relocate-plan.out" >/dev/null ||
    fail "relocatable suffix plan"
PATH="$fake_bin:$PATH" MACOS_TEST_REAL_STAT="$real_stat" MACOS_TEST_REAL_PLATFORM="$real_platform" HARNESS_TEST_ALLOW_NONMAIN=1 HOME="$home" \
    "$ROOT/libexec/harness-macos-bash-hooks" --host office --apply >"$TEMP_DIR/relocate-apply.out"
grep -F -x 'export OWNER_AFTER_SUFFIX=retained' "$home/.bash_profile" >/dev/null ||
    fail "relocatable owner content retained"
tail -n 1 "$home/.bash_profile" | grep -F -x '# <<< harness managed <<<' >/dev/null ||
    fail "relocatable suffix restored"
relocate_transaction=$(sed -n 's/.*transaction=\([^ ]*\).*/\1/p' "$TEMP_DIR/relocate-apply.out")
[ -n "$relocate_transaction" ] || fail "relocatable transaction identifier"
PATH="$fake_bin:$PATH" MACOS_TEST_REAL_STAT="$real_stat" MACOS_TEST_REAL_PLATFORM="$real_platform" HARNESS_TEST_ALLOW_NONMAIN=1 HOME="$home" \
    "$ROOT/libexec/harness-macos-bash-hooks" --rollback "$relocate_transaction" >"$TEMP_DIR/relocate-rollback.out"
cmp -s "$home/.bash_profile" "$TEMP_DIR/profile.drifted" || fail "relocatable rollback"
echo 'personal macOS Bash-hook tests: PASS'
