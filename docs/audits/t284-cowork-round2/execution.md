# Driver execution

## Steps and results

Implemented exactly the five frozen target-file changes from
`reconciliation.md`, no others:

1. `shared/skills/codex-claude-cowork/scripts/cowork-session`: `status`'s
   stage snapshot now includes `mechanical_import_preconditions`
   (`candidate_structurally_ready`, `inputs_fresh`, `destination_fresh`,
   `all_satisfied`, `advisory: true`, `authorization: "none"`), computed only
   from the existing `candidate_state`/`inputs_fresh`/`destination_fresh`
   observations. No `import_ready` key added; `import-copilot`'s gating logic
   is unchanged.
2. `SKILL.md` and `references/protocol.md`: documented the new advisory
   object next to the `status` example (what it does and does not cover),
   froze the monitoring-ownership wording (driver runs full `status`; blinded
   co-pilot reports stage-local observations only; neither candidate state
   nor PID reachability authorizes import), and added the explicit
   "workspace-write limits writes, not reads" / no-confinement-equivalence
   statement in both files. The stage-parent seal-placement boundary was
   already documented in `protocol.md` (direct-child precondition, seal kept
   outside the entire stage-parent tree); no additional edit was needed there.
3. `tests/test-codex-claude-cowork-skill.sh` (round 9): added a case that
   fills the round-9 independent stage's candidate to `ready`, then mutates
   the live `charter.md` input (a staged input for `independent` mode) to
   force `inputs_fresh=false`, asserts `candidate_state=ready`,
   `inputs_fresh=false`, and the full `mechanical_import_preconditions`
   object (`candidate_structurally_ready=true`, `inputs_fresh=false`,
   `all_satisfied=false`, `advisory=true`, `authorization=none`), then
   restores `charter.md` before the existing prompt-drift/import assertions
   continue unmodified. Extended the existing post-import status assertion
   (`destination_fresh=false`) to also assert
   `mechanical_import_preconditions.all_satisfied is False`.
4. `tools/run-focused-tests.py`: wrapped the existing
   `log_dir.mkdir(mode=0o700, parents=False, exist_ok=False)` call in
   `try/except FileExistsError`, printing
   `focused-tests: --log-dir already exists: PATH` to stderr and returning
   exit status 2. No `exist_ok=True` and no idempotent merge — reuse is still
   refused, just without a traceback.
5. `tests/test-focused-runner.sh`: added a regression that re-invokes the
   runner against the already-populated `pass-logs` directory from the first
   parallel-pass case, and asserts exit code 2 (via the existing `if ... ;
   then fail; fi` non-zero-exit pattern), empty stdout (no suite executed),
   the exact diagnostic text on stderr, and the absence of `Traceback` in
   stderr.

`HARNESS_TEST_JOBS=4`, the CI workflow topology, and the direct-child
stage/seal rule are all unmodified, matching the frozen plan.

## Commands run and results

- `bash tests/test-codex-claude-cowork-skill.sh` — one fixup needed
  (see Deviations), then: `Codex-Claude cowork skill tests passed` (exit 0).
- `bash tests/test-focused-runner.sh` — `focused runner tests: PASS` (exit 0)
  on first run, unchanged after the protocol.md fixup.
- `shared/skills/codex-claude-cowork/scripts/cowork-session check
  docs/audits/t284-cowork-round2 --phase executing` —
  `valid executing session: ...` (exit 0).
- `shared/skills/codex-claude-cowork/scripts/cowork-session verify-receipts
  docs/audits/t284-cowork-round2` — `valid reciprocal receipt for live
  co-pilot evidence sha256=d678c4dc452e1005f2f4a86ffd5ffb9e6d58e1b09e9bad3ad3308ac9e837f395`
  (exit 0, unchanged from before execution — this session's receipts are not
  mutated by target execution).
- `git diff --check` — no output, exit 0 (no whitespace-conflict artifacts).
- Relevant skill/source/public/takeover focused suites also run clean:
  `bash tests/test-claude-takeover.sh` (`Claude takeover tests passed`),
  `bash tests/test-source-contract.sh` (`source contract tests: PASS`),
  `bash tests/test-public-repo-audit.sh` (`public repository audit tests
  passed`).
- `git status --porcelain` confirms exactly the five frozen target files
  (plus this session's own `state.json`/`execution.md`/`validation.md`
  bookkeeping) changed; no file outside the frozen scope was touched.

## Deviations

- Wrapping the new protocol.md prose caused `not an OS filesystem sandbox` to
  split across two lines, breaking
  `tests/test-codex-claude-cowork-skill.sh`'s exact-substring assertion
  (`protocol missing Claude enforcement boundary`). Rewrapped the paragraph so
  that exact phrase stays on one line; re-ran the focused cowork suite to
  confirm the fix and no other regression. This is a wording/line-wrap fix
  within the frozen doc-change scope of target file 2, not a new material
  choice.
- No other deviation from the frozen plan. No worker-count benchmarking was
  performed, per the frozen plan and reconciliation item 4.
