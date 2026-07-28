# Validation

## Checks

- The final `-r5` pilot and confirmation aggregates pass their closed schema,
  hygiene lint, and frozen corpus/runner digest checks.
- All 16 untouched fixture baselines fail and all 16 model-free reference
  solutions pass their property grader.
- `tests/test-development-evaluation.sh`,
  `tests/test-client-comparison.sh`, `tests/test-claude-takeover.sh`,
  `git diff --check`, and the cowork session validator pass.
- `tests/test-phase1.sh` passes from clean commit `4abbc8c`. Its declared native
  MPI smoke remains skipped outside a declared MPI environment.
- Protected CI first failed because its credential-free portable runner cannot
  execute the local bubblewrap capability probe. The scored runner remains
  byte-stable; only the focused test now uses static containment declarations
  under `HARNESS_PORTABLE_CI=1`, while normal local validation continues to run
  the complete sandbox, process, and model-free grader self-tests.
- The initial full-suite attempt failed only the two expected clean-checkout
  gates while result/README changes were uncommitted. After checkpointing those
  artifacts, both gates and the complete suite passed.

## Outcome

Accepted. The controlled 96-run `-r5` experiment is internally valid for this
synthetic corpus: Codex passed 48/48; Claude passed 46/48, with one functional
edge-case failure and one strict scope-preservation failure. No row was
invalid, no-artifact, or containment-failed. The README reports the result
without a general superiority claim.

## Residual risks

- Native edit surfaces, effort controls, token counters, and real operational
  task frequencies are not equivalent.
- Codex JSONL did not emit a resolved model identifier, so its pinned model is
  requested-only evidence.
- Earlier tracked aggregates are invalid calibration evidence and must not be
  combined with `-r5`.
- Protected CI, merge, fleet synchronization, Mac context refresh, and guarded
  private-run cleanup remain driver publication/handoff work.

## Post-closeout correction

The outcome above records the original `-r5` closeout and is retained as
historical review evidence. A deeper frozen-plan audit later established that
`-r5` had not met the declared mutation challenge: it exercised only one
reference and the untouched seed per scenario. Those observations are
exploratory, not the accepted comparison.

The distinct `-r6` calibration run then exposed an adapter defect: a
conventional `TypeError` for a non-integer reply count was incorrectly graded
as failure. Its aggregates are invalid calibration evidence. The corrected,
distinct `-r7` source passes a model-free audit of 32 accepted and 48 plausible
wrong variants, including four protected-gate reward hacks, with zero
unexpected passes.

Under `-r7`, the pilot result is Codex 16/16 and Claude 15/16. The cumulative
three-observation confirmation result is Codex 48/48 and Claude 44/48. Claude's
four task failures comprise three reply-count validation misses and one
protected root-route normalization miss. Both arms contain 48 valid rows with
zero unsafe, invalid, no-artifact, or containment outcomes. This addendum
supersedes the acceptance conclusion above without rewriting its chronology.

## Publication validation

The accepted `-r7` source and reports passed the benchmark-focused test, closed
report digest/privacy checks, cowork complete-phase validation, protected
`portable-phase1`, and the complete clean-tree Harness suite. A detached cold
clone of merge `ed1ea25433300ccd2650498468e522cfd0fb4b16` repeated the
benchmark test in native and portable-CI modes and the complete Harness suite.
The only skip was the declared native MPI smoke outside a declared MPI
environment.

The merge was guarded-synchronized to all ten eligible managed checkouts with
an exact `KEEP` repeat. ABQ remained maintenance-excluded. Each advanced Mac
received exactly one pane-blind merge-specific context refresh. The private
`-r6` and `-r7` roots and the detached audit clone were guarded-deleted after
validation; public aggregates and source remain.
