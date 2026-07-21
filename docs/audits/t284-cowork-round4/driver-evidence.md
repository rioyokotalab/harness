# Driver evidence

## Sandbox and baseline

Before the client window, both clones are clean at `267560c`; predecessor round
3 is complete and receipt-valid. This round's independent stage and seal are
created only after planning advances to discussing. Exact runtime observations
will be appended after the real waiter returns.

## Commands and results

Pre-window source trace confirmed `wait-copilot` calls `status_snapshot`, uses
`time.monotonic`, has no import/write call, and prints once after its loop.
`tools/run-focused-tests.py` resolves affinity before creating logs and prints
the selected auto count once; its unit import now disables bytecode. Native and
wait commands were then started separately against the sealed independent
stage. Native Claude was `timeout 180s claude -p --model sonnet --effort medium
--permission-mode bypassPermissions --no-session-persistence --allowedTools
Read,Edit,Bash` with sealed prompt stdin and driver-only stdout/stderr. Its
wrapper PID was 1091851. Exactly one `wait-copilot` call used that PID, stage,
seal, `--timeout-seconds 180`, and one-second polls; no manual status ran during
the window.

The waiter returned exit 0 after 131.745 seconds and wrote exactly one 1295-byte
JSON document. It reported `outcome=ready`, all three mechanical observations
true, candidate 7378 bytes at SHA-256
`16956a188ffa430b95f88fa2b33ffc22c63b7e609ffa87e34b5b6800c75f8729`,
`process.state=reachable`, `process_loss_observed=false`,
`pid_identity_authenticated=false`, `advisory=true`, and
`authorization=none`. The native command subsequently exited 0 after about
146.586 seconds, with empty stderr. The wait invocation began 8.508 seconds
after the native invocation; its shell wall interval was 131.798 seconds (the
JSON rounded its internal interval to 131.745). On the common nanosecond clock,
the waiter ended 6.280 seconds before native exit. The driver observed native
exit 0 before comparing seals/digests or importing and verifying the receipt.

Protected digests, `stage.json`, and external seal matched their pre-window
hashes. Import and independent receipt verification passed.

The reciprocal window repeated the same one-wait path with no manual status.
Its waiter began 7.575 seconds after native start, returned `ready`/0 after
103.768 internal seconds (103.831 shell wall seconds), and ended 7.683 seconds
before the native command exited 0 at 119.089 seconds. It reported a fresh
8013-byte candidate, reachable/unauthed PID, and the same advisory/no-authority
labels. Native stderr was empty. The driver again observed native exit before
digest/stage/seal comparison, import, and reciprocal receipt verification; all
passed unchanged.

## Critique

Dogfooding confirms the expected timing: a valid candidate becomes observable
while the wrapper remains reachable and before native stdout closes. Returning
ready immediately is safe as an observation and avoids needless polling, but
the driver still had to await the separate native exit before import. The one
JSON document parsed directly and preserved the distinct exit status.

The client took about 146.6 seconds despite a compact prompt, so prompt
compactness is not itself a reliable latency predictor. Compared with earlier
rounds, the measurable orchestration improvement is eliminating two to four
status commands/context turns, not reducing model inference time.

## Proposed plan changes

No target change is proposed. The real window confirms the current separation:
waiter readiness is an early file observation, native exit is a separate gate,
and import/receipt follow only after both plus digest/seal review. Ask the
reciprocal pass whether the runbook states this post-ready native-wait ordering
strongly enough and whether either suggested extra test adds coverage rather
than duplicate time.
