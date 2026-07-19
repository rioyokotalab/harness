#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
UPDATE=$ROOT/libexec/harness-macos-update
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/harness-macos-update-test.XXXXXX")
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
        echo "FAIL: guarded personal-Mac update cleanup" >&2
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
        Darwin) stat -f %Lp "$1" ;;
        *) stat -c %a "$1" ;;
    esac
}

# Engine-1 deployments validate this exact public contract before they can
# fast-forward and re-exec the newer updater. Keep the baseline compatible so
# very old Macs can cross the engine-1-to-engine-2 handoff in one update.
legacy_public_profile=$TEMP_DIR/legacy-public-profile.conf
cat >"$legacy_public_profile" <<'EOF'
schema=1
family=personal-macos
private_schema_min=1
private_schema_max=1
baseline=macos-cli-v1
managed_formulae=bash,git,git-lfs,tmux,ripgrep,jq,tree,shellcheck
EOF
cmp -s "$legacy_public_profile" "$ROOT/profiles/personal-macos/base.conf" ||
    fail "public baseline no longer passes the frozen engine-1 contract"

configure_identity() {
    git -C "$1" config user.name mac-test
    git -C "$1" config user.email mac-test.invalid
}

write_private_host() {
    private_file=$1
    groups=$2
    formulae=$3
    cat >"$private_file" <<EOF
schema=1
logical_id=mac-test-pilot
baseline=macos-cli-v1
capability_groups=$groups
extra_formulae=$formulae
EOF
    chmod 600 "$private_file"
}

setup_pair() {
    pair_name=$1
    public_source=$TEMP_DIR/$pair_name-public-source
    public_origin=$TEMP_DIR/$pair_name-public-origin.git
    public_work=$TEMP_DIR/$pair_name-public-work
    private_source=$TEMP_DIR/$pair_name-private-source
    private_origin=$TEMP_DIR/$pair_name-private-origin.git
    pair_home=$TEMP_DIR/$pair_name-home
    private_work=$pair_home/.config/harness/private

    mkdir -p "$public_source/profiles/personal-macos" \
        "$public_source/libexec"
    cp "$ROOT/profiles/personal-macos/base.conf" \
        "$public_source/profiles/personal-macos/base.conf"
    cp -p "$ROOT/libexec/harness-common" \
        "$ROOT/libexec/harness-macos-common" \
        "$ROOT/libexec/harness-macos-profile" \
        "$ROOT/libexec/harness-macos-update" "$public_source/libexec/"
    git -C "$public_source" init -q -b main
    configure_identity "$public_source"
    git -C "$public_source" add profiles libexec
    git -C "$public_source" commit -q -m 'synthetic public v1 old'
    public_old=$(git -C "$public_source" rev-parse HEAD)
    git init -q --bare -b main "$public_origin"
    git -C "$public_source" remote add origin "$public_origin"
    git -C "$public_source" push -q -u origin main
    git clone -q "$public_origin" "$public_work"

    printf '%s\n' current-release >"$public_source/release.txt"
    git -C "$public_source" add release.txt
    git -C "$public_source" commit -q -m 'synthetic public v1 current'
    git -C "$public_source" push -q origin main
    git -C "$public_work" fetch -q origin
    public_target=$(git -C "$public_work" rev-parse refs/remotes/origin/main)

    mkdir -p "$private_source/hosts"
    cp "$ROOT/tests/fixtures/personal-macos/private-v1/companion.conf" \
        "$private_source/companion.conf"
    write_private_host "$private_source/hosts/mac-test-pilot.conf" none none
    git -C "$private_source" init -q -b main
    configure_identity "$private_source"
    git -C "$private_source" add companion.conf hosts/mac-test-pilot.conf
    git -C "$private_source" commit -q -m 'synthetic private v1 old'
    private_old=$(git -C "$private_source" rev-parse HEAD)
    git init -q --bare -b main "$private_origin"
    git -C "$private_source" remote add origin "$private_origin"
    git -C "$private_source" push -q -u origin main
    mkdir -p "$pair_home/.config/harness"
    git clone -q "$private_origin" "$private_work"

    write_private_host "$private_source/hosts/mac-test-pilot.conf" \
        language,agents sqlite,ninja
    cp "$ROOT/tests/fixtures/personal-macos/private-v1/ssh_config" \
        "$private_source/ssh_config"
    chmod 600 "$private_source/ssh_config"
    git -C "$private_source" add hosts/mac-test-pilot.conf ssh_config
    git -C "$private_source" commit -q -m 'synthetic private v1 current'
    git -C "$private_source" push -q origin main
    git -C "$private_work" fetch -q origin
    private_target=$(git -C "$private_work" rev-parse refs/remotes/origin/main)

    chmod 700 "$pair_home" "$pair_home/.config" \
        "$pair_home/.config/harness" "$private_work" \
        "$private_work/.git" "$private_work/hosts"
    chmod 600 "$private_work/companion.conf" \
        "$private_work/hosts/mac-test-pilot.conf"

    printf '%s|%s|%s|%s|%s|%s|%s\n' "$pair_home" "$public_work" \
        "$private_work" "$public_old" "$public_target" "$private_old" \
        "$private_target"
}

IFS='|' read -r primary_home primary_public primary_private \
    primary_public_old primary_public_target primary_private_old \
    primary_private_target <<EOF
$(setup_pair primary)
EOF

plan_output=$(HOME="$primary_home" HARNESS_ROOT="$primary_public" \
    "$UPDATE" --host mac-test-pilot \
    --public-target "$primary_public_target" \
    --private-target "$primary_private_target" --plan)
printf '%s\n' "$plan_output" | grep -F \
    'MACOS_UPDATE mode=plan public=fast-forward private=fast-forward' \
    >/dev/null || fail "direct long-gap plan"
printf '%s\n' "$plan_output" | grep -F \
    'COMPAT engine_schema=2 private_schema=1' >/dev/null ||
    fail "engine/private compatibility plan"
printf '%s\n' "$plan_output" | grep -F \
    'MIGRATION state=initialize' >/dev/null || fail "v1 initialization plan"
[ "$(git -C "$primary_public" rev-parse HEAD)" = "$primary_public_old" ] ||
    fail "plan changed public checkout"
[ "$(git -C "$primary_private" rev-parse HEAD)" = "$primary_private_old" ] ||
    fail "plan changed private checkout"
[ ! -e "$primary_home/.local/state/harness/personal-macos/state.conf" ] ||
    fail "plan created local state"

apply_output=$(HOME="$primary_home" HARNESS_ROOT="$primary_public" \
    "$UPDATE" --host mac-test-pilot \
    --public-target "$primary_public_target" \
    --private-target "$primary_private_target" --apply)
transaction=$(printf '%s\n' "$apply_output" |
    sed -n 's/^TRANSACTION id=\([^ ]*\) status=complete$/\1/p' | tail -n 1)
[ -n "$transaction" ] || fail "missing update transaction"
[ "$(git -C "$primary_public" rev-parse HEAD)" = "$primary_public_target" ] ||
    fail "public checkout did not fast-forward"
[ "$(git -C "$primary_private" rev-parse HEAD)" = "$primary_private_target" ] ||
    fail "private checkout did not fast-forward"
state_file=$primary_home/.local/state/harness/personal-macos/state.conf
[ -f "$state_file" ] && [ ! -L "$state_file" ] || fail "missing v1 state"
[ "$(file_mode "$state_file")" = 600 ] || fail "unsafe v1 state mode"
grep -F "public_revision=$primary_public_target" "$state_file" >/dev/null ||
    fail "state missing public target"
grep -F "private_revision=$primary_private_target" "$state_file" >/dev/null ||
    fail "state missing private target"

second_plan=$(HOME="$primary_home" HARNESS_ROOT="$primary_public" \
    "$primary_public/libexec/harness-macos-update" --host mac-test-pilot \
    --public-target "$primary_public_target" \
    --private-target "$primary_private_target" --plan)
printf '%s\n' "$second_plan" | grep -F \
    'MACOS_UPDATE mode=plan public=current private=current' >/dev/null ||
    fail "idempotent checkout plan"
printf '%s\n' "$second_plan" | grep -F 'MIGRATION state=current' >/dev/null ||
    fail "idempotent state plan"
second_apply=$(HOME="$primary_home" HARNESS_ROOT="$primary_public" \
    "$primary_public/libexec/harness-macos-update" --host mac-test-pilot \
    --public-target "$primary_public_target" \
    --private-target "$primary_private_target" --apply)
printf '%s\n' "$second_apply" | grep -F 'END macos_update changes=none' \
    >/dev/null || fail "idempotent second apply"

rollback_output=$(HOME="$primary_home" HARNESS_ROOT="$primary_public" \
    "$primary_public/libexec/harness-macos-update" --rollback "$transaction")
printf '%s\n' "$rollback_output" | grep -F \
    "TRANSACTION id=$transaction status=rolled-back repositories=current" \
    >/dev/null || fail "state rollback result"
[ ! -e "$state_file" ] || fail "initial state rollback did not restore absence"
[ "$(git -C "$primary_public" rev-parse HEAD)" = "$primary_public_target" ] &&
    [ "$(git -C "$primary_private" rev-parse HEAD)" = \
        "$primary_private_target" ] || fail "state rollback rewound a checkout"

reapply_output=$(HOME="$primary_home" HARNESS_ROOT="$primary_public" \
    "$primary_public/libexec/harness-macos-update" --host mac-test-pilot \
    --public-target "$primary_public_target" \
    --private-target "$primary_private_target" --apply)
printf '%s\n' "$reapply_output" | grep -F 'END macos_update changes=applied' \
    >/dev/null || fail "reapply after rollback"

primary_public_source=$TEMP_DIR/primary-public-source
primary_private_source=$TEMP_DIR/primary-private-source
printf '%s\n' next-release >"$primary_public_source/release.txt"
git -C "$primary_public_source" add release.txt
git -C "$primary_public_source" commit -q -m 'synthetic later public v1'
git -C "$primary_public_source" push -q origin main
git -C "$primary_public" fetch -q origin
later_public_target=$(git -C "$primary_public" \
    rev-parse refs/remotes/origin/main)
write_private_host "$primary_private_source/hosts/mac-test-pilot.conf" \
    language,agents data-tools sqlite,ninja,wget
git -C "$primary_private_source" add hosts/mac-test-pilot.conf
git -C "$primary_private_source" commit -q -m 'synthetic later private v1'
git -C "$primary_private_source" push -q origin main
git -C "$primary_private" fetch -q origin
later_private_target=$(git -C "$primary_private" \
    rev-parse refs/remotes/origin/main)

later_plan=$(HOME="$primary_home" HARNESS_ROOT="$primary_public" \
    "$primary_public/libexec/harness-macos-update" --host mac-test-pilot \
    --public-target "$later_public_target" \
    --private-target "$later_private_target" --plan)
printf '%s\n' "$later_plan" | grep -F 'MIGRATION state=migrate-v1' \
    >/dev/null || fail "existing v1 migration plan"
later_apply=$(HOME="$primary_home" HARNESS_ROOT="$primary_public" \
    "$primary_public/libexec/harness-macos-update" --host mac-test-pilot \
    --public-target "$later_public_target" \
    --private-target "$later_private_target" --apply)
later_transaction=$(printf '%s\n' "$later_apply" |
    sed -n 's/^TRANSACTION id=\([^ ]*\) status=complete$/\1/p' | tail -n 1)
[ -n "$later_transaction" ] || fail "missing existing-state transaction"
cp "$state_file" "$TEMP_DIR/later-state.saved"
printf '%s\n' 'changed=after-apply' >>"$state_file"
if HOME="$primary_home" HARNESS_ROOT="$primary_public" \
    "$primary_public/libexec/harness-macos-update" \
    --rollback "$later_transaction" >"$TEMP_DIR/changed-state.out" 2>&1; then
    fail "rollback accepted changed local state"
fi
grep -F 'Mac update rollback blocked by changed state' \
    "$TEMP_DIR/changed-state.out" >/dev/null || fail "changed-state refusal"
mv "$TEMP_DIR/later-state.saved" "$state_file"
chmod 600 "$state_file"
HOME="$primary_home" HARNESS_ROOT="$primary_public" \
    "$primary_public/libexec/harness-macos-update" \
    --rollback "$later_transaction" >/dev/null
if ! grep -F "public_revision=$primary_public_target" \
    "$state_file" >/dev/null ||
    ! grep -F "private_revision=$primary_private_target" \
    "$state_file" >/dev/null; then
    fail "existing-state rollback did not restore prior v1 state"
fi
[ "$(git -C "$primary_public" rev-parse HEAD)" = "$later_public_target" ] &&
    [ "$(git -C "$primary_private" rev-parse HEAD)" = \
        "$later_private_target" ] || fail "existing-state rollback rewound checkouts"

IFS='|' read -r partial_home partial_public partial_private \
    partial_public_old partial_public_target partial_private_old \
    partial_private_target <<EOF
$(setup_pair partial)
EOF
[ "$(git -C "$partial_public" rev-parse HEAD)" = "$partial_public_old" ] ||
    fail "partial-update fixture public baseline"
fake_bin=$TEMP_DIR/fake-bin
mkdir -p "$fake_bin"
cat >"$fake_bin/git" <<'EOF'
#!/bin/sh
if [ "$1" = -C ] && [ "$2" = "$FAIL_PRIVATE_CHECKOUT" ] &&
    [ "$3" = merge ] && [ "$4" = --ff-only ]; then
    exit 42
fi
exec "$REAL_GIT" "$@"
EOF
chmod 755 "$fake_bin/git"
real_git=$(command -v git)
if HOME="$partial_home" HARNESS_ROOT="$partial_public" \
    FAIL_PRIVATE_CHECKOUT="$partial_private" REAL_GIT="$real_git" \
    PATH="$fake_bin:/usr/bin:/bin" "$UPDATE" --host mac-test-pilot \
    --public-target "$partial_public_target" \
    --private-target "$partial_private_target" --apply \
    >"$TEMP_DIR/partial-failure.out" 2>&1; then
    fail "injected private fast-forward failure succeeded"
fi
grep -F 'private checkout fast-forward failed after public update; retry is safe' \
    "$TEMP_DIR/partial-failure.out" >/dev/null ||
    fail "partial-update failure was not explicit"
[ "$(git -C "$partial_public" rev-parse HEAD)" = "$partial_public_target" ] ||
    fail "partial-update test did not advance public checkout"
[ "$(git -C "$partial_private" rev-parse HEAD)" = "$partial_private_old" ] ||
    fail "partial-update failure changed private checkout"
[ ! -e "$partial_home/.local/state/harness/personal-macos/state.conf" ] ||
    fail "partial-update failure changed local state"

retry_output=$(HOME="$partial_home" HARNESS_ROOT="$partial_public" \
    "$partial_public/libexec/harness-macos-update" --host mac-test-pilot \
    --public-target "$partial_public_target" \
    --private-target "$partial_private_target" --apply)
printf '%s\n' "$retry_output" | grep -F 'END macos_update changes=applied' \
    >/dev/null || fail "partial-update retry"
[ "$(git -C "$partial_private" rev-parse HEAD)" = "$partial_private_target" ] ||
    fail "partial-update retry did not advance private checkout"

IFS='|' read -r incompatible_home incompatible_public incompatible_private \
    incompatible_public_old incompatible_public_target incompatible_private_old \
    incompatible_private_target <<EOF
$(setup_pair incompatible)
EOF
incompatible_source=$TEMP_DIR/incompatible-private-source
sed 's/schema=1/schema=2/' "$incompatible_source/companion.conf" \
    >"$TEMP_DIR/incompatible-companion.new"
mv "$TEMP_DIR/incompatible-companion.new" \
    "$incompatible_source/companion.conf"
sed 's/schema=1/schema=2/' \
    "$incompatible_source/hosts/mac-test-pilot.conf" \
    >"$TEMP_DIR/incompatible-host.new"
mv "$TEMP_DIR/incompatible-host.new" \
    "$incompatible_source/hosts/mac-test-pilot.conf"
git -C "$incompatible_source" add companion.conf hosts/mac-test-pilot.conf
git -C "$incompatible_source" commit -q -m 'synthetic incompatible schema'
git -C "$incompatible_source" push -q origin main
git -C "$incompatible_private" fetch -q origin
incompatible_private_target=$(git -C "$incompatible_private" \
    rev-parse refs/remotes/origin/main)
if HOME="$incompatible_home" HARNESS_ROOT="$incompatible_public" \
    "$UPDATE" --host mac-test-pilot \
    --public-target "$incompatible_public_target" \
    --private-target "$incompatible_private_target" --plan \
    >"$TEMP_DIR/incompatible.out" 2>&1; then
    fail "incompatible target schema accepted"
fi
grep -F 'private companion schema is incompatible' \
    "$TEMP_DIR/incompatible.out" >/dev/null ||
    fail "incompatible target schema refusal"
[ "$(git -C "$incompatible_public" rev-parse HEAD)" = \
    "$incompatible_public_old" ] &&
    [ "$(git -C "$incompatible_private" rev-parse HEAD)" = \
        "$incompatible_private_old" ] ||
    fail "incompatible target plan changed a checkout"

IFS='|' read -r layout_home layout_public layout_private \
    layout_public_old layout_public_target layout_private_old \
    layout_private_target <<EOF
$(setup_pair target-layout)
EOF
layout_source=$TEMP_DIR/target-layout-private-source
target_layout_sentinel=PRIVATE_TARGET_COPIED_CONFIG
printf '%s\n' "$target_layout_sentinel" >"$layout_source/copied-config.txt"
git -C "$layout_source" add copied-config.txt
git -C "$layout_source" commit -q -m 'synthetic prohibited target layout'
git -C "$layout_source" push -q origin main
git -C "$layout_private" fetch -q origin
layout_private_target=$(git -C "$layout_private" \
    rev-parse refs/remotes/origin/main)
if HOME="$layout_home" HARNESS_ROOT="$layout_public" \
    "$UPDATE" --host mac-test-pilot --public-target "$layout_public_target" \
    --private-target "$layout_private_target" --plan \
    >"$TEMP_DIR/target-layout.out" 2>&1; then
    fail "prohibited private target layout accepted"
fi
grep -F 'private target tracked layout is invalid' \
    "$TEMP_DIR/target-layout.out" >/dev/null ||
    fail "private target layout refusal"
if grep -F "$target_layout_sentinel" "$TEMP_DIR/target-layout.out" >/dev/null ||
    grep -F "$layout_home" "$TEMP_DIR/target-layout.out" >/dev/null; then
    fail "private target layout refusal exposed private content"
fi
[ "$(git -C "$layout_public" rev-parse HEAD)" = "$layout_public_old" ] &&
    [ "$(git -C "$layout_private" rev-parse HEAD)" = \
        "$layout_private_old" ] || fail "target layout plan changed a checkout"

# shellcheck disable=SC2034
IFS='|' read -r bundle_home bundle_public bundle_private \
    bundle_public_old bundle_public_target bundle_private_old \
    bundle_private_target <<EOF
$(setup_pair config-bundle)
EOF
bundle_source=$TEMP_DIR/config-bundle-private-source
cp "$ROOT/tests/fixtures/personal-macos/private-v2/companion.conf" \
    "$bundle_source/companion.conf"
cp "$ROOT/tests/fixtures/personal-macos/private-v2/bashrc" \
    "$bundle_source/bashrc"
cp "$ROOT/tests/fixtures/personal-macos/private-v2/tmux.conf" \
    "$bundle_source/tmux.conf"
chmod 600 "$bundle_source/companion.conf" "$bundle_source/bashrc" \
    "$bundle_source/tmux.conf"
git -C "$bundle_source" add companion.conf bashrc tmux.conf
git -C "$bundle_source" commit -q -m 'synthetic engine-2 config bundle'
git -C "$bundle_source" push -q origin main
git -C "$bundle_private" fetch -q origin
bundle_private_target=$(git -C "$bundle_private" \
    rev-parse refs/remotes/origin/main)
bundle_plan=$(HOME="$bundle_home" HARNESS_ROOT="$bundle_public" \
    "$UPDATE" --host mac-test-pilot --public-target "$bundle_public_target" \
    --private-target "$bundle_private_target" --plan)
printf '%s\n' "$bundle_plan" | grep -F \
    'COMPAT engine_schema=2 private_schema=1' >/dev/null ||
    fail "engine-2 config bundle target"

# shellcheck disable=SC2034
IFS='|' read -r incomplete_home incomplete_public incomplete_private \
    incomplete_public_old incomplete_public_target incomplete_private_old \
    incomplete_private_target <<EOF
$(setup_pair incomplete-bundle)
EOF
incomplete_source=$TEMP_DIR/incomplete-bundle-private-source
cp "$ROOT/tests/fixtures/personal-macos/private-v2/companion.conf" \
    "$incomplete_source/companion.conf"
cp "$ROOT/tests/fixtures/personal-macos/private-v2/bashrc" \
    "$incomplete_source/bashrc"
chmod 600 "$incomplete_source/companion.conf" "$incomplete_source/bashrc"
git -C "$incomplete_source" add companion.conf bashrc
git -C "$incomplete_source" commit -q -m 'synthetic incomplete engine-2 bundle'
git -C "$incomplete_source" push -q origin main
git -C "$incomplete_private" fetch -q origin
incomplete_private_target=$(git -C "$incomplete_private" \
    rev-parse refs/remotes/origin/main)
if HOME="$incomplete_home" HARNESS_ROOT="$incomplete_public" \
    "$UPDATE" --host mac-test-pilot \
    --public-target "$incomplete_public_target" \
    --private-target "$incomplete_private_target" --plan \
    >"$TEMP_DIR/incomplete-target.out" 2>&1; then
    fail "incomplete engine-2 target accepted"
fi
grep -F 'payload set is incomplete or incompatible' \
    "$TEMP_DIR/incomplete-target.out" >/dev/null ||
    fail "incomplete engine-2 target refusal"

echo "personal macOS long-gap update tests passed"
