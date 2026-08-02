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

## Minimal repository-native shape

Do not add a heavyweight workflow engine. Extend the existing producer tool
with a small run-manifest schema and three commands:

- `nightly-plan --until ...` validates the primary packet and admitted cards,
  conflict keys, authority classes, estimates, and finalization reserve.
- `nightly-next --remaining-minutes ...` returns one ready card or an exact
  wait/finalize state without requiring the agent to read unrelated packets.
- `nightly-receive` accepts one completion, blocked, skipped, or interrupted
  receipt and enforces one terminal disposition for every pulled card.

Repository-local cards and receipts remain private to their repositories. A
Harness portfolio manifest contains only repository, opaque card ID, class,
minutes, conflict key, and disposition. The selector must be deterministic and
side-effect free. No service, dependency, or hosted scheduler is required.

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
