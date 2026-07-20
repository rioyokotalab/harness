# Charter

## Task

Perform a final release-candidate audit of `codex-claude-cowork` by using the
skill itself with Codex as driver and Claude as co-pilot. Determine whether the
schema-2 external-seal workflow and phase instructions are symmetric, usable,
and fail closed, and make only evidence-justified fixes.

## Boundaries

The live target is this harness checkout. Discussion may write only the round-7
exchange and the two disposable worktrees. Neither agent may access credentials,
external services, or unrelated private data. Claude receives only its worktree
and staged exchange, not the live session. No raw recursive cleanup is allowed.
Only Codex may edit the live skill after reconciliation and after the session is
advanced to `executing`. Do not add features merely because they are possible;
retain documented residuals when the proposed cure is less reliable or usable.

## Baseline and sandboxes

Immutable baseline is Git commit
`4c3602d586fb5d7225f516aa15677a2b6fa1384b` (abbreviated `4c3602d`). Driver
sandbox: `/tmp/harness-t283-round7-codex`. Co-pilot sandbox:
`/tmp/harness-t283-round7-claude`. Both are detached Git worktrees created from
the same baseline. The live exchange is `docs/audits/t283-cowork-round7/`.
Each stage will be a direct child of the Claude sandbox, with its external seal
under `/tmp/harness-t283-round7-seals/`.

## Acceptance

Both agents must run concrete, bounded experiments or static traces against the
helper and tests. They must address: external-seal creation/import lifecycle;
retained-seal verification ergonomics; phase-order enforceability; compatibility
and path-free artifacts; and Codex/Claude role symmetry. The final reconciliation
must classify each issue as fix now, document, or reject with evidence. Any live
change must pass the focused cowork test, source-contract, takeover,
public-repository audit, `git diff --check`, and clean full Phase 1 suite. A
no-code conclusion is acceptable only with explicit evidence.
