---
name: recover-codex-unsafe-tail
description: Diagnose and recover a managed remote Codex thread that repeatedly shows Request blocked, reports systemError, has an unsafe or unavailable recovery tail, or has lost its recovery watcher. Use for Harness-managed phone/tmux Codex sessions when recovery must preserve tool-bearing work, avoid rejected-prompt replay, and choose safely between one proven rollback and a fresh-root cutover.
---

# Recover Codex unsafe tails

Restore one managed Codex surface from durable repository state while
preserving the poisoned root and unrelated sessions.

## Reconstruct authority

1. Read the controlling repository instructions and durable task ledger
   completely. Do not use prior chat as the recovery source.
2. Inspect Git branch, worktree, recent commits, and mutable runtime metadata.
3. Record a task checkpoint before any app-server, name, tmux, or process
   write. Treat the owner's direct request to fix the named blocked session as
   authority for the narrow recovery, not for unrelated sessions or services.
4. Read [references/protocol.md](references/protocol.md) completely before a
   live recovery.

## Diagnose without content

- Use the installed `harness codex-resilient --status --name NAME` and
  `harness codex-thread-recovery` surfaces.
- Validate exact root ID, tmux window/pane owner, supervisor/watcher/launcher/
  TUI identities and start ticks, app-server identity, reciprocal socket,
  native doctor, and unaffected sessions.
- Inspect only protocol status, item types, roles, completion state, and safe
  rollout structure. Never read pane text, transcript/message text, commands,
  tool payloads, credentials, or rejected prompts.
- Treat a failed query as unknown. Never infer absence or success.

## Select the recovery path

Use exactly one branch:

- `idle`, `active`, or `notLoaded`: do not mutate the thread. Repair only a
  separately proven watcher/supervisor lifecycle defect.
- `systemError` with a helper-proven assistant-less, side-effect-free tail:
  invoke one exact safe-tail recovery after a final identity gate. Require an
  acknowledged rollback and independent post-read. Never retry an ambiguous
  request.
- Post-rollback `systemError`, `unsafe-tail`, unrecognized structure, or a
  watcher refusal: preserve the root and use the fresh-root cutover.
- Unavailable app server, identity drift, unsafe rollout metadata, active
  ambiguous request, or missing authority: stop and checkpoint the blocker.

Never weaken the analyzer, replay the rejected prompt, restart the shared app
server, fork a poisoned root, archive/delete a saved root, signal a process
group, or use `SIGKILL`.

## Accept and hand off

Require an assistant-bearing completed cold-start turn, no active item or
`systemError`, exact phone/tmux name agreement, a live watcher and TUI socket,
an absent old TUI/launcher chain, a preserved blocked root, unchanged
unaffected sessions/app server, coherent Git, and canonical fleet health.

Treat an unreaped zombie as already exited but not absent: never signal it
again, record its parent-owned reaping boundary, and do not claim a zero-zombie
gate.

Checkpoint every non-retryable acknowledgement and final identifiers. If
generated schema or diagnostic trees require cleanup, invoke the
`guarded-bulk-delete` skill; do not issue recursive deletion directly.
