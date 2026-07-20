# Initial plan

## Confirmed facts and assumptions

Confirmed: the published helper supports `init`, `check`, `digests`,
`verify-receipts`, `stage`, `import-copilot`, and `advance`, but has no concise
status or wait surface. Each stage copies full charter/plan inputs; the driver
currently creates the task prompt after staging, so that prompt is not committed
by `stage.json` or the external seal. The co-pilot returns a complete evidence
file in both independent and reciprocal passes. The focused suite takes 10.12
seconds locally; the clean full gate takes 88.18 seconds with four workers.
CI runs several suites individually and then runs the umbrella gate, which
repeats them. Assumptions to falsify: a sealed prompt input can reduce manual
handoff ambiguity; a read-only stage/status snapshot can replace ad hoc polling
without pretending PID or file size proves authorship; reciprocal exchange can
be made delta-oriented without losing a complete final evidence record; and
validation concurrency or CI topology can reduce wall time without hidden
shared-state interference.

## Steps

1. Reproduce helper and validation timings in each matched sandbox and identify
   the actual critical path, including four- versus eight-worker full checks.
2. Prototype the smallest sealed-prompt and one-shot stage-status interfaces in
   each sandbox. Status must never mutate the stage/session, trust a co-pilot
   claim as proof, or weaken import validation.
3. Test whether a reciprocal critique can return a bounded addendum that the
   driver deterministically combines with the already-receipted independent
   evidence, while preserving a complete final `copilot-evidence.md` and closed
   receipt chain. Reject this if recovery or validation becomes less clear.
4. Inspect CI duplication and test-runner duration evidence. Compare a safe
   topology change against the unchanged full gate; do not remove coverage for
   a cosmetic speedup.
5. Exchange independent results through a sealed stage, run one reciprocal
   falsification pass, and freeze accepted/rejected changes in
   `reconciliation.md`.
6. Only after `ready-for-execution`, implement accepted changes in the target,
   validate incrementally, and record timing deltas and residual risks.

## Evidence questions

Which manual steps and bytes can be removed from the two client windows? Can a
task prompt be committed by the external seal without expanding the live
session write grant? What stage facts can the driver observe safely while the
co-pilot runs, and which remain only advisory? Is complete-evidence replacement
twice materially slower or more reliable than an independently receipted base
plus reciprocal addendum? Which phase-one suites dominate elapsed time, do they
contend at eight workers, and which CI steps are exact duplicates of the
umbrella gate? Can the same changes be used unchanged when Claude is driver?

## Risks and recovery

New metadata can break old receipts or make a stage unrecoverable; retain
backward readers or reject the design. Polling a PID can race with PID reuse and
candidate size can signal only observed bytes, never semantic progress or
authorship; label those limits. A prompt copied after sealing is untrusted, so
any sealed-prompt design must validate the exact copied bytes at import.
Parallel tests may share repository or user state; treat any mismatch as a stop
and keep the four-worker default. A client timeout or permission denial is
retry-safe only after candidate, stage, protected digests, and target state are
inspected. Retain sandboxes, stages, seals, and logs until checkpointed, then
use guarded deletion for every tree or multi-path cleanup.
