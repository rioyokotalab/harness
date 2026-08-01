# T-373 archive retention inventory — 2026-08-02

## Current report

`harness housekeeping --plan --routine archives --repo
/home/rioyokota/harness` is report-only and creates no plan or other durable
state. It audits every receipt and bundle before classifying metadata, derives
each owning repository from the receipt, and fails closed on unknown repository,
object, protected-main, pull-request, or ledger evidence.

The first live report found:

- 20 valid receipts, 45 item refs, and 39 unique tips;
- 283,188,738 bytes of receipt-bound Git bundles inside a 421,791,676-byte
  housekeeping state;
- 7 archive-only items with no containing normal local or remote ref;
- 20 pull-request items whose archived head tree exactly equals the recorded
  merge tree, with zero unknown or different comparisons;
- 29 item refs named by an exact tip, transaction, or receipt in protected-main
  Harness/owner ledger paths; 16 have no such tracked ledger match and zero are
  unknown;
- 48 individually validated plan records, 58 guarded manifests, and 9 valid
  completed worktree-apply states, with zero incomplete apply transaction;
- 4 unbound legacy bundles and 5 compressed evidence payloads, all preserved as
  unknown/evidence rather than inferred disposable;
- 124 auxiliary rows with age and exact Harness-ledger matching: 4 referenced,
  120 unreferenced, and zero unknown;
- zero deletion candidates and no apply route.

The report emits one value-free row per receipt and item: repository,
transaction, branch, tip, protected-main ancestry, count of containing normal
refs, archive-ref/bundle availability, PR-tree equivalence, and exact ledger
reference status. Auxiliary rows map every plan, manifest, apply state, unbound
bundle, and compressed evidence payload by relative name, identity, size, and
value-free status. It never emits source payloads or Personal values. An item
available only from its archive ref/bundle remains independently protected even
when a merge tree is equal.

The report also measures the complete state tree and evaluates the frozen
generation triggers. After exact Website T-214 closeout, the current readback
is 609,907,224 bytes, 24 receipts, oldest receipt below one day, zero generation
receipts, and `generation_trigger=bytes`.

## Measured consolidation opportunity

A temporary benchmark bundled protected Harness `main` plus all 39 then-live
Harness archive refs. `git bundle verify` passed at 12,988,438 bytes, compared
with 184,262,769 bytes across the 16 then-current Harness-history bundles:
171,274,331 bytes / 92.9% smaller. The benchmark was guarded-deleted and all
real receipts, refs, and bundles remained unchanged. The subsequent exact
T-369 and T-373 closeouts advanced the live state to 17 Harness-history bundles
and 223,552,356 bytes, confirming that per-task full-history packing is the
growth source.

## Frozen phase-one decision

Adopt report-first generational compaction; reject age-, size-, ancestry-, or
tree-equivalence-only deletion. A future generation may supersede individual
bundles only when it includes protected `main` plus every retained exact tip,
has an immutable receipt and digest, restores successfully into an independent
bare repository, and leaves the previous verified independent generation
intact. Archive-only, unpublished, ledger-referenced, incomplete, unknown, and
newest-generation evidence is never a deletion candidate.

Evaluate generation creation when state exceeds 512 MiB, receipt count exceeds
30, or the oldest complete receipt reaches 30 days. Deletion remains disabled
until two independently verified generations exist and a fresh report proves
that removing an exact older generation preserves every required tip, ledger
reference, rollback, and interrupted-closeout path. Current state meets none of
those deletion gates. The state is now about 582 MiB, so first-generation
creation is due; deletion remains rejected because zero prior verified
generation exists.

## Generation receipt and restore contract

`harness-housekeeping-generation-v1` is deliberately audit-only. One immutable
mode-0600 JSON receipt binds a unique generation ID and creation time, every
source receipt name and SHA-256 digest, and one row per owning repository. A
repository row binds the canonical path and filesystem identity, the exact
protected `refs/remotes/origin/main` tip, one sibling mode-0600 bundle and its
digest, the complete unique head set, and a restore proof.

The restore proof uses `independent-bare-fetch-exact-heads-v1`: initialize a
new bare repository outside the source, fetch every generation head from the
bundle, compare every restored ref to its expected tip, and only then record
the verification time and deterministic SHA-256 digest of the sorted head set.
Inventory independently rechecks receipt and bundle identity, source receipt
digests while those receipts exist, repository identity, bundle verification,
the exact bundle head set, inclusion of protected main, and the restore-proof
digest. Missing source receipts may eventually be valid after a later guarded
compaction, so their names and digests remain bound even when their files do
not; any existing source receipt must still match exactly.

The focused test creates a synthetic bundle, restores it into an independent
bare repository, verifies protected main and a retained non-main tip, publishes
the receipt only after that success, and proves report-mode re-audit. Production
inventory creates no generation, plan, or delete candidate. This keeps the
mechanism testable now without spending recovery redundancy before a measured
trigger.

## Report efficiency follow-up

Ledger matching now batches fixed-string patterns once per receipt and once for
the auxiliary inventory, while still emitting only the matched identifier and
never source context. Each owning repository's refs are also snapshotted once,
eliminating redundant per-item object and archive-ref probes without weakening
the bundled-only fallback. The exact live summary remained 22 receipts, 47
items, 41 unique tips, 29 ledger references, zero unknowns, and zero candidates.
A same-state sequential read measured the protected-main implementation at
24.32 seconds and the optimized implementation at 18.50 seconds, a 23.9%
wall-time reduction. This is a bounded improvement to an occasional report;
the report remains read-only and is not promoted into a frequent polling loop.
