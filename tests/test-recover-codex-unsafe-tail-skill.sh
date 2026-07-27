#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
SKILL=$ROOT/shared/skills/recover-codex-unsafe-tail/SKILL.md
PROTOCOL=$ROOT/shared/skills/recover-codex-unsafe-tail/references/protocol.md
OPENAI=$ROOT/shared/skills/recover-codex-unsafe-tail/agents/openai.yaml

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

for path in "$SKILL" "$PROTOCOL" "$OPENAI"; do
    [ -f "$path" ] && [ ! -L "$path" ] ||
        fail "missing skill resource: $path"
done

grep -F -x 'name: recover-codex-unsafe-tail' "$SKILL" >/dev/null ||
    fail "skill name"
grep -F 'Request blocked' "$SKILL" >/dev/null ||
    fail "blocked-thread trigger"
grep -F 'Never retry an ambiguous' "$SKILL" >/dev/null ||
    fail "ambiguous acknowledgement boundary"
grep -F 'fresh-root cutover' "$SKILL" >/dev/null ||
    fail "unsafe-tail route"
grep -F 'Never read pane text' "$SKILL" >/dev/null ||
    fail "content boundary"
grep -F 'Treat an unreaped zombie as already exited but not absent' \
    "$SKILL" >/dev/null || fail "zombie boundary"
grep -F 'Rollback acknowledged but `systemError` remains' "$PROTOCOL" \
    >/dev/null || fail "post-rollback decision"
grep -F 'Send one `SIGTERM` only to that leaf' "$PROTOCOL" >/dev/null ||
    fail "single-signal boundary"
grep -F 'default_prompt: "Use $recover-codex-unsafe-tail' "$OPENAI" \
    >/dev/null || fail "OpenAI interface"

for client in .agents .claude; do
    link=$ROOT/$client/skills/recover-codex-unsafe-tail
    [ -L "$link" ] || fail "$client discovery link"
    [ "$(readlink "$link")" = \
        ../../shared/skills/recover-codex-unsafe-tail ] ||
        fail "$client discovery target"
done

if grep -E '/home/|rioyokota|T-[0-9]+|SW-[0-9]+' \
    "$SKILL" "$PROTOCOL" "$OPENAI" >/dev/null; then
    fail "owner- or incident-specific content"
fi
if grep -E 'rm[[:space:]]+-r|rm[[:space:]]+-rf|find .* -delete' \
    "$SKILL" "$PROTOCOL" >/dev/null; then
    fail "raw recursive deletion guidance"
fi

printf 'recover_codex_unsafe_tail_skill=pass\n'
