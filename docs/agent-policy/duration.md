# Duration policy

Read this file completely before work with an explicit duration, deadline, time
window, overnight run, or instruction to keep iterating.

- Use both `codex-claude-cowork` and `long-running-task-ledger`. Freeze the
  benchmark, evidence cadence, and stop conditions before target execution.
- The final and durable summaries each contain exactly one evidence-backed
  slice per requested hour, rounded up, and at least
  `max(300, 50 * ceil(requested hours))` words.
