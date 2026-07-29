# Initial plan

## Confirmed facts and assumptions

- Students nightly findings D-016 and D-017 remain unresolved: task scopes do
  not constrain native tools, and saved sessions are keyed only by project.
- A completed task's authority must not flow into a different task.  The
  conservative candidate policy is per-task session identity.
- `analysis` and `planning` are read-only.  `code_preparation` and
  `experiment_preparation` authorize project-local preparation writes.
  `compute_execution` is separately gated and does not grant project writes.
- Harness project Claude settings currently omit model and effort defaults.
  The installed Claude Code 2.1.220 accepts `fable` and `--effort high`.
- The current cowork protocol requires independent and reciprocal evidence but
  does not require a benchmark before discussion.

## Steps

1. Freeze the benchmark and obtain independent Claude critique using Fable at
   high effort.
2. Run reciprocal evidence: Codex records its own measurements and Claude
   challenges them against the same benchmark.
3. Reconcile scope semantics, per-task session behavior, migration
   compatibility, and deterministic duration-summary scaling.
4. Let Claude implement candidate changes and tests in its detached sandboxes,
   iterating on observed failures.
5. Codex reviews the candidate and applies the smallest accepted changes to
   the Students T-035 and Harness T-342 target worktrees.
6. Run focused and full offline gates until every benchmark case either passes
   or is recorded as a genuine blocker.  Publish only clean protected changes.

## Evidence questions

- Does every read-only Students task remove native write-capable tools and
  fail before launch when it claims expected artifacts?
- Do exact write scopes produce a minimal, client-specific tool/sandbox policy
  without weakening no-network isolation?
- Can a session resume only for the same task, including durable pending
  outcome replay, while existing schema-1 state fails closed or migrates
  safely?
- Can the cowork helper mechanically prevent execution before a benchmark is
  complete and agreed?
- Can project-local Claude defaults be validated as exactly Fable/high without
  modifying user product settings?
- Is the duration trigger explicit, and does the summary requirement grow
  deterministically without rewarding filler?

## Risks and recovery

- Changing the worker-state schema can strand existing opt-in state.  Prefer a
  backwards-compatible parse with explicit task binding or a documented
  fail-closed migration.
- Claude tool names and permission modes are product contracts; validate
  against the installed CLI and focused command-construction tests.
- Existing cowork sessions must remain checkable.  If the helper gains a new
  schema, retain readers for schema 1/2 and require the benchmark only for new
  schema-3 sessions.
- A model invocation with an ambiguous outcome is never retried.  Record the
  invocation and continue only with a distinct, proven-safe step.
