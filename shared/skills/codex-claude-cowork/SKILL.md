---
name: codex-claude-cowork
description: Coordinate Codex and Claude Code as a symmetric driver/co-pilot pair through durable files, independent sandbox experiments, reciprocal evidence critique, a frozen plan, and driver-only target execution. Use when the owner asks Codex and Claude to work together, cross-review or challenge a consequential plan, compare both agents empirically, hand a task between the two clients, or have either client drive the other through a reproducible planning-discussion-execution workflow.
---

# Codex–Claude cowork

Use one role-neutral protocol. The client handling the owner's request is the
**driver**; the other native client is the **co-pilot**. Do not grant either
product a permanent senior role, and do not substitute a same-product subagent
for the other client.

Read [references/protocol.md](references/protocol.md) completely before starting.
Use `scripts/cowork-session` to initialize and validate the exchange files.
Keep the closest repository instructions, ledger, safety skills, and authority
boundaries controlling throughout.

## Establish the session

1. Reconstruct the target from its instructions, ledger, Git state, and mutable
   external state before changing it. Preserve unrelated work.
2. Confirm that both native clients are available. Identify the current client
   as driver and the other as co-pilot. If the co-pilot cannot run, stop before
   target execution; never fabricate its evidence.
3. Declare separate paths for the target, a file exchange directory, and two
   disposable sandboxes built from the same named baseline. Keep credentials,
   private values, and unrelated data outside all exchange artifacts.
4. Initialize the exchange directory:

   ```text
   scripts/cowork-session init SESSION_DIR --driver codex
   scripts/cowork-session init SESSION_DIR --driver claude
   ```

5. Fill `charter.md` with the task, scope, non-goals, authority, baseline,
   sandbox construction, acceptance gates, and cleanup policy. The driver owns
   `charter.md`, `plan.md`, `driver-evidence.md`, `reconciliation.md`,
   `execution.md`, and `validation.md`; the co-pilot owns
   the content of `copilot-evidence.md`. By default the co-pilot writes a staged
   candidate inside its sandbox and the driver validates/imports those exact
   bytes; neither client receives a live-session write grant during discussion.

## Phase 1: Plan

Have the driver write a numbered initial plan to `plan.md`. Separate confirmed
facts from assumptions and include dependencies, failure modes, recovery,
evidence questions, and validation for every material step. Planning may use
read-only discovery but must not mutate the target.

Advance to `discussing` only after the charter and plan pass the validator:

```text
scripts/cowork-session advance SESSION_DIR discussing
```

## Phase 2: Test, criticize, and reconcile

1. Give both agents the same charter, plan, baseline, and acceptance gates.
   Withhold the other agent's conclusions until both independent passes finish.
   Create the blinded co-pilot bundle inside its sandbox:

   ```text
   scripts/cowork-session stage SESSION_DIR STAGE_DIR --mode independent
   ```

2. Invoke the co-pilot only against `STAGE_DIR`; do not disclose or grant
   `SESSION_DIR`. Have each agent actually exercise the relevant plan steps in its own
   sandbox. Each evidence file must identify the sandbox and baseline, list
   commands or tool actions and observed results, distinguish observations from
   inferences, criticize concrete plan claims, and propose exact plan changes.
   A prose-only review is insufficient when an experiment is safe and feasible.
3. Inspect the candidate, then run `scripts/cowork-session import-copilot
   SESSION_DIR STAGE_DIR`. Import only when it reports fresh, valid evidence.
   Record the candidate hash and retain the stage for recovery.
4. Reveal both evidence files. Create a fresh `--mode reciprocal` stage and
   require the co-pilot to return its complete evidence with a reciprocal
   critique. Validate/import it the same way. Each agent tests or traces the
   strongest conflicting claim and states what it accepts, rejects, or cannot
   resolve. Critique evidence and reasoning, never motives or ability.
5. Have the driver write `reconciliation.md`. Preserve material disagreements
   and uncertainty; do not choose a client by brand. Prefer reproducible
   evidence, matched baselines, narrower claims, and safer reversible changes.
   The frozen plan must state which proposals were accepted or rejected and
   why.
6. Advance to `ready-for-execution`. If required evidence is missing,
   contradictory, unsafe, or non-reproducible, remain in discussion or ask the
   owner one material question. Do not execute by majority vote.

```text
scripts/cowork-session advance SESSION_DIR ready-for-execution
```

## Phase 3: Execute as the driver

1. Treat the normal owner go gate as controlling. An original request that
   explicitly orders execution after cowork planning is a go only for that
   frozen scope; otherwise wait for a new explicit `go`.
2. Re-read `state.json`, `charter.md`, and the frozen plan from disk. Revalidate
   target identity, authority, cleanliness, baseline drift, and rollback before
   advancing to `executing`.
3. Let only the driver mutate the target. Execute small steps, validate each
   one, and record commands, results, deviations, and evidence pointers in
   `execution.md`. A new material choice returns the session to owner review; it
   does not inherit authority from the sandbox experiment.
4. Advance to `validating`, run all frozen acceptance and regression checks,
   and record them in `validation.md`. The co-pilot may inspect the final diff
   and challenge validation in a read-only pass, but may not repair the target.
5. Advance to `complete` only when the validator and target acceptance gates
   pass and no required disagreement remains. Checkpoint the repository ledger
   with modified files, evidence paths, failures and retry safety, remaining
   risks, cleanup state, and next action.

## Preserve symmetry and safety

- Invoke the other product through its recognizable native CLI mapping in the
  protocol reference. State the resolved command in the session record. Do not
  hide collaboration behind an opaque wrapper.
- Grant the co-pilot only the sandbox and exchange-file access required by the
  frozen experiment. Never use a bypass flag merely to make automation pass.
- Use staged exchange without `--add-dir SESSION_DIR` by default. Codex
  workspace-write enforces that smaller writable set; Claude without a separate
  OS/container sandbox does not, so around Claude also run
  `scripts/cowork-session digests SESSION_DIR`, keep the result outside the
  session, and retain a recoverable preimage. Hashes detect change;
  they do not prevent it or restore bytes. Direct-session write is an exceptional
  sealed fallback, and read-only mode is only an advisory tripwire.
- Use separate sandboxes and one immutable baseline to prevent accidental
  target mutation and result contamination. Record deviations between
  environments before comparing results.
- Treat client errors, permission denials, timeouts, and unavailable tools as
  evidence, not permission to weaken safeguards. Retry only after recording
  whether prior actions changed state.
- Follow applicable guarded cleanup rules for sandbox removal. Leaving a
  clearly identified sandbox for later safe cleanup is preferable to an
  unreviewed recursive deletion.
- Keep exchange files concise and durable enough for interruption or takeover.
  Raw bulky logs belong in bounded artifact files referenced from the evidence.
