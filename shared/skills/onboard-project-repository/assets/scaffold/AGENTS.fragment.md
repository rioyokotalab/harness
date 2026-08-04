## Producer/consumer cold start

Read root policy and `PRODUCER.md`, run
`python3 tools/producer-ledger.py next-ready`, then read `TODO.md`, only the
selected packet and its matching record, and routed project policy. Remain idle
when no packet is ready. The producer index and selector are the sole current
disposition; packet metadata is immutable creation-time context.

Producer and consumer have the same repository capabilities. The producer
normally curates `PRODUCER.md`, `docs/producer/`, and durable IDs; a consumer
may change them when necessary after checking overlap, recording the reason,
and preserving ledger invariants atomically. Consumers exhaust safe packet work before reversible owner gates, keep active
records within 900 words, create terminal receipts only for durable outcomes,
and run the consumer diff guard before protected publication. Use
`tools/consumer_validation.py` for proportional checks. If managed checkpoint
messaging is configured, treat it as optional coordination rather than
permission and validate its value-free reports and confirmation envelopes with
`tools/consumer_protocol.py`. Ordinary packet work may proceed asynchronously
without producer confirmation. Before intermediate reports, use
its bounded batch planner and combine only same-authority, same-risk,
same-repository, same-client stages with no owner choice, changed input,
ambiguity, independent review or correction, live/private source, or external
write. Owner authorization has no magic syntax: clear plain-language approval
of the immediately preceding bounded proposal is sufficient.
