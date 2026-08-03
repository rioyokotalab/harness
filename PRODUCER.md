# Harness producer queue

Read this after root instructions and before `TODO.md`. Only the sole portfolio
producer may modify this file or `docs/producer/`. Consumers resolve the first
executable packet with `python3 tools/producer-ledger.py next-ready`, then read
their own board and matching execution record. If it reports idle, remain idle.

Next free ID: Har-390.

## Queue

| Task | State | Priority | Packet |
| --- | --- | ---: | --- |
| Har-389 | ready | 0 | `docs/producer/tasks/Har-389.md` |
| Har-196 | gated | 20 | `docs/producer/tasks/Har-196.md` |
| Har-328 | gated | 30 | `docs/producer/tasks/Har-328.md` |
| Har-303 | gated | 40 | `docs/producer/tasks/Har-303.md` |
## Writer contract

Consumers never modify producer-owned paths or allocate durable IDs. They keep
execution state in `TODO.md`, `docs/tasks/`, and implementation files, and write
completion or blocking evidence under `docs/consumer/receipts/`. Nested in-scope
findings are handled LIFO inside the active task. A durable out-of-scope block
produces a blocked receipt, not a new goal. An expected, reversible owner-choice
wait instead preserves the partial task record without a terminal receipt; the
producer gates that task so the selector can advance, then restores it to ready
after recording the owner answer. Never delete or rewrite a terminal receipt to
resume work.

Before publication run `python3 tools/producer-ledger.py validate` and the
role-appropriate diff check against the protected base. A terminal receipt is
never executable while producer reconciliation is pending.
Owner-started nightly runs additionally follow `docs/producer/NIGHTLY.md`.
