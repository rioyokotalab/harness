# Harness evolution presentation sources

All substantive claims in the deck are sourced to the repository at analysis
HEAD `f25429546bf8114b3309f26e3d3242feae191a30`. Abbreviated footers in the
slides use short SHAs and paths; this file supplies full identifiers and scope.
No confidential runtime output, credentials, private Mac values, or internal
URLs were used.

## History and method

- **G1 — Root and complete history.** Root
  `7f969317c4b597b9adaae629c05cf6723785aff2`; HEAD
  `f25429546bf8114b3309f26e3d3242feae191a30`. Reproduce with
  `git rev-list --max-parents=0 HEAD`, `git log --first-parent --reverse`,
  `git rev-list --count HEAD`, and `git rev-list --first-parent --count HEAD`.
- **G2 — Tags and merges.** No tags and no merge commits at HEAD. Reproduce
  with `git tag` and `git log --merges`.
- **G3 — File events and replacements.** Inspected with `git log --summary
  --find-renames --diff-filter=ADR`, milestone `git show --stat`, and historical
  `git show COMMIT:PATH`.
- **G4 — Reproducible scope metrics.** `presentation/scripts/history_metrics.py
  --check` and `presentation/evidence/metrics.csv`. Counts describe scope or
  coverage breadth, not quality.

## Foundational commits

- **C1 — Portable Codex harness.**
  `7f969317c4b597b9adaae629c05cf6723785aff2`, “Initialize portable Codex
  harness,” 2026-07-14. Historical `README.md`, `install.sh`, `AGENTS.md`,
  `rules/default.rules`, and `skills/`.
- **C2 — Dual-client discovery.**
  `805db485d9b591f399e9025b28dc8397b27286b3`, “Integrate Codex and Claude
  harness,” 2026-07-14. Historical `README.md`, `install.sh`, `claude/`, and
  `shared/skills/`.
- **C3 — Value-free observation.**
  `fb417282588f446f580e2f1de7b4c9b3341c18c5`, “Add read-only environment
  planning foundation,” 2026-07-14. `bin/harness`,
  `libexec/harness-{inventory,plan,doctor}`, `profiles/hosts/`, fixtures, and
  `tests/test-phase1.sh`.
- **R1 — Architecture model.** `docs/environment-portability.md` at HEAD.

## Transactional control and lifecycle safety

- **C4 — Apply and rollback.**
  `07351a40f40d3609d3924c3e440a30523e72fa04`, 2026-07-14.
- **C5 — Shell suffix transactions.**
  `42e9a119f16f43faed318341abcc78252a5866df`, 2026-07-14.
- **C6 — Pinned tool transactions.**
  `37ff256a75418a7d5e2c2ddbddc1c41a1fed1251`, 2026-07-14.
- **C7 — Guarded deletion.**
  `238f0224e6f5ac51ffcb1b47ba5308c97377df3e`, 2026-07-15.
  `shared/skills/guarded-bulk-delete/SKILL.md`, its `guarded-delete` script,
  and `tests/test-guarded-delete.sh`.
- **C8 — Hidden-home backup/restore.**
  `4f34299ac2b0202a92be9e4978b6e5d5630b7ce5`, 2026-07-15.
  `docs/home-backup.md`, `profiles/restic-repositories.tsv`.
- **C9 — Scheduler-native weekly chain.**
  `852b84bb753bf590a55353f96de71fba3b7b77d5`, 2026-07-16.
  `libexec/harness-restic-schedule`, `profiles/restic-schedules.tsv`, and
  `tests/test-restic-schedule.sh`.
- **C10 — Guarded fleet synchronization.**
  `e8b0e9ae37294b4a1d6aba29c64a76c223075a69`, 2026-07-17.
  `libexec/harness-fleet-sync`, `tests/test-fleet-sync.sh`.
- **C11 — Recoverable agent replacement.**
  `1ed9712bc8c3fd4896df2654b2a3379412e5984d`, 2026-07-20.
  `libexec/harness-agent`, `libexec/harness-rollback`, and
  `tests/test-agent-upgrade.sh`.
- **R2 — Current transactional overview.** `README.md`, “Transactional control
  plane” through agent/source-build sections.
- **E1 — Weekly backup acceptance.**
  `docs/audits/restic-first-weekly-2026-07-19.md`; current state in `TODO.md`.

## Evaluation, CI, and native readiness

- **C12 — Acceptance evaluator.**
  `05932762e5ab9be8113da4b7620de4642200d5ae`, 2026-07-16.
  `evaluation/evaluate.py`, `evaluation/corpus.json`, schemas, seeds, oracles,
  and `tests/test-evaluation.sh`.
- **E2 — T-181 full aggregate.**
  `evaluation/results/t181-failure-capsule-v1-full.json`, added by
  `ee9685313cf9ed7b4d3ed1b5cb75bda744d4dd8a`. Canonical totals: 70 primary
  runs, 69 deterministic passes, two retries, zero safety failures.
- **E3 — T-181 targeted review and decision.**
  `evaluation/results/t181-failure-capsule-v1-full-review.md` and
  `docs/evaluation-follow-up.md`. The review judged all 70 runs substantively
  acceptable but did not rewrite the deterministic aggregate; the candidate
  was rejected for no demonstrated benefit and added cost.
- **C13 — Portable CI.**
  `f6b9909a0fa81339bb387782ee660588a54c664c`, 2026-07-16.
  `.github/workflows/ci.yml`, `docs/ci-and-merge-controls.md`, and
  `tests/test-github-rulesets.sh`.
- **E4 — CPU readiness.**
  `docs/audits/hpc-cpu-readiness-2026-07-16.json`, recorded by
  `25efb7b489c8a660695694af39643889187b9021`: seven of seven nodes passed.
- **E5 — Accelerator readiness.**
  `docs/audits/hpc-accelerator-readiness-2026-07-17.json`, recorded by
  `40b40da3b5a7abd637929f1714eb8b46f4dbec00`: seven driver/runtime passes,
  five CUDA-kernel passes, two declared toolkit skips.
- **E6 — MPI readiness.** `docs/audits/hpc-mpi-readiness-2026-07-17.json` and
  `docs/audits/hpc-multinode-mpi-readiness-2026-07-17.json`: five passing
  single-node routes; three passing multi-node routes, two terminal environment
  failures, and two exclusions.
- **R3 — Interpretation limits.** `docs/hpc-readiness.md`: correctness and
  environment gates, not benchmark, scaling, or production-training claims.

## Cross-platform and client configuration

- **C14 — Personal-Mac engine.**
  `a0b74a4a6936c591684325226c872f1ba02f327e`, 2026-07-18.
  `docs/personal-macos.md`, `docs/plans/personal-macos-fleet.md`, schema and
  `libexec/harness-macos-*` commands.
- **C15 — Public Bash/tmux migration.**
  `4209ee84408a0abf4fccdbeafcac62ad050d4ad0`, 2026-07-19.
  `config/tmux/tmux.conf`, `docs/personal-macos-config-sync.md`,
  `libexec/harness-macos-config-migrate`, and focused tests.
- **C16 — Public client configuration.**
  `6a7e177d05742fbbde054a1af94e2c85810e3790`, 2026-07-19.
  `config/agent-clients/`, `docs/agent-client-config.md`, and
  `libexec/harness-agent-config`.
- **E7 — Current Mac state.** `TODO.md` at `f254295`: three reachable personal
  Macs accepted and one owner-operated Mac availability-gated.

## Cross-client cowork and measured validation

- **C17 — Symmetric cowork.**
  `535a49218d766ce917ee28bc4b9d89fa0f650434`, 2026-07-21.
  `shared/skills/codex-claude-cowork/`,
  `docs/audits/t283-cowork-acceptance.md`, and
  `tests/test-codex-claude-cowork-skill.sh`.
- **C18 — Cowork monitoring and adaptive checks.**
  `bb11854f59ec54907920c7cb3e9883ea94ab317e`, 2026-07-21.
  `docs/audits/t284-cowork-acceptance.md`, `tools/run-focused-tests.py`,
  `.github/workflows/ci.yml`, and `tests/test-focused-runner.sh`.
- **E8 — T-284 timings.** Six sequential focused-runner samples: jobs=4
  29.82/29.67/29.69 s; jobs=8 25.35/25.39/25.25 s; 14.62% median reduction on
  one eight-CPU-visible host. Original full gate 88.18 s; final auto-eight
  77.18 s; explicit legacy 149.69 s. The acceptance document records the
  whole-suite and host-specific limitations.
- **E9 — Cowork limits.** T-283 and T-284 acceptance indexes: hashes do not
  prove model authorship or honest inputs; Claude tool permissions are not an
  OS sandbox; workspace-write is a write boundary rather than read
  confidentiality; PID identity is advisory; synchronous reads may outlive a
  waiter deadline.

## Recorded reversals and removed implementations

- **C19 — Remove automatic Git shell hooks.**
  `e52a3d01d11be2f2b3895e1e49dc8e670e3954a1`, 2026-07-18. The diff deletes
  login fetch/fast-forward and exit-time publication from
  `shell/remote-session.sh`; `tests/test-remote-session.sh` freezes explicit
  behavior.
- **C20 — Remove website-specific ownership.**
  `f1b095c505bea596853a329b13feb95a8a1548e4`, 2026-07-18. Deletes website
  audit/ruleset/tool scope and adds `tests/test-repository-independence.sh`.
- **C21 — Replace retired target.**
  `f8685b5a0a2c62db2ee76e125a00f7a897336f3d`, 2026-07-14. Deletes the retired
  `ai4s` profile/fixture and introduces `ri` in successor commits.
- **C22 — Keep native Codex ownership local.**
  `d76575c80ade7638a2df74328df60f07405a1193`, 2026-07-19. Replaces earlier
  managed-native ownership with a locally owned native client plus harness
  policy/wrapper.

## Deck-local generated asset

- `presentation/output/assets/cover-control-network.png` is non-evidentiary
  decorative artwork generated with the built-in `imagegen` tool. It contains
  no text, labels, logos, or technical claims. All evidentiary visuals are
  native slide elements.
