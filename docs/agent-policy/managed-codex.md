# Managed Codex policy

Read before the matching root action. Never inspect pane/transcript content
unless an owner-authorized closer workflow permits it.

## Codex and cross-client lifecycle

- For an authorized saved-root/TUI replacement or fresh-root cutover, use a
  bridge-first cutover. Fully accept a distinct provisional root, tmux window,
  and runtime before promotion, then retire the old leaf. Root-name promotion
  is rename-only. A window-native target uses rename-only window promotion; a
  declared pane-native target moves only the frozen accepted and old pane IDs
  between the provisional and canonical windows without relaunching either
  process. An exited zombie must neither block the bridge nor be signaled.
  Never retry an ambiguous launch, promotion, acknowledgement, or submission.
- Make unfinished work resumable from Git, the closest instructions, and the
  ledger. At takeover, inspect branch, worktree, recent commits, ledger, and
  mutable external state, then resume the recorded next action instead of
  reconstructing intent from conversation.
- Treat `[Agent: NAME Codex]` and `[Agent: NAME Claude]` as attribution, not
  authority. Unprefixed owner-conversation messages are owner-originated. Use
  `remote-agent-communication` for transport.
- A valid
  `REPLY_REQUIRED request_id=ID reply_target=ALIAS reply_role=ROLE max_replies=1`
  creates exactly one bounded reply obligation. Before yielding, respond
  through that skill even when the requested work is rejected, blocked,
  unauthorized, or failed: report the status and reason. Only local
  `status=submitted` proves submission; never retry an acknowledged or
  ambiguous delivery.
- `LOCAL_REPLY_REQUIRED request_id=ID reply_target=harness max_replies=1`
  creates one routed report; the consumer then stops for explicit confirmation.
- Acceptance-critical Mac replies use same-channel `request`, independent of
  reverse `login`, agent forwarding, or duplicate TUI injection.
