#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HPC=$ROOT/shared/skills/operate-native-hpc
HPC_PLANNING=$HPC/references/planning.md
HPC_EXECUTE=$HPC/references/execute-monitor.md
HPC_VALIDATION=$HPC/references/validation.md
PIE=$ROOT/shared/skills/plan-interview-execute
REMOTE=$ROOT/shared/skills/remote-agent-communication
HARDENING=$ROOT/shared/skills/fleet-repository-hardening
PERSONAL_MAC=$ROOT/shared/skills/onboard-personal-mac
UNSAFE=$ROOT/shared/skills/recover-codex-unsafe-tail
UNSAFE_SAFE=$UNSAFE/references/safe-rollback.md
UNSAFE_BRIDGE=$UNSAFE/references/bridge-first.md
UNSAFE_ACCEPTANCE=$UNSAFE/references/acceptance.md
UNSAFE_PROTOCOL=$UNSAFE/references/protocol.md

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
assert_contains() {
    pattern=$1
    file=$2
    label=$3
    grep -F -- "$pattern" "$file" >/dev/null || fail "$label"
}

for path in \
    "$HPC/SKILL.md" \
    "$HPC/references/common.md" \
    "$HPC/references/current.md" \
    "$HPC/references/abci.md" \
    "$HPC/references/abciq.md" \
    "$HPC/references/riken.md" \
    "$HPC/references/alps.md" \
    "$HPC/references/rccs.md" \
    "$HPC/references/tsubame.md" \
    "$HPC_PLANNING" \
    "$HPC_EXECUTE" \
    "$HPC_VALIDATION" \
    "$REMOTE/SKILL.md" \
    "$REMOTE/references/delivery.md" \
    "$REMOTE/references/local-codex.md" \
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
    "$PERSONAL_MAC/references/stages.md" \
    "$UNSAFE/SKILL.md" \
    "$UNSAFE_SAFE" \
    "$UNSAFE_BRIDGE" \
    "$UNSAFE_ACCEPTANCE" \
    "$UNSAFE_PROTOCOL"; do
    [ -f "$path" ] && [ ! -L "$path" ] || fail "missing regular file: $path"
done

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
for route in common current abci abciq riken alps rccs tsubame; do
    assert_contains "[$route.md](references/$route.md)" "$HPC/SKILL.md" \
        "HPC missing $route route"
done
for route in planning execute-monitor validation; do
    [ "$(grep -Fc "[$route.md](references/$route.md)" "$HPC/SKILL.md")" -eq 1 ] ||
        fail "HPC $route phase is not uniquely reachable"
done
[ "$(grep -Eoc '\[(current|abci|abciq|riken|alps|rccs|tsubame)\.md\]\(references/[a-z-]+\.md\)' \
    "$HPC/SKILL.md")" -eq 7 ] || fail 'HPC route table is not one-reference-per-site'
assert_contains 'Then read exactly one' "$HPC/SKILL.md" \
    'HPC one-site routing gate'
assert_contains 'target has no exact row, stop' "$HPC/SKILL.md" \
    'HPC unknown-target stop'
assert_contains 'Read only the current phase reference' "$HPC/SKILL.md" \
    'HPC one-phase routing gate'
assert_contains 'Do not preload later or completed phases' "$HPC/SKILL.md" \
    'HPC unloaded-phase gate'
assert_contains 'phase references never select one another' "$HPC/SKILL.md" \
    'HPC phase chaining refusal'
if grep -E '\]\([^)]*[.]md\)' \
    "$HPC_PLANNING" "$HPC_EXECUTE" "$HPC_VALIDATION" >/dev/null; then
    fail 'HPC phase reference selects another reference'
fi
if grep -E 'ABCI|RIKYU|Alps|R-CCS|TSUBAME|`ab2?`|`ri`|`al`|`rc`|`t4`' \
    "$HPC/references/common.md" >/dev/null; then
    fail 'HPC common reference contains selected-site material'
fi
for route in current abci abciq riken alps rccs tsubame; do
    if grep -E '\]\((current|abci|abciq|riken|alps|rccs|tsubame)\.md\)' \
        "$HPC/references/$route.md" >/dev/null; then
        fail "HPC $route reference pulls another site reference"
    fi
done

# These safety triggers must remain in the mandatory router even when every
# phase reference is unloaded.
assert_contains 'Reject an alias' "$HPC/SKILL.md" \
    'HPC target rejection'
assert_contains 'without a target profile' "$HPC/SKILL.md" \
    'HPC target-profile rejection'
assert_contains 'Never run workloads on proxy nodes' "$HPC/SKILL.md" \
    'HPC proxy rejection'
assert_contains 'print the fully resolved command prefixed with `NATIVE`' \
    "$HPC/SKILL.md" 'HPC native-command visibility'
assert_contains 'Put no hidden scheduler wrapper' "$HPC/SKILL.md" \
    'HPC hidden-wrapper refusal'
assert_contains 'required billing group or project account is missing' \
    "$HPC/SKILL.md" 'HPC missing billing/account stop'
assert_contains 'Never install a generic global framework' "$HPC/SKILL.md" \
    'HPC generic-framework refusal'
assert_contains 'Never read, print, record, or transmit credentials' \
    "$HPC/SKILL.md" 'HPC credential refusal'
assert_contains 'full environment dump' "$HPC/SKILL.md" \
    'HPC full-environment refusal'

assert_contains 'Separate login-node discovery from compute-node evidence' \
    "$HPC_PLANNING" 'HPC login/compute distinction'
assert_contains 'Freeze a correct baseline before optimization' \
    "$HPC_PLANNING" 'HPC frozen baseline'
assert_contains 'verify declared job and source paths retain the same bytes' \
    "$HPC_EXECUTE" 'HPC queued source-byte identity'
assert_contains 'explicitly reviewed shared boundary' "$HPC_EXECUTE" \
    'HPC multi-node shared-boundary gate'
assert_contains 'expected digest and executability from every intended node' \
    "$HPC_EXECUTE" 'HPC multi-node digest gate'
assert_contains 'exact-name collision query and require' "$HPC_EXECUTE" \
    'HPC collision-query gate'
assert_contains 'exact success grammar for one job ID' "$HPC_EXECUTE" \
    'HPC exact job-ID grammar'
assert_contains 'then immediately query that' "$HPC_EXECUTE" \
    'HPC exact job query'
assert_contains 'ID and match owner and name' "$HPC_EXECUTE" \
    'HPC job owner/name match'
assert_contains 'Monitor only the captured job ID' "$HPC_EXECUTE" \
    'HPC single-job monitor'
assert_contains 'Cancel only that ID' "$HPC_EXECUTE" \
    'HPC single-job cancellation'
assert_contains 'Remove only job-scoped temporary builds and smoke output' \
    "$HPC_EXECUTE" 'HPC narrow cleanup'
assert_contains 'CPU/build:' "$HPC_VALIDATION" 'HPC CPU validation'
assert_contains 'GPU:' "$HPC_VALIDATION" 'HPC GPU validation'
assert_contains 'MPI/distributed:' "$HPC_VALIDATION" 'HPC MPI validation'
assert_contains 'LLM training:' "$HPC_VALIDATION" 'HPC LLM validation'
assert_contains 'Performance:' "$HPC_VALIDATION" \
    'HPC performance validation'
assert_contains 'frozen baseline with matched commands' "$HPC_VALIDATION" \
    'HPC matched performance baseline'
assert_contains 'Record neither credentials nor a' "$HPC_VALIDATION" \
    'HPC validation credential refusal'
assert_contains 'Never use broad user-wide' \
    "$HPC/references/common.md" 'HPC scoped-cancel gate'
assert_contains 'exact success grammar for one job ID' \
    "$HPC/references/common.md" 'HPC common exact job-ID gate'
assert_contains 'match its owner and name' \
    "$HPC/references/common.md" 'HPC common owner/name query'
assert_contains 'exit status of every collision/status query' \
    "$HPC/references/common.md" 'HPC common collision status gate'
assert_contains 'Monitor or cancel only the captured job ID' \
    "$HPC/references/common.md" 'HPC common single-job gate'
assert_contains 'no residue-free test-only mode' \
    "$HPC/references/current.md" 'current-node dry-run gate'
assert_contains 'explicit billing group and resource request' \
    "$HPC/references/abci.md" 'ABCI billing gate'
assert_contains 'Check the status page before contacting the site' \
    "$HPC/references/abciq.md" 'ABCI-Q maintenance gate'
assert_contains 'never print PBS `Variable_List`' \
    "$HPC/references/abciq.md" 'ABCI-Q environment-output gate'
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
for route in delivery local-codex request fallback; do
    assert_contains "[$route.md](references/$route.md)" "$REMOTE/SKILL.md" \
        "remote-agent missing $route route"
done
assert_contains 'Never create an autonomous' "$REMOTE/SKILL.md" \
    'remote-agent loop refusal'
assert_contains 'Never retry an acknowledged delivery' "$REMOTE/SKILL.md" \
    'remote-agent acknowledgement boundary'
assert_contains '`profiles/codex-session-targets.tsv`' \
    "$REMOTE/SKILL.md" \
    'remote-agent canonical Local target profile'
assert_contains 'Do not put' "$REMOTE/references/delivery.md" \
    'remote-agent response evidence gate'
assert_contains 'does not use `ssh login`' "$REMOTE/references/request.md" \
    'remote-agent request route independence'
assert_contains 'Never invoke it twice' "$REMOTE/references/fallback.md" \
    'remote-agent fallback replay refusal'
assert_contains 'confirm-local-codex' "$REMOTE/references/local-codex.md" \
    'remote-agent Local confirmation route'
assert_contains 'never grants owner authority' \
    "$REMOTE/references/local-codex.md" \
    'remote-agent confirmation non-escalation'
assert_contains 'closes a terminal checkpoint' \
    "$REMOTE/references/local-codex.md" \
    'remote-agent terminal confirmation boundary'
assert_contains 'reversible owner-choice wait' \
    "$REMOTE/references/local-codex.md" \
    'remote-agent queue-local owner gate'
assert_contains 'creates no terminal receipt' \
    "$REMOTE/references/local-codex.md" \
    'remote-agent reversible receipt boundary'
assert_contains 'Never delete or rewrite one to resume work' \
    "$REMOTE/references/local-codex.md" \
    'remote-agent terminal receipt invariant'
assert_contains 'codex-thread-recovery --check --target personal' \
    "$REMOTE/references/local-codex.md" \
    'remote-agent active-turn preflight'
if grep -F 'unique current-user Codex pane in `projects`' \
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

# Unsafe-tail diagnosis loads no transaction. Each mutation route directly
# selects only its exact transaction plus common acceptance.
assert_contains '| diagnose or classify without mutation | no transaction reference |' \
    "$UNSAFE/SKILL.md" 'unsafe-tail diagnosis route'
assert_contains '[safe-rollback.md](references/safe-rollback.md)' \
    "$UNSAFE/SKILL.md" 'unsafe-tail safe route'
assert_contains '[bridge-first.md](references/bridge-first.md)' \
    "$UNSAFE/SKILL.md" 'unsafe-tail bridge route'
[ "$(grep -Fc '[acceptance.md](references/acceptance.md)' \
    "$UNSAFE/SKILL.md")" -eq 2 ] ||
    fail 'unsafe-tail acceptance is not selected by both transactions'
assert_contains 'References do not select one another' "$UNSAFE/SKILL.md" \
    'unsafe-tail no-reference-chaining gate'
if grep -F '](references/protocol.md)' "$UNSAFE/SKILL.md" >/dev/null; then
    fail 'unsafe-tail entry selects legacy aggregate'
fi
if grep -E '(safe-rollback|bridge-first|acceptance|protocol)\.md' \
    "$UNSAFE_SAFE" "$UNSAFE_BRIDGE" "$UNSAFE_ACCEPTANCE" >/dev/null; then
    fail 'unsafe-tail reference selects a cross-route reference'
fi
assert_contains 'Do not preload this legacy index' "$UNSAFE_PROTOCOL" \
    'unsafe-tail legacy aggregate marker'
assert_contains 'contains no transaction instructions' "$UNSAFE_PROTOCOL" \
    'unsafe-tail compatibility-only index'

# Marker coverage protects the safety semantics across their selected routes.
assert_contains 'narrow authority for that session' "$UNSAFE/SKILL.md" \
    'unsafe-tail authority marker'
assert_contains 'closed canonical map' "$UNSAFE/SKILL.md" \
    'unsafe-tail closed-target marker'
assert_contains 'stored thread CWD must' "$UNSAFE/SKILL.md" \
    'unsafe-tail target/CWD marker'
assert_contains 'Every direct `codex-thread-recovery` `--plan`' \
    "$UNSAFE/SKILL.md" 'unsafe-tail target-scoped plan marker'
assert_contains '`--recover`, or `--watch` requires `--target TARGET`' \
    "$UNSAFE/SKILL.md" 'unsafe-tail target-scoped recover/watch marker'
assert_contains '--status --name NAME --target TARGET' "$UNSAFE/SKILL.md" \
    'unsafe-tail target-aware status marker'
assert_contains 'supervisor/watcher/launcher/TUI identities' \
    "$UNSAFE/SKILL.md" 'unsafe-tail identity marker'
assert_contains 'Never read pane text, transcript or message text' \
    "$UNSAFE/SKILL.md" 'unsafe-tail content marker'
assert_contains 'reconstruct or replay a rejected prompt' "$UNSAFE/SKILL.md" \
    'unsafe-tail no-replay marker'
assert_contains 'Never retry the request' "$UNSAFE_SAFE" \
    'unsafe-tail rollback non-retry marker'
assert_contains '--recover --name NAME --thread ID --target TARGET`' \
    "$UNSAFE_SAFE" 'unsafe-tail target-scoped rollback marker'
assert_contains "thread's stored CWD to equal its exact repository" \
    "$UNSAFE_SAFE" 'unsafe-tail rollback target/CWD marker'
assert_contains 'never retry a sent' "$UNSAFE_BRIDGE" \
    'unsafe-tail bridge non-retry marker'
assert_contains 'Bridge-first fresh-root replacement' "$UNSAFE_BRIDGE" \
    'unsafe-tail bridge-first marker'
assert_contains 'must not block bridge launch or promotion' "$UNSAFE_BRIDGE" \
    'unsafe-tail zombie marker'
assert_contains 'Send one `SIGTERM` only to that leaf' "$UNSAFE_BRIDGE" \
    'unsafe-tail signal marker'
assert_contains 'restart the shared app server' "$UNSAFE/SKILL.md" \
    'unsafe-tail app-server marker'
assert_contains "TARGET\`'s exact closed-map repository" "$UNSAFE_BRIDGE" \
    'unsafe-tail bridge target/CWD marker'
assert_contains 'unchanged unaffected sessions, shared app server' \
    "$UNSAFE_ACCEPTANCE" 'unsafe-tail unaffected-session marker'
assert_contains 'accepted target unchanged' "$UNSAFE_ACCEPTANCE" \
    'unsafe-tail accepted-target marker'
assert_contains 'native doctor, focused recovery and resilience tests' \
    "$UNSAFE_ACCEPTANCE" 'unsafe-tail doctor marker'
assert_contains 'canonical fleet health' "$UNSAFE_ACCEPTANCE" \
    'unsafe-tail fleet marker'
assert_contains 'invoke `guarded-bulk-delete`' "$UNSAFE_ACCEPTANCE" \
    'unsafe-tail guarded-delete marker'

unsafe_direct_commands=$(grep -hE \
    'codex-thread-recovery --(plan|recover|watch)([[:space:]]|`)' \
    "$UNSAFE/SKILL.md" "$UNSAFE_SAFE" "$UNSAFE_BRIDGE" \
    "$UNSAFE_ACCEPTANCE" "$UNSAFE_PROTOCOL" || true)
[ -n "$unsafe_direct_commands" ] ||
    fail 'unsafe-tail direct recovery command coverage is empty'
if printf '%s\n' "$unsafe_direct_commands" |
    grep -Fv -- '--target TARGET' >/dev/null; then
    fail 'unsafe-tail direct recovery command lacks --target TARGET'
fi

printf '%s\n' 'Skill context gate tests passed'
