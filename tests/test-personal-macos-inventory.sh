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
cat >"$fake_bin/dscl" <<'EOF'
#!/bin/sh
printf 'UserShell: %s\n' "$SHELL"
EOF
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
        %u) native_format=%u ;;
        %Lp) native_format=%a ;;
    esac
    case $(/usr/bin/uname -s) in
        Darwin)
            [ "$native_format" != %a ] || native_format=%Lp
            exec /usr/bin/stat -f "$native_format" "$1"
            ;;
        *) exec /usr/bin/stat -c "$native_format" -- "$1" ;;
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
        [ "$#" -eq 3 ] || exit 2
        printf '%s\n' \
            'bash 5.3' \
            'bash-completion@2 2.16' \
            'git 2.0' \
            'git-lfs 3.0' \
            'icu4c@78 78.2' \
            'jq 1.8' \
            'ripgrep 15.0' \
            'shellcheck 0.11' \
            'tmux 3.5' \
            'uv 0.11' \
            'bash-completion 1.3' \
            'pyenv 2.6'
        ;;
    *) exit 99 ;;
esac
EOF
cat >"$fake_bin/socketfilterfw" <<'EOF'
#!/bin/sh
[ "${FAKE_FIREWALL_FAIL:-0}" != 1 ] || exit 7
case "$1" in
    --getglobalstate)
        if [ "${FAKE_FIREWALL_MALFORMED:-0}" = 1 ]; then
            echo 'synthetic malformed firewall state'
        elif [ "${FAKE_FIREWALL_DISABLED:-0}" = 1 ]; then
            echo 'Firewall is disabled. (State = 0)'
        else
            echo 'Firewall is enabled. (State = 1)'
        fi
        ;;
    --getstealthmode)
        if [ "${FAKE_FIREWALL_MALFORMED:-0}" = 1 ]; then
            echo 'synthetic malformed stealth state'
        elif [ "${FAKE_FIREWALL_DISABLED:-0}" = 1 ]; then
            echo 'Firewall stealth mode is off'
        else
            echo 'Firewall stealth mode is on'
        fi
        ;;
    --getallowsigned)
        if [ "${FAKE_FIREWALL_MALFORMED:-0}" = 1 ]; then
            echo 'synthetic malformed signed state'
        elif [ "${FAKE_FIREWALL_SIGNED_DISABLED:-0}" = 1 ]; then
            echo 'Automatically allow built-in signed software DISABLED.'
            echo 'Automatically allow downloaded signed software DISABLED.'
        else
            echo 'Automatically allow built-in signed software ENABLED.'
            echo 'Automatically allow downloaded signed software ENABLED.'
        fi
        ;;
    --getblockall)
        if [ "${FAKE_FIREWALL_MALFORMED:-0}" = 1 ]; then
            echo 'synthetic malformed block-all state'
        elif [ "${FAKE_FIREWALL_BLOCK_ALL:-0}" = 1 ]; then
            echo 'Firewall has block all state set to enabled.'
        else
            echo 'Firewall has block all state set to disabled.'
        fi
        ;;
    *) exit 2 ;;
esac
EOF
chmod 755 "$fake_bin/uname" "$fake_bin/stat" "$fake_bin/dscl" "$fake_bin/xcode-select" \
    "$fake_bin/brew" "$fake_bin/socketfilterfw"
HARNESS_TEST_MODE=1
HARNESS_TEST_SOCKETFILTERFW=$fake_bin/socketfilterfw
HARNESS_TEST_SHELLS_FILE=$TEMP_DIR/shells
: >"$HARNESS_TEST_SHELLS_FILE"
export HARNESS_TEST_MODE HARNESS_TEST_SOCKETFILTERFW HARNESS_TEST_SHELLS_FILE

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
    'account_shell_registry=absent' \
    'homebrew=present' \
    'homebrew_prefix_class=apple-silicon-default' \
    'command_line_tools=present' \
    'firewall=enabled' \
    'firewall_stealth=enabled' \
    'firewall_allow_builtin=enabled' \
    'firewall_allow_signed_apps=enabled' \
    'firewall_block_all=disabled' \
    'private_profile=valid' \
    'harness_checkout=present' \
    'link_codex_guidance=symlink' \
    'link_codex_rules=symlink' \
    'link_claude_guidance=symlink' \
    'link_bash_launcher=absent' \
    'formula_bash=present' \
    'formula_bash_completion_2=present' \
    'formula_git=present' \
    'formula_git_lfs=present' \
    'formula_tmux=present' \
    'formula_ripgrep=present' \
    'formula_jq=present' \
    'formula_tree=absent' \
    'formula_shellcheck=present' \
    'formula_uv=present' \
    'formula_icu4c_78=present' \
    'formula_icu4c=absent' \
    'formula_bash_completion=present' \
    'formula_pyenv=present'
do
    printf '%s\n' "$output" | grep -F -x "$expected" >/dev/null ||
        fail "missing value-minimized fact: $expected"
done

case "$output" in
    *"$home"*|*/opt/homebrew*|*/synthetic/command-line-tools*|*Homebrew\ synthetic*|\
    *language*|*agents*|*ninja*)
        fail "inventory exposed a private path, version, or selection"
        ;;
esac
if grep -E '(^| )(update|upgrade|install|cleanup|services|tap|bundle)( |$)' \
    "$brew_log" >/dev/null; then
    fail "inventory invoked a mutating or broad Homebrew command"
fi
[ "$(grep -c '^list --formula --versions$' "$brew_log")" -eq 1 ] ||
    fail "inventory did not use one exact installed-formula query"

echo 'personal macOS inventory essential contract: PASS'
exit 0
