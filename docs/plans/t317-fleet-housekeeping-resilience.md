# T-317 503-safe fleet and repository housekeeping

## Objective

First make the three existing Local remote-backed Codex tmux sessions
recoverable from classified transient provider exits without changing their
thread identities. Only after matched validation, plan and execute major
housekeeping across the declared fleet and repositories while preserving
active Students and Swallow work.

## Confirmed starting state

At 2026-07-27 08:18 JST:

- Local tmux has exact remote-backed `harness`, `students`, and `swallow`
  windows, all connected to unchanged app-server PID `2852569`.
- Their native TUI process chains are direct launches, not children of
  `harness-codex-resilient`.
- Current resilient state is stale for `harness` and absent for the other two
  names.
- The deployed supervisor retries classified transient exits with bounded
  backoff, but accepts only local selectors. It cannot retain `--remote
  unix://` plus an exact thread ID.
- Fleet health passes Local, ab, ab2, ri, al, rc, t4, redundant abq routes,
  and both routes for aist, home, office, and riken.
- Local arg0 housekeeping inventory is `live=5 eligible=7 young=0
  unexpected=0 removed=0`.

## Non-goals and protection boundary

- Do not read pane contents, send agent prompts, restart the shared app server,
  replay an owner prompt, or alter saved thread identity.
- Do not signal, replace, or detach Students or Swallow during planning.
- Do not clean a repository with an active or ambiguously owned dirty tree.
- Do not perform package upgrades, scheduler changes, backup deletion,
  credential work, external messages, hosting administration, or recursive
  deletion without the separately frozen authority and safety gates.
- Use metadata/process/socket identity only to protect active agents.

## Planned stages

1. Freeze owner decisions for resilience-first sequencing, exact fleet and
   repository scope, allowed housekeeping classes, active-job policy, and
   deadline/cutoff.
2. Add an exact remote selector to the resilience supervisor, with tests that
   prove the endpoint and thread ID survive every retry and prompt replay is
   impossible.
3. Validate the new mechanism in an isolated fake launcher and disposable
   remote-control smoke; do not touch live project agents.
4. Transition `harness` first through an exact staged replacement and verify
   retry behavior. Transition Students and Swallow only after their protected
   identities and owner-approved idle gate pass.
5. Build read-only per-host and per-repository inventories using native health,
   storage, backup, scheduler, Git, and hosting interfaces. Create independent
   repository-local tasks/worktrees before any repository mutation.
6. Process housekeeping as small repository-local LIFO stacks. Apply guarded
   deletion for every tree or multi-path cleanup. Never stash or overwrite
   unrelated work.
7. Stop material work at the frozen cutoff; run full repository and fleet
   readback, record residue and blockers, and leave exact restartable actions.

## Acceptance gates

- Each protected Local window resumes its exact root through `--remote
  unix://` after a matched injected transient exit, with bounded backoff and no
  prompt replay.
- Students and Swallow retain their exact thread IDs and connected app-server
  peers throughout the transition.
- Every affected repository owns its ledger, branch/worktree, tests, commits,
  and publication route.
- Every removed tree has a guarded-delete manifest and verified boundary.
- Final fleet health, backups, active schedulers, managed services, Git trees,
  and hosting controls are read back independently.

## Decision register

### D-001 — Resilience prerequisite

Recommended: implement and validate remote-aware resilience first, transition
Harness as the canary, and postpone all housekeeping until Harness passes.
Students and Swallow remain untouched until the canary is accepted.

Alternative: leave the current direct clients unchanged and restrict
housekeeping to operations proved unable to affect their processes, sockets,
storage, repositories, or dependencies. This substantially narrows
housekeeping and does not satisfy the requested 503-resistant prerequisite.

**Status:** unresolved.

## Interruption contract

After interruption, reload this plan and `TODO.md`, then revalidate Git, tmux,
exact process start identities, socket peers, resilient status, active jobs,
and repository worktrees. A failed or ambiguous launch, signal, retry, or
deletion must never be replayed without read-only reconciliation.
