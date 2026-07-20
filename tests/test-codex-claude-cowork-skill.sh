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
grep -F 'the content of `copilot-evidence.md`' "$SKILL" >/dev/null ||
    fail 'co-pilot content ownership'
grep -F 'prose-only review is insufficient' "$SKILL" >/dev/null || fail 'experiment gate'
grep -F 'Let only the driver mutate the target' "$SKILL" >/dev/null || fail 'execution role'
grep -F 'Do not grant either' "$SKILL" >/dev/null || fail 'role symmetry'
grep -F 'claude --print --permission-mode dontAsk' "$PROTOCOL" >/dev/null ||
    fail 'Codex-driver native Claude mapping'
grep -F 'codex --ask-for-approval never exec --ephemeral' "$PROTOCOL" >/dev/null ||
    fail 'Claude-driver native Codex mapping'
grep -F -- '`--dangerously-skip-permissions`' "$PROTOCOL" >/dev/null ||
    fail 'Claude bypass refusal'
grep -F 'digests SESSION_DIR' "$PROTOCOL" >/dev/null ||
    fail 'protocol missing digest-seal instruction'
grep -F 'outside' "$PROTOCOL" | grep -F 'SESSION_DIR' >/dev/null ||
    fail 'protocol missing external-manifest requirement'
grep -F 'link count' "$PROTOCOL" >/dev/null ||
    fail 'protocol missing hard-link description'
grep -F -- '--predecessor' "$PROTOCOL" >/dev/null ||
    fail 'protocol missing predecessor takeover mapping'
grep -F 'digests SESSION_DIR' "$SKILL" >/dev/null ||
    fail 'skill missing digest-seal guidance'
grep -F 'advisory tripwire' "$SKILL" >/dev/null ||
    fail 'skill missing read-only advisory note'
grep -F 'stage SESSION_DIR STAGE_DIR --mode independent' "$SKILL" >/dev/null ||
    fail 'skill missing independent staged exchange'
grep -F 'import-copilot' "$SKILL" >/dev/null ||
    fail 'skill missing staged import'
grep -F '> STAGE_DIR/candidate-copilot-evidence.md' "$PROTOCOL" >/dev/null ||
    fail 'Claude mapping does not return a staged candidate'
grep -F -- '--output-last-message STAGE_DIR/candidate-copilot-evidence.md' \
    "$PROTOCOL" >/dev/null || fail 'Codex mapping does not return a staged candidate'
grep -F 'not an OS filesystem sandbox' "$PROTOCOL" >/dev/null ||
    fail 'protocol missing Claude enforcement boundary'
grep -F -- '--exchange-mode direct' "$SKILL" >/dev/null ||
    fail 'skill missing explicit direct fallback declaration'
grep -F 'verify-receipts SESSION_DIR' "$SKILL" >/dev/null ||
    fail 'skill missing receipt verification step'
grep -F 'stage_sha256' "$PROTOCOL" >/dev/null ||
    fail 'protocol missing external stage-manifest seal'
grep -F 'not cross-file crash' "$SKILL" >/dev/null ||
    fail 'skill overstates receipt atomicity'
grep -F -- '--seal EXTERNAL_SEAL_FILE' "$SKILL" >/dev/null ||
    fail 'skill missing mandatory seal command'
grep -F -- '--seal EXTERNAL_SEAL_FILE' "$PROTOCOL" >/dev/null ||
    fail 'protocol missing mandatory seal command'
grep -F -- '--prompt DRIVER_PROMPT_FILE' "$SKILL" >/dev/null ||
    fail 'skill missing sealed prompt command'
grep -F -- '--prompt DRIVER_PROMPT_FILE' "$PROTOCOL" >/dev/null ||
    fail 'protocol missing sealed prompt command'
grep -F 'status SESSION_DIR --stage STAGE_DIR' "$SKILL" >/dev/null ||
    fail 'skill missing co-pilot status surface'
grep -F 'status SESSION_DIR --stage STAGE_DIR' "$PROTOCOL" >/dev/null ||
    fail 'protocol missing co-pilot status surface'
python3 - "$SESSION" <<'PY'
import pathlib, sys
source = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
load_seal = source.split("def load_seal(", 1)[1].split("\ndef ", 1)[0]
read_prompt = source.split("def read_owned_bounded_file(", 1)[1].split("\ndef ", 1)[0]
import_copilot = source.split("def import_copilot(", 1)[1].split("\ndef ", 1)[0]
wait_copilot = source.split("def wait_copilot(", 1)[1].split("\ndef ", 1)[0]
assert "os.O_NOFOLLOW" in load_seal, load_seal
assert "os.fstat(descriptor)" in load_seal, load_seal
assert "raw = handle.read()" in load_seal, load_seal
assert "return value, sha256_bytes(raw)" in load_seal, load_seal
assert "seal, seal_sha256 = load_seal" in import_copilot, import_copilot
assert "session_path(args.seal).read_bytes()" not in import_copilot, import_copilot
assert "os.O_NOFOLLOW" in read_prompt, read_prompt
assert "os.O_NONBLOCK" in read_prompt, read_prompt
assert "os.fstat(descriptor)" in read_prompt, read_prompt
assert "status_snapshot(args)" in wait_copilot, wait_copilot
assert "import_copilot" not in wait_copilot, wait_copilot
assert "write_" not in wait_copilot, wait_copilot
PY
PYTHONDONTWRITEBYTECODE=1 python3 - "$SESSION" <<'PY'
import contextlib
import importlib.machinery
import importlib.util
import io
import json
import sys
from types import SimpleNamespace

loader = importlib.machinery.SourceFileLoader("cowork_session_deadline_test", sys.argv[1])
spec = importlib.util.spec_from_loader(loader.name, loader)
module = importlib.util.module_from_spec(spec)
loader.exec_module(module)

def snapshot(satisfied, process):
    return {
        "stage": {"mechanical_import_preconditions": {"all_satisfied": satisfied}},
        "process": process,
    }

def run(clocks, snapshots):
    clock = iter(clocks)
    values = iter(snapshots)
    module.time.monotonic = lambda: next(clock)
    module.time.sleep = lambda _: (_ for _ in ()).throw(AssertionError("slept"))
    module.status_snapshot = lambda _: next(values)
    output = io.StringIO()
    try:
        with contextlib.redirect_stdout(output):
            module.wait_copilot(
                SimpleNamespace(timeout_seconds=1.0, poll_seconds=1.0, pid=None)
            )
    except SystemExit as exc:
        return exc.code, json.loads(output.getvalue())
    raise AssertionError("wait_copilot returned without SystemExit")

code, value = run([0.0, 1.1, 1.15], [snapshot(True, None)])
assert code == 4, value
assert value["wait_observation"]["outcome"] == "timeout", value
assert value["wait_observation"]["elapsed_seconds"] == 1.15, value

not_reachable = {"state": "not-reachable", "advisory": True, "pid": 42}
code, value = run(
    [0.0, 0.4, 1.2, 1.25],
    [snapshot(False, not_reachable), snapshot(True, not_reachable)],
)
assert code == 4, value
assert value["wait_observation"]["outcome"] == "timeout", value
assert value["wait_observation"]["process_loss_observed"] is True, value
assert value["wait_observation"]["elapsed_seconds"] == 1.25, value

code, value = run(
    [0.0, 0.4, 0.9, 0.95],
    [snapshot(False, not_reachable), snapshot(True, not_reachable)],
)
assert code == 0, value
assert value["wait_observation"]["outcome"] == "ready", value
assert value["wait_observation"]["elapsed_seconds"] == 0.95, value
PY
grep -F 'stage_manifest_sha256' "$PROTOCOL" >/dev/null ||
    fail 'protocol missing sealed manifest binding'
grep -F 'does not reopen' "$PROTOCOL" >/dev/null ||
    fail 'protocol overstates verify-receipts seal coverage'

fill() {
    file=$1
    sed 's/^TODO$/verified synthetic evidence/' "$file" >"$file.next"
    mv "$file.next" "$file"
}

codex_session=$TEMP_DIR/codex-driver
"$SESSION" init "$codex_session" --driver codex --exchange-mode direct >/dev/null
[ -d "$codex_session/artifacts" ] && [ ! -L "$codex_session/artifacts" ] ||
    fail 'real artifacts directory'
[ -f "$codex_session/artifacts/.gitkeep" ] &&
    [ ! -s "$codex_session/artifacts/.gitkeep" ] ||
    fail 'empty tracked artifacts placeholder'
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

# --- round 2: hard-link rejection, digest seal, and takeover provenance ---

hlink=$TEMP_DIR/r2-hardlink
"$SESSION" init "$hlink" --driver claude >/dev/null
echo synthetic-outside >"$TEMP_DIR/r2-outside.txt"
ln -f "$TEMP_DIR/r2-outside.txt" "$hlink/plan.md"
if "$SESSION" check "$hlink" >"$TEMP_DIR/hardlink.out" 2>&1; then
    fail 'accepted a hard-linked protocol file'
fi
grep -F 'must not be a hard link' "$TEMP_DIR/hardlink.out" >/dev/null ||
    fail 'missing hard-link refusal'

seal=$TEMP_DIR/r2-seal
"$SESSION" init "$seal" --driver claude >/dev/null
"$SESSION" digests "$seal" >"$TEMP_DIR/seal-a"
"$SESSION" digests "$seal" >"$TEMP_DIR/seal-b"
cmp -s "$TEMP_DIR/seal-a" "$TEMP_DIR/seal-b" || fail 'digests are not deterministic'
if grep -F 'copilot-evidence.md' "$TEMP_DIR/seal-a" >/dev/null; then
    fail 'protected manifest must exclude copilot-evidence.md'
fi
grep -F 'state.json' "$TEMP_DIR/seal-a" >/dev/null ||
    fail 'protected manifest must include state.json'

# a protected-file overwrite is caught by the out-of-session manifest even after
# the writer re-chmods a read-only file
chmod 0400 "$seal/reconciliation.md"
chmod 0600 "$seal/reconciliation.md"
printf 'TAMPERED\n' >"$seal/reconciliation.md"
"$SESSION" digests "$seal" >"$TEMP_DIR/seal-after"
if cmp -s "$TEMP_DIR/seal-a" "$TEMP_DIR/seal-after"; then
    fail 'external digest manifest did not detect a protected-file overwrite'
fi

# co-pilot-owned evidence is excluded from the protected set and stays writable
"$SESSION" digests "$seal" >"$TEMP_DIR/seal-c"
printf 'co-pilot wrote this\n' >"$seal/copilot-evidence.md"
"$SESSION" digests "$seal" >"$TEMP_DIR/seal-d"
cmp -s "$TEMP_DIR/seal-c" "$TEMP_DIR/seal-d" ||
    fail 'co-pilot evidence must not affect the protected manifest'

# cross-product takeover starts at planning with recorded predecessor provenance
pred=$TEMP_DIR/r2-pred
"$SESSION" init "$pred" --driver claude >/dev/null
fill "$pred/charter.md"
fill "$pred/plan.md"
"$SESSION" advance "$pred" discussing >/dev/null
succ=$TEMP_DIR/r2-succ
"$SESSION" init "$succ" --driver codex --predecessor "$pred" >/dev/null
python3 - "$succ/state.json" <<'PY'
import json
import pathlib
import sys

state = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert state["phase"] == "planning", state["phase"]
assert state["driver"] == "codex"
assert state["copilot"] == "claude"
predecessor = state["predecessor"]
assert predecessor["driver"] == "claude", predecessor
assert predecessor["phase"] == "discussing", predecessor
assert len(predecessor["state_sha256"]) == 64
PY

# same-role re-init on an existing path is refused
if "$SESSION" init "$succ" --driver codex >"$TEMP_DIR/reinit.out" 2>&1; then
    fail 'accepted re-init on an existing session path'
fi
grep -F 'already exists' "$TEMP_DIR/reinit.out" >/dev/null ||
    fail 'missing existing-path refusal'

# Staged rounds place every stage as a direct child of one co-pilot sandbox box
# and keep the mandatory external seals in a separate vault outside that box and
# outside every session, matching the schema-2 seal location contract.
BOX=$TEMP_DIR/copilot-box
mkdir -p "$BOX"
SEALS=$TEMP_DIR/seal-vault
mkdir -p "$SEALS"

# --- round 3: staged exchange and failure-atomic co-pilot import ---

r3_session=$TEMP_DIR/r3-session
"$SESSION" init "$r3_session" --driver codex >/dev/null
fill "$r3_session/charter.md"
fill "$r3_session/plan.md"
"$SESSION" advance "$r3_session" discussing >/dev/null

r3_independent=$BOX/r3-independent
r3_independent_2=$BOX/r3-independent-2
"$SESSION" stage "$r3_session" "$r3_independent" --mode independent \
    --seal "$SEALS/r3-ind.json" >/dev/null
"$SESSION" stage "$r3_session" "$r3_independent_2" --mode independent \
    --seal "$SEALS/r3-ind2.json" >/dev/null
cmp -s "$r3_independent/stage.json" "$r3_independent_2/stage.json" ||
    fail 'independent stage manifest is not deterministic'
[ ! -e "$r3_independent/driver-evidence.md" ] ||
    fail 'independent stage leaked driver evidence'
[ -d "$r3_independent/artifacts" ] && [ ! -L "$r3_independent/artifacts" ] ||
    fail 'stage artifacts directory identity'
python3 - "$r3_independent/stage.json" <<'PY'
import json
import pathlib
import stat
import sys

stage_path = pathlib.Path(sys.argv[1])
stage = json.loads(stage_path.read_text(encoding="utf-8"))
assert stage["mode"] == "independent"
assert stage["driver"] == "codex"
assert stage["copilot"] == "claude"
assert stage["phase"] == "discussing"
assert sorted(stage["inputs"]) == ["charter.md", "plan.md", "state.json"]
assert "path" not in stage
assert stat.S_IMODE(stage_path.parent.stat().st_mode) == 0o700
assert stat.S_IMODE((stage_path.parent / "artifacts").stat().st_mode) == 0o700
for path in stage_path.parent.iterdir():
    if path.is_file():
        assert stat.S_IMODE(path.stat().st_mode) == 0o600, (path, oct(path.stat().st_mode))
PY

fill "$r3_independent/candidate-copilot-evidence.md"
"$SESSION" digests "$r3_session" >"$TEMP_DIR/r3-before-import"
"$SESSION" import-copilot "$r3_session" "$r3_independent" \
    --seal "$SEALS/r3-ind.json" >/dev/null
"$SESSION" digests "$r3_session" >"$TEMP_DIR/r3-after-import"
sed '/  receipts\//d' "$TEMP_DIR/r3-after-import" >"$TEMP_DIR/r3-after-core"
cmp -s "$TEMP_DIR/r3-before-import" "$TEMP_DIR/r3-after-core" ||
    fail 'staged import changed a pre-existing protected entry'
grep -F '  receipts/independent.json' "$TEMP_DIR/r3-after-import" >/dev/null ||
    fail 'independent receipt missing from protected digests'
cmp -s "$r3_independent/candidate-copilot-evidence.md" \
    "$r3_session/copilot-evidence.md" || fail 'staged candidate import bytes'
python3 - "$r3_session/copilot-evidence.md" <<'PY'
import pathlib
import stat
import sys

mode = stat.S_IMODE(pathlib.Path(sys.argv[1]).stat().st_mode)
assert mode == 0o600, oct(mode)
PY

fill "$r3_session/driver-evidence.md"
r3_reciprocal=$BOX/r3-reciprocal
"$SESSION" stage "$r3_session" "$r3_reciprocal" --mode reciprocal \
    --seal "$SEALS/r3-recip.json" >/dev/null
[ -f "$r3_reciprocal/driver-evidence.md" ] || fail 'reciprocal stage driver evidence'
[ -f "$r3_reciprocal/copilot-evidence.md" ] || fail 'reciprocal stage co-pilot evidence'
cmp -s "$r3_session/copilot-evidence.md" \
    "$r3_reciprocal/candidate-copilot-evidence.md" ||
    fail 'reciprocal candidate did not preserve prior evidence'

r3_invalid_session=$TEMP_DIR/r3-invalid-session
"$SESSION" init "$r3_invalid_session" --driver codex >/dev/null
fill "$r3_invalid_session/charter.md"
fill "$r3_invalid_session/plan.md"
"$SESSION" advance "$r3_invalid_session" discussing >/dev/null

if "$SESSION" stage "$r3_invalid_session" \
    "$r3_invalid_session/artifacts/inside-stage" \
    --mode independent >"$TEMP_DIR/inside-stage.out" 2>&1; then
    fail 'accepted a stage inside the live session'
fi
grep -F 'outside the live session' "$TEMP_DIR/inside-stage.out" >/dev/null ||
    fail 'missing inside-session stage refusal'

expect_import_refusal() {
    stage_dir=$1
    label=$2
    sha256sum "$r3_invalid_session/copilot-evidence.md" >"$TEMP_DIR/$label.before"
    if "$SESSION" import-copilot "$r3_invalid_session" "$stage_dir" \
        --seal "$R3_BAD_SEAL" >"$TEMP_DIR/$label.out" 2>&1; then
        fail "accepted invalid staged import: $label"
    fi
    sha256sum "$r3_invalid_session/copilot-evidence.md" >"$TEMP_DIR/$label.after"
    cmp -s "$TEMP_DIR/$label.before" "$TEMP_DIR/$label.after" ||
        fail "failed import changed live evidence: $label"
    if find "$r3_invalid_session" -maxdepth 1 -name '.copilot-evidence.md.*.tmp' \
        -print -quit | grep . >/dev/null; then
        fail "failed import left a session temp file: $label"
    fi
}

r3_bad=$BOX/r3-bad
R3_BAD_SEAL=$SEALS/r3-bad.json
"$SESSION" stage "$r3_invalid_session" "$r3_bad" --mode independent \
    --seal "$R3_BAD_SEAL" >/dev/null
fill "$r3_bad/candidate-copilot-evidence.md"
cp "$r3_bad/candidate-copilot-evidence.md" "$TEMP_DIR/r3-valid-candidate"

touch "$r3_bad/unexpected.txt"
expect_import_refusal "$r3_bad" unexpected-stage
unlink "$r3_bad/unexpected.txt"

cp "$r3_bad/plan.md" "$TEMP_DIR/r3-stage-plan"
printf '\nstage tamper\n' >>"$r3_bad/plan.md"
expect_import_refusal "$r3_bad" staged-input-tamper
cp "$TEMP_DIR/r3-stage-plan" "$r3_bad/plan.md"

cp "$r3_invalid_session/plan.md" "$TEMP_DIR/r3-live-plan"
printf '\nlive drift\n' >>"$r3_invalid_session/plan.md"
expect_import_refusal "$r3_bad" stale-live-input
cp "$TEMP_DIR/r3-live-plan" "$r3_invalid_session/plan.md"

mv "$r3_bad/candidate-copilot-evidence.md" "$TEMP_DIR/r3-candidate-real"
ln -s "$TEMP_DIR/r3-candidate-real" "$r3_bad/candidate-copilot-evidence.md"
expect_import_refusal "$r3_bad" symlink-candidate
unlink "$r3_bad/candidate-copilot-evidence.md"
mv "$TEMP_DIR/r3-candidate-real" "$r3_bad/candidate-copilot-evidence.md"

cp "$r3_bad/candidate-copilot-evidence.md" "$TEMP_DIR/r3-hardlink-source"
ln -f "$TEMP_DIR/r3-hardlink-source" "$r3_bad/candidate-copilot-evidence.md"
expect_import_refusal "$r3_bad" hardlink-candidate
unlink "$r3_bad/candidate-copilot-evidence.md"
cp "$TEMP_DIR/r3-valid-candidate" "$r3_bad/candidate-copilot-evidence.md"

sed '/^## Critique$/d' "$TEMP_DIR/r3-valid-candidate" \
    >"$r3_bad/candidate-copilot-evidence.md"
expect_import_refusal "$r3_bad" missing-heading
printf '%s\n' '# Co-pilot evidence' '## Commands and results' 'verified' \
    '## Sandbox and baseline' 'verified' '## Critique' 'verified' \
    '## Proposed plan changes' 'verified' \
    >"$r3_bad/candidate-copilot-evidence.md"
expect_import_refusal "$r3_bad" out-of-order-heading
cp "$TEMP_DIR/r3-valid-candidate" "$r3_bad/candidate-copilot-evidence.md"
printf '\nTODO\n' >>"$r3_bad/candidate-copilot-evidence.md"
expect_import_refusal "$r3_bad" unresolved-todo

dd if=/dev/zero of="$r3_bad/candidate-copilot-evidence.md" \
    bs=65537 count=1 2>/dev/null
expect_import_refusal "$r3_bad" oversized-candidate
printf '\377\n' >"$r3_bad/candidate-copilot-evidence.md"
expect_import_refusal "$r3_bad" non-utf8-candidate

cp "$TEMP_DIR/r3-valid-candidate" "$r3_bad/candidate-copilot-evidence.md"
"$SESSION" import-copilot "$r3_invalid_session" "$r3_bad" \
    --seal "$R3_BAD_SEAL" >/dev/null
"$SESSION" check "$r3_invalid_session" >/dev/null

# --- round 4: path-free state projection and predecessor content validation ---

# a predecessor-backed session stages a fail-closed, path-free state projection
r4_pred=$TEMP_DIR/r4-pred
"$SESSION" init "$r4_pred" --driver codex >/dev/null
fill "$r4_pred/charter.md"
fill "$r4_pred/plan.md"
"$SESSION" advance "$r4_pred" discussing >/dev/null

r4_session=$TEMP_DIR/r4-session
"$SESSION" init "$r4_session" --driver claude --predecessor "$r4_pred" >/dev/null
fill "$r4_session/charter.md"
fill "$r4_session/plan.md"
"$SESSION" advance "$r4_session" discussing >/dev/null

r4_stage=$BOX/r4-stage
"$SESSION" stage "$r4_session" "$r4_stage" --mode independent \
    --seal "$SEALS/r4.json" >/dev/null
python3 - "$r4_pred" "$r4_session/state.json" "$r4_stage/state.json" <<'PY'
import json
import pathlib
import sys

pred_dir = sys.argv[1]
live = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
staged = json.loads(pathlib.Path(sys.argv[3]).read_text(encoding="utf-8"))
assert live["predecessor"]["path"] == pred_dir, live["predecessor"]
assert "predecessor" in staged, staged
assert set(staged["predecessor"]) == {"driver", "phase", "state_sha256"}, staged[
    "predecessor"
]
for key in ("schema_version", "driver", "copilot", "phase", "created_at", "updated_at"):
    assert staged[key] == live[key], key
PY
if grep -F "$r4_pred" "$r4_stage/state.json" >/dev/null; then
    fail 'staged state.json leaked the predecessor path'
fi
if grep -F "$r4_pred" "$r4_stage/stage.json" >/dev/null; then
    fail 'stage manifest leaked the predecessor path'
fi

# projected round trip imports and leaves every protected entry unchanged
fill "$r4_stage/candidate-copilot-evidence.md"
"$SESSION" digests "$r4_session" >"$TEMP_DIR/r4-before"
"$SESSION" import-copilot "$r4_session" "$r4_stage" \
    --seal "$SEALS/r4.json" >/dev/null
"$SESSION" digests "$r4_session" >"$TEMP_DIR/r4-after"
sed '/  receipts\//d' "$TEMP_DIR/r4-after" >"$TEMP_DIR/r4-after-core"
cmp -s "$TEMP_DIR/r4-before" "$TEMP_DIR/r4-after-core" ||
    fail 'projected import changed a pre-existing protected entry'

# an unknown top-level state field fails closed before any stage is created
r4_unknown=$TEMP_DIR/r4-unknown
"$SESSION" init "$r4_unknown" --driver codex >/dev/null
fill "$r4_unknown/charter.md"
fill "$r4_unknown/plan.md"
"$SESSION" advance "$r4_unknown" discussing >/dev/null
python3 - "$r4_unknown/state.json" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
state = json.loads(path.read_text(encoding="utf-8"))
state["audit_path"] = "/private/future/live/session"
path.write_text(json.dumps(state, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
if "$SESSION" stage "$r4_unknown" "$TEMP_DIR/r4-unknown-stage" \
    --mode independent >"$TEMP_DIR/r4-unknown.out" 2>&1; then
    fail 'accepted staging of state with an unknown field'
fi
grep -F 'unexpected or missing keys' "$TEMP_DIR/r4-unknown.out" >/dev/null ||
    fail 'missing fail-closed staging refusal'
[ ! -e "$TEMP_DIR/r4-unknown-stage" ] ||
    fail 'fail-closed staging left a partial stage directory'

# an unknown predecessor field also fails closed
r4_predkey_pred=$TEMP_DIR/r4-predkey-pred
r4_predkey=$TEMP_DIR/r4-predkey
"$SESSION" init "$r4_predkey_pred" --driver codex >/dev/null
"$SESSION" init "$r4_predkey" --driver claude --predecessor "$r4_predkey_pred" >/dev/null
fill "$r4_predkey/charter.md"
fill "$r4_predkey/plan.md"
"$SESSION" advance "$r4_predkey" discussing >/dev/null
python3 - "$r4_predkey/state.json" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
state = json.loads(path.read_text(encoding="utf-8"))
state["predecessor"]["extra"] = "x"
path.write_text(json.dumps(state, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
if "$SESSION" stage "$r4_predkey" "$TEMP_DIR/r4-predkey-stage" \
    --mode independent >"$TEMP_DIR/r4-predkey.out" 2>&1; then
    fail 'accepted staging with an unknown predecessor field'
fi
grep -F 'predecessor has unexpected or missing keys for staging' \
    "$TEMP_DIR/r4-predkey.out" >/dev/null || fail 'missing predecessor fail-closed refusal'

# a withheld-field-only live change is invisible to projected import but caught
# by the external full-state seal
r4_fresh_pred=$TEMP_DIR/r4-fresh-pred
r4_fresh=$TEMP_DIR/r4-fresh
"$SESSION" init "$r4_fresh_pred" --driver codex >/dev/null
"$SESSION" init "$r4_fresh" --driver claude --predecessor "$r4_fresh_pred" >/dev/null
fill "$r4_fresh/charter.md"
fill "$r4_fresh/plan.md"
"$SESSION" advance "$r4_fresh" discussing >/dev/null
r4_fresh_stage=$BOX/r4-fresh-stage
"$SESSION" stage "$r4_fresh" "$r4_fresh_stage" --mode independent \
    --seal "$SEALS/r4-fresh.json" >/dev/null
fill "$r4_fresh_stage/candidate-copilot-evidence.md"
"$SESSION" digests "$r4_fresh" >"$TEMP_DIR/r4-fresh-before"
python3 - "$r4_fresh/state.json" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
state = json.loads(path.read_text(encoding="utf-8"))
state["predecessor"]["path"] = "/private/withheld/relocated"
path.write_text(json.dumps(state, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
"$SESSION" digests "$r4_fresh" >"$TEMP_DIR/r4-fresh-after"
if cmp -s "$TEMP_DIR/r4-fresh-before" "$TEMP_DIR/r4-fresh-after"; then
    fail 'external seal did not detect a withheld-field change'
fi
"$SESSION" import-copilot "$r4_fresh" "$r4_fresh_stage" \
    --seal "$SEALS/r4-fresh.json" >/dev/null ||
    fail 'projected import rejected a withheld-field-only change'

# a retained-field live change is stale-rejected with the destination unchanged
r4_stale=$TEMP_DIR/r4-stale
"$SESSION" init "$r4_stale" --driver codex >/dev/null
fill "$r4_stale/charter.md"
fill "$r4_stale/plan.md"
"$SESSION" advance "$r4_stale" discussing >/dev/null
r4_stale_stage=$BOX/r4-stale-stage
"$SESSION" stage "$r4_stale" "$r4_stale_stage" --mode independent \
    --seal "$SEALS/r4-stale.json" >/dev/null
fill "$r4_stale_stage/candidate-copilot-evidence.md"
sha256sum "$r4_stale/copilot-evidence.md" >"$TEMP_DIR/r4-stale.before"
python3 - "$r4_stale/state.json" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
state = json.loads(path.read_text(encoding="utf-8"))
state["updated_at"] = "2000-01-01T00:00:00+00:00"
path.write_text(json.dumps(state, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
if "$SESSION" import-copilot "$r4_stale" "$r4_stale_stage" \
    --seal "$SEALS/r4-stale.json" >"$TEMP_DIR/r4-stale.out" 2>&1; then
    fail 'accepted a stale retained-field import'
fi
grep -F 'stale relative to the live session: state.json' "$TEMP_DIR/r4-stale.out" \
    >/dev/null || fail 'missing retained-field stale refusal'
sha256sum "$r4_stale/copilot-evidence.md" >"$TEMP_DIR/r4-stale.after"
cmp -s "$TEMP_DIR/r4-stale.before" "$TEMP_DIR/r4-stale.after" ||
    fail 'stale import changed live evidence'

# init --predecessor validates the predecessor's phase-required content
r4_incons=$TEMP_DIR/r4-incons-pred
"$SESSION" init "$r4_incons" --driver codex --exchange-mode direct >/dev/null
python3 - "$r4_incons/state.json" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
state = json.loads(path.read_text(encoding="utf-8"))
state["phase"] = "complete"
path.write_text(json.dumps(state, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
if "$SESSION" init "$TEMP_DIR/r4-incons-succ" --driver claude \
    --predecessor "$r4_incons" >"$TEMP_DIR/r4-incons.out" 2>&1; then
    fail 'accepted a phase/content-inconsistent predecessor'
fi
grep -F 'unresolved TODO marker' "$TEMP_DIR/r4-incons.out" >/dev/null ||
    fail 'missing predecessor content refusal'
[ ! -e "$TEMP_DIR/r4-incons-succ" ] ||
    fail 'inconsistent predecessor left a partial successor'

# a genuinely completed predecessor is still accepted
r4_valid=$TEMP_DIR/r4-valid-pred
"$SESSION" init "$r4_valid" --driver codex --exchange-mode direct >/dev/null
for name in charter plan driver-evidence copilot-evidence reconciliation \
    execution validation; do
    fill "$r4_valid/$name.md"
done
for phase in discussing ready-for-execution executing validating complete; do
    "$SESSION" advance "$r4_valid" "$phase" >/dev/null
done
"$SESSION" init "$TEMP_DIR/r4-valid-succ" --driver claude \
    --predecessor "$r4_valid" >/dev/null
python3 - "$TEMP_DIR/r4-valid-succ/state.json" <<'PY'
import json
import pathlib
import sys

state = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert state["phase"] == "planning", state["phase"]
assert state["predecessor"]["phase"] == "complete", state["predecessor"]
PY

# --- round 5: schema-compatible import receipts and crash-safe retry guards ---

# strict schema-1 sessions remain valid and forbid the schema-2 receipts layout
r5_legacy=$TEMP_DIR/r5-legacy
"$SESSION" init "$r5_legacy" --driver codex --exchange-mode direct >/dev/null
python3 - "$r5_legacy/state.json" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
state = json.loads(path.read_text(encoding="utf-8"))
state["schema_version"] = 1
state.pop("exchange_mode")
path.write_text(json.dumps(state, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
rmdir "$r5_legacy/receipts"
"$SESSION" check "$r5_legacy" >/dev/null
mkdir "$r5_legacy/receipts"
if "$SESSION" check "$r5_legacy" >"$TEMP_DIR/r5-legacy-layout.out" 2>&1; then
    fail 'schema-1 session accepted receipts directory'
fi
grep -F 'schema-1 session must not contain receipts' \
    "$TEMP_DIR/r5-legacy-layout.out" >/dev/null || fail 'missing legacy layout refusal'
rmdir "$r5_legacy/receipts"
for name in charter plan driver-evidence copilot-evidence reconciliation \
    execution validation; do
    fill "$r5_legacy/$name.md"
done
for phase in discussing ready-for-execution executing validating complete; do
    "$SESSION" advance "$r5_legacy" "$phase" >/dev/null
done
"$SESSION" init "$TEMP_DIR/r5-v2-after-v1" --driver claude \
    --predecessor "$r5_legacy" >/dev/null
python3 - "$TEMP_DIR/r5-v2-after-v1/state.json" <<'PY'
import json
import pathlib
import sys

state = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert state["schema_version"] == 2, state
assert state["exchange_mode"] == "staged", state
assert state["predecessor"]["phase"] == "complete", state
PY

# an explicit direct fallback is receipt-free and cannot use staged commands
r5_direct=$TEMP_DIR/r5-direct
"$SESSION" init "$r5_direct" --driver claude --exchange-mode direct >/dev/null
fill "$r5_direct/charter.md"
fill "$r5_direct/plan.md"
"$SESSION" advance "$r5_direct" discussing >/dev/null
if "$SESSION" stage "$r5_direct" "$TEMP_DIR/r5-direct-stage" \
    --mode independent >"$TEMP_DIR/r5-direct-stage.out" 2>&1; then
    fail 'direct exchange accepted staged command'
fi
grep -F 'staged exchange-mode session' "$TEMP_DIR/r5-direct-stage.out" >/dev/null ||
    fail 'missing direct-mode staging refusal'

# default schema-2 staged flow creates an ordered, protected receipt chain
r5_session=$TEMP_DIR/r5-session
"$SESSION" init "$r5_session" --driver codex >/dev/null
[ -d "$r5_session/receipts" ] && [ ! -L "$r5_session/receipts" ] ||
    fail 'schema-2 receipts directory identity'
fill "$r5_session/charter.md"
fill "$r5_session/plan.md"
"$SESSION" advance "$r5_session" discussing >/dev/null
fill "$r5_session/driver-evidence.md"
fill "$r5_session/copilot-evidence.md"
fill "$r5_session/reconciliation.md"
if "$SESSION" advance "$r5_session" ready-for-execution \
    >"$TEMP_DIR/r5-no-receipts.out" 2>&1; then
    fail 'staged ready phase accepted no receipts'
fi
grep -F 'requires independent and reciprocal receipts' \
    "$TEMP_DIR/r5-no-receipts.out" >/dev/null || fail 'missing ready receipt gate'

r5_ind=$BOX/r5-independent
"$SESSION" stage "$r5_session" "$r5_ind" --mode independent \
    --seal "$SEALS/r5-ind.json" >"$TEMP_DIR/r5-stage.out"
grep -E 'stage_sha256=[0-9a-f]{64} seal_sha256=[0-9a-f]{64}$' \
    "$TEMP_DIR/r5-stage.out" >/dev/null ||
    fail 'stage command omitted external manifest or seal hash'
python3 - "$r5_session/copilot-evidence.md" "$r5_ind/stage.json" <<'PY'
import hashlib
import json
import pathlib
import sys

live = pathlib.Path(sys.argv[1]).read_bytes()
stage = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
assert stage["schema_version"] == 3, stage
assert stage["prompt_sha256"] is None, stage
assert stage["destination_before_sha256"] == hashlib.sha256(live).hexdigest(), stage
PY
fill "$r5_ind/candidate-copilot-evidence.md"
"$SESSION" import-copilot "$r5_session" "$r5_ind" \
    --seal "$SEALS/r5-ind.json" >"$TEMP_DIR/r5-import-ind.out"
grep -F 'receipt=receipts/independent.json' "$TEMP_DIR/r5-import-ind.out" >/dev/null ||
    fail 'independent import omitted receipt path'
"$SESSION" verify-receipts "$r5_session" >/dev/null
"$SESSION" digests "$r5_session" >"$TEMP_DIR/r5-digests-one"
grep -F '  receipts/independent.json' "$TEMP_DIR/r5-digests-one" >/dev/null ||
    fail 'digests omitted independent receipt'
if grep -E '/home|/tmp|/Users|/root' "$r5_session/receipts/independent.json" \
    >/dev/null; then
    fail 'receipt leaked an absolute path'
fi
printf '\npost-import stage drift\n' >>"$r5_ind/candidate-copilot-evidence.md"
"$SESSION" verify-receipts "$r5_session" >/dev/null ||
    fail 'stage candidate drift invalidated live receipt'
if "$SESSION" import-copilot "$r5_session" "$r5_ind" \
    --seal "$SEALS/r5-ind.json" >"$TEMP_DIR/r5-replay.out" 2>&1; then
    fail 'replayed an already-receipted independent import'
fi
grep -F 'replay refused' "$TEMP_DIR/r5-replay.out" >/dev/null ||
    fail 'missing receipt replay refusal'

r5_recip=$BOX/r5-reciprocal
"$SESSION" stage "$r5_session" "$r5_recip" --mode reciprocal \
    --seal "$SEALS/r5-recip.json" >/dev/null
printf '\nreciprocal revision\n' >>"$r5_recip/candidate-copilot-evidence.md"
"$SESSION" import-copilot "$r5_session" "$r5_recip" \
    --seal "$SEALS/r5-recip.json" >/dev/null
"$SESSION" verify-receipts "$r5_session" \
    | grep -F 'valid reciprocal receipt' >/dev/null || fail 'reciprocal verification'
python3 - "$r5_session/receipts/independent.json" \
    "$r5_session/receipts/reciprocal.json" <<'PY'
import json
import pathlib
import sys

ind = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
rec = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
assert rec["destination_before_sha256"] == ind["candidate_sha256"], (ind, rec)
assert ind["schema_version"] == 2 and rec["schema_version"] == 2, (ind, rec)
assert set(rec) == {
    "schema_version", "mode", "driver", "copilot", "phase", "inputs",
    "raw_state_sha256", "stage_manifest_sha256", "candidate_sha256",
    "destination_before_sha256", "seal_sha256", "imported_at",
}, rec
import re as _re
assert _re.fullmatch(r"[0-9a-f]{64}", rec["seal_sha256"]), rec
PY
"$SESSION" advance "$r5_session" ready-for-execution >/dev/null

# semantically harmless receipt-byte drift is visible to the external manifest
"$SESSION" digests "$r5_session" >"$TEMP_DIR/r5-receipt-before"
cp "$r5_session/receipts/reciprocal.json" "$TEMP_DIR/r5-recip-receipt"
printf ' ' >>"$r5_session/receipts/reciprocal.json"
"$SESSION" check "$r5_session" >/dev/null
"$SESSION" digests "$r5_session" >"$TEMP_DIR/r5-receipt-after"
if cmp -s "$TEMP_DIR/r5-receipt-before" "$TEMP_DIR/r5-receipt-after"; then
    fail 'receipt-byte drift escaped external digests'
fi
cp "$TEMP_DIR/r5-recip-receipt" "$r5_session/receipts/reciprocal.json"

# destination drift is refused before first import and leaves no receipt
r5_drift=$TEMP_DIR/r5-drift
"$SESSION" init "$r5_drift" --driver claude >/dev/null
fill "$r5_drift/charter.md"
fill "$r5_drift/plan.md"
"$SESSION" advance "$r5_drift" discussing >/dev/null
r5_drift_stage=$BOX/r5-drift-stage
"$SESSION" stage "$r5_drift" "$r5_drift_stage" --mode independent \
    --seal "$SEALS/r5-drift.json" >/dev/null
fill "$r5_drift_stage/candidate-copilot-evidence.md"
fill "$r5_drift/copilot-evidence.md"
if "$SESSION" import-copilot "$r5_drift" "$r5_drift_stage" \
    --seal "$SEALS/r5-drift.json" >"$TEMP_DIR/r5-drift.out" 2>&1; then
    fail 'accepted drifted pre-import destination'
fi
grep -F 'destination-before hash' "$TEMP_DIR/r5-drift.out" >/dev/null ||
    fail 'missing destination-before refusal'
[ ! -e "$r5_drift/receipts/independent.json" ] ||
    fail 'destination drift created a receipt'

# ordinary receipt-write failure rolls back evidence and leaves no temp/final
r5_fail=$TEMP_DIR/r5-fail
"$SESSION" init "$r5_fail" --driver codex >/dev/null
fill "$r5_fail/charter.md"
fill "$r5_fail/plan.md"
"$SESSION" advance "$r5_fail" discussing >/dev/null
r5_fail_stage=$BOX/r5-fail-stage
"$SESSION" stage "$r5_fail" "$r5_fail_stage" --mode independent \
    --seal "$SEALS/r5-fail.json" >/dev/null
fill "$r5_fail_stage/candidate-copilot-evidence.md"
sha256sum "$r5_fail/copilot-evidence.md" >"$TEMP_DIR/r5-fail-before"
chmod 0500 "$r5_fail/receipts"
if "$SESSION" import-copilot "$r5_fail" "$r5_fail_stage" \
    --seal "$SEALS/r5-fail.json" >"$TEMP_DIR/r5-fail.out" 2>&1; then
    fail 'receipt write unexpectedly succeeded in unwritable directory'
fi
chmod 0700 "$r5_fail/receipts"
sha256sum "$r5_fail/copilot-evidence.md" >"$TEMP_DIR/r5-fail-after"
cmp -s "$TEMP_DIR/r5-fail-before" "$TEMP_DIR/r5-fail-after" ||
    fail 'receipt failure did not restore live evidence'
[ ! -e "$r5_fail/receipts/independent.json" ] ||
    fail 'receipt failure left final receipt'
if find "$r5_fail" -maxdepth 1 -name '.receipt-*.tmp' -print -quit \
    | grep . >/dev/null; then
    fail 'receipt failure left temporary residue'
fi
"$SESSION" import-copilot "$r5_fail" "$r5_fail_stage" \
    --seal "$SEALS/r5-fail.json" >/dev/null

# receipt aliases and crash-shaped root residue are detected, not auto-repaired
cp "$r5_fail/receipts/independent.json" "$TEMP_DIR/r5-receipt-hardlink"
ln -f "$TEMP_DIR/r5-receipt-hardlink" "$r5_fail/receipts/independent.json"
if "$SESSION" check "$r5_fail" >"$TEMP_DIR/r5-receipt-link.out" 2>&1; then
    fail 'accepted hard-linked receipt'
fi
grep -F 'must not be a hard link' "$TEMP_DIR/r5-receipt-link.out" >/dev/null ||
    fail 'missing receipt hard-link refusal'
unlink "$r5_fail/receipts/independent.json"
cp "$TEMP_DIR/r5-receipt-hardlink" "$r5_fail/receipts/independent.json"
touch "$r5_fail/.receipt-independent.crash.tmp"
if "$SESSION" check "$r5_fail" >"$TEMP_DIR/r5-residue.out" 2>&1; then
    fail 'accepted crash-shaped receipt temporary residue'
fi
grep -F 'unexpected top-level protocol entries' "$TEMP_DIR/r5-residue.out" >/dev/null ||
    fail 'missing crash-residue layout refusal'
unlink "$r5_fail/.receipt-independent.crash.tmp"

# --- round 6: mandatory external seal binding the co-pilot-writable stage.json ---

r6_new_session() {
    _dir=$1
    "$SESSION" init "$_dir" --driver claude >/dev/null
    fill "$_dir/charter.md"
    fill "$_dir/plan.md"
    "$SESSION" advance "$_dir" discussing >/dev/null
}

# schema-2 staged staging requires --seal
r6_a=$TEMP_DIR/r6-a
r6_new_session "$r6_a"
if "$SESSION" stage "$r6_a" "$BOX/r6-a" --mode independent \
    >"$TEMP_DIR/r6-a.out" 2>&1; then
    fail 'schema-2 staging accepted a missing seal'
fi
grep -F 'requires --seal' "$TEMP_DIR/r6-a.out" >/dev/null ||
    fail 'missing seal-required stage refusal'
[ ! -e "$BOX/r6-a" ] || fail 'seal-less stage minted a partial stage'

# a seal resolved inside the live session or the stage-parent tree is refused,
# before any stage bytes are created
if "$SESSION" stage "$r6_a" "$BOX/r6-a" --mode independent \
    --seal "$r6_a/inside.json" >"$TEMP_DIR/r6-a-sess.out" 2>&1; then
    fail 'accepted a seal inside the live session'
fi
grep -F 'outside the live session and stage-parent sandbox' \
    "$TEMP_DIR/r6-a-sess.out" >/dev/null || fail 'missing in-session seal refusal'
if "$SESSION" stage "$r6_a" "$BOX/r6-a" --mode independent \
    --seal "$BOX/r6-a-cotree.json" >"$TEMP_DIR/r6-a-box.out" 2>&1; then
    fail 'accepted a seal inside the co-pilot sandbox tree'
fi
grep -F 'outside the live session and stage-parent sandbox' \
    "$TEMP_DIR/r6-a-box.out" >/dev/null || fail 'missing co-pilot-tree seal refusal'
[ ! -e "$BOX/r6-a" ] || fail 'refused seal minted a partial stage'

# an already-present seal path is refused before minting the stage
: >"$SEALS/r6-a-taken.json"
if "$SESSION" stage "$r6_a" "$BOX/r6-a" --mode independent \
    --seal "$SEALS/r6-a-taken.json" >"$TEMP_DIR/r6-a-taken.out" 2>&1; then
    fail 'accepted an already-present seal path'
fi
grep -F 'seal path already exists' "$TEMP_DIR/r6-a-taken.out" >/dev/null ||
    fail 'missing pre-existing seal refusal'
[ ! -e "$BOX/r6-a" ] || fail 'pre-existing seal minted a partial stage'

# the laundering route the seal closes: a co-pilot rewrite of stage.json after a
# crash-shaped evidence overwrite is refused before any mutation and mints no receipt
r6_l=$TEMP_DIR/r6-laundering
r6_new_session "$r6_l"
"$SESSION" stage "$r6_l" "$BOX/r6-l" --mode independent \
    --seal "$SEALS/r6-l.json" >/dev/null
fill "$BOX/r6-l/candidate-copilot-evidence.md"
cp "$BOX/r6-l/candidate-copilot-evidence.md" "$r6_l/copilot-evidence.md"
python3 - "$BOX/r6-l/stage.json" "$r6_l/copilot-evidence.md" <<'PY'
import hashlib, json, pathlib, sys
stage_path = pathlib.Path(sys.argv[1])
stage = json.loads(stage_path.read_text(encoding="utf-8"))
stage["destination_before_sha256"] = hashlib.sha256(
    pathlib.Path(sys.argv[2]).read_bytes()
).hexdigest()
stage_path.write_text(json.dumps(stage, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
if "$SESSION" import-copilot "$r6_l" "$BOX/r6-l" --seal "$SEALS/r6-l.json" \
    >"$TEMP_DIR/r6-l.out" 2>&1; then
    fail 'sealed import accepted a laundered stage.json'
fi
grep -F 'seal destination-before does not match the stage' "$TEMP_DIR/r6-l.out" \
    >/dev/null || fail 'missing laundering refusal'
[ ! -e "$r6_l/receipts/independent.json" ] || fail 'laundered import minted a receipt'

# a stage.json tamper that preserves destination-before is caught by the manifest anchor
r6_m=$TEMP_DIR/r6-manifest
r6_new_session "$r6_m"
"$SESSION" stage "$r6_m" "$BOX/r6-m" --mode independent \
    --seal "$SEALS/r6-m.json" >/dev/null
fill "$BOX/r6-m/candidate-copilot-evidence.md"
python3 - "$BOX/r6-m/stage.json" <<'PY'
import json, pathlib, sys
p = pathlib.Path(sys.argv[1])
stage = json.loads(p.read_text(encoding="utf-8"))
key = sorted(stage["inputs"])[0]
stage["inputs"][key] = "1" * 64
p.write_text(json.dumps(stage, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
if "$SESSION" import-copilot "$r6_m" "$BOX/r6-m" --seal "$SEALS/r6-m.json" \
    >"$TEMP_DIR/r6-m.out" 2>&1; then
    fail 'sealed import accepted a tampered manifest'
fi
grep -F 'stage.json does not match the sealed manifest hash' "$TEMP_DIR/r6-m.out" \
    >/dev/null || fail 'missing manifest-anchor refusal'
[ ! -e "$r6_m/receipts/independent.json" ] || fail 'manifest tamper minted a receipt'

# structural seal edge cases: each refuses before mutation and mints no receipt
r6_e=$TEMP_DIR/r6-edge
r6_new_session "$r6_e"
"$SESSION" stage "$r6_e" "$BOX/r6-e" --mode independent \
    --seal "$SEALS/r6-e.json" >/dev/null
fill "$BOX/r6-e/candidate-copilot-evidence.md"
# a second, different-content stage yields a non-matching wrong-stage seal
r6_e2=$TEMP_DIR/r6-edge2
r6_new_session "$r6_e2"
printf '\nmakes this session distinct\n' >>"$r6_e2/charter.md"
"$SESSION" stage "$r6_e2" "$BOX/r6-e2" --mode independent \
    --seal "$SEALS/r6-e2.json" >/dev/null

r6_seal_refused() {
    _label=$1
    shift
    sha256sum "$r6_e/copilot-evidence.md" >"$TEMP_DIR/$_label.before"
    if "$SESSION" import-copilot "$r6_e" "$BOX/r6-e" "$@" \
        >"$TEMP_DIR/$_label.out" 2>&1; then
        fail "sealed import accepted $_label"
    fi
    sha256sum "$r6_e/copilot-evidence.md" >"$TEMP_DIR/$_label.after"
    cmp -s "$TEMP_DIR/$_label.before" "$TEMP_DIR/$_label.after" ||
        fail "$_label mutated live evidence"
    [ ! -e "$r6_e/receipts/independent.json" ] || fail "$_label minted a receipt"
}

r6_seal_refused missing-seal
cp "$SEALS/r6-e.json" "$SEALS/r6-e-altered.json"
python3 - "$SEALS/r6-e-altered.json" <<'PY'
import json, pathlib, sys
p = pathlib.Path(sys.argv[1])
seal = json.loads(p.read_text(encoding="utf-8"))
seal["stage_manifest_sha256"] = "0" * 64
p.write_text(json.dumps(seal, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
r6_seal_refused altered-seal --seal "$SEALS/r6-e-altered.json"
cp "$SEALS/r6-e.json" "$SEALS/r6-e-extra.json"
python3 - "$SEALS/r6-e-extra.json" <<'PY'
import json, pathlib, sys
p = pathlib.Path(sys.argv[1])
seal = json.loads(p.read_text(encoding="utf-8"))
seal["extra"] = "x"
p.write_text(json.dumps(seal, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
r6_seal_refused extra-key-seal --seal "$SEALS/r6-e-extra.json"
printf '\377\376bad' >"$SEALS/r6-e-nonutf8.json"
r6_seal_refused non-utf8-seal --seal "$SEALS/r6-e-nonutf8.json"
ln -s "$SEALS/r6-e.json" "$SEALS/r6-e-symlink.json"
r6_seal_refused symlink-seal --seal "$SEALS/r6-e-symlink.json"
cp "$SEALS/r6-e.json" "$SEALS/r6-e-hardlink.json"
ln -f "$SEALS/r6-e-hardlink.json" "$SEALS/r6-e-hardlink-alias.json"
r6_seal_refused hardlink-seal --seal "$SEALS/r6-e-hardlink.json"
unlink "$SEALS/r6-e-hardlink-alias.json"
cp "$SEALS/r6-e.json" "$BOX/r6-e-cotree-seal.json"
r6_seal_refused cotree-seal --seal "$BOX/r6-e-cotree-seal.json"
r6_seal_refused wrong-stage-seal --seal "$SEALS/r6-e2.json"

# the valid seal imports, binds seal_sha256 into a schema-2 receipt, and replays refuse
"$SESSION" import-copilot "$r6_e" "$BOX/r6-e" --seal "$SEALS/r6-e.json" >/dev/null
"$SESSION" verify-receipts "$r6_e" >/dev/null
python3 - "$SEALS/r6-e.json" "$r6_e/receipts/independent.json" <<'PY'
import hashlib, json, pathlib, sys
seal_bytes = pathlib.Path(sys.argv[1]).read_bytes()
receipt = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
assert receipt["schema_version"] == 2, receipt
assert receipt["seal_sha256"] == hashlib.sha256(seal_bytes).hexdigest(), receipt
PY
if "$SESSION" import-copilot "$r6_e" "$BOX/r6-e" --seal "$SEALS/r6-e.json" \
    >"$TEMP_DIR/r6-e-replay.out" 2>&1; then
    fail 'replayed a sealed independent import'
fi
grep -F 'replay refused' "$TEMP_DIR/r6-e-replay.out" >/dev/null ||
    fail 'missing sealed replay refusal'

# a schema-2 session holding a pre-seal schema-1 receipt stays readable
python3 - "$r6_e/receipts/independent.json" <<'PY'
import json, pathlib, sys
p = pathlib.Path(sys.argv[1])
receipt = json.loads(p.read_text(encoding="utf-8"))
receipt.pop("seal_sha256")
receipt["schema_version"] = 1
p.write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
"$SESSION" check "$r6_e" >/dev/null || fail 'schema-2 session rejected a schema-1 receipt'
"$SESSION" verify-receipts "$r6_e" >/dev/null ||
    fail 'schema-1 receipt failed verification in a schema-2 session'

# --- round 9: sealed prompt input and read-only stage-aware status ---
r9_session=$TEMP_DIR/r9-session
r9_stage=$BOX/r9-stage
r9_prompt=$TEMP_DIR/r9-prompt.md
r9_seal=$SEALS/r9.json
"$SESSION" init "$r9_session" --driver codex >/dev/null
fill "$r9_session/charter.md"
fill "$r9_session/plan.md"
"$SESSION" advance "$r9_session" discussing >/dev/null
printf '%s\n' 'bounded co-pilot prompt' >"$r9_prompt"
"$SESSION" stage "$r9_session" "$r9_stage" --mode independent \
    --prompt "$r9_prompt" --seal "$r9_seal" >/dev/null
cmp -s "$r9_prompt" "$r9_stage/artifacts/copilot-prompt.md" ||
    fail 'staged prompt bytes changed'
python3 - "$r9_prompt" "$r9_stage/stage.json" "$r9_seal" <<'PY'
import hashlib, json, pathlib, sys
prompt = pathlib.Path(sys.argv[1]).read_bytes()
stage_path = pathlib.Path(sys.argv[2])
stage = json.loads(stage_path.read_text(encoding="utf-8"))
seal = json.loads(pathlib.Path(sys.argv[3]).read_text(encoding="utf-8"))
assert stage["schema_version"] == 3, stage
assert stage["prompt_sha256"] == hashlib.sha256(prompt).hexdigest(), stage
assert seal["stage_manifest_sha256"] == hashlib.sha256(stage_path.read_bytes()).hexdigest(), seal
PY
"$SESSION" digests "$r9_session" >"$TEMP_DIR/r9-status-session-before"
sha256sum "$r9_stage/stage.json" "$r9_stage/artifacts/copilot-prompt.md" \
    "$r9_seal" >"$TEMP_DIR/r9-status-stage-before"
"$SESSION" status "$r9_session" --stage "$r9_stage" --seal "$r9_seal" \
    --pid $$ >"$TEMP_DIR/r9-status.json"
"$SESSION" digests "$r9_session" >"$TEMP_DIR/r9-status-session-after"
sha256sum "$r9_stage/stage.json" "$r9_stage/artifacts/copilot-prompt.md" \
    "$r9_seal" >"$TEMP_DIR/r9-status-stage-after"
cmp -s "$TEMP_DIR/r9-status-session-before" "$TEMP_DIR/r9-status-session-after" ||
    fail 'status mutated the session'
cmp -s "$TEMP_DIR/r9-status-stage-before" "$TEMP_DIR/r9-status-stage-after" ||
    fail 'status mutated the stage or seal'
python3 - "$TEMP_DIR/r9-status.json" <<'PY'
import json, pathlib, sys
value = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert value["phase"] == "discussing", value
assert value["receipt_modes"] == [], value
assert value["stage"]["schema_version"] == 3, value
assert value["stage"]["candidate_state"] == "unchanged", value
assert value["stage"]["inputs_fresh"] is True, value
assert value["stage"]["destination_fresh"] is True, value
assert value["process"]["state"] == "reachable", value
assert value["process"]["advisory"] is True, value
assert "independent" in value["next_action"], value
PY

# A structurally-ready candidate against a stale live input is advisory only
# (mechanical_import_preconditions), not an authoritative import gate.
fill "$r9_stage/candidate-copilot-evidence.md"
"$SESSION" digests "$r9_session" >"$TEMP_DIR/r9-wait-session-before"
sha256sum "$r9_stage/stage.json" "$r9_stage/candidate-copilot-evidence.md" \
    "$r9_seal" >"$TEMP_DIR/r9-wait-stage-before"
"$SESSION" wait-copilot "$r9_session" --stage "$r9_stage" --seal "$r9_seal" \
    --timeout-seconds 2 --poll-seconds 1 >"$TEMP_DIR/r9-wait-ready.json"
"$SESSION" digests "$r9_session" >"$TEMP_DIR/r9-wait-session-after"
sha256sum "$r9_stage/stage.json" "$r9_stage/candidate-copilot-evidence.md" \
    "$r9_seal" >"$TEMP_DIR/r9-wait-stage-after"
cmp -s "$TEMP_DIR/r9-wait-session-before" "$TEMP_DIR/r9-wait-session-after" ||
    fail 'ready waiter mutated the session'
cmp -s "$TEMP_DIR/r9-wait-stage-before" "$TEMP_DIR/r9-wait-stage-after" ||
    fail 'ready waiter mutated the stage or seal'
python3 - "$TEMP_DIR/r9-wait-ready.json" <<'PY'
import json, pathlib, sys
value = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
observation = value["wait_observation"]
assert observation["outcome"] == "ready", value
assert observation["process_loss_observed"] is False, value
assert observation["pid_identity_authenticated"] is False, value
assert observation["advisory"] is True, value
assert observation["authorization"] == "none", value
assert value["stage"]["mechanical_import_preconditions"]["all_satisfied"] is True
PY

# A partial editor write is not terminal while the observed process is alive.
cp "$r9_stage/candidate-copilot-evidence.md" "$TEMP_DIR/r9-valid-candidate.md"
: >"$r9_stage/candidate-copilot-evidence.md"
( sleep 1.2; cp "$TEMP_DIR/r9-valid-candidate.md" \
    "$r9_stage/candidate-copilot-evidence.md" ) &
r9_writer=$!
"$SESSION" wait-copilot "$r9_session" --stage "$r9_stage" --seal "$r9_seal" \
    --pid $$ --timeout-seconds 4 --poll-seconds 1 \
    >"$TEMP_DIR/r9-wait-transient.json"
wait "$r9_writer"
python3 - "$TEMP_DIR/r9-wait-transient.json" <<'PY'
import json, pathlib, sys
value = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert value["wait_observation"]["outcome"] == "ready", value
assert value["stage"]["candidate_state"] == "ready", value
PY

cp "$r9_session/charter.md" "$TEMP_DIR/r9-charter-orig.md"
printf '%s\n' 'live drift' >>"$r9_session/charter.md"
"$SESSION" status "$r9_session" --stage "$r9_stage" --seal "$r9_seal" \
    >"$TEMP_DIR/r9-status-precond.json"
python3 - "$TEMP_DIR/r9-status-precond.json" <<'PY'
import json, pathlib, sys
value = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert value["stage"]["candidate_state"] == "ready", value
assert value["stage"]["inputs_fresh"] is False, value
mip = value["stage"]["mechanical_import_preconditions"]
assert mip["candidate_structurally_ready"] is True, value
assert mip["inputs_fresh"] is False, value
assert mip["all_satisfied"] is False, value
assert mip["advisory"] is True, value
assert mip["authorization"] == "none", value
PY

# Process loss gets one final snapshot; stale bytes are never reported ready.
sleep 0.5 &
r9_short_pid=$!
if "$SESSION" wait-copilot "$r9_session" --stage "$r9_stage" --seal "$r9_seal" \
    --pid "$r9_short_pid" --timeout-seconds 3 --poll-seconds 1 \
    >"$TEMP_DIR/r9-wait-stale.json"; then
    fail 'waiter accepted stale candidate after process loss'
else
    r9_wait_status=$?
fi
wait "$r9_short_pid"
[ "$r9_wait_status" -eq 2 ] || fail 'wrong not-importable wait status'
python3 - "$TEMP_DIR/r9-wait-stale.json" <<'PY'
import json, pathlib, sys
value = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
observation = value["wait_observation"]
assert observation["outcome"] == "not-importable", value
assert observation["process_loss_observed"] is True, value
assert observation["authorization"] == "none", value
assert value["stage"]["mechanical_import_preconditions"]["all_satisfied"] is False
PY
if "$SESSION" wait-copilot "$r9_session" --stage "$r9_stage" --seal "$r9_seal" \
    --timeout-seconds 1 --poll-seconds 1 >"$TEMP_DIR/r9-wait-timeout.json"; then
    fail 'waiter accepted stale no-pid candidate'
else
    r9_wait_status=$?
fi
[ "$r9_wait_status" -eq 4 ] || fail 'wrong timeout wait status'
grep -F '"outcome": "timeout"' "$TEMP_DIR/r9-wait-timeout.json" >/dev/null ||
    fail 'missing timeout wait outcome'
if "$SESSION" wait-copilot "$r9_session" --stage "$r9_stage" --seal "$r9_seal" \
    --timeout-seconds 1801 --poll-seconds 1 >"$TEMP_DIR/r9-wait-bounds.out" 2>&1; then
    fail 'waiter accepted an excessive timeout'
fi
grep -F 'at most 1800' "$TEMP_DIR/r9-wait-bounds.out" >/dev/null ||
    fail 'missing wait timeout bound refusal'
if timeout 2 "$SESSION" wait-copilot "$r9_session" --stage "$r9_stage" \
    --seal "$r9_seal" --timeout-seconds nan --poll-seconds 1 \
    >"$TEMP_DIR/r9-wait-nan-timeout.out" 2>&1; then
    fail 'waiter accepted a non-finite timeout'
else
    r9_wait_status=$?
fi
[ "$r9_wait_status" -eq 1 ] || fail 'wrong non-finite timeout status'
grep -F 'at most 1800' "$TEMP_DIR/r9-wait-nan-timeout.out" >/dev/null ||
    fail 'missing non-finite timeout refusal'
if grep -E 'Traceback|"wait_observation"' "$TEMP_DIR/r9-wait-nan-timeout.out" >/dev/null; then
    fail 'non-finite timeout produced a traceback or JSON observation'
fi
if timeout 2 "$SESSION" wait-copilot "$r9_session" --stage "$r9_stage" \
    --seal "$r9_seal" --timeout-seconds 1 --poll-seconds nan \
    >"$TEMP_DIR/r9-wait-nan-poll.out" 2>&1; then
    fail 'waiter accepted a non-finite poll interval'
else
    r9_wait_status=$?
fi
[ "$r9_wait_status" -eq 1 ] || fail 'wrong non-finite poll status'
grep -F 'between 1 and 60' "$TEMP_DIR/r9-wait-nan-poll.out" >/dev/null ||
    fail 'missing non-finite poll refusal'
if grep -E 'Traceback|"wait_observation"' "$TEMP_DIR/r9-wait-nan-poll.out" >/dev/null; then
    fail 'non-finite poll produced a traceback or JSON observation'
fi
cp "$TEMP_DIR/r9-charter-orig.md" "$r9_session/charter.md"

# Prompt drift is visible before any import mutation.
sha256sum "$r9_session/copilot-evidence.md" >"$TEMP_DIR/r9-live-before"
printf '%s\n' 'drift' >>"$r9_stage/artifacts/copilot-prompt.md"
if "$SESSION" status "$r9_session" --stage "$r9_stage" --seal "$r9_seal" \
    >"$TEMP_DIR/r9-status-drift.out" 2>&1; then
    fail 'status accepted prompt drift'
fi
grep -F 'prompt digest mismatch' "$TEMP_DIR/r9-status-drift.out" >/dev/null ||
    fail 'missing status prompt-drift refusal'
fill "$r9_stage/candidate-copilot-evidence.md"
if "$SESSION" import-copilot "$r9_session" "$r9_stage" --seal "$r9_seal" \
    >"$TEMP_DIR/r9-import-drift.out" 2>&1; then
    fail 'import accepted prompt drift'
fi
grep -F 'prompt digest mismatch' "$TEMP_DIR/r9-import-drift.out" >/dev/null ||
    fail 'missing import prompt-drift refusal'
sha256sum "$r9_session/copilot-evidence.md" >"$TEMP_DIR/r9-live-after"
cmp -s "$TEMP_DIR/r9-live-before" "$TEMP_DIR/r9-live-after" ||
    fail 'prompt-drift refusal changed live evidence'
[ ! -e "$r9_session/receipts/independent.json" ] ||
    fail 'prompt drift created a receipt'
cp "$r9_prompt" "$r9_stage/artifacts/copilot-prompt.md"
"$SESSION" import-copilot "$r9_session" "$r9_stage" --seal "$r9_seal" >/dev/null
"$SESSION" status "$r9_session" --stage "$r9_stage" --seal "$r9_seal" \
    --pid 2147483647 >"$TEMP_DIR/r9-status-imported.json"
python3 - "$TEMP_DIR/r9-status-imported.json" <<'PY'
import json, pathlib, sys
value = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert value["receipt_modes"] == ["independent"], value
assert value["stage"]["candidate_state"] == "ready", value
assert value["stage"]["destination_fresh"] is False, value
assert value["stage"]["mechanical_import_preconditions"]["all_satisfied"] is False, value
assert value["process"]["state"] == "not-reachable", value
assert "reciprocal" in value["next_action"], value
PY

# Prompt-source failures happen before either stage or seal is created.
r9_bad_session=$TEMP_DIR/r9-bad-session
"$SESSION" init "$r9_bad_session" --driver claude >/dev/null
fill "$r9_bad_session/charter.md"
fill "$r9_bad_session/plan.md"
"$SESSION" advance "$r9_bad_session" discussing >/dev/null
ln -s "$r9_prompt" "$TEMP_DIR/r9-prompt-link"
if "$SESSION" stage "$r9_bad_session" "$BOX/r9-bad-stage" --mode independent \
    --prompt "$TEMP_DIR/r9-prompt-link" --seal "$SEALS/r9-bad.json" \
    >"$TEMP_DIR/r9-bad.out" 2>&1; then
    fail 'stage accepted a symlinked prompt'
fi
grep -F 'must be real and not a symlink' "$TEMP_DIR/r9-bad.out" >/dev/null ||
    fail 'missing symlinked-prompt refusal'
[ ! -e "$BOX/r9-bad-stage" ] && [ ! -e "$SEALS/r9-bad.json" ] ||
    fail 'bad prompt minted stage or seal residue'

# The stage-2 reader remains available for already-created staged exchanges.
r9_compat=$TEMP_DIR/r9-compat-session
r9_compat_stage=$BOX/r9-compat-stage
r9_compat_seal=$SEALS/r9-compat.json
"$SESSION" init "$r9_compat" --driver claude >/dev/null
fill "$r9_compat/charter.md"
fill "$r9_compat/plan.md"
"$SESSION" advance "$r9_compat" discussing >/dev/null
"$SESSION" stage "$r9_compat" "$r9_compat_stage" --mode independent \
    --seal "$r9_compat_seal" >/dev/null
python3 - "$r9_compat_stage/stage.json" "$r9_compat_seal" <<'PY'
import hashlib, json, pathlib, sys
stage_path, seal_path = map(pathlib.Path, sys.argv[1:])
stage = json.loads(stage_path.read_text(encoding="utf-8"))
stage["schema_version"] = 2
stage.pop("prompt_sha256")
stage_path.write_text(json.dumps(stage, indent=2, sort_keys=True) + "\n", encoding="utf-8")
seal = json.loads(seal_path.read_text(encoding="utf-8"))
seal["stage_manifest_sha256"] = hashlib.sha256(stage_path.read_bytes()).hexdigest()
seal_path.write_text(json.dumps(seal, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
"$SESSION" status "$r9_compat" --stage "$r9_compat_stage" \
    --seal "$r9_compat_seal" >/dev/null || fail 'status rejected stage schema 2'
fill "$r9_compat_stage/candidate-copilot-evidence.md"
"$SESSION" import-copilot "$r9_compat" "$r9_compat_stage" \
    --seal "$r9_compat_seal" >/dev/null || fail 'import rejected stage schema 2'

echo 'Codex-Claude cowork skill tests passed'
