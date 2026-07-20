# Initial plan

## Confirmed facts and assumptions

Confirmed by reading the round-5 helper and protocol:
- `stage` copies inputs into a co-pilot-writable stage and writes `stage.json`
  with `destination_before_sha256` and per-input hashes; it prints
  `stage_sha256` but nothing external anchors it.
- `import-copilot` trusts `stage.json`: it compares live evidence to
  `stage.json`'s `destination_before_sha256` and staged inputs to `stage.json`'s
  input hashes. The receipt records `stage_manifest_sha256` only after the fact.
- Import refuses replay (`receipt already exists`), enforces receipt order, and
  the destination-before binding makes an honest crash-retry fail closed.
- The co-pilot has workspace-write over the stage, so it can rewrite `stage.json`
  before the driver imports.

Assumptions (to test): a co-pilot rewrite of `stage.json`'s
`destination_before_sha256` (and/or input/candidate hashes) can launder a
crash-overwritten evidence file into a valid-looking receipt on an unsealed
import; a mandatory driver-held seal binding the exact `stage.json` bytes closes
this without breaking legacy schema-1 or schema-2 direct behavior.

## Steps

1. In the Claude sandbox, prototype the `--seal` enforcement on a disposable
   copy of `cowork-session`: `stage --seal` writes a path-free mode-0600 seal
   binding the `stage.json` SHA-256, refusing a seal inside the session or the
   stage-parent sandbox; `import-copilot --seal` requires and verifies it before
   mutation; receipts add `seal_sha256` and bump receipt schema.
2. Reproduce the residual against the current helper (rewrite `stage.json` after
   a simulated crash overwrite; show an unsealed import mints an ambiguous
   receipt) and show the sealed prototype fails closed. Probe seal edge cases:
   missing, altered, wrong-stage, hard-linked, non-UTF-8, unexpected-key,
   wrong-owner-shaped, and seal path inside the stage/co-pilot tree. Probe
   replay, receipt binding, and stage/seal write-failure semantics. Do not
   overclaim OS confinement or cross-file atomicity. Freeze `driver-evidence.md`.
3. Take the live protected `digests` seal after driver evidence is frozen. With
   the current live helper, create an independent stage inside the Codex sandbox,
   store its printed `stage_sha256` under the external seal directory, make no
   driver-owned live write during the window, invoke Codex at medium effort
   against only its stage, compare live/stage seals, inspect and import, and run
   `verify-receipts`.
4. Reveal both evidence files, create a reciprocal stage, store its seal
   externally, invoke Codex once more to challenge the exact seal
   schema/location/transaction, compare seals, inspect/import, and verify the
   two-receipt chain. Record bounded command/hash records after each window.
5. Reconcile evidence and freeze the smallest enforcement that survives, stating
   accepted/rejected changes with evidence pointers. Advance ready-for-execution.
6. Execute only the frozen edits in the live target (helper, SKILL, protocol,
   focused test, TODO). Run canonical validation, focused cowork, takeover,
   source, public audit, syntax, and diff checks. Leave at `validating`,
   uncommitted, with clean Phase 1.

## Evidence questions

- Does an unsealed import accept a co-pilot-rewritten `stage.json` after a
  crash-shaped overwrite, and does a mandatory seal binding `stage.json` bytes
  refuse it before mutation?
- Are all seal edge cases (missing/altered/wrong-stage/linked/non-UTF-8/
  unexpected-key/co-pilot-tree location) rejected with no target mutation?
- Does the seal stay path-free and portable, and does the receipt seal binding
  survive `verify-receipts` and the two-receipt chain?
- What exactly can the seal NOT guarantee (authorship, arbitrary co-pilot-writable
  locations, hard power-loss cross-file atomicity)?

## Risks and recovery

- Nested Codex failure: record exact retry safety; permit at most one narrower
  retry without weakening workspace-write or approval. Never fabricate co-pilot
  evidence.
- Protected-manifest drift during a co-pilot window is a stop condition
  returning the session to owner review.
- Overclaiming confinement: the seal only anchors `stage.json` bytes against
  co-pilot rewrite; it does not prove authorship or protect a seal the driver
  places inside a co-pilot-writable tree. Enforce refusal of such placement and
  document the residual rather than pretend safety.
- Live edits are the driver's alone, small and validated per step, reversible by
  ordinary Git; stop on any target drift or failing acceptance gate.
