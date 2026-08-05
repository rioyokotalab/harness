# Harness producer queue

Read this after root instructions and before `TODO.md`. The portfolio producer
normally curates this file and `docs/producer/` to avoid conflicts. Consumers
resolve the first executable packet with `python3 tools/producer-ledger.py
next-ready`, then read their own board and matching execution record. If it
reports idle, remain idle unless exceptional in-scope repair requires queue
work under the writer guidance below.

Next free ID: Har-397.

## Queue

| Task | State | Priority | Packet |
| --- | --- | ---: | --- |
| Har-196 | gated | 20 | `docs/producer/tasks/Har-196.md` |
| Har-328 | gated | 30 | `docs/producer/tasks/Har-328.md` |
| Har-303 | gated | 40 | `docs/producer/tasks/Har-303.md` |
## Writer contract

Producer and consumer have the same repository capabilities. Consumers should
normally keep execution state in `TODO.md`, `docs/tasks/`, implementation, and
receipts while leaving queue curation and ID allocation to the producer. If a
consumer judges a producer-path edit or new durable task necessary, it may do
so after a fresh fetch and overlap check, provided it records the reason and
updates every ledger invariant atomically. Nested findings remain LIFO by
default. A reversible owner-choice wait preserves the partial record without a
terminal receipt. Never delete or rewrite a terminal receipt to resume work.

Before publication run `python3 tools/producer-ledger.py validate` and the
role-aware advisory diff check against the protected base. Immutable packets
and lifecycle validation remain hard gates. A terminal receipt is never
executable while producer reconciliation is pending.
Owner-started nightly runs additionally follow `docs/producer/NIGHTLY.md`.
