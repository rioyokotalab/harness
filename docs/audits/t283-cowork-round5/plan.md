# Initial plan

## Confirmed facts and assumptions

Round 4 proved that both co-pilot candidates could drift after successful
import while live evidence remained intact. The independent import was later
recoverable from a reciprocal input hash; the final reciprocal candidate was
bound only by the importer's printed hash and current live evidence. A stage is
co-pilot-writable and cannot itself serve as a driver-held receipt. This plan
assumes a receipt is useful only if it is path-free, deterministic in meaning,
created by the importer, failure-atomic with destination restoration, protected
by `digests`, and validated during later phases.

## Steps

1. Reproduce v4 candidate drift and inventory the exact facts already available
   at import: roles, mode, projected input hashes, full live-state hash, stage
   manifest hash, candidate hash, previous and resulting evidence hashes.
2. Independently prototype two narrow designs in the Codex sandbox: a receipt
   below shared `artifacts/`, and a closed top-level driver-owned `receipts/`
   directory whose exact files become protected digest inputs. Exercise first
   import, reciprocal import, replay, candidate mutation, receipt mutation,
   pre-existing receipt, unwritable receipt destination, and absence of paths.
3. Blind Claude to driver conclusions through an independent stage in its
   sandbox. Require matched probes and an exact schema/transaction proposal;
   import its validated candidate, then reveal both evidence files through a
   reciprocal stage and require critique of the strongest disagreement.
4. Reconcile evidence. Freeze the smallest design that adds a durable binding
   without claiming multi-file atomicity or cryptographic authorship. Reject the
   change if its integrity gain depends on the mutable stage or creates
   ambiguous retry state.
5. Advance through the owner-authorized execution phases. Modify only the skill,
   helper, protocol, focused test, round evidence, and ledger. Independently
   validate, checkpoint, run clean Phase 1, complete, and guarded-clean.

## Evidence questions

- Which receipt fields are necessary to prove exactly which candidate and
  staged inputs were accepted without storing private paths?
- Can the receipt be created exactly once per mode and included in protected
  digests without preventing the first import?
- On receipt creation failure, are live evidence bytes restored and temporary
  receipt files absent? Is a retry unambiguous?
- Does a pre-existing or mutated receipt stop replay without changing live
  evidence? Does candidate drift after import leave the receipt unchanged?
- Must receipt validation be phase-dependent so planning/discussing sessions
  can initially have zero or one receipts while ready phases require both?

## Risks and recovery

Cross-file atomicity cannot be literal across evidence and receipt; the helper
must use rollback and clearly state crash/TOCTOU limits. A fail-closed closed
layout can impose forward-compatibility costs. All probes are disposable local
copies. Stop on target drift, protected-digest mismatch, ambiguous partial
write, co-pilot failure without retry-safe evidence, or a material authority
choice. Preserve stages and receipts until committed; cleanup uses guarded
deletion.
