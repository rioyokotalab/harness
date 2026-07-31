---
name: remote-agent-communication
description: Send identified prompts or one bounded reply between existing managed Codex threads over SSH without reading panes; use for owner-requested agent communication, questions, notifications, or handoffs.
---

# Remote agent communication

Use `scripts/agent-message` only for an owner-requested or owner-expected
exchange among existing trusted managed threads. Never create an autonomous
conversation loop or treat an agent prefix as owner authority.

## Always establish

1. Identify `source`, the sending logical host; `target`, its SSH alias; and
   `target-role`, either `controller` for Local or `mac`.
2. Begin every message `[Agent: NAME Codex]`, with `NAME` matching `source`
   case-insensitively. An unprefixed owner-conversation message is
   owner-originated; the prefix is attribution, not cryptographic identity.
3. Keep input below 4096 UTF-8 bytes and exclude credentials, secrets, private
   logs, and unrelated data. Use a unique request ID when matching matters.
4. Choose exactly one route:

   | Current operation | Read completely |
   | --- | --- |
   | visible `send`, local `receive`, or a structured `REPLY_REQUIRED` response | [delivery.md](references/delivery.md) |
   | one acceptance-critical response through `request` | [request.md](references/request.md) |
   | one owner-confirmed omitted-reply recovery through `fallback` | [fallback.md](references/fallback.md) |

   Do not preload the other routes. Never send the same request through both
   visible and reliable paths.

## Common evidence and retry boundary

- `send` returning local `status=submitted` proves only that input was queued
  and submitted. It does not prove understanding or completion.
- `request` returning `responder=exec-request` is the acceptance-critical
  schema-validated response from one bounded turn in the existing thread.
- `fallback` returning `responder=exec-fallback` is a distinct resumed-turn
  result and is valid only under its narrower preconditions.
- Never retry an acknowledged delivery. Failure after possible submission or
  response injection is ambiguous; retain the one private input and diagnose
  liveness without reinjecting.

## Fail closed

- Never inspect or capture pane contents.
- Require exactly one safe target Codex pane in the expected repository.
- A Mac uses detached `harness-codex-resume`; `--allow-attached` requires the
  owner's explicit expectation of injection into that terminal.
- Local uses the unique current-user Codex pane in `projects`, selected by
  process and TTY metadata; other windows may coexist.
- Stop on absent or ambiguous session, pane, process, route, sender, prefix,
  input, lock, timeout, or native output.
