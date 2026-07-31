# Cowork execution, validation, and duration

Read this file completely before target execution, validation, or a
duration-bounded cowork run.

## Execute and validate

The benchmark agreement precedes target execution. Require both exact
role-bound benchmark agreements, required independent and reciprocal receipts,
validated live evidence, the frozen reconciliation, and the controlling owner
go before advancing:

```text
scripts/cowork-session advance SESSION_DIR ready-for-execution
scripts/cowork-session advance SESSION_DIR executing
```

Re-read `state.json`, `charter.md`, `benchmark.md`, and reconciliation from
disk. Revalidate target identity, authority, cleanliness, baseline drift,
rollback, and all task-specific safety gates. Let only the driver mutate the
target.

Execute small steps and record commands, results, deviations, and evidence
pointers in `execution.md`. Record every candidate iteration against the frozen
benchmark: hypothesis, before/after digest or diff, exact check and input
identity, observed result, and keep/revert decision. Unchanged blind retries do
not count as iterations; iterate only after a distinct observed failure.

A new material choice, failed gate, unsafe disagreement, missing authority, or
ambiguous partial action stops execution and returns the work to owner review.
Do not infer permission from prior sandbox work or co-pilot agreement.

Advance to `validating`, run all frozen acceptance and regression checks, and
record them in `validation.md`. The co-pilot may challenge the final diff in a
read-only pass but may not repair the target. Advance to `complete` only when
the validator and target acceptance gates pass and no required disagreement
remains. Checkpoint modified files, evidence paths, failures and retry safety,
cleanup, residual risks, and exact next action.

## Duration-bounded work

Use `long-running-task-ledger`. Before target execution, freeze the benchmark,
evidence cadence, stop conditions, requested duration, material-work cutoff,
and final-validation window. Iterate only from recorded measurements.

The final summary and durable ledger summary must each include exactly one
timestamped, evidence-backed time-slice entry per requested hour, rounded up,
plus outcome, validation, residual risks, and exact next action. Each must total
at least `max(300, 50 * ceil(requested hours))` words. A no-change slice records
the stable blocker or wait evidence. Invented results, subdividing one finding
across slices, and padding do not count.
