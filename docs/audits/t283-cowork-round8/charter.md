# Charter

## Task

Determine whether staged import binds `receipt.seal_sha256` to the exact external
seal bytes structurally validated by `load_seal`, and implement the smallest
descriptor-bound fix only if both agents confirm a real byte-identity gap.

## Boundaries

Codex drives and is the only live target writer. Claude receives only a detached
baseline worktree and sealed stages. Work is limited to the seal reader, its
documentation if semantics change, focused regressions, the ledger, and this
audit. No credentials, external writes, raw recursive deletion, broad refactor,
or unrelated hardening. A static identity gap counts only if an exact execution
trace explains the differing bytes a receipt can bind.

## Baseline and sandboxes

Exact baseline `0620d3eb92f942c72e8972dbe67566db36244c00`. Detached driver
sandbox `/tmp/harness-t283-round8-codex`; detached co-pilot sandbox
`/tmp/harness-t283-round8-claude`. Live exchange is the round-8 audit directory.
Stages are direct children of the Claude sandbox; driver-held seals are below
`/tmp/harness-t283-round8-seals`.

## Acceptance

Both agents must trace all seal path opens/stats/reads and distinguish content
identity from external-location confinement. If fixing, one opened file
description must supply ownership/type/link validation, JSON bytes, and receipt
digest without a path reopen; malformed/non-UTF-8/symlink/hard-link tests and all
existing gates must still pass. Clean full Phase 1 is required after checkpoint.
