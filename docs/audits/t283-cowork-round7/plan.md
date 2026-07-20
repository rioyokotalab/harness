# Initial plan

## Confirmed facts and assumptions

- Confirmed: rounds 1–6 are tracked; schema-2 staged exchange now requires an
  external seven-key seal and writes schema-2 receipts that bind its digest.
- Confirmed: round 6 passed the clean full Phase 1 suite and recorded two
  process deviations rather than claiming process compliance.
- Confirmed: the protocol documents that `verify-receipts` does not reopen
  retained seals and that arbitrary target writes cannot presently be phase
  guarded by the helper.
- Assumption to test: these residuals are better treated as explicit operator
  checks than as another incompatible command surface.
- Assumption to test: both native-client directions remain operational with the
  new mandatory `--seal` arguments.

## Steps

1. Validate the live session at `planning`; inspect current helper/docs/tests and
   record the baseline hashes without changing the target.
2. In the Codex sandbox, exercise a complete schema-2 sealed independent and
   reciprocal exchange using synthetic evidence, plus misuse probes for missing,
   relocated, altered, and post-import seals. Record exact results.
3. Freeze driver evidence, take the protected digest manifest, create a blinded
   independent stage/seal, and invoke Claude only inside its sandbox. Require
   Claude to test the same release-candidate questions independently.
4. Import the candidate only after protected/stage/seal comparison and receipt
   validation. Then create a reciprocal stage/seal and ask Claude to challenge
   both evidence sets and return its complete evidence.
5. Reconcile into the smallest frozen action: accept a change only for a
   reproduced correctness or usability flaw with a focused regression; reject
   speculative hardening whose authority or persistence assumptions cannot be
   enforced. Advance to `ready-for-execution` only with two valid receipts.
6. Re-read state and the frozen plan, advance to `executing` before any live
   target edit, execute only the accepted scope, validate, checkpoint, close,
   and use guarded cleanup for all worktrees/stages/seals.

## Evidence questions

- Can the happy path be completed without guessing seal placement or argument
  order, and do common seal mistakes fail before live evidence mutation?
- Does retaining/reopening a seal add meaningful assurance after the receipt
  already binds its digest, and can such a check be path-free and takeover-safe?
- Can a generic helper mechanically prevent an arbitrary editor from changing
  target files before `executing`, or should the protocol instead surface that
  as a process invariant and audit deviation?
- Are schema-1 receipt compatibility, schema-2 direct mode, predecessor state
  projection, and both native CLI mappings still internally consistent?
- Do Claude and Codex reach the same conclusions from matched evidence, and
  where do their environment boundaries differ?

## Risks and recovery

Primary risk is destabilizing a validated helper late in the work window. Stop
and retain the current release candidate unless a failure is reproducible and
the fix has a focused regression. A failed client invocation is retryable only
after exact stage/candidate inspection. Any seal or protected-digest mismatch
stops import. Sandboxes are disposable but remain until evidence is reconciled;
cleanup uses guarded deletion, while Git commits and the tracked session provide
recovery. No target edit may occur until the `executing` transition succeeds.
