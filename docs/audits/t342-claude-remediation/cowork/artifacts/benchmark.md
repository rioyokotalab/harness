# T-342/T-035 agreed benchmark

## Identity

- Benchmark: `t342-t035-claude-remediation-v1`
- Students baseline: `1376690`
- Harness baseline: `5276ddf41fba20d0ab299608db587f1fa2a563da`
- Driver: Codex
- Co-pilot: Claude Code, installed `fable` alias, high effort

## Cases

1. `SCOPE-READONLY`: Students tasks whose scopes are only `analysis` and/or
   `planning` launch neither Codex nor Claude with project-write capability.
   A read-only task that declares expected artifacts is rejected before native
   launch with a stable blocker.
2. `SCOPE-WRITE`: `code_preparation` and `experiment_preparation` grant only
   the project-local write tools/sandbox required by the selected native
   client.  Network, external actions, and unsandboxed commands remain denied.
   `compute_execution` remains compute-gated and grants no implicit writes.
3. `SESSION-TASK`: A native session can resume retries of the same task but is
   never resumed by a different task in the same project.  Pending outcome
   acknowledgement stays durable and bound to the same task.  New state is
   schema 2.  Empty schema-1 state migrates to schema 2; nonempty schema-1
   state fails closed because no prior task identifier exists and guessing
   would transfer authority.
4. `STUDENTS-GATE`: New focused regression tests and
   `uv run --frozen --no-sync tools/check.sh` pass from a clean Students task
   worktree.
5. `COWORK-BENCHMARK`: Every new cowork session creates a dedicated benchmark
   before independent evidence.  Both clients must record agreement or an
   explicit disagreement; the helper cannot advance to execution until
   acceptance cases and reciprocal evidence are complete.
6. `ITERATION-EVIDENCE`: Each candidate iteration records its hypothesis,
   changed bytes, exact check, observed result, and resulting keep/revert
   decision.  Retrying an unchanged failed or ambiguous invocation does not
   count as progress.
7. `CLAUDE-DEFAULT`: Both tracked Harness Claude project-setting mirrors
   validate as exactly model `fable`, effort `high`, with the existing
   permission policy preserved.  A disposable native project-scoped check
   identifies Fable/high without a CLI model or effort override.  No user
   product settings are modified.
8. `DURATION-TRIGGER`: An owner request that specifies a duration or time
   window for continued work must invoke the cowork and long-running-ledger
   workflows.  Its benchmark freezes evidence cadence and a stop condition
   before execution.
9. `DURATION-SUMMARY`: A duration-specified job's durable and user-facing
   summary is at least `max(300, 50 * ceil(requested hours))` words and contains
   exactly one evidence-backed time-slice item per requested hour, rounded up,
   plus outcome, validation, residual risks, and exact next action.  A slice
   with no new result names the stable blocker/wait state and timestamped
   evidence; it must not invent or subdivide results.  Repeated narration and
   padding do not satisfy the gate.
10. `HARNESS-GATE`: Focused cowork/config/takeover tests,
    `tests/test-phase1.sh`, `git diff --check`, and project-policy validation
    pass from a clean Harness task worktree.

## Agreement gate

Before implementation, Codex and Claude must independently assess whether each
case is observable, safe, and sufficient.  The reconciliation records accepted
changes to this benchmark.  Target execution is forbidden until both evidence
files and the final benchmark agreement are complete.

AGREE driver=codex benchmark=t342-t035-claude-remediation-v1

AGREE copilot=claude benchmark=t342-t035-claude-remediation-v1

## Iteration stop

Stop only when every case passes, a case is explicitly rejected during
reconciliation, or a non-retryable blocker is recorded with preserved raw
evidence and an exact owner decision or external-state change needed.
