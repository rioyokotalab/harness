# Initial plan

## Confirmed facts and assumptions

Round 2 retained `HARNESS_TEST_JOBS=4` because all earlier four/eight samples
were contaminated by dirty-tree or sandbox failures. The canonical branch is
now clean and the two experiment clones match commit `a9dd994`. Round 1 added a
single-shot JSON `status`; supervising both native client windows still needed
many external poll calls. `candidate_state`, process reachability, and the new
mechanical precondition summary are advisory and never authorize import.

## Steps

1. Validate both clone baselines and capture host/runtime capabilities.
2. In the Codex clone, run six non-overlapping focused-runner samples in order
   4, 8, 8, 4, 4, 8, each with a fresh log directory and raw output retained.
3. Summarize pass counts, elapsed distributions, medians, and confounders in
   `driver-evidence.md`; inspect the current status implementation and prototype
   the smallest bounded wait semantics without touching the target.
4. Freeze protected digests, stage an independent prompt/plan bundle into a
   direct child of the Claude clone, run Claude Sonnet/medium under a hard time
   limit, and import only a fresh structurally valid candidate.
5. Stage a reciprocal bundle exposing both evidence files and require Claude to
   attack the worker inference and wait semantics. Import and verify receipts.
6. Reconcile accepted evidence. Choose no worker change unless all clean samples
   pass and the effect is stable; reject any aggregate state that implies import
   authorization.
7. Advance ready only on a narrow frozen plan. Under the owner's standing go,
   Codex alone implements it on the task branch and records exact results.
8. Run focused checks, checkpoint, run clean full phase one, validate both
   sessions and a fresh clone, then close or record the next executable action.

## Evidence questions

Does jobs 8 retain its earlier raw advantage when all suites pass, runs are
sequential, and order is balanced? Is elapsed improvement large relative to
run-to-run variance? Can a wait operation safely stop on candidate readiness,
candidate invalidity, observed process exit, or timeout while still reporting
only advisory facts? Should it return a distinct nonzero code for process exit
without a candidate, and how should PID reuse limitations be surfaced? Does a
wait command materially reduce driver context/tool round trips compared with
manual `status` polling?

## Risks and recovery

Shared-host load can add variance; retain raw samples and avoid causal claims
beyond this host. A process PID is advisory and may be reused; waiting must not
turn reachability into authentication. A candidate can be structurally ready
while freshness is false; success must require the existing advisory
conjunction but still grant no authorization. Claude startup may exceed a
budget; hard-timeout partial output is evidence, and retry is allowed only
after protected/stage/seal/destination freshness checks. Keep all scratch until
tracked evidence is committed; later tree cleanup must use guarded deletion.
