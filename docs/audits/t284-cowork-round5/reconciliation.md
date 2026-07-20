# Reconciliation

## Evidence accepted

Codex's deterministic probe and Claude's independent source trace agree that
deadline exhaustion is consulted only after readiness today. A snapshot
completed at 1.1 seconds under a 1.0-second budget returns ready/0, and the same
ordering affects the final process-loss re-read. This is an outcome-classifying
bug: synchronous reads cannot be preempted, but late facts must be classified as
timeout. Equality is timeout, matching existing `remaining <= 0` behavior.

Accept the reciprocal refinement: capture one `observed_at` immediately after
each completed snapshot, check it before either positive or negative content
classification, and reuse it for the ordinary remaining budget. Keep a fresh
final monotonic read for total `elapsed_seconds`.

## Disagreements and uncertainty

The first reciprocal call timed out with candidate unchanged. A same-stage
retry exited 0 but edited a staged input/wrong-stage evidence file, making
`inputs_fresh=false`; the waiter returned not-importable and nothing was
imported. A fresh reciprocal stage with an exact output path produced complete
fresh evidence; its native wrapper later hit the cap after writing the valid
candidate. The driver inspected the full five-heading candidate and accepted
it only after status showed all fresh observations and import/receipt checks
passed. These failures reinforce, rather than weaken, sealed stage semantics.

There is no initial-ready exception or grace beyond the deadline. A final
process-loss snapshot completed late returns timeout even if its content would
otherwise be ready or not-importable. The limitation is classified snapshots,
not hard I/O preemption, and must be documented.

## Frozen plan

1. In `wait_copilot`, after every ordinary snapshot capture
   `observed_at=time.monotonic()`. Only accept ready when
   `observed_at < deadline`; reuse it for remaining sleep.
2. After the process-loss final snapshot, capture a fresh `observed_at`; if it
   is `>= deadline`, keep timeout/4, otherwise classify ready/0 or
   not-importable/2. Leave final elapsed reporting on its own clock read.
3. Add deterministic no-bytecode unit cases: late ordinary ready
   `[0.0,1.1,1.15]` → timeout/4; late process-loss final
   `[0.0,0.4,1.2,1.25]` → timeout/4; on-time process-loss final
   `[0.0,0.4,0.9,0.95]` → ready/0. Patch sleep to fail if invoked.
4. Clarify in protocol docs that completed snapshots are classified against the
   deadline but a synchronous read is not preempted.
5. Run focused cowork, syntax/source/public/takeover/diff/session/receipt,
   checkpoint, clean full phase one, fresh-clone validation, and cleanup.

## Acceptance gates

Do not add threads, signals, clock fields, exit codes, or API flags. Deterministic
tests must restore monkeypatches by using an isolated loaded module and must
disable bytecode. Every existing real-window outcome remains advisory and
non-authorizing. The native reciprocal timeout is recorded evidence, not proof
against the candidate bytes that were complete and independently inspected.
