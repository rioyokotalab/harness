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
