# Charter

## Task

Harden Harness's durable Codex-to-Claude development handoff from the current
protected baseline through an evidence-driven run ending at 2026-07-30 09:00
JST. Codex is the driver and Claude Code 2.1.220 with Fable/high is the
co-pilot. The work must make a fresh Claude process able to recover the exact
task from repository state, receive only task-appropriate authority, preserve
unrelated work and accepted policy, and leave independently reproducible
evidence.

## Boundaries

- The target repository is Harness only. Students, Swallow, Website, live
  Codex/Claude threads, tmux, app servers, schedulers, credentials, connectors,
  user-level settings, packages, system configuration, and hosting settings
  are out of scope.
- The live required-review count of zero is accepted owner policy and must not
  be classified or changed. Ordinary task Git publication is allowed only
  through protected exact-head CI; no force push or workflow dispatch.
- Claude may write only in its disposable sandbox during discussion. Codex is
  the sole target-writing role after the benchmark agreement and owner `go`.
- Do not inspect private chat, pane, transcript, credential, or opaque
  product-owned configuration content. Do not replay historical prompts or
  use client auto-memory as handoff evidence.
- ABQ is excluded from probes and rollout while the official G-QuAT status
  remains `サービス停止中`; an unavailable route is external unknown state.
- Any administrator, account, credential, connector, external-message,
  deployment, destructive, or live-process action discovered as useful is
  recorded and deferred behind its normal authority boundary.

## Baseline and sandboxes

- Immutable baseline:
  `333d67b2179906dbaea5c7ea7e763613851e52b8`.
- Target worktree:
  `/tmp/harness-t343-claude-handoff-hardening`.
- Driver sandbox:
  `/tmp/t343-codex-box/repo`.
- Co-pilot sandbox:
  `/tmp/t343-claude-box/repo`; each sealed stage is a direct child of
  `/tmp/t343-claude-box`.
- Live exchange:
  `docs/audits/t343-claude-handoff-hardening/cowork`.
- External seals and driver prompts remain outside the exchange and co-pilot
  sandbox under `/tmp/t343-seals` and `/tmp/t343-driver-prompts`.
- Both sandboxes are detached, clean clones of the immutable baseline.

## Acceptance

- Codex and Claude agree on the benchmark before target execution.
- Every retained iteration has a hypothesis, before/after identity, exact
  input/check, observed result, and keep/revert decision.
- The frozen handoff cases pass in isolated matched sandboxes and in the final
  target; failure capsules remain versioned evidence rather than rewritten
  history.
- Focused handoff, takeover, cowork, config, benchmark, and hardening tests
  pass, followed by clean `tests/test-phase1.sh`, protected exact-head CI, and
  final clean-tree/readback checks.
- No unrelated repository or live-system state changes. Any merged
  control-plane change is synchronized only to clean, reachable managed
  checkouts and receives the required one-time Mac context refresh.
- Material implementation stops at 2026-07-30 08:00 JST. The last hour is
  validation, publication/readback, cleanup, and durable handoff only.
- The durable and owner summaries each contain exactly 16 timestamped,
  evidence-backed time slices and at least 800 words, plus outcome,
  validation, residual risks, and exact next action.
