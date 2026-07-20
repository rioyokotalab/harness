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

   New sessions use staged exchange by default. Use `--exchange-mode direct`
   only for the exceptional sealed direct-session fallback; direct sessions do
   not create staged import receipts.

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
   Have the driver finish `driver-evidence.md` from its sandbox before opening
   the co-pilot client window, then freeze a protected digest manifest. Create
   the blinded co-pilot bundle inside its sandbox, writing a mandatory external
   seal outside both the live session and the stage-parent sandbox:

   ```text
   scripts/cowork-session stage SESSION_DIR STAGE_DIR --mode independent \
     --seal EXTERNAL_SEAL_FILE
   ```

   For a schema-2 staged session `--seal` is required. It writes a real,
   mode-0600, path-free seal committing the exact `stage.json` SHA-256; refuse a
   seal path inside the session or stage-parent tree. Keep each stage a direct
   child of the co-pilot sandbox so that parent is the true sandbox root.

2. Invoke the co-pilot only against `STAGE_DIR`; do not disclose or grant
   `SESSION_DIR`. Have each agent actually exercise the relevant plan steps in its own
   sandbox. Each evidence file must identify the sandbox and baseline, list
   commands or tool actions and observed results, distinguish observations from
   inferences, criticize concrete plan claims, and propose exact plan changes.
   A prose-only review is insufficient when an experiment is safe and feasible.
3. Store the printed `stage_sha256` outside the stage, session, and co-pilot
   sandbox before invocation. Do not write any driver-owned live file during
   the client window. Compare protected and stage-manifest seals after return.
   Inspect the candidate, then run `scripts/cowork-session import-copilot
   SESSION_DIR STAGE_DIR --seal EXTERNAL_SEAL_FILE`. For a schema-2 staged
   session the seal is required: import refuses a seal inside the session or
   stage-parent tree and, before any target write, requires exact owner, single
   link count, non-symlink, schema, roles, mode, phase, destination-before, and
   `stage.json` SHA-256 match. Import only when it reports fresh, valid evidence
   and a receipt path. Run `scripts/cowork-session verify-receipts SESSION_DIR`.
   Retain the stage and external seals for recovery.
4. Reveal both evidence files. Create a fresh `--mode reciprocal` stage with its
   own `--seal` and require the co-pilot to return its complete evidence with a
   reciprocal critique. Seal, validate, import, and verify it the same way. Each agent tests or traces the
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
- Use staged exchange without `--add-dir SESSION_DIR` by default. The staged
  `state.json` is a fail-closed path-free projection: it drops
  `predecessor.path` and refuses any unknown or missing key, so no absolute path
  reaches a blinded co-pilot. Import compares the same projection, so its
  freshness check covers the projected co-pilot-visible state, not withheld
  fields or representation-only reserialization. Codex workspace-write enforces
  that smaller writable set; Claude without a separate OS/container sandbox does
  not, so around Claude also run `scripts/cowork-session digests SESSION_DIR`,
  keep the result outside the session, and retain a recoverable preimage. The
  full-state seal is the control for a change confined to a withheld field.
  Hashes detect change; they do not prevent it or restore bytes. Direct-session
  write is an exceptional sealed fallback, and read-only mode is only an
  advisory tripwire.
- Schema-2 staged sessions create a closed, driver-owned `receipts/` chain. The
  independent and reciprocal receipts bind projected inputs, full live state,
  exact stage metadata, destination-before bytes, the external seal SHA-256, and
  the accepted candidate without storing paths. Ready and later phases require
  both receipts and live-evidence verification. `digests` protects existing
  receipts. Receipt hashes prove byte relationships, not authorship, and ordinary
  rollback is not cross-file crash atomicity. New receipts are schema 2; the
  reader still accepts schema-1 receipts already written into a schema-2 session,
  and strict schema-1 predecessor sessions remain valid without receipts.
- The external seal is the anchor that makes the co-pilot-writable `stage.json`
  trustworthy: `stage --seal` commits its exact SHA-256 to a path-free mode-0600
  file the driver holds outside every co-pilot-writable tree, and `import --seal`
  refuses any mismatch before mutation, closing the crash-then-relaunder path. The
  seal binds stage *content*, not identity or location: two byte-identical stages
  share a valid seal, harmlessly. It does not prove authorship, create OS
  confinement, protect a seal placed where the co-pilot can write, or make
  stage+seal or evidence+receipt writes crash-atomic; `verify-receipts` checks the
  stored seal hash and chain but does not reopen the external seal bytes.
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
