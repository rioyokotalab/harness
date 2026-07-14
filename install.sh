#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CODEX_HOME=${CODEX_HOME:-"$HOME/.codex"}
CLAUDE_HOME=${CLAUDE_HOME:-"$HOME/.claude"}
USER_SKILLS="$HOME/.agents/skills"
USER_BIN="$HOME/.local/bin"

link_path() {
    source_path=$1
    destination=$2
    legacy_source=${3:-}
    parent=${destination%/*}
    mkdir -p "$parent"

    if [ -L "$destination" ]; then
        current=$(readlink "$destination")
        if [ "$current" = "$source_path" ]; then
            return
        fi
        if [ -n "$legacy_source" ] && [ "$current" = "$legacy_source" ]; then
            rm "$destination"
            ln -s "$source_path" "$destination"
            return
        fi
        echo "refusing to replace different symlink: $destination -> $current" >&2
        exit 1
    fi
    if [ -e "$destination" ]; then
        echo "refusing to replace existing path: $destination" >&2
        exit 1
    fi
    ln -s "$source_path" "$destination"
}

link_path "$ROOT/.codex/AGENTS.md" "$CODEX_HOME/AGENTS.md" \
    "$ROOT/codex/AGENTS.md"
link_path "$ROOT/.codex/rules/default.rules" "$CODEX_HOME/rules/default.rules" \
    "$ROOT/codex/rules/default.rules"
link_path "$ROOT/.claude/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md" \
    "$ROOT/claude/CLAUDE.md"
link_path "$ROOT/bin/harness" "$USER_BIN/harness"

for skill_path in "$ROOT"/shared/skills/*
do
    [ -d "$skill_path" ] || continue
    if [ ! -f "$skill_path/SKILL.md" ]; then
        echo "refusing skill directory without SKILL.md: $skill_path" >&2
        exit 1
    fi
    name=${skill_path##*/}
    link_path "$skill_path" "$CODEX_HOME/skills/$name"
    link_path "$skill_path" "$USER_SKILLS/$name"
    link_path "$skill_path" "$CLAUDE_HOME/skills/$name"
done

echo "Harness command and Codex/Claude discovery links installed. Start new sessions."
