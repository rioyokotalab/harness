# Harness producer queue

Read this after root instructions and before `TODO.md`. Only the sole portfolio
producer may modify this file or `docs/producer/`. Consumers read the first
ready packet in priority/date order, then their own board and matching execution
record. If no packet is ready, remain idle.

Next free ID: Har-382.

## Queue

| Task | State | Priority | Packet |
| --- | --- | ---: | --- |
| Har-381 | ready | 1 | `docs/producer/tasks/Har-381.md` |
| Har-379 | ready | 5 | `docs/producer/tasks/Har-379.md` |
| Har-371 | gated | 10 | `docs/producer/tasks/Har-371.md` |
| Har-196 | gated | 20 | `docs/producer/tasks/Har-196.md` |
| Har-328 | gated | 30 | `docs/producer/tasks/Har-328.md` |
| Har-303 | gated | 40 | `docs/producer/tasks/Har-303.md` |
## Writer contract

Consumers never modify producer-owned paths or allocate durable IDs. They keep
execution state in `TODO.md`, `docs/tasks/`, and implementation files, and write
completion or blocking evidence under `docs/consumer/receipts/`. Nested in-scope
findings are handled LIFO inside the active task; out-of-scope or authority-gated
findings produce a blocked receipt, not a new goal.

Before publication run `python3 tools/producer-ledger.py validate` and the
role-appropriate diff check against the protected base.
Owner-started nightly runs additionally follow `docs/producer/NIGHTLY.md`.
