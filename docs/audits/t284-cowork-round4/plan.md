# Initial plan

## Confirmed facts and assumptions

Round 3 passed all focused and full checks and added `wait-copilot`; its
synthetic tests cover ready, transient writes, stale process loss, and timeout.
Earlier real Claude windows required two to four manual `status` invocations.
This round tests the new single-wait path against actual client timing. PID is
the native timeout-wrapper process and remains advisory, not authenticated.

## Steps

1. Validate predecessor, matched clean clones, planning files, and protected
   digests; advance discussing.
2. Stage an independent bounded prompt and start Claude Sonnet/medium in the
   background with a 180-second cap, recording its wrapper PID and native log.
3. Start exactly one `wait-copilot` with that PID, stage, seal, 180-second
   timeout, and one-second poll. Do not issue manual status during the window.
4. Compare elapsed times and all sealed/protected bytes, inspect one final wait
   JSON, import the candidate, and verify the independent receipt.
5. Add exact observed native/wait results to driver evidence, then stage a
   reciprocal critique asking Claude to attack races, outcome semantics,
   adaptive checking, and prompt compactness.
6. Use the same single-wait path for reciprocal evidence; import and verify.
7. Reconcile. If no defect is reproduced, freeze a no-code acceptance plan; if
   one narrow defect is evidenced, freeze only its fix and focused regression.
8. Run required focused/session/fresh-clone checks, record outcome, complete,
   and retain scratch for guarded cleanup.

## Evidence questions

Does wait return before, with, or after the native wrapper, and is early ready
safe when the client process is still reachable? Is `elapsed_seconds` useful
and is the final process state honest? Does stdout remain one JSON document with
no progress chatter? Are process-loss and timeout meanings sufficiently clear?
Does a compact sealed prompt finish faster without losing evidence quality?
Does auto mode leave any hidden checkout writes or ambiguous selected-worker
reporting after the no-bytecode correction?

## Risks and recovery

Claude may write the complete candidate before its wrapper exits, so ready can
legitimately precede native completion; always wait for and separately inspect
the native exit. A timeout leaves stage/live state unchanged and is retry-safe
only after status/seal/digest review. Do not treat one client elapsed time as a
general benchmark. Any new top-level stage residue fails closed. Cleanup stays
deferred and must use guarded deletion for trees.
