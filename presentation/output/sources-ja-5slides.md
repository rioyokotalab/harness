# Harness Evolution — 日本語5枚版 sources

Source snapshot: `7c592af6a9778ce24fe36b093c3bcdccb877da61`,
2026-07-21. No repository tags or merge commits existed through this snapshot.

## Slide 1

- Initial implementation: `7f969317c4b597b9adaae629c05cf6723785aff2`,
  historical `README.md`, `install.sh`, `AGENTS.md`, and `skills/`.
- Dual-client discovery: `805db485d9b591f399e9025b28dc8397b27286b3`.
- Current source snapshot: `7c592af6a9778ce24fe36b093c3bcdccb877da61`,
  current `README.md`, `bin/harness`, and `TODO.md`.
- Chronology: `presentation/evidence/timeline.csv` and `milestones.md`.

## Slide 2

- Incident record: `e5200fd3ae3aa5b6b326205b6475af2047d21929`,
  historical `TODO.md`, T-171.
- Consolidated recovery record:
  `d726f0deb222416457659c01c5511ba970c590d6`, historical `TODO.md`.
- Guarded deletion response:
  `238f0224e6f5ac51ffcb1b47ba5308c97377df3e`,
  `.codex/rules/default.rules`, `shared/skills/guarded-bulk-delete/`, and
  `tests/test-guarded-delete.sh`.
- Evidence reconciliation: `presentation/evidence/incident-rm-rf.md`.

## Slide 3

- Value-free observation:
  `fb417282588f446f580e2f1de7b4c9b3341c18c5`, inventory/plan/doctor,
  profiles, fixtures, and phase-1 tests.
- Transaction pivot: `07351a40f40d3609d3924c3e440a30523e72fa04`,
  apply/rollback implementation and tests.
- Recovery/backup: `4f34299ac2b0202a92be9e4978b6e5d5630b7ce5`,
  `docs/home-backup.md` and Restic implementation.
- Personal Mac engine: `a0b74a4a6936c591684325226c872f1ba02f327e`;
  public Bash/tmux migration: `4209ee84408a0abf4fccdbeafcac62ad050d4ad0`;
  client configuration: `6a7e177d05742fbbde054a1af94e2c85810e3790`.
- Symmetric cowork: `535a49218d766ce917ee28bc4b9d89fa0f650434`.

## Slide 4

- Evaluation engine/results:
  `05932762e5ab9be8113da4b7620de4642200d5ae` and
  `ee9685313cf9ed7b4d3ed1b5cb75bda744d4dd8a`, under `evaluation/` and
  `docs/evaluation-follow-up.md`.
- HPC acceptance: `25efb7b489c8a660695694af39643889187b9021`
  and `40b40da3b5a7abd637929f1714eb8b46f4dbec00`, checked-in audit JSON and
  `docs/hpc-readiness.md`.
- Cowork timing: `bb11854f59ec54907920c7cb3e9883ea94ab317e`,
  `docs/audits/t284-cowork-acceptance.md`.
- Four accepted Macs: `7c592af6a9778ce24fe36b093c3bcdccb877da61`,
  `TODO.md` current-state section.

## Slide 5

- Current surface: source snapshot `7c592af`, `shared/skills/`, `bin/harness`,
  `tests/focused-suites.tsv`, and `profiles/hosts/`.
- Explicit Git operations replaced automatic hooks:
  `e52a3d01d11be2f2b3895e1e49dc8e670e3954a1`.
- Repository independence replaced website-specific ownership:
  `f1b095c505bea596853a329b13feb95a8a1548e4`.
- Public Bash/tmux replaced private duplication: `4209ee8`.
- Local native Codex ownership replaced harness-owned installation:
  `d76575c80ade7638a2df74328df60f07405a1193`.
- Claim types and limits:
  `presentation/evidence/source-map-ja-5slides.md` and original
  `presentation/evidence/source-map.md`.
