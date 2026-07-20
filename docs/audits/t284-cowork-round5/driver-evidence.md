# Driver evidence

## Sandbox and baseline

Clean driver clone `/tmp/harness-t284-r5.X6y0SH/codex` at `f3114a8` remained
unchanged. The probe loaded the real helper with
`PYTHONDONTWRITEBYTECODE=1`; no target or scratch source file was written.

## Commands and results

Monkeypatched `time.monotonic` to yield 0.0 at start then 1.1 after a mocked
fully ready snapshot, with `timeout_seconds=1.0`, `poll_seconds=1.0`, and no
PID. Current `wait_copilot` returned exit 0, outcome `ready`, and
`elapsed_seconds=1.1`. This deterministically demonstrates that readiness is
currently evaluated before deadline exhaustion.

## Critique

The result violates the ordinary meaning of the explicit maximum wait budget.
A synchronous snapshot cannot be interrupted, but once it completes after the
deadline its facts are late and timeout should win. Equality should also be
timeout (`observed_at >= deadline`) for a crisp upper bound. The same rule
should apply to the immediate post-process-loss final snapshot.

## Proposed plan changes

Capture one `observed_at = time.monotonic()` immediately after every ordinary
snapshot and final process-loss snapshot. Check `observed_at >= deadline` before
ready/not-importable classification. Retain the final snapshot in timeout JSON.
Add a no-sleep fake-clock regression proving a late ready snapshot returns
timeout/4; preserve existing real ready/process-loss/timeout tests. Ask Claude
to challenge whether initial ready deserves an exception and whether final
process-loss reads should have grace beyond the deadline.
