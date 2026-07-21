# Validation

## Checks

Focused cowork passed with the two new NaN cases. Python compilation and
`git diff --check` passed. The first full auto-eight phase-one run passed 56/57
focused suites and failed only `test-tmux-config.sh`, whose deliberate contract
rejects a dirty uncommitted checkout; the umbrella gate stopped there after
26.52 seconds. This is retry-safe test precondition evidence, not a product
failure. A clean-commit retry is required.

## Outcome

After checkpointing the reviewed change, the clean auto-eight retry passed all
57 focused suites and the complete umbrella phase-one gate in 77.22 seconds.
Both direct NaN cases exit 1 before any snapshot with their existing concise
range messages, no traceback, and no JSON. Python AST and diff checks pass.

## Residual risks

Accepted. The standard waiter still cannot preempt a synchronous filesystem read. The
first Claude candidate was factually invalid and intentionally remains outside
the receipt chain; the accepted retry shows narrow prompts with exact paths are
important even for short audits. The exact round-6 sandbox was removed through
a revalidated guarded-delete manifest with protected anchors unchanged.
