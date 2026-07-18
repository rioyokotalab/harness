#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
INVENTORY=$ROOT/libexec/harness-macos-inventory
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/harness-macos-inventory-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEMP_DIR" ]; then
        "$CLEANUP" "$ROOT/bin/harness" "${TMPDIR:-/tmp}" "$TEMP_DIR" \
            "${TMPDIR:-/tmp}" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then
        echo "FAIL: guarded personal-Mac inventory cleanup" >&2
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

home=$TEMP_DIR/home
private=$home/.config/harness/private
mkdir -p "$private/hosts" "$home/.codex/rules" "$home/.claude" \
    "$home/.local/bin"
cp "$ROOT/tests/fixtures/personal-macos/private-v1/companion.conf" \
    "$private/companion.conf"
cp "$ROOT/tests/fixtures/personal-macos/private-v1/hosts/mac-test-pilot.conf" \
    "$private/hosts/mac-test-pilot.conf"
git -C "$private" init -q -b main
git -C "$private" config user.name mac-test
git -C "$private" config user.email mac-test.invalid
git -C "$private" add companion.conf hosts/mac-test-pilot.conf
git -C "$private" commit -q -m 'synthetic private inventory fixture'
chmod 700 "$home" "$home/.config" "$home/.config/harness" "$private" \
    "$private/.git" "$private/hosts"
chmod 600 "$private/companion.conf" "$private/hosts/mac-test-pilot.conf"
ln -s "$ROOT/.codex/AGENTS.md" "$home/.codex/AGENTS.md"
ln -s "$ROOT/.codex/rules/default.rules" \
    "$home/.codex/rules/default.rules"
ln -s "$ROOT/.claude/CLAUDE.md" "$home/.claude/CLAUDE.md"

fake_bin=$TEMP_DIR/fake-bin
mkdir -p "$fake_bin"
cat >"$fake_bin/uname" <<'EOF'
#!/bin/sh
case "$1" in
    -s) echo Darwin ;;
    -m) echo "${FAKE_ARCH:-arm64}" ;;
    *) exit 2 ;;
esac
EOF
cat >"$fake_bin/stat" <<'EOF'
#!/bin/sh
if [ "$1" = -f ]; then
    format=$2
    shift 3
    case "$format" in
        %u) exec /usr/bin/stat -c %u -- "$1" ;;
        %Lp) exec /usr/bin/stat -c %a -- "$1" ;;
    esac
fi
exec /usr/bin/stat "$@"
EOF
cat >"$fake_bin/xcode-select" <<'EOF'
#!/bin/sh
[ "$1" = -p ] || exit 2
echo /synthetic/command-line-tools
EOF
cat >"$fake_bin/brew" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$BREW_LOG"
case "$1" in
    --version)
        [ "${FAKE_BREW_FAIL:-0}" != 1 ] || exit 7
        echo 'Homebrew synthetic'
        exit 0
        ;;
    --prefix) echo "${FAKE_BREW_PREFIX:-/opt/homebrew}"; exit 0 ;;
    list)
        [ "$2:$3" = --formula:--versions ] || exit 2
        [ "$4" != tree ]
        ;;
    *) exit 99 ;;
esac
EOF
chmod 755 "$fake_bin/uname" "$fake_bin/stat" "$fake_bin/xcode-select" \
    "$fake_bin/brew"

brew_log=$TEMP_DIR/brew.log
output=$(HOME="$home" SHELL=/bin/zsh BREW_LOG="$brew_log" \
    PATH="$fake_bin:/usr/bin:/bin" HARNESS_ROOT="$ROOT" \
    "$INVENTORY" --host mac-test-pilot)
for expected in \
    'schema=1' \
    'family=personal-macos' \
    'logical_id=mac-test-pilot' \
    'architecture=arm64' \
    'account_shell=zsh' \
    'homebrew=present' \
    'homebrew_prefix_class=apple-silicon-default' \
    'command_line_tools=present' \
    'private_profile=valid' \
    'harness_checkout=present' \
    'link_codex_guidance=symlink' \
    'link_codex_rules=symlink' \
    'link_claude_guidance=symlink' \
    'link_bash_launcher=absent' \
    'formula_bash=present' \
    'formula_git=present' \
    'formula_git_lfs=present' \
    'formula_tmux=present' \
    'formula_ripgrep=present' \
    'formula_jq=present' \
    'formula_tree=absent' \
    'formula_shellcheck=present'
do
    printf '%s\n' "$output" | grep -F -x "$expected" >/dev/null ||
        fail "missing value-minimized fact: $expected"
done

case "$output" in
    *"$home"*|*/opt/homebrew*|*/synthetic/command-line-tools*|*Homebrew\ synthetic*|\
    *language*|*agents*|*sqlite*|*ninja*)
        fail "inventory exposed a private path, version, or selection"
        ;;
esac
if grep -E '(^| )(update|upgrade|install|cleanup|services|tap|bundle)( |$)' \
    "$brew_log" >/dev/null; then
    fail "inventory invoked a mutating or broad Homebrew command"
fi
[ "$(grep -c '^list --formula --versions ' "$brew_log")" -eq 8 ] ||
    fail "inventory did not query exactly the public formula allowlist"

x86_output=$(HOME="$home" SHELL=/bin/bash BREW_LOG="$TEMP_DIR/brew-x86.log" \
    FAKE_ARCH=x86_64 FAKE_BREW_PREFIX=/usr/local \
    PATH="$fake_bin:/usr/bin:/bin" HARNESS_ROOT="$ROOT" \
    "$INVENTORY" --host mac-test-pilot)
printf '%s\n' "$x86_output" | grep -F -x 'architecture=x86_64' >/dev/null ||
    fail "x86_64 architecture class"
printf '%s\n' "$x86_output" | grep -F -x \
    'homebrew_prefix_class=intel-default' >/dev/null ||
    fail "Intel Homebrew prefix class"
printf '%s\n' "$x86_output" | grep -F -x 'account_shell=bash' >/dev/null ||
    fail "Bash account-shell class"

unusable_output=$(HOME="$home" SHELL=/bin/zsh \
    BREW_LOG="$TEMP_DIR/brew-unusable.log" FAKE_BREW_FAIL=1 \
    PATH="$fake_bin:/usr/bin:/bin" HARNESS_ROOT="$ROOT" \
    "$INVENTORY" --host mac-test-pilot)
printf '%s\n' "$unusable_output" | grep -F -x 'homebrew=unusable' \
    >/dev/null || fail "unusable Homebrew state"
printf '%s\n' "$unusable_output" | grep -F -x \
    'homebrew_prefix_class=unknown' >/dev/null ||
    fail "unusable Homebrew prefix class"

no_brew_bin=$TEMP_DIR/no-brew-bin
mkdir -p "$no_brew_bin"
cp "$fake_bin/uname" "$fake_bin/stat" "$no_brew_bin/"
chmod 755 "$no_brew_bin/uname" "$no_brew_bin/stat"
chmod 755 "$private"
absent_output=$(HOME="$home" SHELL=/bin/other \
    PATH="$no_brew_bin:/usr/bin:/bin" HARNESS_ROOT="$ROOT" \
    "$INVENTORY" --host mac-test-pilot)
chmod 700 "$private"
for expected in 'account_shell=other' 'homebrew=absent' \
    'homebrew_prefix_class=none' 'command_line_tools=absent' \
    'private_profile=invalid' 'formula_bash=unknown'
do
    printf '%s\n' "$absent_output" | grep -F -x "$expected" >/dev/null ||
        fail "missing-tool fact: $expected"
done

if HOME="$home" SHELL=/bin/bash PATH=/usr/bin:/bin HARNESS_ROOT="$ROOT" \
    "$INVENTORY" --host mac-test-pilot >"$TEMP_DIR/linux.out" 2>&1; then
    fail "macOS inventory accepted Linux"
fi
grep -F 'macOS inventory requires Darwin' "$TEMP_DIR/linux.out" >/dev/null ||
    fail "non-Darwin refusal"

# The shared metadata helpers must route through BSD stat syntax on Darwin.
helper_output=$(HOME="$home" PATH="$fake_bin:/usr/bin:/bin" sh -c '
    . "$1/libexec/harness-common"
    . "$1/libexec/harness-macos-common"
    printf "%s|%s\n" "$(macos_stat_owner "$2")" "$(macos_stat_mode "$2")"
' sh "$ROOT" "$private/companion.conf")
[ "$helper_output" = "$(id -u)|600" ] || fail "Darwin metadata helper route"

echo "personal macOS inventory tests passed"
