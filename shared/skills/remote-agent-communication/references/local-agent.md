# Local agent routes

Use declared controller↔consumer/Harness cross-client routes via one mode-0600
file; never SSH/read panes. Claude needs `--permission-mode
bypassPermissions`. Set `SKILL_ROOT` to this skill's directory. Before a
required consumer reply, check:

```text
"$SKILL_ROOT/scripts/agent-message" check-local-agent-compatibility \
  --target personal --target-client claude
```

Sync stale targets; record verified helpers.

```text
"$SKILL_ROOT/scripts/agent-message" send-local-agent --source local --source-client codex \
  --target personal --target-client claude < MESSAGE_FILE
```

Local Claude→Harness Codex:

```text
"$SKILL_ROOT/scripts/agent-message" send-local-codex --source local \
  --source-client claude --target harness < MESSAGE_FILE
```

Omission defaults to Codex; reply/read aliases accept `--source-client claude`.

Request five lines with `LOCAL_REPLY_REQUIRED request_id=ID
reply_target=harness max_replies=1`:

```text
[Agent: Personal Claude] request_id=ID status=complete|blocked|rejected|failed confirmation_required=yes
subtask: NAME
result: RESULT
evidence: EVIDENCE
next_action: ACTION
```

```text
"$SKILL_ROOT/scripts/agent-message" reply-local-agent --source personal \
  --source-client claude --target harness --target-client codex \
  --request-id ID < REPORT_FILE
```

Reports key source/client/ID; duplicates require exact bytes. Read:

```text
"$SKILL_ROOT/scripts/agent-message" read-local-agent-report --source personal \
  --source-client claude --target harness --target-client codex \
  --request-id ID
```

After review, confirm once:

```text
"$SKILL_ROOT/scripts/agent-message" confirm-local-agent --source local \
  --source-client codex --target personal --target-client claude \
  --request-id OLD --status accepted --next-request-id NEW
```

Confirmation removes the report. `accepted` plus a fresh ID advances; without
one it closes a terminal checkpoint. `changes-required` needs a fresh ID and
`rejected` forbids one.
Confirmation never grants owner authority, source access, or writes.

Skip compatibility checks for Harness cross-client targets; the send
command validates endpoints.

Time or an unchanged tree is not failure. Check metadata; never replay
ambiguous submissions. At a reversible owner-choice wait, publish safe work,
create no receipt, report once, and gate only that task. A blocked receipt is
terminal and never deleted or rewritten to resume work.
