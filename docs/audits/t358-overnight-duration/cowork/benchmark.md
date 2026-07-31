# Benchmark

## Identity

- Target: live tmux server (`projects` session) + worktrees `~/harness`
  (branch `claude/t358-overnight-duration` from
  524b3e785c9a2adfc3f5ed4c470a1b55d49e3a32),
  `codex-workspaces/{students,swallow}`, `projects/{website,personal}`.
- Baseline: tmux `projects` = one `codex` window, 3 even panes at the three
  admitted roots; harness main at 524b3e7; other repos at their HEADs as
  first observed and recorded in `execution.md` before mutation.

## Observable cases

Measured for every candidate iteration where applicable:

- C1. `tmux list-panes -t projects:claude` → 3 panes created with `exec
  claude --model fable --effort high --fallback-model opus` as the direct
  pane command (argv verified from the pane PID's `/proc/PID/cmdline` at
  launch), paths exactly the three admitted roots in order, width variance
  ≤1 column, equal heights; immutable pane IDs captured at creation from
  `-P -F '#{pane_id}'` are the only targeting handles thereafter.
- C2. Pre/post fingerprint of the `codex` window (window ID, pane IDs,
  layout string, pane dimensions, paths, commands) byte-identical; no window
  beyond `claude` added or removed.
- C3. Staged switch-back outcomes, each logged separately: (a) timer process
  identity (PID + start time + script digest) alive before 04:25; (b) per-pane
  guard result at fire time (original pane ID live, expected path, claude/node
  process) with generic-shell fail-closed skip; (c) one-shot literal
  `send-keys` delivery result then separate Enter, never retried on
  ambiguity; (d) application-level model confirmation recorded only if a
  content-free surface exposes it, otherwise the effective model is recorded
  as unknown with native fallback left in place. Keystroke delivery is never
  reported as a verified model switch.
- C4. Per-repo survey: 5/5 repos have a dated survey block in `execution.md`
  naming instructions read, TODO state, and ranked issues.
- C5. Per-repo development: each iteration records hypothesis, diff or digest
  before/after, exact check command and result, keep/revert. Owning checks
  pass for mapped components; `harness validate` phase 1 for broad harness
  changes and once on the final integrated harness tree if protected
  publication is requested.
- C6. PR economy: no more than one coherent protected PR per private
  repository unless that repository's closest policy requires separation;
  scope is reduced or deferred rather than bundling unrelated tasks into one
  PR merely to save CI quota.
- C7. Duration artifacts: final + durable summaries each contain exactly 7
  timestamped evidence-backed slices covering 23:21–00:21, 00:21–01:21,
  01:21–02:21, 02:21–03:21, 03:21–04:21, 04:21–05:21, and 05:21–05:30 local,
  and ≥350 words each, completed before the 05:30 hard stop.

## Evidence and iteration method

- Driver independent pass: disposable tmux experiment in a scratch session
  (never `projects`) to answer Q1/Q2; native `--help`/dry checks for Q3;
  read-only repo inspection for Q4. Live execution adds a preflight capture
  of actual session/window dimensions and the full `codex` fingerprint, and
  `even-horizontal` applied idempotently. `--fallback-model` is treated as a
  configured native fallback, not a proven weekly-limit semantics guarantee.
- Per-repo validation is frozen per change-class after reading that
  repository's closest instructions: survey-only → recorded baseline and
  blockers; docs/ledger-only → diff review + `git diff --check` (+ focused
  contract checker where present); one mapped component → smallest owning
  suite + invariants; cross-cutting/policy/validator/safety/unknown → the
  repository's complete required suite; harness → deterministic
  `harness validate` tier with phase 1 on the final integrated tree before
  protected publication. Receipts record policy, change class, exact command,
  result, and target identity.
- Co-pilot independent pass: staged read-only critique of charter, plan,
  benchmark and the Q1–Q5 questions from the codex sandbox; no target access.
- Reciprocal pass reveals driver evidence for critique; strongest conflict
  resolved by a matched experiment or recorded unresolved.
- Iterations only after a distinct observed failure; unchanged blind retries
  do not count. Each iteration logged in `execution.md` against C1–C7.

## Stop condition

- Material-work cutoff 05:00 local 2026-08-01; final-validation window
  05:00–05:30; hard stop 05:30.
- Early stop on: failed gate, unsafe disagreement, missing authority, or
  ambiguous partial action → checkpoint and return to owner review.
- Fable weekly-limit exhaustion of the driver session: checkpoint to ledger;
  eligible native fallback may finish the current turn only.

## Agreement

Protocol completeness agreements recorded after both evidence passes and
reconciliation (co-pilot line reproduced from the imported reciprocal
evidence):

```text
agreement: role=driver client=claude benchmark-accepted
agreement: role=copilot client=codex benchmark-accepted
```
