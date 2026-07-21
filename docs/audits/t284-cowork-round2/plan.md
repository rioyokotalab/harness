# Initial plan

## Confirmed facts and assumptions

Confirmed (from round-1 reconciliation and this checkout's source): `stage`
accepts optional `--prompt FILE`, copies it to fixed
`artifacts/copilot-prompt.md`, records `prompt_sha256` in `stage.json`, and the
external seal commits that hash; import rechecks the copied bytes before
mutation. Schema-2 stages (no prompt) remain readable. `status SESSION
[--stage --seal] [--pid]` is read-only, reports phase, receipts, candidate
state (`empty`/`unchanged`/`invalid`/`ready`), stage/input/prompt/seal
freshness, and advisory PID reachability, and never writes. CI's standalone
ShellCheck step and five suites duplicated inside `test-phase1.sh` were
removed; the four-worker default was retained pending a matched reverse-round
sample. Assumptions to falsify in this pass: (a) these interfaces behave
identically when Claude is driver rather than co-pilot/subject, i.e. no
Codex-specific behavior was baked in; (b) `status` cannot be made to report a
misleading `ready`/`unchanged` state under an adversarial or partial synthetic
candidate; (c) eight-worker concurrency is a reproducible, matched win over
four workers on this host, not a one-off sample; and (d) every CI step
removed in round 1 is still exercised at least once by `test-phase1.sh` (no
silent coverage loss).

## Steps

Steps 1–6 (driver-only, discussing-phase evidence) are complete and frozen;
their outputs are preserved in `driver-evidence.md` and summarized in the
charter's Acceptance section. They are kept here for continuity, not
re-run:

1. Ran the focused cowork suite unmodified and recorded wall time
   (12.099s), comparable to round-1's driver (10.12s) and co-pilot (9.967s)
   baselines.
2. Constructed a synthetic prompt file and synthetic session/stage in
   `scratch-r2/` (no live Codex invocation), exercised `stage --prompt` to
   produce a schema-3 stage, and ran `status` across `unchanged`/`invalid`/
   `ready` candidate states plus a stale-input scenario — surfacing conflict
   1 (status freshness fields) and conflict 2 (stage-parent seal placement).
3. Ran `tools/run-focused-tests.py` twice at `--jobs 4` and twice at `--jobs
   8` with separate logs — surfacing conflict 3 (clean matched worker
   samples still needed; the two-sample dirty-tree comparison is not
   frozen-worthy).
4. Diffed the CI workflow step list against round-1's removed-step evidence
   and re-traced coverage in `tests/test-phase1.sh`/`tests/focused-suites.tsv`
   from source — confirming conflict 4 (CI coverage retained, no loss).
5. Critiqued round-1's `reconciliation.md` claims (symmetry, turnaround,
   prompt integrity, status honesty, schema-2 compatibility, CI
   coverage/speed) against this round's evidence, and separately noted
   conflict 5 (log-dir ergonomics: `--log-dir` must not pre-exist).
6. Wrote `driver-evidence.md` with commands, results, and five proposed plan
   changes; ran `cowork-session check --phase discussing` and stopped without
   staging, invoking Codex, reconciling, or advancing.

Remaining steps (this pass adds them to the plan; it does not execute them):

7. Prepare one bounded, driver-only prompt file per stage (independent and
   reciprocal), each outside `/tmp/harness-t284-r2-codex` and outside this
   session directory, giving Codex the charter, the frozen plan, the five
   numbered conflicts above, and the exact return headings required by
   `copilot-evidence.md`'s template.
8. Freeze a protected digest manifest of the live session
   (`cowork-session digests`) before opening the Codex client window, then
   create the independent-mode sealed stage as a direct child of
   `/tmp/harness-t284-r2-codex` via `cowork-session stage ... --mode
   independent --prompt DRIVER_PROMPT_FILE --seal EXTERNAL_SEAL_FILE`, with
   the seal path outside both `/tmp/harness-t284-r2-codex` and the session
   tree (conflict 2).
9. Invoke Codex CLI as co-pilot against only the stage directory (never the
   live session path), have it independently exercise the plan steps it can
   reach in its own sandbox, and return complete evidence — a full
   replacement of the current stub `copilot-evidence.md`, not a partial diff
   — via the stage's `candidate-copilot-evidence.md`.
10. Compare the stored `stage_sha256` and protected digest manifest, run
    `cowork-session import-copilot ... --seal EXTERNAL_SEAL_FILE`, then
    `cowork-session verify-receipts`, only proceeding when the import reports
    fresh, valid evidence and a receipt path.
11. Create a fresh `--mode reciprocal` stage (its own driver-only prompt and
    seal, same stage-parent and outside-path rules as step 8) that reveals
    both evidence files and requires Codex to test or trace the driver's
    strongest claims among the five numbered conflicts, stating for each
    which it accepts, rejects, or cannot resolve with its own evidence.
    Import and verify the reciprocal candidate the same way as step 10.
12. **Done.** Wrote `reconciliation.md`: all five numbered conflicts resolved
    (advisory `mechanical_import_preconditions` object; driver-only
    monitoring; log-dir `FileExistsError` → concise exit 2; `HARNESS_TEST_JOBS=4`
    retained with no further benchmarking this round; current CI-topology
    trace accepted narrowly, no unsupported historical claim). Recorded the
    reciprocal stage's scope contamination (it read the live skill checkout,
    not only the sealed stage bundle, per the supervisor's independent
    observation) — its strict read-blind claim is rejected, while it is
    accepted that it did not access the live session or mutate live files;
    only recommendations independently corroborated or supported by staged
    bytes are accepted. Recorded that `workspace-write` limits writes, not
    reads, with no Claude/Codex confinement-equivalence claim.
13. **Done.** Advanced to `ready-for-execution` via `cowork-session advance`;
    no unsafe or contradictory required evidence remained after
    reconciliation.
14. On an explicit owner go scoped to the frozen plan, re-read `state.json`,
    the charter, and the frozen plan from disk, revalidate baseline
    cleanliness and rollback, then advance to `executing`. Claude Code is the
    only client that may mutate a target in this session, and the only
    permitted target is the disposable sandbox `/tmp/harness-t284-r2-claude`
    — never the live production checkout. Record every step, command, result,
    and deviation in `execution.md`.
15. Advance to `validating` and run both a focused validation
    (`cowork-session check` plus the focused cowork suite) and a full
    validation (`tests/test-phase1.sh`) against the disposable target,
    recording commands and results in `validation.md`. Codex may inspect the
    final diff and challenge validation in a read-only pass but may not
    repair the target.
16. Advance to `complete` only when the validator and both acceptance gates
    pass and no required disagreement remains; checkpoint the repository
    ledger with modified files, evidence paths, remaining risks, and cleanup
    state.

## Evidence questions

Already answered by the completed driver pass: the helper's driver/co-pilot
role assignment is purely a `state.json` field with no asymmetric code path
(confirmed); a synthetic stage/candidate sequence can surface an
individually-honest-but-jointly-misreadable freshness state (confirmed —
conflict 1); two same-job-count `run-focused-tests.py` runs vary by up to
~10%, so two samples per arm is inconclusive for the four-vs-eight comparison
(confirmed — conflict 3); `test-phase1.sh` still exercises every suite the
removed CI steps used to cover, exactly once (confirmed — conflict 4).

Open for the reciprocal Codex stage and reconciliation: does Codex's
independent read of the `status` runbook text agree that `candidate_state`
alone reads as sufficient, or does it find the existing documentation already
adequate? Does Codex's own sealed stage exercise reproduce the stage-parent
seal-placement refusal (conflict 2) identically from its sandbox? Can Codex
obtain a clean-checkout matched worker-count sample (conflict 3) from its own
sandbox, and does it agree on the resulting four-vs-eight direction? Does
Codex have a safer/simpler alternative for `--log-dir` ergonomics (conflict
5) than either "document it" or "make it idempotent"? Are there safer/simpler
alternatives to schema-3 prompt binding or the status surface that neither
round has considered?

## Risks and recovery

Synthetic session/stage/candidate construction in `scratch-r2/` must not reuse
or write into the real session directory (`docs/audits/t284-cowork-round2/`
itself) so driver-owned files stay clean; synthetic sessions stay under
`scratch-r2/synthetic-session/` and are retained, not deleted. `
run-focused-tests.py` at `--jobs 8` may contend for shared host resources with
other repository state; if a run fails or times out, record it as evidence
rather than retrying silently, and prefer the matched four-worker default
until a clean reproducible eight-worker advantage exists (conflict 3). Any
CLI error, missing subcommand, or validator failure is evidence, not a
blocker to route around. For the independent and reciprocal stages: keep
every stage a direct child of `/tmp/harness-t284-r2-codex` so the stage-parent
seal-placement rule (conflict 2) is satisfied by construction; keep every
driver-only prompt and external seal file outside `/tmp/harness-t284-r2-codex`
and outside this session directory; never grant Codex the live session path;
and treat a Codex tool error, permission denial, or timeout as evidence, not
as permission to weaken sealing or import checks. Execution and validation
touch only the disposable sandbox `/tmp/harness-t284-r2-claude`; the live
production checkout stays out of scope for every phase, including execution.
If a later material choice arises during execution, return the session to
owner review rather than treating sandbox-stage authority as carrying
forward. Retain all `scratch-r2/` logs and any synthetic/independent/
reciprocal session, stage, and seal files for later guarded cleanup; do not
delete them in this pass.
