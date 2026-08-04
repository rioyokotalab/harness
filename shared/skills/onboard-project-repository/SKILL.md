---
name: onboard-project-repository
description: Onboard or migrate one Git project to a repository-native producer/consumer ledger with independent publication and project-specific policy separation.
---

# Onboard Project Repository

Create an independently operable repository whose producer normally curates
durable work and whose consumers execute selected packets. Preserve existing work
and keep project-specific privacy, source, compute, deployment, and authority
rules local.

## Route

1. Read the target root policy and Git state. Confirm its identity, visibility,
   task prefix, protected branch, validation entrypoint, consumer clients, and
   publication route.
2. Read [protocol.md](references/protocol.md) completely.
3. Inventory existing task ledgers and reconcile IDs; never renumber history or
   overwrite a live task.
4. Adapt the files under `assets/scaffold/` through normal patch-based edits.
   Assets are templates, not authority: retain stronger target rules and omit
   features the target cannot validate.
5. Add focused synthetic tests for advisory role overlap, immutable packets, selector lifecycle,
   queue parity, reversible parking, terminal reconciliation, bounded records,
   proportional validation, and any enabled checkpoint protocol.
6. Avoid overlapping branches where practical, validate the complete atomic
   ledger change, and publish through the target's protected route. Verify
   protected readback and leave no temporary branch or worktree residue.

Never copy private task content between repositories. Producer and consumer
have the same repository capabilities; producer-path ownership is a strong
coordination default, not a permission boundary. A consumer may edit those
paths when an in-scope solution requires it after checking overlap, recording
the reason, and preserving all ledger invariants. A ready packet does not grant
source access, credentials, deployment, account changes, or another external
mutation unless its local policy and contextual owner authority do.
