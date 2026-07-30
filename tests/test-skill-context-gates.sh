#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
COWORK=$ROOT/shared/skills/codex-claude-cowork
HPC=$ROOT/shared/skills/operate-native-hpc
PIE=$ROOT/shared/skills/plan-interview-execute
REMOTE=$ROOT/shared/skills/remote-agent-communication
HARDENING=$ROOT/shared/skills/fleet-repository-hardening
PERSONAL_MAC=$ROOT/shared/skills/onboard-personal-mac

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
assert_contains() {
    pattern=$1
    file=$2
    label=$3
    grep -F -- "$pattern" "$file" >/dev/null || fail "$label"
}

for path in \
    "$COWORK/SKILL.md" \
    "$COWORK/references/session-planning.md" \
    "$COWORK/references/evidence-exchange.md" \
    "$COWORK/references/native-clients.md" \
    "$COWORK/references/execution-duration.md" \
    "$COWORK/references/recovery.md" \
    "$HPC/SKILL.md" \
    "$HPC/references/common.md" \
    "$HPC/references/current.md" \
    "$HPC/references/abci.md" \
    "$HPC/references/riken.md" \
    "$HPC/references/alps.md" \
    "$HPC/references/rccs.md" \
    "$HPC/references/tsubame.md" \
    "$REMOTE/SKILL.md" \
    "$REMOTE/references/delivery.md" \
    "$REMOTE/references/request.md" \
    "$REMOTE/references/fallback.md" \
    "$PIE/SKILL.md" \
    "$PIE/references/planning.md" \
    "$PIE/references/interview.md" \
    "$PIE/references/execution.md" \
    "$HARDENING/SKILL.md" \
    "$HARDENING/references/planning.md" \
    "$HARDENING/references/repository-audit.md" \
    "$HARDENING/references/linux-audit.md" \
    "$HARDENING/references/macos-audit.md" \
    "$HARDENING/references/execution.md" \
    "$HARDENING/references/issue-stack.md" \
    "$HARDENING/references/closeout.md" \
    "$HARDENING/references/audit-checklist.md" \
    "$PERSONAL_MAC/SKILL.md" \
    "$PERSONAL_MAC/references/planning.md" \
    "$PERSONAL_MAC/references/execution-common.md" \
    "$PERSONAL_MAC/references/private-companion.md" \
    "$PERSONAL_MAC/references/bootstrap-packages.md" \
    "$PERSONAL_MAC/references/public-control.md" \
    "$PERSONAL_MAC/references/bash-startup.md" \
    "$PERSONAL_MAC/references/tmux.md" \
    "$PERSONAL_MAC/references/ssh-private.md" \
    "$PERSONAL_MAC/references/agent-config.md" \
    "$PERSONAL_MAC/references/acceptance.md" \
    "$PERSONAL_MAC/references/orphan-cleanup.md" \
    "$PERSONAL_MAC/references/stages.md"; do
    [ -f "$path" ] && [ ! -L "$path" ] || fail "missing regular file: $path"
done

# Cowork keeps authority and stop gates in the always-read entry.
assert_contains 'Cowork never grants credential access' "$COWORK/SKILL.md" \
    'cowork credential/authority gate'
assert_contains 'co-pilot is unavailable, stop before target execution' \
    "$COWORK/SKILL.md" 'cowork unavailable-client stop'
assert_contains 'Planning and co-pilot experiments are read-only' \
    "$COWORK/SKILL.md" 'cowork target-read-only gate'
assert_contains 'never grant the co-pilot the live session' "$COWORK/SKILL.md" \
    'cowork live-session boundary'
assert_contains 'seal driver-owned live state outside all' "$COWORK/SKILL.md" \
    'cowork protected-state seal gate'
assert_contains 'A seal, freshness, destination,' "$COWORK/SKILL.md" \
    'cowork staged failure gate'
assert_contains 'They never authorize import' "$COWORK/SKILL.md" \
    'cowork advisory-status gate'
assert_contains 'Let only the driver mutate the target' "$COWORK/SKILL.md" \
    'cowork sole-writer gate'
assert_contains 'Otherwise wait for a new' "$COWORK/SKILL.md" \
    'cowork owner-go gate'
assert_contains 'Never use a bypass flag' "$COWORK/SKILL.md" \
    'cowork permission-refusal gate'
assert_contains 'guarded-deletion workflow' "$COWORK/SKILL.md" \
    'cowork guarded-cleanup gate'
assert_contains 'Cross-product role transfer requires an explicit owner instruction' \
    "$COWORK/SKILL.md" 'cowork takeover authority gate'

for route in session-planning evidence-exchange native-clients \
    execution-duration recovery; do
    assert_contains "[$route.md](references/$route.md)" "$COWORK/SKILL.md" \
        "cowork missing $route route"
done
assert_contains 'benchmark agreement precedes target execution' \
    "$COWORK/references/session-planning.md" 'cowork benchmark gate'
assert_contains 'not cross-file crash atomic' \
    "$COWORK/references/evidence-exchange.md" 'cowork crash ambiguity gate'
assert_contains '`--dangerously-skip-permissions`' \
    "$COWORK/references/native-clients.md" 'cowork Claude bypass gate'
assert_contains 'Unchanged blind retries' \
    "$COWORK/references/execution-duration.md" 'cowork iteration gate'
assert_contains 'retain a recoverable preimage' \
    "$COWORK/references/recovery.md" 'cowork recovery preimage gate'
assert_contains 'routing must use the task- and phase-specific references' \
    "$COWORK/references/protocol.md" 'cowork legacy aggregate marker'

# PIE must not manufacture an interview when decisions and authorization exist.
pie_frontmatter=$(sed -n '1,5p' "$PIE/SKILL.md")
printf '%s\n' "$pie_frontmatter" | grep -F \
    'skip fully frozen authorized execution' \
    >/dev/null || fail 'PIE narrow frontmatter trigger'
if printf '%s\n' "$pie_frontmatter" | grep -F \
    'for consequential, ambiguous, multi-step, or multi-session work' >/dev/null; then
    fail 'PIE retains broad legacy trigger'
fi
assert_contains 'complete frozen plan, resolved all material' "$PIE/SKILL.md" \
    'PIE frozen-plan bypass'
assert_contains 'an explicit `go` resumes Phase 3 directly' "$PIE/SKILL.md" \
    'PIE ready-for-go direct execution'
assert_contains 'do not manufacture an interview' "$PIE/SKILL.md" \
    'PIE empty-interview refusal'
assert_contains 'The go instruction authorizes only the frozen plan' "$PIE/SKILL.md" \
    'PIE go authority boundary'
for route in planning interview execution; do
    assert_contains "[$route.md](references/$route.md)" "$PIE/SKILL.md" \
        "PIE missing $route route"
done
assert_contains 'exactly one matching' "$PIE/SKILL.md" \
    'PIE single-phase routing gate'
assert_contains 'Do not mutate the target system during planning' \
    "$PIE/references/planning.md" 'PIE planning mutation boundary'
assert_contains 'Ask exactly one material decision question at a time' \
    "$PIE/references/interview.md" 'PIE one-question interview gate'
assert_contains 'Wait for an explicit owner instruction' \
    "$PIE/references/interview.md" 'PIE explicit go gate'
assert_contains 'Continue autonomously through settled choices' \
    "$PIE/references/execution.md" 'PIE execution autonomy gate'
assert_contains 'generation by itself is not acceptance' \
    "$PIE/references/execution.md" 'PIE independent acceptance gate'
assert_contains 'Do not add an' "$HARDENING/SKILL.md" \
    'hardening frozen-authority autonomy'
assert_contains 'same request is the `go`' \
    "$HARDENING/references/planning.md" \
    'hardening current-request execution authority'
for route in planning repository-audit linux-audit macos-audit execution \
    issue-stack closeout; do
    assert_contains "[$route.md](references/$route.md)" \
        "$HARDENING/SKILL.md" "hardening missing $route route"
done
assert_contains 'reproducible baseline, measurable benchmark' \
    "$HARDENING/references/planning.md" 'hardening benchmark gate'
assert_contains 'one task in every' "$HARDENING/references/planning.md" \
    'hardening ledger gate'
assert_contains 'On the slightest new ambiguity or failed gate' \
    "$HARDENING/references/issue-stack.md" 'hardening LIFO gate'
assert_contains 'For private Actions' \
    "$HARDENING/references/execution.md" \
    'hardening private Actions gate'
assert_contains 'Treat pull-request code as untrusted' \
    "$HARDENING/references/execution.md" \
    'hardening untrusted-code gate'
assert_contains 'required approving-review count of zero' \
    "$HARDENING/references/execution.md" \
    'hardening zero-approval gate'
assert_contains 'Use `guarded-bulk-delete`' \
    "$HARDENING/references/closeout.md" \
    'hardening cleanup gate'
assert_contains 'stop starting material changes at the frozen cutoff' \
    "$HARDENING/references/closeout.md" \
    'hardening duration cutoff'
assert_contains 'At the deadline, stop execution' \
    "$HARDENING/references/closeout.md" \
    'hardening deadline stop'
assert_contains 'do not preload this compatibility index' \
    "$HARDENING/references/audit-checklist.md" \
    'hardening legacy aggregate marker'

# HPC selects common plus one exact site and retains site-specific stop gates.
for route in common current abci riken alps rccs tsubame; do
    assert_contains "[$route.md](references/$route.md)" "$HPC/SKILL.md" \
        "HPC missing $route route"
done
[ "$(grep -Eoc '\[(current|abci|riken|alps|rccs|tsubame)\.md\]\(references/[a-z-]+\.md\)' \
    "$HPC/SKILL.md")" -eq 6 ] || fail 'HPC route table is not one-reference-per-site'
assert_contains 'exactly one selected site reference' "$HPC/SKILL.md" \
    'HPC one-site routing gate'
assert_contains 'target has no exact row, stop' "$HPC/SKILL.md" \
    'HPC unknown-target stop'
if grep -E 'ABCI|RIKYU|Alps|R-CCS|TSUBAME|`ab2?`|`ri`|`al`|`rc`|`t4`' \
    "$HPC/references/common.md" >/dev/null; then
    fail 'HPC common reference contains selected-site material'
fi
for route in current abci riken alps rccs tsubame; do
    if grep -E '\]\((current|abci|riken|alps|rccs|tsubame)\.md\)' \
        "$HPC/references/$route.md" >/dev/null; then
        fail "HPC $route reference pulls another site reference"
    fi
done
assert_contains 'Never use broad user-wide' \
    "$HPC/references/common.md" 'HPC scoped-cancel gate'
assert_contains 'no residue-free test-only mode' \
    "$HPC/references/current.md" 'current-node dry-run gate'
assert_contains 'explicit billing group and resource request' \
    "$HPC/references/abci.md" 'ABCI billing gate'
assert_contains 'do not describe a job as CPU-only' \
    "$HPC/references/riken.md" 'RIKEN allocation gate'
assert_contains 'requires an explicit project account' \
    "$HPC/references/alps.md" 'Alps account gate'
assert_contains 'Select the partition explicitly' \
    "$HPC/references/rccs.md" 'R-CCS partition gate'
assert_contains 'do not guess or consume points' \
    "$HPC/references/tsubame.md" 'TSUBAME points gate'
assert_contains 'Normal skill routing reads `common.md` and exactly' \
    "$HPC/references/sites.md" 'HPC legacy aggregate marker'

# Remote communication keeps common identity/retry gates in the entry and
# selects only the requested transport path.
for route in delivery request fallback; do
    assert_contains "[$route.md](references/$route.md)" "$REMOTE/SKILL.md" \
        "remote-agent missing $route route"
done
assert_contains 'Never create an autonomous' "$REMOTE/SKILL.md" \
    'remote-agent loop refusal'
assert_contains 'Never retry an acknowledged delivery' "$REMOTE/SKILL.md" \
    'remote-agent acknowledgement boundary'
assert_contains 'unique current-user Codex pane in `projects`' \
    "$REMOTE/SKILL.md" \
    'remote-agent canonical Local session'
assert_contains 'Do not put' "$REMOTE/references/delivery.md" \
    'remote-agent response evidence gate'
assert_contains 'does not use `ssh login`' "$REMOTE/references/request.md" \
    'remote-agent request route independence'
assert_contains 'Never invoke it twice' "$REMOTE/references/fallback.md" \
    'remote-agent fallback replay refusal'
if grep -F 'unique Codex pane in the `harness` session' \
    "$REMOTE/SKILL.md" >/dev/null; then
    fail 'remote-agent retains stale Local session'
fi

# Personal-Mac onboarding keeps one-host/go/unknown gates in the entry, then
# composes execution common with only the active component and acceptance.
for route in planning execution-common private-companion bootstrap-packages \
    public-control bash-startup tmux ssh-private agent-config acceptance \
    orphan-cleanup; do
    assert_contains "[$route.md](references/$route.md)" \
        "$PERSONAL_MAC/SKILL.md" "personal-Mac missing $route route"
done
assert_contains 'exactly one owner-named Mac' "$PERSONAL_MAC/SKILL.md" \
    'personal-Mac one-host gate'
assert_contains 'Do not mutate the target until `planning.md`' \
    "$PERSONAL_MAC/SKILL.md" 'personal-Mac plan/go gate'
assert_contains 'Component routes augment `execution-common.md`' \
    "$PERSONAL_MAC/SKILL.md" 'personal-Mac cumulative route gate'
assert_contains 'wait for the owner' \
    "$PERSONAL_MAC/references/planning.md" 'personal-Mac explicit go'
assert_contains 'selected task record' \
    "$PERSONAL_MAC/references/planning.md" \
    'personal-Mac routed task ledger'
assert_contains 'TCC response' \
    "$PERSONAL_MAC/references/execution-common.md" \
    'personal-Mac credential/TCC pause'
assert_contains 'reload an active shell or tmux' \
    "$PERSONAL_MAC/references/execution-common.md" \
    'personal-Mac no-live-reload gate'
assert_contains 'baseline-only profile' \
    "$PERSONAL_MAC/references/private-companion.md" \
    'personal-Mac private companion default'
assert_contains 'externally managed site-packages' \
    "$PERSONAL_MAC/references/bootstrap-packages.md" \
    'personal-Mac package boundary'
assert_contains '`approval_policy=never`' \
    "$PERSONAL_MAC/references/bootstrap-packages.md" \
    'personal-Mac zero-prompt bootstrap'
assert_contains '`--merge-distinct-profile`' \
    "$PERSONAL_MAC/references/bash-startup.md" \
    'personal-Mac startup default'
assert_contains 'fresh isolated tmux server' \
    "$PERSONAL_MAC/references/tmux.md" 'personal-Mac tmux isolation'
assert_contains '`--adopt-remote`' \
    "$PERSONAL_MAC/references/ssh-private.md" \
    'personal-Mac SSH adoption'
assert_contains 'both Codex and Claude' \
    "$PERSONAL_MAC/references/agent-config.md" \
    'personal-Mac agent configuration'
assert_contains 'exact unchanged-only rollback' \
    "$PERSONAL_MAC/references/acceptance.md" \
    'personal-Mac rollback/reapply gate'
assert_contains 'protected CI' \
    "$PERSONAL_MAC/references/acceptance.md" \
    'personal-Mac protected publication'
assert_contains 'live startup reference or open handle' \
    "$PERSONAL_MAC/references/orphan-cleanup.md" \
    'personal-Mac orphan retention gate'
assert_contains 'Do not preload this compatibility index' \
    "$PERSONAL_MAC/references/stages.md" \
    'personal-Mac legacy aggregate marker'

printf '%s\n' 'Skill context gate tests passed'
