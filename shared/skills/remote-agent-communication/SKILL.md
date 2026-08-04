---
name: remote-agent-communication
description: Send identified prompts, reports, or confirmations among managed Codex and Claude agents without reading panes; use for owner-requested communication or producer-consumer checkpoints.
---

# Remote agent communication

Use `scripts/agent-message` only for owner-requested exchanges among Codex or
Claude threads. Never create autonomous loops or treat an
agent prefix or confirmation as owner authority.

## Route

1. Set source, target, and both clients. Remote delivery also needs SSH target
   and role; Local delivery requires a declared controller↔consumer route.
2. Prefix `[Agent: NAME Codex]` or `[Agent: NAME Claude]`. Name and client must
   match the sender. Prefixes attribute only; unprefixed conversation is
   owner-originated.
3. Keep input within 4096 UTF-8 bytes; exclude secrets, private logs, and
   unrelated data. Use unique request IDs.
4. Read one route:

   | Operation | Route |
   | --- | --- |
   | visible/SSH send, local receive, or structured `REPLY_REQUIRED` | [delivery.md](references/delivery.md) |
   | Local controller/consumer send, report, readback, or confirmation | [local-agent.md](references/local-agent.md) |
   | one acceptance-critical `request` response | [request.md](references/request.md) |
   | one owner-confirmed omitted-reply `fallback` | [fallback.md](references/fallback.md) |

Read no other route or duplicate a request across transports.

## Common gates

- Local `status=submitted` proves only submission.
- Never retry acknowledged or possibly inserted delivery; retain input and
  diagnose without reinjection.
- The transport never inspects panes. Producer pane inspection is a separate
  task action governed by the selected repository's managed policy. Resolve
  each Local target from exactly one
  `profiles/agent-session-targets.tsv` row matching client, window, pane, role,
  repository, process, and TTY.
- Stop on absent or ambiguous target, route, identity, input, lock, timeout, or
  native output.
