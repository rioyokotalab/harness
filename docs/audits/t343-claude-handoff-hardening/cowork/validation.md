# Validation

## Checks

- Packet, evidence, retry, fresh-process, and frozen-retrospective checks are
  passing in `tests/test-claude-handoff.sh`.
- The fixture preserves a tracked zero-approval policy and an unrelated dirty
  owner draft byte-for-byte across all positive and negative validation paths.
- The frozen T-336 runner, corpus, accepted pilot, and accepted confirmation
  inputs retain their declared SHA-256 identities.
- New retest `t343-t336-fable-high-20260729-r1` completed all four selected
  Claude 2.1.220/Fable/high rows with zero invalid, unsafe, or containment
  outcomes. Three rows passed; `ci-gate-preserve/o2` failed only the frozen
  `route_normalization` hidden boundary.
- `tests/test-development-evaluation.sh`,
  `tests/test-t343-fable-retest.sh`, and `git diff --check` pass.

## Outcome

Partial validation is green for completed implementation. Full benchmark
scoring, the complete focused set, `tests/test-phase1.sh`, final reciprocal
critique, protected CI/publication, rollout readback, cleanup, and the exact
16-slice handoff remain pending.

## Residual risks

- The failure-only Fable result is descriptive and is not a full paired-client
  comparison. One protected-gate repair remains a valid task failure.
- The native cold-takeover process used a read-only tool surface. Execution
  authority is covered by strict fixtures and driver reproduction but has not
  granted a model write access to the target repository.
- Live ruleset and fleet state are mutable and require fresh readback before
  publication and handoff. ABQ remains excluded under active maintenance.
