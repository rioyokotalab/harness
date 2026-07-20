# Validation

## Checks

- Live session `check` at validating and `verify-receipts` under the new helper —
  PASS; the pre-change schema-2 receipt chain remains compatible.
- Python AST parse and test-script `bash -n` — PASS.
- `tests/test-codex-claude-cowork-skill.sh` — PASS, including existing seal edge
  behavior, happy-path receipt digest equality, and new structural one-descriptor
  / no-reopen assertions.
- `tests/test-source-contract.sh` — PASS.
- `tests/test-claude-takeover.sh` — PASS.
- `tests/test-public-repo-audit.sh` — PASS.
- `git diff --check` — PASS.
- Clean full `tests/test-phase1.sh` at checkpoint `66b80b7` — PASS in every
  listed suite, with only the declared environment-only native MPI smoke skip.

## Outcome

The accepted fix mechanically binds `receipt.seal_sha256` to the exact bytes
whose JSON passed seal validation in that import. It also removes the prior
lstat-to-following-read leaf-symlink window. Schema, CLI, receipt format,
location checks, historical receipts, and staged/direct behavior are unchanged.
The clean full gate passed; the session can advance to complete with scratch
preserved until guarded cleanup.

## Residual risks

- A same-UID replacement before the single `open` supplies bytes that are both
  validated and digested; it remains governed by external placement/confinement
  and must still satisfy every stage/session cross-check.
- `O_NOFOLLOW` protects only the leaf, not parent path identity. This round does
  not strengthen Claude's OS confinement or cross-file atomicity.
- The structural regression proves the second read is absent; it intentionally
  avoids a production pause/test hook and probabilistic race.
- One invalid first Claude response is retained as a retry-safe process event;
  only the substantive retry was imported.

## Cleanup

After completion, guarded-delete token `5160b26e…` deleted the three exact
round-8 `/tmp` roots (1,222 entries; 6,588,839 bytes), including Claude's labeled
scratch. Separate token `b6f1d5e2…` deleted only the two detached-worktree admin
records (16 entries; 108,275 bytes). Both applies revalidated targets and
verified protected anchors unchanged and targets absent. The spent manifests
were exact-unlinked; `git worktree list`, `git fsck --no-dangling`, and clean
branch status passed. Tracked evidence remains recoverable in Git.
