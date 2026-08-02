# Productive-idle pilot contract

This is the complete Har-383 execution contract. The longer
`productive-idle-design.md` preserves rationale and source provenance but is
lookup-only; do not preload it unless a contract decision is disputed.

## Outcome and non-goals

Build a synthetic Harness-only selector that makes a duration run pull one
independently valuable, preauthorized opportunity or return one durable wait.
It must replace repeated checks and narration without reducing accepted output,
privacy, writer separation, cold recovery, or final validation.

Har-383 does not activate the design. It must not modify `docs/producer/` or
live `NIGHTLY.md` behavior, create a catalog, start a scheduler/wait controller,
touch siblings or consumer runtimes, perform external writes, or allocate a
rollout. Producer reconciliation may queue a later Harness rollout only after
the synthetic pilot passes.

## Repository-local model

Persistent opportunity packets are producer-created, protected, and capped at
12 open entries per repository. They are templates, not durable task IDs. A
run admission is an instance `(run-token, opportunity-id)` and is stored only
inside that repository:

```text
docs/producer/nightly/index.tsv
docs/producer/nightly/cards/<opaque-opportunity-id>.md
docs/audits/<run-token>/admissions.tsv
docs/audits/<run-token>/events.tsv
docs/consumer/nightly-receipts/<run-token>/<opaque-id>.md
```

Public Harness stores no private card row, token, digest, timing, conflict key,
or disposition. A live controller may receive only value-free ready/idle/block
status. Private bytes and all byte-binding evidence remain in their repository.

The pilot uses temporary synthetic fixtures only. Keep its selector separate
from `producer-ledger.py`; share strict helpers later only if equivalence and a
measured reduction justify a refactor.

## Admission and immutability

`nightly-plan --until ...` is read-only. It reports requested window,
finalization reserve, mandatory and reserve p10/p50/p90, lower-tail and
expected minutes, repository representation, authority/conflict classes, and
one of `covered`, `shortfall`, or `planned-wait`. p50 estimates expected supply,
p10 signals early-exhaustion risk but is not a probabilistic portfolio
guarantee, and p90 guards latest start and cutoff;
p90 must never be reported as conservative supply. Only cards whose predicate is ready
and whose authority, conflict, privacy, and time-fit checks currently pass
contribute coverage. One
bounded structural opportunity scan is allowed before `go`; a remaining gap is
reported as expected wait, never padded.

Reserve supply is maintained before the night, not invented inside it. At each
ordinary producer reconciliation, consider at most one evidence-backed catalog
opportunity. When the owner asks to prepare a duration run, the bounded pre-run
scan may propose at most three additional opportunities across the portfolio;
publish them through their repository's normal producer workflow only under
existing authority, then freeze the plan. In-run discovery proposals cannot be
executed until a later producer cycle.

After exact owner `go`, `nightly-admit --run ...` may write only a subset of
cards from the reviewed protected catalog revision. To reduce avoidable queue
exhaustion, it admits every currently eligible, independently valuable card up
to the 32-card run cap; reaching expected p50 coverage is not a stopping rule.
It records catalog OID and selected packet blob IDs. Selection refuses an
uncommitted or dirty manifest.
After the first commit that adds the manifest, its current blob must equal the
first-add blob. A card added after `go`, or changed/removed afterward, is not
substituted. A later protected-head change may continue only if selected packet
bytes remain identical and the named target predicate still passes.

Catalog, card, manifest, event, and receipt schemas are closed. Require regular
non-symlink, non-executable files; bounded bytes; unique identities; exact
fields; repository-local relative paths; and no sensitive metadata keys or
public privacy canaries. Reject unknown fields, duplicate IDs/receipts, unsafe
types, oversized content, arbitrary executable predicates, and overwrite of an
existing admission or receipt. Fixture writes are atomic and interruption
tests cover failure before and after publication.

Owner input arriving during a wait is an exact task amendment, not a manifest
rewrite or reusable card. It invalidates the one-shot wait token. Finish or
safely checkpoint any current atomic action first, and reconcile an ambiguous
external write before reselecting. Never replay the previous prompt.

## Selection and execution

The four monotonic lanes are mandatory work, ready reserve, one bounded
discovery pass, and durable wait/finalization. A changed named input may make a
frozen card ready; discovery cannot execute its own proposals that night.

For eligible cards, reject terminal receipts, expired or unauthorized scope,
stale targets, privacy violations, held conflict keys, and cards whose p90 plus
validation/publication buffer does not fit before latest start. Mandatory work
precedes reserve. The portfolio controller rotates over repositories that
return only ready/idle/block; inside the chosen repository, its local selector
sorts by integer priority, earliest expiry, then opaque ID. Card priority,
expiry, timing, conflict key, and identity never cross into public Harness.
The rotation cursor is private ephemeral controller state and cannot be
committed to public Harness. Task-local defects remain LIFO; independent
portfolio opportunities do not.

`nightly-next` emits one candidate identity or exact wait/finalize state.
`nightly-start --expected-candidate ...` revalidates that candidate, atomically
appends one `selected` event, and emits its packet path. Together they route at
most 1,024 bytes before that packet is read. Before target action, the
controller must durably checkpoint the event. An unresolved selected
event is the only resumable card: recovery reconciles its exact target state
and records `interrupted` or a terminal receipt before another selection. It
never invokes the target action again merely because the receipt is absent.
`nightly-receive` accepts one complete, no-change, blocked, skipped, or
interrupted receipt for each selected instance. An exact retry is an idempotent
no-op; a changed duplicate is rejected. Selection is never completion. The
same predicate cannot run twice in one night after a no-change receipt.

Selection is work-conserving within the frozen scope: it may return wait only
when no eligible card fits. It recalculates remaining p50/p90 coverage after
every terminal receipt because a completed card may change another card's
predicate. A shortfall discovered after `go` changes the forecast to
`planned-wait`; it does not admit late work.

Cards may use only read-only, repository-local, or ordinary protected
publication authority already frozen for the run. Credentials, account or
hosting settings, deployments, messages, consumer mutation, destructive remote
operations, and owner gates are never reserve work.

## Time, freshness, and wait

Reserve at least the larger of 60 minutes or 15% of the window for finalization.
A first-run p90 is at least twice p50 unless matched evidence supports less. Do
not reduce p90 until 20 comparable terminal receipts exist. Five receipts may
calibrate p50; empirical p10/p90 require 20. A card without matched lower-tail
evidence contributes zero to the lower-tail indicator and is labeled unknown.
A 50%
overrun checkpoints and readmits remaining work. Active minutes include local
tools and validation but exclude successful durable deferral.

Freshness receipts contain input key, value-free identity, observation and
expiry times, and supported decision. Immutable bytes reuse exact OIDs;
mutable state uses a declared TTL or cheap event/revision key. Never rerun an
expensive report merely to discover whether its input changed.

A wait begins only from a clean remotely checkpointed branch, with no ambiguous
write and explicit UTC/requested-timezone `wake_at`, `wake_on`, `finalize_at`,
checkpoint revision, and one-shot token. Duplicate or late wakes no-op or enter
finalization. Finalization is one-way: after it begins, reserve work cannot
restart. A wake after latest start cannot launch the card. The pilot tests this
state machine but starts no live controller.

## Anti-make-work and progress

Reject cards accepted only by elapsed time, commands, commits, prose, repeated
reads, generic cleanup/search, or creation of more cards. Splitting one
predicate/output does not create coverage. Discovery may propose at most three
future cards and cannot execute them before a later producer freeze.

Valid outputs are accepted code/test/policy improvement, a measured decision,
a terminal queue-changing receipt, or a bounded owner decision packet.
Progress messages correspond to state transitions or active long work. A
durable wait produces no model-authored heartbeat. One concise unchanged-wait
sentence is sufficient for its hourly evidence slice.

## Pilot acceptance

Use `productive-idle-scenarios.tsv` and `productive-idle-acceptance.tsv` as
normative data. All 27 scenarios and all 24 measures must pass, including the
matched replay from checkpoint `c508483`, zero early duplicate reads, no more
than one wait checkpoint, unchanged always-read bytes, zero billable Actions
increase, no extra protected transition, no value exposure or writer violation,
p95 at most 100 ms over 60 synthetic cards, crash-safe selection recovery,
honest shortfall reporting, and complete Harness validation.
