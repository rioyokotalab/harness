# Driver evidence

## Sandbox and baseline

I worked from clean no-hardlink clone `/tmp/harness-t284-r3.IqKFA8/codex` at
`a9dd994189cfba44777ac3d637d68ae6de72f9e0`. `git status --short` was empty
before and after measurement. Raw stdout, stderr, `/usr/bin/time` records, and
fresh per-sample suite logs are retained under
`/tmp/harness-t284-r3.IqKFA8/driver`; none is inside the clone or live session.

## Commands and results

I invoked `python3 tools/run-focused-tests.py --root . --manifest
tests/focused-suites.tsv --log-dir FRESH_DIR --jobs N` six times, strictly
sequentially in the frozen order 4, 8, 8, 4, 4, 8. Each run emitted 57 PASS
records, zero FAIL records, and exit 0. `/usr/bin/time` results were:

| sample | jobs | elapsed s | user s | sys s | max RSS KiB |
| --- | ---: | ---: | ---: | ---: | ---: |
| 1 | 4 | 29.82 | 46.33 | 56.87 | 294912 |
| 2 | 8 | 25.35 | 47.90 | 59.47 | 294692 |
| 3 | 8 | 25.39 | 48.25 | 59.26 | 294636 |
| 4 | 4 | 29.67 | 46.06 | 57.18 | 294196 |
| 5 | 4 | 29.69 | 46.23 | 56.61 | 294360 |
| 6 | 8 | 25.25 | 48.06 | 59.32 | 294376 |

The four-worker median is 29.69 seconds (range 0.15); the eight-worker median
is 25.35 seconds (range 0.14), a 14.62% median reduction. Peak memory is
effectively unchanged and CPU time rises slightly. This is a clean, balanced,
passing host-local result; it is not a universal hardware claim.

I also traced `status`: it builds and prints one snapshot directly, so a driver
must issue repeated client/tool calls while a native co-pilot runs. Round 1 and
round 2 required many such polls. The smallest prototype is a new read-only
`wait-copilot` command sharing the exact status snapshot builder. It polls on a
monotonic clock and emits one final JSON object plus a top-level
`wait_observation` object. Candidate structure plus both freshness facts may
produce `candidate-observed`; invalid/stale candidate, observed process loss,
and timeout remain distinct observations. Every outcome must say
`advisory: true` and `authorization: "none"`; no outcome calls or bypasses
`import-copilot`.

## Critique

The worker result is unusually stable and materially larger than within-arm
variance, so it supports changing this repository's local/CI default to eight
while retaining `HARNESS_TEST_JOBS` override and the 1–16 validator. It does not
support changing client machines with tighter CPU quotas, and CI acceptance
must include a clean full phase-one run at the new default.

The wait design can reduce orchestration round trips, but its semantics are
more consequential than its code size. PID reachability is advisory, vulnerable
to PID reuse, and wrapper PIDs may not represent the client. It should be
optional; without `--pid`, candidate/timeout are the only terminal observations.
With `--pid`, the command may stop on `not-reachable` only after re-reading the
stage once, and must label that fact rather than infer success or failure.
Candidate readiness alone is also insufficient: stale inputs or destination
must never receive the same outcome as the full three-fact conjunction.

## Proposed plan changes

1. Change `tests/test-phase1.sh`'s two default expansions from four to eight;
   retain explicit overrides and `legacy` mode.
2. Refactor `status` into a pure snapshot builder plus its current JSON printer.
3. Add `wait-copilot SESSION --stage STAGE --seal SEAL [--pid PID]
   --timeout-seconds N [--poll-seconds N]`. Require a stage and bounded positive
   timeout/poll interval. Emit only the final status JSON augmented with
   `wait_observation={outcome, elapsed_seconds, advisory:true,
   authorization:"none"}`.
4. Proposed terminal outcomes: `candidate-observed` only when the existing
   three mechanical observations are all satisfied; `candidate-not-importable`
   for invalid structure or stale input/destination; `process-not-reachable`
   when an optional PID becomes unreachable with no candidate; and `timeout`.
   Use distinct documented exit codes and never call import.
5. Add focused tests with short intervals for ready, stale, invalid,
   process-not-reachable, and timeout cases, plus argument bounds and a
   source-level assertion that wait never calls import.
6. Update SKILL/protocol native mappings so the driver can start one bounded
   wait instead of repeatedly polling; keep one-shot `status` for inspection.
7. Require Claude's independent and reciprocal critique before freezing exact
   wait outcomes or exit codes. Validate the worker change with full phase one.
