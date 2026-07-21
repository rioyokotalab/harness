# Reconciliation

## Evidence accepted

Two real Claude windows validate the new orchestration path. Independent and
reciprocal waiters each emitted one parseable JSON document and returned ready
while the native wrapper remained honestly `reachable`; native exit followed
6.280 and 7.683 seconds later. Both native commands exited 0 before protected,
stage, and seal comparison, import, and receipt verification. This confirms the
waiter safely reduces driver interaction turns without claiming lower model
inference or end-to-end native wall time.

Claude found no code defect in waiter timeout, status sharing, adaptive jobs, or
no-bytecode behavior. Its timing critique is accepted: the original driver
paragraph omitted the 8.508-second staggered start and included an erroneous
second delta. Driver evidence now records both start offsets/common-clock gaps
and explicit native-exit-before-import ordering. The protocol already states
that ordering unambiguously.

## Disagreements and uncertainty

The independent pass could not execute the real process and appropriately kept
PID reuse as a residual. Reciprocal critique established that the existing
process-loss test starts with a permanently absent PID; it does not exercise a
real reachable-to-not-reachable transition. Replace that fake PID with a short
real child in the same stale-candidate test so coverage improves without adding
a second redundant case.

Defer a repository-wide `__pycache__` absence assertion. It would fail on
pre-existing unrelated developer bytecode or need a noisy snapshot protocol;
the exact import already uses `PYTHONDONTWRITEBYTECODE=1`, standalone focused
coverage leaves no cache, and clean parallel full phase one passed. No evidence
supports more production code or runbook changes.

## Frozen plan

1. In the existing stale-candidate/process-loss waiter test, start `sleep 0.5`,
   pass its real PID, and wait/reap it after the helper returns. Preserve the
   exit-2, `not-importable`, process-loss, stale-precondition, no-authority
   assertions. This replaces rather than adds the fixed unreachable PID path.
2. Run the focused cowork suite and session/receipt/diff checks. There is no
   production code, worker, CI, or runbook change and no need to repeat full
   phase one already passed at the unchanged implementation commit.
3. Advance through executing/validating/complete, checkpoint the corrected
   evidence and test, then prove the completed successor validates in a fresh
   clone.

## Acceptance gates

The live process test depends only on POSIX `sleep`, already assumed throughout
the shell suite. A 0.5-second child plus one-second poll adds about one second to
the focused cowork gate; it replaces a structural case with a real transition.
PID identity remains advisory and the test does not claim to eliminate reuse.
Client timings are two observations on one shared host and support reduced
interaction count, not a model-speed claim.
