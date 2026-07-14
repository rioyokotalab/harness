---
name: guarded-bulk-delete
description: Plan, execute, and verify autonomous deletion of directory trees with protected-root rejection, explicit canonical boundaries, immutable short-lived manifests, identity and size revalidation, and post-delete checks. Use whenever Codex or Claude would otherwise run recursive rm, find -delete, wildcard cleanup, synchronization with deletion, or any command that can remove multiple files or directories.
---

# Guarded bulk delete

Use the deterministic `harness guarded-delete` workflow for bulk deletion.
Do not issue raw recursive deletion commands or hide deletion in a shell script.
This workflow does not request approval; plan and apply may proceed autonomously
when every check passes.

## Plan

Choose a narrow existing boundary that is itself retained. Name every target as
an absolute existing directory strictly below that boundary. Never derive the
boundary or targets from command-scoped environment assignments, globs, or
substitutions.

```sh
harness guarded-delete plan \
  --within /absolute/retained/project \
  --manifest /absolute/retained/guarded-delete.manifest \
  -- /absolute/retained/project/build /absolute/retained/project/tmp
```

Read the `PLAN`, every `TARGET`, and `NEXT` line. Confirm that the canonical
boundary and targets match the task. A plan is read-only except for its
mode-600 manifest.

## Apply

Run the exact `NEXT` command emitted by the plan. Do not edit the manifest or
reconstruct its token.

Apply fails closed unless the account home, working directory, repository,
boundary, parent and target identities, entry counts, byte counts, owner,
mode, token, and 15-minute freshness window all still match. It deletes only
the canonical target roots, stays on each target filesystem, then verifies the
targets are absent and protected anchors are unchanged.

If any check fails, preserve the failure, inspect the changed state, and create
a new plan only when retrying remains in scope. Do not bypass the tool with raw
`rm`, `find -delete`, a language runtime, `rsync --delete`, or another remover.

## Scope boundary

Single, exact, non-recursive file removal is outside this workflow when the
path is already verified and the command cannot expand to multiple paths.
Prefer patch-based deletion for tracked repository files. Treat uncertain
globs, generated file lists, and loops as bulk deletion.

After apply, record the manifest path, deleted targets, verification result,
and any retry safety in the active repository ledger or handoff.
