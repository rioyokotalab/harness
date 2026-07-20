# Validation

## Checks

All checks below ran against the clean, committed tree at
`2257cec` (`Refine cowork monitoring and fast failures`), i.e. after
restoring `docs/audits/t284-cowork-round2/state.json` to its committed value
and confirming `git status --porcelain` printed nothing, before advancing the
session phase (which itself dirties `state.json` again and is recorded/
committed only after these results).

1. Focused cowork suite: `bash tests/test-codex-claude-cowork-skill.sh` →
   `Codex-Claude cowork skill tests passed` (exit 0).
2. Focused runner suite: `bash tests/test-focused-runner.sh` →
   `focused runner tests: PASS` (exit 0).
3. `shared/skills/codex-claude-cowork/scripts/cowork-session check
   docs/audits/t284-cowork-round2 --phase executing` → `valid executing
   session: ...` (exit 0), run on the clean tree before advancing phase.
4. `git diff --check` → no output, exit 0.
5. `shared/skills/codex-claude-cowork/scripts/cowork-session verify-receipts
   docs/audits/t284-cowork-round2` → `valid reciprocal receipt for live
   co-pilot evidence
   sha256=d678c4dc452e1005f2f4a86ffd5ffb9e6d58e1b09e9bad3ad3308ac9e837f395`
   (exit 0), unchanged since the frozen-plan commit — session receipts are
   not touched by target execution.
6. Full `tests/test-phase1.sh`, run from the clean committed tree:
   started/finished within the same invocation, elapsed **80s** wall time,
   exit status **0**. Output summary: **57 PASS, 0 FAIL** across the focused
   manifest plus the guarded-delete and native-MPI-smoke sections
   (`guarded-delete tests: PASS`; native MPI smoke skipped as expected —
   `SKIP native MPI smoke: run tests/test-native-mpi.sh in a declared MPI
   environment`); final line `phase-1 harness tests passed`. Notably,
   `test-tmux-config.sh` — which failed in every prior dirty-tree run this
   session (a known confound recorded in `reconciliation.md` item 4) —
   passed on this clean-tree run, confirming that failure mode was purely
   tree cleanliness, not a defect in the five frozen changes.

Also re-ran the additional skill/source/public/takeover focused suites named
in the frozen acceptance gates as an extra spot-check (all included in and
already covered by the full run above, but also run standalone before the
full run during execution): `tests/test-claude-takeover.sh`,
`tests/test-source-contract.sh`, `tests/test-public-repo-audit.sh` — all
passed (see `execution.md`).

## Outcome

All frozen acceptance gates pass. No test, source, or doc file outside the
five frozen target files (`shared/skills/codex-claude-cowork/scripts/
cowork-session`, `shared/skills/codex-claude-cowork/SKILL.md`,
`shared/skills/codex-claude-cowork/references/protocol.md`,
`tests/test-codex-claude-cowork-skill.sh`, `tests/test-focused-runner.sh`,
`tools/run-focused-tests.py`) was modified. `HARNESS_TEST_JOBS=4`, the CI
workflow topology, and the direct-child stage/seal rule remain unmodified, as
required by the frozen plan. Session advances to `complete`.

## Residual risks

- The worker-count question (reconciliation item 4) remains explicitly
  deferred: no benchmarking was performed in this round, and any future
  default change needs a clean-checkout, matched, multi-sample rerun as
  scoped there — not addressed by this validation.
- `mechanical_import_preconditions` is advisory only; a future caller could
  still misuse it as an authorization gate despite the frozen
  `advisory`/`authorization: "none"` fields and documentation. Mitigated by
  explicit SKILL.md/protocol.md wording but not enforceable in code beyond
  naming and the added regression test.
- Native MPI smoke remains skipped in this sandbox (expected, no declared MPI
  environment here); unrelated to the five frozen changes.
