#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
FIXTURE=$ROOT/tests/fixtures/personal-macos/private-v1
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/harness-macos-profile-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEMP_DIR" ]; then
        "$CLEANUP" "$HARNESS" "${TMPDIR:-/tmp}" "$TEMP_DIR" \
            "${TMPDIR:-/tmp}" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then
        echo "FAIL: guarded personal-mac profile cleanup" >&2
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

manifest_probe=$TEMP_DIR/manifest-probe.conf
printf '%s\n' 'duplicate=one' 'duplicate=two' 'equals=a=b' 'empty=' \
    >"$manifest_probe"
printf '%s' bare >>"$manifest_probe"
manifest_read() {
    sh -c '. "$1"; macos_manifest_get "$2" "$3"' _ \
        "$ROOT/libexec/harness-macos-common" "$manifest_probe" "$1"
}
[ "$(manifest_read duplicate)" = "one
two" ] || fail "manifest getter changed duplicate-key output"
[ "$(manifest_read equals)" = 'a=b' ] ||
    fail "manifest getter changed embedded-equals output"
manifest_read empty >"$TEMP_DIR/manifest-empty.out"
[ "$(wc -c <"$TEMP_DIR/manifest-empty.out" | tr -d ' ')" = 1 ] ||
    fail "manifest getter changed empty-value output"
manifest_read bare >"$TEMP_DIR/manifest-bare.out"
[ "$(wc -c <"$TEMP_DIR/manifest-bare.out" | tr -d ' ')" = 1 ] ||
    fail "manifest getter changed delimiter-free output"
manifest_read missing >"$TEMP_DIR/manifest-missing.out" ||
    fail "manifest getter changed missing-key status"
[ ! -s "$TEMP_DIR/manifest-missing.out" ] ||
    fail "manifest getter changed missing-key output"
if sh -c '. "$1"; macos_manifest_get "$2" key' _ \
    "$ROOT/libexec/harness-macos-common" "$TEMP_DIR/absent-manifest" \
    >"$TEMP_DIR/manifest-absent.out" 2>&1; then
    fail "manifest getter accepted an absent file"
fi

checksum_bin=$TEMP_DIR/checksum-bin
mkdir "$checksum_bin"
cat >"$checksum_bin/shasum" <<'EOF'
#!/bin/sh
[ "${MACOS_TEST_CHECKSUM_FAIL:-0}" != 1 ] || exit 7
printf '%s  synthetic path with spaces\n' \
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
EOF
cat >"$checksum_bin/awk" <<'EOF'
#!/bin/sh
exit 99
EOF
chmod 755 "$checksum_bin/shasum" "$checksum_bin/awk"
checksum_value=$(PATH="$checksum_bin:/usr/bin:/bin" \
    sh -c '. "$1"; macos_checksum_file "$2"' _ \
    "$ROOT/libexec/harness-macos-common" "$manifest_probe")
[ "$checksum_value" = \
    aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa ] ||
    fail "checksum helper changed first-field output"
if MACOS_TEST_CHECKSUM_FAIL=1 PATH="$checksum_bin:/usr/bin:/bin" \
    sh -c '. "$1"; macos_checksum_file "$2"' _ \
    "$ROOT/libexec/harness-macos-common" "$manifest_probe" \
    >"$TEMP_DIR/checksum-failure.out" 2>&1; then
    fail "checksum helper suppressed command failure"
fi

make_profile() {
    name=$1
    home=$TEMP_DIR/$name
    private=$home/.config/harness/private
    mkdir -p "$private/hosts"
    cp "$FIXTURE/companion.conf" "$private/companion.conf"
    cp "$FIXTURE/hosts/mac-test-pilot.conf" \
        "$private/hosts/mac-test-pilot.conf"
    cp "$FIXTURE/ssh_config" "$private/ssh_config"
    chmod 700 "$home" "$home/.config" "$home/.config/harness" \
        "$private" "$private/hosts"
    chmod 600 "$private/companion.conf" \
        "$private/hosts/mac-test-pilot.conf" "$private/ssh_config"
    git -C "$private" init -q -b main
    git -C "$private" config user.name mac-test
    git -C "$private" config user.email mac-test.invalid
    git -C "$private" add companion.conf hosts/mac-test-pilot.conf ssh_config
    git -C "$private" commit -q -m 'synthetic private v1'
    chmod 700 "$private/.git"
    printf '%s\n' "$home"
}

valid_home=$(make_profile valid)
valid_output=$(HOME="$valid_home" "$HARNESS" macos-profile \
    --host mac-test-pilot)
expected_output='MACOS_PRIVATE_PROFILE status=valid schema=1 engine_schema=3
SELECTION baseline=macos-cli-v1 capability_groups=2 extra_formulae=1
PUBLIC_FORMULAE count=51
SSH_PAYLOAD state=present values=not-emitted
BASH_PAYLOAD state=absent values=not-emitted
TMUX_PAYLOAD state=absent values=not-emitted
END private_profile values=not-emitted'
[ "$valid_output" = "$expected_output" ] || fail "valid value-free output"
case "$valid_output" in
    *language*|*agents*|*sqlite*|*ninja*|*mac-test-pilot*|*"$valid_home"*)
        fail "valid output exposed private profile values"
        ;;
esac

echo 'personal macOS profile essential contract: PASS'
exit 0
