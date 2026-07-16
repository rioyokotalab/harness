---
name: onboard-mirrored-node
description: Safely onboard a newly configured SSH alias into the mirrored harness fleet with ledger-backed planning, value-free discovery, strict declarations, transactional bootstrap, storage migration, and manual backup/restore validation. Use when the owner adds a new node to SSH configuration and asks to mirror the existing control plane or run `onboard HOST`.
---

# Onboard Mirrored Node

Use the Plan–Interview–Execute skill and the repository's durable ledger. Treat
`onboard HOST` as a workflow invocation, not as permission to enumerate or read
SSH configuration. `HOST` is the complete discovery boundary.

## Establish the boundary

1. Read repository instructions, the task ledger, and the existing fleet,
   storage, shell, backup, and recovery documentation.
2. Fetch and reconcile the repository before changing it. Require a clean,
   exact source revision; preserve unrelated changes and never force-push.
3. Run `scripts/onboard-preflight validate HOST`. Stop on malformed, reserved,
   service, proxy, existing, or colliding identifiers.
4. Create or resume one stable ledger task. Record the source commit, scope,
   exclusions, facts, decisions, safety gates, rollback, acceptance criteria,
   and exact next action.

Do not enumerate `~/.ssh/config`, resolve aliases beyond the supplied `HOST`, or
probe neighboring systems. The go instruction never grants package, scheduler,
credential, deletion, publication, or deployment authority that was not in the
frozen plan.

## Plan from value-free facts

Run `scripts/onboard-preflight inventory HOST`. It makes one read-only,
BatchMode SSH connection, executes the repository's self-contained inventory
helper over standard input, stores output only in a private short-lived file,
and validates schema and logical identity before returning it. Do not replace
this with shell startup, environment, home traversal, or credential inspection.

Read [references/declarations.md](references/declarations.md). Reconcile the
inventory with existing site patterns and record confirmed facts separately
from hypotheses. Plan these stages in order:

1. tracked declarations and fixture;
2. clean-revision remote bootstrap;
3. control-plane, shell, Vim, and approved SSH-fragment convergence;
4. approved hidden-state migration and cleanup;
5. primary Restic snapshot, check, and restore proof;
6. independent encrypted generation and restore proof;
7. idempotence, interaction, non-interaction, and recovery validation.

Ask exactly one owner question at a time only for facts or choices that cannot
be discovered safely: persistent and cache roots, hidden-state policy, replica
route, or missing-package authority. Recommend a default and checkpoint each
answer. Never request or record a secret. The Restic password remains a single
owner-only checkpoint: the owner creates and externally retains the unique
mode-0600 file; agents validate metadata and pass its path only.

Scheduling is excluded. Do not create scheduler jobs, cron entries, or a
schedule declaration during onboarding. Defer them until manual snapshot,
check, restore, and independent-replica restore evidence is stable and the
owner separately authorizes scheduling.

When all decisions are frozen, set the task to `ready-for-go`, summarize the
execution and safety gates, and wait for explicit `go`.

## Stage and validate declarations

After go, reconstruct the plan from the ledger. Generate every required tracked
declaration in a staging worktree or other non-live surface. Reject ambiguous
OS, scheduler, quota, filesystem, root, symlink, or schema state rather than
guessing. Never overwrite an existing declaration.

Validate the focused onboarding tests, full repository suite, shell syntax,
fixture privacy, map uniqueness, and exact diff. Commit only the intended files
in a small checkpoint. Fetch/reconcile again and push only when the owner or
repository instructions authorize it.

## Bootstrap the exact revision

Transfer a verified, credential-free Git bundle of the exact clean commit. Do
not copy a working tree, SSH configuration, Git credentials, Restic password,
or agent state. Verify bundle mode and commit identity, then create a checkout
or fast-forward an existing clean checkout. Stop on remote dirt, divergent
history, wrong identity, or unexpected symlinks. Exact-unlink the short-lived
bundle after verified use.

Run every mutating harness command in `plan` mode first and save the value-free
plan in the ledger. Revalidate the remote identity and roots immediately before
apply. Use the existing transactional harness operations for control-plane
links, shell blocks, dotfiles, and portable tools.

## Migrate and back up safely

Follow the approved row in `profiles/home-layout.tsv`. Retain a verified copy
until link targets, applications, and backup restore tests pass. Before any
recursive, wildcard, synchronization-with-deletion, or multi-path cleanup, use
the guarded-bulk-delete skill and its deterministic plan/apply tool. Never run
raw recursive deletion.

Follow `docs/home-backup.md` for primary repository initialization, manual
snapshot, repository check, representative restore, independent encrypted
generation, credential-safe validation, and independent restore. Do not infer
success from process exit alone. Preserve evidence without recording secrets.

## Accept and hand off

Require all of the following before completion:

- the remote checkout is clean at the recorded revision and `harness doctor`
  passes twice without new changes;
- login and non-interactive SSH behavior is correct and non-interactive
  sessions produce no prompt or unsolicited output;
- Vim and only the approved SSH config fragments converge;
- storage targets, retained-copy recovery, and quota behavior match the plan;
- primary snapshot/check/restore and independent-generation restore proofs pass;
- temporary bundles, plans, and staging artifacts are absent through exact,
  verified cleanup; and
- the ledger records commits, pushed state, evidence, exclusions, residual
  risks, and the next separately authorized action.

If a safety gate fails, leave live state unchanged where possible, preserve the
last known-good copy, checkpoint the exact failure, and stop for the new
material decision or missing authority.
