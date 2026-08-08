#!/bin/sh
set -eu
umask 077

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/harness-macos-ssh-sync-test.XXXXXX")
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
        echo "FAIL: guarded Mac SSH-sync cleanup" >&2
        status=1
    fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

fail() { echo "FAIL: $*" >&2; exit 1; }
file_mode() {
    case $(uname -s) in Darwin) /usr/bin/stat -f %Lp "$1" ;; *) /usr/bin/stat -c %a "$1" ;; esac
}

fake_bin=$TEMP_DIR/fake-bin
mkdir "$fake_bin"
cat >"$fake_bin/uname" <<'EOF'
#!/bin/sh
echo Darwin
EOF
cat >"$fake_bin/stat" <<'EOF'
#!/bin/sh
if [ "$1" = -f ]; then
    case "$2" in
        %u) format=%u ;;
        %Lp) format=%a ;;
        %l) format=%h ;;
        *) exit 2 ;;
    esac
    shift 2
    [ "${1:-}" != -- ] || shift
    case $(/usr/bin/uname -s) in
        Darwin)
            case "$format" in %a) format=%Lp ;; %h) format=%l ;; esac
            exec /usr/bin/stat -f "$format" "$1"
            ;;
        *) exec /usr/bin/stat -c "$format" -- "$1" ;;
    esac
fi
exec /usr/bin/stat "$@"
EOF
cat >"$fake_bin/mv" <<'EOF'
#!/bin/sh
last=
for argument do last=$argument; done
if [ -n "${MACOS_TEST_FAIL_DEST:-}" ] &&
   [ "$last" = "$MACOS_TEST_FAIL_DEST" ] &&
   [ ! -e "${MACOS_TEST_FAIL_MARKER:-}" ]; then
    : >"$MACOS_TEST_FAIL_MARKER"
    exit 42
fi
exec /bin/mv "$@"
EOF
chmod 755 "$fake_bin/uname" "$fake_bin/stat" "$fake_bin/mv"

configure_identity() {
    git -C "$1" config user.name mac-test
    git -C "$1" config user.email mac-test.invalid
}

public=$TEMP_DIR/public
mkdir -p "$public/libexec" "$public/profiles/personal-macos" "$public/config/ssh"
cp -p "$ROOT/libexec/harness-common" "$ROOT/libexec/harness-macos-common" \
    "$ROOT/libexec/harness-macos-profile" \
    "$ROOT/libexec/harness-macos-ssh-sync" \
    "$ROOT/libexec/harness-ssh-config-layout" "$public/libexec/"
cp "$ROOT/config/ssh/harness.conf" "$public/config/ssh/harness.conf"
cp "$ROOT/profiles/personal-macos/base.conf" \
    "$public/profiles/personal-macos/base.conf"
cp "$ROOT/profiles/personal-macos/formula-policy-v4.conf" \
    "$public/profiles/personal-macos/formula-policy-v4.conf"
git -C "$public" init -q -b main
configure_identity "$public"
git -C "$public" add libexec profiles config
git -C "$public" commit -q -m 'synthetic public SSH sync engine'
chmod 700 "$public/.git"
SYNC=$public/libexec/harness-macos-ssh-sync

setup_home() {
    name=$1
    home=$TEMP_DIR/$name-home
    origin=$TEMP_DIR/$name-origin.git
    writer=$TEMP_DIR/$name-writer
    private=$home/.config/harness/private
    mkdir -p "$private/hosts" "$home/.ssh"
    cp "$ROOT/tests/fixtures/personal-macos/private-v1/companion.conf" \
        "$private/companion.conf"
    cp "$ROOT/tests/fixtures/personal-macos/private-v1/hosts/mac-test-pilot.conf" \
        "$private/hosts/mac-test-pilot.conf"
    chmod 600 "$private/companion.conf" "$private/hosts/mac-test-pilot.conf"
    git -C "$private" init -q -b main
    configure_identity "$private"
    git -C "$private" add companion.conf hosts/mac-test-pilot.conf
    git -C "$private" commit -q -m 'synthetic private pre-adoption'
    git init -q --bare -b main "$origin"
    git -C "$private" remote add origin "$origin"
    git -C "$private" push -q -u origin main
    configure_identity "$private"
    cp "$ROOT/tests/fixtures/personal-macos/private-v1/ssh_config" \
        "$home/.ssh/config"
    chmod 700 "$home" "$home/.config" "$home/.config/harness" \
        "$home/.ssh" "$private" "$private/.git" "$private/hosts"
    chmod 600 "$home/.ssh/config" "$private/companion.conf" \
        "$private/hosts/mac-test-pilot.conf"
    printf '%s|%s|%s|%s\n' "$home" "$private" "$writer" "$origin"
}

run_sync() {
    test_home=$1
    shift
    HOME="$test_home" HARNESS_ROOT="$public" HARNESS_TESTING=1 \
        PATH="$fake_bin:/usr/bin:/bin" "$SYNC" "$@"
}

IFS='|' read -r home private writer origin <<EOF
$(setup_home primary)
EOF

case ${HARNESS_TEST_CASE:-plan} in
    plan) ;;
    apply) ;;
    *) fail "unknown essential SSH-sync case" ;;
esac

if [ "${HARNESS_TEST_CASE:-plan}" = plan ]; then
seed_required=$(run_sync "$home" --host mac-test-pilot --plan)
[ "$seed_required" = \
    'MACOS_SSH_SYNC class=current agreement=no action=seed-required' ] ||
    fail "first-adoption seed requirement"
seed_plan=$(run_sync "$home" --host mac-test-pilot --seed --plan)
printf '%s\n' "$seed_plan" | grep -F \
    'class=current agreement=no action=seed apply=not-requested' >/dev/null ||
    fail "first-seed plan"
git -C "$private" cat-file -e HEAD:ssh_config 2>/dev/null &&
    fail "seed plan changed private repository"
echo 'personal macOS SSH sync plan contract: PASS'
exit 0
fi

seed_apply=$(run_sync "$home" --host mac-test-pilot --seed --apply)
printf '%s\n' "$seed_apply" | grep -F \
    'class=current agreement=yes action=applied' >/dev/null || fail "first seed apply"
[ "$(file_mode "$home/.ssh/config")" = 600 ] ||
    fail "first seed did not normalize destination mode"
cmp -s "$home/.ssh/config" "$private/ssh_config" || fail "seed content agreement"
[ -f "$home/.local/state/harness/personal-macos/ssh-sync.conf" ] ||
    fail "first seed omitted state"

echo 'personal macOS SSH sync apply contract: PASS'
exit 0
