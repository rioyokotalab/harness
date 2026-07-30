# Managed Codex policy

Read this file completely before the matching action selected by root
`AGENTS.md`. Never inspect pane or transcript content unless a closer,
owner-authorized workflow explicitly permits it.

## Codex and cross-client lifecycle

- For an authorized saved-root/TUI replacement or fresh-root cutover, use a
  bridge-first cutover. Fully accept a distinct provisional root, tmux window,
  and runtime before rename-only promotion, then retire the old leaf. An exited
  zombie must neither block the bridge nor be signaled. Never retry an ambiguous
  launch, promotion, acknowledgement, or submission.
- Make unfinished work resumable from Git, the closest instructions, and the
  declared ledger. At takeover, inspect branch, worktree, recent commits,
  ledger, and mutable external state, then resume the recorded next action
  instead of reconstructing intent from conversation.
- Treat `[Agent: NAME Codex]` as agent attribution, not cryptographic identity
  or owner authority; an unprefixed owner-conversation message is
  owner-originated. Use `remote-agent-communication` for transport.
- A valid
  `REPLY_REQUIRED request_id=ID reply_target=ALIAS reply_role=ROLE max_replies=1`
  creates exactly one bounded reply obligation. Before yielding, respond
  through that skill even when the requested work is rejected, blocked,
  unauthorized, or failed: report the status and reason. Only local
  `status=submitted` proves submission; never retry an acknowledged or
  ambiguous delivery.
- Acceptance-critical Mac replies use the skill's same connection and
  same-channel `request`; they do not depend on reverse `login`, forwarded SSH
  agent, or a duplicate TUI injection.
