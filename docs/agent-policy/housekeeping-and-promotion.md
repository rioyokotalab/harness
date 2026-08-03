# Housekeeping and reusable-guidance policy

## Runtime residue

- Include a read-only inventory of `$CODEX_HOME/tmp/arg0`. A held `.lock` is live; never
  remove the root or require all Codex processes to exit.
- A candidate is a current-user-owned real directory past grace or from a
  completed invocation, and either empty without a lock or expected-layout
  with an acquirable lock. Lock, quarantine, then guarded-delete. Report live,
  eligible, removed, and unexpected counts. Fresh recurrence is a separate
  vendor-launcher issue requiring authority.

## Repository housekeeping

- Run `harness housekeeping --plan` first; it may create only private
  mode-0600 receipts and guarded manifests.
- Branch eligibility requires exact merged-PR head or ancestry to freshly
  verified `origin/main`, never name or diff. Apply consumes its receipt/token,
  revalidates the set, archives exact tips as local refs plus a verified durable
  bundle, then uses expected-old ref transactions.
- Remote deletion requires explicit archive-first expected-OID housekeeping.
- Worktree eligibility additionally requires zero tracked, untracked, ignored,
  nested, submodule, lock, and process/open-file findings. Its directory and
  Git-admin record need separate fresh guarded manifests and a durable checkpoint.
- Audit archives with `harness housekeeping --audit --receipt PATH`. Apply one
  exact launcher candidate with `--launcher`; never expand a deletion list.

## Reusable guidance

Promote only concise, additive cross-project behavior supported by use or an
explicit preference, without project paths, schemas, private data, or weaker
rules. Put short behavior in root `AGENTS.md`, expertise in one focused shared
skill with both discovery links, and project facts in closest guidance. Keep
projects self-contained; preserve unrelated content, validate both clients,
and report/commit only intended files without changing remotes. Propose
uncertain reuse locally.
