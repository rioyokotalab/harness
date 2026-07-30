---
name: codex-claude-cowork
description: Coordinate Codex and Claude for explicit collaboration, comparison, handoff, or duration work through an agreed benchmark, isolated experiments, reciprocal evidence critique, and one target driver.
---

# Codex–Claude cowork

The client handling the owner's request is the **driver**; the other native
client is the **co-pilot**. Do not grant either product a permanent senior role
or substitute a same-product subagent for the other client.

## Always enforce

- Closest repository instructions, ledger, safety skills, and owner authority
  control. Cowork never grants credential access or authority for external
  writes, publication, deployment, package installation, scheduler use,
  messaging, destructive cleanup, or target mutation absent from the task.
- Reconstruct target, Git, ledger, and mutable external state before changes;
  preserve unrelated work. Require both native clients.
  If the co-pilot is unavailable, stop before target execution. Never fabricate
  evidence.
- Separate the target, live exchange, and two disposable sandboxes built from
  one named baseline. Exclude credentials, private values, and unrelated data
  from every sandbox, prompt, stage, seal, receipt, and artifact.
- Planning and co-pilot experiments are read-only against the target. Stage by
  default and never grant the co-pilot the live session. A direct-session write
  grant requires a recorded fallback when the frozen experiment cannot stage.
- Before every co-pilot window, seal driver-owned live state outside all
  co-pilot-writable trees and retain a recoverable preimage. Freeze
  driver-owned live writes during that window; any protected change stops.
- Every staged pass needs a driver-only prompt, direct-child stage, external
  seal outside co-pilot-writable trees, inspected candidate, validated
  `import-copilot`, and receipts. A seal, freshness, destination, receipt, or
  crash-ambiguity failure stops; never relaunder or blindly retry the stage.
- Treat `status`, `wait-copilot`, candidate state, freshness summaries, and PID
  reachability as advisory only. They never authorize import.
- Hashes, seals, receipts, ownership, modes, and process state prove only byte
  integrity or advisory facts—not authorship, semantics, success, or equivalent
  client confinement. Inspect evidence and protected state independently.
- Let only the driver mutate the target. Before execution, require the frozen
  benchmark, both role-bound agreements, required imports, owner go, target
  identity, authority, cleanliness, rollback, and acceptance gates.
- Only an original request explicitly ordering execution after cowork planning
  in the same frozen scope is go. Otherwise wait for a new explicit `go`.
  Material change, missing evidence or authority, unsafe disagreement, identity
  drift, failed gate, or ambiguous partial action returns to owner review.
- Use reviewed native non-prompting options and narrowest task permissions.
  Never use a bypass flag to pass automation, weaken a safeguard after client
  error, or retry an unchanged ambiguous action.
- Before cleanup that can remove a tree or multiple paths, use the applicable
  guarded-deletion workflow; retain a known sandbox over unreviewed cleanup.
- Same-role recovery may resume a validated session.
  Cross-product role transfer requires an explicit owner instruction; start a
  new planning session that inherits neither target authority nor predecessor
  phase.

## Route references

Read only current matching references, each completely before its guarded
action:

| Task or phase | Required reference |
|---|---|
| Initialize, reconstruct, plan, or advance to `discussing` | [session-planning.md](references/session-planning.md) |
| Evidence design, production, critique, reconciliation, or `ready-for-execution` | [evidence-review.md](references/evidence-review.md) |
| Stage, monitor, or import | [evidence-exchange.md](references/evidence-exchange.md) |
| Launch a native co-pilot | [native-clients.md](references/native-clients.md) plus both evidence references |
| Execute, validate, or satisfy a duration-bounded request | [execution-duration.md](references/execution-duration.md) |
| Recover, transfer roles, use direct exchange, or diagnose ambiguous interruption | [recovery.md](references/recovery.md) |

Do not normally load legacy aggregate `references/protocol.md`; it is an
unselected compatibility fallback for historical handoffs. For an unknown
phase, validate session state and read recovery before another phase. Use
`--exchange-mode direct` only through that recorded fallback.

Duration requests also select `execution-duration.md` and
`long-running-task-ledger`. The final and durable summaries each require
one timestamped, evidence-backed time-slice entry per requested hour; root
duration policy owns length and no-padding.
