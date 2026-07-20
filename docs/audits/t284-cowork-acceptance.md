# T-284 acceptance index

## Scope and baseline

The owner requested a three-hour refinement of the published
`codex-claude-cowork` skill for faster turnaround, higher-quality file exchange,
better co-pilot monitoring, and faster local/protected checks. Work ran on
`task/t-284-cowork-speed` from clean fetched `origin/main`
`f7d5bf0d403bdc07079bb4c5e420a2aa9fbb4a02`. No client settings, credentials,
packages, services, remotes, deployments, or external messages changed.

Six complete staged cowork sessions preserve exact plans, independent and
reciprocal evidence, reconciliation, execution, validation, and receipts:

- `t284-cowork-round1`: Codex drove Claude; prompt binding, status, and CI
  de-duplication.
- `t284-cowork-round2`: Claude drove Codex; advisory precondition grouping,
  driver-owned monitoring, and fast focused-log refusal.
- `t284-cowork-round3`: Codex drove Claude; adaptive test workers and bounded
  `wait-copilot`.
- `t284-cowork-round4`: real native-client waiter dogfood and live process-loss
  coverage.
- `t284-cowork-round5`: deadline-precedence reproduction and correction.
- `t284-cowork-round6`: non-finite waiter-argument reproduction and fail-fast
  correction.

All six sessions are `complete`, validate from Git, and have valid independent
and reciprocal receipt chains.

## Accepted behavior

Information exchange now binds the exact bounded prompt at
`artifacts/copilot-prompt.md` into stage schema 3, the external seal, and import
receipt; existing schema-2 stages remain readable. New session ledgers retain
`artifacts/.gitkeep`, so required empty structure survives Git clone/takeover.

Monitoring now provides:

- a deterministic read-only `status` snapshot with roles, phase, receipts,
  next action, stage/prompt/seal hashes, candidate state/bytes, freshness, and
  advisory PID reachability;
- an explicitly non-authorizing `mechanical_import_preconditions` conjunction,
  preventing consumers from reading attractive `candidate_state=ready` alone;
- a monotonic bounded `wait-copilot` that prints one final JSON object and
  returns `ready`/0, process-loss-final `not-importable`/2, or `timeout`/4;
- fail-fast finite-number validation for timeout and poll arguments, so NaN
  cannot create an unbounded wait or an unhandled sleep error;
- tolerance for transient editor writes, one final read after observed process
  loss, unauthenticated/advisory PID labels, and deadline precedence at every
  completed snapshot; and
- a symmetric rule that the driver, not the blinded co-pilot, owns full live
  monitoring, native exit inspection, protected seals, import, and receipts.

Codex workspace-write is documented as a write boundary rather than a read
confidentiality boundary; no Claude/Codex confinement-equivalence claim remains.

Checking now refuses an existing focused-log directory with concise exit 2
instead of a traceback. The unset focused worker count is affinity-aware: eight
at eight or more visible CPUs, four below, while explicit numeric and `legacy`
overrides remain. CI retains capability output, standalone affinity readiness,
and the complete phase-one gate but removes a standalone ShellCheck run and five
named suites already covered inside phase one.

## Evidence and timing

- Original focused cowork: 10.12 seconds; current expanded focused cowork:
  16.66 seconds (additional real wait/deadline coverage, not a like-for-like
  speed comparison).
- Six clean sequential focused-runner samples: jobs 4 =
  29.82/29.67/29.69 seconds; jobs 8 = 25.35/25.39/25.25 seconds. Median
  reduction: 14.62%, with all 57 suites passing and non-overlapping arms.
- Original clean full phase one: 88.18 seconds. Final clean auto-selected-eight
  phase one: 77.18 seconds, all 57 focused suites plus umbrella checks passing.
  Shared-host/non-focused-tail variance limits the whole-suite speed claim.
- A final real `taskset -c 0-3` acceptance run resolved auto to four visible
  CPUs, passed the same 57 suites and umbrella checks, and took 77.22 seconds.
  This validates the production fallback path and shows that the non-focused
  tail dominates the current whole-suite wall time.
- An explicit `HARNESS_TEST_JOBS=legacy` clean compatibility run passed the
  sequential path and umbrella gate in 149.69 seconds. Auto-eight's 77.18
  seconds is 48.44% lower wall time than legacy on this host; legacy remains an
  available override, not a default candidate.
- Historical protected PR job: 138 seconds with 37 seconds attributable to
  standalone ShellCheck and five duplicated named suites. The duplicate steps
  are removed; a new protected run has not yet measured the resulting CI time.
- Two real wait dogfood windows returned fresh ready observations 6.280 and
  7.683 seconds before the native Claude wrappers exited, replacing repeated
  manual status calls while keeping native exit as a separate gate.

## Final validation and residuals

Final clean `tests/test-phase1.sh` passed in 77.18 seconds with
`jobs=8 visible_cpus=8 mode=auto`. Focused cowork, focused runner, Claude
takeover, source contract, public audit, skill quick validation, Python AST,
shell syntax, CI YAML parse, `git diff --check`, fresh-clone sessions/receipts,
and Codex/Claude discovery links pass. ShellCheck reports only existing
intentional SC2016 informational diagnostics in quoted fixture text; phase one
remains authoritative and passed.
The explicit legacy and real four-CPU-fallback full gates also pass.
A final no-hardlink clone of the completed branch independently passed all 57
focused suites and the umbrella phase-one checks at auto-selected eight in
75.66 seconds, then was removed through a revalidated guarded-delete manifest.

The timeout classifies each completed snapshot but cannot preempt a blocked
synchronous filesystem read. PID identity remains unauthenticated and vulnerable
to reuse. Adaptive speed evidence is specific to an eight-CPU visible affinity;
a real four-CPU constrained run validates fallback correctness but is not a
second physical-host speed study. Protected CI wall time remains unmeasured
until publication. The branch remains local and has not been pushed.

All recorded T-284 clone, stage, seal, log, and handoff trees were removed with
tokenized guarded-delete manifests; exact scalar `/tmp` files and manifests were
unlinked afterward. Protected anchors were verified unchanged, and no T-284
temporary path remains.
