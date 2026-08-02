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
finalization reserve, mandatory and reserve p50/p90, uncovered expected
minutes, repository representation, and authority/conflict classes. One
bounded structural opportunity scan is allowed before `go`; a remaining gap is
reported as expected wait, never padded.

After exact owner `go`, `nightly-admit --run ...` may write only a subset of
cards from the reviewed protected catalog revision. It records catalog OID and
selected packet blob IDs. Selection refuses an uncommitted or dirty manifest.
After the first commit that adds the manifest, its current blob must equal the
first-add blob. A card added after `go`, or changed/removed afterward, is not
substituted. A later protected-head change may continue only if selected packet
bytes remain identical and the named target predicate still passes.

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
validation/publication buffer does not fit before latest start. Sort by primary
flag, integer priority, least-recently-selected repository among ties, earliest
expiry, then opaque ID. Task-local defects remain LIFO; independent portfolio
opportunities do not.

`nightly-next` emits one packet path or exact wait/finalize state and at most
1,024 bytes before that packet is read. `nightly-receive` accepts one complete,
no-change, blocked, skipped, or interrupted receipt for each pulled instance.
Selection is never completion. The same predicate cannot run twice in one
night after a no-change receipt.

Cards may use only read-only, repository-local, or ordinary protected
publication authority already frozen for the run. Credentials, account or
hosting settings, deployments, messages, consumer mutation, destructive remote
operations, and owner gates are never reserve work.

## Time, freshness, and wait

Reserve at least the larger of 60 minutes or 15% of the window for finalization.
A first-run p90 is at least twice p50 unless matched evidence supports less. Do
not reduce estimates until five comparable terminal receipts exist. A 50%
overrun checkpoints and readmits remaining work. Active minutes include local
tools and validation but exclude successful durable deferral.

Freshness receipts contain input key, value-free identity, observation and
expiry times, and supported decision. Immutable bytes reuse exact OIDs;
mutable state uses a declared TTL or cheap event/revision key. Never rerun an
expensive report merely to discover whether its input changed.

A wait begins only from a clean remotely checkpointed branch, with no ambiguous
write and explicit UTC/requested-timezone `wake_at`, `wake_on`, `finalize_at`,
checkpoint revision, and one-shot token. Duplicate or late wakes no-op or enter
finalization. A wake after latest start cannot launch the card. The pilot tests
this state machine but starts no live controller.

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
normative data. All 19 scenarios and all 18 measures must pass, including the
matched replay from checkpoint `c508483`, zero early duplicate reads, no more
than one wait checkpoint, unchanged always-read bytes, zero billable Actions
increase, no extra protected transition, no value exposure or writer violation,
p95 at most 100 ms over 60 synthetic cards, and complete Harness validation.
