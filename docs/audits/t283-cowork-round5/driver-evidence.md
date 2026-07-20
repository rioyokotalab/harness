# Driver evidence

## Sandbox and baseline

Codex used `/tmp/harness-t283-round5-codex`, a clean detached no-hardlink clone
of `f87b019836ad5c5ed4cb9c85ac409d47484e06f2`. It created only disposable
`receipt-probe.py` and `r5-current/` content in that sandbox. The live target was
not edited. Bounded results are in `artifacts/driver-probe-log.md`.

## Commands and results

Observed: `python3 receipt-probe.py` created a path-free receipt binding the
candidate, pre-import evidence, projected staged inputs, full state commitment,
and stage manifest. Removing the final newline from the candidate after import
left both live evidence and the receipt's candidate hash valid. A second import
was rejected because the receipt existed. An injected failure after evidence
replacement but before receipt creation restored exact old evidence and left no
receipt.

Observed: current `cowork-session digests r5-current` was byte-identical before
and after an `artifacts/import-receipt.json` appeared. Current artifacts are
deliberately excluded from protection, so merely placing a receipt there adds
provenance but not driver-held tamper detection. Current exact top-level layout
also means a new top-level directory needs explicit version/backward-
compatibility handling.

Inference: the importer can provide process-failure rollback, not literal
cross-file crash atomicity. A crash after evidence replacement and before
receipt creation must be detectable on retry. Binding the destination's
pre-import hash in stage metadata would let retry fail closed instead of silently
minting a receipt from an already-changed destination.

## Critique

The initial plan under-specified schema evolution. Requiring two receipts at
`ready-for-execution` would invalidate complete v1 predecessors unless the
helper supports both old and receipt-aware sessions. Storing receipts under
shared artifacts is viable only with a closed, validator-owned subdirectory
that `digests` includes; calling all artifacts driver-owned would break the
existing shared-artifact contract. A printed hash alone is not a durable file
contract, but a receipt within the mutable co-pilot stage is equally weak.

The prototype's `O_EXCL` receipt write is not sufficient by itself because a
mid-write failure can leave partial bytes. Production should prepare and fsync a
temporary receipt on the session filesystem, atomically create the final name
without overwrite, fsync the directory, and remove the exact temporary on
failure. Rollback must remove only a receipt whose exact intended bytes were
created by this invocation, then restore evidence.

Protocol deviation: the driver wrote this evidence file while the independent
Claude process was still running. The client-window seal therefore differs in
exactly this known file and cannot be called clean; details and hashes are in
`artifacts/seal-deviation.md`. All staged inputs and other protected entries
stayed unchanged, and a fresh seal around validation/import compared clean. The
reciprocal window must begin only after this evidence is frozen, with no live
driver-file edits until its post-client seal.

## Proposed plan changes

1. Prefer a closed `artifacts/import-receipts/` subtree over a new top-level
   directory only if receipt-aware sessions can be distinguished from legacy
   sessions and `digests` covers each exact receipt file. Otherwise bump the
   session schema and explicitly support v1 predecessors.
2. Add `destination_before_sha256` to staged metadata so replay and crash retry
   refuse before live mutation. Receipt fields should be schema, mode, roles,
   import time, full state commitment, exact stage-manifest hash, staged input
   hashes, destination-before hash, and candidate/destination-after hash; never
   store session or stage paths.
3. Allow exactly one independent then one reciprocal receipt. Receipt-aware
   `ready-for-execution` and later phases require both; a reciprocal stage/import
   requires a valid independent receipt. Mutation is a validation/digest stop.
4. Implement atomic-new receipt creation plus best-effort transactional rollback
   of evidence on ordinary process errors. Document the unclosable crash/TOCTOU
   window and fail closed on destination-before mismatch.
5. Test legacy predecessor compatibility, current-schema phase rules, replay,
   receipt tamper, candidate drift, destination drift, path absence, pre-existing
   receipt, injected receipt failure, exact temp cleanup, and digest coverage.
6. Require reciprocal critique of the location/version disagreement: Claude's
   prototype selects a closed top-level `receipts/`, while the driver notes that
   legacy complete sessions lack it. The frozen plan must explicitly version or
   compatibly gate the new layout rather than invalidating round-1–4 provenance.
