---
name: onboard-mirrored-node
description: Onboard a newly configured SSH alias into the mirrored Harness fleet using ledger-backed discovery, declarations, transactional bootstrap/storage migration, and backup/restore validation.
---

# Onboard Mirrored Node

Treat `onboard HOST` as a workflow invocation. Use Plan–Interview–Execute and
the ledger. `HOST` is the complete discovery boundary.

## Route the current phase

From the ledger, select exactly one row and read all its references before
acting. Do not preload later or unrelated phases. A phase change triggers only
its new row. References never select one another. An unknown phase stops.

| Current action | Read completely |
| --- | --- |
| discover, plan, interview, or await `go` | [planning-interview.md](references/planning-interview.md) |
| stage or validate declarations after `go` | [declarations-phase.md](references/declarations-phase.md) and [declarations.md](references/declarations.md) |
| bootstrap the revision or migrate storage/state | [bootstrap-migration.md](references/bootstrap-migration.md) |
| back up, restore, accept, or hand off | [backup-acceptance.md](references/backup-acceptance.md) |

## Mandatory boundaries

Never enumerate `~/.ssh/config`, resolve beyond `HOST`, or probe neighbors.
Explicit `go` authorizes only the frozen plan and adds no package,
scheduler, credential, deletion, publication, or deployment authority. Never
request or record secrets. Scheduling is excluded.
Recursive, wildcard, deletion-sync, or multi-path cleanup requires the
guarded-bulk-delete skill's deterministic plan/apply; never use raw recursive
deletion.

On gate failure, leave live state unchanged where possible, retain the last
known-good copy, checkpoint the failure, and stop for a material decision or
missing authority.
