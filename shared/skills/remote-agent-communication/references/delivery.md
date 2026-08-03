# Visible delivery and bounded response

Select this route for `send`, local `receive`, or structured
`REPLY_REQUIRED`.

## Send

Put the exact message in a private mode-0600 file or descriptor:

```text
scripts/agent-message send \
  --source SOURCE --target SSH_ALIAS \
  --target-role controller|mac < MESSAGE_FILE
```

Routes: Riken→Local uses `--source riken --target login --target-role
controller`; Local→Riken uses `--source local --target riken --target-role
mac`.

The helper uses native non-interactive SSH with forwarding disabled and sends
only stdin. Without pane capture it locks delivery, loads/pastes/deletes one
private tmux buffer, settles, then submits separate `C-m`. Exact-unlink input
after confirmed success.

A Mac requires one detached Codex pane: canonical `harness:1:codex.0` or
legacy `harness-codex-resume`; both is ambiguous. `--allow-attached` requires
explicit owner expectation.

## Local Codex to Local Claude

Send one mode-0600 `[Agent: Local Codex]` file:

```text
scripts/agent-message send-local-claude --source local < MESSAGE_FILE
```

This content-blind, single-process, submission-only, no-retry route requires one live
metadata-verified `harness:cowork.1` Harness pane. It never reads or creates a
process and never auto-replies. Claude replies separately through `receive
--client claude`.

## One best-effort reply

Place this contract before the visible request:

```text
REPLY_REQUIRED request_id=ID reply_target=ALIAS reply_role=controller|mac max_replies=1
```

Use the actual reverse SSH route. Prefix compliance and reachability remain
best-effort; use `request` when acknowledgement is required for acceptance.

## Receive and respond

`send` normally invokes receive. For manual tests:

```text
scripts/agent-message receive \
  --source SOURCE --target-role controller|mac < MESSAGE_FILE
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
