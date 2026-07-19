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
    "$ROOT/libexec/harness-macos-common" "$PUBLIC/libexec/"
cp "$ROOT/config/agent-clients/codex.toml" \
    "$ROOT/config/agent-clients/claude.json" \
    "$ROOT/config/agent-clients/components.tsv" \
    "$PUBLIC/config/agent-clients/"
chmod 755 "$PUBLIC/bin/harness" "$PUBLIC/bin/harness-codex" \
    "$PUBLIC/libexec/harness-agent-config" \
    "$PUBLIC/libexec/harness-agent-config-catch-up"
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
    mkdir "$home"
    chmod 700 "$home"
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
HOME="$catch_home" HARNESS_ROOT="$PUBLIC" \
    "$PUBLIC/libexec/harness-agent-config-catch-up" --apply --drill \
    >"$TEMP_DIR/catch-up.out"
grep -F 'checkout=fast-forward' "$TEMP_DIR/catch-up.out" >/dev/null ||
    fail "direct catch-up fast-forward"
grep -F 'status=ready activation=new-sessions' "$TEMP_DIR/catch-up.out" >/dev/null ||
    fail "direct catch-up readiness"
[ "$(git -C "$PUBLIC" rev-parse HEAD)" = "$(git -C "$PUBLIC" rev-parse origin/main)" ] ||
    fail "direct catch-up target"

home=$(make_home absent)
run_config "$home" --plan >"$TEMP_DIR/absent.plan"
[ "$(grep -c 'state=absent action=link' "$TEMP_DIR/absent.plan")" -eq 3 ] ||
    fail "absent plan"
run_config "$home" --apply >"$TEMP_DIR/absent.apply"
tx=$(transaction "$TEMP_DIR/absent.apply")
[ -n "$tx" ] || fail "missing transaction"
[ -L "$home/.codex/config.toml" ] &&
    [ "$(readlink "$home/.codex/config.toml")" = "$PUBLIC/config/agent-clients/codex.toml" ] ||
    fail "Codex canonical link"
[ -L "$home/.claude/settings.json" ] &&
    [ "$(readlink "$home/.claude/settings.json")" = "$PUBLIC/config/agent-clients/claude.json" ] ||
    fail "Claude canonical link"
[ -L "$home/.local/bin/codex" ] &&
    [ "$(readlink "$home/.local/bin/codex")" = "$PUBLIC/bin/harness-codex" ] ||
    fail "Codex launcher link"
run_config "$home" --doctor >"$TEMP_DIR/doctor.out"
grep -F 'status=ready failures=0' "$TEMP_DIR/doctor.out" >/dev/null ||
    fail "ready doctor"
run_config "$home" --apply >"$TEMP_DIR/noop.out"
grep -F 'action=none activation=unchanged' "$TEMP_DIR/noop.out" >/dev/null ||
    fail "second apply no-op"

FAKE_BIN=$TEMP_DIR/fake-bin
PROJECT=$TEMP_DIR/project
mkdir "$FAKE_BIN" "$PROJECT"
git -C "$PROJECT" init -q
cat >"$FAKE_BIN/codex" <<'EOF'
#!/bin/sh
printf '%s\n' "$@"
EOF
chmod 755 "$FAKE_BIN/codex"
launcher_output=$(cd "$PROJECT" && HOME="$home" \
    PATH="$home/.local/bin:$FAKE_BIN:/usr/bin:/bin" codex exec --help)
project_root=$(CDPATH='' cd -- "$PROJECT" && pwd -P)
printf '%s\n' "$launcher_output" | sed -n '1p' | grep -F -x -- '-c' >/dev/null ||
    fail "launcher config flag"
printf '%s\n' "$launcher_output" | sed -n '2p' |
    grep -F -x "projects.\"$project_root\".trust_level=\"trusted\"" >/dev/null ||
    fail "launcher transient trust"
printf '%s\n' "$launcher_output" | sed -n '3p' | grep -F -x exec >/dev/null ||
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
ln -s "$PUBLIC/config/agent-clients/codex.toml" "$home/.codex/config.toml"
unlink "$home/.codex/config.toml.changed"
run_config "$home" --rollback "$tx" >"$TEMP_DIR/rollback.out"
[ ! -e "$home/.codex" ] && [ ! -L "$home/.codex" ] || fail "Codex absent rollback"
[ ! -e "$home/.claude" ] && [ ! -L "$home/.claude" ] || fail "Claude absent rollback"
[ ! -e "$home/.local/bin" ] && [ ! -L "$home/.local/bin" ] || fail "launcher absent rollback"

adopt_home=$(make_home adopt)
mkdir -p "$adopt_home/.codex" "$adopt_home/.claude" "$adopt_home/.local/bin"
printf '%s\n' '# owner Codex' >"$adopt_home/.codex/config.toml"
printf '%s\n' '{"owner":true}' >"$adopt_home/.claude/settings.json"
ln -s /opt/owner/codex "$adopt_home/.local/bin/codex"
chmod 640 "$adopt_home/.codex/config.toml" "$adopt_home/.claude/settings.json"
if run_config "$adopt_home" --plan >"$TEMP_DIR/adopt-refuse.out" 2>&1; then
    fail "adoption accepted without authority"
fi
run_config "$adopt_home" --adopt --apply >"$TEMP_DIR/adopt.apply"
adopt_tx=$(transaction "$TEMP_DIR/adopt.apply")
run_config "$adopt_home" --rollback "$adopt_tx" >"$TEMP_DIR/adopt.rollback"
grep -F -x '# owner Codex' "$adopt_home/.codex/config.toml" >/dev/null ||
    fail "Codex regular preimage"
grep -F -x '{"owner":true}' "$adopt_home/.claude/settings.json" >/dev/null ||
    fail "Claude regular preimage"
[ "$(stat -c %a "$adopt_home/.codex/config.toml")" = 640 ] ||
    fail "Codex preimage mode"
[ -L "$adopt_home/.local/bin/codex" ] &&
    [ "$(readlink "$adopt_home/.local/bin/codex")" = /opt/owner/codex ] ||
    fail "launcher symlink preimage"

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
[ ! -e "$unsafe_home/.local" ] || fail "blocked apply mutated state"

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
printf '%s\n' launcher-owner >"$failure_home/.local/bin/codex"
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
grep -F -x launcher-owner "$failure_home/.local/bin/codex" >/dev/null ||
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
