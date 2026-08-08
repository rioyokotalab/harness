#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
INVENTORY=$ROOT/libexec/harness-macos-inventory
PLAN=$ROOT/libexec/harness-macos-plan
DOCTOR=$ROOT/libexec/harness-macos-doctor
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/harness-macos-plan-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEMP_DIR" ]; then
        "$CLEANUP" "$ROOT/bin/harness" "$TEMP_BASE" "$TEMP_DIR" \
            "$TEMP_BASE" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then
        echo "FAIL: guarded personal-Mac plan cleanup" >&2
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
git -C "$private" commit -q -m 'synthetic private plan fixture'
chmod 700 "$home" "$home/.config" "$home/.config/harness" "$private" \
    "$private/.git" "$private/hosts"
chmod 600 "$private/companion.conf" "$private/hosts/mac-test-pilot.conf"
ln -s "$ROOT/.codex/AGENTS.md" "$home/.codex/AGENTS.md"
ln -s "$ROOT/.codex/rules/default.rules" \
    "$home/.codex/rules/default.rules"
ln -s "$ROOT/config/agent-clients/claude-sentinel.md" \
    "$home/.claude/CLAUDE.md"

fake_bin=$TEMP_DIR/fake-bin
mkdir -p "$fake_bin"
cat >"$fake_bin/uname" <<'EOF'
#!/bin/sh
case "$1" in -s) echo Darwin ;; -m) echo arm64 ;; *) exit 2 ;; esac
EOF
cat >"$fake_bin/stat" <<'EOF'
#!/bin/sh
if [ "$1" = -f ]; then
    format=$2
    shift 3
    case "$format" in
        %u) native_format=%u ;;
        %Lp) native_format=%a ;;
        %l) native_format=%h ;;
    esac
    case $(/usr/bin/uname -s) in
        Darwin)
            case "$native_format" in %a) native_format=%Lp ;; %h) native_format=%l ;; esac
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
cat >"$fake_bin/tmux" <<'EOF'
#!/bin/sh
exit 0
EOF
cat >"$fake_bin/grep" <<'EOF'
#!/bin/sh
if [ "$#" -eq 5 ] && [ "$1:$2:$3" = -F:-x:-c ] &&
    [ "$4" = /opt/homebrew/bin/bash ] && [ "$5" = /etc/shells ]; then
    echo 1
    exit 0
fi
exec /usr/bin/grep "$@"
EOF
cat >"$fake_bin/brew" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$BREW_LOG"
case "$1" in
    --version) echo 'Homebrew synthetic' ;;
    --prefix) echo /opt/homebrew ;;
    list)
        [ "$2:$3" = --formula:--versions ] || exit 2
        if [ "$#" -eq 3 ]; then
            printf '%s\n' "$FAKE_MANAGED_FORMULAE" | tr ',' '\n' |
                awk -v tree="${FAKE_TREE_PRESENT:-0}" '
                    NF && ($0 != "tree" || tree == 1) { print $0, "1.0" }
                '
            printf '%s\n' 'ninja 1.0'
        elif [ "$#" -eq 4 ]; then
            if [ "${FAKE_ALIAS_RESOLUTION:-0}" = 1 ] &&
                [ "$4" = icu4c ]; then
                exit 0
            fi
            case ",$FAKE_MANAGED_FORMULAE,ninja," in *,$4,*) ;; *) exit 1 ;; esac
            [ "$4" != tree ] || [ "${FAKE_TREE_PRESENT:-0}" = 1 ]
        else
            exit 2
        fi
        ;;
    outdated)
        [ "$2:$3" = --formula:--quiet ] || exit 2
        if [ "${FAKE_OUTDATED_UNMANAGED:-0}" = 1 ]; then
            echo unmanaged-formula
        else
            echo git
            echo sqlite
        fi
        exit 1
        ;;
    *) exit 99 ;;
esac
EOF
cat >"$fake_bin/socketfilterfw" <<'EOF'
#!/bin/sh
case "$1" in
    --getglobalstate) echo 'Firewall is enabled. (State = 1)' ;;
    --getstealthmode) echo 'Firewall stealth mode is on' ;;
    --getallowsigned)
        echo 'Automatically allow built-in signed software ENABLED.'
        echo 'Automatically allow downloaded signed software ENABLED.'
        ;;
    --getblockall) echo 'Firewall has block all state set to disabled.' ;;
    *) exit 2 ;;
esac
EOF
chmod 755 "$fake_bin/uname" "$fake_bin/stat" "$fake_bin/xcode-select" \
    "$fake_bin/tmux" "$fake_bin/grep" "$fake_bin/brew" \
    "$fake_bin/socketfilterfw"
HARNESS_TEST_MODE=1
HARNESS_TEST_SOCKETFILTERFW=$fake_bin/socketfilterfw
export HARNESS_TEST_MODE HARNESS_TEST_SOCKETFILTERFW

brew_log=$TEMP_DIR/brew.log
facts=$TEMP_DIR/facts.conf
FAKE_MANAGED_FORMULAE=$(sed -n 's/^managed_formulae=//p' \
    "$ROOT/profiles/personal-macos/formula-policy-v4.conf")
export FAKE_MANAGED_FORMULAE
cat >"$facts" <<'EOF'
schema=1
family=personal-macos
logical_id=mac-test-pilot
architecture=arm64
account_shell=zsh
account_shell_registry=absent
homebrew=present
homebrew_prefix_class=apple-silicon-default
command_line_tools=present
firewall=enabled
firewall_stealth=enabled
firewall_allow_builtin=enabled
firewall_allow_signed_apps=enabled
firewall_block_all=disabled
private_profile=valid
harness_checkout=present
link_codex_guidance=symlink
link_codex_rules=symlink
link_claude_guidance=symlink
link_bash_launcher=absent
EOF
managed_formulae=$(sed -n 's/^managed_formulae=//p' \
    "$ROOT/profiles/personal-macos/formula-policy-v4.conf")
retired_formulae=$(sed -n 's/^retired_formulae=//p' \
    "$ROOT/profiles/personal-macos/formula-policy-v4.conf")
formulae=$(printf '%s\n%s\n' "$managed_formulae" "$retired_formulae" | tr ',' '\n')
printf '%s\n' "$formulae" | while IFS= read -r formula; do
    [ -n "$formula" ] || continue
    key=$(printf '%s' "$formula" | sed 's/+/p/g; s/[-@.]/_/g')
    state=present
    case ",$retired_formulae," in *,"$formula",*) state=absent ;; esac
    [ "$formula" != tree ] || state=absent
    printf 'formula_%s=%s\n' "$key" "$state"
done >>"$facts"
chmod 600 "$facts"
: >"$brew_log"

case ${HARNESS_TEST_CASE:-plan} in
    plan) ;;
    doctor) ;;
    *) fail "unknown essential plan/doctor case" ;;
esac

if [ "${HARNESS_TEST_CASE:-plan}" = plan ]; then
plan_output=$(HOME="$home" SHELL=/bin/zsh BREW_LOG="$brew_log" \
    PATH="$fake_bin:/usr/bin:/bin" HARNESS_ROOT="$ROOT" \
    "$PLAN" --host mac-test-pilot --facts "$facts")
for expected in \
    'MACOS_PLAN mode=read-only privacy=local-details' \
    'PRIVATE capability_groups=2 extra_formulae=1 values=not-emitted' \
    'CREATE link=bash_launcher collision_check=required' \
    "HOMEBREW_METADATA authority=separate command='env HOMEBREW_NO_ANALYTICS=1 brew update'" \
    "HOMEBREW_DRY_RUN stage=install count=1 command='env -u HOMEBREW_ASK HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 HOMEBREW_NO_ANALYTICS=1 brew install --formula --dry-run tree'" \
    "HOMEBREW_APPLY stage=install count=1 command='env -u HOMEBREW_ASK HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 HOMEBREW_NO_ANALYTICS=1 brew install --formula tree'" \
    "HOMEBREW_DRY_RUN stage=upgrade count=2 command='env -u HOMEBREW_ASK HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 HOMEBREW_NO_ANALYTICS=1 brew upgrade --formula --dry-run git sqlite'" \
    'END macos_plan blocked=0 package_changes=not-applied network=none'
do
    printf '%s\n' "$plan_output" | grep -F -x "$expected" >/dev/null ||
        fail "missing plan result: $expected"
done
case "$plan_output" in *"$home"*|*/opt/homebrew*) fail "plan exposed private path" ;; esac
if grep -E '^(update|install|upgrade|cleanup|services|tap|bundle)( |$)' \
    "$brew_log" >/dev/null; then
    fail "plan executed a mutating Homebrew command"
fi
[ "$(grep -F -x -c 'list --formula --versions' "$brew_log")" -eq 1 ] ||
    fail "plan did not use one installed-formula snapshot"
if grep -E '^list --formula --versions .+' "$brew_log" >/dev/null; then
    fail "plan queried alias-resolving per-formula state"
fi
echo 'personal macOS plan essential contract: PASS'
exit 0
fi

if false; then
: >"$brew_log"
alias_plan_output=$(HOME="$home" SHELL=/bin/zsh BREW_LOG="$brew_log" \
    FAKE_ALIAS_RESOLUTION=1 PATH="$fake_bin:/usr/bin:/bin" HARNESS_ROOT="$ROOT" \
    "$PLAN" --host mac-test-pilot --facts "$facts")
printf '%s\n' "$alias_plan_output" | grep -F -x \
    'END macos_plan blocked=0 package_changes=not-applied network=none' \
    >/dev/null || fail "Homebrew alias resolution created false formula drift"
if grep -E '^list --formula --versions .+' "$brew_log" >/dev/null; then
    fail "alias regression used a per-formula Homebrew query"
fi

unlink "$home/.codex/AGENTS.md"
ln -s "$ROOT/.codex/rules/default.rules" "$home/.codex/AGENTS.md"
wrong_link_plan=$(HOME="$home" BREW_LOG="$TEMP_DIR/wrong-link.log" \
    PATH="$fake_bin:/usr/bin:/bin" HARNESS_ROOT="$ROOT" \
    "$PLAN" --host mac-test-pilot --facts "$facts")
printf '%s\n' "$wrong_link_plan" | grep -F -x \
    'BLOCK link=codex_guidance reason=wrong-symlink-target' >/dev/null ||
    fail "wrong managed-link target refusal"
unlink "$home/.codex/AGENTS.md"
ln -s "$ROOT/.codex/AGENTS.md" "$home/.codex/AGENTS.md"

drifted=$TEMP_DIR/drifted.conf
sed 's/formula_tree=absent/formula_tree=present/' "$facts" >"$drifted"
chmod 600 "$drifted"
if HOME="$home" BREW_LOG="$TEMP_DIR/drifted.log" \
    PATH="$fake_bin:/usr/bin:/bin" HARNESS_ROOT="$ROOT" \
    "$PLAN" --host mac-test-pilot --facts "$drifted" \
    >"$TEMP_DIR/drifted.out" 2>&1; then
    fail "captured/live formula drift accepted"
fi
grep -F 'captured public formula state drifted' \
    "$TEMP_DIR/drifted.out" >/dev/null || fail "formula drift refusal"

if HOME="$home" SHELL=/bin/zsh BREW_LOG="$TEMP_DIR/unmanaged.log" \
    FAKE_OUTDATED_UNMANAGED=1 PATH="$fake_bin:/usr/bin:/bin" \
    HARNESS_ROOT="$ROOT" "$PLAN" --host mac-test-pilot --facts "$facts" \
    >"$TEMP_DIR/unmanaged.out" 2>&1; then
    fail "unmanaged outdated scope accepted"
fi
grep -F 'Homebrew outdated query returned unmanaged scope' \
    "$TEMP_DIR/unmanaged.out" >/dev/null || fail "unmanaged outdated refusal"

malformed=$TEMP_DIR/malformed.conf
cp "$facts" "$malformed"
fact_sentinel=PRIVATE_FACT_SENTINEL
printf '%s\n' "secret=$fact_sentinel" >>"$malformed"
chmod 600 "$malformed"
if HOME="$home" BREW_LOG="$TEMP_DIR/malformed.log" \
    PATH="$fake_bin:/usr/bin:/bin" HARNESS_ROOT="$ROOT" \
    "$PLAN" --host mac-test-pilot --facts "$malformed" \
    >"$TEMP_DIR/malformed.out" 2>&1; then
    fail "unknown fact key accepted"
fi
grep -F 'private companion manifest is malformed' \
    "$TEMP_DIR/malformed.out" >/dev/null || fail "unknown fact refusal"
if grep -F "$fact_sentinel" "$TEMP_DIR/malformed.out" >/dev/null ||
    grep -F "$home" "$TEMP_DIR/malformed.out" >/dev/null; then
    fail "fact refusal exposed private content"
fi

malformed_firewall=$TEMP_DIR/malformed-firewall.conf
sed 's/^firewall=enabled$/firewall=unsafe/' "$facts" >"$malformed_firewall"
chmod 600 "$malformed_firewall"
if HOME="$home" BREW_LOG="$TEMP_DIR/malformed-firewall.log" \
    PATH="$fake_bin:/usr/bin:/bin" HARNESS_ROOT="$ROOT" \
    "$DOCTOR" --host mac-test-pilot --facts "$malformed_firewall" \
    >"$TEMP_DIR/malformed-firewall.out" 2>&1; then
    fail "doctor accepted malformed firewall fact"
fi
grep -F 'personal-Mac firewall fact is malformed' \
    "$TEMP_DIR/malformed-firewall.out" >/dev/null ||
    fail "malformed firewall fact refusal"

if HOME="$home" BREW_LOG="$TEMP_DIR/doctor-not-ready.log" \
    PATH="$fake_bin:/usr/bin:/bin" HARNESS_ROOT="$ROOT" \
    "$DOCTOR" --host mac-test-pilot --facts "$facts" \
    >"$TEMP_DIR/doctor-not-ready.out" 2>&1; then
    fail "doctor accepted missing formula and Bash launcher"
fi
grep -F 'END macos_doctor status=not-ready' \
    "$TEMP_DIR/doctor-not-ready.out" >/dev/null || fail "not-ready doctor result"
fi

ln -s "$ROOT/bin/harness-bash" "$home/.local/bin/harness-bash"
mkdir -p "$home/.config/harness/managed"
chmod 700 "$home/.config/harness/managed"
for startup in bash_profile bashrc; do
    {
        printf '%s\n' \
            '# >>> harness early managed >>>' \
            'HARNESS_LOGICAL_HOST=mac-test-pilot' \
            'export HARNESS_LOGICAL_HOST' \
            'if [ -r "$HOME/harness/shell/early-cache.sh" ]; then' \
            '    . "$HOME/harness/shell/early-cache.sh"' \
            'fi' \
            '# <<< harness early managed <<<' \
            '' \
            '# synthetic local middle'
        cat "$ROOT/shell/$startup.block"
    } >"$home/.$startup"
done
chmod 600 "$home/.bash_profile" "$home/.bashrc"
ln -s "$ROOT/config/tmux/tmux.conf" "$home/.tmux.conf"
ready_facts=$TEMP_DIR/ready-facts.conf
sed -e 's/^account_shell=zsh$/account_shell=homebrew-bash/' \
    -e 's/^account_shell_registry=absent$/account_shell_registry=present/' \
    -e 's/^link_bash_launcher=absent$/link_bash_launcher=symlink/' \
    -e 's/^formula_tree=absent$/formula_tree=present/' \
    -e 's/^formula_bash_completion=present$/formula_bash_completion=absent/' \
    -e 's/^formula_pyenv=present$/formula_pyenv=absent/' \
    "$facts" >"$ready_facts"
chmod 600 "$ready_facts"
doctor_output=$(HOME="$home" BREW_LOG="$TEMP_DIR/doctor-ready.log" \
    FAKE_TREE_PRESENT=1 PATH="$fake_bin:/usr/bin:/bin" HARNESS_ROOT="$ROOT" \
    "$DOCTOR" --host mac-test-pilot --facts "$ready_facts")
printf '%s\n' "$doctor_output" | grep -F -x \
    'END macos_doctor status=ready failures=0 warnings=0' >/dev/null ||
    fail "ready doctor result"
echo 'personal macOS plan/doctor essential contract: PASS'
exit 0
