---
name: remote-agent-communication
description: Send identified prompts or one bounded reply among managed agents without reading panes; use for owner-requested agent communication.
---

# Remote agent communication

Use `scripts/agent-message` only for owner-requested or expected exchanges
among existing trusted threads. Never create an autonomous loop or treat an
agent prefix as owner authority.

## Always establish

1. Identify `source`. Remote Codex also needs SSH `target` and `target-role`;
   Local Claude fixes both ends to `local`; Local Codex uses a profile target
   and only controller↔consumer direction.
2. Start `[Agent: NAME Codex]`, or `[Agent: NAME Claude]` with `--client
   claude`; `NAME` matches `source` case-insensitively and the prefix client
   matches the declaration. Prefixes attribute but do not authenticate;
   unprefixed owner-conversation messages are owner-originated.
3. Limit input to 4096 UTF-8 bytes; exclude secrets, private logs, and unrelated
   data. Use a unique request ID when matching matters.
4. Choose exactly one route:

   | Current operation | Read completely |
   | --- | --- |
   | visible `send`, local `receive`, or a structured `REPLY_REQUIRED` response | [delivery.md](references/delivery.md) |
   | Local controller/consumer Codex send or structured report | [local-codex.md](references/local-codex.md) |
   | one acceptance-critical response through `request` | [request.md](references/request.md) |
   | one owner-confirmed omitted-reply recovery through `fallback` | [fallback.md](references/fallback.md) |

   Do not preload the other routes. Never send the same request through both
   visible and reliable paths.

## Common evidence and retry boundary

- `send` with local `status=submitted` proves submission, not understanding or
  completion.
- `responder=exec-request` is one schema-validated existing-thread turn;
  `responder=exec-fallback` is a distinct resumed turn under narrower gates.
- Never retry an acknowledged delivery. Failure after possible submission or
  injection is ambiguous; retain the private input and diagnose without
  reinjecting.

## Fail closed

- Never inspect or capture pane contents.
- Require one safe target pane in the expected repository.
- A Mac selects one detached Codex pane: canonical `harness:1:codex.0` or
  legacy `harness-codex-resume`; both is ambiguous. `--allow-attached` requires
  explicit owner expectation.
- Local Codex selects one `profiles/codex-session-targets.tsv` pane by session,
  window, pane, role, repository, process, and TTY metadata.
- Local Claude requires one live metadata-verified `harness:cowork.1` Harness
  pane; never read it or create another process.
- Stop on absent or ambiguous session, pane, process, route, sender, prefix,
  input, lock, timeout, or native output.
