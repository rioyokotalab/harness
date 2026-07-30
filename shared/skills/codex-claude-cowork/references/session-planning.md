# Cowork session and planning

Read this file completely before initializing or reconstructing a cowork
session, planning, or advancing to `discussing`.

## State and files

`scripts/cowork-session` permits only:

```text
planning -> discussing -> ready-for-execution -> executing -> validating -> complete
```

New sessions use schema 3 and staged exchange. Use
`--exchange-mode direct` only for the exceptional direct fallback selected
under `recovery.md`. Existing schema-1/2 sessions retain their frozen layouts
and must never be rewritten in place.

The exchange contains driver-owned `charter.md`, `plan.md`, `benchmark.md`,
`driver-evidence.md`, `reconciliation.md`, `execution.md`, and
`validation.md`; co-pilot-owned `copilot-evidence.md`; validator-owned
`state.json`; bounded `artifacts/`; and, for staged schema-2+ sessions,
driver-owned `receipts/`. Do not add auxiliary top-level entries.

Initialize exactly one driver:

```text
scripts/cowork-session init SESSION_DIR --driver codex
scripts/cowork-session init SESSION_DIR --driver claude
```

Declare the target, live exchange, two disposable sandboxes, and one immutable
baseline. The driver owns session content except the content of
`copilot-evidence.md`. Prepare each bounded co-pilot prompt in a driver-only
path outside the co-pilot sandbox before staging it.

## Charter, plan, and benchmark

Record in `charter.md` the task, scope, non-goals, authority, baseline,
sandbox construction, acceptance gates, and cleanup policy. Keep credentials,
private values, and unrelated data out.

Write a numbered plan with confirmed facts separated from assumptions,
dependencies, failure modes, recovery, evidence questions, stop conditions,
and validation for every material step. Planning may use read-only discovery
but must not mutate the target.

Complete `benchmark.md` before evidence:

- exact target and baseline identity;
- observable cases measured for every candidate;
- evidence and iteration method;
- stop condition; and
- agreement section.

The frozen benchmark agreement precedes target execution. Before
`ready-for-execution`, record both exact client-bound lines:

```text
agreement: role=driver client=DRIVER_CLIENT benchmark-accepted
agreement: role=copilot client=COPILOT_CLIENT benchmark-accepted
```

These records assert protocol completeness, not authorship. Keep the benchmark
in the protected digest set.

Advance only after the charter, plan, and benchmark validate:

```text
scripts/cowork-session advance SESSION_DIR discussing
```

The validator must reject unresolved standalone `TODO` markers, role mismatch,
skipped/backward phases, symlinks, foreign-owned or hard-linked protocol files,
missing or unexpected entries, and an invalid schema-specific layout. Protocol
validation does not prove factual correctness, authorship, or confinement.
