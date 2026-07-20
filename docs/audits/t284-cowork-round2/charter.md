# Charter

## Task

Round 2 of T-284: Claude Code drives, Codex CLI is the blinded co-pilot, to
challenge the round-1 (Codex-driver) candidate implemented on this branch,
across the full cowork workflow rather than stopping at driver-only evidence.
The frozen driver pass already tested the accepted `stage --prompt`, schema-3
prompt binding, read-only `status` surface, and the CI duplicate-step removal
for symmetry, turnaround, prompt integrity, status honesty across
process/candidate states, backward compatibility with schema-2 stages, and CI
coverage, and it surfaced concrete unresolved conflicts (see Acceptance). This
charter now also covers the remaining phases: sealed independent and
reciprocal Codex stages against the driver evidence, a complete evidence
replacement in `copilot-evidence.md` (the co-pilot's real returned bytes, not
a synthetic stand-in), reciprocal critique of the driver's strongest claims,
a frozen `reconciliation.md`/plan, and — only after an explicit owner go on
that frozen plan — Claude-only execution and validation against the
disposable target below. Do not implement target code, stage, or invoke
Codex in the current pass; this update only extends the charter/plan and
re-validates the `discussing` phase.

## Boundaries

Claude Code is the driver; Codex CLI is the co-pilot. Only the driver may
mutate a target, and only after a frozen `ready-for-execution` plan and an
explicit owner go scoped to that plan. No access to `/home/rioyokota/harness`,
credentials, packages, services, remotes, or external systems. The live
production checkout (the harness `main`-tracked repository outside this
sandbox) remains permanently out of scope for every phase of this session,
including execution — execution in this workflow targets only the disposable
sandbox declared below, never the production checkout. Sealed stages for both
the independent and reciprocal rounds must be direct children of the Codex
sandbox `/tmp/harness-t284-r2-codex` (so that sandbox is the true stage
parent), and each stage's driver-only prompt file and external seal file must
live outside `/tmp/harness-t284-r2-codex` (and outside this session directory
and its stage-parent tree), per the stage-parent seal-placement conflict
recorded in `driver-evidence.md`. The current pass performs no staging, no
Codex invocation, no reconciliation, and no advance past `discussing`; it
stops after `cowork-session check --phase discussing`. Exchange artifacts stay
bounded and public-safe; raw logs live in `scratch-r2/` inside this sandbox
for later guarded cleanup.

## Baseline and sandboxes

Immutable Git baseline for this sandbox:
`ca875387c232e0da51fdf602a5aa21369720965f` (branch
`task/t-284-cowork-speed`, detached, clean at session start except this new
`docs/audits/t284-cowork-round2/` directory). This checkout at
`/tmp/harness-t284-r2-claude` is the driver sandbox for round 2 and is also
the disposable execution target for the eventual Claude-only execution phase
— never the live production checkout. The counterpart Codex sandbox is
declared at `/tmp/harness-t284-r2-codex`, built from the same named baseline
commit, and is the required stage-parent for every independent and reciprocal
sealed stage in this session; it is out of scope for direct edits by the
driver except to create stage directories under it via `cowork-session
stage`. Driver-only prompt files and external seal files for both stages are
kept outside `/tmp/harness-t284-r2-codex`, e.g. under
`/tmp/t284-r2-external-seal/` and a driver-only prompts directory, consistent
with the seal-placement conflict already found. All experiment output stays
under
`/tmp/harness-t284-r2-claude/docs/audits/t284-cowork-round2/scratch-r2/`.

## Acceptance

Charter and plan must pass `cowork-session check --phase planning`, then the
session advances to `discussing`. The completed driver pass in
`driver-evidence.md` stands as-is (preserved, not overwritten) and reports
exact commands, elapsed times, and observed output for the focused cowork
suite, a synthetic `stage --prompt`/`status` sequence, and matched
`tools/run-focused-tests.py --jobs 4`/`--jobs 8` runs. It surfaced five
concrete conflicts that the reciprocal Codex stage and reconciliation must
resolve before any `ready-for-execution` advance:

1. **Status freshness fields must be consumed together** — `status`'s
   `candidate_state`, `inputs_fresh`, and `destination_fresh` are each
   individually honest, but a caller reading `candidate_state: ready` alone
   can import a candidate staged against live inputs the driver has since
   changed; the runbook and any import gate must treat all three fields as
   jointly required, not `candidate_state` alone.
2. **Stage-parent seal placement** — `stage --seal` correctly refuses a seal
   path under the stage's parent directory, not just under the stage itself;
   this session's stage-parent (`/tmp/harness-t284-r2-codex`) and seal
   locations must be declared consistent with that boundary before staging.
3. **Clean matched worker samples** — the two-sample-per-arm `--jobs 4` vs
   `--jobs 8` comparison ran on a dirty tree (confounded by
   `test-tmux-config.sh`) and is not yet frozen-worthy; any worker-count
   default change requires a clean-checkout, 3–4-sample-per-arm rerun.
4. **CI coverage** — confirmed no coverage loss from the round-1 CI-step
   removal (ShellCheck and duplicate suites remain covered exactly once in
   `tests/test-phase1.sh`/the manifest); this stands unless the reciprocal
   pass finds a contradiction.
5. **Log-dir ergonomics** — `tools/run-focused-tests.py --log-dir` requires a
   non-existent directory and exits with a traceback if pre-created; this is
   an open documentation/ergonomics question for reconciliation, not yet a
   proposed code change.

The reciprocal Codex stage must independently test or trace the driver's
strongest claims among these five, accept/reject/mark-unresolved each with
its own evidence, and `reconciliation.md` must record the outcome before any
advance to `ready-for-execution`. Execution (when later authorized by an
explicit owner go on the frozen plan) is Claude-only, targets solely the
disposable sandbox `/tmp/harness-t284-r2-claude`, and must be followed by both
a focused validation (`cowork-session check` plus the focused cowork suite)
and a full validation (`tests/test-phase1.sh`) recorded in `validation.md`.
This pass stops after `cowork-session check --phase discussing` passes; no
target file outside `docs/audits/t284-cowork-round2/` is modified, no stage is
created, and no Codex process is invoked.
