# Co-pilot evidence

## Sandbox and baseline

Sandbox: `/tmp/harness-t284-r5.X6y0SH/claude`, stage `stage-reciprocal-retry`,
reciprocal-mode inspection with `driver-evidence.md`, `charter.md`, `plan.md`,
and the imported `copilot-evidence.md` (round-4/independent) as staged inputs.
`git rev-parse HEAD` = `f3114a881ea0adb05c82c48d0018b549f72a6d5a`, matching
`charter.md`'s stated baseline. No target files were mutated; every command
below is read-only (`grep -n`, `sed -n`, `Read`). Re-read `wait_copilot`
(`shared/skills/codex-claude-cowork/scripts/cowork-session` L1257-1304), its
snapshot source `status_snapshot` (L1144-1249), and
`references/protocol.md` L280-324 to check whether the reconciled fix changes
any documented contract. This file is written only to the exact candidate
path `stage-reciprocal-retry/candidate-copilot-evidence.md`; `copilot-evidence.md`
and every other staged input were left untouched.

## Commands and results

- `grep -n "def wait_copilot\|started = time.monotonic\|deadline = started\|while True:\|all_satisfied\|not-reachable\|remaining = deadline\|time.sleep(min\|wait_observation\|elapsed_seconds\|SystemExit(exit_code)" cowork-session`
  confirms the exact lines both `driver-evidence.md` and the imported
  `copilot-evidence.md` cite: `started`/`deadline` at L1266-1267, the
  unconditional `all_satisfied` ready check at L1274, the process-loss final
  re-read and its own unconditional `all_satisfied` check at L1279-1289, the
  clock-consulted-only-for-sleep `remaining = deadline - time.monotonic()` at
  L1290, and the unconditional `elapsed_seconds = round(time.monotonic() -
  started, 3)` at L1297. Nothing has drifted from the prior round's line
  numbers.
- `sed -n '280,324p' references/protocol.md`: the documented contract says
  `wait-copilot` "returns `ready`/0 only for the full three-fact conjunction,
  `not-importable`/2 only after an observed process loss and one immediate
  final snapshot, or `timeout`/4" and separately asserts "A ready-but-stale
  candidate never returns ready." Neither sentence currently distinguishes
  *byte staleness* (which the doc already covers) from *temporal staleness*
  (a snapshot that completes after the deadline) — the exact gap
  `driver-evidence.md` and `plan.md` target. The doc also has no sentence
  admitting that a single synchronous `status_snapshot()` call cannot be
  aborted once started.

## Observations, inferences, and residuals

**Observations:**
- Reconciling `driver-evidence.md`'s requested shape against the current
  code, the minimal patch needs exactly one new local per snapshot-completion
  site, reused, plus one separate final read:
  ```python
  started = time.monotonic()
  deadline = started + args.timeout_seconds
  process_loss_observed = False
  outcome = "timeout"
  exit_code = 4
  while True:
      snapshot = status_snapshot(args)
      observed_at = time.monotonic()                 # one read per completed snapshot
      preconditions = snapshot["stage"]["mechanical_import_preconditions"]
      if observed_at < deadline and preconditions["all_satisfied"]:
          outcome = "ready"
          exit_code = 0
          break
      process = snapshot["process"]
      if process is not None and process["state"] == "not-reachable":
          process_loss_observed = True
          snapshot = status_snapshot(args)
          observed_at = time.monotonic()              # fresh read for THIS snapshot only
          preconditions = snapshot["stage"]["mechanical_import_preconditions"]
          if observed_at >= deadline:
              outcome = "timeout"
              exit_code = 4
          elif preconditions["all_satisfied"]:
              outcome = "ready"
              exit_code = 0
          else:
              outcome = "not-importable"
              exit_code = 2
          break
      remaining = deadline - observed_at              # reuse, no extra clock call
      if remaining <= 0:
          break
      time.sleep(min(args.poll_seconds, remaining))

  snapshot["wait_observation"] = {
      "outcome": outcome,
      "elapsed_seconds": round(time.monotonic() - started, 3),  # fresh final clock, not observed_at
      "process_loss_observed": process_loss_observed,
      "pid_identity_authenticated": False,
      "advisory": True,
      "authorization": "none",
  }
  ```
  This satisfies the driver's exact reconciliation request: one
  `observed_at` per completed snapshot (ordinary loop body and the
  process-loss final re-read are two distinct sites, each gets its own single
  read — they are never the same call), checked with `>= deadline` *before*
  either a `ready` or a `not-importable` classification is allowed to stand;
  `observed_at` is reused for the `remaining`/sleep decision on the ordinary
  path (no second, redundant clock read in the same iteration); and a
  separate, later `time.monotonic()` call is made once, after the loop, for
  `elapsed_seconds`, rather than reusing the last `observed_at`.
- On the ordinary path, equality (`observed_at == deadline`) fails
  `observed_at < deadline` and falls through — consistent with the existing
  `remaining <= 0` boundary already treating equality as exhausted, so the
  patch introduces no second, divergent equality rule.
- On the process-loss path, the deadline check is evaluated first and
  unconditionally decides `timeout` before `all_satisfied` is even
  consulted — this is the one place the reconciled design diverges from a
  naive "add the check to both branches independently" reading of
  `driver-evidence.md`: a late final read is `timeout`, never
  `not-importable`, even though the pre-patch code could have called it
  `not-importable` if unsatisfied. Deadline exhaustion is defined to
  supersede a negative content classification too, since by the time of a
  late read the budget itself is the reason the wait is ending, not the
  content of that specific read.
- Deterministic, no-sleep fake-clock sequence for **late ordinary ready**
  (mirrors the driver's 1.1s-over-1.0s probe): `time.monotonic` returns
  `[0.0, 1.1, 1.15]` in order (`started`, `observed_at` after the first
  `status_snapshot`, and the post-loop elapsed read), `status_snapshot` is
  stubbed to return an already-`all_satisfied` snapshot with `process=None`,
  `timeout_seconds=1.0`, and `time.sleep` is patched to raise if invoked.
  Trace: `started=0.0`, `deadline=1.0`; iteration 1 takes the snapshot,
  `observed_at=1.1`; `1.1 < 1.0` is false, so the ready branch is skipped
  even though `all_satisfied` is true; `process is None` skips the
  process-loss branch; `remaining = 1.0 - 1.1 = -0.1 <= 0`, loop breaks with
  the pre-initialized `outcome="timeout"`, `exit_code=4`; `time.sleep` is
  never called (proving no real delay); the final `elapsed_seconds` read
  consumes the third mock value, `1.15`, giving `elapsed_seconds=1.15` —
  strictly greater than `observed_at=1.1`, demonstrating the fresh-clock read
  is a distinct call, not a re-use of `observed_at`.
- Deterministic, no-sleep fake-clock sequence for **late process-loss final
  read**: `time.monotonic` returns `[0.0, 0.4, 1.2, 1.25]` (`started`, the
  ordinary-loop `observed_at`, the process-loss-final-read `observed_at`, the
  post-loop elapsed read), `status_snapshot` is stubbed to return
  `all_satisfied=False`/`process.state="not-reachable"` on its first call and
  `all_satisfied=True` on its second call, `timeout_seconds=1.0`, `time.sleep`
  patched to raise. Trace: `started=0.0`, `deadline=1.0`; iteration 1 takes
  the first snapshot, `observed_at=0.4`; `0.4 < 1.0` but `all_satisfied` is
  false, so the ready branch is skipped on content, not time; `process.state
  == "not-reachable"` triggers `process_loss_observed=True` and one *second*
  `status_snapshot` call; its `observed_at=1.2`; `1.2 >= 1.0` is true, so
  `outcome="timeout"`, `exit_code=4` is set *without* consulting the
  second snapshot's `all_satisfied=True` at all, and the loop breaks;
  `time.sleep` is never called; the final elapsed read consumes the fourth
  mock value, `1.25`, giving `elapsed_seconds=1.25`. A sibling case with the
  same stubs but `observed_at=0.9` on the final read (`< deadline`) is needed
  alongside it to prove the *positive* process-loss path still returns
  `ready`/0 unchanged — the fix must not turn every process-loss final read
  into `timeout`, only the late ones.

**Inferences:**
- Reusing `observed_at` for the ordinary-path `remaining` computation (rather
  than a third `time.monotonic()` call inside the same iteration) is not
  merely an optimization: it guarantees the ready-classification instant and
  the retry/give-up instant are the *same* observation, so there is no window
  in which the code could inconsistently treat one instant as "before
  deadline" for classification and a fractionally later instant as "after
  deadline" for the retry decision within a single loop body.
- Using a separate, later clock read for `elapsed_seconds` is the correct
  choice precisely because `elapsed_seconds` is documented (and tested
  elsewhere in the suite) as wall-clock time actually spent inside
  `wait_copilot`, including the small amount of work between the last
  `observed_at` and the function's return (building `wait_observation`,
  `json.dumps`). Reusing the classification-time `observed_at` for
  `elapsed_seconds` would under-report elapsed time and could, in a
  pathological case, report `elapsed_seconds < timeout_seconds` even when the
  outcome is `timeout`, which would read as self-contradictory in the JSON
  output.

**Residuals:**
- This is still classification of a *completed* snapshot, not preemption of
  an in-flight one: if a single `status_snapshot()` call blocks past the
  deadline, `wait_copilot` cannot return until it unblocks, regardless of how
  large the overrun is. The reconciled design does not change this — it only
  ensures that whenever a snapshot *does* complete, its `observed_at` is
  checked against `deadline` before either `ready` or `not-importable` is
  allowed to stand.
- Could not exercise the real 1.1s-timeout / 1.0s-budget case as a live
  subprocess from this stage (no access to the driver's own probe
  transcript or a writable target); the two fake-clock sequences above are
  proposed deterministic regressions, not independently re-run wall-clock
  trials.

## Critique

`driver-evidence.md`'s reconciliation request is achievable with exactly one
new local (`observed_at`) per snapshot-completion site, no new function, no
new field, and no change to `--timeout-seconds`/`--poll-seconds` validation.
The two sites are not symmetric in one respect worth calling out explicitly
in the frozen plan: on the ordinary path, `observed_at >= deadline` simply
falls through to the existing `remaining <= 0` retry/give-up logic (already
present, just now fed a reused clock value instead of a second read); on the
process-loss path there is no "fall through and retry" option — the loop
always `break`s after the final re-read — so the deadline check there must
directly decide between `timeout` and the pre-existing `ready`/`not-importable`
pair, and must be evaluated first so that a late-but-unsatisfied final read
still reports `timeout` (the budget's exhaustion, not the content) rather
than `not-importable`.

`references/protocol.md` L317-322 currently documents `wait-copilot`'s outer
contract (`ready`/0, `not-importable`/2, `timeout`/4) and the byte-staleness
guarantee ("A ready-but-stale candidate never returns ready") but says
nothing about temporal staleness or about the fact that a single synchronous
`status_snapshot()` read cannot be preempted once started. Both driver and
independent evidence converge on the same honest framing: the fix bounds
*classification*, not *execution*. That framing is not obvious from the
current doc text and should be added rather than left implicit — a caller
reading only the protocol doc could otherwise assume `--timeout-seconds` is a
hard wall-clock bound on the call itself. Concretely, `protocol.md` L317-322
should gain one sentence stating that `ready`/`not-importable`/`timeout` are
decided by comparing each completed snapshot's own read time to the deadline,
and that a single slow synchronous read is not interrupted by the timeout.

## Proposed plan changes

Freeze the smallest production change plus two deterministic tests; no
broader `wait_copilot`/`wait-copilot` API, CLI flag, or CI topology change:

1. In `wait_copilot`, replace the unconditional `all_satisfied` checks at
   L1274 and L1283 with the reconciled sequence above: one `observed_at =
   time.monotonic()` per completed snapshot (ordinary loop body, and
   separately the process-loss final re-read), each checked with `>=
   deadline` before a `ready`/`not-importable` classification is accepted;
   reuse the ordinary-path `observed_at` for the L1290 `remaining`
   computation instead of a second `time.monotonic()` call there; leave the
   L1297 `elapsed_seconds` computation as its own, separate, later
   `time.monotonic()` call, not a reuse of any `observed_at`.
2. Add the **late ordinary ready** deterministic regression exactly as
   traced above (`time.monotonic` sequence `[0.0, 1.1, 1.15]`,
   `timeout_seconds=1.0`, `time.sleep` patched to raise): assert
   `SystemExit(4)`, `outcome == "timeout"`, and `elapsed_seconds == 1.15`
   (not `1.1`), the last assertion specifically proving the fresh-clock read
   is exercised.
3. Add the **late process-loss final read** deterministic regression exactly
   as traced above (`time.monotonic` sequence `[0.0, 0.4, 1.2, 1.25]`,
   `status_snapshot` stubbed not-reachable-then-satisfied,
   `time.sleep` patched to raise): assert `SystemExit(4)`, `outcome ==
   "timeout"` (not `"ready"` despite the second snapshot's
   `all_satisfied=True`), and `elapsed_seconds == 1.25`. Pair it with one
   on-time control case (`observed_at=0.9` on the final read) asserting the
   pre-existing `ready`/0 outcome is unchanged, so the regression cannot pass
   by accident from an overly broad `timeout` default.
4. Update `references/protocol.md` L317-322 to add one sentence
   distinguishing classification-time deadline precedence from execution-time
   preemption: state that `ready`/`not-importable`/`timeout` are decided from
   each snapshot's own completion time against the deadline, and that a
   single blocked synchronous read is not interrupted by
   `--timeout-seconds`. No other doc line, exit code, or field name changes.
