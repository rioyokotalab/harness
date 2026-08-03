# Local controller and consumer Codex

Prepare one private mode-0600 identified input in the exact source repository:

```text
scripts/agent-message send-local-codex \
  --source local --target personal < MESSAGE_FILE
```

The target must be declared in `profiles/codex-session-targets.tsv`. Selection
matches session, window, pane, role, repository, process, and TTY metadata.
Only controller-to-consumer or consumer-to-controller direction is allowed;
the route uses neither SSH nor pane content. Submitted delivery is final—do not
retry it.

For one bounded subtask report, include:

```text
LOCAL_REPLY_REQUIRED request_id=ID reply_target=harness max_replies=1
```

The consumer responds from its repository:

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

After `status=submitted`, the consumer stops. The controller reviews evidence
and separately confirms or requests the next subtask. Never create a reply loop.
