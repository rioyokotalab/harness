#!/usr/bin/env bash
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
SKILL_ROOT=$ROOT/shared/skills/fleet-repository-hardening
SKILL=$SKILL_ROOT/SKILL.md
PLANNING=$SKILL_ROOT/references/planning.md
REPOSITORY=$SKILL_ROOT/references/repository-audit.md
LINUX=$SKILL_ROOT/references/linux-audit.md
MACOS=$SKILL_ROOT/references/macos-audit.md
EXECUTION=$SKILL_ROOT/references/execution.md
ISSUES=$SKILL_ROOT/references/issue-stack.md
CLOSEOUT=$SKILL_ROOT/references/closeout.md
AGGREGATE=$SKILL_ROOT/references/audit-checklist.md
OPENAI=$SKILL_ROOT/agents/openai.yaml
AGENTS=$ROOT/AGENTS.md
EXTERNAL_POLICY=$ROOT/docs/agent-policy/repository-git.md

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_contains() {
    pattern=$1
    file=$2
    label=$3
    grep -F -- "$pattern" "$file" >/dev/null || fail "$label"
}

for path in "$SKILL" "$PLANNING" "$REPOSITORY" "$LINUX" "$MACOS" \
    "$EXECUTION" "$ISSUES" "$CLOSEOUT" "$AGGREGATE" "$OPENAI" \
    "$AGENTS" "$EXTERNAL_POLICY"; do
    [ -f "$path" ] && [ ! -L "$path" ] ||
        fail "missing regular skill resource: $path"
done

assert_contains 'name: fleet-repository-hardening' "$SKILL" 'skill name'
assert_contains 'repository-local LIFO issue stacks' "$SKILL" \
    'frontmatter LIFO contract'
assert_contains 'Do not add an' "$SKILL" 'already-authorized autonomy gate'
assert_contains 'Do not mutate target state until `planning.md`' "$SKILL" \
    'planning authority stop'
assert_contains 'one blocked stack must not acquire another repository' "$SKILL" \
    'parallel repository isolation'
assert_contains 'Do not preload later phases or unrelated host types' "$SKILL" \
    'progressive-disclosure gate'
assert_contains 'stop target mutation and record that unknown state' "$SKILL" \
    'unknown-route stop'

expected_routes=$(printf '%s\n' \
    'closeout.md' \
    'execution.md' \
    'issue-stack.md' \
    'linux-audit.md' \
    'macos-audit.md' \
    'planning.md' \
    'repository-audit.md')
actual_routes=$(grep -Eo '\]\(references/[a-z-]+\.md\)' "$SKILL" |
    sed 's#.*references/##; s#).*##' | sort)
[ "$actual_routes" = "$expected_routes" ] ||
    fail "phase router does not select the exact seven references"
if grep -F '](references/audit-checklist.md)' "$SKILL" >/dev/null; then
    fail 'normal route still selects the aggregate checklist'
fi
for phase in "$PLANNING" "$REPOSITORY" "$LINUX" "$MACOS" "$EXECUTION" \
    "$ISSUES" "$CLOSEOUT"; do
    if grep -E '\]\((planning|repository-audit|linux-audit|macos-audit|execution|issue-stack|closeout)\.md\)' \
        "$phase" >/dev/null; then
        fail "selected reference cascades to another phase: $phase"
    fi
done
assert_contains 'do not preload this compatibility index' "$AGGREGATE" \
    'aggregate compatibility marker'

assert_contains 'same request is the `go`' "$PLANNING" \
    'existing execution authority'
assert_contains 'reproducible baseline, measurable benchmark' "$PLANNING" \
    'benchmark gate'
assert_contains 'one task in every' "$PLANNING" 'independent ledger gate'
assert_contains 'private repository' "$PLANNING" \
    'private Actions planning gate'
assert_contains 'Use `python3`' "$PLANNING" 'portable Python entry point'

assert_contains 'On the slightest new ambiguity or failed gate' "$ISSUES" \
    'LIFO trigger'
assert_contains 'next highest safe' "$ISSUES" \
    'same-repository continuation'
assert_contains 'Keep every other repository progressing independently' "$ISSUES" \
    'cross-repository continuation'
assert_contains 'administrator authority' "$ISSUES" \
    'administrator handoff'

assert_contains 'For private Actions' "$EXECUTION" \
    'private Actions execution gate'
assert_contains 'Treat pull-request code as untrusted' "$EXECUTION" \
    'untrusted-code boundary'
assert_contains 'required approving-review count of zero' "$EXECUTION" \
    'zero-review hardening baseline'
assert_contains 'git push origin HEAD:refs/heads/TASK_BRANCH' "$EXECUTION" \
    'explicit push refspec'
assert_contains 'Do not use plain `git push`' "$EXECUTION" \
    'matching-push guard'

assert_contains 'Use `guarded-bulk-delete`' "$CLOSEOUT" \
    'guarded cleanup gate'
assert_contains 'stop starting material changes at the frozen cutoff' "$CLOSEOUT" \
    'duration cutoff'
assert_contains 'At the deadline, stop execution' "$CLOSEOUT" \
    'deadline stop gate'
assert_contains 'every unfinished repository' "$CLOSEOUT" \
    'ledger handoff gate'

for audit in "$REPOSITORY" "$LINUX" "$MACOS"; do
    assert_contains 'failed query as `unknown`' "$audit" \
        "unknown-state classification in $audit"
done
assert_contains 'required pull-request approval' "$EXTERNAL_POLICY" \
    'zero-review global agreement'
assert_contains 'Harden fleets and repositories with LIFO recovery' "$OPENAI" \
    'OpenAI interface'

if grep -E '/home/|rioyokota|students|swallow|website|T-311' \
    "$SKILL" "$PLANNING" "$REPOSITORY" "$LINUX" "$MACOS" \
    "$EXECUTION" "$ISSUES" "$CLOSEOUT" "$AGGREGATE" "$OPENAI" \
    >/dev/null; then
    fail 'project- or owner-specific content'
fi

printf 'fleet_repository_hardening_skill=pass routes=7\n'
