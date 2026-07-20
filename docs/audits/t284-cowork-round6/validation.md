# Validation

## Checks

Focused cowork passed with the two new NaN cases. Python compilation and
`git diff --check` passed. The first full auto-eight phase-one run passed 56/57
focused suites and failed only `test-tmux-config.sh`, whose deliberate contract
rejects a dirty uncommitted checkout; the umbrella gate stopped there after
26.52 seconds. This is retry-safe test precondition evidence, not a product
failure. A clean-commit retry is required.

## Outcome

Pending the clean-commit full phase-one retry, current behavior is accepted by
both receipt-valid agent passes and the focused regression only.

## Residual risks

The standard waiter still cannot preempt a synchronous filesystem read. The
first Claude candidate was factually invalid and intentionally remains outside
the receipt chain; the accepted retry shows narrow prompts with exact paths are
important even for short audits.
