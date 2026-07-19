#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/harness-agent-config-test.XXXXXX")
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

PUBLIC=$TEMP_DIR/public
mkdir -p "$PUBLIC/bin" "$PUBLIC/libexec" "$PUBLIC/config/agent-clients"
cp "$ROOT/bin/harness" "$ROOT/bin/harness-codex" "$PUBLIC/bin/"
cp "$ROOT/libexec/harness-agent-config" "$ROOT/libexec/harness-common" \
    "$ROOT/libexec/harness-agent-config-catch-up" \
    "$ROOT/libexec/harness-macos-common" \
    "$ROOT/libexec/harness-macos-update" "$PUBLIC/libexec/"
cp "$ROOT/config/agent-clients/codex.toml" \
    "$ROOT/config/agent-clients/claude.json" \
    "$ROOT/config/agent-clients/components.tsv" \
    "$PUBLIC/config/agent-clients/"
chmod 755 "$PUBLIC/bin/harness" "$PUBLIC/bin/harness-codex" \
    "$PUBLIC/libexec/harness-agent-config" \
    "$PUBLIC/libexec/harness-agent-config-catch-up"
cat >"$PUBLIC/libexec/harness-macos-update" <<'EOF'
#!/bin/sh
printf 'DELEGATED_MACOS_UPDATE'
for argument do printf ' %s' "$argument"; done
printf '\n'
EOF
chmod 755 "$PUBLIC/libexec/harness-macos-update"
git -C "$PUBLIC" init -q -b main
git -C "$PUBLIC" config user.name agent-config-test
git -C "$PUBLIC" config user.email agent-config-test.invalid
git -C "$PUBLIC" add .
git -C "$PUBLIC" commit -q -m baseline
ORIGIN=$TEMP_DIR/origin.git
PUBLISHER=$TEMP_DIR/publisher
git init -q --bare "$ORIGIN"
git -C "$PUBLIC" remote add origin "$ORIGIN"
git -C "$PUBLIC" push -q -u origin main
git -C "$ORIGIN" symbolic-ref HEAD refs/heads/main
git clone -q "$ORIGIN" "$PUBLISHER"
git -C "$PUBLISHER" config user.name agent-config-test
git -C "$PUBLISHER" config user.email agent-config-test.invalid
printf '%s\n' current >"$PUBLISHER/catch-up-marker"
git -C "$PUBLISHER" add catch-up-marker
git -C "$PUBLISHER" commit -q -m 'synthetic current release'
git -C "$PUBLISHER" push -q origin main

make_home() {
    home=$TEMP_DIR/$1
    mkdir -p "$home/.local/bin"
    chmod 700 "$home"
    cat >"$home/.local/bin/codex" <<'EOF'
#!/bin/sh
printf '%s\n' "$@"
EOF
    chmod 755 "$home/.local/bin/codex"
    printf '%s\n' "$home"
}
run_config() {
    test_home=$1
    shift
    HOME="$test_home" HARNESS_ROOT="$PUBLIC" HARNESS_TEST_ALLOW_NONMAIN=1 \
        "$PUBLIC/libexec/harness-agent-config" "$@"
}
transaction() { sed -n 's/.*transaction=\([^ ]*\).*/\1/p' "$1"; }

catch_home=$(make_home catch-up)
LINUX_FAKE_BIN=$TEMP_DIR/linux-fake-bin
mkdir "$LINUX_FAKE_BIN"
cat >"$LINUX_FAKE_BIN/uname" <<'EOF'
#!/bin/sh
if [ ! -e "$UNAME_FIRST_CALL" ]; then
    : >"$UNAME_FIRST_CALL"
    printf '%s\n' Linux
else
    /usr/bin/uname "$@"
fi
EOF
chmod 755 "$LINUX_FAKE_BIN/uname"
HOME="$catch_home" HARNESS_ROOT="$PUBLIC" \
    UNAME_FIRST_CALL="$TEMP_DIR/uname-first-call" \
    PATH="$LINUX_FAKE_BIN:/usr/bin:/bin" \
    "$PUBLIC/libexec/harness-agent-config-catch-up" --apply --drill \
    >"$TEMP_DIR/catch-up.out"
grep -F 'checkout=fast-forward' "$TEMP_DIR/catch-up.out" >/dev/null ||
    fail "direct catch-up fast-forward"
grep -F 'status=ready activation=new-sessions' "$TEMP_DIR/catch-up.out" >/dev/null ||
    fail "direct catch-up readiness"
[ "$(git -C "$PUBLIC" rev-parse HEAD)" = "$(git -C "$PUBLIC" rev-parse origin/main)" ] ||
    fail "direct catch-up target"

# The Mac route must compose with macos-update and must not independently
# advance the public checkout. A stub isolates the routing contract here;
# test-personal-macos-update.sh exercises the delegated compatibility and
# migration engine itself.
printf '%s\n' coordinated >"$PUBLISHER/coordinated-catch-up-marker"
git -C "$PUBLISHER" add coordinated-catch-up-marker
git -C "$PUBLISHER" commit -q -m 'synthetic coordinated release'
git -C "$PUBLISHER" push -q origin main
git -C "$PUBLIC" fetch -q origin main
MAC_PRIVATE_SOURCE=$TEMP_DIR/mac-private-source
MAC_PRIVATE_ORIGIN=$TEMP_DIR/mac-private-origin.git
mac_home=$(make_home mac-catch-up)
mkdir -p "$MAC_PRIVATE_SOURCE" "$mac_home/.config/harness"
git -C "$MAC_PRIVATE_SOURCE" init -q -b main
git -C "$MAC_PRIVATE_SOURCE" config user.name agent-config-test
git -C "$MAC_PRIVATE_SOURCE" config user.email agent-config-test.invalid
printf '%s\n' 'schema=synthetic' >"$MAC_PRIVATE_SOURCE/companion.conf"
git -C "$MAC_PRIVATE_SOURCE" add companion.conf
git -C "$MAC_PRIVATE_SOURCE" commit -q -m baseline
git init -q --bare -b main "$MAC_PRIVATE_ORIGIN"
git -C "$MAC_PRIVATE_SOURCE" remote add origin "$MAC_PRIVATE_ORIGIN"
git -C "$MAC_PRIVATE_SOURCE" push -q -u origin main
git clone -q "$MAC_PRIVATE_ORIGIN" "$mac_home/.config/harness/private"
MAC_FAKE_BIN=$TEMP_DIR/mac-fake-bin
mkdir "$MAC_FAKE_BIN"
cat >"$MAC_FAKE_BIN/uname" <<'EOF'
#!/bin/sh
printf '%s\n' Darwin
EOF
chmod 755 "$MAC_FAKE_BIN/uname"
mac_public_before=$(git -C "$PUBLIC" rev-parse HEAD)
HOME="$mac_home" HARNESS_ROOT="$PUBLIC" \
    PATH="$MAC_FAKE_BIN:/usr/bin:/bin" \
    "$PUBLIC/libexec/harness-agent-config-catch-up" \
    --host mac-test-pilot --adopt --plan >"$TEMP_DIR/mac-catch-up.out"
grep -F 'MAC_AGENT_CONFIG_ROUTE public=fast-forward private=none compatibility=required migration=required' \
    "$TEMP_DIR/mac-catch-up.out" >/dev/null || fail "coordinated Mac route"
grep -F 'DELEGATED_MACOS_UPDATE --host mac-test-pilot --public-target ' \
    "$TEMP_DIR/mac-catch-up.out" >/dev/null || fail "macos-update delegation"
grep -F 'post_update_plan=required apply=not-requested' \
    "$TEMP_DIR/mac-catch-up.out" >/dev/null || fail "Mac post-update plan boundary"
[ "$(git -C "$PUBLIC" rev-parse HEAD)" = "$mac_public_before" ] ||
    fail "Mac plan independently advanced public checkout"
if [ "${HARNESS_AGENT_CONFIG_ROUTE_ONLY:-0}" = 1 ]; then
    echo 'agent configuration catch-up routing tests: PASS'
    exit 0
fi

home=$(make_home absent)
missing_native_home=$(make_home missing-native)
unlink "$missing_native_home/.local/bin/codex"
if run_config "$missing_native_home" --plan >"$TEMP_DIR/missing-native.out" 2>&1; then
    fail "missing native Codex accepted"
fi
grep -F 'AGENT_CONFIG_NATIVE_CODEX state=absent action=relocate-required' \
    "$TEMP_DIR/missing-native.out" >/dev/null || fail "missing native Codex state"
recursive_native_home=$(make_home recursive-native)
unlink "$recursive_native_home/.local/bin/codex"
ln -s "$PUBLIC/bin/harness-codex" \
    "$recursive_native_home/.local/bin/codex"
if run_config "$recursive_native_home" --plan >"$TEMP_DIR/recursive-native.out" 2>&1; then
    fail "recursive native Codex accepted"
fi
grep -F 'AGENT_CONFIG_NATIVE_CODEX state=recursive action=relocate-required' \
    "$TEMP_DIR/recursive-native.out" >/dev/null || fail "recursive native Codex state"
run_config "$home" --plan >"$TEMP_DIR/absent.plan"
[ "$(grep -c 'state=absent action=link' "$TEMP_DIR/absent.plan")" -eq 3 ] ||
    fail "absent plan"
run_config "$home" --apply >"$TEMP_DIR/absent.apply"
tx=$(transaction "$TEMP_DIR/absent.apply")
[ -n "$tx" ] || fail "missing transaction"
[ -f "$home/.codex/config.toml" ] && [ ! -L "$home/.codex/config.toml" ] &&
    cmp -s "$home/.codex/config.toml" "$PUBLIC/config/agent-clients/codex.toml" ||
    fail "Codex managed regular file"
[ -L "$home/.claude/settings.json" ] &&
    [ "$(readlink "$home/.claude/settings.json")" = "$PUBLIC/config/agent-clients/claude.json" ] ||
    fail "Claude canonical link"
[ -L "$home/.local/bin/harness-codex" ] &&
    [ "$(readlink "$home/.local/bin/harness-codex")" = "$PUBLIC/bin/harness-codex" ] ||
    fail "Codex launcher link"
run_config "$home" --doctor >"$TEMP_DIR/doctor.out"
grep -F 'status=ready failures=0' "$TEMP_DIR/doctor.out" >/dev/null ||
    fail "ready doctor"
printf '%s\n' '' '[projects."/synthetic/private-project"]' \
    'trust_level = "trusted"' >>"$home/.codex/config.toml"
private_config=$TEMP_DIR/private-config
printf '%s\n' 'model = "opaque-private-model"' \
    'model_reasoning_effort = "opaque-private-effort"' >"$private_config"
cat "$home/.codex/config.toml" >>"$private_config"
mv "$private_config" "$home/.codex/config.toml"
chmod 600 "$home/.codex/config.toml"
project_number=1
while [ "$project_number" -lt 93 ]; do
    printf '\n[projects."/synthetic/private-project-%s"]\ntrust_level = "trusted"\n' \
        "$project_number" >>"$home/.codex/config.toml"
    project_number=$((project_number + 1))
done
run_config "$home" --doctor >"$TEMP_DIR/trust-suffix.doctor"
grep -F 'status=ready failures=0' "$TEMP_DIR/trust-suffix.doctor" >/dev/null ||
    fail "private preferences and 93-table trust suffix doctor"
printf '%s\n' 'model = "duplicate-private-model"' >>"$home/.codex/config.toml"
if run_config "$home" --doctor >"$TEMP_DIR/invalid-suffix.doctor" 2>&1; then
    fail "invalid private suffix accepted"
fi
cp "$PUBLIC/config/agent-clients/codex.toml" "$home/.codex/config.toml"
chmod 600 "$home/.codex/config.toml"
run_config "$home" --apply >"$TEMP_DIR/noop.out"
grep -F 'action=none activation=unchanged' "$TEMP_DIR/noop.out" >/dev/null ||
    fail "second apply no-op"

# A single drifted path must be adoptable without rejecting or relinking the
# two paths that are already current. Rollback restores only that preimage.
unlink "$home/.local/bin/harness-codex"
ln -s /opt/owner/codex "$home/.local/bin/harness-codex"
run_config "$home" --adopt --apply >"$TEMP_DIR/partial.apply"
partial_tx=$(transaction "$TEMP_DIR/partial.apply")
[ -n "$partial_tx" ] || fail "partial adoption transaction"
run_config "$home" --doctor >"$TEMP_DIR/partial.doctor"
grep -F 'status=ready failures=0' "$TEMP_DIR/partial.doctor" >/dev/null ||
    fail "partial adoption doctor"
run_config "$home" --rollback "$partial_tx" >"$TEMP_DIR/partial.rollback"
[ -L "$home/.local/bin/harness-codex" ] &&
    [ "$(readlink "$home/.local/bin/harness-codex")" = /opt/owner/codex ] ||
    fail "partial adoption rollback"
run_config "$home" --adopt --apply >"$TEMP_DIR/partial.reapply"
run_config "$home" --doctor >"$TEMP_DIR/partial.reapply.doctor"
grep -F 'status=ready failures=0' "$TEMP_DIR/partial.reapply.doctor" >/dev/null ||
    fail "partial adoption reapply doctor"

printf '%s\n' 'model = "rollback-private-model"' \
    'model_reasoning_effort = "rollback-private-effort"' \
    'approval_policy = "never"' \
    'sandbox_mode = "danger-full-access"' '' \
    '[projects."/synthetic/rollback-private-project"]' \
    'trust_level = "trusted"' >"$home/.codex/config.toml"
chmod 600 "$home/.codex/config.toml"
cp "$home/.codex/config.toml" "$TEMP_DIR/current-codex-before"
unlink "$home/.local/bin/harness-codex"
ln -s /opt/owner/codex "$home/.local/bin/harness-codex"
run_config "$home" --adopt --apply --drill >"$TEMP_DIR/current-codex-drill.out"
cmp -s "$home/.codex/config.toml" "$TEMP_DIR/current-codex-before" ||
    fail "current private Codex changed by rollback drill"
run_config "$home" --doctor >"$TEMP_DIR/current-codex-drill.doctor"
grep -F 'status=ready failures=0' "$TEMP_DIR/current-codex-drill.doctor" >/dev/null ||
    fail "current private Codex drill doctor"

PROJECT=$TEMP_DIR/project
mkdir "$PROJECT"
git -C "$PROJECT" init -q
launcher_output=$(cd "$PROJECT" && HOME="$home" \
    PATH="$home/.local/bin:/usr/bin:/bin" harness-codex exec --help)
printf '%s\n' "$launcher_output" | sed -n '1p' |
    grep -F -x -- '--ask-for-approval' >/dev/null || fail "launcher approval flag"
printf '%s\n' "$launcher_output" | sed -n '2p' | grep -F -x never >/dev/null ||
    fail "launcher approval value"
printf '%s\n' "$launcher_output" | sed -n '3p' |
    grep -F -x -- '--sandbox' >/dev/null || fail "launcher sandbox flag"
printf '%s\n' "$launcher_output" | sed -n '4p' |
    grep -F -x danger-full-access >/dev/null || fail "launcher sandbox value"
printf '%s\n' "$launcher_output" | sed -n '5p' | grep -F -x exec >/dev/null ||
    fail "launcher arguments"

printf '%s\n' changed >"$home/.codex/config.toml.changed"
unlink "$home/.codex/config.toml"
ln -s "$home/.codex/config.toml.changed" "$home/.codex/config.toml"
if run_config "$home" --rollback "$tx" >"$TEMP_DIR/changed.out" 2>&1; then
    fail "changed link rollback accepted"
fi
grep -F 'rollback blocked by changed live path' "$TEMP_DIR/changed.out" >/dev/null ||
    fail "changed link refusal"
unlink "$home/.codex/config.toml"
cp "$PUBLIC/config/agent-clients/codex.toml" "$home/.codex/config.toml"
chmod 600 "$home/.codex/config.toml"
unlink "$home/.codex/config.toml.changed"
run_config "$home" --rollback "$tx" >"$TEMP_DIR/rollback.out"
[ ! -e "$home/.codex" ] && [ ! -L "$home/.codex" ] || fail "Codex absent rollback"
[ ! -e "$home/.claude" ] && [ ! -L "$home/.claude" ] || fail "Claude absent rollback"
[ ! -e "$home/.local/bin/harness-codex" ] || fail "launcher absent rollback"

adopt_home=$(make_home adopt)
mkdir -p "$adopt_home/.codex" "$adopt_home/.claude" "$adopt_home/.local/bin"
ln -s /opt/owner/codex-config "$adopt_home/.codex/config.toml"
printf '%s\n' '{"owner":true}' >"$adopt_home/.claude/settings.json"
ln -s /opt/owner/codex "$adopt_home/.local/bin/harness-codex"
chmod 640 "$adopt_home/.claude/settings.json"
if run_config "$adopt_home" --plan >"$TEMP_DIR/adopt-refuse.out" 2>&1; then
    fail "adoption accepted without authority"
fi
run_config "$adopt_home" --adopt --apply >"$TEMP_DIR/adopt.apply"
adopt_tx=$(transaction "$TEMP_DIR/adopt.apply")
run_config "$adopt_home" --rollback "$adopt_tx" >"$TEMP_DIR/adopt.rollback"
[ -L "$adopt_home/.codex/config.toml" ] &&
    [ "$(readlink "$adopt_home/.codex/config.toml")" = /opt/owner/codex-config ] ||
    fail "Codex symlink preimage"
grep -F -x '{"owner":true}' "$adopt_home/.claude/settings.json" >/dev/null ||
    fail "Claude regular preimage"
[ -L "$adopt_home/.local/bin/harness-codex" ] &&
    [ "$(readlink "$adopt_home/.local/bin/harness-codex")" = /opt/owner/codex ] ||
    fail "launcher symlink preimage"

layout_home=$TEMP_DIR/layout-home
layout_root=$TEMP_DIR/layout-persistent
mkdir -p "$layout_home" "$layout_root/local-state/bin"
chmod 700 "$layout_home"
cat >"$layout_root/local-state/bin/codex" <<'EOF'
#!/bin/sh
printf '%s\n' "$@"
EOF
chmod 755 "$layout_root/local-state/bin/codex"
ln -s "$layout_root/local-state" "$layout_home/.local"
layout_file=$TEMP_DIR/home-layout.tsv
printf '%s\n' '# host|persistent-root|cache-root|move-large|move-fast|delete-after-backup|owner-action' \
    "local-test|$layout_root|$layout_root/cache|.local|none|none|none" >"$layout_file"
HOME="$layout_home" HARNESS_ROOT="$PUBLIC" HARNESS_TEST_ALLOW_NONMAIN=1 \
    HARNESS_LOGICAL_HOST=local-test HARNESS_HOME_LAYOUT_FILE="$layout_file" \
    "$PUBLIC/libexec/harness-agent-config" --apply >"$TEMP_DIR/layout.apply"
layout_transaction=$(transaction "$TEMP_DIR/layout.apply")
[ -n "$layout_transaction" ] || fail "declared local symlink transaction"
HOME="$layout_home" HARNESS_ROOT="$PUBLIC" HARNESS_TEST_ALLOW_NONMAIN=1 \
    HARNESS_LOGICAL_HOST=local-test HARNESS_HOME_LAYOUT_FILE="$layout_file" \
    "$PUBLIC/libexec/harness-agent-config" --doctor >"$TEMP_DIR/layout.doctor"
grep -F 'status=ready failures=0' "$TEMP_DIR/layout.doctor" >/dev/null ||
    fail "declared local symlink doctor"
HOME="$layout_home" HARNESS_ROOT="$PUBLIC" HARNESS_TEST_ALLOW_NONMAIN=1 \
    HARNESS_LOGICAL_HOST=local-test HARNESS_HOME_LAYOUT_FILE="$layout_file" \
    "$PUBLIC/libexec/harness-agent-config" --rollback "$layout_transaction" \
    >"$TEMP_DIR/layout.rollback"
[ ! -e "$layout_home/.codex" ] && [ ! -L "$layout_home/.codex" ] ||
    fail "declared local symlink Codex rollback"
[ ! -e "$layout_home/.claude" ] && [ ! -L "$layout_home/.claude" ] ||
    fail "declared local symlink Claude rollback"
[ ! -e "$layout_home/.local/bin/harness-codex" ] ||
    fail "declared local symlink launcher rollback"
if HOME="$layout_home" HARNESS_ROOT="$PUBLIC" HARNESS_TEST_ALLOW_NONMAIN=1 \
    HARNESS_LOGICAL_HOST=undeclared HARNESS_HOME_LAYOUT_FILE="$layout_file" \
    "$PUBLIC/libexec/harness-agent-config" --plan >"$TEMP_DIR/layout-undeclared.out" 2>&1; then
    fail "undeclared local symlink accepted"
fi
grep -F 'agent configuration parent is unsafe' "$TEMP_DIR/layout-undeclared.out" >/dev/null ||
    fail "undeclared local symlink refusal"
escape_root=$TEMP_DIR/layout-escape
mkdir -p "$escape_root/bin"
cat >"$escape_root/bin/codex" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod 755 "$escape_root/bin/codex"
unlink "$layout_home/.local"
ln -s "$escape_root" "$layout_home/.local"
if HOME="$layout_home" HARNESS_ROOT="$PUBLIC" HARNESS_TEST_ALLOW_NONMAIN=1 \
    HARNESS_LOGICAL_HOST=local-test HARNESS_HOME_LAYOUT_FILE="$layout_file" \
    "$PUBLIC/libexec/harness-agent-config" --plan >"$TEMP_DIR/layout-escape.out" 2>&1; then
    fail "escaping local symlink accepted"
fi
grep -F 'agent configuration parent is unsafe' "$TEMP_DIR/layout-escape.out" >/dev/null ||
    fail "escaping local symlink refusal"

drill_home=$(make_home drill)
run_config "$drill_home" --apply --drill >"$TEMP_DIR/drill.out"
grep -F 'AGENT_CONFIG_DRILL rollback=' "$TEMP_DIR/drill.out" >/dev/null ||
    fail "automated rollback/reapply drill"
[ "$(grep -c '^AGENT_CONFIG action=applied transaction=' "$TEMP_DIR/drill.out")" -eq 2 ] ||
    fail "drill apply count"
run_config "$drill_home" --doctor >"$TEMP_DIR/drill.doctor"
grep -F 'status=ready failures=0' "$TEMP_DIR/drill.doctor" >/dev/null ||
    fail "drill final agreement"

unsafe_home=$(make_home unsafe)
mkdir -p "$unsafe_home/.codex/config.toml"
if run_config "$unsafe_home" --apply >"$TEMP_DIR/unsafe.out" 2>&1; then
    fail "unsafe destination accepted"
fi
grep -F 'state=unsafe action=blocked' "$TEMP_DIR/unsafe.out" >/dev/null ||
    fail "unsafe destination refusal"
[ ! -e "$unsafe_home/.local/bin/harness-codex" ] &&
    [ ! -e "$unsafe_home/.local/state" ] ||
    fail "blocked apply mutated state"

hardlink_home=$(make_home hardlink)
mkdir -p "$hardlink_home/.codex"
printf '%s\n' owner >"$hardlink_home/.codex/config.toml"
ln "$hardlink_home/.codex/config.toml" "$hardlink_home/.codex/config.second"
if run_config "$hardlink_home" --adopt --apply >"$TEMP_DIR/hardlink.out" 2>&1; then
    fail "hard-linked destination accepted"
fi
grep -F 'state=unsafe action=blocked' "$TEMP_DIR/hardlink.out" >/dev/null ||
    fail "hard-link refusal"

FAIL_BIN=$TEMP_DIR/fail-bin
failure_home=$(make_home injected-failure)
mkdir -p "$FAIL_BIN" "$failure_home/.codex" "$failure_home/.claude" \
    "$failure_home/.local/bin"
printf '%s\n' codex-owner >"$failure_home/.codex/config.toml"
printf '%s\n' claude-owner >"$failure_home/.claude/settings.json"
printf '%s\n' launcher-owner >"$failure_home/.local/bin/harness-codex"
cat >"$FAIL_BIN/ln" <<'EOF'
#!/bin/sh
last=
for argument do last=$argument; done
if [ -n "${AGENT_CONFIG_FAIL_DEST:-}" ] && [ "$last" = "$AGENT_CONFIG_FAIL_DEST" ]; then
    echo injected-link-failure >&2
    exit 73
fi
exec /bin/ln "$@"
EOF
chmod 755 "$FAIL_BIN/ln"
if HOME="$failure_home" HARNESS_ROOT="$PUBLIC" HARNESS_TEST_ALLOW_NONMAIN=1 \
    AGENT_CONFIG_FAIL_DEST="$failure_home/.claude/settings.json" \
    PATH="$FAIL_BIN:/usr/bin:/bin" \
    "$PUBLIC/libexec/harness-agent-config" --adopt --apply \
    >"$TEMP_DIR/injected.out" 2>&1; then
    fail "injected link failure accepted"
fi
grep -F -x codex-owner "$failure_home/.codex/config.toml" >/dev/null ||
    fail "partial failure did not restore Codex"
grep -F -x claude-owner "$failure_home/.claude/settings.json" >/dev/null ||
    fail "partial failure did not restore Claude"
grep -F -x launcher-owner "$failure_home/.local/bin/harness-codex" >/dev/null ||
    fail "partial failure did not preserve launcher"

invalid=$TEMP_DIR/invalid-public
cp -R "$PUBLIC" "$invalid"
git -C "$invalid" remote remove origin
printf '%s\n' 'unknown_key = true' >>"$invalid/config/agent-clients/codex.toml"
git -C "$invalid" add config/agent-clients/codex.toml
git -C "$invalid" commit -q -m invalid
invalid_home=$(make_home invalid-source)
if HOME="$invalid_home" HARNESS_ROOT="$invalid" HARNESS_TEST_ALLOW_NONMAIN=1 \
    "$invalid/libexec/harness-agent-config" --plan \
    >"$TEMP_DIR/invalid-source.out" 2>&1; then
    fail "unknown canonical Codex key accepted"
fi
grep -F 'canonical Codex configuration is invalid' \
    "$TEMP_DIR/invalid-source.out" >/dev/null || fail "unknown-key refusal"

echo 'agent configuration tests: PASS'
