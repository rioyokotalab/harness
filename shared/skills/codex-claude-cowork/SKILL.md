---
name: codex-claude-cowork
description: Coordinate Codex and Claude for explicit collaboration, comparison, handoff, or duration work through an agreed benchmark, isolated experiments, reciprocal evidence critique, and one target driver.
---

# Codex–Claude cowork

The client handling the owner's request is the **driver**; the other native
client is the **co-pilot**. Do not grant either product a permanent senior role
or substitute a same-product subagent for the other client.

## Always enforce

- Keep the closest repository instructions, ledger, safety skills, and owner
  authority controlling. Cowork never grants credential access, external
  writes, publication, deployment, package installation, scheduler use,
  messaging, destructive cleanup, or target mutation that the underlying task
  did not independently authorize.
- Reconstruct the target, Git state, ledger, and mutable external state before
  changing it. Preserve unrelated work. Require both native clients; if the
  co-pilot is unavailable, stop before target execution and never fabricate its
  evidence.
- Separate the target, live exchange, and two disposable sandboxes built from
  one named baseline. Keep credentials, private values, and unrelated data out
  of every sandbox, prompt, stage, seal, receipt, and evidence artifact.
- Planning and co-pilot experiments are read-only with respect to the target.
  Use staged exchange by default and never grant the co-pilot the live session.
  A direct-session write grant is an exceptional, explicitly recorded fallback
  only when the frozen experiment cannot use staging.
- Before every co-pilot window, seal driver-owned live state outside all
  co-pilot-writable trees and retain a recoverable preimage. Make no
  driver-owned live write during the window; any protected change is a stop
  condition.
- Every staged pass requires a driver-only prompt, direct-child stage, external
  seal outside every co-pilot-writable tree, inspected candidate, validated
  `import-copilot`, and verified receipts. A seal, freshness, destination,
  receipt, or crash-ambiguity failure stops; never relaunder or blindly retry
  the stage.
- Treat `status`, `wait-copilot`, candidate state, freshness summaries, and PID
  reachability as advisory observations only. They never authorize import.
- Treat hashes, seals, receipts, file ownership, modes, and process state only
  as the byte-integrity or advisory evidence they actually provide. They do not
  prove authorship, semantic correctness, success, or equivalent Claude/Codex
  confinement. Inspect the returned evidence and protected state independently.
- Let only the driver mutate the target. The frozen benchmark, both role-bound
  agreement records, required evidence imports, owner go status, target
  identity, authority, cleanliness, rollback, and applicable acceptance gates
  must all pass before target execution.
- An original request is a go only when it explicitly orders execution after
  cowork planning within the same frozen scope. Otherwise wait for a new
  explicit `go`. A new material choice, missing evidence, unsafe disagreement,
  identity drift, failed gate, ambiguous partial action, or missing authority
  stops execution and returns the work to owner review.
- Use reviewed native non-prompting client options and the narrowest task
  permissions. Never use a bypass flag merely to make automation pass, weaken a
  safeguard after a client error, or retry an unchanged ambiguous action.
- Before cleanup that can remove a tree or multiple paths, use the applicable
  guarded-deletion workflow. Retaining a clearly identified sandbox is safer
  than unreviewed recursive cleanup.
- Same-role process recovery may resume a validated session in place.
  Cross-product role transfer requires an explicit owner instruction and a new
  session beginning at planning; it cannot inherit target authority or the
  predecessor's phase.

## Route references

Read only the references selected by the current task or phase, but read each
selected file completely before its guarded action:

| Task or phase | Required reference |
|---|---|
| Initialize, reconstruct, plan, or advance to `discussing` | [session-planning.md](references/session-planning.md) |
| Run independent/reciprocal evidence, stage, monitor, import, reconcile, or advance to `ready-for-execution` | [evidence-exchange.md](references/evidence-exchange.md) |
| Launch either native co-pilot client | [native-clients.md](references/native-clients.md) plus the evidence reference |
| Execute, validate, or satisfy a duration-bounded request | [execution-duration.md](references/execution-duration.md) |
| Recover, transfer roles, use direct exchange, or diagnose ambiguous interruption | [recovery.md](references/recovery.md) |

Do not load the legacy aggregate `references/protocol.md` during normal routing;
it remains only as an unselected compatibility fallback for historical
handoffs. If the current phase is unknown, validate session state first and
read the recovery reference before choosing another phase.

## Core flow

1. Initialize the durable exchange with
   `scripts/cowork-session init SESSION_DIR --driver codex|claude`, then fill
   the driver-owned charter, plan, and benchmark under the session-planning
   contract. Use `--exchange-mode direct` only through the recorded recovery
   fallback.
2. Freeze the driver's independent evidence before opening the co-pilot
   window. Run a blinded independent stage, then a reciprocal stage. The
   co-pilot writes only its staged candidate; the driver validates and imports
   those exact bytes.
3. Reconcile reproducible evidence rather than client brand. Preserve material
   disagreement and uncertainty. Do not execute by majority vote.
4. After the owner go gate, execute only as driver in small measured steps,
   validate the frozen acceptance criteria, and checkpoint evidence, failures,
   retry safety, residual risks, cleanup, and the exact next action.

## Duration-bounded requests

Use `long-running-task-ledger` together with this skill. Freeze the benchmark,
evidence cadence, and stop conditions before target execution and iterate only
from recorded measurements.

The final summary and durable ledger summary must each contain exactly one
timestamped, evidence-backed time-slice entry per requested hour, rounded up,
plus outcome, validation, residual risks, and exact next action. Each must total
at least `max(300, 50 * ceil(requested hours))` words. A no-change slice names
the stable blocker or wait evidence observed; invented results, subdivided
findings, and padding do not count.
