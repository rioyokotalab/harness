#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
COWORK=$ROOT/shared/skills/codex-claude-cowork
HPC=$ROOT/shared/skills/operate-native-hpc
PIE=$ROOT/shared/skills/plan-interview-execute/SKILL.md
REMOTE=$ROOT/shared/skills/remote-agent-communication
HARDENING=$ROOT/shared/skills/fleet-repository-hardening/SKILL.md

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
    "$PIE" "$HARDENING"; do
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
pie_frontmatter=$(sed -n '1,5p' "$PIE")
printf '%s\n' "$pie_frontmatter" | grep -F \
    'Do not trigger merely because work is consequential, multi-step, multi-session' \
    >/dev/null || fail 'PIE narrow frontmatter trigger'
if printf '%s\n' "$pie_frontmatter" | grep -F \
    'for consequential, ambiguous, multi-step, or multi-session work' >/dev/null; then
    fail 'PIE retains broad legacy trigger'
fi
assert_contains 'complete frozen plan, resolved all material' "$PIE" \
    'PIE frozen-plan bypass'
assert_contains 'an explicit `go` resumes Phase 3 directly' "$PIE" \
    'PIE ready-for-go direct execution'
assert_contains 'do not manufacture an interview' "$PIE" \
    'PIE empty-interview refusal'
assert_contains 'The go instruction authorizes only the frozen plan' "$PIE" \
    'PIE go authority boundary'
assert_contains 'add another interview or confirmation' "$HARDENING" \
    'hardening frozen-authority autonomy'
assert_contains 'same request is the `go`' "$HARDENING" \
    'hardening current-request execution authority'

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

printf '%s\n' 'Skill context gate tests passed'
