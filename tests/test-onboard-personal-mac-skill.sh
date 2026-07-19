#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
SKILL=$ROOT/shared/skills/onboard-personal-mac/SKILL.md
STAGES=$ROOT/shared/skills/onboard-personal-mac/references/stages.md
OPENAI=$ROOT/shared/skills/onboard-personal-mac/agents/openai.yaml

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
[ -f "$SKILL" ] && [ ! -L "$SKILL" ] || fail 'skill file identity'
[ -f "$STAGES" ] && [ ! -L "$STAGES" ] || fail 'stage reference identity'
[ -f "$OPENAI" ] && [ ! -L "$OPENAI" ] || fail 'OpenAI metadata identity'

grep -F -x 'name: onboard-personal-mac' "$SKILL" >/dev/null || fail 'skill name'
grep -F 'Codex must run the native commands itself' "$SKILL" >/dev/null ||
    fail 'Codex execution contract'
grep -F 'wait for the owner' "$SKILL" >/dev/null || fail 'go gate'
grep -F 'one material decision at a time' "$SKILL" >/dev/null || fail 'interview gate'
grep -F '`.bash_common` orphan test' "$SKILL" >/dev/null || fail 'orphan cleanup order'
grep -F 'rollback' "$SKILL" >/dev/null || fail 'rollback contract'
grep -F 'macos-pilot-plan --host HOST' "$STAGES" >/dev/null || fail 'aggregate plan'
grep -F 'macos-doctor --host HOST' "$STAGES" >/dev/null || fail 'doctor acceptance'
grep -F 'Every command above is run by Codex' "$STAGES" >/dev/null ||
    fail 'no owner shell execution'
grep -F '$onboard-personal-mac' "$OPENAI" >/dev/null || fail 'default prompt'

if rg -n '\[TODO:' "$SKILL" "$STAGES" "$OPENAI" >/dev/null; then
    fail 'skill retains template placeholder'
fi
printf '%s\n' 'personal Mac onboarding skill tests: PASS'
