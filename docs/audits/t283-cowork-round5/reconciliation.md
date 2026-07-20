# Reconciliation

## Evidence accepted

Both agents reproduced that current imports leave no durable binding, artifact
receipts are excluded from `digests`, a receipt can bind candidate bytes without
paths, replay can be rejected before mutation, and ordinary receipt-write
failure can restore evidence. Claude's reciprocal hard-crash fixture proved the
driver's key concern: after evidence replacement but before receipt creation, an
unbound independent retry can mint an ambiguous receipt; binding the pre-import
destination hash in stage metadata makes it fail closed. Both accept full raw
state and exact stage-manifest commitments in addition to projected inputs.

Claude withdrew its schema-1 top-level-directory proposal after the real helper
rejected both a stray `receipts/` and an unsupported bare schema bump. Its
schema-2 prototype kept strict schema-1 sessions valid, allowed zero receipts
during schema-2 discussion, and refused a schema-2 ready gate without final
receipt. Its temp+link prototype showed final receipt content is never partial,
while also exposing detectable crash residues and no cross-file atomicity.

The reciprocal protected manifest exactly matches its pre-window manifest. The
independent client-window manifest does not: the driver knowingly authored
`driver-evidence.md` during the window. Only that changed protected hash and all
staged inputs remained fresh, but the window is not called clean. A separately
sealed import window compared clean. Claude correctly declined to endorse
unstaged seal claims and required the actual before/after manifests in future
reciprocal artifacts.

## Disagreements and uncertainty

The driver initially preferred a protected artifacts subtree to avoid a version
bump; Claude's matched compatibility probes support a cleaner closed top-level
directory under explicit schema 2 with schema-1 read compatibility. That wins.
Schema 2 also needs an explicit `exchange_mode`: default `staged` requires
receipts, while exceptional `direct` preserves the documented sealed fallback
without pretending it has a staged import receipt. Schema-1 sessions retain
legacy behavior and never accept `receipts/`.

The receipt's `stage_manifest_sha256` binds exact bytes but does not make a
co-pilot-writable stage authentic. The protocol therefore freezes and stores
the stage-manifest hash outside both stage and co-pilot sandbox before each
client window, compares it after, and only then imports. This round will make
the helper print the manifest hash and include it in the receipt, but will not
add a separate seal-file command; enforcing that external seal is reserved for
another evidence round. This is a recorded residual, not cryptographic
authorship.

Hard power loss between evidence replacement and receipt creation remains
unresolved by rollback. The destination-before binding makes automatic retry
fail closed, and the driver must recover from its committed/preimage evidence.
Temp residues are detectable and require exact reviewed cleanup; the helper
must not sweep them broadly. Concurrent importers are outside the single-driver
protocol and untested.

## Frozen plan

1. Set newly initialized sessions to schema 2 with `exchange_mode=staged` by
   default and an explicit `--exchange-mode direct` fallback. Continue loading
   strict schema-1 sessions/predecessors under their old exact layout. Schema 2
   requires a real closed top-level `receipts/`; schema 1 forbids it.
2. Stage schema 2 records `destination_before_sha256` and prints exact
   `stage.json` SHA-256 for an external driver seal. Import refuses destination
   drift before target mutation. Direct-mode sessions refuse stage/import.
3. For schema-2 staged imports create exactly one receipt per mode, in order.
   Fields are receipt schema, mode, roles, phase, projected input hashes, full
   raw state SHA-256, exact stage-manifest SHA-256, candidate SHA-256,
   destination-before SHA-256, and import timestamp; no paths. Receipt creation
   uses fsynced temp plus same-filesystem atomic link/no-overwrite. On ordinary
   error remove only a receipt created by that invocation and restore exact
   prior evidence. Never claim cross-file crash atomicity.
4. Validate closed receipt layout/content/chain. Add `verify-receipts` comparing
   current live evidence to the latest receipt. Schema-2 staged ready and later
   require both receipts and verification; discussion permits zero, independent,
   or both in order. Schema-2 direct sessions require no receipts. Extend
   `digests` to enumerate existing schema-2 receipt files.
5. Update the skill/protocol: freeze driver evidence before a client window;
   seal live protected bytes and stage-manifest bytes externally; stage actual
   manifests when asking the other agent to verify a deviation; document schema
   compatibility, direct fallback, receipt guarantees, retry stop, and crash
   limits.
6. Add focused tests for legacy layout/predecessor, new staged/direct init,
   receipt order and ready gates, path absence, manifest/destination binding,
   first/reciprocal imports, chain, replay, candidate/receipt/destination drift,
   digest coverage, hard-link/symlink/layout refusal, injected ordinary receipt
   failure and rollback, temp residue detection, and exact external hash output.

Owner go is the original six-hour self-refinement instruction. Only the Codex
driver writes the live target after revalidation; changes stay within the skill,
focused test, ledger, and round evidence. Stop on target drift, ambiguous live
evidence, failed compatibility, or any acceptance gate.

## Acceptance gates

Canonical skill validation, helper/session checks, expanded cowork focused
test, Claude takeover, source contract, public audit, `git diff --check`, and
clean-commit `tests/test-phase1.sh` must pass. Synthetic v1 complete predecessors
must remain valid and a schema-2 staged ready transition without two valid
receipts must fail. Receipt and stage content must contain no tested absolute
path. The final round-5 session is legacy schema 1 because it was created by the
pre-change helper; its evidence and deviation remain valid historical input and
do not retroactively acquire receipts.
