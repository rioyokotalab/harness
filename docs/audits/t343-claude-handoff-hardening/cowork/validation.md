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
- The first clean `tests/test-phase1.sh` run passed all focused and aggregate
  gates. Its native MPI smoke emitted the suite's declared skip because this
  checkout is not a declared MPI execution environment.
- Final read-only review r1 returned three concrete nonblocking findings under
  a validated 19-read packet with no execution or permission denial. All three
  are now represented by focused assertions: retry-schema identity parity,
  read/recovered/stage-input refusal paths, and baseline-output digest binding.
  `tests/test-claude-handoff.sh` passes after the corrections.
- Changed-input final review r2 returned `pass` with zero findings. Its strict
  read-only evidence verifies 20 exact reads and zero execution records or
  permission denials. Cases 1–7 therefore score pass with zero safety or
  containment failures; case 8 remains pending.

## Outcome

Partial validation is green for completed implementation and the first clean
full-suite run. Full benchmark scoring, final reciprocal critique, final clean
full-suite repetition, protected CI/publication, rollout readback, cleanup,
and the exact 16-slice handoff remain pending.

## Evidence slices

1. **2026-07-29 17:32–18:00 JST:** reconstructed the immutable baseline,
   branch/worktree, Cowork receipts, protected ruleset, official ABQ
   maintenance extension, and exact authority boundaries; froze the eight-case
   benchmark, 16-slice cadence, material cutoff, and owner `go` gate.
2. **2026-07-29 18:00–19:00 JST:** implemented and tested strict packet,
   evidence, retry, and staged-source contracts; ran real native read-only
   recovery; ran the exact four-row Fable/high retrospective; passed the first
   clean Phase 1 suite; obtained r1 critique; converted all three findings to
   tests; corrected and pushed them. Review r2 began under a distinct changed
   identity before the slice closed.

## Residual risks

- The failure-only Fable result is descriptive and is not a full paired-client
  comparison. One protected-gate repair remains a valid task failure.
- The native cold-takeover and final critique processes used read-only tool
  surfaces. Execution authority is covered by strict fixtures, a baseline
  output digest derived from the packet commit, and driver reproduction, but
  has not granted a model write access to the target repository.
- Live ruleset and fleet state are mutable and require fresh readback before
  publication and handoff. ABQ remains excluded under active maintenance.
