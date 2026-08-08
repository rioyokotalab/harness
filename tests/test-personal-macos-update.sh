#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
UPDATE=$ROOT/libexec/harness-macos-update
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/harness-macos-update-test.XXXXXX")
UPDATE_TMP=$TEMP_DIR/update-tmp
mkdir "$UPDATE_TMP"
chmod 700 "$UPDATE_TMP"
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

run_update() {
    TMPDIR=$UPDATE_TMP "$@"
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
legacy_formula_policy=$TEMP_DIR/legacy-formula-policy-v2.conf
cat >"$legacy_formula_policy" <<'EOF'
schema=2
family=personal-macos
managed_formulae=bash,bash-completion@2,git,git-lfs,tmux,ripgrep,jq,tree,shellcheck,uv
retired_formulae=bash-completion,pyenv
EOF
cmp -s "$legacy_formula_policy" \
    "$ROOT/profiles/personal-macos/formula-policy-v2.conf" ||
    fail "formula policy v2 no longer passes the frozen updater contract"
[ "$(git hash-object "$ROOT/profiles/personal-macos/formula-policy-v3.conf")" = \
    37c7c2ba1865bdef51fa84f65f3d1ccaca30f8e9 ] ||
    fail "formula policy v3 no longer passes the frozen updater contract"

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
    cp "$ROOT/profiles/personal-macos/formula-policy-v2.conf" \
        "$public_source/profiles/personal-macos/formula-policy-v2.conf"
    cp "$ROOT/profiles/personal-macos/formula-policy-v3.conf" \
        "$public_source/profiles/personal-macos/formula-policy-v3.conf"
    cp "$ROOT/profiles/personal-macos/formula-policy-v4.conf" \
        "$public_source/profiles/personal-macos/formula-policy-v4.conf"
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
        language,agents ninja,cmake
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
    run_update "$UPDATE" --host mac-test-pilot \
    --public-target "$primary_public_target" \
    --private-target "$primary_private_target" --plan)
printf '%s\n' "$plan_output" | grep -F \
    'MACOS_UPDATE mode=plan public=fast-forward private=fast-forward' \
    >/dev/null || fail "direct long-gap plan"
printf '%s\n' "$plan_output" | grep -F \
    'COMPAT engine_schema=3 private_schema=1' >/dev/null ||
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
    run_update "$UPDATE" --host mac-test-pilot \
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
    run_update "$primary_public/libexec/harness-macos-update" \
    --host mac-test-pilot \
    --public-target "$primary_public_target" \
    --private-target "$primary_private_target" --plan)
printf '%s\n' "$second_plan" | grep -F \
    'MACOS_UPDATE mode=plan public=current private=current' >/dev/null ||
    fail "idempotent checkout plan"
printf '%s\n' "$second_plan" | grep -F 'MIGRATION state=current' >/dev/null ||
    fail "idempotent state plan"
second_apply=$(HOME="$primary_home" HARNESS_ROOT="$primary_public" \
    run_update "$primary_public/libexec/harness-macos-update" \
    --host mac-test-pilot \
    --public-target "$primary_public_target" \
    --private-target "$primary_private_target" --apply)
printf '%s\n' "$second_apply" | grep -F 'END macos_update changes=none' \
    >/dev/null || fail "idempotent second apply"

rollback_output=$(HOME="$primary_home" HARNESS_ROOT="$primary_public" \
    run_update "$primary_public/libexec/harness-macos-update" \
    --rollback "$transaction")
printf '%s\n' "$rollback_output" | grep -F \
    "TRANSACTION id=$transaction status=rolled-back repositories=current" \
    >/dev/null || fail "state rollback result"
[ ! -e "$state_file" ] || fail "initial state rollback did not restore absence"
[ "$(git -C "$primary_public" rev-parse HEAD)" = "$primary_public_target" ] &&
    [ "$(git -C "$primary_private" rev-parse HEAD)" = \
        "$primary_private_target" ] || fail "state rollback rewound a checkout"

echo 'personal macOS update essential contract: PASS'
exit 0
