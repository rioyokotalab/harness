# Local controller and consumer Codex

Create one private mode-0600 message in the source repository:

```text
scripts/agent-message send-local-codex \
  --source local --target personal < MESSAGE_FILE
```

The profile permits only controller↔consumer traffic, without SSH or pane
content. Request one bounded report with:

```text
LOCAL_REPLY_REQUIRED request_id=ID reply_target=harness max_replies=1
```

The consumer sends it from its repository, then stops:

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

The helper atomically preserves the validated report mode 0600 before terminal
delivery. An exact duplicate is idempotent; different bytes for one ID fail.
If delivery is absent or partial, read that copy without waking the consumer:

```text
scripts/agent-message read-local-codex-report \
  --source personal --target harness --request-id ID
```

After review, send one schema-built checkpoint:

```text
scripts/agent-message confirm-local-codex --source local --target personal \
  --request-id OLD --status accepted --next-request-id NEW
```

The submitted confirmation removes only its matching preserved report.
`accepted` advances; `changes-required` repeats only recorded corrections.
Both require a fresh report ID. `rejected` forbids one.
Confirmation never grants owner authority, source access, or external write.
Never create a reply loop.

At a reversible owner-choice wait, protected-publish the partial record; it
creates no terminal receipt. Report once and let the producer gate only that
task. Restore it only after recording the owner answer. A blocked receipt is
terminal. Never delete or rewrite one to resume work.
