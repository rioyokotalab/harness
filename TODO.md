# Personal harness task board

This is the authoritative active queue. Read it completely at cold start, then
read only the linked record for the selected task. Completed chronology is
indexed by `docs/tasks/index.tsv`; do not preload the historical snapshot.

Next free ID: T-366.

## Resume contract

1. Read root `AGENTS.md` and this board.
2. Select the first executable task, then read its linked task record and only
   the evidence routed by that record.
3. Confirm branch, worktree, recent commits, ownership, and mutable inputs.
4. Resume the first unverified recorded action; preserve unrelated work.
5. A failed mutable-state query is unknown, never evidence of absence.

## Active queue

### T-363 — Workspace lifecycle for alternating clients

**Phase:** proposal; awaiting an owner decision between per-turn worktrees and
the same plus an observability lease, and on the enforcement surface. Nothing
implemented.

**Record:** `docs/tasks/T-363.md`.

### T-354 — Relocate repository-native Codex roots under `projects`

**Phase:** blocked until the live checkout occupying the exact Students
destination is retired; no direct rename is safe.

**Record:** `docs/tasks/T-354.md`.

### T-196 — Backup lifecycle phase 2

**Phase:** time-gated until 2026-08-02; all eight chains are 2/8.

**Record:** `docs/tasks/T-196.md`. Do not query or mutate a successor early.

### T-328 — Complete the deferred Local reboot

**Phase:** time-gated to the 2026-08-08–09 Institute outage.

**Record:** `docs/tasks/T-328.md`. Do not infer that contingency dates apply.

### T-303 — Observe intermittent NFS I/O latency

**Phase:** blocked on trusted administrator or console verification.

**Record:** `docs/tasks/T-303.md`. Do not retry the unverified network path.

## Completed-task lookup

The exact pre-T-351 board is preserved at
`docs/history/TODO-full-archive-2026-07-30.md`. Use
`docs/tasks/index.tsv` to locate one completed task's plan or evidence; chat
history and client memory are never authoritative.
