# Local controller and consumer Codex

Prepare one private mode-0600 identified input in the source repository:

```text
scripts/agent-message send-local-codex \
  --source local --target personal < MESSAGE_FILE
```

The declared profile permits only controller↔consumer direction. This route
uses no SSH or pane content; submitted delivery is final.

For one bounded subtask report include:

```text
LOCAL_REPLY_REQUIRED request_id=ID reply_target=harness max_replies=1
```

The consumer replies from its repository:

```text
scripts/agent-message reply-local-codex \
  --source personal --target harness --request-id ID < REPORT_FILE
```

Use exactly five non-sensitive single-line fields:

```text
[Agent: Personal Codex] request_id=ID status=complete|blocked|rejected|failed confirmation_required=yes
subtask: NAME
result: RESULT
evidence: EVIDENCE
next_action: ACTION
```

After submission the consumer stops. The controller reviews the evidence and
sends one schema-built checkpoint:

```text
scripts/agent-message confirm-local-codex --source local --target personal \
  --request-id OLD --status accepted --next-request-id NEW
```

`accepted` advances the next declared stage. `changes-required` repeats only
durably recorded corrections; otherwise send a new bounded request. Both bind
the next report to `NEW`; `rejected` forbids `--next-request-id`. Confirmation
controls sequence only and never grants owner authority, source access, or an
external write. Never create a reply loop.

For an expected, reversible owner-choice wait, the consumer preserves and
publishes the partial record as its packet permits, reports once, and
creates no terminal receipt. The producer gates only that task, confirms with a
fresh ID, and restores it to ready only after recording the owner answer. A
blocked receipt is terminal and reserved for a durable unavailable outcome.
Never delete or rewrite one to resume work.
