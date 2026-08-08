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
retry = json.loads(
    (root / "docs/schemas/claude-handoff-retry.schema.json").read_text(
        encoding="utf-8"
    )
)
run_pattern = "^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$"
for name in ("previous_run_id", "next_run_id"):
    if retry.get("properties", {}).get(name, {}).get("pattern") != run_pattern:
        raise SystemExit("retry schema run identity pattern differs: " + name)
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
sha_file() {
    python3 -c \
        'import hashlib, pathlib, sys; print(hashlib.sha256(pathlib.Path(sys.argv[1]).read_bytes()).hexdigest())' \
        "$1"
}

repo=$TEST_ROOT/repo
mkdir -p "$repo" "$STAGE_DIR/artifacts"
git -C "$repo" init -q
git -C "$repo" config user.name handoff-test
git -C "$repo" config user.email handoff-test.invalid
printf '%s\n' '# instructions' >"$repo/AGENTS.md"
printf '%s\n' '# ledger' >"$repo/TODO.md"
printf '%s\n' '{"required_approvals":0,"owner_selected":true}' \
    >"$repo/policy.json"
git -C "$repo" add AGENTS.md TODO.md policy.json
git -C "$repo" commit -qm baseline
baseline=$(git -C "$repo" rev-parse HEAD)
printf '%s\n' 'owner draft: preserve this unrelated dirty file' \
    >"$repo/owner-note.txt"

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

printf '%s\n' 'Claude handoff essential contract: PASS'
exit 0
