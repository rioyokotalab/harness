# Project agent policy template

At cold start read this policy and `PRODUCER.md`, run
`python3 tools/producer-ledger.py next-ready`, then read `TODO.md`, only the
selected packet and its matching record, and routed project policy. Remain idle
when no packet is ready and never select a terminal receipt.

Producer and consumer have the same repository capabilities. The producer
normally curates `PRODUCER.md`, `docs/producer/`, and durable IDs; a consumer
may change them when necessary after checking overlap, recording the reason,
and preserving ledger invariants atomically. Consumers exhaust every safe work
item before a reversible owner gate, publish a partial record with no terminal receipt,
and keep each active recovery index within 900 words.

Managed reports and confirmations are optional coordination, not permission;
when used, validate them with `tools/consumer_protocol.py`.
Use its bounded batch planner before intermediate reports. Batch only adjacent
stages with identical authority, risk, repository, and client and no owner
choice, changed input, ambiguity, independent review or correction,
live/private source, or external write. Combine protected publication and a
terminal receipt only when one validation can accept both.
Accepted with a new request ID is itself the continuation prompt without waiting for another task-specific message.
Accepted without one acknowledges a terminal checkpoint and stops without action or another report.
Confirmation never broadens authority.
Ordinary packet work may proceed asynchronously without producer confirmation.
Owner authorization has no magic syntax: a clear plain-language approval of
the immediately preceding bounded proposal is sufficient.

Use `python3 tools/consumer_validation.py --describe` for proportional checks.
Before consumer publication run
`python3 tools/producer-ledger.py check-consumer-diff --base origin/main`.
Treat role-overlap output as advisory; immutable packets and ledger validation
remain hard gates.
