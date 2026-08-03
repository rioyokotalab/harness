# Local controller and consumer Codex

The profile permits only controller↔consumer. Send one mode-0600 file; do not
use SSH or read panes:

```text
scripts/agent-message send-local-codex \
  --source local --target personal < MESSAGE_FILE
```

Request one stopping report: `LOCAL_REPLY_REQUIRED request_id=ID
reply_target=harness max_replies=1`.

```text
scripts/agent-message reply-local-codex \
  --source personal --target harness --request-id ID < REPORT_FILE
```

Use exactly five non-sensitive lines:

```text
[Agent: Personal Codex] request_id=ID status=complete|blocked|rejected|failed confirmation_required=yes
subtask: NAME
result: RESULT
evidence: EVIDENCE
next_action: ACTION
```

Keep reports mode 0600. Duplicates are idempotent; changed bytes fail. Read
without waking the consumer:

```text
scripts/agent-message read-local-codex-report \
  --source personal --target harness --request-id ID
```

Confirm after review:

```text
scripts/agent-message confirm-local-codex --source local --target personal \
  --request-id OLD --status accepted --next-request-id NEW
```

Confirmation removes the matching report. `accepted` plus a fresh ID advances;
without one it closes a terminal checkpoint. `changes-required` requires a
fresh ID; `rejected` forbids one. Confirmation never grants owner authority,
source access, or external write.

Elapsed time or an unchanged tree is not failure. Before follow-up, run this
metadata-only check; it reads no pane or transcript:

```text
harness codex-thread-recovery --check --target personal
```

Wait on `thread_status=active`. Idle without report or progress permits one
bounded status/start request. Route `systemError` through recovery; never
resend the prior prompt.

At a reversible owner-choice wait, finish safe work and publish the partial
record; it creates no terminal receipt. Report once. The producer gates and
restores only that task. A blocked receipt is terminal.
Never delete or rewrite one to resume work.
