#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/harness-macos-config-migrate-test.XXXXXX")
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
fake_bin=$TEMP_DIR/bin
public=$TEMP_DIR/public
home=$TEMP_DIR/home
private_remote=$TEMP_DIR/private.git
private=$home/.config/harness/private
mkdir "$fake_bin" "$home"
cat >"$fake_bin/uname" <<'EOF'
#!/bin/sh
echo Darwin
EOF
real_stat=$(command -v stat)
cat >"$fake_bin/stat" <<'EOF'
#!/bin/sh
case "$1:$2" in
    -f:%u) shift 2; exec "$MACOS_TEST_REAL_STAT" -c %u "$@" ;;
    -f:%Lp) shift 2; exec "$MACOS_TEST_REAL_STAT" -c %a "$@" ;;
    -f:%l) shift 2; exec "$MACOS_TEST_REAL_STAT" -c %h "$@" ;;
    *) exec "$MACOS_TEST_REAL_STAT" "$@" ;;
esac
EOF
chmod 755 "$fake_bin/uname" "$fake_bin/stat"

git clone -q "$ROOT" "$public"
git -C "$public" branch -m main
git -C "$public" config branch.main.remote origin
git -C "$public" config branch.main.merge refs/heads/main
git init -q --bare "$private_remote"
mkdir -p "$home/.config/harness" "$home/.ssh" "$home/.local/state/harness/personal-macos"
git clone -q "$private_remote" "$private"
git -C "$private" switch -q -c main
mkdir "$private/hosts"
cp "$ROOT/tests/fixtures/personal-macos/private-v2/companion.conf" "$private/companion.conf"
cp "$ROOT/tests/fixtures/personal-macos/private-v1/ssh_config" "$private/ssh_config"
cp "$ROOT/tests/fixtures/personal-macos/private-v2/bashrc" "$private/bashrc"
: >"$private/tmux.conf"
cp "$ROOT/tests/fixtures/personal-macos/private-v1/hosts/mac-test-pilot.conf" \
    "$private/hosts/office.conf"
sed -i 's/mac-test-pilot/office/' "$private/hosts/office.conf"
chmod 700 "$private" "$private/.git" "$private/hosts"
chmod 600 "$private/companion.conf" "$private/ssh_config" "$private/bashrc" \
    "$private/tmux.conf" "$private/hosts/office.conf"
git -C "$private" add companion.conf ssh_config bashrc tmux.conf hosts/office.conf
git -C "$private" -c user.name=Fixture -c user.email=fixture.invalid commit -q -m fixture
git -C "$private" push -q -u origin main

cp "$private/ssh_config" "$home/.ssh/config"
chmod 600 "$home/.ssh/config"
mkdir -p "$home/.config/harness/managed"
chmod 700 "$home/.config/harness/managed" "$home/.local/state/harness" \
    "$home/.local/state/harness/personal-macos"
: >"$home/.config/harness/managed/personal-macos-private.bash"
chmod 600 "$home/.config/harness/managed/personal-macos-private.bash"
ln -s "$public/shell/personal-macos.bash" \
    "$home/.config/harness/managed/personal-macos.bash"
printf '%s\n' 'export MAC_LOCAL=profile' >"$home/.bash_profile"
printf '%s\n' 'export MAC_LOCAL=bashrc' >"$home/.bashrc"
cat "$public/shell/personal-macos-startup.block" >>"$home/.bash_profile"
cat "$public/shell/personal-macos-startup.block" >>"$home/.bashrc"
chmod 600 "$home/.bash_profile" "$home/.bashrc"
: >"$home/.tmux.conf"; chmod 600 "$home/.tmux.conf"
printf '%s\n' 'synthetic-config-state' >"$home/.local/state/harness/personal-macos/config-sync.conf"
printf '%s\n' 'synthetic-config-status' >"$home/.local/state/harness/personal-macos/config-sync-status.conf"
chmod 600 "$home/.local/state/harness/personal-macos/config-sync.conf" \
    "$home/.local/state/harness/personal-macos/config-sync-status.conf"
cp "$home/.bash_profile" "$TEMP_DIR/profile.before"
cp "$home/.bashrc" "$TEMP_DIR/bashrc.before"

env PATH="$fake_bin:$PATH" MACOS_TEST_REAL_STAT="$real_stat" HOME="$home" \
    HARNESS_ROOT="$public" sh -x "$public/libexec/harness-macos-config-migrate" \
    --host office --plan >"$TEMP_DIR/plan.out" 2>&1 || {
        sed -n '1,80p' "$TEMP_DIR/plan.out" >&2
        fail "legacy migration plan command"
    }
grep -F 'private_layout=legacy action=migrate apply=not-requested' "$TEMP_DIR/plan.out" >/dev/null ||
    fail "legacy migration plan"
env PATH="$fake_bin:$PATH" MACOS_TEST_REAL_STAT="$real_stat" HOME="$home" \
    HARNESS_ROOT="$public" "$public/libexec/harness-macos-config-migrate" \
    --host office --apply >"$TEMP_DIR/apply.out" 2>&1 || {
        sed -n '1,80p' "$TEMP_DIR/apply.out" >&2
        fail "legacy migration apply command"
    }
transaction=$(sed -n 's/.*transaction=\([^ ]*\).*/\1/p' "$TEMP_DIR/apply.out")
[ -n "$transaction" ] || fail "migration transaction"
[ -L "$home/.tmux.conf" ] && [ "$(readlink "$home/.tmux.conf")" = "$public/config/tmux/tmux.conf" ] ||
    fail "migrated tmux symlink"
grep -F 'HARNESS_LOGICAL_HOST=office' "$home/.bashrc" >/dev/null || fail "migrated Bash prefix"
[ ! -e "$home/.config/harness/managed/personal-macos-private.bash" ] || fail "private fragment retained"
[ ! -L "$home/.config/harness/managed/personal-macos.bash" ] || fail "legacy loader retained"
[ ! -e "$home/.local/state/harness/personal-macos/config-sync.conf" ] || fail "bundle state retained"
git --git-dir="$private_remote" ls-tree -r --name-only main >"$TEMP_DIR/private-tree"
grep -F -x ssh_config "$TEMP_DIR/private-tree" >/dev/null || fail "SSH payload missing"
if grep -E '^(bashrc|tmux\.conf)$' "$TEMP_DIR/private-tree" >/dev/null; then fail "retired payload remains"; fi

env PATH="$fake_bin:$PATH" MACOS_TEST_REAL_STAT="$real_stat" HOME="$home" \
    HARNESS_ROOT="$public" "$public/libexec/harness-macos-config-migrate" \
    --rollback "$transaction" >"$TEMP_DIR/rollback.out"
cmp -s "$home/.bash_profile" "$TEMP_DIR/profile.before" || fail "profile rollback"
cmp -s "$home/.bashrc" "$TEMP_DIR/bashrc.before" || fail "bashrc rollback"
[ -f "$home/.tmux.conf" ] && [ ! -L "$home/.tmux.conf" ] && [ ! -s "$home/.tmux.conf" ] ||
    fail "tmux rollback"
[ -f "$home/.config/harness/managed/personal-macos-private.bash" ] || fail "fragment rollback"
[ -L "$home/.config/harness/managed/personal-macos.bash" ] || fail "loader rollback"
[ -f "$home/.local/state/harness/personal-macos/config-sync.conf" ] || fail "state rollback"
git --git-dir="$private_remote" ls-tree -r --name-only main >"$TEMP_DIR/private-tree-after"
if grep -E '^(bashrc|tmux\.conf)$' "$TEMP_DIR/private-tree-after" >/dev/null; then
    fail "rollback rewound private history"
fi
echo 'personal macOS configuration migration tests: PASS'
