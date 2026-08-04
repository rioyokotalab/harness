# Local producer and consumer agents

The profile permits only controller↔consumer routes. Declare both clients and
send one mode-0600 file without SSH or pane reads:

```text
scripts/agent-message send-local-agent --source local --source-client codex \
  --target personal --target-client claude < MESSAGE_FILE
```

Request one stopping report with `LOCAL_REPLY_REQUIRED request_id=ID
reply_target=harness max_replies=1`. The consumer submits exactly five
non-sensitive lines through the matching source client:

```text
[Agent: Personal Claude] request_id=ID status=complete|blocked|rejected|failed confirmation_required=yes
subtask: NAME
result: RESULT
evidence: EVIDENCE
next_action: ACTION
```

```text
scripts/agent-message reply-local-agent --source personal \
  --source-client claude --target harness --target-client codex \
  --request-id ID < REPORT_FILE
```

Reports are mode 0600 and keyed by source, client, and request ID. Exact
duplicates are idempotent; changed bytes fail. Read one without waking the
consumer:

```text
scripts/agent-message read-local-agent-report --source personal \
  --source-client claude --target harness --target-client codex \
  --request-id ID
```

After review, confirm exactly once:

```text
scripts/agent-message confirm-local-agent --source local \
  --source-client codex --target personal --target-client claude \
  --request-id OLD --status accepted --next-request-id NEW
```

Confirmation removes only the matching report. `accepted` plus a fresh ID
advances; without one it closes a terminal checkpoint. `changes-required`
requires a fresh ID; `rejected` forbids one. Confirmation never grants owner
authority, source access, or an external write.

Elapsed time or an unchanged tree is not failure. Use metadata-only health
checks before follow-up and never replay an ambiguous submission. At a
reversible owner-choice wait, finish and publish safe work, create no receipt,
report once, and let the producer gate only that task. A blocked receipt is
terminal and is never deleted or rewritten to resume work.
