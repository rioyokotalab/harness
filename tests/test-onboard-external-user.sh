#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/harness-external-onboard-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    "$CLEANUP" "$HARNESS" "$TEMP_BASE" "$TEMP_DIR" "$TEMP_BASE" >/dev/null || status=1
    exit "$status"
}
trap cleanup EXIT HUP INT TERM
fail() { echo "FAIL: $*" >&2; exit 1; }

repo=$TEMP_DIR/repo
home=$TEMP_DIR/home
mkdir -p "$repo/.codex/rules" "$repo/.claude" "$repo/bin" \
    "$repo/shared/skills/example" "$home"
printf '%s\n' guidance >"$repo/.codex/AGENTS.md"
printf '%s\n' rules >"$repo/.codex/rules/default.rules"
printf '%s\n' guidance >"$repo/.claude/CLAUDE.md"
printf '%s\n' '#!/bin/sh' >"$repo/bin/harness"
printf '%s\n' '#!/bin/sh' >"$repo/install.sh"
printf '%s\n' '---' 'name: example' 'description: Example.' '---' \
    >"$repo/shared/skills/example/SKILL.md"
chmod 755 "$repo/install.sh" "$repo/bin/harness"
git -C "$repo" init -q -b main
git -C "$repo" config user.name external-test
git -C "$repo" config user.email external-test.invalid
git -C "$repo" add .
git -C "$repo" commit -qm baseline

PREFLIGHT=$ROOT/shared/skills/onboard-external-user/scripts/preflight
SKILL=$ROOT/shared/skills/onboard-external-user/SKILL.md
OPENAI=$ROOT/shared/skills/onboard-external-user/agents/openai.yaml
sh -n "$PREFLIGHT" || fail 'preflight syntax'
HOME="$home" CODEX_HOME="$home/.codex" CLAUDE_HOME="$home/.claude" \
    "$PREFLIGHT" --repo "$repo" >"$TEMP_DIR/absent.out"
grep -F 'status=ready' "$TEMP_DIR/absent.out" >/dev/null || fail 'fresh status'
grep -F 'links_total=7 links_current=0 links_absent=7 collisions=0' \
    "$TEMP_DIR/absent.out" >/dev/null || fail 'fresh link classification'

mkdir -p "$home/.codex"
printf '%s\n' collision >"$home/.codex/AGENTS.md"
if HOME="$home" CODEX_HOME="$home/.codex" CLAUDE_HOME="$home/.claude" \
    "$PREFLIGHT" --repo "$repo" >"$TEMP_DIR/collision.out" 2>&1; then
    fail 'collision accepted'
fi
grep -F 'status=blocked' "$TEMP_DIR/collision.out" >/dev/null || fail 'blocked status'
grep -F 'collisions=1' "$TEMP_DIR/collision.out" >/dev/null || fail 'collision count'

printf '%s\n' dirty >"$repo/dirty"
if HOME="$TEMP_DIR/other-home" "$PREFLIGHT" --repo "$repo" \
    >"$TEMP_DIR/dirty.out" 2>&1; then
    fail 'dirty checkout accepted'
fi
grep -F 'repo=dirty' "$TEMP_DIR/dirty.out" >/dev/null || fail 'dirty classification'

grep -F -x 'name: onboard-external-user' "$SKILL" >/dev/null || fail 'skill name'
grep -F 'local-first' "$SKILL" >/dev/null || fail 'local-first boundary'
grep -F 'onboard-mirrored-node' "$SKILL" >/dev/null || fail 'remote handoff'
grep -F '$onboard-external-user' "$OPENAI" >/dev/null || fail 'default prompt'
if rg -n '\[TODO:' "$SKILL" "$OPENAI" >/dev/null; then fail 'template placeholder'; fi
echo 'external user onboarding skill tests: PASS'
