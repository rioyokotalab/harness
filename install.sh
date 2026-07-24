#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
CODEX_HOME=${CODEX_HOME:-"$HOME/.codex"}
CLAUDE_HOME=${CLAUDE_HOME:-"$HOME/.claude"}
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

preflight_path() {
    source_path=$1
    destination=$2
    legacy_source=${3:-}

    if [ -L "$destination" ]; then
        current=$(readlink "$destination")
        [ "$current" = "$source_path" ] && return
        [ -n "$legacy_source" ] && [ "$current" = "$legacy_source" ] && return
        echo "refusing to replace different symlink: $destination -> $current" >&2
        exit 1
    fi
    if [ -e "$destination" ]; then
        echo "refusing to replace existing path: $destination" >&2
        exit 1
    fi
}

managed_links() {
    printf '%s|%s|%s\n' "$ROOT/.codex/AGENTS.md" "$CODEX_HOME/AGENTS.md" \
        "$ROOT/codex/AGENTS.md"
    printf '%s|%s|%s\n' "$ROOT/config/agent-clients/claude-sentinel.md" \
        "$CLAUDE_HOME/CLAUDE.md" "$ROOT/.claude/CLAUDE.md"
    printf '%s|%s|\n' "$ROOT/bin/harness" "$USER_BIN/harness"
}

links=$(managed_links)

# Refuse every known collision before creating or migrating any link. This
# keeps a late Claude or skill collision from leaving a partial installation.
printf '%s\n' "$links" | while IFS='|' read -r source destination legacy; do
    preflight_path "$source" "$destination" "$legacy"
done

printf '%s\n' "$links" | while IFS='|' read -r source destination legacy; do
    link_path "$source" "$destination" "$legacy"
done

echo "Harness command and out-of-project Codex/Claude sentinels installed. Start clients from this checkout."
