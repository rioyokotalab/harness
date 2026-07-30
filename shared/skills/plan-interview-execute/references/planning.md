# Planning phase

Perform safe read-only discovery before asking the owner questions. Inspect the
actual system, repository, and existing evidence so the plan contains facts
and the interview contains only choices that cannot be resolved from evidence.

Write a step-by-step plan to the repository ledger containing:

- desired outcome, scope, non-goals, and authority boundaries;
- confirmed current-state facts, with assumptions clearly separated;
- dependencies, ordering constraints, conflicts, and external blockers;
- numbered execution steps and their exact working surfaces;
- risks, failure modes, safety gates, and rollback or recovery paths;
- validation and acceptance criteria for each material stage;
- a decision register with recommended defaults and consequences;
- checkpoint cadence, interruption behavior, and next executable action.

Do not mutate the target system during planning beyond narrow ledger updates.
Read-only probes and disposable validation that cannot affect the target are
allowed. If discovery reveals a material scope change, checkpoint it and keep
the task in `planning`.

When the plan is coherent:

- if material decisions remain, set `interviewing` and give the owner a compact
  summary of the outcome, stages, risks, and unresolved-decision count;
- if no material decision remains, set `ready-for-go`, record that the
  decision register is complete, and summarize the frozen execution and safety
  gates without creating an interview.

Keep full detail on disk. User-facing updates should expose the outcome and
choices without forcing the owner to reread the plan.
