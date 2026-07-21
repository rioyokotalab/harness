# Initial plan

## Confirmed facts and assumptions

`argparse` accepts `nan` as a float. In the current range checks, comparisons of
NaN with both bounds are false. For a NaN timeout, `deadline` and `remaining`
remain NaN and `min(1.0, nan)` sleeps one second repeatedly; for a NaN poll,
`time.sleep(nan)` can fail rather than emit the promised final JSON. Assume the
correct contract is finite numeric values within the documented ranges.

## Steps

1. Have both agents independently inspect/reproduce the non-finite behavior.
2. Reconcile whether explicit finiteness checks are sufficient and where they
   must occur.
3. If accepted, import `math`, reject non-finite timeout and poll values before
   the first snapshot, and add CLI-focused regression cases.
4. Run focused cowork, syntax/diff, and phase-one acceptance; update durable
   evidence and clean the disposable sandbox.

## Evidence questions

Can NaN bypass either range check? Do infinities already fail? Must rejection
occur before any session/stage read? Does the fix preserve exit/error behavior
for valid bounds and avoid broadening the monitoring API?

## Risks and recovery

Do not test a potentially infinite invocation without an external bound. Any
partial co-pilot output is non-importable. Stop on disagreement about accepted
numeric syntax or if focused/full regressions fail. All target edits remain
reversible Git changes; temporary tree cleanup uses guarded deletion.
