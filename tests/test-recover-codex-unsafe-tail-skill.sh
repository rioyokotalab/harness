#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
AGENTS=$ROOT/AGENTS.md
RUNTIME_POLICY=$ROOT/docs/agent-policy/managed-codex.md
SKILL=$ROOT/shared/skills/recover-codex-unsafe-tail/SKILL.md
PROTOCOL=$ROOT/shared/skills/recover-codex-unsafe-tail/references/protocol.md
SAFE=$ROOT/shared/skills/recover-codex-unsafe-tail/references/safe-rollback.md
BRIDGE=$ROOT/shared/skills/recover-codex-unsafe-tail/references/bridge-first.md
ACCEPTANCE=$ROOT/shared/skills/recover-codex-unsafe-tail/references/acceptance.md
OPENAI=$ROOT/shared/skills/recover-codex-unsafe-tail/agents/openai.yaml

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

for path in "$AGENTS" "$RUNTIME_POLICY" "$SKILL" "$PROTOCOL" "$SAFE" \
    "$BRIDGE" "$ACCEPTANCE" "$OPENAI"; do
    [ -f "$path" ] && [ ! -L "$path" ] ||
        fail "missing skill resource: $path"
done

assert_contains 'name: recover-codex-unsafe-tail' "$SKILL" 'skill name'
assert_contains 'Request blocked' "$SKILL" 'blocked-thread trigger'

# Every normal route is directly reachable from the entry; diagnosis selects
# no transaction and the compatibility index is never loaded.
assert_contains '| diagnose or classify without mutation | no transaction reference |' \
    "$SKILL" 'diagnosis-only route'
assert_contains '[safe-rollback.md](references/safe-rollback.md)' "$SKILL" \
    'safe rollback route'
assert_contains '[bridge-first.md](references/bridge-first.md)' "$SKILL" \
    'bridge-first route'
assert_contains '[acceptance.md](references/acceptance.md)' "$SKILL" \
    'common acceptance route'
if grep -F '](references/protocol.md)' "$SKILL" >/dev/null; then
    fail 'normal route loads compatibility protocol'
fi
assert_contains 'Do not preload this legacy index' "$PROTOCOL" \
    'legacy aggregate marker'
assert_contains 'contains no transaction instructions' "$PROTOCOL" \
    'legacy aggregate boundary'

# Always-read authority, identity, content, and no-replay gates.
assert_contains 'narrow authority for that session' "$SKILL" \
    'narrow recovery authority'
assert_contains 'checkpoint before any app-server' "$SKILL" \
    'pre-write checkpoint'
assert_contains 'closed canonical map' "$SKILL" \
    'closed target map'
assert_contains 'stored thread CWD must' "$SKILL" \
    'target repository CWD gate'
assert_contains 'Every direct `codex-thread-recovery` `--plan`' "$SKILL" \
    'target-scoped plan invocation'
assert_contains '`--recover`, or `--watch` requires `--target TARGET`' \
    "$SKILL" 'target-scoped recover/watch invocation'
assert_contains '--status --name NAME --target TARGET' "$SKILL" \
    'target-aware diagnosis'
assert_contains 'supervisor/watcher/launcher/TUI identities and start' "$SKILL" \
    'runtime identity gate'
assert_contains 'Never read pane text, transcript or message text' "$SKILL" \
    'pane/transcript content boundary'
assert_contains 'reconstruct or replay a rejected prompt' "$SKILL" \
    'rejected-prompt replay boundary'
assert_contains 'restart the shared app server' "$SKILL" \
    'shared app-server boundary'
assert_contains 'signal a process group' "$SKILL" \
    'process-group signal boundary'
assert_contains 'use `SIGKILL`' "$SKILL" 'SIGKILL boundary'
assert_contains 'bridge-first cutover' "$RUNTIME_POLICY" \
    'global bridge-first policy'

# The safe transaction remains exactly one-shot and independently accepted.
assert_contains 'assistant-less, side-effect-free tail' "$SAFE" \
    'safe-tail proof'
assert_contains 'immediately before' "$SAFE" 'safe final identity gate'
assert_contains '--recover --name NAME --thread ID --target TARGET`' "$SAFE" \
    'single rollback transaction'
assert_contains "thread's stored CWD to equal its exact repository" "$SAFE" \
    'safe target/CWD identity'
assert_contains 'Never retry the request' "$SAFE" \
    'ambiguous rollback boundary'
assert_contains 'same root and' "$SAFE" 'safe root retention'
assert_contains 'never issue a second rollback' "$SAFE" \
    'post-rollback decision'

# Bridge creation, promotion, retirement, zombie, and retry gates.
assert_contains 'distinct provisional root, tmux window, and runtime name' \
    "$BRIDGE" 'distinct bridge identities'
assert_contains 'Root promotion is rename-only' "$BRIDGE" \
    'rename-only promotion'
assert_contains 'For a declared pane-native target' "$BRIDGE" \
    'pane-native promotion'
assert_contains '`break-pane -d`' "$BRIDGE" \
    'old pane preservation'
assert_contains '`join-pane -d`' "$BRIDGE" \
    'accepted pane promotion'
assert_contains 'Only after promotion and that published checkpoint' "$BRIDGE" \
    'promotion-before-retirement'
assert_contains 'must not block bridge launch or promotion' "$BRIDGE" \
    'zombie bridge boundary'
assert_contains 'Send one `SIGTERM` only to that leaf' "$BRIDGE" \
    'single-signal boundary'
assert_contains 'never send a second signal' "$BRIDGE" \
    'second-signal boundary'
assert_contains 'Treat an unreaped zombie as' "$BRIDGE" \
    'zombie presence boundary'
assert_contains 'never create a second root, window, or runtime' "$BRIDGE" \
    'ambiguous bridge boundary'
assert_contains 'unchanged app server' "$BRIDGE" \
    'bridge app-server identity'
assert_contains "TARGET\`'s exact closed-map repository" "$BRIDGE" \
    'bridge target/CWD identity'
assert_contains '--target TARGET --remote-session NEW_ID' "$BRIDGE" \
    'target-scoped bridge runtime'
assert_contains 'old TUI/launcher chain absent' "$BRIDGE" \
    'old chain acceptance'

# Common acceptance keeps unaffected state, doctor/fleet, request, and cleanup
# requirements selected by both transaction routes.
assert_contains 'unchanged unaffected sessions, shared app server' "$ACCEPTANCE" \
    'unaffected-session acceptance'
assert_contains "stored CWD equal to" "$ACCEPTANCE" \
    'accepted target/CWD identity'
assert_contains 'native doctor, focused recovery and resilience tests' \
    "$ACCEPTANCE" 'doctor acceptance'
assert_contains 'canonical fleet health' "$ACCEPTANCE" \
    'fleet acceptance'
assert_contains 'retry-forbidden boundary' "$ACCEPTANCE" \
    'non-retryable checkpoint'
assert_contains 'invoke `guarded-bulk-delete`' "$ACCEPTANCE" \
    'guarded-delete requirement'
assert_contains 'default_prompt: "Use $recover-codex-unsafe-tail' "$OPENAI" \
    'OpenAI interface'

direct_recovery_commands=$(grep -hE \
    'codex-thread-recovery --(plan|recover|watch)([[:space:]]|`)' \
    "$SKILL" "$SAFE" "$BRIDGE" "$ACCEPTANCE" "$PROTOCOL" || true)
[ -n "$direct_recovery_commands" ] ||
    fail 'no direct recovery command found for target isolation'
if printf '%s\n' "$direct_recovery_commands" |
    grep -Fv -- '--target TARGET' >/dev/null; then
    fail 'direct plan/recover/watch command lacks --target TARGET'
fi

for client in .agents .claude; do
    link=$ROOT/$client/skills/recover-codex-unsafe-tail
    [ -L "$link" ] || fail "$client discovery link"
    [ "$(readlink "$link")" = \
        ../../shared/skills/recover-codex-unsafe-tail ] ||
        fail "$client discovery target"
done

if grep -E '/home/|rioyokota|T-[0-9]+|SW-[0-9]+' \
    "$SKILL" "$PROTOCOL" "$SAFE" "$BRIDGE" "$ACCEPTANCE" "$OPENAI" \
    >/dev/null; then
    fail "owner- or incident-specific content"
fi
if grep -E 'rm[[:space:]]+-r|rm[[:space:]]+-rf|find .* -delete' \
    "$SKILL" "$PROTOCOL" "$SAFE" "$BRIDGE" "$ACCEPTANCE" >/dev/null; then
    fail "raw recursive deletion guidance"
fi

printf 'recover_codex_unsafe_tail_skill=pass\n'
