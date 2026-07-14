---
name: bounded-agent-delegation
description: Decide, dispatch, and review bounded subagent work when the user and active project instructions permit delegation. Use for independent research, diagnosis, or non-overlapping implementation whose saved context exceeds dispatch and review cost.
---

# Bounded agent delegation

1. Confirm delegation is allowed by the current user, system, and repository
   instructions. Stay solo for configuration, security decisions, tightly
   coupled edits, ambiguous conflicts, or tasks cheaper to do directly.
2. Delegate only an independent scope with exact inputs, output path, authority,
   exclusions, and acceptance checks. Default to one agent; use concurrency
   only for disjoint read/write scopes.
3. Pass on-disk pointers and the smallest useful context. Keep root-owned
   decisions, ledger integration, publication, external writes, and user
   communication with the primary agent.
4. Require a durable handoff containing status, summary, changed files,
   commands, verification, confirmed evidence, hypotheses, and remaining work.
5. Independently inspect the artifact and actual diff, spot-check material
   claims, and run proportional integration tests. A subagent does not certify
   its own work.
6. Record model/effort and telemetry only when observed. Never claim savings or
   exact routing when the dispatch surface could not apply the requested route.
