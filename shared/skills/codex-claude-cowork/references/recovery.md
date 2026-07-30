# Cowork recovery and role transfer

Read this file completely before recovering an interrupted session, using
direct exchange, transferring driver role, or retrying an ambiguous client
window.

## Protect live state

Before every co-pilot window, run:

```text
scripts/cowork-session digests SESSION_DIR
```

Store the manifest outside both `SESSION_DIR` and the co-pilot sandbox and
retain a recoverable preimage. The digest set covers full `state.json`,
driver-owned Markdown, and existing receipts while excluding
`copilot-evidence.md` and shared artifacts. Freeze `driver-evidence.md` before
the pre-window seal and make no driver-owned live write during the window.
After return, compare digests before import. Any protected change is a stop
condition requiring owner review. Hashes detect change; they do not prevent it
or restore bytes.

Staged exchange is the default. A direct `--add-dir SESSION_DIR` grant exposes
the whole live exchange to same-user writes; mode 0600 and read-only mode are
only advisory tripwires. Use direct exchange only when a recorded frozen
experiment cannot use staging, initialize it explicitly with
`--exchange-mode direct`, and apply the same external digest plus recoverable
preimage. Never switch an existing staged session to direct merely to bypass a
failed stage, seal, import, or receipt gate.

## Resume or transfer

For same-role process recovery, validate the repository ledger, target state,
session phase, required files, receipts, stages, seals, and last verified
action. Resume the first unverified action in place; do not replay an ambiguous
operation.

Cross-product role transfer changes file ownership and execution authority. It
requires an explicit owner instruction and a new session beginning at
`planning`; it cannot resume the predecessor phase. Initialize provenance with:

```text
scripts/cowork-session init NEW_DIR --driver ROLE --predecessor OLD_DIR
```

The helper validates the predecessor's phase-required content before creating
the successor and records its path, driver, phase, and validated state digest.
This records current protocol completeness, not historical authorship or a
transactional snapshot. Never infer target authority from the predecessor.

A client failure is retry-safe only when the sandbox, stage, seal, receipts,
owned files, and target prove that no ambiguous partial action occurred.
Record the exact error, touched state, and retry precondition. Absent output,
process loss, timeout, or advisory candidate readiness is not success.
