# Producer and consumer execution

Producer and consumer are trust-equivalent repository agents. Producer curates
`PRODUCER.md`, `docs/producer/`, and IDs; either may cross for in-scope work
after fetch/overlap checks, a recorded reason, and ledger validation. The
role-aware diff command reports overlap advisory; packet immutability remains
hard.

A ready packet grants bounded repository work/publication, not owner
choices/external mutations. Exhaust every safe work item before
a reversible owner gate; publish a record and create no terminal receipt.
Keep active records within 900 words.

Managed checkpoints are optional coordination, not authorization. When used,
`tools/consumer_protocol.py` binds messages: a new request ID is itself the continuation prompt
without another task-specific message; a terminal checkpoint stops without action. Confirmation never
broadens authority; ordinary work proceeds without producer confirmation.
Batch same-authority/risk/repository/client work absent choices, changed input,
ambiguity, review, private sources, or external writes. Use
`tools/consumer_validation.py --describe` for proportional checks and reuse
only unchanged evidence. Run `python3 tools/producer-ledger.py check-consumer-diff --base origin/main`;
overlap does not fail it.

Owner approval needs no magic phrase or pasted wording; a response to the
latest bounded proposal suffices.
