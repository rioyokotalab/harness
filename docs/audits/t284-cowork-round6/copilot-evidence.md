# Co-pilot evidence

## Sandbox and baseline
- `git -C target rev-parse HEAD` → `c78c45a57159785a6cdd8f03a27e0f4bdecf644f` (matches declared baseline)
- Read-only: `sed -n '1250,1300p'` on `target/shared/skills/codex-claude-cowork/scripts/cowork-session` plus `grep -n "^import"` on the same file. No target or staged-input files were modified.

## Commands and results
- Confirmed `wait_copilot` guards remain exactly `args.timeout_seconds <= 0 or args.timeout_seconds > 1800` and `args.poll_seconds < 1 or args.poll_seconds > 60` — no `math.isfinite` present, and `math` is not in the module's `import` list (only `argparse, errno, hashlib, json, os, re, stat, sys, tempfile, time`), so any fix needs `import math` added.
- Traced the loop body directly: on each iteration that reaches neither the `ready` branch nor the `process-loss` branch, it computes `remaining = deadline - observed_at` and executes `time.sleep(min(args.poll_seconds, remaining))` before re-looping.
- With `timeout_seconds = nan`: `deadline = started + nan = nan`. `remaining = nan - observed_at = nan`. `remaining <= 0` is `False` (all NaN comparisons are `False`), so the loop does not break there. `min(args.poll_seconds, remaining)` — Python's `min(a, b)` keeps `a` unless `b < a`, and `nan < poll_seconds` is `False`, so the call returns `args.poll_seconds` unchanged. The process therefore sleeps a normal, finite `poll_seconds` interval every iteration.

## Critique
Correction to my earlier (candidate) evidence: I described the loop as "tight-ish" and left the sleep behavior "not fully confirmed." That was wrong and is now confirmed wrong — the loop always calls `time.sleep(min(args.poll_seconds, remaining))` on the non-ready, non-process-loss path, and NaN propagation through `min()` degrades safely to `args.poll_seconds`. So `--timeout-seconds nan` does not spin or busy-loop; it polls `status_snapshot` once per finite `poll_seconds` interval, indefinitely, until process loss is observed (or the process is killed externally). The bug is real but its severity is "unbounded wall-clock wait despite an advertised bound," not "CPU-spinning hang." The driver's evidence text ("the loop can sleep one second indefinitely") is consistent with this corrected understanding.

Independently, `--poll-seconds nan` is a distinct, still-live defect: it passes its own range check the same way, and once inside the loop, `min(args.poll_seconds, remaining)` with `args.poll_seconds = nan` returns `nan` whenever `nan < remaining` is `False` — i.e., always — so `time.sleep(nan)` is reached. `time.sleep(float('nan'))` raises `ValueError: Invalid value NaN (not a number)` in CPython, which is an unhandled crash with a traceback, not a clean `fail()` exit. This is a second, separate reason the fix must guard `poll_seconds` too, not just `timeout_seconds`.

The proposed fix — `math.isfinite` guards on both floats before `status_snapshot`/deadline construction, plus `import math`, plus two CLI regression cases (`timeout nan`, `poll nan`) expecting `fail()`/exit 2 and no JSON — is accepted as the smallest correct fix for both defects. It is minimal, closes exactly the identified gap (NaN evading ordered-comparison bounds), and does not touch unrelated loop/branch logic. One scope note: the guard must be placed before the *existing* range checks (or combined via `or`) so that NaN is rejected by the same `fail()` call path already covered by regression tests, rather than only being caught later at `time.sleep`.

## Proposed plan changes
- Accept as written: add `if not math.isfinite(args.timeout_seconds) or args.timeout_seconds <= 0 or args.timeout_seconds > 1800: fail(...)` and the analogous `poll_seconds` guard, plus `import math` at module scope. No other behavior change.
- Narrow the acceptance-gate wording: change "timeout nan polls once per finite poll interval rather than spinning" framing to also state explicitly, in the regression test rationale, that the untreated `poll_seconds` path independently reaches an unhandled `time.sleep(nan)` `ValueError` — the plan should record both root causes (unbounded-wait for timeout-nan, crash for poll-nan) so the two added CLI regression cases are justified by distinct failure modes rather than one shared symptom.
- No rejection of any part of the proposed fix; no widening beyond the two guard lines, `import math`, and the two CLI tests.
