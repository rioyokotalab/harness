# Driver execution

## Steps and results

Implemented the frozen round-three plan on the task branch:

1. Refactored the helper's existing `status` body into
   `status_snapshot(args)` and kept `status` as the same deterministic JSON
   printer.
2. Added bounded `wait-copilot` with required stage/seal/timeout, optional PID,
   1–60 second polls and an 1800-second timeout ceiling. It uses a monotonic
   deadline and the shared snapshot; full fresh conjunction returns `ready`/0,
   observed PID loss triggers one final snapshot then `not-importable`/2, and
   no terminal observation returns `timeout`/4. Its JSON explicitly denies PID
   authentication and authorization. It has no import or write path.
3. Added ready/no-mutation, transient invalid-to-ready, stale-after-process-
   loss, no-PID timeout, bound-refusal, JSON-label, and source-separation tests.
4. Added focused-runner `--jobs auto`: visible CPUs come from process affinity
   when available and otherwise `os.cpu_count`; default selection is eight at
   eight or more visible CPUs and four below. The runner prints the resolved
   count. Explicit numeric jobs are unchanged.
5. Changed only unset `HARNESS_TEST_JOBS` phase-one behavior to `auto`; retained
   `legacy` and numeric overrides. Added deterministic 1/7→4 and 8/64→8 tests
   plus a real auto runner pass.
6. Updated the skill and protocol so drivers use one bounded wait rather than
   repeated polls, while preserving advisory/non-authorizing language and
   separate process, semantic, digest, import, and receipt gates.

Focused execution checks all passed: cowork 15.75 seconds; focused runner 0.49
seconds; Claude takeover; source contract; public repository audit; canonical
skill quick validation; Python AST; shell syntax; receipt verification; and
`git diff --check`.

## Deviations

I applied the frozen target edits immediately after the valid
`ready-for-execution` commit and explicit owner go, but advanced the durable
session state from ready to executing only after the focused implementation
checks. No safety or scope gate was skipped—the plan, receipts, target, and go
were already frozen—but the administrative phase transition should have
preceded the first edit. I recorded the ordering error rather than rewriting
history, advanced exactly one phase, and revalidated executing state and the
unchanged reciprocal receipt. No other deviation occurred.
