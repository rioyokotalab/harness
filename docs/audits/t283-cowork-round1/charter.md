# Charter

## Task

Use version 1 of `codex-claude-cowork` to find and empirically demonstrate
defects in its own symmetry, file protocol, sandbox safety, client mapping, and
validation claims, then freeze a minimal revision plan.

## Boundaries

Codex is driver and Claude is co-pilot. During discussion, each may write only
its independent `/tmp/harness-t283-round1-{codex,claude}` clone and its owned
evidence file under this exchange directory. Neither may change the live target,
Git refs, credentials, client settings, packages, remote systems, or external
messages. Native client output may be retained only as public-safe bounded text
under this session. The owner already authorized driver execution after the
plan is frozen.

## Baseline and sandboxes

Both sandboxes are local no-hardlink clones detached at immutable commit
`35ed1db478df4f15471fced4dfc1279f678e462d`. The live target is `~/harness` on
branch `task/t-283-codex-claude-cowork`. The exchange directory is
`docs/audits/t283-cowork-round1`. Cleanup of the two clone trees must use
`guarded-bulk-delete`; the tracked exchange record is retained.

## Acceptance

Both agents must run tests rather than provide prose alone, identify facts
separately from inferences, and challenge at least one specific protocol claim.
Reconciliation must preserve disagreements and freeze exact edits. Driver-only
execution must then pass the canonical skill validator, the cowork focused test,
Claude takeover, source contract, public-repository audit, `git diff --check`,
and the full `tests/test-phase1.sh` suite without weakening safety boundaries.
