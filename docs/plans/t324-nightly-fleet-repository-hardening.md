# T-324 nightly fleet and repository hardening

## Objective and deadline

Perform lock-aware Local housekeeping, then audit and harden the managed fleet
and the independent `harness`, `students`, `swallow`, and `website`
repositories from 2026-07-27 22:13 JST through 2026-07-28 05:13 JST.
Stop starting material changes at 04:13 JST and reserve the final hour for
regression, live-state readback, residue checks, and durable handoff.

## Frozen owner decisions

- The owner's instruction to begin immediately is the execution gate.
- Resolve every safe in-scope finding immediately using a repository-local
  LIFO stack.
- Defer, but durably record, any item requiring owner confirmation,
  administrator authentication, credentials, hosting administration,
  deployment, publication outside ordinary protected Git, external messaging,
  package installation, reboot, TCC, or another authority not already granted.
- Preserve unrelated work, active sessions, private state, and all repository
  ownership boundaries.

## Scope and non-goals

Inventory all managed logical Linux nodes and both routes for every managed
Mac. Audit reachability, capacity/inodes, backup schedule state, managed agent
and service health, SSH/control-plane consistency, and applicable security
posture through native value-free interfaces. Audit each repository's own
instructions, ledger, branch/upstream/worktree state, dependency locks,
workflows, permissions encoded in Git, tracked-private-path exclusions, and
test/CI contracts.

Do not inspect credentials, panes, transcripts, private file contents, or
unrelated project data. Do not infer a finding from an unavailable query.
Do not perform blanket package upgrades, deployment, external messages,
administrator changes, or GitHub settings/API mutations without separately
established authority. Do not make sibling repositories depend on Harness.

## Execution

1. Complete Local arg0 housekeeping through its lock-aware guarded workflow.
2. Reconstruct every repository from its closest instructions and ledger;
   fetch collaborative remotes, preserving dirty work and using isolated
   worktrees for any implementation.
3. Capture a value-free host inventory and repository-control matrix. Classify
   each row as pass, finding, expected, unavailable, or unknown.
4. Push each confirmed issue onto its owning repository's LIFO stack. Fix the
   newest safe issue first with focused regression and proportional full
   validation. Defer authority-gated items in place and continue independent
   safe work.
5. Publish repository changes only through explicit task branches and protected
   workflows. Re-read mutable state immediately before and after each action.
6. At 04:13 JST stop new material changes. Run final tests, clean-tree and
   residue checks, backup/service readback, and canonical fleet health.
7. Record exact commits, pull requests, live identifiers, failures, retry
   safety, deferred authority, and the next executable action in each owning
   ledger.

## Acceptance and rollback

Housekeeping reports no eligible or unexpected residue while preserving live
locks. Every reachable target and repository has a classified audit row.
Every safe confirmed finding is fixed and independently validated or remains
on a precise LIFO stack with retry safety. Every authority-gated item is
deferred without mutation. Changed repositories pass their focused/full
contracts and protected publication route. Changed hosts pass native readback,
and all route or service failures are reported as failed or unknown rather
than silently accepted.

Rollback is per small repository commit or existing transactional Harness
command. Never force-push, broad-stash, raw-recursively delete, or restore over
unrelated work.
