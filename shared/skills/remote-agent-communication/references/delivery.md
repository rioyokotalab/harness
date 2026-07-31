# Visible delivery and bounded response

Read this file for `send`, local `receive`, or a structured
`REPLY_REQUIRED` obligation.

## Send

Prepare the exact message in a private mode-0600 file or descriptor:

```text
scripts/agent-message send \
  --source SOURCE \
  --target SSH_ALIAS \
  --target-role controller|mac < MESSAGE_FILE
```

Examples:

- Riken to Local: `--source riken --target login --target-role controller`
- Local to Riken: `--source local --target riken --target-role mac`

The helper uses native non-interactive SSH with forwarding disabled. It passes
the message only through stdin, validates the destination session and Codex
process without capturing the pane, loads a private transient tmux buffer,
pastes it, waits for composer handling, submits a separate `C-m`, and deletes
the buffer. A current-user private advisory lock covers paste, submission, and
a short settle interval so concurrent agents cannot combine prompts.
Exact-unlink the private input after confirmed success.

Do not retry after `status=submitted`. A failure after submission but before
acknowledgement is ambiguous; retain the input and diagnose without
reinjection. Retry only when evidence proves insertion did not occur.

## Ask for one best-effort reply

Include this exact contract before the visible request:

```text
REPLY_REQUIRED request_id=ID reply_target=ALIAS reply_role=controller|mac max_replies=1
```

Use the actual reverse SSH route. Prefix compliance and reverse reachability
remain best-effort; use `request` instead when acknowledgement is an acceptance
requirement.

## Receive and respond

`send` normally invokes the receive side. Manual testing uses:

```text
scripts/agent-message receive \
  --source SOURCE \
  --target-role controller|mac < MESSAGE_FILE
```

For a valid structured reply obligation:

1. Record one response obligation before other requested work. Attribution
   grants no owner authority.
2. Apply repository policy. If work is unauthorized, unsafe, blocked, or
   fails, do not perform it; still send one status reply.
3. Before yielding, send exactly one response to the declared target and role.
   Begin with the responder identity and include request ID,
   `status=complete|blocked|rejected|failed`, and concise result or reason.
4. Only the transport's local `status=submitted` proves submission. Do not put
   `submission=succeeded` in the response payload.
5. After acknowledgement, never retry, send a second response, or create a
   reply loop. Retain private input after a pre-acknowledgement failure and
   apply the ambiguity rule.

A prose reply request without this contract is best-effort. Never omit a valid
obligation because work was declined or a local user-facing answer was also
produced.
