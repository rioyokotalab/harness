#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
COWORK=$ROOT/shared/skills/codex-claude-cowork
HPC=$ROOT/shared/skills/operate-native-hpc
PIE=$ROOT/shared/skills/plan-interview-execute/SKILL.md
REMOTE=$ROOT/shared/skills/remote-agent-communication/SKILL.md
HARDENING=$ROOT/shared/skills/fleet-repository-hardening/SKILL.md

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
words() { wc -w <"$1" | tr -d ' '; }
assert_max() {
    value=$1
    maximum=$2
    label=$3
    [ "$value" -le "$maximum" ] ||
        fail "$label word budget exceeded: $value > $maximum"
}

# Frozen T-351 baselines measured before conditional routing.
COWORK_BEFORE=5926
HPC_BEFORE=2668

cowork_entry=$(words "$COWORK/SKILL.md")
cowork_plan=$(words "$COWORK/references/session-planning.md")
cowork_initial=$((cowork_entry + cowork_plan))
assert_max "$cowork_entry" 1000 'cowork entry'
assert_max "$cowork_plan" 400 'cowork planning reference'
assert_max "$cowork_initial" 1300 'cowork initial planning route'
cowork_reduction=$(((COWORK_BEFORE - cowork_initial) * 100 / COWORK_BEFORE))
[ "$cowork_reduction" -ge 75 ] ||
    fail "cowork initial reduction is not material: $cowork_reduction%"

for name in evidence-exchange native-clients execution-duration recovery; do
    count=$(words "$COWORK/references/$name.md")
    assert_max "$count" 800 "cowork $name reference"
done

if grep -F '](references/protocol.md)' "$COWORK/SKILL.md" >/dev/null; then
    fail 'cowork entry still selects the aggregate protocol'
fi

hpc_entry=$(words "$HPC/SKILL.md")
hpc_common=$(words "$HPC/references/common.md")
assert_max "$hpc_entry" 900 'HPC entry'
assert_max "$hpc_common" 250 'HPC common reference'

hpc_largest=0
for name in current abci riken alps rccs tsubame; do
    site_words=$(words "$HPC/references/$name.md")
    assert_max "$site_words" 350 "HPC $name reference"
    route_words=$((hpc_entry + hpc_common + site_words))
    assert_max "$route_words" 1500 "HPC $name selected route"
    [ "$route_words" -le "$hpc_largest" ] || hpc_largest=$route_words
done
hpc_reduction=$(((HPC_BEFORE - hpc_largest) * 100 / HPC_BEFORE))
[ "$hpc_reduction" -ge 40 ] ||
    fail "HPC largest-route reduction is not material: $hpc_reduction%"

if grep -F '](references/sites.md)' "$HPC/SKILL.md" >/dev/null; then
    fail 'HPC entry still selects the aggregate sites reference'
fi

assert_max "$(words "$PIE")" 1150 'PIE entry'
assert_max "$(words "$REMOTE")" 1300 'remote-agent entry'
assert_max "$(words "$HARDENING")" 1200 'fleet-hardening entry'

printf '%s\n' \
    "Skill context budgets passed: cowork $COWORK_BEFORE->$cowork_initial words (-$cowork_reduction%); HPC $HPC_BEFORE->$hpc_largest words (-$hpc_reduction%, largest selected route)"
