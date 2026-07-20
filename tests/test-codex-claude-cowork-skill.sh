#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
SKILL=$ROOT/shared/skills/codex-claude-cowork/SKILL.md
PROTOCOL=$ROOT/shared/skills/codex-claude-cowork/references/protocol.md
SESSION=$ROOT/shared/skills/codex-claude-cowork/scripts/cowork-session
OPENAI=$ROOT/shared/skills/codex-claude-cowork/agents/openai.yaml
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/harness-cowork-test.XXXXXX")

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEMP_DIR" ]; then
        "$CLEANUP" "$HARNESS" "${TMPDIR:-/tmp}" "$TEMP_DIR" \
            "${TMPDIR:-/tmp}" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then
        echo 'FAIL: guarded cowork skill test cleanup' >&2
        status=1
    fi
    exit "$status"
}

trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

for path in "$SKILL" "$PROTOCOL" "$SESSION" "$OPENAI"; do
    [ -f "$path" ] && [ ! -L "$path" ] || fail "missing regular file: $path"
done
[ -x "$SESSION" ] || fail 'session validator is not executable'

grep -Fx 'name: codex-claude-cowork' "$SKILL" >/dev/null || fail 'skill name'
grep -F 'as driver and the other as co-pilot' "$SKILL" >/dev/null || fail 'driver rule'
grep -F 'Neither may overwrite the other' "$SKILL" >/dev/null || fail 'file ownership'
grep -F 'prose-only review is insufficient' "$SKILL" >/dev/null || fail 'experiment gate'
grep -F 'Let only the driver mutate the target' "$SKILL" >/dev/null || fail 'execution role'
grep -F 'Do not grant either' "$SKILL" >/dev/null || fail 'role symmetry'
grep -F 'claude --print --permission-mode dontAsk' "$PROTOCOL" >/dev/null ||
    fail 'Codex-driver native Claude mapping'
grep -F 'codex --ask-for-approval never exec --ephemeral' "$PROTOCOL" >/dev/null ||
    fail 'Claude-driver native Codex mapping'
grep -F -- '`--dangerously-skip-permissions`' "$PROTOCOL" >/dev/null ||
    fail 'Claude bypass refusal'

fill() {
    file=$1
    sed 's/^TODO$/verified synthetic evidence/' "$file" >"$file.next"
    mv "$file.next" "$file"
}

codex_session=$TEMP_DIR/codex-driver
"$SESSION" init "$codex_session" --driver codex >/dev/null
[ -d "$codex_session/artifacts" ] && [ ! -L "$codex_session/artifacts" ] ||
    fail 'real artifacts directory'
python3 - "$codex_session/state.json" <<'PY'
import json
import pathlib
import sys

state = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert state["driver"] == "codex"
assert state["copilot"] == "claude"
assert state["phase"] == "planning"
PY

if "$SESSION" advance "$codex_session" discussing >"$TEMP_DIR/early.out" 2>&1; then
    fail 'advanced with unfinished planning files'
fi
grep -F 'unresolved TODO marker' "$TEMP_DIR/early.out" >/dev/null ||
    fail 'missing unfinished-file refusal'
fill "$codex_session/charter.md"
fill "$codex_session/plan.md"
printf '\n  TODO marker mentioned as evidence, not a placeholder.\n' \
    >>"$codex_session/plan.md"
"$SESSION" advance "$codex_session" discussing >/dev/null

if "$SESSION" advance "$codex_session" executing >"$TEMP_DIR/skip.out" 2>&1; then
    fail 'skipped ready-for-execution phase'
fi
grep -F 'invalid transition' "$TEMP_DIR/skip.out" >/dev/null ||
    fail 'missing skipped-phase refusal'

fill "$codex_session/driver-evidence.md"
fill "$codex_session/copilot-evidence.md"
fill "$codex_session/reconciliation.md"
"$SESSION" advance "$codex_session" ready-for-execution >/dev/null
"$SESSION" advance "$codex_session" executing >/dev/null
fill "$codex_session/execution.md"
"$SESSION" advance "$codex_session" validating >/dev/null
fill "$codex_session/validation.md"
"$SESSION" advance "$codex_session" complete >/dev/null
"$SESSION" check "$codex_session" >/dev/null

touch "$codex_session/unexpected.txt"
if "$SESSION" check "$codex_session" >"$TEMP_DIR/extra.out" 2>&1; then
    fail 'accepted an unexpected top-level file'
fi
grep -F 'unexpected top-level protocol entries' "$TEMP_DIR/extra.out" >/dev/null ||
    fail 'missing unexpected-file refusal'
unlink "$codex_session/unexpected.txt"

mv "$codex_session/validation.md" "$TEMP_DIR/validation.md"
ln -s "$TEMP_DIR/validation.md" "$codex_session/validation.md"
if "$SESSION" check "$codex_session" >"$TEMP_DIR/file-link.out" 2>&1; then
    fail 'accepted a symlinked protocol file'
fi
grep -F 'must be real and not a symlink' "$TEMP_DIR/file-link.out" >/dev/null ||
    fail 'missing protocol-file identity refusal'
unlink "$codex_session/validation.md"
mv "$TEMP_DIR/validation.md" "$codex_session/validation.md"

mv "$codex_session/state.json" "$TEMP_DIR/state.json"
ln -s "$TEMP_DIR/state.json" "$codex_session/state.json"
if "$SESSION" check "$codex_session" >"$TEMP_DIR/state-link.out" 2>&1; then
    fail 'accepted a symlinked state file'
fi
grep -F 'must be real and not a symlink' "$TEMP_DIR/state-link.out" >/dev/null ||
    fail 'missing state-file identity refusal'
unlink "$codex_session/state.json"
mv "$TEMP_DIR/state.json" "$codex_session/state.json"

mv "$codex_session/artifacts" "$TEMP_DIR/artifacts"
ln -s "$TEMP_DIR/artifacts" "$codex_session/artifacts"
if "$SESSION" check "$codex_session" >"$TEMP_DIR/artifacts-link.out" 2>&1; then
    fail 'accepted a symlinked artifacts directory'
fi
grep -F 'must be real and not a symlink' "$TEMP_DIR/artifacts-link.out" >/dev/null ||
    fail 'missing artifacts identity refusal'
unlink "$codex_session/artifacts"
mv "$TEMP_DIR/artifacts" "$codex_session/artifacts"

ln -s "$codex_session" "$TEMP_DIR/session-link"
if "$SESSION" check "$TEMP_DIR/session-link" >"$TEMP_DIR/root-link.out" 2>&1; then
    fail 'accepted a symlinked session root'
fi
grep -F 'must be real and not a symlink' "$TEMP_DIR/root-link.out" >/dev/null ||
    fail 'missing session-root identity refusal'
unlink "$TEMP_DIR/session-link"
"$SESSION" check "$codex_session" >/dev/null

claude_session=$TEMP_DIR/claude-driver
"$SESSION" init "$claude_session" --driver claude >/dev/null
python3 - "$claude_session/state.json" <<'PY'
import json
import pathlib
import sys

state = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert state["driver"] == "claude"
assert state["copilot"] == "codex"
assert state["phase"] == "planning"
PY

if "$SESSION" advance "$claude_session" complete >"$TEMP_DIR/backward.out" 2>&1; then
    fail 'accepted a multi-phase transition'
fi
grep -F 'invalid transition' "$TEMP_DIR/backward.out" >/dev/null ||
    fail 'missing transition refusal'

if command -v codex >/dev/null 2>&1; then
    codex --ask-for-approval never exec --ephemeral \
        --sandbox workspace-write --skip-git-repo-check --cd "$TEMP_DIR" \
        --add-dir "$TEMP_DIR" --output-last-message "$TEMP_DIR/last.md" \
        --help >"$TEMP_DIR/codex-help.out" 2>&1
    if codex exec --ask-for-approval never --help \
        >"$TEMP_DIR/codex-old-order.out" 2>&1; then
        fail 'Codex unexpectedly accepted the old option order'
    fi
fi

if command -v claude >/dev/null 2>&1; then
    claude --help >"$TEMP_DIR/claude-help.out" 2>&1
    for option in --print --permission-mode --allowedTools --add-dir; do
        grep -F -- "$option" "$TEMP_DIR/claude-help.out" >/dev/null ||
            fail "installed Claude lacks $option"
    done
    grep -F 'dontAsk' "$TEMP_DIR/claude-help.out" >/dev/null ||
        fail 'installed Claude lacks dontAsk permission mode'
fi

echo 'Codex-Claude cowork skill tests passed'
