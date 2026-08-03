---
name: fleet-repository-hardening
description: Audit or harden multiple repositories or nodes with independent ledgers, isolated worktrees, frozen decisions, repository-local LIFO issue stacks, protected changes, and deadline handoff.
---

# Fleet and Repository Hardening

Keep repositories independent: preserve instructions, ledger, branch,
worktree, validation, publication, and lifecycle locks. Never make a sibling
depend at runtime on this skill or Harness, or stash pre-existing work.

## Compose only triggered workflows

- Apply `plan-interview-execute` only for an owner-requested plan, interview,
  separate explicit `go`, or open material choice. Do not add an interview or
  confirmation to frozen authorized execution.
- Apply `long-running-task-ledger` to multi-session, deadline, or duration work.
- Apply `evidence-first-research` to current advisory, entitlement, vendor, or
  security claims.
- Apply `operate-native-hpc` before scheduler/allocation work.
- Apply `guarded-bulk-delete` before recursive or multi-path cleanup.

## Route exact working context

Reconstruct the recorded phase and read each matching reference completely
before acting. Do not preload later phases or unrelated host types.

| Current action | Read completely |
| --- | --- |
| reconstruct, discover, benchmark, freeze choices/authority | [planning.md](references/planning.md) |
| inspect repository or hosting controls | [repository-audit.md](references/repository-audit.md) |
| inspect Linux/HPC hosts | [linux-audit.md](references/linux-audit.md) |
| inspect macOS hosts | [macos-audit.md](references/macos-audit.md) |
| implement a frozen repository/host change | [execution.md](references/execution.md) |
| handle ambiguity, failed gate, or blocker | [issue-stack.md](references/issue-stack.md), plus the current phase |
| validate, publish, clean residue, reach cutoff, or hand off | [closeout.md](references/closeout.md) |

Read the selected reference when phase or target type changes. If phase,
ownership, or authority cannot be reconstructed, stop target mutation and record that unknown state in the owning ledger.

Do not mutate target state until `planning.md` has established frozen material
choices and authority. Keep unaffected repositories progressing: one blocked stack must not acquire another repository's
lock, alter its ledger, or stop its safe work.
