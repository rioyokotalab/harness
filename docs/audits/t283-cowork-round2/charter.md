# Charter

## Task

Use version 2 of `codex-claude-cowork` (the post-round-1 skill at commit
`7df5f7d`) to find and empirically demonstrate the strongest *remaining* defects
in its symmetry, sandbox/exchange safety, takeover contract, and native client
invocation, then freeze a minimal, reviewed revision plan. Round 1 already
closed symlinked/foreign-owned protocol entries, the exact top-level set, the
misordered Codex approval flag, and the over-broad `TODO` regex; round 2 must
not re-litigate those and must honestly report where v2 is already sound.

## Boundaries

Claude is driver and Codex is co-pilot. During discussion each client may write
only its own immutable-baseline no-hardlink clone
(`/tmp/harness-t283-round2-claude` for the driver,
`/tmp/harness-t283-round2-codex` for the co-pilot) and its owned evidence file
under this exchange directory. Codex is explicitly blinded from
`driver-evidence.md` until its independent pass finishes; the driver never
hands Codex the live target. Neither client may change the live target, Git
refs, credentials, client settings, packages, remotes, schedulers, or external
systems. Native co-pilot output is retained only as public-safe bounded text
under `artifacts/`. The owner's original T-283 instruction is the explicit go
for driver execution once the plan is frozen; a new material choice returns to
owner review.

## Baseline and sandboxes

Both sandboxes are local no-hardlink clones detached at the immutable commit
`7df5f7d2bb8b199c51fd87f00d43467c12b8073e` (harness v2 of the skill). The live
target is `/home/rioyokota/harness` on branch `task/t-283-codex-claude-cowork`,
clean with only this exchange directory untracked. The exchange directory is
`docs/audits/t283-cowork-round2`. Any removal of the four round sandboxes or
throwaway probe trees must use `guarded-bulk-delete`; the tracked exchange
record is retained.

## Acceptance

Both clients must exercise the validator and native mappings in their own
sandbox rather than argue from prose, separate observed facts from inferences,
and challenge at least one concrete v2 claim. Reconciliation must preserve
disagreement and freeze exact edits confined to the live skill, protocol,
deterministic helper (`scripts/cowork-session`), focused test, round-2 exchange
files, and the T-283 ledger. Driver-only execution must then pass the canonical
skill validator, the cowork focused test, `tests/test-claude-takeover.sh`,
`tests/test-source-contract.sh`, `tests/test-public-repo-audit.sh`,
`git diff --check`, and the full `tests/test-phase1.sh` suite with no weakened
safety gate.
