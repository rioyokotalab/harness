# Reconciliation

## Evidence accepted

The six clean sequential samples are accepted as a stable host-scoped result:
all 342 suite executions passed; the jobs-8 median was 25.35 seconds versus
29.69 for jobs 4, a 14.62% reduction, with only 0.14–0.15 seconds of within-arm
range and no overlap. Claude correctly rejects a universal fixed eight-worker
claim because only one eight-CPU host was measured. Codex accepts Claude's
reciprocal middle ground: make the unset default affinity-aware—eight only when
at least eight CPUs are visible, otherwise four—while preserving explicit
numeric overrides and legacy mode. The claim remains conditional, not global.

Both sides accept a bounded read-only waiter sharing the exact status snapshot.
Claude's reciprocal correction is accepted: empty or invalid bytes are normal
while an editor is writing and cannot terminate while a tracked process remains
reachable. Only the full structural/input/destination conjunction can yield
`ready`; after observed PID loss, one immediate final snapshot resolves either
`ready` or `not-importable`; without a PID only `ready` or `timeout` can occur.

## Disagreements and uncertainty

The independent Claude pass saw no timing numbers by design and recommended
retaining four; the reciprocal pass withdrew that unconditional position after
seeing the non-overlapping measurements, but still rejected fixed eight. The
affinity gate resolves this disagreement without claiming evidence on smaller
hosts. GitHub CI improvement is an inference until a protected run measures it.

Claude initially proposed terminating on `invalid`/`empty`; reciprocal review
corrected this after considering non-atomic editor writes. The frozen waiter has
three valid-invocation outcomes: `ready` (exit 0), `not-importable` after a
debounced observed PID loss (exit 2), and `timeout` (exit 4). Argument validation
uses existing helper error behavior rather than manufacturing JSON for parser
failures. PID reachability remains vulnerable to reuse and is never identity,
authentication, success, or failure evidence.

## Frozen plan

1. Refactor `cowork-session status` into a pure snapshot builder plus its
   unchanged one-shot JSON printer.
2. Add `wait-copilot SESSION --stage STAGE --seal SEAL
   --timeout-seconds SECONDS [--poll-seconds SECONDS] [--pid PID]`. Require
   `0 < timeout <= 1800` and `1 <= poll <= 60`, use a monotonic deadline, print
   exactly one final JSON snapshot, and append
   `wait_observation={outcome,elapsed_seconds,process_loss_observed,
   pid_identity_authenticated:false,advisory:true,authorization:"none"}`.
3. Return `ready`/0 only for the existing full mechanical conjunction. Never
   terminate on partial candidate bytes while PID is reachable. On
   `not-reachable`, take one immediate final snapshot, then return ready/0 or
   `not-importable`/2. With no PID, wait for ready or `timeout`/4. Never call
   import or write any session/stage/target file.
4. Add focused tests for immediate ready, transient invalid-to-ready with a
   reachable process, stale final candidate after process loss, no-PID timeout,
   argument bounds, single-JSON output, unchanged digests, and source separation
   from `import_copilot`.
5. Extend the focused runner with `--jobs auto`. Resolve visible CPUs from
   `sched_getaffinity(0)` when available and otherwise `os.cpu_count()`, then
   choose eight at `>=8` and four below. Print the resolved selection once.
   Change only the unset phase-one default to `auto`; explicit numeric and
   `legacy` values remain unchanged.
6. Add deterministic function tests for 7→4, 8→8, and larger→8 plus a real auto
   runner pass. Update the skill/protocol monitoring and checking mappings.
7. Run focused cowork/runner, source, public, takeover, AST, shell, receipt,
   fresh-clone, and diff checks; checkpoint; then run clean full phase one using
   auto. Record measured resolution and elapsed time. No CI topology change.

## Acceptance gates

Every wait outcome must retain `advisory: true` and `authorization: "none"`;
`import-copilot` remains the sole mechanical mutation gate. Tests must prove
session/stage/seal digests unchanged. Full phase one must show `auto` resolved
to eight on the measured eight-CPU affinity and pass all 57 suites. If it fails
or regresses beyond the clean 29.69-second focused median without an explained
non-focused tail, revert only the auto default and retain the explicit override.
Both receipts and a fresh Git clone must validate before completion.
