# Cowork evidence and staged exchange

Read this file completely before independent or reciprocal evidence, staging,
monitoring, import, reconciliation, or advancement to `ready-for-execution`.

## Independent and reciprocal evidence

Use two independently writable sandboxes from the same immutable baseline.
Permit network, package installation, schedulers, remote writes, or messages
only when the owner's frozen task independently authorizes them and a local
experiment cannot answer the question.

Give both clients the charter, plan, baseline, benchmark, and acceptance gates,
but withhold the other's conclusions until both independent passes finish.
Each evidence file must identify its sandbox and baseline, record commands or
tool actions and bounded results, separate observation from inference,
criticize concrete plan claims, and propose exact plan changes. A prose-only
review is insufficient when a safe experiment is feasible.

Freeze `driver-evidence.md`, take a protected digest manifest, and make no
driver-owned live write during the co-pilot window. After both independent
passes, reveal both evidence files through a new reciprocal stage and require
the co-pilot's complete evidence plus critique. Resolve the strongest conflict
with a matched test or keep it explicitly unresolved.

## Stage and seal

Each stage must be a direct child of the co-pilot sandbox and outside the live
session. Keep its external seal outside the live session, stage-parent sandbox,
and every co-pilot-writable tree:

```text
scripts/cowork-session stage SESSION_DIR STAGE_DIR --mode independent \
  --prompt DRIVER_PROMPT_FILE \
  --seal EXTERNAL_SEAL_FILE
scripts/cowork-session stage SESSION_DIR STAGE_DIR --mode reciprocal \
  --prompt DRIVER_PROMPT_FILE \
  --seal EXTERNAL_SEAL_FILE
```

The staged `state.json` is a fail-closed path-free projection. It drops
`predecessor.path`, refuses unknown or missing keys, and is used for the later
freshness comparison. Schema-3 stages bind the bounded UTF-8 prompt copied to
`artifacts/copilot-prompt.md`; do not add or replace that prompt after sealing.

Before invoking the co-pilot, retain the printed `stage_sha256` outside the
stage, session, and sandbox. The mode-0600 external seal binds the exact
`stage.json` SHA-256 as `stage_manifest_sha256` plus roles, mode, phase, and
destination-before digest.
It binds bytes, not authorship, path identity, OS confinement, or cross-file
atomicity. A failed seal write leaves an import-refused stage; inspect it and
start with a fresh stage and seal rather than relaundering it.

## Monitor and import

The driver may observe a long co-pilot window with:

```text
scripts/cowork-session status SESSION_DIR --stage STAGE_DIR \
  --seal EXTERNAL_SEAL_FILE --pid COPILOT_PID
scripts/cowork-session wait-copilot SESSION_DIR --stage STAGE_DIR \
  --seal EXTERNAL_SEAL_FILE --pid COPILOT_PID \
  --timeout-seconds CLIENT_BUDGET_SECONDS
```

`status` and `wait-copilot` are read-only and advisory. Candidate state, input
freshness, destination freshness, their
`stage.mechanical_import_preconditions.all_satisfied` conjunction, PID
reachability, and process loss never authorize import or prove authorship,
semantic progress, correctness, or success. Do not rename or treat this
observation as `import_ready`.

After the native process exits, compare protected and stage seals, inspect the
complete candidate, and import only with:

```text
scripts/cowork-session import-copilot SESSION_DIR STAGE_DIR \
  --seal EXTERNAL_SEAL_FILE
scripts/cowork-session verify-receipts SESSION_DIR
```

For schema-2+ staged sessions, import must fail before live mutation unless the
seal, stage, roles, mode, phase, owner, link count, non-symlink identity,
destination-before digest, projected inputs, prompt, schema, required headings,
UTF-8 and size bounds all match. Retain stage and seal evidence for recovery.

Import atomically replaces only `copilot-evidence.md` and creates one ordered
receipt for each independent and reciprocal import. Receipts bind projected
inputs, full live state, exact stage metadata, destination-before bytes,
external seal digest, accepted candidate, and roles without storing paths.
`verify-receipts` checks the stored seal hash and receipt/evidence chain; it
does not reopen the external seal. Receipt creation and evidence replacement
are not cross-file crash atomic. A crash can leave ambiguous evidence or a
detectable temporary/receipt; stop for reviewed exact recovery and do not
blindly retry.

Projection freshness does not detect a withheld-field-only change or
representation-only reserialization. Protect full raw `state.json` and all
driver-owned files with `scripts/cowork-session digests SESSION_DIR` plus a
recoverable preimage. Hashes detect change but do not prevent it or restore
bytes.

## Reconcile

Prefer reproducible matched observations, then primary repository contracts,
deterministic static analysis, explicit inference, and finally unsupported
opinion. Preserve minority evidence. If disagreement affects safety, scope,
correctness, irreversible state, or acceptance, resolve it empirically or ask
the owner before execution.

The frozen reconciliation must record ordered target steps, the sole
target-writing role, accepted and rejected changes, unresolved uncertainty,
preconditions, rollback, stop conditions, authority boundaries, per-step and
final checks, owner go status, and exact next action. Do not execute by
majority vote.
