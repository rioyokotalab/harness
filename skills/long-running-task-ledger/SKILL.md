---
name: long-running-task-ledger
description: Maintain durable state for multi-step, interrupted, multi-session, or long-running work. Use when a repository already declares a task ledger, the user asks Codex to keep going or resume later, or recovery must not depend on chat history.
---

# Long-running task ledger

1. Read the repository's instruction files and declared ledger before acting.
   Reuse its schema and locations; do not impose a competing ledger.
2. Reconstruct the current task, owner, last verified step, working files,
   blockers, and next action from disk and version control.
3. Checkpoint at task start, after each material result or failure, before risky
   or lengthy work, and at session end.
4. Store tasks in the board, immediate execution state in the session file,
   stable facts separately from decisions, and bulky/reproducible evidence in
   artifact paths. Use pointers instead of copying payloads into handoffs.
5. Record exact failure evidence and whether a retry is safe. Never turn an
   uncertain or externally blocked result into a completed task.
6. At handoff, state the next executable command or decision, modified files,
   checks already run, remaining checks, and any authority required.
7. Keep ledgers compact by pruning completed detail only after Git or another
   durable system retains it. Do not create a ledger-only commit when the
   repository requires ledger changes to travel with task work.
