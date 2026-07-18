#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/harness-claude-test.XXXXXX")

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEMP_DIR" ]; then
        "$CLEANUP" "$HARNESS" "${TMPDIR:-/tmp}" "$TEMP_DIR" \
            "${TMPDIR:-/tmp}" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then
        echo "FAIL: guarded Claude takeover test cleanup" >&2
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

assert_link() {
    source=$1
    destination=$2
    [ -L "$destination" ] || fail "missing link: $destination"
    [ "$(readlink "$destination")" = "$source" ] ||
        fail "wrong link target: $destination"
}

# Claude Code officially supports project instructions in CLAUDE.md and
# .claude/CLAUDE.md. The root import gives it the same project handoff rules as
# AGENTS-aware clients, while the .claude link remains the shared global policy.
[ -f "$ROOT/AGENTS.md" ] && [ ! -L "$ROOT/AGENTS.md" ] ||
    fail "missing project AGENTS.md"
[ -f "$ROOT/CLAUDE.md" ] && [ ! -L "$ROOT/CLAUDE.md" ] ||
    fail "missing project CLAUDE.md"
grep -Fx '@AGENTS.md' "$ROOT/CLAUDE.md" >/dev/null ||
    fail "Claude project instructions do not import AGENTS.md"
[ -L "$ROOT/.claude/CLAUDE.md" ] || fail "Claude global guidance is not a link"
[ "$(readlink "$ROOT/.claude/CLAUDE.md")" = '../.codex/AGENTS.md' ] ||
    fail "Claude global guidance target"
cmp -s "$ROOT/.claude/CLAUDE.md" "$ROOT/.codex/AGENTS.md" ||
    fail "Codex and Claude global guidance differ"
grep -F 'Git and `TODO.md` as the durable source of truth' "$ROOT/AGENTS.md" \
    >/dev/null || fail "project takeover source of truth"
grep -F 'Claude auto-memory are optional context only' "$ROOT/.codex/AGENTS.md" \
    >/dev/null || fail "global cross-client handoff policy"
[ "$(wc -l <"$ROOT/.codex/AGENTS.md" | tr -d ' ')" -le 200 ] ||
    fail "shared global guidance exceeds the reviewed Claude size bound"

python3 - "$ROOT/.claude/settings.example.json" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
assert data.get("$schema") == "https://json.schemastore.org/claude-code-settings.json"
PY

# Exercise the standalone installer in an isolated home. Every shared skill
# must be visible from the Codex, Agent Skills, and Claude personal locations,
# and a second run must be idempotent.
test_home=$TEMP_DIR/home
codex_home=$test_home/codex-config
claude_home=$test_home/claude-config
mkdir -p "$test_home"
HOME="$test_home" CODEX_HOME="$codex_home" CLAUDE_HOME="$claude_home" \
    "$ROOT/install.sh" >"$TEMP_DIR/install-first.out"
assert_link "$ROOT/.codex/AGENTS.md" "$codex_home/AGENTS.md"
assert_link "$ROOT/.codex/rules/default.rules" "$codex_home/rules/default.rules"
assert_link "$ROOT/.claude/CLAUDE.md" "$claude_home/CLAUDE.md"
assert_link "$ROOT/bin/harness" "$test_home/.local/bin/harness"
cmp -s "$claude_home/CLAUDE.md" "$ROOT/.codex/AGENTS.md" ||
    fail "installed Claude guidance differs from canonical policy"

for skill_path in "$ROOT"/shared/skills/*; do
    [ -f "$skill_path/SKILL.md" ] || fail "shared skill lacks SKILL.md: $skill_path"
    name=${skill_path##*/}
    assert_link "$skill_path" "$codex_home/skills/$name"
    assert_link "$skill_path" "$test_home/.agents/skills/$name"
    assert_link "$skill_path" "$claude_home/skills/$name"
done

HOME="$test_home" CODEX_HOME="$codex_home" CLAUDE_HOME="$claude_home" \
    "$ROOT/install.sh" >"$TEMP_DIR/install-second.out"

# A collision discovered late in the declaration order must block the entire
# install before any Codex, command, or skill link is created.
conflict_home=$TEMP_DIR/conflict-home
conflict_codex=$conflict_home/codex-config
conflict_claude=$conflict_home/claude-config
mkdir -p "$conflict_claude"
printf '%s\n' owner-content >"$conflict_claude/CLAUDE.md"
if HOME="$conflict_home" CODEX_HOME="$conflict_codex" \
    CLAUDE_HOME="$conflict_claude" "$ROOT/install.sh" \
    >"$TEMP_DIR/install-conflict.out" 2>&1; then
    fail "installer accepted a Claude guidance collision"
fi
grep -Fx owner-content "$conflict_claude/CLAUDE.md" >/dev/null ||
    fail "installer changed the colliding Claude file"
[ ! -e "$conflict_codex/AGENTS.md" ] && [ ! -L "$conflict_codex/AGENTS.md" ] ||
    fail "collision left a partial Codex install"
[ ! -e "$conflict_home/.local/bin/harness" ] &&
    [ ! -L "$conflict_home/.local/bin/harness" ] ||
    fail "collision left a partial harness command"
[ ! -e "$conflict_home/.agents/skills" ] ||
    fail "collision left partial Agent Skills discovery"

echo "Claude takeover tests passed"
