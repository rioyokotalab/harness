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

## Change and validation

- Keep this repository independent of the sibling `website` repository. Do not
  import its scripts, CI, policy files, artifacts, or working-tree state.
- Add focused tests for changed behavior and run `tests/test-phase1.sh` before
  merge. Documentation-only work must at least pass `git diff --check` and the
  relevant focused test; protected CI remains authoritative.
- Publish through the protected `main` workflow without force-push. After a
  merged control-plane change, use guarded `harness fleet-sync` plan/apply to
  synchronize only clean managed checkouts.

## Handoff

- Before yielding unfinished work, update `TODO.md` with verified results,
  exact identifiers, failures and retry safety, modified files, completed and
  remaining checks, the next executable action, and any authority boundary.
- Keep bulky reproducible evidence in Git-tracked artifacts and link to it from
  the ledger. Never put credentials, private environment values, or chat-only
  assumptions in a handoff.
