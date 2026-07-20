#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/harness-agent-upgrade-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    if [ -d "$TEMP_DIR" ]; then
        "$CLEANUP" "$HARNESS" "${TMPDIR:-/tmp}" "$TEMP_DIR" \
            "${TMPDIR:-/tmp}" >/dev/null || status=1
    fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
fail() { echo "FAIL: $*" >&2; exit 1; }

REPO=$TEMP_DIR/repo
HOME_DIR=$TEMP_DIR/home
FAKE_BIN=$TEMP_DIR/bin
mkdir -p "$REPO/libexec" "$REPO/profiles/hosts" "$REPO/tools" \
    "$REPO/shared/skills" "$HOME_DIR" "$FAKE_BIN"
cp "$ROOT/libexec/harness-agent" "$ROOT/libexec/harness-rollback" \
    "$ROOT/libexec/harness-common" "$REPO/libexec/"
cp "$ROOT/profiles/hosts/local.conf" "$REPO/profiles/hosts/"
cp -R "$ROOT/shared/skills/guarded-bulk-delete" "$REPO/shared/skills/"
cat >"$REPO/libexec/harness-doctor" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod 755 "$REPO/libexec/"*
git -C "$REPO" init -q -b main
git -C "$REPO" config user.name agent-upgrade-test
git -C "$REPO" config user.email agent-upgrade-test.invalid

cat >"$FAKE_BIN/node" <<'EOF'
#!/bin/sh
printf '%s\n' v24.16.0
EOF
cat >"$FAKE_BIN/curl" <<'EOF'
#!/bin/sh
url=
out=
while [ "$#" -gt 0 ]; do
    case "$1" in
        https://*) url=$1; shift ;;
        -o) out=$2; shift 2 ;;
        *) shift ;;
    esac
done
case "$url" in
    *linux-x64*) cp "$FIXTURE_AGENT_NATIVE" "$out" ;;
    *) cp "$FIXTURE_AGENT_LAUNCHER" "$out" ;;
esac
EOF
chmod 755 "$FAKE_BIN/node" "$FAKE_BIN/curl"

write_version() {
    version=$1
    fixture=$TEMP_DIR/fixture-$version
    launcher_root=$fixture/launcher/package
    native_root=$fixture/native/package
    launcher_archive=$fixture/launcher.tar.gz
    native_archive=$fixture/native.tar.gz
    mkdir -p "$launcher_root/bin" \
        "$native_root/vendor/x86_64-unknown-linux-musl/bin"
    printf '%s\n' '#!/bin/sh' "echo 'codex-cli $version'" \
        >"$launcher_root/bin/codex.js"
    chmod 755 "$launcher_root/bin/codex.js"
    printf '{"name":"@openai/codex","version":"%s"}\n' "$version" \
        >"$launcher_root/package.json"
    printf '%s\n' "$version-native" \
        >"$native_root/vendor/x86_64-unknown-linux-musl/bin/codex"
    printf '{"name":"@openai/codex-linux-x64","version":"%s-linux-x64"}\n' \
        "$version" >"$native_root/package.json"
    tar -czf "$launcher_archive" -C "$fixture/launcher" package
    tar -czf "$native_archive" -C "$fixture/native" package
    launcher_hash=$(sha256sum "$launcher_archive" | awk '{print $1}')
    native_hash=$(sha256sum "$native_archive" | awk '{print $1}')
    printf '%s\n' \
        '# name|version|os|arch|node-version|launcher-url|launcher-sha256|native-directory|native-url|native-sha256|command-relative|version-line' \
        "codex|$version|linux|x86_64|24.16.0|https://fixtures.invalid/codex-$version.tgz|$launcher_hash|@openai/codex-linux-x64|https://fixtures.invalid/codex-$version-linux-x64.tgz|$native_hash|node_modules/@openai/codex/bin/codex.js|codex-cli $version" \
        >"$REPO/tools/agents.tsv"
    git -C "$REPO" add .
    git -C "$REPO" commit -q --allow-empty -m "declare $version"
    FIXTURE_AGENT_LAUNCHER=$launcher_archive
    FIXTURE_AGENT_NATIVE=$native_archive
    export FIXTURE_AGENT_LAUNCHER FIXTURE_AGENT_NATIVE
}

run_agent() {
    HOME="$HOME_DIR" HARNESS_ROOT="$REPO" \
        PATH="$FAKE_BIN:/usr/bin:/bin" \
        "$REPO/libexec/harness-agent" --host local --name codex "$@"
}
run_rollback() {
    HOME="$HOME_DIR" HARNESS_ROOT="$REPO" PATH="/usr/bin:/bin" \
        "$REPO/libexec/harness-rollback" "$1"
}
transaction() { sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' "$1"; }
old_tree=$HOME_DIR/.local/opt/agents/codex/1.2.3/linux-x86_64
new_tree=$HOME_DIR/.local/opt/agents/codex/1.2.4/linux-x86_64
stable=$HOME_DIR/.local/bin/codex

write_version 1.2.3
run_agent --apply >"$TEMP_DIR/install.out"
[ -L "$stable" ] && [ "$(readlink "$stable")" = \
    "$old_tree/node_modules/@openai/codex/bin/codex.js" ] ||
    fail "initial managed install"

write_version 1.2.4
cp "$REPO/tools/agents.tsv" "$TEMP_DIR/agents-valid.tsv"
awk -F'|' 'BEGIN { OFS="|" } /^#/ { print; next } { $7=sprintf("%064d", 0); print }' \
    "$REPO/tools/agents.tsv" >"$REPO/tools/agents.tsv.invalid"
mv "$REPO/tools/agents.tsv.invalid" "$REPO/tools/agents.tsv"
git -C "$REPO" add tools/agents.tsv
git -C "$REPO" commit -q -m 'inject replacement checksum failure'
if run_agent --apply >"$TEMP_DIR/checksum-failure.out" 2>&1; then
    fail "replacement accepted invalid checksum"
fi
[ -L "$stable" ] && [ "$(readlink "$stable")" = \
    "$old_tree/node_modules/@openai/codex/bin/codex.js" ] &&
    [ ! -e "$new_tree" ] &&
    [ ! -e "${new_tree%/*}" ] || fail "prepared-state recovery"
cp "$TEMP_DIR/agents-valid.tsv" "$REPO/tools/agents.tsv"
git -C "$REPO" add tools/agents.tsv
git -C "$REPO" commit -q -m 'restore valid replacement checksum'
run_agent --plan >"$TEMP_DIR/replace.plan"
grep -F 'REPLACE agent=codex from=1.2.3 to=1.2.4' \
    "$TEMP_DIR/replace.plan" >/dev/null || fail "forward replacement plan"
run_agent --apply >"$TEMP_DIR/replace.apply"
replace_tx=$(transaction "$TEMP_DIR/replace.apply")
[ -n "$replace_tx" ] || fail "replacement transaction"
[ -L "$stable" ] && [ "$(readlink "$stable")" = \
    "$new_tree/node_modules/@openai/codex/bin/codex.js" ] ||
    fail "replacement link"
[ -d "$old_tree" ] && [ -d "$new_tree" ] || fail "retained predecessor"
run_agent --plan | grep -F 'KEEP agent=codex source=managed-agent' >/dev/null ||
    fail "replacement idempotence"

run_rollback "$replace_tx" >"$TEMP_DIR/replace.rollback"
[ -L "$stable" ] && [ "$(readlink "$stable")" = \
    "$old_tree/node_modules/@openai/codex/bin/codex.js" ] ||
    fail "replacement rollback link"
[ -d "$old_tree" ] && [ ! -e "$new_tree" ] ||
    fail "replacement rollback trees"

if HARNESS_TEST_AGENT_INTERRUPT=after-promote run_agent --apply \
    >"$TEMP_DIR/promote-interrupt.out" 2>&1; then
    fail "after-promote interruption returned success"
fi
run_agent --plan >"$TEMP_DIR/promote-recovery.plan"
grep -F 'AGENT_RECOVERY status=promoted action=restore-prior' \
    "$TEMP_DIR/promote-recovery.plan" >/dev/null || fail "promote recovery plan"
run_agent --apply >"$TEMP_DIR/promote-recovery.apply"
grep -F 'AGENT_RECOVERY action=restored-prior' \
    "$TEMP_DIR/promote-recovery.apply" >/dev/null || fail "promote recovery apply"
[ -L "$stable" ] && [ "$(readlink "$stable")" = \
    "$old_tree/node_modules/@openai/codex/bin/codex.js" ] &&
    [ ! -e "$new_tree" ] || fail "promote recovery state"

if HARNESS_TEST_AGENT_INTERRUPT=after-switch run_agent --apply \
    >"$TEMP_DIR/switch-interrupt.out" 2>&1; then
    fail "after-switch interruption returned success"
fi
run_agent --plan >"$TEMP_DIR/switch-recovery.plan"
grep -F 'AGENT_RECOVERY status=activated action=restore-prior' \
    "$TEMP_DIR/switch-recovery.plan" >/dev/null || fail "switch recovery plan"
run_agent --apply >"$TEMP_DIR/switch-recovery.apply"
[ -L "$stable" ] && [ "$(readlink "$stable")" = \
    "$old_tree/node_modules/@openai/codex/bin/codex.js" ] &&
    [ ! -e "$new_tree" ] || fail "switch recovery state"

run_agent --apply >"$TEMP_DIR/final-replace.apply"
final_tx=$(transaction "$TEMP_DIR/final-replace.apply")
cp -p "$new_tree/node_modules/@openai/codex/bin/codex.js" \
    "$TEMP_DIR/new-command.before"
printf '%s\n' changed >>"$new_tree/node_modules/@openai/codex/bin/codex.js"
if run_rollback "$final_tx" >"$TEMP_DIR/changed-new.out" 2>&1; then
    fail "rollback accepted changed new tree"
fi
cp -p "$TEMP_DIR/new-command.before" \
    "$new_tree/node_modules/@openai/codex/bin/codex.js"
cp -p "$old_tree/node_modules/@openai/codex/bin/codex.js" \
    "$TEMP_DIR/old-command.before"
printf '%s\n' changed >>"$old_tree/node_modules/@openai/codex/bin/codex.js"
if run_rollback "$final_tx" >"$TEMP_DIR/changed-old.out" 2>&1; then
    fail "rollback accepted changed predecessor"
fi
cp -p "$TEMP_DIR/old-command.before" \
    "$old_tree/node_modules/@openai/codex/bin/codex.js"
unlink "$stable"
ln -s /unexpected/codex "$stable"
if run_rollback "$final_tx" >"$TEMP_DIR/changed-link.out" 2>&1; then
    fail "rollback accepted changed stable link"
fi
unlink "$stable"
ln -s "$new_tree/node_modules/@openai/codex/bin/codex.js" "$stable"
run_rollback "$final_tx" >"$TEMP_DIR/final.rollback"

write_version 1.2.2
if run_agent --plan >"$TEMP_DIR/downgrade.out" 2>&1; then
    fail "ordinary downgrade was accepted"
fi
grep -F 'reason=managed-version-not-forward' "$TEMP_DIR/downgrade.out" >/dev/null ||
    fail "downgrade refusal reason"

unlink "$stable"
ln -s /unmanaged/codex "$stable"
if run_agent --plan >"$TEMP_DIR/unmanaged.out" 2>&1; then
    fail "unmanaged stable link was accepted"
fi
grep -F 'reason=partial-unmanaged-or-invalid-state' \
    "$TEMP_DIR/unmanaged.out" >/dev/null || fail "unmanaged refusal reason"

echo 'agent upgrade tests: PASS'
