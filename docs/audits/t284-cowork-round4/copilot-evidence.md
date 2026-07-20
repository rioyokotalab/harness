# Co-pilot evidence

## Sandbox and baseline

Sandbox: `/tmp/harness-t284-r4.jSSkja/claude` (Claude clone), stage
`stage-reciprocal`, read-only reciprocal critique. `git rev-parse HEAD` =
`267560cf34152fabbf029c5fc5b3742b400993df`, matching `charter.md`. No target
files were mutated; all commands below are read-only (`grep`, `sed`, `Read`).
Reviewed `driver-evidence.md`'s real-window numbers against
`scripts/cowork-session` (`status_snapshot` L1144–1249, `wait_copilot`
L1257–1304), `references/protocol.md` L280–331, and
`tests/test-codex-claude-cowork-skill.sh` R9 (L1101–1260) /
`tests/test-focused-runner.sh` L52–90.

## Commands and results

- Read `wait_copilot` in full: confirms driver's source trace — one
  `status_snapshot` per iteration, `all_satisfied` checked before process
  reachability, one final `json.dumps` + `SystemExit`, no import/write call.
- `sed -n '270,331p' references/protocol.md`: the documented long-window
  template is `COPILOT_NATIVE_COMMAND ... & COPILOT_PID=$!` → `status` →
  `wait-copilot` → `wait "$COPILOT_PID"`, followed by "Inspect semantics,
  native process exit, protected digests, and receipts separately." `plan.md`
  L42–44 states the same requirement independently.
- `grep -n "R9\|not-reachable\|process_loss" tests/test-codex-claude-cowork-skill.sh`
  then read L1165–1260: the process-loss exercise uses a fixed,
  never-reachable PID (`2147483647`), not a live subprocess observed
  transitioning `reachable`→`not-reachable`. The earlier independent-round
  evidence (`copilot-evidence.md`, this session) flagged this as an
  unresolved residual; reading the full block resolves it: R9 is structural,
  not a live-process race test.
- Read `tests/test-focused-runner.sh` L52–65: the no-bytecode regression only
  asserts `default_jobs()` return values under `PYTHONDONTWRITEBYTECODE=1`;
  no line in the file asserts the absence of a `tools/__pycache__` directory
  after any run.

## Observations, inferences, and residuals

**Observations:**
- Recomputing driver's own numbers: native exit (146.586s) minus wait-ready
  (131.745s) is 14.841s, not the "roughly 6.3 seconds" driver reports for the
  wait-end-to-native-end gap, nor the "about 7.3 seconds" driver reports for
  the native-start-relative gap in the same sentence. Both figures could only
  be correct simultaneously under different, unstated origin offsets between
  when the native command and the `wait-copilot` call each started (the
  driver evidence never records absolute or common-origin start timestamps,
  only each command's own `elapsed_seconds`). As written, the two numbers are
  irreconcilable from the evidence given, and neither is derivable from the
  two elapsed values alone.
- `mechanical_import_preconditions.all_satisfied` (the sole driver of the
  `ready` outcome) is computed purely from candidate/input/destination bytes
  and never inspects `process`, confirming the driver's premise that "ready"
  can legitimately precede the wrapper's own exit — this part of the timing
  critique is well-supported by source, independent of the arithmetic issue.
- The documented runbook (protocol.md template + plan.md risk section) does
  state the later native `wait`/exit check unambiguously in prose and in the
  example command sequence (`wait "$COPILOT_PID"` immediately follows
  `wait-copilot`). That said, nothing in code or tests enforces that a driver
  actually performs this step — it is convention, not a mechanical gate, same
  as every other advisory signal in this protocol.

**Inferences:**
- Driver evidence never states whether import/receipt verification ran
  before or after the native process's observed exit at 146.586s ("Import and
  independent receipt verification passed" has no timestamp). Given the
  runbook is unambiguous about ordering, I infer compliance is likely but the
  evidence text does not itself demonstrate it — this is an evidence
  completeness gap, not a runbook clarity gap.
- "Reduces orchestration turnaround without reducing model inference time" is
  accurate only if "turnaround" means driver interaction/context-turn count
  (2–4 manual `status` calls collapsed to one `wait-copilot` call), which is
  what the surrounding sentence actually supports. Total wall-clock time to
  completion is not reduced — it remains bounded by the 146.586s native
  process either way — so the driver's own claim is correctly scoped, but the
  word "turnaround" alone is ambiguous enough to be misread as a wall-clock
  claim.

**Residuals:**
- Could not independently confirm the real 131.745s/146.586s figures (this
  stage has no access to the driver-only native log or wait output); this
  critique is limited to internal consistency of the reported numbers, not an
  independent re-measurement.

## Critique

The core safety and code claims in `driver-evidence.md` hold up against
source: `ready` is purely a byte-freshness observation, is documented as
advisory/non-authorizing on every field, and legitimately precedes native
exit by design — this is safe under the documented contract because import
remains gated separately by `import-copilot`, not by `wait-copilot`. The
runbook (protocol.md's template plus plan.md's risk section) states the
required later native wait/exit check unambiguously in text; the gap is that
driver-evidence.md doesn't itself show timestamped compliance with it.

The timing arithmetic is the one concrete defect: the "roughly 6.3 seconds"
and "about 7.3 seconds" figures in the same paragraph describe what reads as
the same ready-to-exit gap but are mutually inconsistent given the reported
131.745s/146.586s elapsed values and no recorded start-time offset between
the two invocations. This is a documentation/evidence-quality defect, not a
`wait-copilot` code defect — the underlying mechanism (advisory ready file
observation, separate native-exit gate) is correctly designed and correctly
described in prose elsewhere in the same file.

Both proposed extra tests add non-duplicate coverage. R9's existing
process-loss exercise uses PID `2147483647`, a value that is never reachable
from the first poll — it never exercises a real `reachable`→`not-reachable`
transition, so a live-subprocess variant closes a real gap rather than
duplicating R9. `test-focused-runner.sh` has no filesystem assertion against
`__pycache__` anywhere; it only checks `default_jobs()` behavior under
`PYTHONDONTWRITEBYTECODE=1`, so a direct absence check is a distinct,
non-duplicate regression guard against a Python-version-dependent behavioral
assumption.

## Proposed plan changes

No target/code change is warranted for `wait_copilot` or
`status_snapshot` — no reproducible defect found there. Recommend one small,
concrete doc/evidence fix and accept both previously-proposed tests as
optional additions (not required by any established gap):

1. Doc/evidence fix (smallest exact change): in `driver-evidence.md`,
   reconcile or remove one of the two inconsistent deltas ("roughly 6.3
   seconds" vs "about 7.3 seconds") for the ready-to-native-exit gap, and
   record the actual start-time offset (or a single unambiguous gap computed
   from a common origin) between the native invocation and the
   `wait-copilot` invocation so the timing claim is independently verifiable
   from the evidence text alone. Optionally also add one sentence stating
   explicitly that import/receipt verification followed the observed native
   exit, closing the ordering-evidence gap noted above.
2. Accept test 1 (real subprocess PID transitioning reachable→not-reachable
   in a `wait-copilot` regression) as it exercises a case R9's fixed-invalid-
   PID exercise does not cover.
3. Accept test 2 (assert no `tools/__pycache__` after
   `test-focused-runner.sh` runs) as a direct filesystem check the existing
   behavioral test does not provide.

Neither test is required to close a currently-demonstrated defect; both are
offered for reconciliation to accept or defer.
