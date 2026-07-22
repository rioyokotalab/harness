# Harness repository instructions

These project rules supplement the shared global agreements in
`.codex/AGENTS.md`.

## Start and resume

- Treat Git and `TODO.md` as the durable source of truth. Do not rely on a
  previous Codex or Claude conversation, client auto-memory, or an uncommitted
  recollection of external state.
- Before changing anything, read the applicable instructions and `TODO.md`,
  inspect the current branch and working tree, fetch the collaborative remote,
  and reconstruct the exact next action and blockers.
- Resume only the recorded task. Revalidate scheduler, hosting-service, and
  other mutable external state before acting; a failed query is unknown state,
  not evidence of absence.
- Use `docs/fleet-inventory.md` as the cold-start reference for logical aliases,
  SSH entries, usernames, hostnames, and operating systems.

## Change and validation

- Keep this repository independent of the sibling `website` repository. Do not
  import its scripts, CI, policy files, artifacts, or working-tree state.
- Add focused tests for changed behavior and run `tests/test-phase1.sh` before
  merge. Documentation-only work must at least pass `git diff --check` and the
  relevant focused test; protected CI remains authoritative.
- Publish through the protected `main` workflow without force-push. After a
  merged control-plane change, use guarded `harness fleet-sync` plan/apply to
  synchronize only clean managed checkouts.
- On a managed personal Mac, treat `~/harness` as the live tunnel-control
  checkout: keep it on clean `main` and perform feature work in a separate Git
  worktree. The watchdog tolerates unrelated branch/worktree state, but any
  difference in its runtime-critical scripts or public Mac profile inputs must
  continue to fail closed.

## Handoff

- Before yielding unfinished work, update `TODO.md` with verified results,
  exact identifiers, failures and retry safety, modified files, completed and
  remaining checks, the next executable action, and any authority boundary.
- Keep bulky reproducible evidence in Git-tracked artifacts and link to it from
  the ledger. Never put credentials, private environment values, or chat-only
  assumptions in a handoff.
