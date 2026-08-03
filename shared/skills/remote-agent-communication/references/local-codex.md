# Local controller and consumer Codex

Send one mode-0600 file. The profile permits only controller↔consumer,
without SSH or pane reads:

```text
scripts/agent-message send-local-codex \
  --source local --target personal < MESSAGE_FILE
```

Request one stopping report with `LOCAL_REPLY_REQUIRED request_id=ID
reply_target=harness max_replies=1`:

```text
scripts/agent-message reply-local-codex \
  --source personal --target harness --request-id ID < REPORT_FILE
```

Use five non-sensitive lines:

```text
[Agent: Personal Codex] request_id=ID status=complete|blocked|rejected|failed confirmation_required=yes
subtask: NAME
result: RESULT
evidence: EVIDENCE
next_action: ACTION
```

Bytes remain mode 0600; duplicates are idempotent and changes fail.
Recover without waking the consumer:

```text
scripts/agent-message read-local-codex-report \
  --source personal --target harness --request-id ID
```

After review, confirm:

```text
scripts/agent-message confirm-local-codex --source local --target personal \
  --request-id OLD --status accepted --next-request-id NEW
```

It removes the matching report. `accepted` with a fresh ID advances; without
one it closes a terminal checkpoint. `changes-required` requires a fresh
correction ID. `rejected` forbids one.
Confirmation never grants owner authority, source access, or external write.
Never create a reply loop.

Elapsed time or an unchanged tree is not failure. Before follow-up run this
metadata-only status/path check; it reads no pane or transcript:

```text
harness codex-thread-recovery --check --target personal
```

Wait on `thread_status=active`. Idle with no report or progress permits one
bounded status/start request. Route `systemError` through recovery; never
resend the prior prompt.

At a reversible owner-choice wait, publish the partial record; it creates no terminal receipt.
Report once; the producer gates only that task and restores
it after the owner answer. A blocked receipt is terminal.
Never delete or rewrite one to resume work.
