#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
INVENTORY=$ROOT/libexec/harness-macos-inventory
PLAN=$ROOT/libexec/harness-macos-plan
DOCTOR=$ROOT/libexec/harness-macos-doctor
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/harness-macos-plan-test.XXXXXX")
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
ln -s "$ROOT/.claude/CLAUDE.md" "$home/.claude/CLAUDE.md"

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
        %u) exec /usr/bin/stat -c %u -- "$1" ;;
        %Lp) exec /usr/bin/stat -c %a -- "$1" ;;
        %l) exec /usr/bin/stat -c %h -- "$1" ;;
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
    --version) echo 'Homebrew synthetic' ;;
    --prefix) echo /opt/homebrew ;;
    list)
        [ "$2:$3" = --formula:--versions ] || exit 2
        if [ "$4" = tree ] && [ "${FAKE_TREE_PRESENT:-0}" != 1 ]; then
            exit 1
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
chmod 755 "$fake_bin/uname" "$fake_bin/stat" "$fake_bin/xcode-select" \
    "$fake_bin/brew"

brew_log=$TEMP_DIR/brew.log
facts=$TEMP_DIR/facts.conf
HOME="$home" SHELL=/bin/zsh BREW_LOG="$brew_log" \
    PATH="$fake_bin:/usr/bin:/bin" HARNESS_ROOT="$ROOT" \
    "$INVENTORY" --host mac-test-pilot >"$facts"
chmod 600 "$facts"

plan_output=$(HOME="$home" SHELL=/bin/zsh BREW_LOG="$brew_log" \
    PATH="$fake_bin:/usr/bin:/bin" HARNESS_ROOT="$ROOT" \
    "$PLAN" --host mac-test-pilot --facts "$facts")
for expected in \
    'MACOS_PLAN mode=read-only privacy=local-details' \
    'PRIVATE capability_groups=2 extra_formulae=2 values=not-emitted' \
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

if HOME="$home" BREW_LOG="$TEMP_DIR/doctor-not-ready.log" \
    PATH="$fake_bin:/usr/bin:/bin" HARNESS_ROOT="$ROOT" \
    "$DOCTOR" --host mac-test-pilot --facts "$facts" \
    >"$TEMP_DIR/doctor-not-ready.out" 2>&1; then
    fail "doctor accepted missing formula and Bash launcher"
fi
grep -F 'END macos_doctor status=not-ready' \
    "$TEMP_DIR/doctor-not-ready.out" >/dev/null || fail "not-ready doctor result"

ln -s "$ROOT/bin/harness-bash" "$home/.local/bin/harness-bash"
mkdir -p "$home/.config/harness/managed"
chmod 700 "$home/.config/harness/managed"
ln -s "$ROOT/shell/personal-macos.bash" \
    "$home/.config/harness/managed/personal-macos.bash"
cp "$ROOT/shell/personal-macos-startup.block" "$home/.bash_profile"
cp "$ROOT/shell/personal-macos-startup.block" "$home/.bashrc"
chmod 600 "$home/.bash_profile" "$home/.bashrc"
ready_facts=$TEMP_DIR/ready-facts.conf
HOME="$home" SHELL=/bin/zsh BREW_LOG="$TEMP_DIR/ready-inventory.log" \
    FAKE_TREE_PRESENT=1 PATH="$fake_bin:/usr/bin:/bin" HARNESS_ROOT="$ROOT" \
    "$INVENTORY" --host mac-test-pilot >"$ready_facts"
chmod 600 "$ready_facts"
doctor_output=$(HOME="$home" BREW_LOG="$TEMP_DIR/doctor-ready.log" \
    FAKE_TREE_PRESENT=1 PATH="$fake_bin:/usr/bin:/bin" HARNESS_ROOT="$ROOT" \
    "$DOCTOR" --host mac-test-pilot --facts "$ready_facts")
printf '%s\n' "$doctor_output" | grep -F -x \
    'END macos_doctor status=ready failures=0 warnings=0' >/dev/null ||
    fail "ready doctor result"
case "$doctor_output" in
    *sqlite*|*ninja*|*language*|*agents*|*"$home"*)
        fail "doctor exposed private desired state"
        ;;
esac

implicit_plan=$(HOME="$home" SHELL=/bin/zsh TMPDIR="$TEMP_DIR" \
    BREW_LOG="$TEMP_DIR/implicit-plan.log" FAKE_TREE_PRESENT=1 \
    PATH="$fake_bin:/usr/bin:/bin" HARNESS_ROOT="$ROOT" \
    "$PLAN" --host mac-test-pilot)
printf '%s\n' "$implicit_plan" | grep -F -x \
    'END macos_plan blocked=0 package_changes=not-applied network=none' \
    >/dev/null || fail "implicit inventory plan"
HOME="$home" SHELL=/bin/zsh TMPDIR="$TEMP_DIR" \
    BREW_LOG="$TEMP_DIR/implicit-doctor.log" FAKE_TREE_PRESENT=1 \
    PATH="$fake_bin:/usr/bin:/bin" HARNESS_ROOT="$ROOT" \
    "$DOCTOR" --host mac-test-pilot >/dev/null || fail "implicit inventory doctor"
if find "$TEMP_DIR" -maxdepth 1 \
    \( -name 'harness-macos-plan-facts.*' -o \
       -name 'harness-macos-doctor-facts.*' \) -print -quit |
    grep . >/dev/null; then
    fail "implicit inventory left a temporary fact file"
fi

echo "personal macOS plan/doctor tests passed"
