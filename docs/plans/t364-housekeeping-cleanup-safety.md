# T-364 plan — Safe repository cleanup and durable recovery evidence

## Outcome, scope, and non-goals

Harden `harness housekeeping` so branch and worktree cleanup is evidence-based,
race-resistant, durable across Git garbage collection, and independently
auditable. Repair the recovery-evidence gap from the 2026-08-01 cleanup without
recreating obsolete worktrees or branch names.

In scope:

1. durable archive refs, verified Git bundles, and schema-versioned receipts;
2. exact local-branch eligibility tied to pull-request head identity;
3. report-only remote-branch inventory;
4. strict worktree teardown planning and guarded application;
5. audit/recovery commands and synthetic regression tests; and
6. protected publication and normal managed-checkout synchronization.

Out of scope:

- restoring or deleting a current branch, worktree, remote ref, user file,
  credential, backup, project workspace, or evidence bundle;
- remote-ref deletion as an autonomous or routine operation;
- changing hosting settings, GitHub rulesets, approval counts, or retention;
- choosing T-363's alternating-client design or cleaning Students worktrees;
- rewriting history, force-pushing, or treating patch similarity as merge
  proof; and
- deleting Codex arg0 residue, whose independent lock-aware workflow remains
  unchanged.

## Confirmed current state

- Harness is clean on `main` at
  `dda8acac07a4e4f739228777e12a7d1bcf5d593f`, equal to `origin/main`, with one
  local branch and one registered worktree.
- Git connectivity, `tests/test-housekeeping.sh`, task-ledger routing, and
  `git diff --check` pass.
- Five prior `/tmp` task worktree paths are absent. T-354 records two as clean;
  the other three lack durable deletion receipts, so their former untracked or
  ignored state is unknowable after deletion.
- The local cleanup receipt records four branches, all associated with merged
  pull requests. T-354 records two more retired branches, and T-362 records one
  closed T-361 branch whose implementation bytes match merged PR #525.
- A mode-0600 runtime receipt records 20 remote branch deletions. Nineteen
  names are associated with merged PRs or tips already reachable from `main`;
  `codex/t354-project-root-migration` had no PR and is explicitly superseded by
  the more complete current T-354 record.
- The remote deletion crossed T-362's explicit non-goal and is not recorded in
  a tracked task record. Current remote inventory contains only `main`.
- Every recorded tip object exists now, but at least seven have no containing
  ref. A SHA written in a receipt does not prevent future Git pruning.
- Current arg0 inventory is independently healthy but not empty: 35 live, 69
  eligible, 0 young, 0 unexpected, and 0 removed by this audit.

The audit artifact contains the exact classifications and recovery caveats.

## Decision register

### D-001 — Current cleanup outcome

Frozen: preserve the current one-branch/one-worktree state. Restoring obsolete
names would add risk without recovering intended content.

### D-002 — Recovery durability

Frozen: before deleting any ref, atomically create local archive refs under
`refs/harness-housekeeping/archive/<transaction>/`, create a mode-0600 Git
bundle under `${XDG_STATE_HOME:-$HOME/.local/state}/harness/housekeeping/`, run
`git bundle verify`, and atomically publish a receipt containing repository
identity, candidate names, exact tips, PR identifiers, classification, bundle
digest, restore commands, and timestamps. Retain archive refs for at least 30
days; archive-ref expiry is report-only until separately implemented.

### D-003 — Local branch classification

Frozen: a branch is eligible only when it is not current or worktree-held and
one of these exact conditions holds:

1. its current tip equals the recorded head OID of a merged PR; or
2. its current tip is an ancestor of freshly fetched `origin/main`.

A merged PR with the same branch name but a different current tip is not
enough. Squash-merged tips qualify only through exact PR-head equality. Closed,
absent, ambiguous, API-failed, or advanced-after-merge branches are report-only.
Delete an eligible local ref with an expected-old OID transaction, never a
blind `branch -D`.

### D-004 — Remote branches

Frozen: Harness inventories remote branches and reports merged/advanced/open,
but provides no apply path. This restores the documented authority boundary
and avoids a race between readback and remote deletion. Any future remote
deletion requires a separate owner-authorized task and hosting/Git policy.

### D-005 — Worktree teardown

Frozen: a candidate must be a linked non-primary worktree under an allowlisted
scratch boundary, user-owned, real, unlocked, and mapped to one exact Git admin
record. Require zero modified/staged tracked files, zero untracked files, zero
ignored files, no nested repository or submodule, and no live process cwd or
open file beneath it. Require its branch to satisfy D-003 or an explicit
superseded decision recorded in the active task.

Deletion is a two-checkpoint guarded transaction: first guarded-delete the
exact worktree directory; then, after proving the primary repository and
archive remain intact, separately guarded-delete its exact `.git/worktrees/`
administration directory. A failure between stages is recoverable by the
recorded admin path and `git worktree prune` diagnosis; never force-remove.

### D-006 — T-363 boundary

Frozen: T-364 supplies a safe cleanup primitive and evidence contract. T-363
still decides whether routine Codex/Claude work uses per-turn worktrees and an
observability lease. T-364 neither chooses nor deploys that lifecycle.

No material decision remains open.

## Ordered execution

### Stage 0 — Protect the currently recorded tips

Before any lengthy implementation, revalidate that all 21 unique recorded tip
objects still exist. Create transaction-scoped archive refs for each exact tip,
write and verify one durable bundle, and publish one atomic receipt. Do not
restore branch names and do not touch remotes. If an object is missing, stop
and record it as unrecoverable; never substitute a guessed commit.

### Stage 1 — Durable receipt and archive library

Add a focused native helper used by housekeeping. It validates repository and
state-root identity, rejects symlinks and hard links, writes through private
temporary files with fsync and atomic rename, creates expected-old archive
refs, verifies bundles, and emits value-free compact status. Add an `audit`
mode that proves every receipt tip is available through a live ref or bundle.

Working surfaces: `libexec/harness-housekeeping`, one focused helper if needed,
`bin/harness` routing only if a new subcommand is required, tests, and compact
documentation.

### Stage 2 — Correct local branch eligibility

Replace name-only merged-PR matching with D-003. Freeze candidate name, tip,
PR number, PR head OID, base, merge time, and classification in the plan
receipt. Re-read all mutable values immediately before apply. Archive first,
then delete each exact ref using its expected old OID. Stop the transaction on
the first mismatch; do not partially continue through a changed candidate set.

### Stage 3 — Report-only remote inventory

Report remote branch name, exact tip, matching PR state/head, ancestry to
`origin/main`, and a reason. Never emit or execute a remote deletion command in
routine mode. Explicitly detect the 2026-08-01 failure class: branch name has a
merged PR but its current tip differs from that PR's head.

### Stage 4 — Strict worktree planning and guarded teardown

Add `worktrees` plan output with zero-residue checks, process metadata checks,
branch eligibility, canonical path/admin identities, entry/byte counts, and
archive receipt. Apply consumes only fresh immutable manifests and uses the
two guarded-delete stages in D-005. Any ignored file, untracked file, lock,
submodule, nested repository, live process, identity drift, or branch drift
blocks deletion and remains report-only.

### Stage 5 — Tests and validation

Synthetic tests must cover:

- branch reuse after a merged PR;
- exact squash-merge head acceptance and mismatched-head rejection;
- API failure and ambiguous PR state;
- archive-ref and bundle verification, atomic receipt publication, and restore;
- garbage-collection survival through the bundle;
- dirty tracked, untracked, ignored, nested-repository, submodule, locked, and
  live-process worktree rejection;
- primary worktree, account home, repository root, symlink, hard-link, and
  non-owned path rejection;
- guarded worktree/admin ordering, interruption after stage one, and postcheck;
- remote inventory with no write path; and
- unchanged arg0, launcher, board, evidence, policy, and T-363 boundaries.

Run owning focused tests, task-ledger/context gates, `harness validate` at its
selected risk tier, and full phase one on the final integrated tree.

### Stage 6 — Publication and rollout

Fetch again, publish one protected PR, require hosted checks, fast-forward the
primary checkout while preserving unrelated state, and guarded-sync only clean
managed checkouts. No cleanup apply is part of rollout. Record exact commits,
validation receipts, archive receipt, and fleet-sync results.

## Failure, interruption, and recovery

- Before archive publication, retry only after revalidating all object OIDs.
- After any archive ref is created but before bundle acceptance, retain it and
  resume from archive audit; do not delete it as residue.
- A failed GitHub query is unknown and yields no candidate.
- Candidate drift between plan and apply aborts before ref deletion.
- Interruption after worktree-directory deletion but before admin cleanup is a
  recorded recoverable stale-worktree state; do not repeat directory deletion.
- Bundle or receipt ambiguity blocks every deletion until `audit` resolves it.
- Never replay a remote deletion because T-364 has no remote apply path.

## Acceptance criteria

1. The 21 current tips are protected by verified durable archive evidence.
2. A reused branch with an older merged PR is rejected.
3. A squash-merged exact head remains eligible without diff heuristics.
4. Worktree cleanup cannot remove tracked, untracked, ignored, nested,
   submodule, locked, live, primary, or ambiguous content.
5. Every destructive filesystem target passes guarded-delete identity and
   post-delete checks.
6. No routine command can delete a remote ref.
7. Receipts remain auditable after Git garbage collection and runtime reboot.
8. Existing housekeeping, arg0, task routing, validation, and fleet behavior
   remain passing.

## Checkpoints and next action

Checkpoint after Stage 0, each failed or completed stage, before any guarded
apply, after publication, and after fleet synchronization. The next action is
explicit `go` for this frozen plan. Until then, perform no archive, cleanup,
remote, worktree, branch, or runtime-state mutation.
