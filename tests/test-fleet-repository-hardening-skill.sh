#!/usr/bin/env bash
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SKILL=$ROOT/shared/skills/fleet-repository-hardening/SKILL.md
CHECKLIST=$ROOT/shared/skills/fleet-repository-hardening/references/audit-checklist.md
OPENAI=$ROOT/shared/skills/fleet-repository-hardening/agents/openai.yaml

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

for path in "$SKILL" "$CHECKLIST" "$OPENAI"; do
    [ -f "$path" ] || fail "missing skill resource: $path"
done

grep -F 'name: fleet-repository-hardening' "$SKILL" >/dev/null ||
    fail "skill name"
grep -F 'repository-local LIFO' "$SKILL" >/dev/null ||
    fail "LIFO contract"
grep -F 'git push origin HEAD:refs/heads/TASK_BRANCH' "$SKILL" >/dev/null ||
    fail "explicit push refspec"
grep -F 'Do not use plain `git push`' "$SKILL" >/dev/null ||
    fail "matching-push guard"
grep -F 'Use `python3`' "$SKILL" >/dev/null ||
    fail "portable Python entry point"
grep -F 'unavailable administrator authority' "$SKILL" >/dev/null ||
    fail "administrator handoff"
grep -F 'material-work cutoff' "$SKILL" >/dev/null ||
    fail "deadline cutoff"
grep -F 'failed query is `unknown`' "$CHECKLIST" >/dev/null ||
    fail "unknown-state classification"
grep -F 'Harden fleets and repositories with LIFO recovery' "$OPENAI" >/dev/null ||
    fail "OpenAI interface"

if grep -E '/home/|rioyokota|students|swallow|website|T-311' \
    "$SKILL" "$CHECKLIST" "$OPENAI" >/dev/null; then
    fail "project- or owner-specific content"
fi

printf 'fleet_repository_hardening_skill=pass\n'
