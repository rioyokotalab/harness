# Driver evidence

## Sandbox and baseline

Before the client window, both clones are clean at `267560c`; predecessor round
3 is complete and receipt-valid. This round's independent stage and seal are
created only after planning advances to discussing. Exact runtime observations
will be appended after the real waiter returns.

## Commands and results

Pre-window source trace confirms `wait-copilot` calls `status_snapshot`, uses
`time.monotonic`, has no import/write call, and prints once after its loop.
`tools/run-focused-tests.py` resolves affinity before creating logs and prints
the selected auto count once; its unit import now disables bytecode. Native and
wait commands/results are pending the planned real stage.

## Critique

The synthetic coverage is strong but cannot prove actual wrapper/candidate
timing. In particular, a ready outcome may occur before native stdout is closed;
the driver must still wait for the client process. A single JSON result is
useful only if the orchestrator can parse it and distinguish its exit status
from the native client's exit.

## Proposed plan changes

No target change is proposed before the real independent and reciprocal
windows. Preserve the round-three implementation unless dogfooding reproduces
a concrete defect; documentation-only clarity still requires reciprocal
agreement and a focused assertion.
