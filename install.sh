#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CODEX_HOME=${CODEX_HOME:-"$HOME/.codex"}
CLAUDE_HOME=${CLAUDE_HOME:-"$HOME/.claude"}
USER_SKILLS="$HOME/.agents/skills"

link_path() {
    source_path=$1
    destination=$2
    parent=${destination%/*}
    mkdir -p "$parent"

    if [ -L "$destination" ]; then
        current=$(readlink "$destination")
        if [ "$current" = "$source_path" ]; then
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

link_path "$ROOT/codex/AGENTS.md" "$CODEX_HOME/AGENTS.md"
link_path "$ROOT/codex/rules/default.rules" "$CODEX_HOME/rules/default.rules"
link_path "$ROOT/claude/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md"

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

echo "Codex and Claude harness discovery links installed. Start new sessions."
