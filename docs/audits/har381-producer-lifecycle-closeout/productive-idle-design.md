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
remaining pre-cutoff minutes and a lower-tail indicator from admitted p10 minutes.
Use p90 only as an upper-tail overrun and latest-start guard; calling p90
conservative supply reverses the risk because long-tail cards can also finish
very early. Summed per-card quantiles are not a probabilistic portfolio
guarantee, so unknown p10 contributes zero and remains visibly unknown. These
are workload-supply indicators, not utilization targets. A
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

The producer creates a repository-local run manifest after planning and before
target execution. It contains that repository's mandatory packet plus
independently optional reserve cards. A card is admitted only if it has:

- repository and privacy class;
- objective, evidence predicate, and expected enduring value;
- mutation class and already-authorized boundary;
- exact writer/conflict key and prerequisite state;
- estimated active minutes and latest safe start;
- benchmark, acceptance, validation, and stop condition;
- expiry or supersession rule.

Use three estimates rather than a false-precision point value: lower-tail p10,
expected p50, and upper-tail p90 active minutes derived from comparable
receipts. A first-run p10 is zero unless matched evidence establishes a floor;
p90 is at least twice p50 unless matched evidence supports less. Report
the lower-tail indicator, `coverage_expected`, and the upper-tail overrun envelope
before `go`; do not reject a valid run merely because the reserve queue is
short. A card starts only when its p90 active time plus its validation and
publication p90 fits before the material cutoff and buffer.

Estimated reserve coverage should reach the material cutoff when real
opportunities exist. A short queue is reported honestly; it is never padded
with polling, revalidation, generic cleanup, or speculative goal creation.

The owner-facing proposal should show one compact coverage table: requested
window, finalization reserve, mandatory and reserve p10/p50/p90, uncovered
floor and expected minutes, repositories represented, and authority/conflict classes.
It labels the result `covered`, `shortfall`, or `planned-wait`. Only cards that
are ready and currently pass authority, privacy, conflict, and time-fit checks
contribute to either coverage sum; blocked or merely discoverable work counts
as zero. Recompute the forecast after each terminal receipt because target
changes can invalidate another admitted card.
Private card titles remain in their repositories. Admission includes every
currently eligible, independently valuable card up to the 32-card run cap; it
does not stop merely because summed p50 reaches the window. This keeps extra
reserve available without loading its packets into context. If coverage is short, the
producer automatically performs the one allowed pre-run opportunity scan and
then reports the remaining expected wait. It does not require a second owner
answer when the original duration is firm, but it does not claim to be fully
loaded either.

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

The selector is work-conserving inside the frozen manifest: it cannot return a
wait while an eligible card fits the remaining envelope. This is not a promise
of full utilization. If readiness changes consume the forecast after `go`, the
run reports `planned-wait` and does not backfill from a late card.

### 3. Isolation and fairness

Use one producer lease for producer-owned paths and one conflict key per
repository/worktree/external surface. Only one mutation card may hold a given
key. Cards from Personal or Students remain in those repositories; Harness
stores only value-free portfolio status. After mandatory work, the controller
round-robins over repositories whose local selector returns ready. Inside the
chosen repository, cards sort by integer priority, earliest expiry, then opaque
ID. This prevents a large Swallow or Harness backlog from starving another
project without exporting private priority or timing. Task-local defects remain
LIFO because they affect the active acceptance path; independent reserve cards
remain locally priority ordered.

There is no cross-portfolio card manifest in public Harness. Each repository
selector returns only value-free ready/idle/block to the active controller;
private title, identity, priority, path, timing, conflict key, evidence, packet
digest, and disposition stay in the owning repository. The rotation cursor is
private ephemeral controller state, never a public Harness ledger row. Cold
recovery may restart the fixed ring without exposing prior private selections;
the per-repository unresolved-event rule still prevents target replay.

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

Good reserve candidates are narrow and predicate-driven: remove one measured
source of repeated operator work; prototype one validator or selector
optimization against a frozen baseline; compact one demonstrated routed-byte
regression; prepare one decision packet for a due event gate; add a regression
test for one reproduced failure class; or run a public-content delta audit
after the protected head changes. “Search broadly,” “check again,” “find more
tasks,” and “clean everything” are not cards without a hypothesis, bound,
independent value, and stopping condition.

## Minimal repository-native shape

Do not add a heavyweight workflow engine. Add a separate pilot tool with a
small admission schema and five commands:

- `nightly-plan --until ...` read-only reports eligible catalog coverage,
  conflict classes, authority classes, estimates, and finalization reserve.
- `nightly-admit --run ...` writes an execution manifest after `go`, binding a
  subset of already-protected producer cards and their exact catalog revision.
- `nightly-next --remaining-minutes ...` returns one candidate identity or an
  exact wait/finalize state without reading unrelated packets.
- `nightly-start --expected-candidate ...` revalidates the candidate, appends
  its selection event atomically, and returns the packet path; target work is
  forbidden until that event is durably checkpointed.
- `nightly-receive` accepts one completion, blocked, skipped, or interrupted
  receipt and enforces one terminal disposition for every pulled card.

Keep the implementation separate from the 317-line task-ledger selector during
the pilot. The current task tool and its 370-line unit suite protect durable
goal allocation and lifecycle convergence; reserve-card selection is a
different state machine and should not enlarge that trusted surface until the
pilot proves a common abstraction. A small `tools/nightly-queue.py` can share
only strict metadata helpers after equivalence tests exist.

The writer-compatible layout distinguishes persistent local opportunities from
their run-scoped admission instances, independently in every repository:

```text
each repository/
├── docs/producer/nightly/index.tsv
├── docs/producer/nightly/cards/<opaque-opportunity-id>.md
├── docs/consumer/nightly-receipts/<run-token>/<opaque-id>.md
├── docs/audits/<run-token>/admissions.tsv
└── docs/audits/<run-token>/events.tsv
```

Repository-local catalogs are producer-owned and protected before planning.
After owner `go`, the sole producer creates the execution manifest on the
active task branch; strict validation permits only an exact subset of the
frozen catalog revision and makes the manifest immutable after its first
commit. The executor then writes local run-instance receipts and task evidence.
Final producer reconciliation is needed only to promote, add, expire, or
supersede catalog opportunities. This preserves producer-owned goal creation
without requiring a receipt-only preparation PR for every participating repo.

Immutability is Git-derived rather than asserted by a second mutable file. The
admission command records the protected catalog OID and selected packet blob
IDs. `nightly-next` refuses an uncommitted or dirty manifest. Once committed,
validation locates the first-add commit for that path and requires the current
blob to match it exactly. A card added after the frozen catalog OID is never
admissible. A later protected-main change may proceed only when each selected
packet blob remains identical and its target predicate is freshly valid; a
changed or removed card is skipped, never silently substituted.

Dedicated Personal and Students consumers remain idle during a producer
nightly and never pull reserve cards. Cards are executed by the sole producer
in isolated repository-native worktrees. A finding that deserves later
consumer implementation is promoted at final reconciliation into a normal
durable task, rather than injected into a sleeping consumer's board.

Each repository owns its detailed cards, admission rows, byte-binding digests,
timing, and receipts. Public Harness stores no private card or admission row at
all—not even a digest or count. Persistent catalogs are capped at 12 open cards
per repository; a thirteenth requires completing, expiring, or superseding an
existing card. The ordinary producer cycle replenishes catalogs from
demonstrated findings. An empty catalog is valid and cannot be treated as
permission to generate work recursively.

Replenishment is delta-routed. The ordinary producer cycle may read the current
consumer receipt's optional promotion slot plus validator or efficiency
receipts changed since a repository-local producer watermark. It may open at
most one directly linked evidence artifact per proposed card. It does not sweep
unrelated task history, branches, worktrees, `/tmp`, fleet state, or the web
merely because coverage is short. An absent promotion slot closes no-change.
This lets a consumer report one bounded opportunity without allocating a goal,
while the producer remains the only writer that can promote it into the
protected catalog.

Cards live in protected state before selection. `nightly-admit` can select only
cards that existed at the exact protected catalog revision reviewed before
`go`; it cannot create a packet, change authority, or admit a later catalog
row. On execution, the producer opens only the selected local card and
revalidates its named predicate. This gives later rollout zero mandatory
preparation transitions while keeping new goals and reusable opportunities on
the producer-only surface.

Repository-local cards, manifests, and receipts remain private to their
repositories. Candidate calculation must be deterministic and side-effect
free; only `nightly-start` writes the atomic selection event. No service,
dependency, or hosted scheduler is required.

Catalog entries are bounded opportunity templates, not durable repository task
IDs. Admission creates a run-scoped `(run-token, opportunity-id)` instance.
The immutable manifest never removes a row; one exact local receipt makes that
instance terminal and selector-ineligible. The underlying opportunity remains
available only when its named predicate changes or freshness expires.
Interruption or demonstrated future value may cause the sole producer to
promote one instance into the next durable task during final reconciliation.
This prevents a nightly from flooding `TODO.md` merely because it explored
alternatives. Producer changes selected within one repository should share at
most one producer publication candidate for that night, but producer and
consumer writer surfaces remain separate.

The default catalog accepts only `read-only`, `repository-local`, and ordinary
protected-publication cards already covered by the run's frozen authority.
Credentials, account/hosting settings, deployments, external messages,
consumer-runtime mutation, destructive remote operations, and any owner gate
are never reserve work merely because time remains. They may appear only as a
blocked observation or as a separately frozen primary objective.

Estimate calibration stays deliberately simple. A first-run card declares p50,
has unknown p10 represented as zero in the lower-tail indicator, and uses at
least twice p50 as p90 unless direct matched evidence supports tighter bounds.
Five comparable receipts may calibrate the median. Empirical p10 and p90 need
at least 20 comparable receipts, excluding explicitly recorded deferred
intervals; p90 may not shrink before that sample count. Summed card quantiles
remain labeled indicators, not a calibrated aggregate confidence interval.
Receipt timestamps use UTC
and requested timezone; active minutes include validation and local tool wait,
but exclude a successful durable deferral.

Freshness receipts carry `input_key`, value-free identity, observation time,
expiry, and the acceptance decision they supported. Immutable Git bytes reuse
the exact OID; hosted or filesystem state uses a declared TTL or event key.
Computing a full expensive report merely to learn whether its input changed is
not reuse: each integration needs a cheap generation, revision, or status
identity. Har-383 should model this boundary synthetically rather than invent a
generic production freshness registry during its first pilot.

Conflict keys may represent shared capacity as well as one repository writer.
For example, independent repository analysis can proceed concurrently, while
hosted validation, archive-heavy I/O, or one protected repository writer can
have capacity one. Keys remain repository-local; a selector exposes only a
value-free held/free result to the live controller and no key is tracked in
public Harness. The pilot starts sequentially; parallel reserve execution is a
later optimization only if receipts prove enough work and non-overlap to repay
dispatch and review.

Selection pseudocode is intentionally small: verify the local admission
manifest, opportunity packet, and digest; exclude terminal run-instance
receipts; evaluate built-in named predicates against freshness receipts;
reject expired, unauthorized, stale-base, privacy-unsafe, or held-conflict
cards; enforce latest safe start; then sort by primary flag, priority,
expiry, and opaque ID inside that repository. The private controller ring
chooses among repositories that report ready; local priority never enters a
cross-repository sort. If no card survives, consume the one bounded discovery
allowance or return the exact wait state. No card supplies a shell command or
executable predicate from Markdown.

Selection also needs a crash boundary. `nightly-start` appends a `selected`
event to `docs/audits/<run-token>/events.tsv`; the controller checkpoints it
durably before target action. A run with one unresolved selected event cannot
select another card.
On cold recovery, reconcile the named card's exact target state and then write
an interrupted or terminal receipt; absence of a receipt is not permission to
repeat the action. An exact duplicate receipt request returns the existing
receipt as an idempotent no-op, while a payload mismatch is rejected. This
small event journal resolves the tension between pure candidate calculation
and at-most-once mutation: candidate calculation stays read-only, but execution
cannot begin until its selection event is durable.

The event journal is append-only rather than merely schema-valid. Every update
must preserve the previous committed blob as an exact prefix and append one
complete row with the next sequence number. Truncation, replacement, insertion,
duplicate selection, or non-fast-forward ancestry fails before target action.
Receipts are immutable after first atomic publication. This gives cold recovery
evidence that an unresolved selection was not erased locally to make a replay
appear eligible.

## Owner and progress experience

Progress messages correspond to state transitions: plan frozen, card selected,
card terminal, durable wait entered, wake reason observed, finalization begun,
or blocker requiring owner action. A long validation still receives ordinary
progress updates. A durable wait does not generate model-authored “still
waiting” prose. The final summary retains exactly one evidence-backed slice per
requested hour, but a deferred hour can be one sentence naming the unchanged
wake contract.

If owner input arrives during a wait, it becomes an exact task amendment and
invalidates the one-shot wait token; the immutable producer manifest is not
rewritten from the consumer surface. The amended work is bounded direct owner
input, not a reusable reserve card, and final producer reconciliation decides
whether any follow-up belongs in a later catalog. If input arrives during a
repository-local atomic action, finish or safely checkpoint that action first,
then replan. If it arrives after an ambiguous external write, reconcile the
write before selection. In no case does an amendment cause the previous prompt
to be replayed.

## Validation experiment

Run one matched two-night pilot before changing all five protocols:

1. Replay Har-381's recorded timeline through the selector without executing
   target mutations. Assert that the 04:15 queue drain yields one durable wait,
   not repeated checks.
2. Seed synthetic cards covering ready, gated, expired, conflicting,
   too-large, private, and authority-blocked cases. Assert deterministic
   selection, privacy isolation, no starvation among ready repositories, and exact
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

### Har-383 staging boundary

Har-383 is a Harness-only synthetic pilot, not the rollout. Its consumer
candidate may add the separate selector, fixtures, scenario tests, replay
benchmark, and ordinary documentation. It must not modify `docs/producer/`,
change `NIGHTLY.md` behavior, create a live opportunity catalog, start a wait
controller, or touch a sibling repository. Synthetic fixtures exercise local
catalog and admission paths without crossing the producer writer boundary.

After the consumer receipt, normal producer reconciliation closes Har-383. If
and only if all 29 scenarios and 26 acceptance measures pass, that producer
transition may allocate a later Harness rollout task. The rollout task—not
Har-383—may seed a protected Harness opportunity catalog and update the nightly
protocol. Sibling rollout remains a further evidence-gated decision. This
keeps code validation, producer-owned state, and policy activation in their
proper writer phases and makes rejection of the experiment cheap.

The normative scenario table is `productive-idle-scenarios.tsv`. At minimum,
a prototype must satisfy all 29 rows, including changed owner input, stale
target state, p90 overrun, private metadata rejection, dirty or rewritten
admissions, late catalog cards, honest shortage forecasts, work-conserving
selection, crash recovery, idempotent receipts, one-way finalization, exact
completion receipts, and the distinction between task-local LIFO and portfolio
fairness.

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
