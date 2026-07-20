# Driver evidence

## Sandbox and baseline

Canonical checkout `/home/rioyokota/harness` at `c78c45a`; read-only source and
Python-expression probes only, with no target mutation.

## Commands and results

Python 3 reported `nan <= 0` false and `nan > 1800` false, while
`math.isfinite(nan)` is false. Positive infinity fails the upper bound and
negative infinity fails the lower bound. It also reported
`min(1.0, nan) == 1.0`. Source inspection confirms timeout and poll validation
use only ordered comparisons before constructing the monotonic deadline.

## Critique

The advertised bounded wait is false for a NaN timeout: absent readiness or
process loss, the loop can sleep one second indefinitely. A NaN poll is also an
unhandled error path. Relying on argparse float conversion is insufficient.

## Proposed plan changes

Require `math.isfinite` for both arguments before all filesystem snapshots,
reuse the existing concise range messages, and add externally bounded CLI tests
that assert exit 2 and no JSON for `nan`. Preserve all finite-value semantics.
