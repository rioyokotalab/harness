# Archive-owner migration follow-up

## Demonstrated problem

Worktree archive receipts are immutable and correctly bind the Git common
directory that owned their archive refs. When that owner is a full clone under
a scratch root, removing the final clone also removes the pathname and object
identity needed by `archive_audit` and generation creation. The private bundle
still protects every recorded tip, but the formal audit route fails before it
can use that bundle. Har-381 reconstructed twelve exact roots and now prevents
new scratch-root owners; it does not rewrite historical receipts.

## Smallest durable migration

The bounded legacy set is twelve reconstructed roots bound by 28 receipts.
Each receipt contains one tip, and all 28 source bundles are still present;
none currently depends only on a retired-bundle compaction. Migration can
therefore prove aliases against the immutable source bundle first, while still
testing and preserving the existing generation and compaction recovery route.
All 28 are archive-v2 receipts with canonical repository identity and exact
Git common-directory fields, so this migration needs no legacy-schema guess or
source-receipt rewrite.

The durable-owner mapping is bounded to four already-declared canonical
repositories: one Personal root, five Students roots, five Swallow roots, and
one Website root. Alias creation must derive that mapping from normalized
remote identity and independently read protected main; basename or directory
proximity is never sufficient evidence of repository identity.

The 28 live source bundles total 377,250,219 bytes and remain durable inputs;
the migration is not bundle compaction. Its cleanup benefit is the separately
measured 490,203,636 bytes occupied by reconstructed sparse roots, subject to
the acceptance checks below.

Add an immutable private alias receipt rather than editing a source receipt.
The alias should bind the source receipt path and digest, legacy repository and
Git common-directory paths, source bundle digest and item tips, durable
canonical owner path and identity, normalized credential-free remote identity,
and protected-main ref and tip. Creation must independently restore every
source tip, prove the durable owner is the same repository, and refuse mixed
repositories, missing objects, mutable source bytes, symlinks, or duplicate
aliases.

`archive_audit` and generation creation may use the alias only when the legacy
root is absent. They must revalidate the durable owner, source receipt, bundle
or applied compaction, and exact tip set on every call. Existing receipts with
live roots keep the current route. Recovery remains possible from either the
source bundle or verified generations; no alias may weaken the two-generation
compaction rule.

## Cleanup acceptance

For each of the twelve reconstructed roots, enumerate every bound receipt,
publish and audit one exact alias per receipt, prove ordinary archive reports
and generation creation with the legacy root temporarily unavailable, then
guarded-remove only that root. Finish with all receipts passing, no uncovered
tip, no incomplete apply, no unbound alias, and no scratch-root archive owner.
Tests must cover wrong remote identity, changed protected main, changed source
receipt or bundle, duplicate/mixed aliases, missing generation coverage,
interruption, and independent restore. No remote branch, repository content,
credential, or hosting setting is part of this migration.
