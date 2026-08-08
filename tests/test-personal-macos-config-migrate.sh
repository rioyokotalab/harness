#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/harness-macos-config-migrate-test.XXXXXX")
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
    -f:%u) native_format=%u ;;
    -f:%Lp) native_format=%a ;;
    -f:%l) native_format=%h ;;
    *) exec "$MACOS_TEST_REAL_STAT" "$@" ;;
esac
shift 2
case $(/usr/bin/uname -s) in
    Darwin)
        case "$native_format" in %a) native_format=%Lp ;; %h) native_format=%l ;; esac
        exec "$MACOS_TEST_REAL_STAT" -f "$native_format" "$@"
        ;;
    *) exec "$MACOS_TEST_REAL_STAT" -c "$native_format" "$@" ;;
esac
EOF
chmod 755 "$fake_bin/uname" "$fake_bin/stat"

mkdir -p "$public/libexec" "$public/profiles/personal-macos" \
    "$public/config/ssh" "$public/config/tmux" "$public/shell" \
    "$public/shared/skills/guarded-bulk-delete/scripts"
cp "$ROOT/libexec/harness-common" "$ROOT/libexec/harness-macos-common" \
    "$ROOT/libexec/harness-macos-profile" \
    "$ROOT/libexec/harness-macos-config-migrate" \
    "$ROOT/libexec/harness-macos-ssh-sync" \
    "$ROOT/libexec/harness-ssh-config-layout" \
    "$ROOT/libexec/harness-macos-bash-hooks" \
    "$ROOT/libexec/harness-tmux-config" "$public/libexec/"
cp "$ROOT/profiles/personal-macos/base.conf" \
    "$ROOT/profiles/personal-macos/formula-policy-v4.conf" \
    "$public/profiles/personal-macos/"
cp "$ROOT/config/ssh/harness.conf" "$public/config/ssh/"
cp "$ROOT/config/tmux/tmux.conf" "$public/config/tmux/"
cp "$ROOT/shell/personal-macos.bash" \
    "$ROOT/shell/personal-macos-startup.block" \
    "$ROOT/shell/bash_profile.block" "$ROOT/shell/bashrc.block" \
    "$public/shell/"
cp "$ROOT/shared/skills/guarded-bulk-delete/scripts/guarded-delete" \
    "$public/shared/skills/guarded-bulk-delete/scripts/"
git -C "$public" init -q -b main
git -C "$public" add .
git -C "$public" -c user.name=Fixture -c user.email=fixture.invalid \
    commit -q -m fixture
git init -q --bare "$private_remote"
mkdir -p "$home/.config/harness" "$home/.ssh" "$home/.local/state/harness/personal-macos"
mkdir "$private"
git -C "$private" init -q -b main
git -C "$private" remote add origin "$private_remote"
git -C "$private" config user.name Fixture
git -C "$private" config user.email fixture.invalid
mkdir "$private/hosts"
cp "$ROOT/tests/fixtures/personal-macos/private-v2/companion.conf" "$private/companion.conf"
cp "$ROOT/tests/fixtures/personal-macos/private-v1/ssh_config" "$private/ssh_config"
cp "$ROOT/tests/fixtures/personal-macos/private-v2/bashrc" "$private/bashrc"
: >"$private/tmux.conf"
cp "$ROOT/tests/fixtures/personal-macos/private-v1/hosts/mac-test-pilot.conf" \
    "$private/hosts/office.conf"
case $(uname -s) in
    Darwin) sed -i '' 's/mac-test-pilot/office/' "$private/hosts/office.conf" ;;
    *) sed -i 's/mac-test-pilot/office/' "$private/hosts/office.conf" ;;
esac
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
env PATH="$fake_bin:$PATH" MACOS_TEST_REAL_STAT="$real_stat" HOME="$home" \
    HARNESS_ROOT="$public" "$public/libexec/harness-macos-config-migrate" \
    --host office --plan >"$TEMP_DIR/plan.out" 2>&1 || {
        sed -n '1,220p' "$TEMP_DIR/plan.out" >&2
        fail "legacy migration plan command"
    }
grep -F 'private_layout=legacy action=migrate apply=not-requested' "$TEMP_DIR/plan.out" >/dev/null ||
    fail "legacy migration plan"
echo 'personal macOS configuration migration plan: PASS'
