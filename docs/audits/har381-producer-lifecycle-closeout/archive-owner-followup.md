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
one Website root. All twelve legacy clones have an absolute local `origin`
whose canonical path is exactly the proposed durable owner; each durable owner
then has a GitHub origin. Alias creation must require that exact one-hop local
mapping, bind the durable owner's normalized credential-free terminal remote,
and independently read protected main. It must reject relative paths,
symlinks, arbitrary origin chains, basename inference, and directory proximity
as repository identity.

The 28 live source bundles total 377,250,219 bytes and remain durable inputs;
the migration is not bundle compaction. Its cleanup benefit is the separately
measured 490,203,636 bytes occupied by reconstructed sparse roots, subject to
the acceptance checks below.

Add an immutable private alias receipt rather than editing a source receipt.
Store aliases in a dedicated owner-only state directory (`0700`) with
single-link `0600` files, atomic publication, directory fsync, and a schema
that rejects unknown fields. One source receipt has at most one alias.
The alias should bind the source receipt path and digest, legacy repository and
Git common-directory paths, source bundle digest and item tips, durable
canonical owner path and identity, normalized credential-free remote identity,
and a protected-main ref/tip snapshot. Creation must independently restore
every source tip, prove the durable owner is the same repository, re-read the
remote and protected tip immediately before immutable publication, and refuse
mixed repositories, missing objects, mutable source bytes, symlinks,
concurrent protected-main change, or duplicate aliases.

`archive_audit` and generation creation may use the alias only when the legacy
root is absent. They must revalidate the durable owner, source receipt, bundle
or applied compaction, and exact tip set on every call. Existing receipts with
live roots keep the current route. Recovery remains possible from either the
source bundle or verified generations; no alias may weaken the two-generation
compaction rule. A later protected-main fast-forward must remain valid when the
recorded tip is still an ancestor; requiring permanent equality would make an
immutable alias expire during ordinary repository progress. A remote-identity
change, missing recorded tip, rewind, or divergence fails closed.

Use one owner resolver before any `canonical_repo()` call in archive reporting,
generation creation, source audit, and compaction audit; otherwise those routes
would still dereference the absent legacy path before seeing the alias. Archive
reports must count valid and unbound aliases explicitly and retain
`candidates=0` until every source-bound alias and recovery source passes.

## Cleanup acceptance

For each of the twelve reconstructed roots, enumerate every bound receipt,
publish and audit one exact alias per receipt, prove ordinary archive reports
and generation creation with the legacy root temporarily unavailable, then
guarded-remove only that root. Finish with all receipts passing, no uncovered
tip, no incomplete apply, no unbound alias, and no scratch-root archive owner.
Tests must cover wrong remote identity, protected-main change during creation,
post-publication fast-forward acceptance, rewind/divergence refusal, changed
source receipt or bundle, changed/local-origin mismatch, relative or symlinked
local origins, duplicate/mixed aliases, missing generation coverage, unknown
schema fields, unsafe modes/link counts, interruption before and after
publication, report/generation/compaction fallback, and independent restore.
No remote branch, repository content, credential, or hosting setting is part
of this migration.
