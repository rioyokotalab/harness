# Driver evidence

## Sandbox and baseline

Claude driver sandbox `/tmp/harness-t283-round6-claude`, a detached no-hardlink
clone at baseline `52c7931` (verified `git rev-parse HEAD`). Experiments ran on
disposable copies of the helper in `exp/`: `base-cowork-session` (unmodified
round-5 helper, sha256 `7ba2aff1…`) and `proto-cowork-session` (the sealed
prototype). No live target file was touched. Fixture sessions used a simulated
layout: session `exp/sess`, simulated co-pilot sandbox `exp/cbx` (stages inside
it, mirroring the protocol), and external seal directory `exp/seals` outside both.
Bounded logs: `artifacts/proto-seal.diff`, `artifacts/driver-battery.log`.

## Commands and results

Observations (O) are printed helper output; inferences (I) are labeled.

1. **Residual reproduced against the round-5 helper (O).** Independent schema-2
   staged session; crash-shaped overwrite (`cp candidate → copilot-evidence.md`,
   no receipt). Honest retry `import-copilot` was refused
   ("live co-pilot evidence drifted from the staged destination-before hash") —
   the round-5 guard. Then a co-pilot rewrite of `stg/stage.json`
   `destination_before_sha256` to the overwritten evidence hash made the
   *unsealed* import **succeed**, minting `receipts/independent.json` attesting
   `destination_before = candidate` with the post-tamper `stage_manifest_sha256`
   (`2cf7a08…`), never pinned to the pre-window `stage_sha256=b4a9a86…`. Residual
   confirmed: `stage.json` is the sole, co-pilot-controlled anchor.

2. **Sealed prototype (O).** Added `stage … --seal EXTERNAL_FILE` and
   `import-copilot … --seal EXTERNAL_FILE`. Stage writes a real mode-0600,
   path-free seal (keys: schema_version, mode, driver, copilot, phase,
   `stage_manifest_sha256`, `destination_before_sha256` — confirmed no path in
   the emitted JSON). Import (schema-2 staged) requires the seal, and before any
   mutation checks owner, single link count, non-symlink, schema, roles, mode,
   phase, seal `destination_before` == stage's, and seal `stage_manifest_sha256`
   == sha256 of the actual `stage.json`. Receipts gained `seal_sha256` and the
   receipt schema bumped to 2. Happy independent import succeeded, `seal_sha256`
   in the receipt equaled the seal file hash, and `verify-receipts` passed.

3. **Attack + edge battery against the prototype (O), no receipt minted in any
   refusal:**
   - Laundered `stage.json` (rewritten `destination_before`) → refused
     ("seal destination-before does not match the stage").
   - `stage.json` tampered while preserving `destination_before` (an input hash
     flipped) → refused ("stage.json does not match the sealed manifest hash") —
     the manifest-hash anchor is the general guarantee.
   - Missing seal (flag omitted) → "schema-2 staged import requires --seal";
     removed seal file → "missing protocol entry".
   - Altered seal (manifest hash) → refused; unexpected-key seal → refused;
     non-UTF-8 seal → refused; symlinked seal → refused; hard-linked seal
     (nlink 2) → refused; seal placed inside the co-pilot sandbox tree → refused
     ("seal must be outside the live session and stage-parent sandbox").
   - Replay after a successful import → "receipt already exists … replay refused".

4. **Reciprocal chain (O).** Independent then reciprocal sealed imports produced
   distinct `seal_sha256` values; `reciprocal.destination_before` ==
   `independent.candidate` (chain intact); `verify-receipts` passed; advance to
   `ready-for-execution` succeeded with both receipts.

5. **Backward compatibility (O).** Schema-2 **direct** session refuses staging
   entirely and `verify-receipts` reports no receipts. A hand-built schema-1
   **legacy** session validates, stages and imports **seal-free**, and creates no
   receipts. `digests` lists `receipts/*.json` but not the external seal.

6. **Fail-closed refinement (O).** Initial prototype raised an uncaught
   `FileExistsError` on a pre-existing seal path and left a sealless stage. I
   moved seal location/absence validation ahead of stage creation; now a seal
   inside the co-pilot tree or an already-present seal path is a clean refusal
   that mints **no** partial stage. The valid case then succeeds.

## Critique

- The plan's core claim is confirmed: `stage.json` alone is a co-pilot-controlled
  anchor, and the strong-candidate seal binding its exact bytes closes the
  laundering path before mutation. (O for the attack; I that the manifest-hash
  check subsumes the destination-before check as the general guarantee.)
- The seal binds stage *content*, not stage identity or location: two
  byte-identical independent stages of the same session share a valid seal (O).
  This is harmless — both commit to the same true `destination_before` — but must
  be stated plainly rather than described as per-stage uniqueness.
- Honest limits (I): the seal is not authorship or cryptographic provenance; it
  does not defend a seal the driver places in a co-pilot-writable tree (hence the
  location refusal, which only approximates the co-pilot sandbox as the stage
  parent and cannot know arbitrary other writable paths); and stage+seal are two
  files, so a seal write that fails *after* `stage.json` exists leaves a sealless
  stage that import refuses — not cross-file atomicity.

## Proposed plan changes

- Freeze the strong-candidate enforcement with the fail-closed refinement:
  validate the seal path (location outside session and stage-parent; not already
  present) **before** minting the stage, so a bad seal leaves no partial stage.
- Make `--seal` mandatory for schema-2 staged `stage` and `import-copilot`; leave
  schema-1 legacy and schema-2 direct untouched (seal-free).
- Receipt adds `seal_sha256`; bump `RECEIPT_SCHEMA_VERSION` to 2; extend
  `verify-receipts`/`validate_receipts` and keep `digests` covering receipts only
  (the seal is external by design).
- Document precisely: content-not-identity binding, the co-pilot-tree refusal
  approximation, and the non-atomic stage+seal boundary. Do not overclaim OS
  confinement or crash atomicity.
- Add focused tests for: laundering refusal, manifest-anchor refusal, each seal
  edge case, co-pilot-tree/session-tree refusal at both stage and import, replay,
  reciprocal chain with seals, legacy/direct seal-free paths, and receipt seal
  binding.
