# Duration policy

Read this file completely before work with an explicit duration, end time/date,
time window, overnight run, or instruction to keep iterating.

- Use `long-running-task-ledger`. Freeze the objective, benchmark, evidence
  cadence, cutoff, and stop conditions before target execution. A second
  client is optional and must be independently selected by the task.
- The final and durable summaries each contain exactly one evidence-backed
  slice per requested hour, rounded up, and at least
  `max(300, 50 * ceil(requested hours))` words.
