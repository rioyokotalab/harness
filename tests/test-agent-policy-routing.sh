#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
AGENTS=$ROOT/AGENTS.md
EXTERNAL=$ROOT/docs/agent-policy/repository-and-external.md
RUNTIME=$ROOT/docs/agent-policy/managed-runtime-and-fleet.md
HOUSEKEEPING=$ROOT/docs/agent-policy/housekeeping-and-promotion.md
RESEARCH=$ROOT/docs/agent-policy/research.md

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

for path in "$AGENTS" "$EXTERNAL" "$RUNTIME" "$HOUSEKEEPING" "$RESEARCH"; do
    [ -f "$path" ] && [ ! -L "$path" ] ||
        fail "missing regular policy file: $path"
done

root_words=$(words "$AGENTS")
external_words=$(words "$EXTERNAL")
runtime_words=$(words "$RUNTIME")
housekeeping_words=$(words "$HOUSEKEEPING")
research_words=$(words "$RESEARCH")

assert_max "$root_words" 1050 'always-read policy'
assert_max "$external_words" 550 'repository/external policy'
assert_max "$runtime_words" 550 'runtime/fleet policy'
assert_max "$housekeeping_words" 300 'housekeeping/promotion policy'
assert_max "$research_words" 100 'research policy'
assert_max "$((root_words + external_words))" 1750 'Git selected route'
assert_max "$((root_words + runtime_words))" 1750 'runtime selected route'
assert_max "$((root_words + housekeeping_words))" 1500 \
    'housekeeping selected route'
assert_max "$((root_words + research_words))" 1300 'research selected route'

for route in repository-and-external managed-runtime-and-fleet \
    housekeeping-and-promotion research; do
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
assert_contains 'Git and `TODO.md` as the durable source of truth' "$AGENTS" \
    'durable source of truth'
assert_contains "task's board-linked record" "$AGENTS" \
    'selected active-task route'
assert_contains 'never expand it with task chronology' "$AGENTS" \
    'compact board handoff gate'
assert_contains 'never preload' "$AGENTS" 'archive selective-read gate'
assert_contains '`codex-claude-cowork` and' "$AGENTS" \
    'duration cowork route'
assert_contains 'Installed skill descriptions are the trigger index' "$AGENTS" \
    'skill catalog routing authority'
assert_contains 'REPLY_REQUIRED request_id=ID' "$AGENTS" \
    'bounded reply contract'

# Conditional authority stays reachable through the exact route that selects it.
assert_contains 'Owner approval alone never' "$EXTERNAL" \
    'installer exception boundary'
assert_contains 'approval count of zero' "$EXTERNAL" \
    'owner-selected zero approvals'
assert_contains 'SSH_AUTH_SOCK' "$EXTERNAL" 'agent socket boundary'
assert_contains 'bridge-first cutover' "$RUNTIME" \
    'bridge-first lifecycle boundary'
assert_contains 'docs/fleet-inventory.md' "$RUNTIME" \
    'fleet inventory route'
assert_contains 'Do not run it for every unrelated' "$RUNTIME" \
    'bounded fleet-health cadence'
assert_contains '$CODEX_HOME/tmp/arg0' "$HOUSEKEEPING" \
    'arg0 housekeeping route'
assert_contains 'Prefer primary sources' "$RESEARCH" \
    'research provenance default'

# Prove large task-specific details are not back in the mandatory core.
for unrelated in 'SSH_AUTH_SOCK' 'docs/fleet-inventory.md' \
    '$CODEX_HOME/tmp/arg0' 'Prefer primary sources'; do
    if grep -F -- "$unrelated" "$AGENTS" >/dev/null; then
        fail "conditional detail leaked into always-read policy: $unrelated"
    fi
done

grep -Fx '@AGENTS.md' "$ROOT/CLAUDE.md" >/dev/null ||
    fail 'Claude does not import the policy router'

printf '%s\n' \
    "AGENT_POLICY_ROUTING status=pass root_words=$root_words external=$external_words runtime=$runtime_words housekeeping=$housekeeping_words research=$research_words"
