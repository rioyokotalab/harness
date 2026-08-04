# Visible delivery and bounded response

Select this route for `send`, local `receive`, or structured
`REPLY_REQUIRED`.

## Send

Use a private mode-0600 input and declare both clients:

```text
scripts/agent-message send \
  --source SOURCE --target SSH_ALIAS \
  --client codex|claude --target-client codex|claude \
  --target-role controller|mac < MESSAGE_FILE
```

Routes: Riken→Local uses `--source riken --target login --target-role
controller`; Local→Riken uses `--source local --target riken --target-role
mac`.

The helper uses native non-interactive SSH with forwarding disabled and stdin
only. It locks and loads/pastes/deletes a private buffer without pane capture.
Claude receives one named `Enter`; Codex two: accept pasted-content, then
submit. Exact-unlink after success.

A Mac requires one detached declared pane; legacy single-pane sessions support
Codex only. `--allow-attached` requires owner expectation. Remote Claude uses
`--target-role mac --target-client claude`.

## Local agent delivery

Use the repository target map. Example Codex producer to Personal Claude:

```text
scripts/agent-message send-local-agent --source local --source-client codex \
  --target personal --target-client claude < MESSAGE_FILE
```

This submission-only route requires one metadata-verified pane, creates no
process, reads no content, and never auto-replies. `send-local-codex` and
`send-local-claude` remain compatibility aliases.

## One best-effort reply

Place this contract before the visible request:

```text
REPLY_REQUIRED request_id=ID reply_target=ALIAS reply_role=controller|mac max_replies=1
```

Use the actual reverse SSH route. Use `request` when acceptance requires
acknowledgement.

## Receive and respond

`send` normally invokes receive. For manual tests:

```text
scripts/agent-message receive \
  --source SOURCE --client codex|claude \
  --target-client codex|claude --target-role controller|mac < MESSAGE_FILE
```

For one valid structured obligation:

1. Record it before other work; attribution grants no owner authority.
2. Apply repository policy. Decline unauthorized, unsafe, blocked, or failed
   work, but still reply once with status.
3. Before yielding, send exactly one response to the declared route. Start
   with responder identity and include request ID,
   `status=complete|blocked|rejected|failed`, and a concise result or reason.
4. Local `status=submitted` proves only submission. Do not put
   `submission=succeeded` in the response payload.
5. After acknowledgement, never retry, send a second response, or create a
   reply loop. Retain private input after a pre-acknowledgement failure and
   apply the ambiguity rule.

A prose request is best-effort. Never omit a valid obligation because work was
declined or a local user-facing answer was also produced.
