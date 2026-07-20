# Reconciliation

## Evidence accepted

Both agents independently reproduced the residual against the unmodified round-5
helper: after a crash-shaped evidence overwrite (evidence replaced, no receipt),
rewriting the co-pilot-writable `stage.json` `destination_before_sha256` to the
overwritten hash lets an *unsealed* `import-copilot` mint a receipt whose recorded
`stage_manifest_sha256` is the post-tamper value, never pinned to the pre-window
`stage_sha256`. `stage.json` is a co-pilot-controlled trust anchor.

Both agents built independent sealed prototypes and confirmed the fix: a
mandatory external, path-free seal that commits the exact `stage.json` SHA-256 and
is verified by import before any mutation refuses the rewrite and mints no
receipt. Both confirmed the full edge battery fails closed with no receipt:
missing/altered/wrong-stage/hard-linked/symlinked/non-UTF-8/unexpected-key seals,
a seal inside the co-pilot tree, replay after success, and a `stage.json` tamper
that preserves `destination_before` (caught by the manifest-hash anchor). Both
confirmed the happy path imports, binds `seal_sha256` in the receipt, and passes
`verify-receipts`; and that the reciprocal two-receipt chain holds. The live
round-6 session's own imports (run by the pre-change helper) produced schema-1
receipts, so the session is a real backward-compatibility fixture.

Reciprocal experiments (Codex, medium effort) refined the design with evidence:
- A seven-key seal without `stage_schema_version` still rejects manifest tampers,
  because the hashed `stage.json` transitively commits its own schema. The extra
  field is redundant.
- A nested stage defeats the `stage_root.parent` co-pilot-root approximation: a
  seal placed elsewhere in the co-pilot tree but outside the stage's immediate
  parent was accepted. The rule is sound only under a direct-child precondition.
- Stage-then-seal is fail-closed but not cross-file atomic (fault-injected seal
  failure leaves a sealless, non-importable stage).
- `verify-receipts SESSION_DIR` cannot revalidate external seal bytes; it checks
  the stored commitment and the receipt/evidence chain only.
- Bumping the receipt schema requires a dual-version reader so pre-change
  schema-1 receipts in schema-2 sessions stay valid.

## Disagreements and uncertainty

- **File mode 0600 at import.** Codex's prototypes additionally required the seal
  file to be mode 0600 at import. Rejected for the frozen design: on a same-UID
  file, mode is not a security property (the owner can re-chmod), and requiring
  exact bits reduces portability. Owner, single link count, and non-symlink are
  the enforced structural checks; the seal is created 0600 by `stage` as a
  courtesy, and file mode is treated like read-only mode elsewhere — an advisory
  tripwire, not a gate.
- **Descriptor-bound seal read.** Codex suggested `open(O_NOFOLLOW)/fstat/read`
  to close a check/use gap. Rejected for this round as scope creep: every
  protocol file in the helper is validated with the shared `require_owned_kind`
  (lstat) pattern and then read; the seal introduces no new class of race, and
  its integrity rests on being outside co-pilot write authority, which a
  descriptor-bound read does not change. Recorded as a possible future hardening.
- **`--copilot-root` argument.** Rejected for this round in favor of the smaller
  direct-child precondition, which the protocol already implies ("create each
  stage inside the co-pilot sandbox"). Documented as the residual, with the
  nested-stage caveat stated plainly rather than papered over.
- **Unresolved limits (kept explicit):** no dynamic foreign-owner test was
  possible as the unprivileged user (owner rejection is a source-level property of
  `require_owned_kind`); no protection against a same-UID process that can reach
  the seal; no cross-file crash atomicity; the seal proves byte equality, not
  authorship or honest driver inputs.

## Frozen plan

Only Claude (driver) edits the live target, after this freeze. Implement exactly:

1. **Seal creation.** Add `stage SESSION STAGE --mode MODE --seal EXTERNAL_FILE`.
   For schema-2 staged sessions `--seal` is required; schema-1 legacy staging and
   schema-2 direct sessions are unchanged (seal-free / staging-refused). Resolve
   and pre-check the seal path **before** creating the stage directory: refuse a
   seal resolved inside the live session or inside `stage_root.parent`, and refuse
   an already-present seal path, so a bad seal mints no partial stage. After
   writing `stage.json`, write a real mode-0600, path-free seal with exactly seven
   keys — `schema_version` (=1), `driver`, `copilot`, `mode`, `phase`,
   `destination_before_sha256`, `stage_manifest_sha256` (= exact `stage.json`
   SHA-256). Print `seal_sha256`. Stage-then-seal is fail-closed, not atomic.

2. **Seal verification at import.** Add `import-copilot … --seal EXTERNAL_FILE`,
   required for schema-2 staged sessions. Before any mutation: refuse a seal
   inside the session or `stage_root.parent`; require a real, current-user-owned,
   single-link, non-symlink file; parse UTF-8 JSON with exactly the seven keys and
   supported schema; require `driver`/`copilot` == session, `mode` == stage mode,
   `phase` == `discussing`, `destination_before_sha256` == stage's, and
   `stage_manifest_sha256` == exact SHA-256 of the stage's `stage.json`. Bind the
   seal's SHA-256 into the receipt.

3. **Receipt schema.** New receipts are schema 2 with a required `seal_sha256`;
   bump `RECEIPT_SCHEMA_VERSION` to 2 and support reading `{1, 2}` with a
   per-schema exact key set (schema 1 has no `seal_sha256`). `verify-receipts`,
   `validate_receipts`, and `digests` keep working over both; `digests` still
   covers receipts only (the seal is external by design). `verify-receipts`
   interface is unchanged and does not reopen the external seal.

4. **Docs.** Update SKILL and protocol: the mandatory external seal, the seven-key
   path-free schema, the direct-child co-pilot-sandbox precondition with the
   nested-stage caveat, the content-not-identity/location binding, the
   fail-closed-not-atomic stage+seal boundary, the receipt dual-version reader, and
   the explicit limits (no authorship, no OS confinement, no same-UID-seal
   protection, no crash atomicity, `verify-receipts` does not reopen the seal).

5. **Focused tests.** Add: unsealed laundering refusal (schema-2), manifest-anchor
   refusal, every seal edge case (missing/altered/wrong-stage/hard-link/symlink/
   non-UTF-8/extra-key/bad-schema/role-mode-phase-destination mismatch), seal
   inside session/co-pilot tree refused at stage and import, seal preflight before
   stage mint, valid sealed import, replay refusal, receipt `seal_sha256` binding,
   reciprocal chain with seals, schema-1→2 receipt-read compatibility (a schema-2
   session holding a schema-1 receipt stays valid), and unchanged schema-1 legacy
   / schema-2 direct behavior.

Owner go is the standing round-6 self-refinement instruction; execution is
authorized only for this frozen scope. Stop on target drift, ambiguous live
evidence, or any failing acceptance gate.

## Acceptance gates

Canonical skill validation, helper self-checks (`check`, `verify-receipts`,
`digests` on the live round-6 session with its schema-1 receipts still valid),
expanded `tests/test-codex-claude-cowork-skill.sh`, Claude takeover test, source
contract, public audit, `git diff --check`, and clean-commit
`tests/test-phase1.sh` must all pass. The seal must be path-free (no absolute
path in seal or receipt), refuse co-pilot-tree placement at stage and import, and
make an unsealed or tampered schema-2 staged import fail closed before mutation.
Schema-1 legacy sessions/predecessors and schema-2 direct sessions keep existing
behavior. Session ends at `validating`, uncommitted, with full clean Phase 1.
