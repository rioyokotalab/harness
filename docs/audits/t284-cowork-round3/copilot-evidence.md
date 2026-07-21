# Co-pilot evidence

## Sandbox and baseline

Read-only inspection performed entirely inside sealed stage `stage-reciprocal`
under Claude clone `/tmp/harness-t284-r3.IqKFA8/claude`, matching immutable
baseline `a9dd994`. No live session, external seal, driver-only files, Codex
clone, or repository target files were accessed or modified; no process was
left running. Inputs read this pass: `charter.md`, `plan.md`, `state.json`,
`stage.json`, `artifacts/copilot-prompt.md`, `driver-evidence.md`, and my own
prior `copilot-evidence.md` from `stage-independent`. This reciprocal pass
now has the real six-sample timing table that was withheld from the
independent pass, plus the driver's `wait-copilot` proposal.

## Commands and results

Arithmetic re-check only, no repository state touched:

- jobs=4 samples: 29.82, 29.67, 29.69 s — median 29.69, range 0.15.
- jobs=8 samples: 25.35, 25.39, 25.25 s — median 25.35, range 0.14.
- Every jobs=8 sample (25.25–25.39) is below every jobs=4 sample
  (29.67–29.82): zero overlap between arms, and each arm's own range
  (≤0.15 s) is roughly 25–30x smaller than the ~4.3 s gap between arms. That
  is a real, low-variance, non-overlapping separation on this host and this
  run, not noise.
- `driver-evidence.md`'s traced `status()` builder and the proposed
  `wait-copilot` sharing it match what I found independently in
  `cowork-session` (`candidate_state`, `inputs_fresh`, `destination_fresh`,
  `mechanical_import_preconditions`, optional `process` block) — no
  discrepancy in the underlying primitives.

## Critique

**Six-sample worker evidence — accepted with a scope correction, not a
rejection.** The separation is real and stable: I accept the driver's
14.62% median reduction as a genuine effect on this host at this commit,
sequential and balanced as specified. I reject the driver's proposed
unconditional repository-default change to `8`. My independent pass already
flagged that this host's `nproc=8` means `HARNESS_TEST_JOBS=8` saturates
every logical core with zero headroom for the OS, shell, and harness driver
itself; the six real samples do not add evidence about any host with fewer
cores, because none was tested. `n=3` per arm on one host also cannot
support a causal "8 is generically better" claim, only "8 beat 4 here." I
also reject retaining a hard-coded `4` unconditionally: that throws away a
reproducible, non-overlapping, six-sample result on hosts that plainly have
the headroom to use it. **Reconciled recommendation: a bounded
affinity-aware default — `8` only when at least eight logical CPUs are
visible to the process (e.g., `os.cpu_count()`/`nproc`-equivalent ≥ 8),
otherwise retain `4`.** This is not a generalization beyond the evidence:
the evidence was collected at exactly `nproc=8`, so gating the raised
default on that same precondition keeps the claim scoped to the condition
under which it was measured, while a host with fewer visible cores falls
back to the previously validated `4`. `HARNESS_TEST_JOBS` must still
override both.

**Wait semantics — stress-tested against a still-writing co-pilot.** A
candidate file can be empty or structurally invalid purely because the
co-pilot process has not finished its write yet, so "invalid/empty" must
never be treated as a synonym for "will not become ready." Decisions:

- **Safe to terminate while PID is still reachable:** only the full
  mechanical conjunction — structurally ready **and** `inputs_fresh` **and**
  `destination_fresh` all true. A live, still-reachable co-pilot process is
  irrelevant once the file on disk is complete and fresh; waiting further
  only adds latency. Structural readiness alone, or readiness with either
  freshness fact false, must **not** terminate while the PID is reachable —
  the co-pilot may still be about to overwrite it.
- **Requires a final snapshot after process loss:** when the tracked PID
  transitions to `not-reachable`, `wait-copilot` must not terminate on that
  tick's stale read. It must take exactly one more immediate re-read of the
  stage (a debounced "final snapshot") before deciding the terminal outcome,
  so a co-pilot that finishes writing in the same instant it exits is not
  misreported as a failure. I reject the driver's plan of treating
  `process-not-reachable` as its own parallel terminal outcome alongside
  `candidate-not-importable` — that races ahead of the last write and
  produces a wrong answer whenever exit and final write are near-simultaneous
  (a realistic case for a co-pilot that writes-then-exits).
- **A structurally ready candidate with stale inputs/destination must not
  terminate successfully.** Staleness means the driver's live inputs or
  destination moved after this candidate was produced; importing it would be
  mechanically wrong even though the file itself parses. It must resolve to
  the same non-success terminal outcome as an invalid/empty candidate, not
  to `ready`.
- **Minimize exit-code/API complexity while keeping it machine-useful:**
  collapse to three substantive terminal outcomes plus one argument-error
  outcome, rather than the driver's four-way split or my earlier
  five-way split:
  - `ready` (exit `0`): full conjunction true; may fire while PID reachable.
  - `not-importable` (exit `2`): fires either (a) after the debounced final
    snapshot following PID loss, when the conjunction is still not fully
    true (covers invalid, empty, unchanged, and stale-but-structurally-ready
    alike), or (b) instantly if no `--pid` was given and none applies —
    without `--pid` this outcome is unreachable, since there is no external
    signal that writing has stopped; only `ready`/`timeout` apply, matching
    the driver's own note.
  - `timeout` (exit `4`): poll budget exhausted with no terminal state
    reached.
  - `usage-error` (exit `1`): bad flags (missing `--stage`/`--seal`, poll
    interval below a 1 s busy-loop floor, or timeout above a fixed ceiling,
    e.g. 1800 s).
  The fine-grained facts the driver's four-way split tried to expose
  (which specific freshness/structural check failed, whether process loss
  was observed) belong in the retained JSON body — e.g. a
  `process_loss_observed: true/false` field and the existing
  `mechanical_import_preconditions` breakdown — not in a wider outcome/exit
  matrix. This keeps the API small while a driver script can still branch on
  the JSON fields when it needs the detail.
  Every outcome, including `ready`, must still carry
  `advisory: true, authorization: "none"` in `wait_observation`, and the
  command must never call or shell out to `import-copilot` under any
  outcome.

## Proposed plan changes

1. Change the worker default from a flat `4→8` swap to an affinity-aware
   default: `HARNESS_TEST_JOBS` unset resolves to `8` only when the visible
   logical CPU count is `≥ 8`, else falls back to `4`; keep explicit
   `HARNESS_TEST_JOBS` overrides and `legacy` mode unchanged. Document the
   `nproc=8`, zero-headroom scope of the measured evidence next to this
   logic.
2. Specify `wait-copilot` with exactly four outcomes —
   `ready`(0)/`not-importable`(2)/`timeout`(4)/`usage-error`(1) — built as a
   bounded loop over the existing `status()` snapshot, minimum poll interval
   1 s, maximum timeout 1800 s, and a mandatory single debounced re-read
   immediately after any observed PID-reachable→not-reachable transition
   before finalizing `ready` vs `not-importable`. Retain `advisory: true,
   authorization: "none"` on every outcome and add `process_loss_observed`
   to the JSON body.
3. Add focused tests: (a) candidate starts empty/invalid while PID reachable
   and later becomes fully fresh — must not terminate early, must end
   `ready`; (b) candidate structurally ready but stale destination while PID
   reachable, then PID exits with staleness still true — must end
   `not-importable`, never `ready`; (c) PID exits in the same tick the
   candidate becomes fully ready — debounced final snapshot must catch it
   and end `ready`, proving the single-re-read requirement is load-bearing;
   (d) timeout with no `--pid`; (e) `usage-error` for out-of-bounds
   interval/timeout; (f) source-level assertion `wait-copilot` never calls
   `import-copilot` and never writes `state.json`/`stage.json`/target files
   in any outcome.
4. Add a focused test asserting the affinity-aware jobs default resolves to
   `4` when the visible CPU count is mocked below 8 and to `8` at/above 8,
   independent of the raw six-sample host's own `nproc`.
5. Record in `reconciliation.md` that the worker-default disagreement is
   resolved by narrowing scope (affinity gate), not by picking a side, and
   that the wait-outcome disagreement is resolved by merging the driver's
   `process-not-reachable` outcome into a debounced `not-importable` check
   rather than keeping it as a fourth parallel terminal state.
