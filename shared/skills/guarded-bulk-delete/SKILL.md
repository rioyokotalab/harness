---
name: guarded-bulk-delete
description: Plan, execute, and verify autonomous deletion of directory trees with protected-root rejection, explicit canonical boundaries, immutable short-lived manifests, identity and size revalidation, and post-delete checks. Use whenever Codex or Claude would otherwise run recursive rm, find -delete, wildcard cleanup, synchronization with deletion, or any command that can remove multiple files or directories, including to classify whether reviewed installer or package-manager internal cleanup qualifies for the narrow exception.
---

# Guarded bulk delete

Use the deterministic `harness guarded-delete` workflow for bulk deletion.
Do not issue raw recursive deletion commands or hide deletion in a shell script.
This workflow does not request approval; plan and apply may proceed autonomously
when every check passes.

## Reviewed installer exception

Do not use the manifest workflow for cleanup internal to a vendor installer or
trusted package manager only when every gate below passes:

1. Obtain the artifact from the vendor's official HTTPS endpoint, or use an
   already trusted system package manager. Download remote scripts to a private
   temporary file; never pipe them directly to a shell.
2. Syntax-check and review the exact executable bytes. Identify every recursive
   or multi-path deletion primitive and prove how each target is derived.
3. Run non-interactively with explicit install and state destinations. Confine
   deletion to declared package-owned release, cache, staging, or temporary
   roots.
4. Reject any target that is an account-home root, repository, workspace,
   credential or authentication store, backup, or unrelated user-data path.
5. Execute the exact reviewed artifact without a second download or mutation.
   Verify the installed state, expected obsolete-package cleanup, and absence
   of unexpected residue afterward.

Owner approval alone is insufficient. If provenance, bytes, target derivation,
ownership, or scope is ambiguous, use guarded deletion or stop. Agent-authored
installers, repository cleanup scripts, wrappers that hide deletion, and any
deletion outside package-owned roots never qualify.

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
mode-600 manifest. Manifest content is first built on independent temporary
storage, then copied and hard-linked into place only after exact size and
SHA-256 verification. Quota exhaustion, truncation, or delayed destination
write failure must fail planning without publishing a usable manifest.

## Apply

Run the exact `NEXT` command emitted by the plan. Do not edit the manifest or
reconstruct its token.

Apply fails closed unless the lexical account home, its canonical resolved
home, working directory, repository, boundary, parent and target identities,
entry counts, byte counts, owner, mode, token, and 15-minute freshness window
all still match. Both account-home spellings are protected. It deletes only the
canonical target roots, stays on each target filesystem, then verifies the
targets are absent and protected anchors are unchanged.

If any check fails, preserve the failure, inspect the changed state, and create
a new plan only when retrying remains in scope. Do not bypass the tool with raw
`rm`, `find -delete`, a language runtime, `rsync --delete`, or another remover.

## Scope boundary

Single, exact, non-recursive file removal and qualifying reviewed-installer
internal cleanup are outside the manifest workflow. Prefer patch-based deletion
for tracked repository files. Treat uncertain globs, generated file lists,
loops, and non-qualifying installer cleanup as bulk deletion.

After apply, record the manifest path, deleted targets, verification result,
and any retry safety in the active repository ledger or handoff.
