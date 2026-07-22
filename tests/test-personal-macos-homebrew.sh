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
cp "$ROOT/profiles/personal-macos/formula-policy-v3.conf" \
    "$PUBLIC/profiles/personal-macos/formula-policy-v3.conf"
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
        awk -v name="$4" '$1 == name { print }' "$BREW_STATE/installed"
        [ "$(awk -v name="$4" '$1 == name { count++ } END { print count + 0 }' \
            "$BREW_STATE/installed")" -gt 0 ]
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
                --formula) ;;
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
        "$PUBLIC/profiles/personal-macos/formula-policy-v3.conf" | tr ',' ' ')
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
        PATH="$FAKE_PREFIX/bin:$FAKE_BIN:/usr/bin:/bin" "$HOMEBREW" "$@"
}

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
    'DEPENDENCIES count=1 scope=validated shared_users=preserved' \
    "UNMANAGED_DEPENDENTS count=0 formulae=''" \
    "RETIRED_DEPENDENTS count=0 formulae=''" \
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

retire_home=$(make_home retire)
retire_state=$(make_brew_state retire)
printf '%s\n' 'bash-completion 1.3' 'pyenv 2.6.0' >>"$retire_state/installed"
FAKE_RETIRED_INTERNAL_DEPENDENT=1 run_homebrew "$retire_home" \
    "$retire_state" "$TEMP_DIR/retire-plan.log" \
    --host mac-test-pilot --plan >"$TEMP_DIR/retire-plan.out"
grep -F -x "RETIRE count=2 formulae='bash-completion pyenv'" \
    "$TEMP_DIR/retire-plan.out" >/dev/null || fail "retirement plan"
if grep -F -x 'uninstall --formula bash-completion pyenv' \
    "$TEMP_DIR/retire-plan.log" >/dev/null; then
    fail "retirement plan mutated Homebrew"
fi
FAKE_RETIRED_INTERNAL_DEPENDENT=1 run_homebrew "$retire_home" \
    "$retire_state" "$TEMP_DIR/retire-apply.log" \
    --host mac-test-pilot --apply >"$TEMP_DIR/retire-apply.out"
grep -F -x 'uninstall --formula bash-completion pyenv' \
    "$TEMP_DIR/retire-apply.log" >/dev/null || fail "bounded retirement apply"
grep -F ' status=complete install=1 upgrade=2 retire=2' \
    "$TEMP_DIR/retire-apply.out" >/dev/null || fail "retirement transaction summary"
if awk '$1 == "bash-completion" || $1 == "pyenv" { found = 1 }
    END { exit found ? 0 : 1 }' "$retire_state/installed"; then
    fail "retired formula remained installed"
fi

retired_dependent_home=$(make_home retired-dependent)
retired_dependent_state=$(make_brew_state retired-dependent)
printf '%s\n' 'pyenv 2.6.0' >>"$retired_dependent_state/installed"
if FAKE_RETIRED_DEPENDENT=1 run_homebrew "$retired_dependent_home" \
    "$retired_dependent_state" "$TEMP_DIR/retired-dependent.log" \
    --host mac-test-pilot --plan >"$TEMP_DIR/retired-dependent.out" 2>&1; then
    fail "retirement plan accepted an installed dependent"
fi
grep -F -x "RETIRED_DEPENDENTS count=1 formulae='personal-tool'" \
    "$TEMP_DIR/retired-dependent.out" >/dev/null || fail "retired-dependent plan"
grep -F -x 'BLOCK macos_homebrew reason=retired-formula-has-installed-dependent' \
    "$TEMP_DIR/retired-dependent.out" >/dev/null || fail "retired-dependent refusal"

apply_home=$(make_home apply)
apply_state=$(make_brew_state apply)
apply_log=$TEMP_DIR/apply.log
run_homebrew "$apply_home" "$apply_state" "$apply_log" \
    --host mac-test-pilot --apply >"$TEMP_DIR/apply.out"
transaction_id=$(sed -n \
    's/^TRANSACTION id=\([^ ]*\) status=complete.*/\1/p' "$TEMP_DIR/apply.out")
[ -n "$transaction_id" ] || fail "Homebrew apply transaction identifier"
transaction_root=$apply_home/.local/state/harness/transactions
status_file=$transaction_root/$transaction_id.macos-homebrew.status
pre_file=$transaction_root/$transaction_id.macos-homebrew.pre.tsv
post_file=$transaction_root/$transaction_id.macos-homebrew.post.tsv
delta_file=$transaction_root/$transaction_id.macos-homebrew.delta.diff
local_apply_log=$transaction_root/$transaction_id.macos-homebrew.apply.log
for private_file in "$status_file" "$pre_file" "$post_file" \
    "$delta_file" "$local_apply_log"; do
    [ "$(file_mode "$private_file")" = 600 ] ||
        fail "Homebrew transaction evidence mode"
done
[ "$(sed -n '1p' "$status_file")" = complete ] ||
    fail "Homebrew transaction completion state"
grep -F -x 'selected|tree|absent' "$pre_file" >/dev/null ||
    fail "missing-formula pre-state evidence"
grep -F -x 'selected|tree|1.0' "$post_file" >/dev/null ||
    fail "installed-formula post-state evidence"
grep -F -x 'dependency|dependency-lib|3.0' "$post_file" >/dev/null ||
    fail "dependency post-state evidence"
grep -F 'selected|git|1.0' "$delta_file" >/dev/null ||
    fail "version delta evidence"
grep -F -x 'END macos_homebrew applied=yes rollback=manual-review-only metadata_refresh=separate' \
    "$TEMP_DIR/apply.out" >/dev/null || fail "irreversible apply summary"
if grep -E '^(update|cleanup|services|tap|bundle)( |$)' "$apply_log" >/dev/null; then
    fail "Homebrew apply used a prohibited command"
fi

before_count=$(find "$transaction_root" -type f \
    -name '*.macos-homebrew.manifest' | wc -l | tr -d ' ')
run_homebrew "$apply_home" "$apply_state" "$TEMP_DIR/noop.log" \
    --host mac-test-pilot --apply >"$TEMP_DIR/noop.out"
after_count=$(find "$transaction_root" -type f \
    -name '*.macos-homebrew.manifest' | wc -l | tr -d ' ')
[ "$before_count" = "$after_count" ] || fail "no-op apply created a transaction"
grep -F -x 'END macos_homebrew changes=none metadata_refresh=separate' \
    "$TEMP_DIR/noop.out" >/dev/null || fail "no-op apply summary"

dependent_home=$(make_home dependent)
dependent_state=$(make_brew_state dependent)
if FAKE_UNMANAGED_DEPENDENT=1 FAKE_UNMANAGED_DEPENDENCY_USER=0 \
    FAKE_PROHIBITED_DRY_RUN=0 FAKE_APPLY_FAILURE=0 \
    run_homebrew "$dependent_home" "$dependent_state" \
    "$TEMP_DIR/dependent.log" --host mac-test-pilot --plan \
    >"$TEMP_DIR/dependent.out" 2>&1; then
    fail "Homebrew plan accepted an unmanaged selected-root dependent"
fi
grep -F -x "UNMANAGED_DEPENDENTS count=1 formulae='personal-tool'" \
    "$TEMP_DIR/dependent.out" >/dev/null || fail "unmanaged-dependent plan"
grep -F -x 'BLOCK macos_homebrew reason=selected-root-has-unmanaged-dependent' \
    "$TEMP_DIR/dependent.out" >/dev/null || fail "unmanaged-dependent refusal"
[ ! -e "$dependent_home/.local" ] ||
    fail "unmanaged-dependent refusal created transaction state"

shared_home=$(make_home shared-dependent)
shared_state=$(make_brew_state shared-dependent)
if ! FAKE_UNMANAGED_DEPENDENT=0 FAKE_UNMANAGED_DEPENDENCY_USER=1 \
    FAKE_PROHIBITED_DRY_RUN=0 FAKE_APPLY_FAILURE=0 \
    run_homebrew "$shared_home" "$shared_state" \
    "$TEMP_DIR/shared.log" --host mac-test-pilot --plan \
    >"$TEMP_DIR/shared.out" 2>&1; then
    fail "Homebrew plan rejected an unmanaged shared-dependency user"
fi
grep -F -x "UNMANAGED_DEPENDENTS count=0 formulae=''" \
    "$TEMP_DIR/shared.out" >/dev/null || fail "shared-dependency user preservation"
if grep -F -x 'uses --installed --recursive --formula dependency-lib' \
    "$TEMP_DIR/shared.log" >/dev/null; then
    fail "Homebrew plan treated a shared dependency as a selected root"
fi

dry_home=$(make_home prohibited-dry-run)
dry_state=$(make_brew_state prohibited-dry-run)
if FAKE_UNMANAGED_DEPENDENT=0 FAKE_UNMANAGED_DEPENDENCY_USER=0 \
    FAKE_PROHIBITED_DRY_RUN=1 FAKE_APPLY_FAILURE=0 \
    run_homebrew "$dry_home" "$dry_state" \
    "$TEMP_DIR/dry.log" --host mac-test-pilot --plan \
    >"$TEMP_DIR/dry.out" 2>&1; then
    fail "Homebrew plan accepted prohibited dry-run scope"
fi
grep -F 'dry-run reported prohibited scope' "$TEMP_DIR/dry.out" >/dev/null ||
    fail "prohibited dry-run refusal"
[ ! -e "$dry_home/.local" ] || fail "prohibited dry-run created state"

failure_home=$(make_home apply-failure)
failure_state=$(make_brew_state apply-failure)
if FAKE_UNMANAGED_DEPENDENT=0 FAKE_UNMANAGED_DEPENDENCY_USER=0 \
    FAKE_PROHIBITED_DRY_RUN=0 FAKE_APPLY_FAILURE=1 \
    run_homebrew "$failure_home" "$failure_state" \
    "$TEMP_DIR/failure.log" --host mac-test-pilot --apply \
    >"$TEMP_DIR/failure.out" 2>&1; then
    fail "injected Homebrew apply failure succeeded"
fi
grep -F 'automatic rollback is unavailable' "$TEMP_DIR/failure.out" >/dev/null ||
    fail "irreversible failure warning"
failure_status=$(find "$failure_home/.local/state/harness/transactions" \
    -type f -name '*.macos-homebrew.status')
[ -n "$failure_status" ] && [ "$(sed -n '1p' "$failure_status")" = failed ] ||
    fail "failed Homebrew transaction state"
failure_post=${failure_status%.status}.post.tsv
failure_delta=${failure_status%.status}.delta.diff
[ -f "$failure_post" ] && [ -f "$failure_delta" ] ||
    fail "failed Homebrew transaction retained no post/delta evidence"

tapped_home=$(make_home tapped-selection)
tapped_private=$tapped_home/.config/harness/private
sed 's/extra_formulae=ninja/extra_formulae=owner\/tap\/formula/' \
    "$tapped_private/hosts/mac-test-pilot.conf" >"$TEMP_DIR/tapped.conf"
mv "$TEMP_DIR/tapped.conf" "$tapped_private/hosts/mac-test-pilot.conf"
chmod 600 "$tapped_private/hosts/mac-test-pilot.conf"
git -C "$tapped_private" add hosts/mac-test-pilot.conf
git -C "$tapped_private" commit -q -m 'synthetic tapped selection'
if run_homebrew "$tapped_home" "$(make_brew_state tapped-selection)" \
    "$TEMP_DIR/tapped.log" --host mac-test-pilot --plan \
    >"$TEMP_DIR/tapped.out" 2>&1; then
    fail "Homebrew plan accepted a tapped formula selection"
fi
grep -F 'selection contains a tap or duplicate' "$TEMP_DIR/tapped.out" >/dev/null ||
    fail "tapped-selection refusal"

echo "personal macOS Homebrew tests: PASS"
