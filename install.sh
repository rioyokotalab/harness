#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CODEX_HOME=${CODEX_HOME:-"$HOME/.codex"}
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

link_path "$ROOT/AGENTS.md" "$CODEX_HOME/AGENTS.md"
link_path "$ROOT/rules/default.rules" "$CODEX_HOME/rules/default.rules"

for skill_path in "$ROOT"/skills/*
do
    [ -d "$skill_path" ] || continue
    if [ ! -f "$skill_path/SKILL.md" ]; then
        echo "refusing skill directory without SKILL.md: $skill_path" >&2
        exit 1
    fi
    name=${skill_path##*/}
    link_path "$skill_path" "$CODEX_HOME/skills/$name"
    link_path "$skill_path" "$USER_SKILLS/$name"
done

echo "Codex harness discovery links installed. Start a new Codex session."
