# Local producer and consumer agents

Only controller↔consumer routes are permitted. Declare both clients and send
one mode-0600 file without SSH or pane reads. Claude requires explicit
`--permission-mode bypassPermissions`; otherwise stop before insertion:

```text
scripts/agent-message send-local-agent --source local --source-client codex \
  --target personal --target-client claude < MESSAGE_FILE
```

Request one stopping report with `LOCAL_REPLY_REQUIRED request_id=ID
reply_target=harness max_replies=1`. The consumer submits five non-sensitive
lines:

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
duplicates are idempotent; changed bytes fail. Read without waking the consumer:

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

Confirmation removes only the matching report. `accepted` with a fresh ID
advances; without one it closes a terminal checkpoint. `changes-required`
requires a fresh ID; `rejected` forbids one. Confirmation never grants owner
authority, source access, or writes.

Elapsed time or an unchanged tree is not failure. Use metadata-only health
checks before follow-up and never replay an ambiguous submission. At a
reversible owner-choice wait, finish and publish safe work, create no receipt,
report once, and let the producer gate only that task. A blocked receipt is
terminal and is never deleted or rewritten to resume work.
