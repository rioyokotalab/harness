#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
MACOS_BASH=$ROOT/libexec/harness-macos-bash
LAUNCHER=$ROOT/bin/harness-bash
FIXTURE=$ROOT/tests/fixtures/personal-macos/private-v1
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/harness-macos-bash-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEMP_DIR" ]; then
        "$CLEANUP" "$HARNESS" "$TEMP_BASE" "$TEMP_DIR" \
            "$TEMP_BASE" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then
        echo "FAIL: guarded personal-Mac Bash cleanup" >&2
        status=1
    fi
    exit "$status"
}

trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

file_mode() {
    case $(uname -s) in
        Darwin) /usr/bin/stat -f '%Lp' "$1" ;;
        *) /usr/bin/stat -c '%a' -- "$1" ;;
    esac
}

file_inode() {
    case $(uname -s) in
        Darwin) /usr/bin/stat -f '%i' "$1" ;;
        *) /usr/bin/stat -c '%i' -- "$1" ;;
    esac
}

PUBLIC=$TEMP_DIR/public
mkdir -p "$PUBLIC/bin" "$PUBLIC/shell" "$PUBLIC/profiles/personal-macos"
cp "$ROOT/bin/harness-bash" "$PUBLIC/bin/harness-bash"
cp "$ROOT/shell/personal-macos.bash" "$PUBLIC/shell/personal-macos.bash"
cp "$ROOT/shell/personal-macos-startup.block" \
    "$PUBLIC/shell/personal-macos-startup.block"
cp "$ROOT/profiles/personal-macos/base.conf" \
    "$PUBLIC/profiles/personal-macos/base.conf"
git -C "$PUBLIC" init -q -b main
git -C "$PUBLIC" config user.name mac-test
git -C "$PUBLIC" config user.email mac-test.invalid
git -C "$PUBLIC" add .
git -C "$PUBLIC" commit -q -m 'synthetic public Bash integration'

FAKE_PREFIX=$TEMP_DIR/homebrew-prefix
FAKE_BASH_PREFIX=$FAKE_PREFIX/Cellar/bash/5.3.0
FAKE_BIN=$TEMP_DIR/fake-bin
mkdir -p "$FAKE_PREFIX/bin" "$FAKE_BASH_PREFIX/bin" "$FAKE_BIN"
cat >"$FAKE_BIN/uname" <<'EOF'
#!/bin/sh
case "${1:-}" in -s) echo Darwin ;; -m) echo arm64 ;; *) exit 2 ;; esac
EOF
cat >"$FAKE_BIN/stat" <<'EOF'
#!/bin/sh
case "${1:-}:${2:-}" in
    -f:%u) native_format=%u ;;
    -f:%Lp) native_format=%a ;;
    -f:%l) native_format=%h ;;
    *) exec /usr/bin/stat "$@" ;;
esac
shift 2; [ "${1:-}" = -- ] && shift
case $(/usr/bin/uname -s) in
    Darwin)
        case "$native_format" in %a) native_format=%Lp ;; %h) native_format=%l ;; esac
        exec /usr/bin/stat -f "$native_format" "$@"
        ;;
    *) exec /usr/bin/stat -c "$native_format" -- "$@" ;;
esac
EOF
cat >"$FAKE_PREFIX/bin/brew" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$BREW_LOG"
case "$1:$2" in
    --prefix:)
        printf '%s\n' "${FAKE_PREFIX_OVERRIDE:-$FAKE_BREW_PREFIX}"
        ;;
    --prefix:bash)
        printf '%s\n' "$FAKE_BASH_PREFIX"
        ;;
    list:--formula)
        [ "$3:$4" = --versions:bash ] || exit 91
        printf '%s\n' 'bash 5.3.0'
        ;;
    *) exit 92 ;;
esac
EOF
cat >"$FAKE_BASH_PREFIX/bin/bash" <<'EOF'
#!/bin/sh
printf 'args=%s\n' "$*" >>"$BASH_LAUNCH_LOG"
printf 'managed=%s\n' "${HARNESS_PERSONAL_MACOS_BASH:-}" >>"$BASH_LAUNCH_LOG"
printf 'path=%s\n' "$PATH" >>"$BASH_LAUNCH_LOG"
EOF
cat >"$FAKE_BIN/ln" <<'EOF'
#!/bin/sh
last=
for argument do last=$argument; done
if [ -n "${MACOS_BASH_FAIL_LINK:-}" ] && [ "$last" = "$MACOS_BASH_FAIL_LINK" ]; then
    echo 'injected managed Bash link failure' >&2
    exit 73
fi
exec /bin/ln "$@"
EOF
chmod 755 "$FAKE_BIN/uname" "$FAKE_BIN/stat" "$FAKE_BIN/ln" \
    "$FAKE_PREFIX/bin/brew" "$FAKE_BASH_PREFIX/bin/bash"

make_home() {
    name=$1
    home=$TEMP_DIR/$name
    private=$home/.config/harness/private
    mkdir -p "$private/hosts"
    cp "$FIXTURE/companion.conf" "$private/companion.conf"
    cp "$FIXTURE/hosts/mac-test-pilot.conf" \
        "$private/hosts/mac-test-pilot.conf"
    chmod 700 "$home" "$home/.config" "$home/.config/harness" \
        "$private" "$private/hosts"
    chmod 600 "$private/companion.conf" \
        "$private/hosts/mac-test-pilot.conf"
    git -C "$private" init -q -b main
    git -C "$private" config user.name mac-test
    git -C "$private" config user.email mac-test.invalid
    git -C "$private" add companion.conf hosts/mac-test-pilot.conf
    git -C "$private" commit -q -m 'synthetic private Bash profile'
    chmod 700 "$private/.git"
    printf '%s\n' "$home"
}

run_macos_bash() {
    test_home=$1
    test_log=$2
    shift 2
    HOME="$test_home" HARNESS_ROOT="$PUBLIC" BREW_LOG="$test_log" \
        FAKE_BREW_PREFIX="$FAKE_PREFIX" FAKE_BASH_PREFIX="$FAKE_BASH_PREFIX" \
        PATH="$FAKE_PREFIX/bin:$FAKE_BIN:/usr/bin:/bin" "$MACOS_BASH" "$@"
}

launcher_home=$(make_home launcher)
launcher_log=$TEMP_DIR/launcher-brew.log
bash_launch_log=$TEMP_DIR/launcher-bash.log
HOME="$launcher_home" BREW_LOG="$launcher_log" \
    BASH_LAUNCH_LOG="$bash_launch_log" FAKE_BREW_PREFIX="$FAKE_PREFIX" \
    FAKE_BASH_PREFIX="$FAKE_BASH_PREFIX" \
    PATH="$FAKE_PREFIX/bin:$FAKE_BIN:/usr/bin:/bin" "$LAUNCHER"
grep -F -x 'args=--login' "$bash_launch_log" >/dev/null ||
    fail "launcher default login argument"
grep -F -x 'managed=1' "$bash_launch_log" >/dev/null ||
    fail "launcher managed marker"
grep -F "path=$launcher_home/.local/bin:" "$bash_launch_log" >/dev/null ||
    fail "launcher managed path"
if grep -E '^(update|install|upgrade|cleanup|services|tap|bundle)( |$)' \
    "$launcher_log" >/dev/null; then
    fail "launcher performed a Homebrew mutation"
fi
HOME="$launcher_home" BREW_LOG="$TEMP_DIR/launcher-explicit-brew.log" \
    BASH_LAUNCH_LOG="$TEMP_DIR/launcher-explicit-bash.log" \
    FAKE_BREW_PREFIX="$FAKE_PREFIX" FAKE_BASH_PREFIX="$FAKE_BASH_PREFIX" \
    PATH="$FAKE_PREFIX/bin:$FAKE_BIN:/usr/bin:/bin" \
    "$LAUNCHER" -lc 'printf synthetic'
grep -F -x 'args=-lc printf synthetic' \
    "$TEMP_DIR/launcher-explicit-bash.log" >/dev/null ||
    fail "launcher explicit arguments"
if HOME="$launcher_home" BREW_LOG="$TEMP_DIR/launcher-mismatch.log" \
    BASH_LAUNCH_LOG="$TEMP_DIR/launcher-mismatch-bash.log" \
    FAKE_BREW_PREFIX="$FAKE_PREFIX" FAKE_BASH_PREFIX="$FAKE_BASH_PREFIX" \
    FAKE_PREFIX_OVERRIDE="$TEMP_DIR/other-prefix" \
    PATH="$FAKE_PREFIX/bin:$FAKE_BIN:/usr/bin:/bin" "$LAUNCHER" \
    >"$TEMP_DIR/launcher-mismatch.out" 2>&1; then
    fail "launcher accepted a Homebrew prefix mismatch"
fi
grep -F 'executable/prefix mismatch' "$TEMP_DIR/launcher-mismatch.out" >/dev/null ||
    fail "launcher prefix mismatch refusal"

basic_home=$(make_home basic)
printf '%s' '# owner rc without final newline' >"$basic_home/.bashrc"
chmod 640 "$basic_home/.bashrc"
basic_inode=$(file_inode "$basic_home/.bashrc")
cp "$basic_home/.bashrc" "$TEMP_DIR/basic-original-rc"
basic_log=$TEMP_DIR/basic-brew.log
run_macos_bash "$basic_home" "$basic_log" --host mac-test-pilot --plan \
    >"$TEMP_DIR/basic.plan"
grep -F -x 'APPEND startup=.bash_profile position=end preserves=bytes-mode-acl' \
    "$TEMP_DIR/basic.plan" >/dev/null || fail "new profile plan"
grep -F -x 'APPEND startup=.bashrc position=end preserves=bytes-mode-acl' \
    "$TEMP_DIR/basic.plan" >/dev/null || fail "existing rc plan"
[ ! -e "$basic_home/.local" ] || fail "managed Bash plan mutated state"
cmp -s "$basic_home/.bashrc" "$TEMP_DIR/basic-original-rc" ||
    fail "managed Bash plan changed owner rc"

run_macos_bash "$basic_home" "$basic_log" --host mac-test-pilot --apply \
    >"$TEMP_DIR/basic.apply"
basic_tx=$(sed -n 's/^TRANSACTION id=\([^ ]*\) status=complete/\1/p' \
    "$TEMP_DIR/basic.apply")
[ -n "$basic_tx" ] || fail "managed Bash transaction identifier"
[ -L "$basic_home/.local/bin/harness-bash" ] &&
    [ "$(readlink "$basic_home/.local/bin/harness-bash")" = \
        "$PUBLIC/bin/harness-bash" ] || fail "managed Bash launcher link"
[ -L "$basic_home/.config/harness/managed/personal-macos.bash" ] &&
    [ "$(readlink "$basic_home/.config/harness/managed/personal-macos.bash")" = \
        "$PUBLIC/shell/personal-macos.bash" ] || fail "managed Bash loader link"
[ "$(file_mode "$basic_home/.bashrc")" = 640 ] ||
    fail "managed Bash changed existing rc mode"
[ "$(file_inode "$basic_home/.bashrc")" = "$basic_inode" ] ||
    fail "managed Bash replaced the existing rc inode"
[ "$(file_mode "$basic_home/.bash_profile")" = 600 ] ||
    fail "managed Bash new profile mode"
head -c "$(wc -c <"$TEMP_DIR/basic-original-rc" | tr -d ' ')" \
    "$basic_home/.bashrc" | cmp -s - "$TEMP_DIR/basic-original-rc" ||
    fail "managed Bash changed existing rc bytes"
[ "$(grep -F -x -c '# >>> harness personal macOS Bash v1 >>>' \
    "$basic_home/.bashrc")" -eq 1 ] || fail "managed Bash rc marker count"
[ "$(grep -F -x -c '# >>> harness personal macOS Bash v1 >>>' \
    "$basic_home/.bash_profile")" -eq 1 ] || fail "managed Bash profile marker count"

interactive_output=$(HOME="$basic_home" PATH=/usr/bin:/bin \
    /bin/bash --rcfile "$basic_home/.bashrc" -ic \
    'printf "loaded=%s\npath=%s\n" "$HARNESS_PERSONAL_MACOS_LOADER_LOADED" "$PATH"' \
    2>/dev/null)
printf '%s\n' "$interactive_output" | grep -F -x 'loaded=1' >/dev/null ||
    fail "fresh interactive Bash loader"
printf '%s\n' "$interactive_output" | grep -F \
    "path=$basic_home/.local/bin:" >/dev/null || fail "fresh interactive PATH"
noninteractive_output=$(HOME="$basic_home" PATH=/usr/bin:/bin /bin/bash -c \
    '. "$1"; printf "loaded=%s" "${HARNESS_PERSONAL_MACOS_LOADER_LOADED:-absent}"' \
    synthetic "$PUBLIC/shell/personal-macos.bash")
[ "$noninteractive_output" = loaded=absent ] ||
    fail "non-interactive loader was not silent/inactive"

transaction_root=$basic_home/.local/state/harness/transactions
before_count=$(find "$transaction_root" -type f -name '*.macos-bash.manifest' |
    wc -l | tr -d ' ')
run_macos_bash "$basic_home" "$TEMP_DIR/basic-noop.log" \
    --host mac-test-pilot --apply >"$TEMP_DIR/basic.noop"
after_count=$(find "$transaction_root" -type f -name '*.macos-bash.manifest' |
    wc -l | tr -d ' ')
[ "$before_count" = "$after_count" ] || fail "managed Bash no-op transaction"
grep -F -x 'END macos_bash changes=none' "$TEMP_DIR/basic.noop" >/dev/null ||
    fail "managed Bash no-op summary"

cp "$basic_home/.bashrc" "$TEMP_DIR/basic-post-rc"
printf '%s\n' '# later owner change' >>"$basic_home/.bashrc"
if run_macos_bash "$basic_home" "$TEMP_DIR/basic-refuse.log" \
    --rollback "$basic_tx" >"$TEMP_DIR/basic-refuse.out" 2>&1; then
    fail "managed Bash rollback accepted a changed startup file"
fi
grep -F 'rollback blocked by changed startup file' \
    "$TEMP_DIR/basic-refuse.out" >/dev/null || fail "changed startup refusal"
[ -L "$basic_home/.local/bin/harness-bash" ] ||
    fail "changed startup refusal mutated launcher link"
cp "$TEMP_DIR/basic-post-rc" "$basic_home/.bashrc"
chmod 640 "$basic_home/.bashrc"
run_macos_bash "$basic_home" "$TEMP_DIR/basic-rollback.log" \
    --rollback "$basic_tx" >"$TEMP_DIR/basic.rollback"
cmp -s "$basic_home/.bashrc" "$TEMP_DIR/basic-original-rc" ||
    fail "managed Bash rollback did not restore exact rc bytes"
[ "$(file_mode "$basic_home/.bashrc")" = 640 ] ||
    fail "managed Bash rollback did not preserve rc mode"
[ "$(file_inode "$basic_home/.bashrc")" = "$basic_inode" ] ||
    fail "managed Bash rollback replaced the rc inode"
[ ! -e "$basic_home/.bash_profile" ] && [ ! -L "$basic_home/.bash_profile" ] ||
    fail "managed Bash rollback retained created profile"
[ ! -e "$basic_home/.local/bin/harness-bash" ] &&
    [ ! -L "$basic_home/.local/bin/harness-bash" ] ||
    fail "managed Bash rollback retained launcher link"

marker_home=$(make_home marker-collision)
printf '%s\n' '# >>> harness personal macOS Bash v1 >>>' >"$marker_home/.bashrc"
chmod 600 "$marker_home/.bashrc"
if run_macos_bash "$marker_home" "$TEMP_DIR/marker.log" \
    --host mac-test-pilot --apply >"$TEMP_DIR/marker.out" 2>&1; then
    fail "managed Bash accepted a partial marker collision"
fi
grep -F 'reason=marker' "$TEMP_DIR/marker.out" >/dev/null ||
    fail "partial marker refusal"
[ ! -e "$marker_home/.local" ] || fail "marker refusal created state"

symlink_home=$(make_home startup-symlink)
printf '%s\n' '# owner target' >"$symlink_home/owner-rc"
ln -s "$symlink_home/owner-rc" "$symlink_home/.bashrc"
if run_macos_bash "$symlink_home" "$TEMP_DIR/symlink.log" \
    --host mac-test-pilot --plan >"$TEMP_DIR/symlink.out" 2>&1; then
    fail "managed Bash accepted a symlink startup file"
fi
grep -F 'reason=type' "$TEMP_DIR/symlink.out" >/dev/null ||
    fail "startup symlink refusal"

hardlink_home=$(make_home startup-hardlink)
printf '%s\n' '# owner rc' >"$hardlink_home/owner-rc"
ln "$hardlink_home/owner-rc" "$hardlink_home/.bashrc"
if run_macos_bash "$hardlink_home" "$TEMP_DIR/hardlink.log" \
    --host mac-test-pilot --plan >"$TEMP_DIR/hardlink.out" 2>&1; then
    fail "managed Bash accepted a hard-linked startup file"
fi
grep -F 'reason=hardlink' "$TEMP_DIR/hardlink.out" >/dev/null ||
    fail "startup hardlink refusal"

partial_home=$(make_home partial-failure)
printf '%s\n' '# owner rc' >"$partial_home/.bashrc"
chmod 600 "$partial_home/.bashrc"
cp "$partial_home/.bashrc" "$TEMP_DIR/partial-original"
partial_loader=$partial_home/.config/harness/managed/personal-macos.bash
if MACOS_BASH_FAIL_LINK="$partial_loader" run_macos_bash "$partial_home" \
    "$TEMP_DIR/partial.log" --host mac-test-pilot --apply \
    >"$TEMP_DIR/partial.out" 2>&1; then
    fail "injected managed Bash partial failure succeeded"
fi
grep -F 'injected managed Bash link failure' "$TEMP_DIR/partial.out" >/dev/null ||
    fail "managed Bash partial failure injection"
cmp -s "$partial_home/.bashrc" "$TEMP_DIR/partial-original" ||
    fail "managed Bash partial failure changed rc"
[ ! -e "$partial_home/.local/bin/harness-bash" ] &&
    [ ! -L "$partial_home/.local/bin/harness-bash" ] ||
    fail "managed Bash partial failure retained launcher"
partial_status=$(find "$partial_home/.local/state/harness/transactions" \
    -type f -name '*.macos-bash.status')
[ -n "$partial_status" ] && [ "$(sed -n '1p' "$partial_status")" = failed ] ||
    fail "managed Bash partial failure status"

echo "personal macOS Bash tests: PASS"
