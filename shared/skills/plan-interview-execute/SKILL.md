---
name: plan-interview-execute
description: Use when the owner explicitly requests planning/interview/go, a material owner choice remains open, or an existing PIE ledger must resume; skip fully frozen authorized execution.
---

# Plan–Interview–Execute

Use the repository ledger as the source of truth. Keep the on-disk plan
exhaustive and user updates compact; conversation history is not durable state.

## Select one phase route

First reconstruct the ledger's current phase and read exactly one matching
reference before phase work:

- new or `planning`: [planning.md](references/planning.md);
- `interviewing` or `ready-for-go`: [interview.md](references/interview.md);
- authorized `ready-for-go`, `executing`, or `validating`:
  [execution.md](references/execution.md).

Do not preload later-phase references. When a phase transition occurs, read
the newly selected reference completely before taking its phase actions.

## Apply the trigger boundary

Use PIE only for an explicit plan/interview/go request, an unresolved material
owner decision that requires an interview, or a task already recorded in a PIE
phase. Do not invoke it merely because ordinary work is consequential,
ambiguous, multi-step, multi-session, or ledger-backed.

If the owner supplied a complete frozen plan, resolved all material choices,
and explicitly authorized execution, use the applicable domain and ledger
workflows without starting another interview. For an existing task at
`ready-for-go`, an explicit `go` resumes Phase 3 directly. Never repeat settled
questions. If planning finds no unresolved decision, move to `ready-for-go`;
do not manufacture an interview.

## Preserve the durable contract

Before phase work, read applicable repository instructions and the declared
task/session ledgers completely. Reconstruct Git state, task ownership,
verified facts, prior decisions, blockers, working files, and the last safe
next action. Reuse the repository's ledger schema; if none exists, create only
the smallest project-local ledger allowed by repository instructions.

Record a stable task ID, phase, status, scope, non-goals, working set, open
decisions, and exact next action. Use only `planning`, `interviewing`,
`ready-for-go`, `executing`, `validating`, `complete`, or `blocked`.

On `continue` or `resume`, verify the recorded result against current state and
resume that phase: ask only the next unresolved interview question, wait at
`ready-for-go` without an explicit go, or continue from the first unverified
execution/validation step.

The go instruction authorizes only the frozen plan. It does not override
credential, deletion, publication, deployment, messaging, package, scheduler,
or other authority boundaries in applicable instructions. Stop for a new
material choice, failed safety gate, missing authority, contradiction, or
external blocker; checkpoint the exact reason and retry safety.
