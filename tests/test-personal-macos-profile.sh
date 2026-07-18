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
expected_output='MACOS_PRIVATE_PROFILE status=valid schema=1 engine_schema=1
SELECTION baseline=macos-cli-v1 capability_groups=2 extra_formulae=2
PUBLIC_FORMULAE count=8
SSH_PAYLOAD state=present values=not-emitted
END private_profile values=not-emitted'
[ "$valid_output" = "$expected_output" ] || fail "valid value-free output"
case "$valid_output" in
    *language*|*agents*|*sqlite*|*ninja*|*mac-test-pilot*|*"$valid_home"*)
        fail "valid output exposed private profile values"
        ;;
esac

absent_home=$(make_profile payload-absent)
git -C "$absent_home/.config/harness/private" rm -q ssh_config
git -C "$absent_home/.config/harness/private" commit -q -m \
    'synthetic pre-adoption layout'
absent_output=$(HOME="$absent_home" "$HARNESS" macos-profile \
    --host mac-test-pilot)
printf '%s\n' "$absent_output" | grep -F \
    'SSH_PAYLOAD state=absent values=not-emitted' >/dev/null ||
    fail "pre-adoption payload absence"

payload_mode_home=$(make_profile payload-mode)
chmod 644 "$payload_mode_home/.config/harness/private/ssh_config"
if HOME="$payload_mode_home" "$HARNESS" macos-profile --host mac-test-pilot \
    >"$TEMP_DIR/payload-mode.out" 2>&1; then
    fail "unsafe SSH payload mode accepted"
fi
grep -F 'SSH configuration has unsafe mode' \
    "$TEMP_DIR/payload-mode.out" >/dev/null || fail "SSH payload mode refusal"

payload_link_home=$(make_profile payload-link)
mv "$payload_link_home/.config/harness/private/ssh_config" \
    "$payload_link_home/.config/harness/private/ssh_config.real"
ln -s ssh_config.real "$payload_link_home/.config/harness/private/ssh_config"
if HOME="$payload_link_home" "$HARNESS" macos-profile --host mac-test-pilot \
    >"$TEMP_DIR/payload-link.out" 2>&1; then
    fail "symlink SSH payload accepted"
fi
grep -F 'SSH configuration has unsafe type' \
    "$TEMP_DIR/payload-link.out" >/dev/null || fail "SSH payload symlink refusal"

payload_hardlink_home=$(make_profile payload-hardlink)
ln "$payload_hardlink_home/.config/harness/private/ssh_config" \
    "$payload_hardlink_home/.config/harness/private/ssh_config.second"
if HOME="$payload_hardlink_home" "$HARNESS" macos-profile --host mac-test-pilot \
    >"$TEMP_DIR/payload-hardlink.out" 2>&1; then
    fail "hard-linked SSH payload accepted"
fi
grep -F 'SSH configuration has unsafe link count' \
    "$TEMP_DIR/payload-hardlink.out" >/dev/null || fail "SSH payload hard-link refusal"

payload_grammar_home=$(make_profile payload-grammar)
payload_sentinel=PRIVATE_SSH_SENTINEL
printf '%s\n' "Host $payload_sentinel" '    ProxyCommand "unterminated' > \
    "$payload_grammar_home/.config/harness/private/ssh_config"
chmod 600 "$payload_grammar_home/.config/harness/private/ssh_config"
if HOME="$payload_grammar_home" "$HARNESS" macos-profile --host mac-test-pilot \
    >"$TEMP_DIR/payload-grammar.out" 2>&1; then
    fail "invalid SSH payload grammar accepted"
fi
grep -F 'SSH configuration grammar is invalid' \
    "$TEMP_DIR/payload-grammar.out" >/dev/null || fail "SSH payload grammar refusal"
if grep -F "$payload_sentinel" "$TEMP_DIR/payload-grammar.out" >/dev/null; then
    fail "SSH payload grammar refusal exposed private content"
fi

payload_key_home=$(make_profile payload-key)
printf '%s\n' '-----BEGIN OPENSSH PRIVATE KEY-----' > \
    "$payload_key_home/.config/harness/private/ssh_config"
chmod 600 "$payload_key_home/.config/harness/private/ssh_config"
if HOME="$payload_key_home" "$HARNESS" macos-profile --host mac-test-pilot \
    >"$TEMP_DIR/payload-key.out" 2>&1; then
    fail "credential material in SSH payload accepted"
fi
grep -F 'SSH configuration contains prohibited credential material' \
    "$TEMP_DIR/payload-key.out" >/dev/null || fail "credential material refusal"

payload_include_home=$(make_profile payload-include)
printf '%s\n' 'Include ~/.ssh/other-private-config' > \
    "$payload_include_home/.config/harness/private/ssh_config"
chmod 600 "$payload_include_home/.config/harness/private/ssh_config"
if HOME="$payload_include_home" "$HARNESS" macos-profile --host mac-test-pilot \
    >"$TEMP_DIR/payload-include.out" 2>&1; then
    fail "external SSH include accepted"
fi
grep -F 'SSH configuration contains prohibited external or credential material' \
    "$TEMP_DIR/payload-include.out" >/dev/null || fail "SSH include refusal"

wrong_mode_home=$(make_profile wrong-mode)
chmod 755 "$wrong_mode_home/.config/harness/private"
if HOME="$wrong_mode_home" "$HARNESS" macos-profile --host mac-test-pilot \
    >"$TEMP_DIR/wrong-mode.out" 2>&1; then
    fail "unsafe root mode accepted"
fi
grep -F 'private companion directory has unsafe mode' \
    "$TEMP_DIR/wrong-mode.out" >/dev/null || fail "unsafe root mode refusal"

file_mode_home=$(make_profile file-mode)
chmod 644 "$file_mode_home/.config/harness/private/companion.conf"
if HOME="$file_mode_home" "$HARNESS" macos-profile --host mac-test-pilot \
    >"$TEMP_DIR/file-mode.out" 2>&1; then
    fail "unsafe manifest mode accepted"
fi
grep -F 'private companion manifest has unsafe mode' \
    "$TEMP_DIR/file-mode.out" >/dev/null || fail "unsafe file mode refusal"

root_link_home=$TEMP_DIR/root-link
mkdir -p "$root_link_home/.config/harness" "$root_link_home/real-private"
chmod 700 "$root_link_home" "$root_link_home/.config" \
    "$root_link_home/.config/harness" "$root_link_home/real-private"
ln -s "$root_link_home/real-private" \
    "$root_link_home/.config/harness/private"
if HOME="$root_link_home" "$HARNESS" macos-profile --host mac-test-pilot \
    >"$TEMP_DIR/root-link.out" 2>&1; then
    fail "symlink root accepted"
fi
grep -F 'private companion directory has unsafe type' \
    "$TEMP_DIR/root-link.out" >/dev/null || fail "symlink root refusal"

host_link_home=$(make_profile host-link)
mv "$host_link_home/.config/harness/private/hosts/mac-test-pilot.conf" \
    "$host_link_home/.config/harness/private/hosts/real.conf"
ln -s real.conf \
    "$host_link_home/.config/harness/private/hosts/mac-test-pilot.conf"
if HOME="$host_link_home" "$HARNESS" macos-profile --host mac-test-pilot \
    >"$TEMP_DIR/host-link.out" 2>&1; then
    fail "symlink host manifest accepted"
fi
grep -F 'private companion manifest has unsafe type' \
    "$TEMP_DIR/host-link.out" >/dev/null || fail "symlink host refusal"

duplicate_home=$(make_profile duplicate)
printf '%s\n' 'schema=1' >> \
    "$duplicate_home/.config/harness/private/companion.conf"
if HOME="$duplicate_home" "$HARNESS" macos-profile --host mac-test-pilot \
    >"$TEMP_DIR/duplicate.out" 2>&1; then
    fail "duplicate key accepted"
fi
grep -F 'private companion manifest is malformed' \
    "$TEMP_DIR/duplicate.out" >/dev/null || fail "duplicate key refusal"

unknown_home=$(make_profile unknown)
private_sentinel=PRIVATE_SENTINEL_VALUE
printf '%s\n' "secret=$private_sentinel" >> \
    "$unknown_home/.config/harness/private/hosts/mac-test-pilot.conf"
if HOME="$unknown_home" "$HARNESS" macos-profile --host mac-test-pilot \
    >"$TEMP_DIR/unknown.out" 2>&1; then
    fail "unknown private key accepted"
fi
grep -F 'private companion manifest is malformed' \
    "$TEMP_DIR/unknown.out" >/dev/null || fail "unknown key refusal"
if grep -F "$private_sentinel" "$TEMP_DIR/unknown.out" >/dev/null ||
    grep -F "$unknown_home" "$TEMP_DIR/unknown.out" >/dev/null; then
    fail "unknown-key refusal exposed private content"
fi

layout_home=$(make_profile layout)
layout_sentinel=PRIVATE_COPIED_CONFIGURATION
printf '%s\n' "$layout_sentinel" > \
    "$layout_home/.config/harness/private/copied-config.txt"
git -C "$layout_home/.config/harness/private" add copied-config.txt
git -C "$layout_home/.config/harness/private" commit -q -m \
    'synthetic prohibited layout'
if HOME="$layout_home" "$HARNESS" macos-profile --host mac-test-pilot \
    >"$TEMP_DIR/layout.out" 2>&1; then
    fail "unapproved tracked private content accepted"
fi
grep -F 'private companion tracked layout is invalid' \
    "$TEMP_DIR/layout.out" >/dev/null || fail "tracked-layout refusal"
if grep -F "$layout_sentinel" "$TEMP_DIR/layout.out" >/dev/null ||
    grep -F "$layout_home" "$TEMP_DIR/layout.out" >/dev/null; then
    fail "tracked-layout refusal exposed private content"
fi

mismatch_home=$(make_profile mismatch)
sed 's/logical_id=mac-test-pilot/logical_id=private-machine-name/' \
    "$mismatch_home/.config/harness/private/hosts/mac-test-pilot.conf" \
    >"$TEMP_DIR/mismatch.new"
mv "$TEMP_DIR/mismatch.new" \
    "$mismatch_home/.config/harness/private/hosts/mac-test-pilot.conf"
chmod 600 "$mismatch_home/.config/harness/private/hosts/mac-test-pilot.conf"
if HOME="$mismatch_home" "$HARNESS" macos-profile --host mac-test-pilot \
    >"$TEMP_DIR/mismatch.out" 2>&1; then
    fail "mismatched logical identifier accepted"
fi
grep -F 'private logical identifier mismatch' \
    "$TEMP_DIR/mismatch.out" >/dev/null || fail "identifier mismatch refusal"
if grep -F 'private-machine-name' "$TEMP_DIR/mismatch.out" >/dev/null; then
    fail "identifier mismatch exposed private value"
fi

schema_home=$(make_profile schema)
sed 's/schema=1/schema=2/' \
    "$schema_home/.config/harness/private/companion.conf" \
    >"$TEMP_DIR/schema.new"
mv "$TEMP_DIR/schema.new" \
    "$schema_home/.config/harness/private/companion.conf"
chmod 600 "$schema_home/.config/harness/private/companion.conf"
if HOME="$schema_home" "$HARNESS" macos-profile --host mac-test-pilot \
    >"$TEMP_DIR/schema.out" 2>&1; then
    fail "incompatible schema accepted"
fi
grep -F 'private companion schema is incompatible' \
    "$TEMP_DIR/schema.out" >/dev/null || fail "schema refusal"

token_home=$(make_profile token)
private_path_sentinel=/private/owner/path
sed "s|extra_formulae=sqlite,ninja|extra_formulae=$private_path_sentinel|" \
    "$token_home/.config/harness/private/hosts/mac-test-pilot.conf" \
    >"$TEMP_DIR/token.new"
mv "$TEMP_DIR/token.new" \
    "$token_home/.config/harness/private/hosts/mac-test-pilot.conf"
chmod 600 "$token_home/.config/harness/private/hosts/mac-test-pilot.conf"
if HOME="$token_home" "$HARNESS" macos-profile --host mac-test-pilot \
    >"$TEMP_DIR/token.out" 2>&1; then
    fail "absolute private formula token accepted"
fi
grep -F 'private companion token list is malformed' \
    "$TEMP_DIR/token.out" >/dev/null || fail "private token refusal"
if grep -F "$private_path_sentinel" "$TEMP_DIR/token.out" >/dev/null; then
    fail "token refusal exposed private path"
fi

owner_home=$(make_profile owner)
fake_bin=$TEMP_DIR/fake-bin
mkdir -p "$fake_bin"
cat >"$fake_bin/stat" <<'EOF'
#!/bin/sh
case "$1:$2" in
    -c:%u) echo 999999 ;;
    *) exec /usr/bin/stat "$@" ;;
esac
EOF
chmod 755 "$fake_bin/stat"
if HOME="$owner_home" PATH="$fake_bin:/usr/bin:/bin" \
    "$HARNESS" macos-profile --host mac-test-pilot \
    >"$TEMP_DIR/owner.out" 2>&1; then
    fail "wrong owner accepted"
fi
grep -F 'private companion directory has unsafe owner' \
    "$TEMP_DIR/owner.out" >/dev/null || fail "wrong owner refusal"

if HOME="$valid_home" "$HARNESS" macos-profile --host '../private' \
    >"$TEMP_DIR/unsafe-id.out" 2>&1; then
    fail "unsafe logical identifier accepted"
fi
grep -F 'invalid private logical identifier' \
    "$TEMP_DIR/unsafe-id.out" >/dev/null || fail "unsafe identifier refusal"

echo "personal macOS private-profile tests passed"
