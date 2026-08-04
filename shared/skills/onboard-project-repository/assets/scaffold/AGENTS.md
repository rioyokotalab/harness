# Project agent policy template

At cold start read this policy and `PRODUCER.md`, run
`python3 tools/producer-ledger.py next-ready`, then read `TODO.md`, only the
selected packet and its matching record, and routed project policy. Remain idle
when no packet is ready and never select a terminal receipt.

Only the portfolio producer edits `PRODUCER.md` or `docs/producer/`. Consumers
exhaust every safe work item before a reversible owner gate, publish a partial
record, emit one value-free report, and create no terminal receipt. Keep each
active recovery index within 900 words.

Validate managed reports and confirmations with `tools/consumer_protocol.py`.
Accepted with a new request ID is itself the continuation prompt without waiting for another task-specific message.
Accepted without one acknowledges a terminal checkpoint and stops without action or another report.
Confirmation never broadens authority.

Use `python3 tools/consumer_validation.py --describe` for proportional checks.
Before consumer publication run
`python3 tools/producer-ledger.py check-consumer-diff --base origin/main`.
