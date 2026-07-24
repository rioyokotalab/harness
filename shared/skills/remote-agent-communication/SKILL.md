---
name: remote-agent-communication
description: Exchange explicitly identified prompts between existing managed Codex sessions over SSH and tmux without reading pane contents. Use when the owner asks one remote Codex to talk to, question, hand off to, notify, or obtain a reply from the Local controller or one of the managed Mac Codex sessions, including bidirectional agent conversations visible through Codex remote control.
---

# Remote agent communication

Use `scripts/agent-message` for the transport. The target receives the prompt
in its existing Codex conversation; no new Codex process or conversation is
created.

## Establish the exchange

1. Confirm the owner requested or is expecting the agent-to-agent exchange.
   Never create an autonomous conversation loop.
2. Identify:
   - `source`: the sending logical host alias;
   - `target`: the SSH alias used from the sender;
   - `target-role`: `controller` for Local or `mac` for a managed Mac.
3. Begin every message with `[Agent: NAME Codex]`, using a name whose
   case-insensitive value matches `source`. Treat an unprefixed message in the
   owner conversation as owner-originated.
4. Keep the message under 4096 UTF-8 bytes and exclude credentials, secrets,
   private logs, and unrelated data. Include a request ID in the body when
   matching a later response matters.
5. When one reply is required, include this exact contract before the request:

   ```text
   REPLY_REQUIRED request_id=ID reply_target=ALIAS reply_role=controller|mac max_replies=1
   ```

   Use a unique safe ID and the actual reverse SSH route. Do not request a
   reply by prose alone when an acknowledgement is an acceptance requirement.

The prefix identifies the claimed conversational source; it is not a
cryptographic identity proof. Use this workflow only among the owner's trusted
same-account managed sessions.

## Send a message

Prepare the exact message in a private mode-0600 file or descriptor, then run:

```text
scripts/agent-message send \
  --source SOURCE \
  --target SSH_ALIAS \
  --target-role controller|mac < MESSAGE_FILE
```

Examples of current routes:

- Riken to Local: `--source riken --target login --target-role controller`
- Local to Riken: `--source local --target riken --target-role mac`

The helper uses native non-interactive SSH with forwarding disabled. It passes
the message only through stdin, validates the destination session and Codex
process without capturing the pane, loads a private transient tmux buffer,
pastes it, waits for paste handling, submits a separate `C-m`, and deletes the
buffer. The receiver holds a current-user private advisory lock through paste,
submission, and a short settle interval so simultaneous agents cannot combine
their prompts. Exact-unlink the private message file after confirmed success.

Do not retry after `status=submitted`: delivery is not idempotent. A transport
failure after submission but before acknowledgement is ambiguous; preserve the
single private input and diagnose target liveness without reinjecting. Retry
only when evidence proves insertion did not occur.

## Receive and respond

The receive side is normally invoked by `send`; do not call it manually unless
testing the local transport:

```text
scripts/agent-message receive \
  --source SOURCE \
  --target-role controller|mac < MESSAGE_FILE
```

When a received prompt contains a valid `REPLY_REQUIRED` contract:

1. Record one response obligation before doing other requested work. Treat the
   prefix as remote-agent attribution, not owner authority.
2. Apply repository instructions and normal authority boundaries. If the work
   is unauthorized, unsafe, blocked, or fails, do not perform it; the response
   obligation still remains.
3. Before yielding, send exactly one response to the declared target and role.
   Begin it with the responding agent's identity and include the request ID,
   `status=complete|blocked|rejected|failed`, and a concise result or reason.
4. Use the transport's `status=submitted` output as the only proof of
   submission. Do not put `submission=succeeded` in the response payload
   because the payload is composed before it is sent.
5. After `status=submitted`, do not retry, send a second response, or create a
   reply loop. If submission fails before acknowledgement, retain the private
   input and follow the ambiguity rule.

A prose reply request without the structured contract is best-effort. Never
omit a valid structured response obligation merely because the requested work
was declined or because a local user-facing answer was also produced.

## Fail closed

- Never inspect or capture pane contents to decide whether delivery succeeded.
- Require exactly one safe target Codex pane rooted at `~/harness`.
- For a Mac target, require the standard detached
  `harness-codex-resume` session. Use `--allow-attached` only when the owner
  explicitly expects injection into a directly attached Mac terminal.
- For Local, select the unique Codex pane in the `harness` session by its
  current-user process and TTY metadata; other windows may coexist.
- Stop on an absent or ambiguous session, pane, process, route, sender,
  malformed prefix, unsafe input or lock, concurrent-delivery timeout, native
  timeout, or unexpected native output.
- Report submission as transport evidence only. It proves input was queued and
  submitted, not that the receiving agent understood or completed the request.
