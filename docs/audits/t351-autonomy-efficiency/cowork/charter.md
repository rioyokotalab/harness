# Charter

## Task

Design and validate a repository-native reduction in GitHub Actions minute use,
mandatory agent context, repeated checks, and cross-project contention for the
Harness, Students, and Swallow sessions.  The owner ranks autonomy first,
efficiency second, and non-obstructive safety third, and requests iterative
work through 2026-07-31 09:00 JST.

## Boundaries

Codex is the sole target driver.  Claude is an advisory co-pilot confined to
its detached baseline sandbox and staged exchange.  Neither independent client
may inspect tmux panes/transcripts, mutate live Codex/app-server/session state,
inspect credentials, change GitHub settings/rulesets/billing, or touch
unrelated dirty state.  Repository-owned workflow, instruction, skill, test,
and task-ledger changes are in scope.  External facts use primary sources.
Unknown external state stays unknown.

## Baseline and sandboxes

Immutable Git baseline:
`f2ce89ac3ea393cb5a7b882bed1b79fe773974fb`.

- Codex sandbox: `/tmp/harness-t351-codex-sandbox`, detached worktree at the
  baseline.
- Claude sandbox: `/tmp/harness-t351-claude-sandbox`, detached worktree at the
  same baseline.
- Target worktree: `/tmp/harness-t351-autonomy-efficiency`, branch
  `codex/t351-autonomy-efficiency`.
- Exchange mode: staged schema 3.  Stages are direct children of the Claude
  sandbox; seals are outside the repository, session, and both sandboxes.

The target and both sandboxes are independently writable.  No sandbox contains
task credentials or grants external-write authority.

## Acceptance

The frozen B1–B6 benchmark must pass: at least 70% median mandatory-context
reduction; a compact resumable board without lost history; deterministic
risk-tiered validation with fast simple cases and full escalation; at least
90% lower private hosted-minute demand for ordinary owner work while retaining
untrusted checks; concurrent project-isolated work; and unchanged critical
safety invariants.  Every retained iteration records its exact input, command,
result, and keep/revert decision.  Final publication uses one coherent PR and
the complete suite once.  Deadline closeout includes guarded cleanup and fresh
fleet health.
