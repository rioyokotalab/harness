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
  containment failures.
- The final clean `tests/test-phase1.sh` repetition at implementation/evidence
  head `60bd1bd` passed every focused and aggregate gate. Native MPI retained
  only its declared environment-specific skip.
- Fresh ruleset `19127355` readback is active with repository-role
  owner/admin bypass, strict required `portable-phase1`, review-thread
  resolution, and owner-selected required approvals `0`.
- Protected PR #412's first `portable-phase1` run failed only because the
  retest declaration validator required the intentionally absent Claude CLI.
  The changed helper now exposes a machine-reported client-check skip only
  under `HARNESS_PORTABLE_CI=1`; normal local use still requires exact Claude
  2.1.220. Both local and simulated credential-free focused checks pass.
- Corrected required check run `30442745725` passed on exact head `3b8857b`;
  PR #412 merged by rebase as main `0fdfd97`. Post-merge ruleset readback
  preserves strict `portable-phase1`, owner/admin bypass, and required
  approvals `0`.
- Local and all ten eligible clean remote checkouts reached `0fdfd97`; ABQ was
  excluded under active maintenance. Exactly one pane-blind context refresh
  was submitted to each managed Mac session.
- Guarded cleanup removed ten task-owned evidence/sandbox roots (4400 entries,
  86131602 bytes), verified protected anchors unchanged, and left no declared
  target. Three exact task files were unlinked after identity checks.
- At the 08:00 material cutoff, protected main had advanced cleanly to
  `f533310` through unrelated T-344 work. The closeout history was rebased
  onto that exact base without conflict, and a fresh `tests/test-phase1.sh`
  passed every focused and aggregate gate with only the declared native MPI
  environment skip.
- Closeout PR #415 passed required `portable-phase1` run `30498317061`, job
  `90732137097`, on exact head `6a18f72` and merged by rebase as
  `5f7ce2e`. Final case-8, Cowork-state, and through-deadline evidence remain
  on the distinct final-acceptance follow-up.

## Outcome

All eight benchmark cases pass with zero safety or containment failures.
Implementation, reciprocal reviews, repeated local tests, protected CI,
implementation and closeout merges, eligible-fleet rollout, Mac refresh,
declared residue cleanup, exact 16-slice monitoring, and final live readbacks
are green. Cowork advanced to complete only after these terminal gates passed.

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
3. **2026-07-29 19:00–20:00 JST:** changed-input review r2 returned pass with
   zero findings; final clean Phase 1 passed; the first protected CI run
   exposed and the changed exact-head run closed the credential-free native
   client assumption; PR #412 merged as `0fdfd97`; Local and ten eligible
   remotes synchronized; four one-shot Mac refreshes were submitted; guarded
   cleanup removed all declared task roots. At 20:00, main and closeout were
   clean and equal to their remotes, ruleset `19127355` read active/zero/
   strict-`portable-phase1`, PR #412 remained merged, 13 declared cleanup
   paths remained absent, Linux was 7/8 ready with maintained ABQ the sole
   failure, and all four Mac route pairs passed.
4. **2026-07-29 20:00–21:00 JST:** sub-minute native heartbeats completed the
   full slice without interruption or mutation. At the 21:00 readback, main
   remained clean at merged `0fdfd97`, the closeout branch remained clean and
   equal to its pushed `048339d`, PR #412 remained merged, no closeout PR
   existed, ruleset `19127355` remained active with zero approvals and strict
   `portable-phase1`, all 13 declared cleanup paths remained absent, Linux
   remained 7/8 ready with maintained ABQ the sole failure, and all four Mac
   route pairs passed.
5. **2026-07-29 21:00–22:00 JST:** sub-minute native heartbeats completed the
   full slice without interruption or mutation. The 22:00 readback again
   proved clean merged main `0fdfd97`, a clean pushed closeout branch at
   `0a63aa7`, merged PR #412, no closeout PR, active ruleset `19127355` with
   zero approvals and strict `portable-phase1`, all 13 cleanup paths absent,
   Linux 7/8 ready with maintained ABQ the sole failure, and all four Mac route
   pairs passing.
6. **2026-07-29 22:00–23:00 JST:** sub-minute native heartbeats completed the
   full slice without interruption or mutation. The 23:00 readback again
   proved clean merged main `0fdfd97`, a clean pushed closeout branch at
   `9cdf115`, merged PR #412, no closeout PR, active ruleset `19127355` with
   zero approvals and strict `portable-phase1`, all 13 cleanup paths absent,
   Linux 7/8 ready with maintained ABQ the sole failure, and all four Mac route
   pairs passing.
7. **2026-07-29 23:00–2026-07-30 00:00 JST:** sub-minute native heartbeats
   completed the full slice without interruption or mutation. The midnight
   readback again proved clean merged main `0fdfd97`, a clean pushed closeout
   branch at `daac40f`, merged PR #412, no closeout PR, active ruleset
   `19127355` with zero approvals and strict `portable-phase1`, all 13 cleanup
   paths absent, Linux 7/8 ready with maintained ABQ the sole failure, and all
   four Mac route pairs passing.
8. **2026-07-30 00:00–01:00 JST:** sub-minute native heartbeats completed the
   first full post-midnight slice without interruption or mutation. The 01:00
   readback proved clean merged main `0fdfd97`, a clean pushed closeout branch
   at `3672d08`, merged PR #412, no closeout PR, active ruleset `19127355`
   with zero approvals and strict `portable-phase1`, no task sandbox or
   evaluation residue, Linux 7/8 ready with maintained ABQ the sole failure,
   and all four Mac route pairs passing.
9. **2026-07-30 01:00–02:00 JST:** native heartbeats covered the full slice
   without interruption or mutation. The 02:00 readback proved clean merged
   main `0fdfd97`, a clean pushed closeout branch at `aa40187`, merged PR
   #412, no closeout PR, active ruleset `19127355` with zero approvals and
   strict `portable-phase1`, no task sandbox or evaluation residue, Linux 7/8
   ready with maintained ABQ the sole failure, and all four Mac route pairs
   passing.
10. **2026-07-30 02:00–03:00 JST:** native heartbeats covered the full slice
    without interruption or mutation. The 03:00 readback proved clean merged
    main `0fdfd97`, a clean pushed closeout branch at `42ae28b`, merged PR
    #412, no closeout PR, active ruleset `19127355` with zero approvals and
    strict `portable-phase1`, no task sandbox or evaluation residue, Linux 7/8
    ready with maintained ABQ the sole failure, and all four Mac route pairs
    passing.
11. **2026-07-30 03:00–04:00 JST:** native heartbeats covered the full slice
    without interruption or mutation. The 04:00 readback proved clean merged
    main `0fdfd97`, a clean pushed closeout branch at `d2f2743`, merged PR
    #412, no closeout PR, active ruleset `19127355` with zero approvals and
    strict `portable-phase1`, no task sandbox or evaluation residue, Linux 7/8
    ready with maintained ABQ the sole failure, and all four Mac route pairs
    passing.
12. **2026-07-30 04:00–05:00 JST:** native heartbeats covered the full slice
    without interruption or mutation. The 05:00 readback proved clean merged
    main `0fdfd97`, a clean pushed closeout branch at `6dae7b9`, merged PR
    #412, no closeout PR, active ruleset `19127355` with zero approvals and
    strict `portable-phase1`, no task sandbox or evaluation residue, Linux 7/8
    ready with maintained ABQ the sole failure, and all four Mac route pairs
    passing.
13. **2026-07-30 05:00–06:00 JST:** native heartbeats covered the full slice
    without interruption or mutation. The 06:00 readback proved clean merged
    main `0fdfd97`, a clean pushed closeout branch at `b0180b4`, merged PR
    #412, no closeout PR, active ruleset `19127355` with zero approvals and
    strict `portable-phase1`, no task sandbox or evaluation residue, Linux 7/8
    ready with maintained ABQ the sole failure, and all four Mac route pairs
    passing.
14. **2026-07-30 06:00–07:00 JST:** native heartbeats covered the full slice
    without interruption or mutation. The 07:00 readback proved clean merged
    main `0fdfd97`, a clean pushed closeout branch at `d50be39`, merged PR
    #412, no closeout PR, active ruleset `19127355` with zero approvals and
    strict `portable-phase1`, no task sandbox or evaluation residue, Linux 7/8
    ready with maintained ABQ the sole failure, and all four Mac route pairs
    passing.
15. **2026-07-30 07:00–08:00 JST:** native heartbeats covered the final
    pre-cutoff slice without interruption or mutation. The 08:00 readback
    proved clean protected main at `f533310`, incorporating unrelated merged
    T-344 work after T-343’s `0fdfd97`; the pushed closeout branch was clean at
    `d0d6fdc`. PR #412 remained merged, no closeout PR existed, ruleset
    `19127355` remained active with zero approvals and strict
    `portable-phase1`, no task sandbox or evaluation residue existed, Linux
    was 7/8 ready with maintained ABQ the sole failure, and all four Mac route
    pairs passed.
16. **2026-07-30 08:00–09:00 JST:** the material cutoff was honored and the
    reserved final slice used only validation, evidence publication, cleanup,
    and readback work. Unrelated protected T-344 history was integrated without
    conflict. A fresh full Phase 1 suite passed, with only its declared native
    MPI environment skip. Closeout PR #415 passed exact-head required CI and
    merged as `5f7ce2e`; final-acceptance PR #416 carried the terminal 8/8
    score, completed Cowork state, this exact 16-slice summary, and the
    authoritative ledger. Repeated ruleset reads preserved active enforcement,
    owner/admin bypass, strict `portable-phase1`, and approvals `0`; task
    sandbox/evaluation residue remained absent. Linux was 7/8 ready with
    maintained ABQ the sole failure, all four Mac route pairs passed, and
    native heartbeats continued under the same read-only monitor through the
    deadline.

## Residual risks

- The failure-only Fable result is descriptive and is not a full paired-client
  comparison. One protected-gate repair remains a valid task failure.
- The native cold-takeover and final critique processes used read-only tool
  surfaces. Execution authority is covered by strict fixtures, a baseline
  output digest derived from the packet commit, and driver reproduction, but
  has not granted a model write access to the target repository.
- Live ruleset and fleet state remain point-in-time observations. Final
  readback preserved the intended policy and found only ABQ unavailable under
  its recorded maintenance window through 17:00 JST.
