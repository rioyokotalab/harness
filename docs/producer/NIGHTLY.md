# Harness nightly producer protocol

Read this file only for an owner-started nightly or duration-bounded portfolio
run. The first two runs remain owner-started; this file does not authorize a
scheduler, daemon, deployment, external message, credential operation, or
consumer mutation.

1. Metadata-check active repository work; never inspect pane or transcript
   content. If another agent is active or unknown, use an isolated worktree and
   avoid overlapping paths instead of treating its role as a hard stop.
2. Fetch protected Git state and inventory branches, worktrees, pull requests,
   and temporary residue. Read this repository's producer index, open receipts,
   active consumer board, and only routed evidence.
3. Run the public-content check: `tests/test-public-repo-audit.sh`. Never move private repository
   payloads into a public report or use them as a comparison corpus.
4. Measure always-read bytes, routed bytes, command count, wall time, and
   validation cost. Compact ledgers or skills only when equivalent capability
   checks pass and measured time or token cost improves.
5. Preserve existing goals and gates. The producer normally curates durable
   goals. A consumer may create, cancel, or reprioritize one when necessary for
   an in-scope solution, with fresh reconciliation and a recorded rationale.
6. Run `python3 tools/producer-ledger.py validate --require-converged`, then
   validate and publish this repository independently through its native
   protected workflow. One blocked repository must not hold another's branch,
   worktree, or ledger.
7. Use guarded cleanup for recursive or multi-path residue. Finish with clean
   protected main, no task worktree or branch residue, and a value-free receipt.
