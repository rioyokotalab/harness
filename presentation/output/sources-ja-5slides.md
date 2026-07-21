# Harness Evolution — 日本語5枚版 sources

Source snapshot: `90451d49ac96a31ca5f42044ce2f4735b8908698`,
2026-07-21. No repository tags or merge commits existed through this snapshot.

## Slide 1

- Managed topology: `90451d49ac96a31ca5f42044ce2f4735b8908698`,
  `TODO.md`, `profiles/hosts/*.conf`, `docs/environment-portability.md`, and
  personal-Mac public/private architecture documentation.
- Repository structure: current Git tree, `README.md`, `bin/harness`,
  `libexec/`, `profiles/`, `shared/skills/`, `tests/focused-suites.tsv`,
  `docs/audits/`, and `evaluation/`.
- Discovery and invocation: `install.sh`, `.codex/AGENTS.md`,
  `.codex/rules/default.rules`, `.claude/CLAUDE.md`, and every
  `shared/skills/*/SKILL.md`.
- Discovery validation: `tests/test-phase1.sh`,
  `tests/test-source-contract.sh`, and installer checks.

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

- Authority and policy: `.codex/AGENTS.md` and
  `.codex/rules/default.rules` at the source snapshot.
- Transaction/revalidation: `libexec/harness-{apply,rollback,remediate}`, the
  guarded-delete skill/script, and their focused tests.
- Focused execution: `tests/focused-suites.tsv` and
  `tools/run-focused-tests.py`.
- Complete portable gate: `tests/test-phase1.sh` and
  `tests/guarded-test-cleanup.sh`.
- Protected CI: `.github/workflows/ci.yml`, including non-persisted checkout
  credentials, affinity readiness, and the credential-free phase-one gate.

## Slide 4

- Symmetric cowork implementation:
  `535a49218d766ce917ee28bc4b9d89fa0f650434`,
  `shared/skills/codex-claude-cowork/SKILL.md`,
  `references/protocol.md`, and `scripts/cowork-session`.
- Protocol and takeover validation:
  `tests/test-codex-claude-cowork-skill.sh` and
  `tests/test-claude-takeover.sh`.
- Acceptance evidence: `docs/audits/t283-cowork-acceptance.md` and
  `docs/audits/t284-cowork-acceptance.md` at
  `bb11854f59ec54907920c7cb3e9883ea94ab317e`.

## Slide 5

- Complete chronology: `presentation/evidence/timeline.csv` and
  `milestones.md`, root `7f969317c4b597b9adaae629c05cf6723785aff2`
  through source snapshot `90451d49ac96a31ca5f42044ce2f4735b8908698`.
- Checked-in metrics: `presentation/evidence/metrics.csv`, HPC audit JSON,
  evaluation results/review, backup acceptance, and T-284 matched samples.
- Current surface: source snapshot `90451d4`, `shared/skills/`, `bin/harness`,
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
