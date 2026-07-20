# Driver evidence

## Sandbox and baseline

Driver sandbox `/tmp/harness-t284-r2-claude`, detached at
`ca875387c232e0da51fdf602a5aa21369720965f` on `task/t-284-cowork-speed`
(round-1's implemented candidate already on this branch). Raw logs are under
`/tmp/harness-t284-r2-claude/scratch-r2/` (outside the session directory,
since `cowork-session check` rejects any unexpected top-level session entry).
A synthetic session/stage/candidate was built at
`scratch-r2/synthetic-session` and `scratch-r2/synthetic-stage`; its external
seal is at `/tmp/t284-r2-external-seal/synthetic-seal.bin` because `stage
--seal` refused a seal path under `scratch-r2/` once that directory also
contained the stage's parent — this is a real, useful boundary check, not a
bug, and is recorded as a plan-change note below. No live Codex process was
invoked in this pass.

## Commands and results

1. `bash tests/test-codex-claude-cowork-skill.sh` — passed in 12.099s (real),
   log `scratch-r2/focused-cowork-suite.log`. Comparable to round-1's driver
   (10.12s) and co-pilot (9.967s) samples; the ~2s delta is within expected
   single-sample host variance and not evidence of regression.

2. Synthetic `stage --prompt` / `status` sequence (commands and full output in
   this evidence; `scratch-r2/synthetic-*`):
   - `cowork-session init scratch-r2/synthetic-session --driver claude` →
     `initialized ... with claude driving codex`. Role assignment is a plain
     `state.json` field (`driver: claude`, `copilot: codex`); nothing in the
     `init`/`stage`/`status` code path is Codex- or Claude-specific — **the
     helper is symmetric** for the driver/co-pilot axis, confirming round-1's
     implicit assumption rather than contradicting it.
   - `cowork-session stage ... --mode independent --prompt scratch-r2/synthetic-prompt.md --seal /tmp/t284-r2-external-seal/synthetic-seal.bin`
     → succeeded, produced a schema-3 stage with `prompt_sha256` set and
     `artifacts/copilot-prompt.md` populated from the exact prompt bytes.
   - `status` immediately after staging (untouched candidate template):
     `candidate_state: "unchanged"`, `inputs_fresh: true`,
     `destination_fresh: true`. Correct — the stub candidate file is
     unmodified.
   - After overwriting the candidate with one line of garbage (missing
     required headings): `candidate_state: "invalid"`. Correct.
   - After overwriting the candidate with a full evidence file using the
     required headings: `candidate_state: "ready"`. Correct.
   - **New finding, not covered by round-1:** after the candidate reached
     `ready`, I appended one line to the *live session's* `plan.md` (simulating
     the driver continuing to edit `plan.md` while a co-pilot window is open).
     `status` then reported `inputs_fresh: false` **but `candidate_state`
     stayed `"ready"`**. Both fields are individually correct and status never
     claims the stale-input candidate is authoritative, but a driver who reads
     only `candidate_state` (the field named in round-1's `reconciliation.md`
     summary) and not `inputs_fresh` could import a candidate that was produced
     against inputs the driver has since changed. `status`'s JSON is honest
     field-by-field; the risk is in a caller that doesn't consume the full
     object.

3. `tools/run-focused-tests.py --root . --manifest tests/focused-suites.tsv
   --jobs {4,8}`, two runs each, separate `--log-dir` per run (must be a
   *non-existent* directory — the script `mkdir`s it with `exist_ok=False` and
   exits immediately with a traceback if pre-created; this is worth noting in
   the skill's runbook so a future driver doesn't `mkdir -p` first):

   | run | jobs | elapsed (s) |
   |-----|------|-------------|
   | a   | 4    | 31.27 |
   | a   | 8    | 27.19 |
   | b   | 4    | 34.29 |
   | b   | 8    | 25.53 |

   Every one of the four runs failed on the exact same single suite,
   `test-tmux-config.sh` ("harness: tmux configuration requires a clean
   committed checkout"), because this sandbox's working tree is intentionally
   dirty (the new `docs/audits/t284-cowork-round2/` directory itself, plus
   `scratch-r2/`). This is a sandbox-cleanliness confound, not a
   concurrency-dependent flake: it reproduced identically at both job counts
   and in both repeats, took under 0.3s each time, and every other suite
   passed in all four runs. It does not undermine the jobs=4-vs-8 wall-time
   comparison, but it means none of these four runs is a "clean" gate result
   by this repository's own definition — a matched clean-tree sample still
   needs to be taken from a pristine checkout before freezing any worker-count
   change.

   Job-count comparison: jobs=8 was faster in both repeats (27.19s vs 31.27s,
   25.53s vs 34.29s), a consistent ~13-25% improvement, but run-to-run
   variance at the *same* job count (31.27 vs 34.29 at jobs=4; 27.19 vs 25.53
   at jobs=8) is itself up to ~10%, so two samples per arm is not enough to
   rule out shared-host noise as the dominant effect. The direction agrees
   with round-1's single unmatched sample (76.39s at 8 workers vs 88.18s at 4,
   via the full wrapper) but this is still not a frozen-worthy sample size.
   Top suite durations were consistent across all four runs: the cowork skill
   suite itself (~11.2s), `test-personal-macos-config-sync.sh` (~18.1s),
   `test-personal-macos-ssh-sync.sh` (~11.4s), `test-restic-schedule.sh`
   (~9.4s), `test-personal-macos-update.sh` (~8.5s) dominate; these are
   unrelated to T-284 and are the actual critical path for any further
   concurrency tuning.

4. CI-coverage trace: `.github/workflows/ci.yml` on this branch has exactly
   three steps — capability recording, `tests/test-affinity-readiness.sh`, and
   `tests/test-phase1.sh`. No standalone ShellCheck step remains.
   `tests/test-phase1.sh:376-379` still runs
   `shellcheck --severity=warning` when the binary is present, so that
   coverage is retained, not dropped. `tests/focused-suites.tsv` lists
   `tests/test-codex-claude-cowork-skill.sh` exactly once (line 11), and
   `test-affinity-readiness.sh` does **not** appear in the manifest, so it is
   not duplicated between the standalone CI step and the phase-one gate. This
   independently confirms round-1's CI-duplication claim rather than
   contradicting it — I re-traced it from source in this checkout instead of
   trusting the prior prose.

## Critique

- **Symmetry:** confirmed, not contradicted. `init --driver claude` produces
  an identical protocol shape to `--driver codex`; `stage`/`status`/`check`
  have no branch on driver identity in the commands exercised here. Round-1's
  implicit "same design works reversed" assumption holds for everything tested
  in this pass.
- **Turnaround:** the focused suite and CI trace match round-1 within normal
  variance; no regression found.
- **Prompt integrity:** the schema-3 prompt binding worked as designed
  (`prompt_sha256` set, artifact copied, seal committed) — no new issue found
  beyond round-1's own analysis.
- **Status honesty:** partially confirmed, one gap found. `status` never lies
  about any individual field (verified `unchanged`/`invalid`/`ready` and
  `inputs_fresh` all transitioned correctly under synthetic manipulation), but
  round-1's own `reconciliation.md` summarizes `status` by candidate state
  alone ("report ... candidate bytes/state") without foregrounding
  `inputs_fresh` as equally load-bearing. A driver skimming `candidate_state:
  ready` without checking `inputs_fresh` can import a candidate that was
  staged against now-stale live inputs. The tool is honest; the *documented
  usage pattern* in the skill reference is the risk surface.
- **Backward compatibility:** not independently re-tested in this pass beyond
  observing that `stage --prompt` is optional and schema-3 is additive over
  schema-2 in the source path exercised; round-1's compatibility test suite
  additions were not re-run here (out of this pass's time budget) and should
  be re-verified before any further change is frozen.
- **CI coverage/speed:** confirmed no coverage loss; the removed standalone
  ShellCheck and duplicate-suite steps remain covered exactly once inside
  `test-phase1.sh`/the manifest.

## Proposed plan changes

1. Update the skill reference's `status` usage guidance to require checking
   `inputs_fresh` (and `destination_fresh`) together with `candidate_state`
   before import, and have `import-copilot` itself already refuses a stale
   match at import time (confirm this in a follow-up pass) — but the *human/
   client-facing* runbook text should not imply `candidate_state: ready` alone
   is sufficient to import.
2. Document in the skill reference that `stage --seal` requires the seal path
   to be outside the stage's *parent* directory, not just outside the stage
   itself — a driver who puts scratch logs and the stage in the same working
   directory (as I initially did) will hit a late `stage` failure. This is
   correct/safe behavior; only the documentation is missing.
3. Before freezing any worker-count default change, re-run the
   `run-focused-tests.py` jobs=4-vs-8 comparison from a clean (non-dirty)
   checkout with at least 3-4 samples per arm, since this pass's own dirty
   tree produced an identical confound in all four runs and two samples per
   arm is not enough to separate real concurrency gains from host noise.
4. Note `tools/run-focused-tests.py --log-dir` must not pre-exist; either
   document this or make the script `mkdir(parents=True, exist_ok=True)` for
   driver convenience — no evidence either way on safety implications, flagged
   as an open question rather than adopted.
5. No change proposed to prompt integrity or CI-topology design; round-1's
   implementation is confirmed correct on every axis tested here except the
   documentation gap in (1) and (2).
