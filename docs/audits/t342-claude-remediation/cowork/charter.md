# Charter

## Task

Remediate the unresolved Claude-specific findings from the Students T-031
nightly hardening run, then promote only the reusable controls to Harness.
Codex is the driver and Claude is the co-pilot.  The benchmark in
`artifacts/benchmark.md` is the shared definition of success and must be
agreed before target execution.

## Boundaries

- Preserve unrelated work and the frozen Students T-031/T-033 and Harness
  T-336 evidence.
- The target repositories are Students at `1376690` and Harness at `5276ddf`.
- Claude may experiment and implement only in its detached sandbox worktrees.
  Codex alone may mutate the target task worktrees after reconciliation.
- Do not change live user Claude settings, credentials, MCP servers, hosted
  rulesets, live student state, or external services.
- Do not run live compute or contact students.
- Iterate on distinct test failures with recorded evidence; never blindly
  replay an ambiguous native-client invocation.

## Baseline and sandboxes

- Driver target worktrees:
  `/tmp/students-t035-claude-boundaries` and
  `/tmp/harness-t342-claude-remediation`.
- Driver experiment worktrees:
  `/tmp/t342-codex-box/students` and `/tmp/t342-codex-box/harness`.
- Co-pilot experiment worktrees:
  `/tmp/t342-claude-box/students` and `/tmp/t342-claude-box/harness`.
- Co-pilot stages are direct children of `/tmp/t342-claude-box`; seals and
  driver prompts remain outside that tree.

## Acceptance

All benchmark cases in `artifacts/benchmark.md` must pass with reproducible
commands.  Students must pass its focused worker tests and complete offline
gate.  Harness must pass its focused cowork/config/takeover tests,
`tests/test-phase1.sh`, and project-policy validation.  Native Claude evidence
must identify the installed Fable alias at high effort.  Any protected remote
publication and fleet synchronization must remain clean and reviewable.
