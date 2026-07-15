---
name: plan-interview-execute
description: Run a thorough, ledger-backed Plan–Interview–Execute (PIE) workflow for consequential, ambiguous, multi-step, or multi-session work. Use when the owner asks to plan first, resolve choices interactively or one question at a time, wait for an explicit go, execute autonomously afterward, or make work resumable without relying on chat context.
---

# Plan–Interview–Execute

Use the repository ledger as the source of truth for all three phases. Keep the
on-disk plan exhaustive and user updates compact. Do not treat conversation
history as durable state.

## Establish durable state

1. Read all applicable repository instructions and the declared task/session
   ledgers completely before acting.
2. Reconstruct Git status, current task ownership, verified facts, prior
   decisions, blockers, working files, and the last safe next action.
3. Reuse the repository's ledger schema. If none exists, establish the smallest
   project-local task and session ledger allowed by repository instructions
   before planning; do not create a competing ledger.
4. Assign a stable task ID and record phase, status, scope, non-goals, working
   set, open decisions, and next action.
5. Use these phase states consistently:
   `planning`, `interviewing`, `ready-for-go`, `executing`, `validating`, and
   `complete` or `blocked`.

## Phase 1: Plan

Perform safe read-only discovery before asking the owner questions. Inspect the
actual system, repository, and existing evidence so the interview contains only
decisions that cannot be resolved from facts.

Write a thorough step-by-step plan to the ledger that includes:

- desired outcome, explicit scope, non-goals, and authority boundaries;
- current-state inventory with confirmed facts separated from assumptions;
- dependencies, ordering constraints, conflicts, and external blockers;
- a numbered execution sequence with exact working surfaces;
- risks, failure modes, safety gates, rollback or recovery paths;
- validation and acceptance criteria for every material stage;
- decision register with a recommended default and consequences per option;
- checkpoint cadence, interruption behavior, and the next executable action.

Do not mutate the target system during planning beyond narrow ledger updates.
Read-only probes and disposable validation that cannot affect the target are
allowed. If planning discovers a material scope change, checkpoint it and keep
the phase at `planning`.

When the plan is coherent, set the phase to `interviewing` and give the owner a
compact summary: outcome, major stages, material risks, and number of unresolved
decisions. Keep the complete detail in the ledger.

## Phase 2: Interview

Ask exactly one decision question at a time.

1. Ask only questions whose answers materially affect scope, behavior, risk,
   cost, or external state. Resolve discoverable facts yourself first.
2. State the recommended choice first and explain its practical consequence in
   one or two sentences. Present a small set of mutually exclusive options when
   useful.
3. After every answer, immediately checkpoint the selected value, rationale,
   affected plan steps, and next unresolved question in the ledger.
4. Preserve the owner's exact constraint when paraphrasing could change its
   meaning. Never store secrets or credential contents.
5. If an answer invalidates earlier assumptions, revise the on-disk plan and
   report the delta before asking the next question.
6. Do not execute target changes during the interview. Safe read-only checks may
   continue when they eliminate another question.

Do not batch a questionnaire, repeat settled questions, or make the owner
re-read the full plan after every answer. On interruption, resume from the one
next unresolved ledger question.

After the final answer, audit the decision register for gaps and contradictions.
Set the phase to `ready-for-go`, state that all required input is collected, and
summarize the frozen execution order, safety boundaries, and acceptance gates.
Wait for an explicit owner instruction such as `go`, `proceed`, or `execute`.

The go instruction authorizes only the frozen plan. It does not override
credential, deletion, publication, deployment, messaging, package, scheduler,
or other authority boundaries in applicable instructions.

## Phase 3: Execute

After go, reconstruct the frozen plan and decisions from disk before changing
the target. Do not rely on the interview remaining in context.

1. Set the phase to `executing` and record the exact first step.
2. Execute in small, ordered, independently verifiable steps. Use applicable
   safety or domain skills and native commands required by the environment.
3. Before each material step, revalidate its preconditions, target identity,
   authority, and relevant drift. Afterward, run its planned acceptance check.
4. Checkpoint the result, evidence pointer, changed files/state, and exact next
   action immediately. Record failures verbatim when safe, whether retry is
   safe, and what remains unchanged.
5. Continue autonomously through decisions already settled. Stop only for a new
   material choice, a failed safety gate, missing authority, contradiction, or
   external blocker; set the ledger status accordingly.
6. Keep the owner informed at the requested cadence during long work. Progress
   reporting does not replace ledger checkpoints.

When implementation is finished, set the phase to `validating` and run every
planned end-to-end, regression, safety, cleanup, and state-consistency check.
Independently inspect the actual diff or external state; generation alone is not
acceptance.

Mark `complete` only when all acceptance gates pass and no required work
remains. Record commits, unpushed state, remaining proposals, and any excluded
external actions. Leave a restartable final handoff with the outcome, modified
surfaces, checks, residual risks, and next action.

## Resume safely

On any later `continue` or `resume` request:

- reload instructions, task ledger, session state, and working-tree status;
- verify the last recorded result against current state;
- resume the recorded phase rather than restarting the workflow;
- during `interviewing`, ask only the next unresolved question;
- during `ready-for-go`, continue waiting unless the owner explicitly goes;
- during `executing` or `validating`, continue from the first unverified step.
