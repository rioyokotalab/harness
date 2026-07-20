# Charter

## Task

Close the strongest residual carried out of round 5: because a stage's
`stage.json` lives in the co-pilot sandbox and is co-pilot-writable, the
schema-2 staged import trusts a manifest the co-pilot controls. After a
crash-shaped evidence overwrite (evidence replaced, receipt not yet created), a
co-pilot can rewrite `stage.json` — notably `destination_before_sha256` and the
input/candidate hashes — so that an unsealed retry import passes its own
self-referential guard and mints an ambiguous receipt. Round 5 printed the
`stage.json` SHA-256 for a *manual* external seal but never made `import`
require a driver-held seal, so the anchor was advisory.

Round 6 designs, empirically tests, reconciles, and freezes the smallest
enforcement that makes the external seal mandatory and binding for schema-2
staged exchange, then implements exactly that frozen change in the live target.

Strong candidate enforcement (to validate, not assume):
- `stage SESSION STAGE --mode MODE --seal EXTERNAL_FILE` writes a real,
  path-free, mode-0600 seal file at `EXTERNAL_FILE`, refusing any seal path
  inside the live session or the stage-parent (co-pilot) sandbox. The seal binds
  the exact `stage.json` SHA-256 plus mode, roles, phase, and destination-before.
- `import-copilot SESSION STAGE --seal EXTERNAL_FILE` requires the seal for
  schema-2 staged sessions and verifies exact owner, single link count, schema,
  roles, mode, phase, destination-before, and `stage.json` SHA-256 match before
  any target mutation.
- Each staged import receipt binds the seal SHA-256 and the receipt schema bumps.

## Boundaries

- Live target: `/home/rioyokota/harness` on clean branch
  `task/t-283-codex-claude-cowork` at baseline `52c7931`. Only Claude (driver)
  edits the live target, and only after the plan is frozen.
- Exchange: `docs/audits/t283-cowork-round6`. Predecessor:
  `docs/audits/t283-cowork-round5` (recorded, provenance only, no authority).
- Sandboxes: Claude driver `/tmp/harness-t283-round6-claude`, Codex co-pilot
  `/tmp/harness-t283-round6-codex` — detached no-hardlink clones at `52c7931`.
- External seals live in `/tmp/harness-t283-round6-seals`, outside both
  sandboxes and the live session.
- No commit, push, ref/settings/credential/package/service/remote change, no
  external message, no scratch deletion, no unrelated file edits. Preserve all
  scratch for guarded cleanup. Follow `guarded-bulk-delete` before any recursive
  removal.
- Codex co-pilot is invoked only against its stage from its sandbox at medium
  reasoning effort; the live session is never disclosed.

## Baseline and sandboxes

Common baseline commit `52c7931` (`Record guarded round-five cleanup`). Both
sandboxes are independent detached clones with no hard links to the live target,
already present at the baseline. Claude experiments edit only a disposable copy
of the helper inside the Claude sandbox; the live helper stays untouched until
execution.

## Acceptance

Canonical skill validation, helper self-checks, expanded focused cowork test
(`tests/test-codex-claude-cowork-skill.sh`), Claude takeover test, source
contract, public audit, `git diff --check`, and clean-commit
`tests/test-phase1.sh` must all pass. The frozen seal must be portable, contain
no absolute path, refuse placement inside the co-pilot tree, and make an
unsealed or tampered schema-2 staged import fail closed before mutation.
Schema-1 legacy sessions/predecessors and schema-2 direct sessions keep their
existing behavior. Session ends at `validating`, uncommitted, with full clean
Phase 1 for supervising Codex review.
