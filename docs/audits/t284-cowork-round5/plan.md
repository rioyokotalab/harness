# Initial plan

## Confirmed facts and assumptions

Current `wait_copilot` computes `deadline`, reads a snapshot, checks full
preconditions, and only afterward computes remaining time. A deterministic
driver probe made `monotonic()` return 0.0 at start and 1.1 after a ready
snapshot with a 1.0-second timeout; the command returned ready/0 with
`elapsed_seconds=1.1`. Snapshot reads themselves cannot be forcibly bounded,
but their completed observation must be classified against the deadline.

## Steps

1. Record exact deterministic reproduction and immutable baseline.
2. Stage a blinded independent prompt asking Claude to derive deadline
   precedence without seeing Codex's conclusion.
3. Import, then stage reciprocal evidence with the reproduction and require
   critique of initial-ready, ordinary poll, process-loss final-read, and exact
   deadline equality.
4. Reconcile timeout semantics and freeze only helper/test/doc changes needed.
5. Execute under owner go, run focused checks, checkpoint cleanly, run final
   full phase one and fresh-clone validation, complete, and clean scratch.

## Evidence questions

Should a ready snapshot completed exactly at the deadline count or timeout?
Should a process-loss final snapshot be allowed to finish after the deadline,
or should timeout win consistently? How can a deterministic unit avoid sleeping
and prove ordering? Does checking elapsed before readiness change immediate
ready or normal real-window behavior?

## Risks and recovery

Filesystem reads are synchronous and can exceed a deadline; this command can
bound polling decisions but cannot preempt a blocked read. Define the guarantee
honestly as deadline precedence at each completed snapshot. Fake-clock tests
must not create bytecode. Treat equality consistently and avoid multiple clock
reads that complicate deterministic behavior.
