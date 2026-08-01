# Validation, cleanup, and handoff

For each repository:

1. Run focused tests, its declared full suite, dependency and lock checks,
   secret checks, and `git diff --check`.
2. Push a small reviewed commit series and open the repository-owned pull
   request.
3. Require exact current-head checks. After any hosting change, read back live
   Actions, security, environment, and ruleset settings.
4. Merge only through the selected protected workflow, then verify expected
   alert or setting changes.
5. Record commits, pull requests, immutable rule identifiers, checks, external
   state, residue, and remaining stack items in that repository's ledger and
   the umbrella handoff.

Independently recheck applicable logical nodes, redundant routes, managed
service ownership, backups, and changed configuration. Never report an
unverified route pair as healthy.

Use `guarded-bulk-delete` for recursive or multi-path cleanup. Remove only
task-owned residue after identity revalidation. Preserve unrelated worktrees,
files, sessions, and live locks. Verify clean trees and account for every
task-owned stash or helper in its ledger.

For a Harness-opened task tree, run repository-explicit `harness housekeeping
--plan --routine worktrees`, then apply only its exact fresh receipt and token.
An eligible closeout proves the exact merged/ancestor classification, zero
tracked, untracked, or ignored residue, no nested repository, submodule, lock,
process, or open file, and safe Git marker/admin backlinks. Apply archives the
exact tip, guarded-removes the tree and administration record, audits the
archive, and deletes the task branch with an expected-old transaction.
Interrupted stages remain durably recorded; rerun discovery rather than
assuming a missing path means completion.
If the recorded phase is `directory-deleted` or `admin-deleted`, run the
explicit repository-scoped `harness housekeeping --recover-worktree --receipt
STATE` path. It revalidates the immutable plan, archive, current merge
classification, missing directory, administration identity, and exact-old
branch; it creates a fresh guarded administration manifest instead of reusing
an expired token. Unstarted bulk candidates remain for a fresh normal plan.

For duration work, stop starting material changes at the frozen cutoff. Use
the final window for full regression, live-settings readback, fleet health,
residue, clean-tree, branch/worktree, and ledger checks.
At the deadline, stop execution and leave the exact next executable action,
retry safety, and authority requirement in every unfinished repository.
