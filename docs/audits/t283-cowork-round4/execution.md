# Driver execution

## Steps and results

Claude re-read the ready state, charter, and frozen reconciliation; verified
branch `task/t-283-codex-claude-cowork` at baseline `9fed369` with only this
declared exchange untracked; and advanced to `executing` before target edits.
It changed only the frozen skill, protocol, helper, focused test, and round-4
evidence surfaces. The one target-writing role is the Claude driver.

1. `scripts/cowork-session` gained `project_stage_state`: a fail-closed,
   path-free projection of `state.json` that whitelists exactly the schema-1
   top-level keys plus an optional `predecessor` with exactly
   `driver/path/phase/state_sha256`, drops `predecessor.path`, refuses any
   unknown/missing key, and serializes canonically.
2. `stage_session` computes the projection before resolving/creating the stage
   directory (fail-closed leaves no partial stage) and writes the projected
   bytes as the staged `state.json`, hashing those bytes into `stage.json`.
3. `import_copilot` projects the live `state.json` identically before the
   equality/digest comparison, preserving projected-semantic freshness binding.
4. `predecessor_record` now calls `validate_files(pred_root,
   pred_state["phase"])` immediately after `load_state`, before any successor
   directory is created, so `init --predecessor` refuses a phase/content-
   inconsistent predecessor atomically.
5. `references/protocol.md` and `SKILL.md` now describe the staged state as a
   fail-closed path-free projection tied to `schema_version`, define import
   freshness as projected-semantic (withheld fields and representation-only
   changes are outside import and covered by the external `digests` seal plus
   recoverable preimage), and note the new predecessor content validation.
6. `tests/test-codex-claude-cowork-skill.sh` gained a round-4 block covering
   path-free predecessor staging, projected round-trip import with unchanged
   protected entries, fail-closed unknown top-level and predecessor fields (no
   partial stage), withheld-field-only change (import passes, external seal
   detects), retained-field stale refusal with unchanged destination, and
   `init --predecessor` reject-inconsistent-atomically plus accept-valid.

The live helper parses and, on a throwaway predecessor-backed session, staged a
path-free state and round-tripped an import. The T1–T10 battery was reproduced
against the final whitelist-fail-closed prototype in the driver sandbox before
these edits.

## Deviations

None material. The live round-4 discussion itself used the pre-fix helper (raw
`state.json` staging), which is expected: the fix targets future sessions and
the state machine cannot move backward to re-stage this one under the new
helper. The disclosure that occurred in this round was the predecessor path
`…/t283-cowork-round3`, exactly the artifact under study, and Codex observed it
as evidence rather than being blinded to it. The first Codex independent call
timed out at 10 minutes at high reasoning effort with the candidate file
unchanged (retry-safe); one narrower retry at medium reasoning effort, identical
sandbox/approval confinement, completed and returned valid evidence.
