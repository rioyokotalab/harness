# Omitted-reply fallback

Use one schema-constrained fallback for an earlier visible `send` only when all
of these are true:

- the original required request returned `status=submitted`;
- the owner explicitly observed that turn finish without a response attempt;
- no later turn entered the Mac conversation; and
- fallback only reports the preceding result and cannot redo work.

Run:

```text
scripts/agent-message fallback \
  --source CONTROLLER \
  --target MAC \
  --request-id ID
```

The fallback uses the managed `harness-codex` launcher for one read-only
`codex exec resume --last` turn in the same session context. Its prompt forbids
tools and state changes, `references/reply.schema.json` constrains the final
answer, and Local validates the request ID and bounded fields before injection.
It uses no reverse SSH route, does not replace the TUI, expose the private Codex
log, or create a reply loop.

Elapsed time and process idleness do not prove a turn finished. Refuse fallback
when the latest session, preceding turn, or response-attempt state is ambiguous.
Never invoke it twice for one request. An error after possible response
injection is ambiguous and not retryable.
