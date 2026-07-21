# Driver execution

## Steps and results

Implemented exactly the frozen deadline-precedence change. Each ordinary
snapshot now records one `observed_at`; ready is accepted only before deadline,
and the same value drives remaining sleep. The process-loss final snapshot gets
its own observation time; deadline exhaustion wins before ready or
not-importable. Final elapsed output retains a separate clock read. Protocol
text states that completed snapshots are classified against the deadline while
synchronous reads are not preempted.

Added isolated no-bytecode fake-clock cases for late ordinary ready
(`[0,1.1,1.15]` → timeout/4), late process-loss final ready
(`[0,0.4,1.2,1.25]` → timeout/4), and on-time process-loss final ready
(`[0,0.4,0.9,0.95]` → ready/0). Sleep raises if called.

Focused cowork passed in 16.66 seconds; Python syntax, shell syntax, diff,
Claude takeover, source, public audit, skill quick validation, session, and
receipt checks pass.

## Deviations

The first reciprocal call timed out with no candidate change. Its retry exited
0 but edited a staged input/wrong-stage file; status exposed
`inputs_fresh=false` and the waiter refused import. A new sealed reciprocal
stage with an exact output path produced valid complete evidence, though the
native wrapper timed out after the ready candidate was already on disk. The
driver inspected it, verified fresh sealed status, imported it, and verified
the receipt. No invalid stage was imported. No execution deviation from the
subsequently frozen plan occurred.
