#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
AGENTS=$ROOT/AGENTS.md
GIT_POLICY=$ROOT/docs/agent-policy/repository-git.md
EXTERNAL=$ROOT/docs/agent-policy/external-operations.md
CODEX=$ROOT/docs/agent-policy/managed-codex.md
FLEET=$ROOT/docs/agent-policy/fleet.md
HOUSEKEEPING=$ROOT/docs/agent-policy/housekeeping-and-promotion.md
RESEARCH=$ROOT/docs/agent-policy/research.md
DURATION=$ROOT/docs/agent-policy/duration.md

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
words() { wc -w <"$1" | tr -d ' '; }
assert_max() {
    value=$1
    maximum=$2
    label=$3
    [ "$value" -le "$maximum" ] ||
        fail "$label word budget exceeded: $value > $maximum"
}
assert_contains() {
    pattern=$1
    file=$2
    label=$3
    grep -F -- "$pattern" "$file" >/dev/null || fail "$label"
}

for path in "$AGENTS" "$GIT_POLICY" "$EXTERNAL" "$CODEX" "$FLEET" \
    "$HOUSEKEEPING" "$RESEARCH" "$DURATION"; do
    [ -f "$path" ] && [ ! -L "$path" ] ||
        fail "missing regular policy file: $path"
done

root_words=$(words "$AGENTS")
git_words=$(words "$GIT_POLICY")
external_words=$(words "$EXTERNAL")
codex_words=$(words "$CODEX")
fleet_words=$(words "$FLEET")
housekeeping_words=$(words "$HOUSEKEEPING")
research_words=$(words "$RESEARCH")
duration_words=$(words "$DURATION")

assert_max "$root_words" 900 'always-read policy'
assert_max "$git_words" 300 'repository Git policy'
assert_max "$external_words" 300 'external-operation policy'
assert_max "$codex_words" 250 'managed Codex policy'
assert_max "$fleet_words" 350 'fleet policy'
assert_max "$housekeeping_words" 275 'housekeeping/promotion policy'
assert_max "$research_words" 85 'research policy'
assert_max "$duration_words" 85 'duration policy'
assert_max "$((root_words + git_words))" 1200 'Git selected route'
assert_max "$((root_words + external_words))" 1200 \
    'external-operation selected route'
assert_max "$((root_words + codex_words))" 1150 \
    'managed Codex selected route'
assert_max "$((root_words + fleet_words))" 1250 'fleet selected route'
assert_max "$((root_words + git_words + external_words + fleet_words))" \
    1800 'repository/fleet hardening cumulative route'
assert_max "$((root_words + housekeeping_words))" 1200 \
    'housekeeping selected route'
assert_max "$((root_words + research_words))" 1000 'research selected route'
assert_max "$((root_words + duration_words))" 1000 'duration selected route'

for route in repository-git external-operations managed-codex fleet \
    housekeeping-and-promotion research duration; do
    assert_contains "[$route.md](docs/agent-policy/$route.md)" "$AGENTS" \
        "missing policy route: $route"
done

# Always-read boundaries cannot depend on selecting a conditional module.
assert_contains 'Never inspect, expose, copy, or modify credentials' "$AGENTS" \
    'credential boundary'
assert_contains 'Never run raw recursive or multi-path deletion' "$AGENTS" \
    'raw deletion refusal'
assert_contains 'guarded-bulk-delete' "$AGENTS" 'guarded deletion route'
assert_contains 'run a fresh native' "$AGENTS" 'fresh timestamp source'
assert_contains "\`date '+%H:%M:%S'\` read" "$AGENTS" \
    'native timestamp command'
assert_contains 'never blindly replay the prior prompt' "$AGENTS" \
    'provider retry boundary'
assert_contains 'safety, lifecycle, cleanup,' "$AGENTS" \
    'full validation escalation'
assert_contains 'not merely because a session resumed' "$AGENTS" \
    'unchanged validation reuse'
assert_contains 'Git and `TODO.md` as the durable source of truth' "$AGENTS" \
    'durable source of truth'
assert_contains "task's board-linked record" "$AGENTS" \
    'selected active-task route'
assert_contains 'never expand it with task chronology' "$AGENTS" \
    'compact board handoff gate'
assert_contains 'never preload' "$AGENTS" 'archive selective-read gate'
assert_contains 'Installed skill descriptions are the trigger index' "$AGENTS" \
    'skill catalog routing authority'

# Conditional authority stays reachable through the exact route that selects it.
assert_contains 'Owner approval alone never' "$EXTERNAL" \
    'installer exception boundary'
assert_contains 'Ordinary Git operations inside the active task' "$GIT_POLICY" \
    'standing Git authority'
assert_contains 'approval count of zero' "$GIT_POLICY" \
    'owner-selected zero approvals'
assert_contains 'SSH_AUTH_SOCK' "$GIT_POLICY" 'agent socket boundary'
assert_contains 'bridge-first cutover' "$CODEX" \
    'bridge-first lifecycle boundary'
assert_contains 'docs/fleet-inventory.md' "$FLEET" \
    'fleet inventory route'
assert_contains 'Do not run it for every unrelated' "$FLEET" \
    'bounded fleet-health cadence'
assert_contains 'REPLY_REQUIRED request_id=ID' "$CODEX" \
    'bounded reply contract'
assert_contains 'Only local' "$CODEX" 'reply submission evidence'
assert_contains '$CODEX_HOME/tmp/arg0' "$HOUSEKEEPING" \
    'arg0 housekeeping route'
assert_contains 'Prefer primary sources' "$RESEARCH" \
    'research provenance default'
assert_contains '`codex-claude-cowork` and `long-running-task-ledger`' \
    "$DURATION" 'duration cowork route'
assert_contains 'max(300, 50 * ceil(requested hours))' "$DURATION" \
    'duration summary floor'

# Prove large task-specific details are not back in the mandatory core.
for unrelated in 'SSH_AUTH_SOCK' 'docs/fleet-inventory.md' \
    '$CODEX_HOME/tmp/arg0' 'Prefer primary sources' \
    'max(300, 50 * ceil(requested hours))'; do
    if grep -F -- "$unrelated" "$AGENTS" >/dev/null; then
        fail "conditional detail leaked into always-read policy: $unrelated"
    fi
done

grep -Fx '@AGENTS.md' "$ROOT/CLAUDE.md" >/dev/null ||
    fail 'Claude does not import the policy router'

printf '%s\n' \
    "AGENT_POLICY_ROUTING status=pass root_words=$root_words git=$git_words external=$external_words codex=$codex_words fleet=$fleet_words housekeeping=$housekeeping_words research=$research_words duration=$duration_words"
