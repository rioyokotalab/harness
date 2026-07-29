# Validation

## Checks

- Students candidate and target:
  `uv run --frozen --no-sync pytest -q tests/test_student_worker.py` — 17
  passed; `uv run --frozen --no-sync tools/check.sh` — 174 tests plus Ruff,
  compile, secret scan and repository validation passed; `git diff --check` —
  clean.
- Harness focused candidate:
  `tests/test-codex-claude-cowork-skill.sh`,
  `tests/test-agent-config.sh`, and `tests/test-claude-takeover.sh` — passed
  independently after driver corrections.
- Harness clean candidate: `tests/test-phase1.sh` — passed every focused suite,
  guarded-delete checks, and phase-1 gate; native MPI was explicitly skipped
  outside a declared MPI environment.
- Native project settings: Claude Code 2.1.220 with
  `--setting-sources project`, no `--model`, no `--effort`, and `--tools ""`
  returned one successful turn with canonical `claude-fable-5`.
- Both tracked Claude settings mirrors are byte-identical, the policy validator
  requires exact `model=fable` and `effortLevel=high`, and focused negative
  fixtures reject wrong/missing/diverged values.
- New helper tests prove schema-3 benchmark creation/completeness, staged
  inclusion/protection, exact role-bound agreement gating, and schema-1/2
  compatibility.

## Outcome

All frozen benchmark cases pass.  Students D-016/D-017 are implemented and
closed without activation.  Harness now requires benchmark-first cowork
iterations for every duration-specified job, emits proportional evidence-backed
summaries, and defaults managed project Claude sessions and cowork invocations
to Fable/high.  Target commits are `8c04f63` (Students) and `4d21c8d`
(Harness); protected publication remains.

## Residual risks

- Schema-3 agreement records prove protocol completeness, not client
  authorship; external seals, sandbox separation and driver review remain
  required.
- Duration summary structure is a durable instruction, not a standalone
  machine parser over arbitrary owner prose.
- A deployed nonempty Students schema-1 worker state now fails closed because
  it cannot attest a task ID.  No live student deployment was touched.
- Students real-client read-only command semantics remain a pre-activation
  validation gate; unit and full offline tests pass.
- The future T-336 Fable/high failure-capsule retest requires a distinct result
  identity and is not part of this remediation.
