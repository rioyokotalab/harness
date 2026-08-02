# Productive-idle design for duration-bounded producer runs

## Decision

Adopt a pull-based, repository-isolated reserve queue for future nightly runs,
plus a first-class durable wait state. Do not try to guarantee that an agent is
busy for every minute of a requested window. Guarantee instead that every unit
of work was independently worth doing, selected without a writer conflict,
and stopped when its evidence or time budget was exhausted.

This is a design for a follow-up task, not a runtime change in Har-381. It does
not authorize a scheduler, daemon, consumer mutation, external message,
deployment, credential operation, or ruleset change.

## Demonstrated gap

Har-381 had a precise primary objective and a deliberately late publication
window. The substantive implementation, portfolio reconciliation, cleanup,
measurement, and closeout rehearsal were complete well before final
publication could begin. At 05:59 the candidate was 24 commits and 21 paths
above protected main, with 18 task-specific audit files, 4,487 words in the
hourly chronology, and 1,660 words in the compact active record. The duration
policy requires one evidence slice per requested hour, but it does not require
activity in every slice or repeated polling. The five repository-native
nightly protocols define a finite seven-step checklist and no reserve-work
selection or durable wait behavior. Once that checklist and the packet's
acceptance work were exhausted, the controller could only narrate a hold or
repeat mutable reads.

The problem is therefore workload admission and scheduling, not a lack of
checks. Adding more mandatory checks would increase the exact toil that the
nightly is meant to remove.

### Matched Har-381 baseline

Use the interval after exact checkpoint
`c50848382f1f3e8031b4ab921b421723f4cf49e8` as the replay baseline. Before the
owner redirected the run to this design, that interval produced three commits
touching only `time-slices.md`, with 58 insertions and one deletion. Runtime,
tests, packets, ledgers, and target state were unchanged. A deferred selector
should instead emit one wait checkpoint at queue drain, perform no early
mutable read, and wake at the predeclared finalization time. The 05:57 owner
input is then a changed event: invalidate the old one-shot wake revision,
reselect the new bounded design work, and preserve the already-complete target
state. This is a reproducible comparison, not a claim that all three evidence
commits were intrinsically valueless.

For planning, exclude the finalization reserve from available engineering
time. Define `coverage_expected` as admitted p50 active minutes divided by the
remaining pre-cutoff minutes and `coverage_conservative` using admitted p90
minutes. These are workload-supply indicators, not utilization targets. A
ratio below one prompts reserve admission or an explicit expected wait; it
never licenses low-value work. The retrospective observed queue-drain envelope
was roughly 195 minutes into a 420-minute pre-cutoff window, demonstrating why
the missing coverage should have been visible before execution even though
exact task duration could not be known.

## Evidence adopted

- Google SRE defines toil as manual, repetitive, automatable, tactical work
  without enduring value, and distinguishes engineering work by its permanent
  improvement. Its workbook recommends quantifying toil and using ROI, risk,
  and iterative development rather than automating every observed task.
  Sources: [Eliminating Toil](https://sre.google/sre-book/eliminating-toil/)
  and [Operational Efficiency](https://sre.google/workbook/eliminating-toil/).
- Python's queue contract separates retrieval from completion: every accepted
  item needs one completion signal before `join()` is satisfied, and immediate
  shutdown explicitly weakens that invariant. Adapt this as exact receipts for
  admitted reserve work; do not count a selected or started item as complete.
  Source: [Python asyncio queues](https://docs.python.org/3/library/asyncio-queue.html).
- Airflow pools bound parallelism, assign different slot costs to heavy and
  light tasks, and queue ready work by priority when capacity is full. Adapt
  the slot concept as repository/conflict keys and estimated cost, without
  importing Airflow as a dependency.
  Source: [Airflow pools](https://airflow.apache.org/docs/apache-airflow/stable/administration-and-deployment/pools.html).
- Airflow's deferrable operators suspend an idle task, release its worker slot,
  and resume from an event signal. Adapt the state transition, not the service:
  a Harness nightly should checkpoint and release active model execution while
  a lightweight wait controller owns only the wake signal.
  Source: [Airflow deferrable operators](https://airflow.apache.org/docs/apache-airflow/stable/authoring-and-scheduling/deferring.html).
- AWS recommends bounding queues and isolating workloads so one source cannot
  starve others. Its queue guidance also treats LIFO as a selective overload
  strategy, not a universal ordering rule. Adapt isolation per repository and
  keep LIFO only for nested issues inside the active card.
  Sources: [Avoiding insurmountable queue backlogs](https://d1.awsstatic.com/builderslibrary/pdfs/avoiding-insurmountable-queue-backlogs.pdf)
  and [fairness in multi-tenant systems](https://builder.aws.com/content/3Eupj3d2bo4fEvlzYbICMZNhQ3B/fairness-in-multi-tenant-systems).
- GitHub supports concurrency groups but scheduled workflows can be delayed or
  dropped under load. Retain local/durable control of owner-started nightlies;
  hosted Actions remain a validation backstop, not the timing controller.
  Sources: [workflow concurrency](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency)
  and [scheduled workflow behavior](https://docs.github.com/en/actions/how-tos/troubleshoot-workflows#scheduled-workflows-running-at-unexpected-times).
- Kubernetes CronJobs make overlap and missed-start policy explicit through
  `concurrencyPolicy` and `startingDeadlineSeconds`. Adapt those two semantics
  to one producer lease and a declared latest-start time for reserve cards.
  Source: [Kubernetes CronJob API](https://kubernetes.io/docs/reference/kubernetes-api/batch/cron-job-v1/).

These sources support bounded queues, exact completion, workload isolation,
explicit concurrency, and engineering-over-toil. They do not prove that any
particular reserve task is valuable; each card still needs local evidence.

## Proposed run model

### 1. Admission before `go`

The producer creates a value-free run manifest after planning and before target
execution. It contains the mandatory packet plus independently optional reserve
cards. A card is admitted only if it has:

- repository and privacy class;
- objective, evidence predicate, and expected enduring value;
- mutation class and already-authorized boundary;
- exact writer/conflict key and prerequisite state;
- estimated active minutes and latest safe start;
- benchmark, acceptance, validation, and stop condition;
- expiry or supersession rule.

Use two estimates rather than a false-precision point value: expected active
minutes and a conservative p90 bound derived from comparable receipts or a
declared first-run assumption. Report `coverage_expected` and
`coverage_conservative` before `go`; do not reject a valid run merely because
the reserve queue is short. A card starts only when its p90 active time plus
its validation and publication p90 fits before the material cutoff and buffer.

Estimated reserve coverage should reach the material cutoff when real
opportunities exist. A short queue is reported honestly; it is never padded
with polling, revalidation, generic cleanup, or speculative goal creation.

### 2. Four pull lanes

1. **Mandatory:** execute the frozen packet and task-owned LIFO findings.
2. **Ready reserve:** pull the highest-value card whose repository, authority,
   conflict key, and remaining-time checks pass.
3. **Bounded discovery:** if reserve is empty, perform at most one structural
   opportunity scan per repository and one cross-portfolio synthesis. This
   lane may measure a bottleneck or draft a producer proposal; it may not
   inspect private payload for a public report or invent an implementation
   merely to occupy time.
4. **Durable wait/finalize:** if no card remains, write one wait checkpoint
   with `wake_at`, `wake_on`, and `finalize_at`. Recheck only when a named
   mutable input expires or an event occurs. Hourly slices record the wait as
   one concise evidence delta, not fabricated activity.

The wait controller must never own repository, tmux, app-server, or external
service mutation. It stores only run identity, checkpoint revision, `wake_at`,
event keys, and a one-shot resume token. On wake, the producer resumes the
saved task, reconciles durable state, and reselects; it does not replay the
last prompt. If a product-native recurring wait is available, prefer it. A
shell sleep loop is not the target architecture because it occupies a client,
has weak recovery semantics, and encourages narration without decisions.

A wait transition is allowed only after the current atomic action is terminal,
the branch is clean and remotely checkpointed, no external write is ambiguous,
and the task record names its wake conditions. Store requested timezone and an
UTC instant; use monotonic time only for in-process intervals. Duplicate or
late wake signals compare the one-shot token and checkpoint revision, then
either no-op or enter finalization. A wake after the card's latest safe start
cannot begin that card.

Lanes are monotonic for one run except that a changed input may make a
previously declared reserve card ready. Discovery cannot recursively create
more discovery during the same night.

### 3. Isolation and fairness

Use one producer lease for producer-owned paths and one conflict key per
repository/worktree/external surface. Only one mutation card may hold a given
key. Cards from Personal or Students remain in those repositories; Harness
stores only value-free portfolio status. Selection should round-robin among
repositories at equal priority so a large Swallow or Harness backlog cannot
starve another project. Task-local defects remain LIFO because they affect the
active acceptance path; independent reserve cards remain priority ordered.

Deterministic ordering is mandatory before fairness: primary status, integer
priority, least-recently-selected repository among ties, earliest expiry, then
opaque card ID. The cross-portfolio manifest must not contain a private title,
path, evidence excerpt, or task body. It may contain only repository, opaque
card ID, privacy class, mutation class, conflict key, p50/p90 minutes, and
disposition. The selected repository's own producer packet carries its detail.

### 4. Time and evidence budgets

Reserve work starts only when `estimate + validation + closeout buffer` fits
before the material cutoff. Preserve at least the larger of 60 minutes or 15%
of the requested window for integration and handoff. A card that exceeds its
estimate by 50% must checkpoint and re-admit its remainder rather than consume
the portfolio silently. Cache immutable validation receipts. Mutable reads
carry an explicit freshness lifetime or event key; the same read cannot be
repeated early merely to make a new progress message.

Each hourly duration slice should contain only decisions and changed evidence.
The proportional summary minimum applies to the complete run, not to every
slice individually. Command count, active minutes, wait minutes, reserve hit
rate, estimate error, repeated-read count, and enduring artifacts become the
efficiency benchmark.

The current 60-second progress expectation should apply while commands,
research, validation, or an unresolved decision are actively advancing. Once
the durable wait transition succeeds, there is no active worker operation to
narrate. The wait controller should emit only a start checkpoint, named wake
reason, and resume checkpoint. If the product requires a heartbeat, it should
be machine-generated and value-free rather than consume model turns.

### 5. Anti-make-work constraints

A reserve card is invalid when its only acceptance is elapsed time, command
count, commit count, prose volume, repeated observation, or creation of more
cards. Splitting one objective into multiple cards does not increase coverage;
cards sharing an evidence predicate and enduring output are one unit. A due
scan that finds no issue may close `no-change`, but the same predicate cannot
run again in that night. Discovery may propose at most three future cards and
cannot select its own proposals until a later producer freeze.

An enduring output is one of: accepted code/test/policy improvement; a measured
decision that adopts, adapts, experiments, rejects, or leaves unresolved a
specific option; a terminal receipt that changes executable queue state; or a
bounded owner decision packet. Progress narration, a fresh timestamp, and an
unchanged read are evidence transport, not outputs.

Autonomy comes from freezing card authority classes with the owner's initial
`go`, not from asking at every pull. Efficiency comes from returning one packet
path and reusing freshness receipts, not from loading every catalog. Safety is
then enforced at the card boundary through immutable scope, conflict keys,
latest start, privacy class, and exact receipts. Missing authority remains a
blocked disposition and never becomes a reason to spend the remaining window.

## Minimal repository-native shape

Do not add a heavyweight workflow engine. Extend the existing producer tool
with a small run-manifest schema and three commands:

- `nightly-plan --until ...` validates the primary packet and admitted cards,
  conflict keys, authority classes, estimates, and finalization reserve.
- `nightly-next --remaining-minutes ...` returns one ready card or an exact
  wait/finalize state without requiring the agent to read unrelated packets.
- `nightly-receive` accepts one completion, blocked, skipped, or interrupted
  receipt and enforces one terminal disposition for every pulled card.

Keep the implementation separate from the 317-line task-ledger selector during
the pilot. The current task tool and its 370-line unit suite protect durable
goal allocation and lifecycle convergence; reserve-card selection is a
different state machine and should not enlarge that trusted surface until the
pilot proves a common abstraction. A small `tools/nightly-queue.py` can share
only strict metadata helpers after equivalence tests exist.

The writer-compatible layout is:

```text
docs/producer/nightly/
├── index.tsv                 # bounded persistent reserve catalog
├── cards/<opaque-id>.md      # immutable repository-local card
└── runs/<run-id>.tsv         # immutable admitted-card manifest
docs/consumer/nightly-receipts/<run-id>/<opaque-id>.md
docs/audits/<run-id>/         # execution benchmark and value-free summary
```

The catalog and admitted manifest are producer-owned and are frozen before
target execution. The consumer-side executor writes only receipts and task
evidence. Final producer reconciliation closes the run disposition without
rewriting card or manifest bytes. This mirrors the already-proven task packet
and receipt lifecycle instead of creating a second mutable shared board.

Dedicated Personal and Students consumers remain idle during a producer
nightly and never pull reserve cards. Cards are executed by the sole producer
in isolated repository-native worktrees. A finding that deserves later
consumer implementation is promoted at final reconciliation into a normal
durable task, rather than injected into a sleeping consumer's board.

Each repository owns its detailed cards and byte-binding digests. Harness's
public portfolio manifest contains only repository, opaque run/card token,
class, p50/p90 minutes, and disposition; it never stores a private packet
digest that could become a dictionary oracle. Persistent catalogs are capped at
12 open cards per repository; a thirteenth requires completing, expiring, or
superseding an existing card. The ordinary producer cycle replenishes catalogs
from demonstrated findings. An empty catalog is valid and cannot be treated as
permission to generate work recursively.

To avoid a producer PR in every repository before every night, cards live in
protected state before selection. The one Harness preparation transition
freezes the public portfolio run manifest by opaque ID only. Each private
repository's local selector binds its protected packet and base bytes in that
repository's own evidence. On execution, the producer opens only the selected
repository-local card and revalidates its named predicate. A card absent from
protected state at freeze time is not executable that night.

Repository-local cards and receipts remain private to their repositories. A
Harness portfolio manifest contains only repository, opaque card ID, class,
minutes, conflict key, and disposition. The selector must be deterministic and
side-effect free. No service, dependency, or hosted scheduler is required.

Cards are run-scoped IDs, not durable repository task IDs. Completion removes
them from the run manifest through a receipt; interruption or demonstrated
future value may cause the sole producer to promote one into the next durable
task during final reconciliation. This prevents a nightly from flooding
`TODO.md` merely because it explored alternatives. Producer changes selected
within one repository should share at most one producer publication candidate
for that night, but producer and consumer writer surfaces remain separate.

The default catalog accepts only `read-only`, `repository-local`, and ordinary
protected-publication cards already covered by the run's frozen authority.
Credentials, account/hosting settings, deployments, external messages,
consumer-runtime mutation, destructive remote operations, and any owner gate
are never reserve work merely because time remains. They may appear only as a
blocked observation or as a separately frozen primary objective.

Estimate calibration stays deliberately simple. A first-run card declares p50
and uses at least twice p50 as p90 unless direct matched evidence supports a
tighter bound. After five comparable terminal receipts, use observed median
and empirical p90, excluding explicitly recorded deferred intervals. An
estimate may not shrink before that sample count. Receipt timestamps use UTC
and requested timezone; active minutes include validation and local tool wait,
but exclude a successful durable deferral.

Conflict keys may represent shared capacity as well as one repository writer.
For example, independent repository analysis can proceed concurrently, while
hosted validation, archive-heavy I/O, or one protected repository writer can
have capacity one. Keys are opaque in the public portfolio manifest. The pilot
starts sequentially; parallel reserve execution is a later optimization only
if receipts prove enough work and non-overlap to repay dispatch and review.

Selection pseudocode is intentionally small: verify the local manifest and
packet digest inside its owning repository; exclude terminal receipts;
evaluate built-in named predicates against freshness receipts; reject expired,
unauthorized, stale-base, privacy-unsafe, or held-conflict cards; enforce
latest safe start; then sort by primary flag, priority, repository fairness
age, expiry, and opaque ID. If no card survives, consume the one bounded
discovery allowance or return the exact wait state. No card supplies a shell
command or executable predicate from Markdown.

## Validation experiment

Run one matched two-night pilot before changing all five protocols:

1. Replay Har-381's recorded timeline through the selector without executing
   target mutations. Assert that the 04:15 queue drain yields one durable wait,
   not repeated checks.
2. Seed synthetic cards covering ready, gated, expired, conflicting,
   too-large, private, and authority-blocked cases. Assert deterministic
   selection, privacy isolation, no starvation at equal priority, and exact
   terminal receipts.
3. Compare current and proposed protocols on active minutes, repeated mutable
   reads, commentary/checkpoint count, routed bytes, command count, validation
   time, and accepted enduring outputs.
4. Require no regression in cold recovery, writer boundaries, approval gates,
   protected publication, guarded cleanup, or the ability to stop at a
   material cutoff.
5. Adopt across repositories only if the pilot reduces repeated reads and
   narration while preserving or improving accepted outputs and routed
   context. Otherwise retain the current protocol and the design as evidence.

The normative scenario table is `productive-idle-scenarios.tsv`. At minimum,
a prototype must satisfy all 16 rows, including changed owner input, stale
target state, p90 overrun, private metadata rejection, exact completion
receipts, and the distinction between task-local LIFO and portfolio fairness.

## Alternatives

- **Add more fixed checks — reject.** It guarantees activity but creates
  repetitive work without a changed input or enduring value.
- **Allow unrestricted autonomous discovery — reject.** It creates goal sprawl,
  privacy risk, and unpredictable publication scope.
- **Run producer consumers in parallel — experiment later.** Repository
  isolation helps, but concurrent producer writers would conflict with the
  sole-writer contract and are unnecessary to solve queue exhaustion.
- **End immediately when mandatory work is complete — adapt.** This is correct
  when the owner requests an upper bound. For an explicit until-time request,
  retain the durable wait/finalization state and pull only admitted valuable
  work.
- **Adopt a general workflow platform — reject for now.** The required state is
  small, Git-native, and already validated locally; a service would increase
  operational surface and credentials without demonstrated benefit.

## Follow-up disposition

Publish this design as a separate bounded producer task after Har-381 closes.
The implementation task should be allocated after Har-382, use a matched
Har-381 replay as its benchmark, modify Harness first, and require an explicit
pilot result before any sibling protocol rollout.
