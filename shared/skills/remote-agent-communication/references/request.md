# Acceptance-critical request

Read this file when one response from an existing managed Mac thread is an
acceptance requirement.

Prepare one identified request and run:

```text
scripts/agent-message request \
  --source local \
  --target MAC \
  --request-id UNIQUE_ID < MESSAGE_FILE
```

The helper sends stdin over one Local-to-Mac SSH connection. On the Mac, one
schema-constrained `codex exec resume --last` turn processes the request in the
existing thread under repository policy. Its validated response returns over
that originating connection. Local verifies source, request ID, status, and
responder, then injects the response into the controller conversation.

This path does not use `ssh login`, a reverse route, agent forwarding, or the
Mac's `SSH_AUTH_SOCK`. Do not also send the request through the TUI. The target
private advisory lock serializes the resumed process with helper-mediated TUI
work.

Do not retry after a result may have been returned or injected. Treat
`responder=exec-request` as the bounded acceptance response; retain the request
and diagnose an ambiguous transport failure without reinjecting it.
