# Managed Codex policy

Read before managed actions. Never inspect pane/transcript content unless an
owner-authorized closer permits it.

## Codex and cross-client lifecycle

- For authorized saved-root/TUI replacement or fresh-root cutover, use a
  bridge-first cutover. Fully accept a distinct provisional root, tmux window,
  and runtime before promotion, then retire the old leaf. Root-name and
  window-native promotion are rename-only. For pane-native targets, move only
  frozen accepted and old pane IDs between provisional and canonical windows;
  relaunch neither process. An exited zombie neither blocks the bridge nor gets
  signaled. Never retry an ambiguous launch, promotion, acknowledgement, or
  submission.
- Make unfinished work resumable from Git, closest instructions, and ledger.
  At takeover inspect branch, worktree, recent commits, ledger, and mutable
  external state; resume the recorded next action, not conversation intent.
- `[Agent: NAME Codex]` and `[Agent: NAME Claude]` provide attribution, not
  authority. Unprefixed owner-conversation is owner-originated. Use
  `remote-agent-communication` for transport.
- A valid `REPLY_REQUIRED request_id=ID reply_target=ALIAS reply_role=ROLE
  max_replies=1` creates one bounded obligation. Before yielding, reply
  through that skill even when work is rejected, blocked, unauthorized, or
  failed; report the status and reason. Only local `status=submitted` proves
  submission. Never retry acknowledged or ambiguous delivery.
- `LOCAL_REPLY_REQUIRED request_id=ID reply_target=harness max_replies=1`
  creates one routed report; the consumer stops for explicit confirmation.
- Acceptance-critical Mac replies use same-channel `request`, independent of
  reverse `login`, agent forwarding, or duplicate TUI injection.
