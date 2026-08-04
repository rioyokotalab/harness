# Local producer and consumer agents

Permit controller↔consumer routes only. Use one mode-0600 file without SSH or
pane reads. Claude needs
`--permission-mode bypassPermissions`.

Before required reply, check the target skill:

```text
scripts/agent-message check-local-agent-compatibility \
  --target personal --target-client claude
```

On stale, sync. A bounded request may name the verified owner-managed helper
both ways; record it.

```text
scripts/agent-message send-local-agent --source local --source-client codex \
  --target personal --target-client claude < MESSAGE_FILE
```

Request a report with `LOCAL_REPLY_REQUIRED request_id=ID
reply_target=harness max_replies=1`. The consumer sends five lines:

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

Mode-0600 reports use source/client/ID. Duplicates require exact bytes. Read
without waking the consumer:

```text
scripts/agent-message read-local-agent-report --source personal \
  --source-client claude --target harness --target-client codex \
  --request-id ID
```

After review, confirm once:

```text
scripts/agent-message confirm-local-agent --source local \
  --source-client codex --target personal --target-client claude \
  --request-id OLD --status accepted --next-request-id NEW
```

Confirmation removes the report. `accepted` with a fresh ID advances; without
one it closes a terminal checkpoint. `changes-required` requires a fresh ID;
`rejected` forbids one. Confirmation never grants owner authority, source
access, or writes.

Elapsed time or unchanged tree is not failure. Check metadata; never replay an
ambiguous submission. At a reversible owner-choice wait, publish safe work,
create no receipt, report once, and gate only that task. A blocked receipt is
terminal and never deleted or rewritten to resume work.
