# Charter

## Task

Use Codex as driver and Claude as blinded staged co-pilot to determine whether
`import-copilot` should create a durable driver-held receipt, then implement
only the evidence-supported refinement to `codex-claude-cowork`.

## Boundaries

The live target is `/home/rioyokota/harness` on branch
`task/t-283-codex-claude-cowork`. Only the Codex driver may edit it after the
plan is frozen. Claude writes only inside its detached sandbox and staged
candidate. No credentials, settings, packages, services, remotes, external
messages, destructive raw cleanup, or unrelated repository content are in
scope. Receipt content must be public-safe and must not disclose live or stage
absolute paths.

## Baseline and sandboxes

The immutable common baseline is commit
`f87b019836ad5c5ed4cb9c85ac409d47484e06f2`. Independent no-hardlink detached
clones are `/tmp/harness-t283-round5-codex` and
`/tmp/harness-t283-round5-claude`. The live exchange is this directory and its
validated predecessor is round 4 at `complete`.

## Acceptance

Both agents must run actual matched probes for post-import candidate mutation,
receipt tampering/detection, replay, disclosure, and a receipt-write failure.
The reconciliation must choose exact receipt location, schema, protection,
creation order, and retry semantics. The driver must add focused adversarial
tests and pass the canonical skill validator, cowork focused suite, Claude
takeover, source contract, public audit, `git diff --check`, and finally the
clean-commit Phase 1 suite. Sandboxes remain until guarded cleanup.
