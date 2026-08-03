#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HPC=$ROOT/shared/skills/operate-native-hpc
PIE=$ROOT/shared/skills/plan-interview-execute
REMOTE=$ROOT/shared/skills/remote-agent-communication
HARDENING=$ROOT/shared/skills/fleet-repository-hardening
PERSONAL_MAC=$ROOT/shared/skills/onboard-personal-mac
UNSAFE=$ROOT/shared/skills/recover-codex-unsafe-tail

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
HPC_BEFORE=2668
HPC_LARGEST_BEFORE=1397
# One independently routed ABCI-Q reference adds capability without increasing
# any unrelated selected route. Keep that addition bounded rather than
# rewriting the historical pre-routing baseline.
HPC_ABCIQ_ADDITION_MAX=220
REMOTE_BEFORE=1241
# Before routing, every hardening invocation selected both the 1,130-word
# entry and its 301-word aggregate checklist.
HARDENING_BEFORE=1431
# Before routing, every personal-Mac invocation selected the 889-word entry
# and its mandatory 638-word aggregate stage reference.
PERSONAL_MAC_BEFORE=1527
# Before routing, diagnosis selected only the 455-word entry; either live
# transaction selected that entry plus the 766-word aggregate protocol.
UNSAFE_DIAGNOSIS_BEFORE=455
UNSAFE_TRANSACTION_BEFORE=1221

hpc_entry=$(words "$HPC/SKILL.md")
hpc_common=$(words "$HPC/references/common.md")
assert_max "$hpc_entry" 300 'HPC entry'
assert_max "$hpc_common" 250 'HPC common reference'

hpc_phase_total=0
hpc_phase_largest=0
for name in planning execute-monitor validation; do
    phase_words=$(words "$HPC/references/$name.md")
    assert_max "$phase_words" 270 "HPC $name phase reference"
    hpc_phase_total=$((hpc_phase_total + phase_words))
    [ "$phase_words" -le "$hpc_phase_largest" ] ||
        hpc_phase_largest=$phase_words
done

hpc_site_total=0
hpc_largest=0
for name in current abci abciq riken alps rccs tsubame; do
    site_words=$(words "$HPC/references/$name.md")
    assert_max "$site_words" 350 "HPC $name reference"
    hpc_site_total=$((hpc_site_total + site_words))
    route_words=$((hpc_entry + hpc_common + site_words +
        hpc_phase_largest))
    assert_max "$route_words" 1125 "HPC $name selected route"
    [ "$route_words" -le "$hpc_largest" ] || hpc_largest=$route_words
done
hpc_aggregate=$((hpc_entry + hpc_common + hpc_site_total +
    hpc_phase_total))
assert_max "$hpc_aggregate" "$((HPC_BEFORE + HPC_ABCIQ_ADDITION_MAX))" \
    'HPC aggregate with bounded ABCI-Q route'
hpc_reduction=$(((HPC_LARGEST_BEFORE - hpc_largest) * 100 /
    HPC_LARGEST_BEFORE))
[ "$hpc_reduction" -ge 20 ] ||
    fail "HPC largest-route reduction is not material: $hpc_reduction%"

if grep -F '](references/sites.md)' "$HPC/SKILL.md" >/dev/null; then
    fail 'HPC entry still selects the aggregate sites reference'
fi

PIE_BEFORE=1088
pie_entry=$(words "$PIE/SKILL.md")
assert_max "$pie_entry" 600 'PIE entry'
pie_largest=0
for name in planning interview execution; do
    phase_words=$(words "$PIE/references/$name.md")
    assert_max "$phase_words" 400 "PIE $name reference"
    route_words=$((pie_entry + phase_words))
    assert_max "$route_words" 850 "PIE $name selected route"
    [ "$route_words" -le "$pie_largest" ] || pie_largest=$route_words
done
pie_reduction=$(((PIE_BEFORE - pie_largest) * 100 / PIE_BEFORE))
[ "$pie_reduction" -ge 25 ] ||
    fail "PIE largest-route reduction is not material: $pie_reduction%"
remote_entry=$(words "$REMOTE/SKILL.md")
assert_max "$remote_entry" 245 'remote-agent entry'
remote_largest=0
for name in delivery local-codex request fallback; do
    route_words=$(words "$REMOTE/references/$name.md")
    assert_max "$route_words" 400 "remote-agent $name reference"
    selected_words=$((remote_entry + route_words))
    assert_max "$selected_words" 675 "remote-agent $name selected route"
    [ "$selected_words" -le "$remote_largest" ] ||
        remote_largest=$selected_words
done
remote_local_reference=$(words "$REMOTE/references/local-codex.md")
remote_local=$((remote_entry + remote_local_reference))
assert_max "$remote_local" 500 'remote-agent Local Codex selected route'
remote_delivery_reference=$(words "$REMOTE/references/delivery.md")
remote_delivery=$((remote_entry + remote_delivery_reference))
assert_max "$remote_delivery" 600 'remote-agent delivery selected route'
remote_reduction=$(((REMOTE_BEFORE - remote_largest) * 100 / REMOTE_BEFORE))
[ "$remote_reduction" -ge 45 ] ||
    fail "remote-agent largest-route reduction is not material: $remote_reduction%"
hardening_entry=$(words "$HARDENING/SKILL.md")
assert_max "$hardening_entry" 450 'fleet-hardening entry'
hardening_largest=0
for name in planning repository-audit linux-audit macos-audit execution \
    closeout; do
    phase_words=$(words "$HARDENING/references/$name.md")
    assert_max "$phase_words" 350 "fleet-hardening $name reference"
    selected_words=$((hardening_entry + phase_words))
    assert_max "$selected_words" 750 \
        "fleet-hardening $name selected route"
    [ "$selected_words" -le "$hardening_largest" ] ||
        hardening_largest=$selected_words
done
issue_words=$(words "$HARDENING/references/issue-stack.md")
assert_max "$issue_words" 220 'fleet-hardening issue-stack reference'
# The router explicitly adds issue handling to the interrupted phase. Measure
# that cumulative route rather than pretending issue handling replaces it.
hardening_issue_route=$((hardening_largest + issue_words))
[ "$hardening_issue_route" -le 950 ] ||
    fail "fleet-hardening interrupted-phase route exceeds 950 words: $hardening_issue_route"
hardening_largest=$hardening_issue_route
hardening_reduction=$(((HARDENING_BEFORE - hardening_largest) * 100 / HARDENING_BEFORE))
[ "$hardening_reduction" -ge 35 ] ||
    fail "fleet-hardening largest-route reduction is not material: $hardening_reduction%"
assert_max "$(words "$HARDENING/references/audit-checklist.md")" 80 \
    'fleet-hardening compatibility audit index'

personal_entry=$(words "$PERSONAL_MAC/SKILL.md")
personal_common=$(words "$PERSONAL_MAC/references/execution-common.md")
personal_planning=$(words "$PERSONAL_MAC/references/planning.md")
assert_max "$personal_entry" 450 'personal-Mac entry'
assert_max "$personal_common" 250 'personal-Mac execution common'
personal_planning_route=$((personal_entry + personal_planning))
assert_max "$personal_planning_route" 700 'personal-Mac planning route'

personal_component_words_largest=0
personal_component_largest=0
for name in private-companion bootstrap-packages public-control bash-startup \
    tmux ssh-private agent-config; do
    component_words=$(words "$PERSONAL_MAC/references/$name.md")
    assert_max "$component_words" 160 "personal-Mac $name reference"
    selected_words=$((personal_entry + personal_common + component_words))
    assert_max "$selected_words" 850 \
        "personal-Mac $name execution route"
    [ "$component_words" -le "$personal_component_words_largest" ] ||
        personal_component_words_largest=$component_words
    [ "$selected_words" -le "$personal_component_largest" ] ||
        personal_component_largest=$selected_words
done

personal_acceptance=$(words "$PERSONAL_MAC/references/acceptance.md")
assert_max "$personal_acceptance" 180 'personal-Mac acceptance reference'
# Acceptance augments execution common and the exact component under test.
personal_acceptance_route=$((personal_entry + personal_common +
    personal_acceptance + personal_component_words_largest))
assert_max "$personal_acceptance_route" 1000 \
    'personal-Mac component acceptance route'
personal_orphan=$(words "$PERSONAL_MAC/references/orphan-cleanup.md")
assert_max "$personal_orphan" 100 'personal-Mac orphan reference'
# Orphan cleanup may augment component acceptance during revalidation. Count
# that largest cumulative combination rather than dropping the component.
personal_orphan_route=$((personal_entry + personal_common +
    personal_acceptance + personal_component_words_largest + personal_orphan))
assert_max "$personal_orphan_route" 1000 \
    'personal-Mac cumulative orphan route'

personal_largest=$personal_component_largest
[ "$personal_acceptance_route" -le "$personal_largest" ] ||
    personal_largest=$personal_acceptance_route
[ "$personal_orphan_route" -le "$personal_largest" ] ||
    personal_largest=$personal_orphan_route
personal_reduction=$(((PERSONAL_MAC_BEFORE - personal_largest) * 100 /
    PERSONAL_MAC_BEFORE))
[ "$personal_reduction" -ge 35 ] ||
    fail "personal-Mac largest-route reduction is not material: $personal_reduction%"
assert_max "$(words "$PERSONAL_MAC/references/stages.md")" 80 \
    'personal-Mac compatibility stage index'

unsafe_entry=$(words "$UNSAFE/SKILL.md")
unsafe_safe=$(words "$UNSAFE/references/safe-rollback.md")
unsafe_bridge=$(words "$UNSAFE/references/bridge-first.md")
unsafe_acceptance=$(words "$UNSAFE/references/acceptance.md")
assert_max "$unsafe_entry" 420 'unsafe-tail entry'
assert_max "$unsafe_safe" 180 'unsafe-tail safe rollback reference'
assert_max "$unsafe_bridge" 620 'unsafe-tail bridge reference'
assert_max "$unsafe_acceptance" 180 'unsafe-tail common acceptance'

unsafe_diagnosis_route=$unsafe_entry
unsafe_safe_route=$((unsafe_entry + unsafe_safe + unsafe_acceptance))
unsafe_bridge_route=$((unsafe_entry + unsafe_bridge + unsafe_acceptance))
assert_max "$unsafe_diagnosis_route" 420 \
    'unsafe-tail diagnosis selected route'
assert_max "$unsafe_safe_route" 750 \
    'unsafe-tail safe rollback selected route'
assert_max "$unsafe_bridge_route" 1180 \
    'unsafe-tail bridge selected route'

unsafe_diagnosis_reduction=$(((UNSAFE_DIAGNOSIS_BEFORE -
    unsafe_diagnosis_route) * 100 / UNSAFE_DIAGNOSIS_BEFORE))
unsafe_safe_reduction=$(((UNSAFE_TRANSACTION_BEFORE - unsafe_safe_route) *
    100 / UNSAFE_TRANSACTION_BEFORE))
unsafe_bridge_reduction=$(((UNSAFE_TRANSACTION_BEFORE - unsafe_bridge_route) *
    100 / UNSAFE_TRANSACTION_BEFORE))
[ "$unsafe_diagnosis_reduction" -ge 10 ] ||
    fail "unsafe-tail diagnosis reduction is not material: $unsafe_diagnosis_reduction%"
[ "$unsafe_safe_reduction" -ge 40 ] ||
    fail "unsafe-tail rollback reduction is not material: $unsafe_safe_reduction%"
[ "$unsafe_bridge_reduction" -ge 5 ] ||
    fail "unsafe-tail bridge reduction is not material: $unsafe_bridge_reduction%"
assert_max "$(words "$UNSAFE/references/protocol.md")" 80 \
    'unsafe-tail compatibility protocol index'

printf '%s\n' \
    "Skill context budgets passed: HPC aggregate $HPC_BEFORE->$hpc_aggregate words, largest route $HPC_LARGEST_BEFORE->$hpc_largest (-$hpc_reduction%); PIE $PIE_BEFORE->$pie_largest words (-$pie_reduction%); remote $REMOTE_BEFORE->$remote_largest words (-$remote_reduction%); hardening $HARDENING_BEFORE->$hardening_largest words (-$hardening_reduction%, largest selected routes including interrupted phase); personal-Mac $PERSONAL_MAC_BEFORE->$personal_largest words (-$personal_reduction%, cumulative component acceptance); unsafe-tail diagnosis $UNSAFE_DIAGNOSIS_BEFORE->$unsafe_diagnosis_route words (-$unsafe_diagnosis_reduction%), rollback $UNSAFE_TRANSACTION_BEFORE->$unsafe_safe_route words (-$unsafe_safe_reduction%), bridge $UNSAFE_TRANSACTION_BEFORE->$unsafe_bridge_route words (-$unsafe_bridge_reduction%)"
