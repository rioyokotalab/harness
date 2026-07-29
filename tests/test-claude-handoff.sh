#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/claude-handoff-test.XXXXXX")
STAGE_DIR=$TEST_ROOT/stage
PACKET=$STAGE_DIR/handoff.json
STAGE=$STAGE_DIR/stage.json
EVIDENCE=$TEST_ROOT/evidence.json
REPRODUCTION=$TEST_ROOT/reproduction.json
RETRY=$TEST_ROOT/retry.json

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEST_ROOT" ]; then
        "$CLEANUP" "$HARNESS" "$TEMP_BASE" "$TEST_ROOT" \
            "$TEMP_BASE" >/dev/null || cleanup_failed=1
    fi
    [ "$status" -ne 0 ] || [ "$cleanup_failed" -eq 0 ] || status=1
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

expect_failure() {
    label=$1
    shift
    if "$@" >"$TEST_ROOT/$label.out" 2>&1; then
        fail "$label unexpectedly passed"
    fi
}

python3 - "$ROOT" <<'PY'
import ast
import json
from pathlib import Path
import sys

root = Path(sys.argv[1])
source = (root / "libexec/harness-claude-handoff").read_text(encoding="utf-8")
ast.parse(source, filename="harness-claude-handoff", feature_version=(3, 6))
if "from __future__ import annotations" in source:
    raise SystemExit("validator requires newer-than-Python-3.6 syntax")
for name in (
    "claude-handoff-packet.schema.json",
    "claude-handoff-evidence.schema.json",
    "claude-handoff-retry.schema.json",
    "claude-handoff-structured-output.schema.json",
):
    value = json.loads((root / "docs/schemas" / name).read_text(encoding="utf-8"))
    if value.get("type") != "object" or value.get("additionalProperties") is not False:
        raise SystemExit("handoff schema is not a closed object: " + name)
structured = json.loads(
    (root / "docs/schemas/claude-handoff-structured-output.schema.json").read_text(
        encoding="utf-8"
    )
)
if "$schema" in structured or "$id" in structured:
    raise SystemExit("native structured schema retains unsupported metadata")
PY

"$HARNESS" help | grep -F \
    'claude-handoff  validate task-bound Claude handoff packets and evidence' \
    >/dev/null || fail "harness help declaration"
grep -F '`harness claude-handoff` validates a bounded, expiring packet' \
    "$ROOT/docs/agent-client-config.md" >/dev/null ||
    fail "handoff documentation"

repo=$TEST_ROOT/repo
mkdir -p "$repo" "$STAGE_DIR/artifacts"
git -C "$repo" init -q
git -C "$repo" config user.name handoff-test
git -C "$repo" config user.email handoff-test.invalid
printf '%s\n' '# instructions' >"$repo/AGENTS.md"
printf '%s\n' '# ledger' >"$repo/TODO.md"
git -C "$repo" add AGENTS.md TODO.md
git -C "$repo" commit -qm baseline
baseline=$(git -C "$repo" rev-parse HEAD)

write_packet() {
    task_id=$1
    expires_at=$2
    cat >"$PACKET" <<EOF
{
  "schema_version": 1,
  "task_id": "$task_id",
  "run_id": "t343-readonly-r1",
  "repository_root": "$repo",
  "baseline_commit": "$baseline",
  "phase": "executing",
  "client": "claude",
  "model": "fable",
  "effort": "high",
  "authority_class": "read-only",
  "allowed_paths": [],
  "source_files": ["AGENTS.md", "TODO.md"],
  "checks": ["tests/test-claude-handoff.sh"],
  "next_action": "recover the packet without changing the repository",
  "issued_at": "2026-07-29T09:00:00Z",
  "expires_at": "$expires_at"
}
EOF
}

validate_packet() {
    "$HARNESS" claude-handoff validate \
        --packet "$PACKET" \
        --expect-task T-343 \
        --expect-run-id t343-readonly-r1 \
        --expect-root "$repo" \
        --expect-baseline "$baseline" \
        --now 2026-07-29T10:00:00Z
}

write_packet T-343 2026-07-29T11:00:00Z
validate_packet | grep -Fx \
    'CLAUDE_HANDOFF status=pass task=T-343 run=t343-readonly-r1 phase=executing authority=read-only checks=1 sources=2' \
    >/dev/null || fail "exact packet acceptance"

expect_failure wrong-root "$HARNESS" claude-handoff validate \
    --packet "$PACKET" --expect-task T-343 \
    --expect-run-id t343-readonly-r1 --expect-root "$TEST_ROOT" \
    --expect-baseline "$baseline" --now 2026-07-29T10:00:00Z
grep -F 'repository root mismatch' "$TEST_ROOT/wrong-root.out" >/dev/null ||
    fail "wrong-root diagnostic"

expect_failure wrong-baseline "$HARNESS" claude-handoff validate \
    --packet "$PACKET" --expect-task T-343 \
    --expect-run-id t343-readonly-r1 --expect-root "$repo" \
    --expect-baseline 0000000000000000000000000000000000000000 \
    --now 2026-07-29T10:00:00Z
grep -F 'baseline mismatch' "$TEST_ROOT/wrong-baseline.out" >/dev/null ||
    fail "wrong-baseline diagnostic"

write_packet T-343 2026-07-29T11:00:00Z
sed '/"task_id":/d' "$PACKET" >"$TEST_ROOT/missing-task.json"
expect_failure missing-task "$HARNESS" claude-handoff validate \
    --packet "$TEST_ROOT/missing-task.json" --expect-task T-343 \
    --expect-run-id t343-readonly-r1 --expect-root "$repo" \
    --expect-baseline "$baseline" --now 2026-07-29T10:00:00Z
grep -F 'packet fields differ from schema' "$TEST_ROOT/missing-task.out" \
    >/dev/null || fail "missing-task diagnostic"

write_packet T-343 2026-07-29T09:59:59Z
expect_failure expired validate_packet
grep -F 'packet is expired' "$TEST_ROOT/expired.out" >/dev/null ||
    fail "expired diagnostic"

write_packet T-344 2026-07-29T11:00:00Z
expect_failure cross-task validate_packet
grep -F 'task mismatch' "$TEST_ROOT/cross-task.out" >/dev/null ||
    fail "cross-task diagnostic"

write_packet T-343 2026-07-29T11:00:00Z
ln -s "$PACKET" "$TEST_ROOT/packet-link.json"
expect_failure linked-packet "$HARNESS" claude-handoff validate \
    --packet "$TEST_ROOT/packet-link.json" --expect-task T-343 \
    --expect-run-id t343-readonly-r1 --expect-root "$repo" \
    --expect-baseline "$baseline" --now 2026-07-29T10:00:00Z
grep -F 'packet must be a real regular file' \
    "$TEST_ROOT/linked-packet.out" >/dev/null ||
    fail "linked-packet diagnostic"

cp "$repo/AGENTS.md" "$STAGE_DIR/AGENTS.md"
cp "$repo/TODO.md" "$STAGE_DIR/TODO.md"
printf '%s\n' 'Read the sealed handoff packet and source files.' \
    >"$STAGE_DIR/artifacts/copilot-prompt.md"

sha_file() {
    python3 -c \
        'import hashlib, pathlib, sys; print(hashlib.sha256(pathlib.Path(sys.argv[1]).read_bytes()).hexdigest())' \
        "$1"
}

digest_a=$(sha_file "$STAGE_DIR/AGENTS.md")
digest_b=$(sha_file "$STAGE_DIR/TODO.md")
digest_c=$(sha_file "$STAGE_DIR/artifacts/copilot-prompt.md")
digest_d=dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd

write_stage() {
    digest_packet=$(sha_file "$PACKET")
    cat >"$STAGE" <<EOF
{
  "schema_version": 3,
  "driver": "codex",
  "copilot": "claude",
  "mode": "independent",
  "phase": "executing",
  "destination_before_sha256": "$digest_d",
  "inputs": {
    "AGENTS.md": "$digest_a",
    "TODO.md": "$digest_b",
    "handoff.json": "$digest_packet"
  },
  "prompt_sha256": "$digest_c"
}
EOF
}

write_readonly_evidence() {
    prompt_digest=$1
    cat >"$EVIDENCE" <<EOF
{
  "schema_version": 1,
  "task_id": "T-343",
  "run_id": "t343-readonly-r1",
  "authority_class": "read-only",
  "stage_receipt": {
    "prompt_sha256": "$prompt_digest",
    "inputs": {
      "AGENTS.md": "$digest_a",
      "TODO.md": "$digest_b",
      "handoff.json": "$digest_packet"
    }
  },
  "read_manifest": [
    {"path": "AGENTS.md", "sha256": "$digest_a"},
    {"path": "TODO.md", "sha256": "$digest_b"},
    {"path": "handoff.json", "sha256": "$digest_packet"},
    {"path": "artifacts/copilot-prompt.md", "sha256": "$prompt_digest"}
  ],
  "recovered": {
    "task_id": "T-343",
    "run_id": "t343-readonly-r1",
    "repository_root": "$repo",
    "baseline_commit": "$baseline",
    "phase": "executing",
    "authority_class": "read-only",
    "next_action": "recover the packet without changing the repository",
    "checks": ["tests/test-claude-handoff.sh"]
  },
  "execution_records": []
}
EOF
}

verify_readonly_evidence() {
    "$HARNESS" claude-handoff verify-evidence \
        --packet "$PACKET" --stage "$STAGE" --evidence "$EVIDENCE" \
        --expect-task T-343 --expect-run-id t343-readonly-r1 \
        --expect-root "$repo" --expect-baseline "$baseline" \
        --now 2026-07-29T10:00:00Z
}

write_packet T-343 2026-07-29T11:00:00Z
write_stage
write_readonly_evidence "$digest_c"
verify_readonly_evidence | grep -Fx \
    'CLAUDE_HANDOFF_EVIDENCE status=pass task=T-343 run=t343-readonly-r1 authority=read-only reads=4 records=0 reproduced=0' \
    >/dev/null || fail "read-only evidence acceptance"

write_readonly_evidence "$digest_d"
expect_failure receipt-mismatch verify_readonly_evidence
grep -F 'prompt receipt mismatch' "$TEST_ROOT/receipt-mismatch.out" \
    >/dev/null || fail "prompt receipt mismatch diagnostic"

write_readonly_evidence "$digest_c"
sed 's/"execution_records": \[\]/"execution_records": [{"case_id": "forbidden", "command": ["true"], "exit_status": 0, "output_sha256": "'"$digest_a"'"}]/' \
    "$EVIDENCE" >"$TEST_ROOT/readonly-executed.json"
expect_failure readonly-executed "$HARNESS" claude-handoff verify-evidence \
    --packet "$PACKET" --stage "$STAGE" \
    --evidence "$TEST_ROOT/readonly-executed.json" \
    --expect-task T-343 --expect-run-id t343-readonly-r1 \
    --expect-root "$repo" --expect-baseline "$baseline" \
    --now 2026-07-29T10:00:00Z
grep -F 'read-only evidence must not contain execution records' \
    "$TEST_ROOT/readonly-executed.out" >/dev/null ||
    fail "read-only execution diagnostic"

sed -e 's/"authority_class": "read-only"/"authority_class": "execution"/' \
    -e 's/"allowed_paths": \[\]/"allowed_paths": ["sandbox"]/' \
    "$PACKET" >"$TEST_ROOT/execution-packet.json"
mv "$TEST_ROOT/execution-packet.json" "$PACKET"
write_stage
cat >"$EVIDENCE" <<EOF
{
  "schema_version": 1,
  "task_id": "T-343",
  "run_id": "t343-readonly-r1",
  "authority_class": "execution",
  "stage_receipt": {
    "prompt_sha256": "$digest_c",
    "inputs": {
      "AGENTS.md": "$digest_a",
      "TODO.md": "$digest_b",
      "handoff.json": "$digest_packet"
    }
  },
  "read_manifest": [
    {"path": "AGENTS.md", "sha256": "$digest_a"},
    {"path": "TODO.md", "sha256": "$digest_b"},
    {"path": "handoff.json", "sha256": "$digest_packet"},
    {"path": "artifacts/copilot-prompt.md", "sha256": "$digest_c"}
  ],
  "recovered": {
    "task_id": "T-343",
    "run_id": "t343-readonly-r1",
    "repository_root": "$repo",
    "baseline_commit": "$baseline",
    "phase": "executing",
    "authority_class": "execution",
    "next_action": "recover the packet without changing the repository",
    "checks": ["tests/test-claude-handoff.sh"]
  },
  "execution_records": [
    {
      "case_id": "baseline",
      "command": ["git", "rev-parse", "HEAD"],
      "exit_status": 0,
      "output_sha256": "$digest_d"
    }
  ]
}
EOF
cat >"$REPRODUCTION" <<EOF
{
  "schema_version": 1,
  "run_id": "t343-readonly-r1",
  "case_id": "baseline",
  "command": ["git", "rev-parse", "HEAD"],
  "exit_status": 0,
  "output_sha256": "$digest_d",
  "reproduced_at": "2026-07-29T10:01:00Z"
}
EOF

verify_execution_evidence() {
    "$HARNESS" claude-handoff verify-evidence \
        --packet "$PACKET" --stage "$STAGE" --evidence "$EVIDENCE" \
        --driver-reproduction "$REPRODUCTION" \
        --expect-task T-343 --expect-run-id t343-readonly-r1 \
        --expect-root "$repo" --expect-baseline "$baseline" \
        --now 2026-07-29T10:00:00Z
}

verify_execution_evidence | grep -Fx \
    'CLAUDE_HANDOFF_EVIDENCE status=pass task=T-343 run=t343-readonly-r1 authority=execution reads=4 records=1 reproduced=1' \
    >/dev/null || fail "execution evidence acceptance"

printf '%s\n' 'drift' >>"$STAGE_DIR/TODO.md"
expect_failure stale-stage verify_execution_evidence
grep -F 'staged input digest mismatch' "$TEST_ROOT/stale-stage.out" \
    >/dev/null || fail "stale stage diagnostic"
cp "$repo/TODO.md" "$STAGE_DIR/TODO.md"

expect_failure missing-reproduction "$HARNESS" claude-handoff verify-evidence \
    --packet "$PACKET" --stage "$STAGE" --evidence "$EVIDENCE" \
    --expect-task T-343 --expect-run-id t343-readonly-r1 \
    --expect-root "$repo" --expect-baseline "$baseline" \
    --now 2026-07-29T10:00:00Z
grep -F 'execution evidence requires driver reproduction' \
    "$TEST_ROOT/missing-reproduction.out" >/dev/null ||
    fail "missing reproduction diagnostic"

python3 - "$EVIDENCE" "$TEST_ROOT/broken-sandbox-evidence.json" <<'PY'
import json
from pathlib import Path
import sys

source = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
source["execution_records"] = []
Path(sys.argv[2]).write_text(
    json.dumps(source, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)
PY
expect_failure broken-sandbox "$HARNESS" claude-handoff verify-evidence \
    --packet "$PACKET" --stage "$STAGE" \
    --evidence "$TEST_ROOT/broken-sandbox-evidence.json" \
    --driver-reproduction "$REPRODUCTION" \
    --expect-task T-343 --expect-run-id t343-readonly-r1 \
    --expect-root "$repo" --expect-baseline "$baseline" \
    --now 2026-07-29T10:00:00Z
grep -F 'execution evidence requires command records' \
    "$TEST_ROOT/broken-sandbox.out" >/dev/null ||
    fail "broken sandbox diagnostic"

write_retry() {
    previous=$1
    next=$2
    outcome=$3
    acknowledged=$4
    changed=$5
    cat >"$RETRY" <<EOF
{
  "schema_version": 1,
  "task_id": "T-343",
  "previous_run_id": "$previous",
  "next_run_id": "$next",
  "previous_outcome": "$outcome",
  "previous_acknowledged": $acknowledged,
  "previous_imported": false,
  "protected_state_unchanged": true,
  "input_changed": $changed,
  "replayed": false,
  "exact_error_sha256": "$digest_a"
}
EOF
}

write_retry reciprocal-r1 reciprocal-r2 transport-failure false true
"$HARNESS" claude-handoff verify-retry --record "$RETRY" \
    --expect-task T-343 --expect-previous reciprocal-r1 \
    --expect-next reciprocal-r2 | grep -Fx \
    'CLAUDE_HANDOFF_RETRY status=pass task=T-343 previous=reciprocal-r1 next=reciprocal-r2 outcome=transport-failure acknowledged=0' \
    >/dev/null || fail "transport retry acceptance"

write_retry reciprocal-r2 reciprocal-r3 candidate-invalid true true
"$HARNESS" claude-handoff verify-retry --record "$RETRY" \
    --expect-task T-343 --expect-previous reciprocal-r2 \
    --expect-next reciprocal-r3 | grep -Fx \
    'CLAUDE_HANDOFF_RETRY status=pass task=T-343 previous=reciprocal-r2 next=reciprocal-r3 outcome=candidate-invalid acknowledged=1' \
    >/dev/null || fail "format retry acceptance"

write_retry reciprocal-r2 reciprocal-r2 candidate-invalid true false
expect_failure unchanged-retry "$HARNESS" claude-handoff verify-retry \
    --record "$RETRY" --expect-task T-343 \
    --expect-previous reciprocal-r2 --expect-next reciprocal-r2
grep -F 'retry requires a distinct run identity' \
    "$TEST_ROOT/unchanged-retry.out" >/dev/null ||
    fail "unchanged retry diagnostic"

write_retry native-r1 native-r2 launch-validation-failure false true
"$HARNESS" claude-handoff verify-retry --record "$RETRY" \
    --expect-task T-343 --expect-previous native-r1 \
    --expect-next native-r2 | grep -Fx \
    'CLAUDE_HANDOFF_RETRY status=pass task=T-343 previous=native-r1 next=native-r2 outcome=launch-validation-failure acknowledged=0' \
    >/dev/null || fail "launch validation retry acceptance"

printf '%s\n' 'Claude handoff tests passed'
