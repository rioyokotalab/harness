# Reconciliation

## Evidence accepted

1. **Status freshness / `mechanical_import_preconditions` (conflict 1).**
   Accepted, with the reciprocal Codex stage's exact shape. Add an advisory
   status object `stage.mechanical_import_preconditions` containing
   `candidate_structurally_ready`, `inputs_fresh`, `destination_fresh`, their
   conjunction as `all_satisfied`, `advisory: true`, and
   `authorization: "none"`. It must never be named or treated as
   `import_ready`; `import-copilot` remains the sole authoritative mechanical
   gate (schema/role/receipt-order/prompt/seal/input/destination/candidate
   checks). The object only summarizes the three existing byte/freshness
   observations already exposed as sibling fields — it adds no new
   information, only a conjunction, closing the "read `candidate_state` alone"
   risk the driver's synthetic test surfaced.

2. **Monitoring ownership.** Accepted verbatim, both passes agree: the driver,
   which alone holds the live-session and external-seal paths, runs full
   `status` during and after the native co-pilot window; the blinded co-pilot
   can only report stage-local observations (it cannot reach the live session
   path or authenticate the external seal by design). Neither
   `candidate_state` nor PID reachability authorizes import. This is not an
   asymmetry bug — it is the intended confinement model — and the runbook
   wording is frozen as: "The driver, which retains the live-session and
   external-seal paths, runs `status` during and after the native co-pilot
   window. The blinded co-pilot reports only stage-local observations. Neither
   candidate state nor PID reachability authorizes import."

3. **Log-dir ergonomics (conflict 5).** Accepted the reciprocal proposal over
   the driver's two open alternatives: keep the non-existent-directory
   refusal (do not switch to idempotent `exist_ok=True`, which would risk
   mixing old and new logs and weakening log attribution), but catch
   `FileExistsError` around the existing `mkdir(..., exist_ok=False)` and
   return a concise diagnostic and exit 2 instead of an uncaught traceback.
   Add a focused-runner regression that re-invokes the runner against an
   already-populated `pass-logs` directory and asserts exit 2, the exact
   `focused-tests: --log-dir already exists: PATH` message, no `Traceback` in
   output, and that no suite executes during that invocation.

4. **Worker default / concurrency (conflict 3).** Accepted the reciprocal
   critique over the driver's own framing. Both the driver's four dirty-tree
   samples and the independent stage's six workspace-confined samples point
   toward jobs=8 being faster in raw wall time, but every sample in both sets
   ran against a failing suite set (the driver's dirty `test-tmux-config.sh`
   failure in all four runs; the independent stage's seven failing suites with
   an overlapping jobs-4/jobs-8 pair). A failed/contaminated run can alter
   scheduling and the critical path, so neither dataset is acceptance
   evidence, even though the raw direction is diagnostically consistent.
   `HARNESS_TEST_JOBS=4` is retained as the frozen default. No further worker
   benchmark runs in this round; a later, separately bounded task must first
   get an environment where every focused suite passes, then take at least
   three strictly sequential alternating samples per arm under matched
   host/confinement conditions before any default change.

5. **CI coverage (conflict 4).** Accepted, narrowed. Both passes independently
   re-traced current source and agree on the present topology: the workflow
   runs capability recording, `tests/test-affinity-readiness.sh`, and
   `tests/test-phase1.sh`; `test-affinity-readiness.sh` is not present in
   `tests/focused-suites.tsv`, so it is not duplicated; `test-phase1.sh`
   invokes the focused manifest once and retains the conditional ShellCheck
   warning/error gate, so no lint coverage was dropped. This is accepted only
   as a proven *current-state* mapping, not as historical proof that every
   step removed in round 1 maps exactly once — that stronger claim would need
   the round-1 removal diff, which neither pass produced, so it stays
   unsupported and is not asserted.

6. **Stage-parent seal rule (conflict 2).** Accepted unchanged: keep the
   existing rule that `stage --seal` refuses a path under the stage's parent
   directory, and keep the charter/skill/protocol requirement that every
   stage be a direct child of the declared co-pilot sandbox with every prompt
   and external seal kept outside that entire sandbox tree. The reciprocal
   critique correctly notes the path check only establishes this boundary
   under the direct-child precondition and does not itself prove general
   same-UID confinement — the driver must still choose an actually-withheld
   external location. No code change; a co-pilot-root parameter is deferred
   until nested stages become a real requirement.

## Disagreements and uncertainty

- **Confinement equivalence rejected.** The driver's evidence did not claim
  Claude/Codex sandbox equivalence, but the reciprocal critique flags this as
  a risk worth freezing explicitly: Codex `workspace-write` enforces a
  smaller writable-root boundary at the OS/CLI level, while Claude tool
  permissions are behavioral only, without an added platform sandbox. This
  reconciliation records that **workspace-write limits writes, not reads**,
  and that no claim of equivalent Claude/Codex confinement is made anywhere
  in this session's frozen plan or runbook wording.

- **Scope contamination in the reciprocal stage.** The reciprocal
  `copilot-evidence.md` lists reading, from its own working tree rather than
  only the sealed stage bundle, `shared/skills/codex-claude-cowork/scripts/
  cowork-session`, `SKILL.md`, `references/protocol.md`,
  `tools/run-focused-tests.py`, `tests/test-focused-runner.sh`,
  `tests/test-codex-claude-cowork-skill.sh`, `tests/test-phase1.sh`,
  `tests/focused-suites.tsv`, and `.github/workflows/ci.yml` — i.e. the live
  skill checkout, not the blinded stage-local copy the protocol intends the
  co-pilot to reason from. The supervisor independently confirmed this same
  observation. This reconciliation therefore **rejects the reciprocal
  evidence's strict read-blind claim**: the co-pilot's read scope was not
  confined to the sealed stage as the protocol prompt directed. It is
  simultaneously true, and accepted, that this contamination did not access
  the live session directory or mutate any live file — the digest/seal
  evidence (matching `raw_state_sha256`, `destination_before_sha256`, and
  `stage_manifest_sha256` across both receipts) shows no unauthorized write
  occurred. Consequence for this reconciliation: reciprocal-stage
  recommendations are accepted only where they are independently
  corroborated by the driver's own sandboxed evidence, supported by bytes
  actually present in the sealed stage bundle, or self-evidently reproducible
  from source (e.g. quoting exact line content). No reciprocal claim is
  accepted solely on the strength of the co-pilot having read the live
  checkout outside its intended blind. Every item accepted above (1, 2, 3, 5,
  6) meets this bar because it is either corroborated by the driver's own
  synthetic evidence, or is a direct, independently-checkable read of current
  source that this reconciliation does not extend into an unsupported
  historical claim (see item 5).

- **Timing samples remain individually inconclusive.** Focused-cowork-suite
  wall times across passes (9.967s, 10.12s, 11.55s, 12.099s) are unmatched
  single samples on a shared host; this reconciliation treats them only as
  "no gross regression observed," not as evidence of performance equivalence,
  per the reciprocal critique's correction of the driver's looser "expected
  variance" framing.

## Frozen plan

Execution (Claude-only, disposable sandbox `/tmp/harness-t284-r2-claude`
only) implements exactly:

1. `shared/skills/codex-claude-cowork/scripts/cowork-session`: add
   `stage.mechanical_import_preconditions` to `status` output, computed from
   the existing `candidate_state`/`inputs_fresh`/`destination_fresh`
   observations only (`candidate_structurally_ready` = true iff
   `candidate_state == "ready"`), with `advisory: true` and
   `authorization: "none"`; never emit an `import_ready` key. No change to
   `import-copilot`'s authoritative gating logic.
2. `SKILL.md` / `references/protocol.md`: document the new advisory object
   next to the `status` example, state explicitly what it does and does not
   cover (candidate/freshness bytes only — not seal validation, stage
   mode/receipt sequencing, process exit, protected digests, semantic review,
   or `import-copilot`/`verify-receipts` success), and freeze the monitoring
   wording from item 2 above. Document the stage-parent seal-placement
   boundary (item 6) as a "must be outside the entire stage-parent sandbox,
   not just the stage" clarification. State plainly that `workspace-write`
   limits writes, not reads, and make no Claude/Codex confinement-equivalence
   claim anywhere in this text.
3. `tests/test-codex-claude-cowork-skill.sh` (focused cowork test): add a
   case that stages a structurally-ready candidate, then mutates a staged
   live input, and asserts `candidate_state=ready`, `inputs_fresh=false`,
   `mechanical_import_preconditions.candidate_structurally_ready=true`,
   `.inputs_fresh=false`, `.all_satisfied=false`, `.advisory=true`,
   `.authorization=none`; restore the fixture before continuing existing
   import assertions; extend the post-import assertion so
   `destination_fresh=false` also yields `all_satisfied=false`.
4. `tools/run-focused-tests.py`: catch `FileExistsError` around the existing
   `log_dir.mkdir(mode=0o700, parents=False, exist_ok=False)` call, print
   `focused-tests: --log-dir already exists: PATH` to stderr, and return exit
   status 2; keep refusing reuse (no `exist_ok=True`, no idempotent merge).
5. `tests/test-focused-runner.sh`: add a regression that re-invokes the
   runner against an already-populated `pass-logs` directory and asserts
   exit 2, the exact diagnostic text above, absence of `Traceback` in
   output, and that no suite executed during that invocation.

`HARNESS_TEST_JOBS=4` is retained unmodified; this execution performs no
worker-count change and no further concurrency benchmarking. The CI workflow
topology and the direct-child stage/seal rule are unmodified.

## Acceptance gates

Run from the clean, committed disposable target `/tmp/harness-t284-r2-claude`
after the five changes above, all must pass before advancing past
`validating`:

1. Focused cowork suite: `bash tests/test-codex-claude-cowork-skill.sh`.
2. Focused runner suite: `bash tests/test-focused-runner.sh`.
3. Skill/public/source/quick/takeover checks via
   `shared/skills/codex-claude-cowork/scripts/cowork-session check` across
   this session's phases as applicable.
4. `git diff --check` (no whitespace-conflict artifacts).
5. `shared/skills/codex-claude-cowork/scripts/cowork-session verify-receipts
   docs/audits/t284-cowork-round2`.
6. Full `tests/test-phase1.sh` from the clean committed tree.

No target file outside the five files named in the frozen plan is modified.
Any new material choice discovered during execution returns the session to
owner review rather than being carried forward under this go.
