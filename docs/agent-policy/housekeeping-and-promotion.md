# Housekeeping and reusable-guidance policy

## Runtime residue

- Include a read-only inventory of `$CODEX_HOME/tmp/arg0`. A held `.lock` is live; never
  remove the root or require all Codex processes to exit.
- Candidates are current-user-owned real directories past grace or from a
  completed invocation, empty without a lock or expected-layout with an
  acquirable lock. Quarantine while locked, then guarded-delete. Report live,
  eligible, removed, and unexpected counts. Recurring fresh residue is a
  separate vendor-launcher issue requiring authority.

## Repository housekeeping

- Run `harness housekeeping --plan` first; it may create only private
  mode-0600 receipts and guarded manifests.
- A local branch qualifies only by exact merged-PR head or ancestry to freshly
  verified `origin/main`, never by name or diff. Apply consumes the emitted
  receipt/token, revalidates the full set, archives exact tips in local refs
  and a verified durable bundle, then uses expected-old ref transactions.
- Remote deletion requires explicit archive-first expected-OID housekeeping.
- A linked worktree also requires zero tracked, untracked, ignored, nested,
  submodule, lock, and process/open-file findings. Its directory and Git-admin
  record use separate fresh guarded manifests and a durable checkpoint.
- Audit archives with `harness housekeeping --audit --receipt PATH`. Apply one
  exact launcher candidate with `--launcher`; never expand a deletion list.

## Reusable guidance

Promote only concise, additive cross-project behavior supported by use or an
explicit preference, with no project path, schema, private data, or weaker
rule. Use root `AGENTS.md` for short behavior, one focused shared skill with
both discovery links for expertise, and closest project guidance for project
facts. Keep projects self-contained; preserve unrelated content, validate both
clients, report and commit only intended files without changing remotes. Keep
uncertain reuse local and propose it.
