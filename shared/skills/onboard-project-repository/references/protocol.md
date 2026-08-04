# Repository-native producer/consumer protocol

## Required structure

Install a compact root `PRODUCER.md`, consumer `TODO.md`, immutable producer
packets under `docs/producer/tasks/`, producer `config.json`, `index.tsv`,
`assignment.tsv`, and `NIGHTLY.md`, consumer execution records under
`docs/tasks/`, terminal receipts under `docs/consumer/receipts/`, and a local
ledger validator. Root cold-start instructions read policy, producer entrypoint,
selector result, then only the selected packet, board record, and routed policy.

The index and `next-ready` output are the sole current-disposition authority.
Published packet metadata is immutable creation-time context. Every nonterminal
index row appears exactly once in the human Queue table; terminal rows never do.
Priority, date, then ID define top-level order. In-scope findings are handled
LIFO inside the selected task and never allocate another durable goal.

## Ownership and lifecycle

Only the portfolio producer writes `PRODUCER.md` and `docs/producer/`. Consumers
write `TODO.md`, `docs/tasks/`, implementation paths, tests, and immutable
terminal receipts. Both roles run a base-relative diff guard that includes
untracked, nonignored paths. Producer and consumer changes use independent
branches and protected publications.

A ready packet grants only its bounded repository reads, edits, tests, and
declared normal publication. Consumers exhaust safe synthetic or parameterized
work before an owner gate: this is the safe-work-first rule. At a reversible owner choice, publish the partial
record, emit one value-free gate report, create no receipt, and let the producer
gate only that task. Resume by restoring its index/queue disposition; never
delete or rewrite a terminal receipt. Use a blocked receipt only for a durable
unavailable prerequisite or terminal blocked outcome.

A terminal receipt excludes its task from selection immediately. Until the
producer reconciles the disposition, only a client-compatible active assignment
may remain as a reconciliation-pending handoff. Strict convergence rejects that
intermediate state. After reconciliation, remove the queue row, mark the index
terminal, and idle an assignment with no compatible executable task.

## Efficiency and communication

Keep active execution records at or below 900 words: current facts, decisions,
gates, paths, validation, retry safety, next action, and required authority.
Move reproducible detail into tests or bounded artifacts. A deterministic local
proportional validation planner chooses record-only, focused, or complete checks and reuses focused
evidence only when target identity, environment contract, acceptance scope, and
owning checks are unchanged. Publication, policy, validator, lifecycle, safety,
credential, external-write, or unknown changes require complete validation.

When a managed consumer reports checkpoints, use one bounded value-free report
bound to a request ID. Exact accepted, changes-required, or rejected envelopes
never broaden scope. Accepted with a new request ID continues; accepted without
one acknowledges terminal completion and stops. Malformed, duplicate-with-
changed-bytes, or mismatched envelopes fail closed. Repositories without a
managed message route retain the lifecycle contract but need not install the
checkpoint parser.

## Project-specific layer

Do not place connector names, private paths, source values, student details,
research parameters, scheduler commands, deployment destinations, credentials,
or project authority in the generic scaffold. Add these only to target-local
routed policy. Public repositories also run a value-free privacy audit before
publication. Preserve stronger review, hosting, workflow, and deployment gates;
an approval requirement of zero is accepted policy unless the owner separately
authorizes changing it.

## Acceptance

- Cold start selects exactly one executable packet or idles.
- Queue/index parity, packet immutability, task IDs, assignment compatibility,
  active-record bounds, receipts, and strict convergence fail closed.
- Producer and consumer diff guards reject cross-role tracked and untracked
  changes.
- Reversible gates and terminal handoffs are covered by synthetic regressions.
- The target's focused and complete offline validation pass.
- Protected readback matches the candidate; temporary branches and worktrees
  are retired only after identity and merge verification.
