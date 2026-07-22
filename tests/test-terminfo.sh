#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/harness-terminfo-test.XXXXXX")

fail() { echo "FAIL: $*" >&2; exit 1; }
cleanup() {
    result=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEST_ROOT" ]; then
        "$CLEANUP" "$HARNESS" "$TEMP_BASE" "$TEST_ROOT" \
            "$TEMP_BASE" >/dev/null || cleanup_failed=1
    fi
    [ "$result" -ne 0 ] || [ "$cleanup_failed" -eq 0 ] || result=1
    exit "$result"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

home=$TEST_ROOT/home
mkdir "$home"
chmod 700 "$home"

if HOME="$home" HARNESS_LOGICAL_HOST=local \
    "$HARNESS" terminfo --host al --plan >"$TEST_ROOT/wrong-host.out" 2>&1; then
    fail "wrong logical host accepted"
fi
grep -F 'logical host does not match this environment' \
    "$TEST_ROOT/wrong-host.out" >/dev/null || fail "wrong-host refusal"

plan=$(HOME="$home" HARNESS_LOGICAL_HOST=al \
    "$HARNESS" terminfo --host al --plan)
printf '%s\n' "$plan" | grep -F \
    'TERMINFO mode=plan host=al entry=tmux-256color state=missing action=install' \
    >/dev/null || fail "missing-entry plan"

apply=$(HOME="$home" HARNESS_LOGICAL_HOST=al \
    "$HARNESS" terminfo --host al --apply)
transaction=$(printf '%s\n' "$apply" |
    sed -n 's/^TERMINFO action=applied transaction=\([^ ]*\) rollback=available$/\1/p')
[ -n "$transaction" ] || fail "apply transaction"
entry=$(find "$home/.terminfo" -mindepth 2 -maxdepth 2 -type f \
    -name tmux-256color -print)
[ "$(printf '%s\n' "$entry" | awk 'NF { n++ } END { print n + 0 }')" -eq 1 ] ||
    fail "installed entry layout"
HOME="$home" TERM=tmux-256color TERMINFO="$home/.terminfo" tput colors \
    >/dev/null || fail "installed entry discovery"

current=$(HOME="$home" HARNESS_LOGICAL_HOST=al \
    "$HARNESS" terminfo --host al --plan)
printf '%s\n' "$current" | grep -F 'state=current action=none' >/dev/null ||
    fail "current-entry plan"

fake_bin=$TEST_ROOT/fake-bin
mkdir "$fake_bin"
real_infocmp=$(command -v infocmp)
cat >"$fake_bin/infocmp" <<'EOF'
#!/bin/sh
"$REAL_INFOCMP" "$@" | sed 's/Smulx=\\E\[4:/Smulx=\\E[4\\:/'
EOF
chmod 755 "$fake_bin/infocmp"
escaped_current=$(HOME="$home" HARNESS_LOGICAL_HOST=al REAL_INFOCMP="$real_infocmp" \
    PATH="$fake_bin:/usr/bin:/bin" "$HARNESS" terminfo --host al --plan)
printf '%s\n' "$escaped_current" | grep -F 'state=current action=none' >/dev/null ||
    fail "ncurses colon-escape normalization"

cp "$entry" "$TEST_ROOT/entry.backup"
printf 'x' >>"$entry"
if HOME="$home" HARNESS_LOGICAL_HOST=al \
    "$HARNESS" terminfo --host al --rollback "$transaction" \
    >"$TEST_ROOT/changed.out" 2>&1; then
    fail "changed installed entry rollback accepted"
fi
grep -F 'installed terminfo entry changed; rollback refused' \
    "$TEST_ROOT/changed.out" >/dev/null || fail "changed-entry refusal"
cp "$TEST_ROOT/entry.backup" "$entry"
chmod 600 "$entry"

rollback=$(HOME="$home" HARNESS_LOGICAL_HOST=al \
    "$HARNESS" terminfo --host al --rollback "$transaction")
[ "$rollback" = "TERMINFO action=rolled-back transaction=$transaction" ] ||
    fail "rollback result"
[ ! -e "$home/.terminfo" ] && [ ! -L "$home/.terminfo" ] ||
    fail "rollback directory restoration"

symlink_home=$TEST_ROOT/symlink-home
symlink_persistent=$TEST_ROOT/symlink-persistent
symlink_layout=$TEST_ROOT/home-layout.tsv
mkdir "$symlink_home" "$symlink_persistent"
mkdir "$symlink_persistent/.local"
chmod 700 "$symlink_home" "$symlink_persistent" "$symlink_persistent/.local"
ln -s "$symlink_persistent/.local" "$symlink_home/.local"
printf 'al|%s|%s|.local|none|none|none\n' "$symlink_persistent" \
    "$symlink_persistent/cache" >"$symlink_layout"
symlink_apply=$(HOME="$symlink_home" HARNESS_LOGICAL_HOST=al \
    HARNESS_HOME_LAYOUT_FILE="$symlink_layout" \
    "$HARNESS" terminfo --host al --apply)
symlink_transaction=$(printf '%s\n' "$symlink_apply" |
    sed -n 's/^TERMINFO action=applied transaction=\([^ ]*\) rollback=available$/\1/p')
[ -n "$symlink_transaction" ] || fail "declared symlink apply"
[ -d "$symlink_persistent/.local/state/harness/transactions" ] ||
    fail "declared symlink state location"
HOME="$symlink_home" HARNESS_LOGICAL_HOST=al \
    HARNESS_HOME_LAYOUT_FILE="$symlink_layout" \
    "$HARNESS" terminfo --host al --rollback "$symlink_transaction" >/dev/null ||
    fail "declared symlink rollback"

unsafe_home=$TEST_ROOT/unsafe-home
unsafe_target=$TEST_ROOT/unsafe-target
mkdir "$unsafe_home" "$unsafe_target"
chmod 700 "$unsafe_home" "$unsafe_target"
ln -s "$unsafe_target" "$unsafe_home/.local"
if HOME="$unsafe_home" HARNESS_LOGICAL_HOST=al \
    HARNESS_HOME_LAYOUT_FILE="$symlink_layout" \
    "$HARNESS" terminfo --host al --apply >"$TEST_ROOT/unsafe.out" 2>&1; then
    fail "undeclared state symlink accepted"
fi
grep -F 'terminfo transaction state is unsafe' "$TEST_ROOT/unsafe.out" >/dev/null ||
    fail "undeclared state symlink refusal"

echo "terminfo tests passed"
