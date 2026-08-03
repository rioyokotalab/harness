# Reviewed installer exception

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
