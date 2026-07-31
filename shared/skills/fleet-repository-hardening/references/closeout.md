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

For duration work, stop starting material changes at the frozen cutoff. Use
the final window for full regression, live-settings readback, fleet health,
residue, clean-tree, branch/worktree, and ledger checks.
At the deadline, stop execution and leave the exact next executable action,
retry safety, and authority requirement in every unfinished repository.
