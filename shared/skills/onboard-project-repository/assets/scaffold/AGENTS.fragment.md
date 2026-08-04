## Producer/consumer cold start

Read root policy and `PRODUCER.md`, run
`python3 tools/producer-ledger.py next-ready`, then read `TODO.md`, only the
selected packet and its matching record, and routed project policy. Remain idle
when no packet is ready. The producer index and selector are the sole current
disposition; packet metadata is immutable creation-time context.

Only the portfolio producer edits `PRODUCER.md` or `docs/producer/`.
Consumers exhaust safe packet work before reversible owner gates, keep active
records within 900 words, create terminal receipts only for durable outcomes,
and run the consumer diff guard before protected publication. Use
`tools/consumer_validation.py` for proportional checks. If managed checkpoint
messaging is configured, validate its value-free reports and exact confirmation
envelopes with `tools/consumer_protocol.py`. Before intermediate reports, use
its bounded batch planner and combine only same-authority, same-risk,
same-repository, same-client stages with no owner choice, changed input,
ambiguity, independent review or correction, live/private source, or external
write.
