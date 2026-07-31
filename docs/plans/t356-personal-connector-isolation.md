# T-356 Harness integration plan

Phase: `blocked`.

## Outcome

Extend `harness personal-agent` so one bounded Personal operation can use an
explicit Gmail or Google Calendar profile only after Personal P-002 proves
provider privacy, exact scopes, client parity, cross-root absence, and
metadata-safe persistence.

## Scope

Harness owns:

- private runtime-profile path, ownership, mode, and type validation;
- bounded-child environment and exact MCP-manifest selection;
- connector status, inventory, and value-free receipts;
- fail-closed blocked/ready transitions;
- synthetic Codex/Claude launcher tests; and
- preservation of the immutable three-target lifecycle.

Personal owns connector code, credential-free manifests, domain policies,
readiness evidence, and every live source task. Follow the exhaustive plan at
`/mnt/nfs-03/safe/Users/rioyokota/projects/personal/docs/plans/p002-connector-isolation-privacy.md`.

## Expected files

- `libexec/harness-personal-agent`
- `tests/test-personal-agent.sh`
- focused tests added only if the existing suite would become too broad
- `docs/tasks/T-356.md`
- `docs/plans/t356-personal-connector-isolation.md`
- `TODO.md`
- `docs/tasks/index.tsv`

Do not change target maps, tmux topology, monitors, phone roots, app-server
roots, client defaults, user product configuration, credentials, or external
services.

## Execution sequence

1. Finish and freeze P-002 interview decisions; wait for explicit `go`.
2. Implement synthetic Personal connector behavior first.
3. Add launcher profile/status/inventory contracts without enabling a domain.
4. Add deterministic fake-client and fake-connector tests for both clients.
5. Require exact ready evidence before the launcher selects a connector
   manifest.
6. Run focused tests, `tests/test-phase1.sh`, and cross-root inventory tests.
7. Merge Personal and Harness changes through their protected `main` flows.
8. Only then enter the owner-driven privacy/OAuth gates from P-002.

P-002 P2-D001 froze the repository-native direct Google API MCP architecture
on 2026-07-31 from the owner's exact answer `1`. Harness must never substitute
a provider first-party account-wide connector.

P-002 P2-D002 froze one shared Google authorization identity for Gmail and
Calendar on 2026-07-31 from the owner's exact answer `1`. Harness uses one
opaque private profile while preserving separate domain scopes and readiness.

P-002 P2-D003 froze a consumer ChatGPT personal workspace on 2026-07-31 from
the owner's exact answer `1`. Live access requires a value-free owner
attestation that **Improve the model for everyone** is off; Harness never reads
or records account identity or plan details.

P-002 P2-D004 froze a consumer Claude account on 2026-07-31 from the owner's
exact answer `1`. Live access requires a value-free owner attestation that
**Help Improve Claude** is off. Existing T-355 D-015 already accepts applicable
provider retention; revalidate it before first live use without repeating the
settled decision unless terms materially change.

P-002 P2-D005 froze Gmail read-only before Calendar read-only on 2026-07-31
from the owner's exact answer `1`. Both domains retain separate scopes and
readiness; no write scope is part of P-002.

All P-002 decisions are audited and consistent. T-356 is ready for explicit
owner `go`. The first authorized mutation after `go` is synthetic code and
tests only; provider privacy, OAuth, and live-source actions remain later exact
owner gates.

## Safety and retry contract

- Profile bootstrap may create only a fixed current-user-owned private
  directory and credential-free templates.
- Credential paths may be passed to the intended connector only; their bytes,
  names beyond the fixed contract, hashes, and command output are never read.
- All live connector calls remain blocked until privacy and OAuth readbacks
  are complete.
- Every ambiguous login, consent, install, or live call is non-retryable until
  reconciled.
- A connector failure never falls back to a global plugin, account connector,
  another profile, client, or source.

## Acceptance

- Focused Personal-agent tests and full `tests/test-phase1.sh` pass.
- Personal's own complete validation passes.
- Fresh inventories prove selected tools present only in Personal for Codex
  and Claude.
- Exactly three managed targets remain declared.
- Personal has no persistent session, phone identity, or managed lifecycle.
- No source content, token, credential, or private provider identity appears
  in Git, logs, test output, or durable receipts.

## Recovery

Resume from `docs/tasks/T-356.md`, then Personal `docs/tasks/P-002.md`. The
Personal decision register is authoritative. Never infer or replay an external
step from chat history.
