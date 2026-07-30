#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/harness-agent-config-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    "$CLEANUP" "$HARNESS" "$TEMP_BASE" "$TEMP_DIR" "$TEMP_BASE" >/dev/null ||
        status=1
    exit "$status"
}
trap cleanup EXIT HUP INT TERM
fail() { echo "FAIL: $*" >&2; exit 1; }
file_mode() {
    case $(uname -s) in
        Darwin) stat -f %Lp "$1" ;;
        *) stat -c %a "$1" ;;
    esac
}

repo=$TEMP_DIR/repo
home=$TEMP_DIR/home
mkdir -p "$repo/bin" "$repo/libexec" "$repo/.codex/rules" \
    "$repo/.claude/skills" "$repo/.agents/skills" \
    "$repo/config/agent-clients" "$repo/profiles" \
    "$repo/shared/skills/example" \
    "$home/.codex/rules" "$home/.codex/skills/.system" \
    "$home/.agents/skills" "$home/.claude/skills" "$home/.local/bin"
cp "$ROOT/bin/harness" "$ROOT/bin/harness-codex" "$repo/bin/"
cp "$ROOT/libexec/harness-agent-config" "$ROOT/libexec/harness-common" \
    "$ROOT/libexec/harness-macos-common" \
    "$ROOT/libexec/harness_codex_targets.py" "$repo/libexec/"
cp "$ROOT/profiles/codex-session-targets.tsv" "$repo/profiles/"
cp "$ROOT/config/agent-clients/codex.toml" \
    "$ROOT/config/agent-clients/claude.json" \
    "$ROOT/config/agent-clients/claude-sentinel.md" \
    "$repo/config/agent-clients/"
cp "$ROOT/.codex/AGENTS.md" "$repo/.codex/AGENTS.md"
cp "$ROOT/.codex/config.toml" "$repo/.codex/config.toml"
cp "$ROOT/.codex/rules/default.rules" "$repo/.codex/rules/default.rules"
cp "$ROOT/.claude/settings.json" "$repo/.claude/settings.json"
cp "$ROOT/AGENTS.md" "$ROOT/CLAUDE.md" "$repo/"
printf '%s\n' '---' 'name: example' 'description: Example.' '---' \
    >"$repo/shared/skills/example/SKILL.md"
ln -s ../../shared/skills/example "$repo/.agents/skills/example"
ln -s ../../shared/skills/example "$repo/.claude/skills/example"
chmod 755 "$repo/bin/harness" "$repo/bin/harness-codex" \
    "$repo/libexec/harness-agent-config" \
    "$repo/libexec/harness_codex_targets.py"
git -C "$repo" init -q -b main
git -C "$repo" config user.name agent-config-test
git -C "$repo" config user.email agent-config-test.invalid
git -C "$repo" add .
git -C "$repo" commit -qm baseline

printf '%s\n' 'opaque product-owned bytes; Harness must not parse this' \
    >"$home/.codex/config.toml"
chmod 600 "$home/.codex/config.toml"
cp "$home/.codex/config.toml" "$TEMP_DIR/product-config.before"
ln -s "$repo/.codex/AGENTS.md" "$home/.codex/AGENTS.md"
ln -s "$repo/.codex/rules/default.rules" "$home/.codex/rules/default.rules"
ln -s "$repo/shared/skills/example" "$home/.codex/skills/example"
ln -s "$repo/shared/skills/example" "$home/.agents/skills/example"
ln -s "$repo/shared/skills/example" "$home/.claude/skills/example"
ln -s "$repo/.claude/CLAUDE.md" "$home/.claude/CLAUDE.md"
ln -s "$repo/config/agent-clients/claude.json" "$home/.claude/settings.json"
printf '%s\n' vendor >"$home/.codex/skills/.system/marker"
printf '%s\n' auth-state >"$home/.codex/auth.json"
printf '%s\n' mixed-state >"$home/.claude.json"

run_config() {
    HOME="$home" HARNESS_ROOT="$repo" HARNESS_TEST_ALLOW_NONMAIN=1 \
        "$repo/libexec/harness-agent-config" "$@"
}
transaction() { sed -n 's/.*transaction=\([^ ]*\).*/\1/p' "$1" | sed -n '1p'; }

cp "$repo/.codex/config.toml" "$TEMP_DIR/codex-policy.valid"
sed 's/mcp_elicitations = true/mcp_elicitations = false/' \
    "$repo/.codex/config.toml" >"$repo/.codex/config.toml.invalid"
mv "$repo/.codex/config.toml.invalid" "$repo/.codex/config.toml"
cp "$repo/.codex/config.toml" "$repo/config/agent-clients/codex.toml"
git -C "$repo" add .codex/config.toml config/agent-clients/codex.toml
git -C "$repo" commit -qm 'disable project MCP approvals'
if run_config --plan >"$TEMP_DIR/mcp-disabled.out" 2>&1; then
    fail 'disabled project MCP approvals accepted'
fi
grep -F 'project Codex policy is invalid' "$TEMP_DIR/mcp-disabled.out" >/dev/null ||
    fail 'disabled project MCP approval rejection'
cp "$TEMP_DIR/codex-policy.valid" "$repo/.codex/config.toml"
cp "$TEMP_DIR/codex-policy.valid" "$repo/config/agent-clients/codex.toml"
git -C "$repo" add .codex/config.toml config/agent-clients/codex.toml
git -C "$repo" commit -qm 'restore project MCP approval policy'

sed 's/check_for_update_on_startup = false/check_for_update_on_startup = true/' \
    "$repo/.codex/config.toml" >"$repo/.codex/config.toml.invalid"
mv "$repo/.codex/config.toml.invalid" "$repo/.codex/config.toml"
cp "$repo/.codex/config.toml" "$repo/config/agent-clients/codex.toml"
git -C "$repo" add .codex/config.toml config/agent-clients/codex.toml
git -C "$repo" commit -qm 'inject unsafe update policy'
if run_config --plan >"$TEMP_DIR/update-enabled.out" 2>&1; then
    fail 'enabled native Codex update check accepted'
fi
grep -F 'project Codex policy is invalid' "$TEMP_DIR/update-enabled.out" >/dev/null ||
    fail 'enabled update policy rejection'
cp "$TEMP_DIR/codex-policy.valid" "$repo/.codex/config.toml"
cp "$TEMP_DIR/codex-policy.valid" "$repo/config/agent-clients/codex.toml"
git -C "$repo" add .codex/config.toml config/agent-clients/codex.toml
git -C "$repo" commit -qm 'restore managed update policy'

sed 's/model = "gpt-5.6-sol"/model = "gpt-5.6-terra"/' \
    "$repo/.codex/config.toml" >"$repo/.codex/config.toml.invalid"
mv "$repo/.codex/config.toml.invalid" "$repo/.codex/config.toml"
cp "$repo/.codex/config.toml" "$repo/config/agent-clients/codex.toml"
git -C "$repo" add .codex/config.toml config/agent-clients/codex.toml
git -C "$repo" commit -qm 'inject wrong project model'
if run_config --plan >"$TEMP_DIR/wrong-model.out" 2>&1; then
    fail 'wrong project Codex model accepted'
fi
grep -F 'project Codex policy is invalid' "$TEMP_DIR/wrong-model.out" >/dev/null ||
    fail 'wrong project model rejection'
cp "$TEMP_DIR/codex-policy.valid" "$repo/.codex/config.toml"
cp "$TEMP_DIR/codex-policy.valid" "$repo/config/agent-clients/codex.toml"
git -C "$repo" add .codex/config.toml config/agent-clients/codex.toml
git -C "$repo" commit -qm 'restore project model policy'

cp "$repo/config/agent-clients/claude.json" "$TEMP_DIR/claude-policy.valid"
sed 's/"model": "fable"/"model": "opus"/' "$TEMP_DIR/claude-policy.valid" \
    >"$repo/.claude/settings.json"
cp "$repo/.claude/settings.json" "$repo/config/agent-clients/claude.json"
git -C "$repo" add .claude/settings.json config/agent-clients/claude.json
git -C "$repo" commit -qm 'inject wrong project Claude model'
if run_config --plan >"$TEMP_DIR/claude-wrong-model.out" 2>&1; then
    fail 'wrong project Claude model accepted'
fi
grep -F 'project Claude policy is invalid' "$TEMP_DIR/claude-wrong-model.out" \
    >/dev/null || fail 'wrong project Claude model rejection'

sed '/"effortLevel": "high",/d' "$TEMP_DIR/claude-policy.valid" \
    >"$repo/.claude/settings.json"
cp "$repo/.claude/settings.json" "$repo/config/agent-clients/claude.json"
git -C "$repo" add .claude/settings.json config/agent-clients/claude.json
git -C "$repo" commit -qm 'drop project Claude effort'
if run_config --plan >"$TEMP_DIR/claude-no-effort.out" 2>&1; then
    fail 'missing project Claude effort accepted'
fi
grep -F 'project Claude policy is invalid' "$TEMP_DIR/claude-no-effort.out" \
    >/dev/null || fail 'missing project Claude effort rejection'

sed 's/"model": "fable"/"model": "fable-x"/' "$TEMP_DIR/claude-policy.valid" \
    >"$repo/.claude/settings.json"
cp "$TEMP_DIR/claude-policy.valid" "$repo/config/agent-clients/claude.json"
git -C "$repo" add .claude/settings.json config/agent-clients/claude.json
git -C "$repo" commit -qm 'diverge project Claude mirrors'
if run_config --plan >"$TEMP_DIR/claude-diverged.out" 2>&1; then
    fail 'diverged project Claude mirrors accepted'
fi
grep -F 'project Claude policy differs from its public contract' \
    "$TEMP_DIR/claude-diverged.out" >/dev/null ||
    fail 'diverged project Claude mirror rejection'
cp "$TEMP_DIR/claude-policy.valid" "$repo/.claude/settings.json"
cp "$TEMP_DIR/claude-policy.valid" "$repo/config/agent-clients/claude.json"
git -C "$repo" add .claude/settings.json config/agent-clients/claude.json
git -C "$repo" commit -qm 'restore project Claude policy'

run_config --plan >"$TEMP_DIR/plan.out"
grep -F 'AGENT_CONFIG schema=2 mode=plan' "$TEMP_DIR/plan.out" >/dev/null ||
    fail 'schema-2 plan'
grep -F 'label=codex-config scope=user state=product-owned action=none' \
    "$TEMP_DIR/plan.out" >/dev/null || fail 'Codex product config preservation plan'
grep -F 'label=claude-sentinel scope=user state=legacy action=install' \
    "$TEMP_DIR/plan.out" >/dev/null || fail 'Claude sentinel migration plan'
grep -F 'PROJECT_AGENT_CONFIG codex=ready claude=ready skills=1' \
    "$TEMP_DIR/plan.out" >/dev/null || fail 'project contract'

run_config --apply >"$TEMP_DIR/apply.out"
tx=$(transaction "$TEMP_DIR/apply.out")
[ -n "$tx" ] || fail 'transaction id'
[ ! -e "$home/.local/state/harness/transactions/$tx.agent-config.codex-config.before" ] ||
    fail 'Codex product config entered transaction backup'
[ -L "$home/.codex/AGENTS.md" ] &&
    [ "$(readlink "$home/.codex/AGENTS.md")" = "$repo/.codex/AGENTS.md" ] ||
    fail 'Codex sentinel'
[ -L "$home/.claude/CLAUDE.md" ] &&
    [ "$(readlink "$home/.claude/CLAUDE.md")" = \
        "$repo/config/agent-clients/claude-sentinel.md" ] ||
    fail 'Claude sentinel'
[ -L "$home/.local/bin/harness-codex" ] || fail 'launcher retained'
for removed in "$home/.claude/settings.json" \
    "$home/.codex/rules/default.rules" "$home/.codex/skills/example" \
    "$home/.agents/skills/example" "$home/.claude/skills/example"; do
    [ ! -e "$removed" ] && [ ! -L "$removed" ] || fail "legacy path retained: $removed"
done
cmp "$TEMP_DIR/product-config.before" "$home/.codex/config.toml" >/dev/null ||
    fail 'Codex product config changed during apply'
[ "$(file_mode "$home/.codex/config.toml")" = 600 ] ||
    fail 'Codex product config mode changed during apply'
[ -f "$home/.codex/skills/.system/marker" ] || fail 'vendor skill removed'
grep -F -x auth-state "$home/.codex/auth.json" >/dev/null ||
    fail 'Codex auth changed'
grep -F -x mixed-state "$home/.claude.json" >/dev/null ||
    fail 'Claude mixed state changed'
run_config --doctor >"$TEMP_DIR/doctor.out"
grep -F 'status=ready failures=0' "$TEMP_DIR/doctor.out" >/dev/null ||
    fail 'doctor'

unlink "$home/.codex/config.toml"
run_config --rollback "$tx" >"$TEMP_DIR/rollback.out"
[ ! -e "$home/.codex/config.toml" ] ||
    fail 'Codex product config recreated during rollback'
[ -L "$home/.claude/settings.json" ] || fail 'Claude settings rollback'
[ "$(readlink "$home/.claude/CLAUDE.md")" = "$repo/.claude/CLAUDE.md" ] ||
    fail 'Claude guidance rollback'
[ -L "$home/.codex/skills/example" ] &&
    [ -L "$home/.agents/skills/example" ] &&
    [ -L "$home/.claude/skills/example" ] || fail 'skill rollback'
[ ! -e "$home/.local/bin/harness-codex" ] ||
    fail 'launcher rollback'

cp "$TEMP_DIR/product-config.before" "$home/.codex/config.toml"
chmod 600 "$home/.codex/config.toml"
run_config --apply --drill >"$TEMP_DIR/drill.out"
grep -F 'AGENT_CONFIG_DRILL rollback=' "$TEMP_DIR/drill.out" >/dev/null ||
    fail 'rollback drill'
run_config --doctor >/dev/null
cmp "$TEMP_DIR/product-config.before" "$home/.codex/config.toml" >/dev/null ||
    fail 'Codex product config changed during drill'

chmod 644 "$home/.codex/config.toml"
if run_config --doctor >"$TEMP_DIR/config-mode.out" 2>&1; then
    fail 'broad Codex product config mode accepted'
fi
grep -F 'label=codex-config scope=user state=collision action=blocked' \
    "$TEMP_DIR/config-mode.out" >/dev/null || fail 'Codex config mode refusal'
chmod 600 "$home/.codex/config.toml"

mv "$home/.codex/config.toml" "$home/.codex/config.product"
ln -s config.product "$home/.codex/config.toml"
if run_config --doctor >"$TEMP_DIR/config-symlink.out" 2>&1; then
    fail 'Codex product config symlink accepted'
fi
grep -F 'label=codex-config scope=user state=collision action=blocked' \
    "$TEMP_DIR/config-symlink.out" >/dev/null || fail 'Codex config symlink refusal'
unlink "$home/.codex/config.toml"
mv "$home/.codex/config.product" "$home/.codex/config.toml"

ln "$home/.codex/config.toml" "$home/.codex/config.hardlink"
if run_config --doctor >"$TEMP_DIR/config-hardlink.out" 2>&1; then
    fail 'Codex product config hard link accepted'
fi
grep -F 'label=codex-config scope=user state=collision action=blocked' \
    "$TEMP_DIR/config-hardlink.out" >/dev/null || fail 'Codex config hard-link refusal'
unlink "$home/.codex/config.hardlink"
run_config --doctor >/dev/null

collision_home=$TEMP_DIR/collision-home
mkdir -p "$collision_home/.codex" "$collision_home/.local/bin"
printf '%s\n' owner >"$collision_home/.codex/AGENTS.md"
if HOME="$collision_home" HARNESS_ROOT="$repo" HARNESS_TEST_ALLOW_NONMAIN=1 \
    "$repo/libexec/harness-agent-config" --plan >"$TEMP_DIR/collision.out" 2>&1; then
    fail 'foreign sentinel accepted'
fi
grep -F 'label=codex-sentinel scope=user state=collision action=blocked' \
    "$TEMP_DIR/collision.out" >/dev/null || fail 'collision classification'

linked_home=$TEMP_DIR/linked-home
persistent_root=$TEMP_DIR/persistent
linked_local=$persistent_root/account/local
mkdir -p "$linked_home" "$linked_local"
chmod 700 "$linked_home" "$persistent_root" "$persistent_root/account" \
    "$linked_local"
ln -s "$linked_local" "$linked_home/.local"
layout=$TEMP_DIR/home-layout.tsv
printf '%s\n' \
    "linked|$persistent_root|$persistent_root/cache|.local|none|none|none" \
    >"$layout"
HOME="$linked_home" HARNESS_ROOT="$repo" HARNESS_TEST_ALLOW_NONMAIN=1 \
    HARNESS_LOGICAL_HOST=linked HARNESS_HOME_LAYOUT_FILE="$layout" \
    "$repo/libexec/harness-agent-config" --apply >"$TEMP_DIR/linked.out"
grep -F 'AGENT_CONFIG action=applied' "$TEMP_DIR/linked.out" >/dev/null ||
    fail 'declared .local symlink apply'
HOME="$linked_home" HARNESS_ROOT="$repo" HARNESS_TEST_ALLOW_NONMAIN=1 \
    HARNESS_LOGICAL_HOST=linked HARNESS_HOME_LAYOUT_FILE="$layout" \
    "$repo/libexec/harness-agent-config" --doctor >/dev/null ||
    fail 'declared .local symlink doctor'

echo 'agent configuration tests: PASS'
