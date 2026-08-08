# Harness nightly task ledger

This is the sole nightly ledger for the five-project portfolio. Read it only
for an owner-started nightly or duration-bounded run, or when the owner asks to
put work in the nightly ledger. Personal, Students, Swallow, and Website do not
run nightly agents; Harness may inspect their value-free metadata and update
their ordinary repository-local ledgers when needed.

Unless the owner specifies another cutoff, every nightly runs until 09:00
Asia/Tokyo on the morning following its start.

Next free ID: Nit-003.

When the owner says to add something to the nightly ledger, allocate the next
`Nit-NNN` here and under `docs/nightly/`; do not create a `Har-*` task. Keep
private sibling values in that sibling's repository, never in this public
ledger. Run `python3 tools/harness-ledgers.py validate` after every change.

## Run contract

1. Record the requested duration, cutoff, scope, and next action in one
   `docs/nightly/tasks/Nit-NNN.md` record before lengthy work.
2. Reconcile protected Git state, active work, branches, worktrees, pull
   requests, and temporary residue without reading pane or transcript content.
3. Audit public exposure for Harness and Website. Use only value-free metadata
   when evaluating private repositories.
4. Prefer already-recorded useful work; never invent tasks merely to consume a
   duration. Record skipped, gated, exhausted, and completed outcomes.
5. Measure time, tokens, command count, and validation cost. Compact policy or
   skills only with equivalent behavior evidence and measured improvement.
6. Publish each affected repository independently through its protected route;
   one blocked repository never holds another's ledger or worktree.
7. Finish with converged ledgers, clean protected main branches, guarded
   cleanup, and an exact resumable checkpoint or terminal result.

This ledger grants no scheduler, daemon, deployment, external message,
credential, private-source, compute, or destructive authority by itself.

## Active queue

| Task | State | Priority | Record |
| --- | --- | ---: | --- |
| Nit-002 | active | 20 | `docs/nightly/tasks/Nit-002.md` |
| Nit-001 | ready | 10 | `docs/nightly/tasks/Nit-001.md` |

## Completed lookup

Use `docs/nightly/index.tsv`; completed chronology does not remain on this
active board.
