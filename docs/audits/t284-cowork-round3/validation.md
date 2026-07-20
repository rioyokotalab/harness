# Validation

## Checks

Pre-checks passed: focused cowork (15.75s), focused runner (0.49s), Claude
takeover, source contract, public audit, canonical skill quick validation,
Python AST, shell syntax, reciprocal receipt, and `git diff --check`.

The first committed full run selected `jobs=8 visible_cpus=8 mode=auto`; 56/57
suites passed and tmux failed because the new unit-test import created a `.pyc`
in the checkout during parallel execution. After the recorded no-bytecode fix
and clean commit, the full retry again selected eight, passed all 57 focused
suites, guarded-delete tests, and the umbrella gate; native MPI correctly
skipped outside a declared MPI environment. `/usr/bin/time` reported
`elapsed=77.09 user=85.14 sys=78.62 maxrss_kb=521388 exit=0`.

Both round-three receipts verify, the session validates at `validating`, and no
Python cache or untracked file remains.

## Outcome

Accepted. Clean matched focused measurements improved from a four-worker median
of 29.69 seconds to an eight-worker median of 25.35 seconds (14.62%) on the
eight-CPU affinity. The clean full auto run passed in 77.09 seconds versus the
round-two four-worker 80-second run and the earlier four-worker 88.18/118.16
second observations; shared-host and non-focused-tail variance prevents a
stronger whole-suite percentage claim. The affinity gate preserves four below
eight visible CPUs and all explicit overrides.

The new waiter is read-only, bounded, single-output, and exercised across ready,
partial-write, stale/process-loss, timeout, and argument-bound paths. It reduces
driver polling orchestration without upgrading advisory facts into import
authority.

## Residual risks

No protected CI run has yet measured auto mode, so CI wall-time improvement is
an inference until publication. PID reachability remains vulnerable to reuse
and wrappers; `pid_identity_authenticated=false` is deliberate. The waiter
cannot inspect semantic progress and must be followed by native process result,
candidate review, digest comparison, import, and receipt validation. The
eight-worker evidence is specific to an eight-CPU visible affinity; the four-
worker fallback on smaller affinities has deterministic unit coverage but not a
second physical-host timing sample in this round.
