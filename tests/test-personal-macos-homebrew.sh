#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
HOMEBREW=$ROOT/libexec/harness-macos-homebrew
FIXTURE=$ROOT/tests/fixtures/personal-macos/private-v1
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/harness-macos-homebrew-test.XXXXXX")
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
        echo "FAIL: guarded personal-Mac Homebrew cleanup" >&2
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

PUBLIC=$TEMP_DIR/public
mkdir -p "$PUBLIC/profiles/personal-macos"
cp "$ROOT/profiles/personal-macos/base.conf" \
    "$PUBLIC/profiles/personal-macos/base.conf"
cp "$ROOT/profiles/personal-macos/formula-policy-v4.conf" \
    "$PUBLIC/profiles/personal-macos/formula-policy-v4.conf"
git -C "$PUBLIC" init -q -b main
git -C "$PUBLIC" config user.name mac-test
git -C "$PUBLIC" config user.email mac-test.invalid
git -C "$PUBLIC" add .
git -C "$PUBLIC" commit -q -m 'synthetic public Homebrew adapter'

FAKE_PREFIX=$TEMP_DIR/homebrew-prefix
FAKE_BIN=$TEMP_DIR/fake-bin
mkdir -p "$FAKE_PREFIX/bin" "$FAKE_BIN"
cat >"$FAKE_BIN/uname" <<'EOF'
#!/bin/sh
case "${1:-}" in -s) echo Darwin ;; -m) echo arm64 ;; *) exit 2 ;; esac
EOF
cat >"$FAKE_BIN/stat" <<'EOF'
#!/bin/sh
case "${1:-}:${2:-}" in
    -f:%u) native_format=%u ;;
    -f:%Lp) native_format=%a ;;
    *) exec /usr/bin/stat "$@" ;;
esac
shift 2; [ "${1:-}" = -- ] && shift
case $(/usr/bin/uname -s) in
    Darwin)
        [ "$native_format" != %a ] || native_format=%Lp
        exec /usr/bin/stat -f "$native_format" "$@"
        ;;
    *) exec /usr/bin/stat -c "$native_format" -- "$@" ;;
esac
EOF
cat >"$FAKE_PREFIX/bin/brew" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$*" >>"$BREW_LOG"

remove_formula() {
    remove_file=$1
    remove_name=$2
    awk -v name="$remove_name" '$1 != name' "$remove_file" >"$remove_file.new"
    mv "$remove_file.new" "$remove_file"
}

case "$1" in
    --prefix)
        printf '%s\n' "$FAKE_BREW_PREFIX"
        ;;
    list)
        [ "$2:$3" = --formula:--versions ] || exit 91
        shift 3
        if [ "$#" -eq 0 ]; then
            sed -n '/./p' "$BREW_STATE/installed"
            exit 0
        fi
        list_status=0
        for list_name in "$@"; do
            if awk -v name="$list_name" '$1 == name { print; found = 1 }
                END { exit found ? 0 : 1 }' "$BREW_STATE/installed"; then
                :
            else
                list_status=1
            fi
        done
        exit "$list_status"
        ;;
    outdated)
        [ "$2:$3" = --formula:--quiet ] || exit 92
        sed -n '/./p' "$BREW_STATE/outdated"
        [ ! -s "$BREW_STATE/outdated" ] || exit 1
        ;;
    deps)
        [ "$2:$3:$4:$5" = --union:--full-name:--formula:bash ] || {
            [ "$2:$3:$4" = --union:--full-name:--formula ] || exit 93
        }
        printf '%s\n' dependency-lib
        ;;
    uses)
        [ "$2:$3:$4" = --installed:--recursive:--formula ] || exit 94
        if [ "${FAKE_UNMANAGED_DEPENDENT:-0}" = 1 ] && [ "$5" = git ]; then
            printf '%s\n' personal-tool
        fi
        if [ "${FAKE_UNMANAGED_DEPENDENCY_USER:-0}" = 1 ] && \
            [ "$5" = dependency-lib ]; then
            printf '%s\n' personal-tool
        fi
        if [ "${FAKE_RETIRED_INTERNAL_DEPENDENT:-0}" = 1 ] && \
            [ "$5" = bash-completion ]; then
            printf '%s\n' pyenv
        fi
        if [ "${FAKE_RETIRED_UPGRADE_DEPENDENT:-0}" = 1 ] && \
            [ "$5" = pyenv ] && grep -F -x node "$BREW_STATE/outdated" \
                >/dev/null 2>&1; then
            printf '%s\n' node
        fi
        if [ "${FAKE_RETIRED_DEPENDENT:-0}" = 1 ] && [ "$5" = pyenv ]; then
            printf '%s\n' personal-tool
        fi
        ;;
    install|upgrade|uninstall)
        [ "${HOMEBREW_ASK+x}" != x ] || exit 95
        action=$1
        shift
        dry=0
        formulae=
        while [ "$#" -gt 0 ]; do
            case "$1" in
                --dry-run) dry=1 ;;
                --formula|--force) ;;
                *) formulae="$formulae $1" ;;
            esac
            shift
        done
        formulae=${formulae# }
        if [ "$dry" -eq 1 ]; then
            if [ "${FAKE_PROHIBITED_DRY_RUN:-0}" = 1 ]; then
                echo 'Would install prohibited cask payload'
            else
                printf 'Would %s formulae: %s\n' "$action" "$formulae"
            fi
            exit 0
        fi
        [ "${FAKE_APPLY_FAILURE:-0}" != 1 ] || {
            echo 'injected Homebrew apply failure' >&2
            exit 73
        }
        if [ "$action" = uninstall ]; then
            for formula in $formulae; do
                remove_formula "$BREW_STATE/installed" "$formula"
                remove_formula "$BREW_STATE/outdated" "$formula"
            done
            if [ "${FAKE_RETIRE_REMOVES_MANAGED:-0}" = 1 ]; then
                remove_formula "$BREW_STATE/installed" mpdecimal
            fi
            printf '%s complete\n' "$action"
            exit 0
        fi
        for formula in $formulae; do
            remove_formula "$BREW_STATE/installed" "$formula"
            remove_formula "$BREW_STATE/outdated" "$formula"
            case "$action" in
                install) version=1.0 ;;
                upgrade) version=2.0 ;;
            esac
            printf '%s %s\n' "$formula" "$version" >>"$BREW_STATE/installed"
        done
        printf '%s complete\n' "$action"
        ;;
    cleanup)
        shift
        cleanup_dry=0
        cleanup_target=
        while [ "$#" -gt 0 ]; do
            case "$1" in
                --dry-run) cleanup_dry=1 ;;
                *) cleanup_target=$1 ;;
            esac
            shift
        done
        [ "$cleanup_target" = icu4c@78 ] || exit 96
        cleanup_path=$cleanup_target
        if [ "$cleanup_target" = icu4c@78 ] &&
            awk '$1 == "icu4c" { found = 1 } END { exit found ? 0 : 1 }' \
                "$BREW_STATE/installed"; then
            cleanup_path=icu4c
        fi
        if [ "$cleanup_dry" -eq 1 ]; then
            printf 'Would remove: %s/Cellar/%s/legacy\n' \
                "$FAKE_BREW_PREFIX" "$cleanup_path"
        else
            if [ "$cleanup_path" = icu4c ]; then
                remove_formula "$BREW_STATE/installed" icu4c
            else
                awk -v name="$cleanup_target" \
                    '$1 == name { print $1, $2; next } { print }' \
                    "$BREW_STATE/installed" >"$BREW_STATE/installed.new"
                mv "$BREW_STATE/installed.new" "$BREW_STATE/installed"
            fi
            printf '%s\n' 'cleanup complete'
        fi
        ;;
    *) exit 99 ;;
esac
EOF
chmod 755 "$FAKE_BIN/uname" "$FAKE_BIN/stat" "$FAKE_PREFIX/bin/brew"

make_home() {
    name=$1
    home=$TEMP_DIR/$name
    private=$home/.config/harness/private
    mkdir -p "$private/hosts"
    cp "$FIXTURE/companion.conf" "$private/companion.conf"
    cp "$FIXTURE/hosts/mac-test-pilot.conf" \
        "$private/hosts/mac-test-pilot.conf"
    sed 's/^extra_formulae=.*/extra_formulae=ninja/' \
        "$private/hosts/mac-test-pilot.conf" >"$TEMP_DIR/$name-host.conf"
    mv "$TEMP_DIR/$name-host.conf" "$private/hosts/mac-test-pilot.conf"
    chmod 700 "$home" "$home/.config" "$home/.config/harness" \
        "$private" "$private/hosts"
    chmod 600 "$private/companion.conf" \
        "$private/hosts/mac-test-pilot.conf"
    git -C "$private" init -q -b main
    git -C "$private" config user.name mac-test
    git -C "$private" config user.email mac-test.invalid
    git -C "$private" add companion.conf hosts/mac-test-pilot.conf
    git -C "$private" commit -q -m 'synthetic private Homebrew profile'
    chmod 700 "$private/.git"
    printf '%s\n' "$home"
}

make_brew_state() {
    name=$1
    state=$TEMP_DIR/$name-state
    mkdir -p "$state"
    selected=$(sed -n 's/^managed_formulae=//p' \
        "$PUBLIC/profiles/personal-macos/formula-policy-v4.conf" | tr ',' ' ')
    : >"$state/installed"
    for formula in $selected ninja; do
        [ "$formula" = tree ] || printf '%s 1.0\n' "$formula"
    done >>"$state/installed"
    printf '%s 3.0\n' dependency-lib >>"$state/installed"
    printf '%s\n' git sqlite >"$state/outdated"
    printf '%s\n' "$state"
}

run_homebrew() {
    test_home=$1
    test_state=$2
    test_log=$3
    shift 3
    HOME="$test_home" HARNESS_ROOT="$PUBLIC" BREW_STATE="$test_state" \
        BREW_LOG="$test_log" FAKE_BREW_PREFIX="$FAKE_PREFIX" \
        PATH="$FAKE_PREFIX/bin:$FAKE_BIN:/usr/bin:/bin" \
        "$HOMEBREW" "$@" && homebrew_status=0 || homebrew_status=$?
    unset FAKE_APPLY_FAILURE FAKE_PROHIBITED_DRY_RUN FAKE_RETIRED_DEPENDENT \
        FAKE_RETIRED_INTERNAL_DEPENDENT FAKE_RETIRED_UPGRADE_DEPENDENT \
        FAKE_RETIRE_REMOVES_MANAGED FAKE_UNMANAGED_DEPENDENCY_USER \
        FAKE_UNMANAGED_DEPENDENT
    return "$homebrew_status"
}

case ${HARNESS_TEST_CASE:-plan} in
    apply)
        apply_home=$(make_home apply)
        apply_state=$(make_brew_state apply)
        run_homebrew "$apply_home" "$apply_state" "$TEMP_DIR/essential-apply.log" \
            --host mac-test-pilot --apply >"$TEMP_DIR/essential-apply.out"
        grep -F 'TRANSACTION id=' "$TEMP_DIR/essential-apply.out" >/dev/null ||
            fail "essential Homebrew apply transaction"
        grep -F -x 'END macos_homebrew applied=yes rollback=manual-review-only metadata_refresh=separate' \
            "$TEMP_DIR/essential-apply.out" >/dev/null || fail "essential Homebrew apply summary"
        echo 'personal macOS Homebrew apply contract: PASS'
        exit 0
        ;;
    plan) ;;
    *) fail "unknown essential Homebrew case" ;;
esac

plan_home=$(make_home plan)
plan_state=$(make_brew_state plan)
plan_log=$TEMP_DIR/plan.log
run_homebrew "$plan_home" "$plan_state" "$plan_log" \
    --host mac-test-pilot --plan >"$TEMP_DIR/plan.out"
for expected in \
    'MACOS_HOMEBREW mode=plan privacy=local-details prefix=other' \
    "INSTALL count=1 formulae='tree'" \
    "UPGRADE count=2 formulae='git sqlite'" \
    "RETIRE count=0 formulae=''" \
    "RETIRE_CLEANUP count=0 aliases='' targets=''" \
    "CLEANUP_OLD count=0 formulae=''" \
    'DEPENDENCIES count=1 scope=validated shared_users=preserved' \
    "UNMANAGED_DEPENDENTS count=0 formulae=''" \
    "UNMANAGED_INSTALLED count=0 formulae=''" \
    "RETIRED_DEPENDENTS count=0 formulae=''" \
    "MIGRATION_DEPENDENTS count=0 formulae='' resolution=upgrade-before-retire" \
    'DRY_RUN status=validated install=1 upgrade=2 retire=package-manager-no-dry-run' \
    'END macos_homebrew applied=no metadata_refresh=separate'
do
    grep -F -x "$expected" "$TEMP_DIR/plan.out" >/dev/null ||
        fail "missing bounded Homebrew plan result: $expected"
done
[ ! -e "$plan_home/.local" ] && [ ! -L "$plan_home/.local" ] ||
    fail "Homebrew plan created transaction state"
if grep -E '^(update|cleanup|services|tap|bundle|list --formula$)( |$)' \
    "$plan_log" >/dev/null; then
    fail "Homebrew plan used an unscoped or prohibited command"
fi
grep -F -x 'install --formula --dry-run tree' "$plan_log" >/dev/null ||
    fail "scoped install dry-run"
grep -F -x 'upgrade --formula --dry-run git sqlite' \
    "$plan_log" >/dev/null || fail "scoped upgrade dry-run"

echo 'personal macOS Homebrew plan contract: PASS'
exit 0
