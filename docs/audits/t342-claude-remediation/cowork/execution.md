# Driver execution

## Steps and results

1. Claude independent evidence iteration 1 ran with Fable/high but the command
   used empty `--allowedTools`; tools remained available, Claude searched an
   unrelated archived session, and returned a wrapped invalid candidate.  The
   import helper refused it.  The changed iteration used documented
   `--tools ""`, a distinct prompt/stage/seal, and imported valid independent
   evidence at SHA-256
   `c6bafad7bdff02a9747d3b27934802b92b798830b23669b5e61f9e886d83557f`.
2. The reciprocal Fable/high no-tools stage imported at SHA-256
   `b6f2be20c51bc32ebc2e536dcb4ba148609530da048f055b5a5f5715c54281fc`.
   Reconciliation selected a root-level read-only/workspace-write matrix,
   task-bound sessions, empty-only legacy migration, schema-3 cowork
   benchmarks, tracked Fable/high intent, and proportional time-slice
   summaries.
3. Claude's first Students implementation launch failed before execution
   because native sandbox dependencies lacked `socat`.  A Bash-only audited
   bubblewrap wrapper reused the validated T-336 containment pattern.
4. The wrapper's first launch failed before execution because its
   `apply_patch` bind destination did not exist on the read-only root.  A
   private predeclared mount slot fixed that exact setup error.
5. The next launch read all source but client policy denied every Bash
   mutation/test.  The clean worktree proved retry safety.  A task-local
   `permissions.allow=["Bash(*)"]` rule, with no bypass mode and the same
   outer bubblewrap boundary, enabled the distinct implementation iteration.
6. Claude implemented Students D-016/D-017 in its sandbox and passed 17 focused
   tests plus the complete 174-test offline gate.  Codex reviewed the diff,
   corrected the ledger to close those owner-selected gates without activating
   student services, independently reran both gates, committed candidate
   `abedd2d`, and cherry-picked it as target commit `8c04f63` on
   `codex/t035-claude-boundaries`.
7. Claude implemented the reusable Harness candidate in a separate Bash-only
   bubblewrap sandbox.  Codex reviewed the helper compatibility paths,
   corrected stale schema wording, made Fable/high explicit in the skill
   trigger and native protocol, and added focused assertions.
8. The first Harness phase-1 run on a dirty candidate failed only the two
   clean-checkout suites.  After candidate commit `b823318`, the identical
   phase-1 command passed.  Codex cherry-picked it as target commit `4d21c8d`
   on `codex/t342-claude-remediation`.
9. A project-settings-only native Claude Code 2.1.220 probe used no CLI model
   or effort override and no tools.  It returned `PROJECT_DEFAULT_OK` with
   `is_error=false`, one turn, and model usage containing canonical
   `claude-fable-5`; the mode-0600 raw result was exact-unlinked afterward.

## Deviations

- The current session predates the schema-3 helper and therefore keeps its
  valid schema-2 receipt-backed layout.  Its agreed benchmark is retained at
  `artifacts/benchmark.md`; no in-place session migration was attempted.
- Driver evidence was persisted after the first co-pilot window rather than
  before it.  The independent driver source analysis had already occurred, but
  the ordering deviation weakens formal blinding and remains explicit.
- Claude's no-tools prompt could not itself read staged Markdown; the bounded
  prompt carried the benchmark cases.  The new schema-3 protocol stages
  `benchmark.md` mechanically and documents the exact no-tools contract.
- Native Claude's built-in sandbox was unavailable because `socat` is absent.
  No package was installed.  Candidate implementation used the previously
  audited bubblewrap Bash-only boundary instead.
- Claude's restricted Harness phase-1 run had host-environment failures.  The
  driver reran from a clean committed candidate in the normal host environment,
  where the complete gate passed.
