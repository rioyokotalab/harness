#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
SKILL_ROOT=$ROOT/shared/skills/onboard-personal-mac
SKILL=$SKILL_ROOT/SKILL.md
PLANNING=$SKILL_ROOT/references/planning.md
COMMON=$SKILL_ROOT/references/execution-common.md
PRIVATE=$SKILL_ROOT/references/private-companion.md
PACKAGES=$SKILL_ROOT/references/bootstrap-packages.md
CONTROL=$SKILL_ROOT/references/public-control.md
STARTUP=$SKILL_ROOT/references/bash-startup.md
TMUX=$SKILL_ROOT/references/tmux.md
SSH_PRIVATE=$SKILL_ROOT/references/ssh-private.md
AGENT_CONFIG=$SKILL_ROOT/references/agent-config.md
ACCEPTANCE=$SKILL_ROOT/references/acceptance.md
ORPHAN=$SKILL_ROOT/references/orphan-cleanup.md
STAGES=$SKILL_ROOT/references/stages.md
OPENAI=$SKILL_ROOT/agents/openai.yaml

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
assert_contains() {
    pattern=$1
    file=$2
    label=$3
    grep -F -- "$pattern" "$file" >/dev/null || fail "$label"
}

for path in "$SKILL" "$PLANNING" "$COMMON" "$PRIVATE" "$PACKAGES" \
    "$CONTROL" "$STARTUP" "$TMUX" "$SSH_PRIVATE" "$AGENT_CONFIG" \
    "$ACCEPTANCE" "$ORPHAN" "$STAGES" "$OPENAI"; do
    [ -f "$path" ] && [ ! -L "$path" ] ||
        fail "missing regular skill resource: $path"
done

assert_contains 'name: onboard-personal-mac' "$SKILL" 'skill name'
assert_contains 'exactly one owner-named Mac' "$SKILL" 'one-host gate'
assert_contains 'owner supplies only' "$SKILL" 'native execution ownership'
assert_contains 'do not preload later phases or' "$SKILL" \
    'progressive-disclosure gate'
assert_contains 'Component routes augment `execution-common.md`' "$SKILL" \
    'cumulative component route'
assert_contains 'orphan route cumulatively includes' "$SKILL" \
    'cumulative orphan route'
assert_contains 'Do not mutate the target until `planning.md`' "$SKILL" \
    'plan/go mutation gate'
assert_contains 'Apply recorded owner defaults without asking again' "$SKILL" \
    'settled owner defaults'
assert_contains 'Stop rather than guess' "$SKILL" 'unknown-route stop'

expected_routes=$(printf '%s\n' \
    'acceptance.md' \
    'agent-config.md' \
    'bash-startup.md' \
    'bootstrap-packages.md' \
    'execution-common.md' \
    'orphan-cleanup.md' \
    'planning.md' \
    'private-companion.md' \
    'public-control.md' \
    'ssh-private.md' \
    'tmux.md')
actual_routes=$(grep -Eo '\]\(references/[a-z-]+\.md\)' "$SKILL" |
    sed 's#.*references/##; s#).*##' | sort -u)
[ "$actual_routes" = "$expected_routes" ] ||
    fail 'phase/component router does not select the exact eleven references'
if grep -F '](references/stages.md)' "$SKILL" >/dev/null; then
    fail 'normal route still selects the aggregate stages reference'
fi
for route in "$PLANNING" "$COMMON" "$PRIVATE" "$PACKAGES" "$CONTROL" \
    "$STARTUP" "$TMUX" "$SSH_PRIVATE" "$AGENT_CONFIG" "$ACCEPTANCE" \
    "$ORPHAN"; do
    if grep -E '\]\((planning|execution-common|private-companion|bootstrap-packages|public-control|bash-startup|tmux|ssh-private|agent-config|acceptance|orphan-cleanup)\.md\)' \
        "$route" >/dev/null; then
        fail "selected reference cascades to another route: $route"
    fi
done
assert_contains 'Do not preload this compatibility index' "$STAGES" \
    'legacy aggregate marker'

assert_contains 'Require exactly one owner-supplied' "$PLANNING" \
    'one-host planning gate'
assert_contains 'one material decision at a time' "$PLANNING" \
    'interview gate'
assert_contains 'wait for the owner' "$PLANNING" 'explicit go gate'
assert_contains 'macos-pilot-plan --host HOST' "$PLANNING" 'aggregate plan'
assert_contains 'private Mac validator' "$PLANNING" \
    'private profile validator'

assert_contains 'Print the resolved native command' "$COMMON" \
    'native command evidence'
assert_contains 'TCC response' "$COMMON" 'credential/TCC pause gate'
assert_contains 'transactional adapters' "$COMMON" 'transaction gate'
assert_contains 'reload an active shell or tmux' "$COMMON" \
    'no-live-reload gate'
assert_contains 'machine-local startup bytes' "$COMMON" \
    'startup byte preservation'

assert_contains 'baseline-only profile' "$PRIVATE" \
    'private companion owner default'
assert_contains 'native `gh` login' "$PRIVATE" 'native authentication route'
assert_contains 'macos-codex-bootstrap --host HOST --apply' "$PACKAGES" \
    'Codex bootstrap'
assert_contains 'pinned `PyYAML`' "$PACKAGES" 'PyYAML package gate'
assert_contains 'externally managed' "$PACKAGES" \
    'managed Python boundary'
assert_contains '`approval_policy=never`' "$PACKAGES" \
    'zero-prompt bootstrap stage'
assert_contains '`danger-full-access`' "$PACKAGES" \
    'bootstrap execution mode'
assert_contains 'no casks, services, taps, cleanup' "$PACKAGES" \
    'bounded Homebrew gate'
assert_contains 'macos-control --host HOST --plan|--apply' "$CONTROL" \
    'public control plan/apply'
assert_contains '`--merge-distinct-profile`' "$STARTUP" \
    'preserve-both Bash owner default'
assert_contains '`--merge-thin-profile-tail`' "$STARTUP" \
    'thin profile route'
assert_contains '`--remove-bash-common-reference`' "$STARTUP" \
    'Bash common reference route'
assert_contains 'without changing the native account shell' "$STARTUP" \
    'native shell gate'
assert_contains 'tmux-config --host HOST --plan|--apply' "$TMUX" \
    'tmux route'
assert_contains 'fresh isolated tmux server' "$TMUX" \
    'isolated tmux acceptance'
assert_contains '`--adopt-remote`' "$SSH_PRIVATE" \
    'remote SSH adoption owner default'
assert_contains 'two-sided divergence' "$SSH_PRIVATE" \
    'SSH divergence stop'
assert_contains 'SSH-only' "$SSH_PRIVATE" 'SSH-only private agreement'
assert_contains 'agent-config-catch-up --host HOST --adopt --plan|--apply' \
    "$AGENT_CONFIG" 'agent adoption route'
assert_contains 'allowed model, reasoning,' "$AGENT_CONFIG" \
    'strict Codex local body'
assert_contains 'both Codex and Claude' "$AGENT_CONFIG" \
    'Codex and Claude validation'

assert_contains 'exact unchanged-only rollback' "$ACCEPTANCE" \
    'rollback/reapply contract'
assert_contains 'macos-doctor --host HOST' "$ACCEPTANCE" \
    'doctor acceptance'
assert_contains 'protected CI' "$ACCEPTANCE" \
    'protected publication gate'
assert_contains 'live startup reference or open handle' "$ORPHAN" \
    'active Bash common retention'
assert_contains 'exact-unlink only a proven orphan' "$ORPHAN" \
    'orphan cleanup order'

assert_contains '$onboard-personal-mac' "$OPENAI" 'default prompt'
if rg -n '\[TODO:' "$SKILL_ROOT" >/dev/null; then
    fail 'skill retains template placeholder'
fi

printf '%s\n' 'personal Mac onboarding skill tests: PASS routes=11'
