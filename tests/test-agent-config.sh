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

repo=$TEMP_DIR/repo
home=$TEMP_DIR/home
mkdir -p "$repo/bin" "$repo/libexec" "$repo/.codex/rules" \
    "$repo/.claude/skills" "$repo/.agents/skills" \
    "$repo/config/agent-clients" "$repo/shared/skills/example" \
    "$home/.codex/rules" "$home/.codex/skills/.system" \
    "$home/.agents/skills" "$home/.claude/skills" "$home/.local/bin"
cp "$ROOT/bin/harness" "$ROOT/bin/harness-codex" "$repo/bin/"
cp "$ROOT/libexec/harness-agent-config" "$ROOT/libexec/harness-common" \
    "$ROOT/libexec/harness-macos-common" "$repo/libexec/"
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
    "$repo/libexec/harness-agent-config"
git -C "$repo" init -q -b main
git -C "$repo" config user.name agent-config-test
git -C "$repo" config user.email agent-config-test.invalid
git -C "$repo" add .
git -C "$repo" commit -qm baseline

printf '%s\n' 'approval_policy = "never"' \
    'sandbox_mode = "danger-full-access"' \
    'model = "synthetic"' >"$home/.codex/config.toml"
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

run_config --plan >"$TEMP_DIR/plan.out"
grep -F 'AGENT_CONFIG schema=2 mode=plan' "$TEMP_DIR/plan.out" >/dev/null ||
    fail 'schema-2 plan'
grep -F 'label=codex-config scope=user state=removable-regular action=remove' \
    "$TEMP_DIR/plan.out" >/dev/null || fail 'Codex config removal plan'
grep -F 'label=claude-sentinel scope=user state=legacy action=install' \
    "$TEMP_DIR/plan.out" >/dev/null || fail 'Claude sentinel migration plan'
grep -F 'PROJECT_AGENT_CONFIG codex=ready claude=ready skills=1' \
    "$TEMP_DIR/plan.out" >/dev/null || fail 'project contract'

run_config --apply >"$TEMP_DIR/apply.out"
tx=$(transaction "$TEMP_DIR/apply.out")
[ -n "$tx" ] || fail 'transaction id'
[ -L "$home/.codex/AGENTS.md" ] &&
    [ "$(readlink "$home/.codex/AGENTS.md")" = "$repo/.codex/AGENTS.md" ] ||
    fail 'Codex sentinel'
[ -L "$home/.claude/CLAUDE.md" ] &&
    [ "$(readlink "$home/.claude/CLAUDE.md")" = \
        "$repo/config/agent-clients/claude-sentinel.md" ] ||
    fail 'Claude sentinel'
[ -L "$home/.local/bin/harness-codex" ] || fail 'launcher retained'
for removed in "$home/.codex/config.toml" "$home/.claude/settings.json" \
    "$home/.codex/rules/default.rules" "$home/.codex/skills/example" \
    "$home/.agents/skills/example" "$home/.claude/skills/example"; do
    [ ! -e "$removed" ] && [ ! -L "$removed" ] || fail "legacy path retained: $removed"
done
[ -f "$home/.codex/skills/.system/marker" ] || fail 'vendor skill removed'
grep -F -x auth-state "$home/.codex/auth.json" >/dev/null ||
    fail 'Codex auth changed'
grep -F -x mixed-state "$home/.claude.json" >/dev/null ||
    fail 'Claude mixed state changed'
run_config --doctor >"$TEMP_DIR/doctor.out"
grep -F 'status=ready failures=0' "$TEMP_DIR/doctor.out" >/dev/null ||
    fail 'doctor'

run_config --rollback "$tx" >"$TEMP_DIR/rollback.out"
[ -f "$home/.codex/config.toml" ] || fail 'Codex config rollback'
[ -L "$home/.claude/settings.json" ] || fail 'Claude settings rollback'
[ "$(readlink "$home/.claude/CLAUDE.md")" = "$repo/.claude/CLAUDE.md" ] ||
    fail 'Claude guidance rollback'
[ -L "$home/.codex/skills/example" ] &&
    [ -L "$home/.agents/skills/example" ] &&
    [ -L "$home/.claude/skills/example" ] || fail 'skill rollback'
[ ! -e "$home/.local/bin/harness-codex" ] ||
    fail 'launcher rollback'

run_config --apply --drill >"$TEMP_DIR/drill.out"
grep -F 'AGENT_CONFIG_DRILL rollback=' "$TEMP_DIR/drill.out" >/dev/null ||
    fail 'rollback drill'
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
