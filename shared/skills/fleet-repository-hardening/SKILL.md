---
name: fleet-repository-hardening
description: Audit or harden multiple repositories or fleet nodes using independent ledgers, isolated worktrees, frozen decisions, repository-local LIFO issue stacks, protected changes, and deadline handoff.
---

# Fleet and Repository Hardening

Keep each repository operationally independent: preserve its instructions,
ledger, branch, worktree, validation, publication route, and lifecycle locks.
Never make a sibling repository depend at runtime on this skill or the
coordinating harness. Never stash pre-existing owner or agent work.

## Compose only triggered workflows

- Apply `plan-interview-execute` only for an owner-requested plan, interview,
  separate explicit `go`, or a still-open material choice. Do not add an
  interview or confirmation to frozen, authorized execution.
- Apply `long-running-task-ledger` to multi-session, deadline-bound, or
  duration-specified work.
- Apply `evidence-first-research` to current advisories, entitlements, vendor
  guidance, or security claims.
- Apply `operate-native-hpc` before scheduler or allocation work.
- Apply `guarded-bulk-delete` before recursive or expanded multi-path cleanup.

## Route exact working context

Reconstruct the recorded phase, then read every matching reference completely
before its action. Do not preload later phases or unrelated host types.

| Current action | Read completely |
| --- | --- |
| reconstruct, discover, benchmark, freeze decisions, or establish authority | [planning.md](references/planning.md) |
| inspect repository or hosting controls | [repository-audit.md](references/repository-audit.md) |
| inspect Linux or HPC hosts | [linux-audit.md](references/linux-audit.md) |
| inspect macOS hosts | [macos-audit.md](references/macos-audit.md) |
| implement a frozen repository or host change | [execution.md](references/execution.md) |
| handle any ambiguity, failed gate, or blocker | [issue-stack.md](references/issue-stack.md), in addition to the current phase |
| validate, publish, clean task residue, reach a cutoff, or hand off | [closeout.md](references/closeout.md) |

When the phase or target type changes, read the newly selected reference before
continuing. If the phase, ownership, or authority cannot be reconstructed,
stop target mutation and record that unknown state in the owning ledger.

Do not mutate target state until `planning.md` has established frozen material
choices and execution authority. Keep unaffected repositories progressing
independently; one blocked stack must not acquire another repository's lock,
alter its ledger, or stop its safe work.
