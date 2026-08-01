# Housekeeping and reusable-guidance policy

Read this file completely before the matching action selected by root
`AGENTS.md`.

## Routine housekeeping

- Include a read-only inventory of `$CODEX_HOME/tmp/arg0` when present. A held
  `.lock` is live; never remove the whole root or require every Codex process to
  exit.
- Eligible candidates are current-user-owned real directories past the grace
  period or from an observed completed invocation, and are either empty without
  a lock or expected-layout with an acquirable lock. Quarantine while locked,
  then use `guarded-bulk-delete`.
- Report live, eligible, removed, and unexpected counts. If fresh invocations
  recreate residue, separate housekeeping from a vendor-launcher fix; the
  latter requires explicit authority.

## Routine repository housekeeping

Run read-only `harness housekeeping --plan` first and record its receipt.
Classify branches by pull-request merge state, never by diff, and record each
tip before deleting.

## Promote reusable guidance

Promote a correction automatically only when it is stable personal behavior or
applies to at least two project types, is supported by successful use or an
explicit preference, contains no project path/schema/private data, and is
concise, additive, non-conflicting, and no weaker than closer policy.

Choose the smallest surface:

- short cross-project behavior in root `AGENTS.md`, imported by `CLAUDE.md`;
- repeatable expertise in a focused `shared/skills/` skill with matching
  `.agents/skills/` and `.claude/skills/` discovery links;
- non-secret product examples under `.codex/` or `.claude/`, never live
  settings;
- build, test, schema, deployment, benchmark, and team facts in the closest
  project instructions or skill.

Keep project repositories self-contained. Preserve unrelated content, validate
both clients' discovery, report the promotion, and commit only intended Harness
files without changing remotes. If reuse is uncertain, keep the rule local and
propose promotion.
