# Har-378 producer/consumer ledger plan

## Desired outcome

Create a repository-local, asynchronous producer/consumer protocol for exactly
Harness, Personal, Students, Swallow, and Website:

- `harness:cowork.0` Codex converts owner input and evidence-based nightly
  review into durable task packets in the affected repository only;
- an assigned Codex or Claude consumer reads its repository's producer ledger
  before its existing board, executes only producer-created durable goals, and
  handles newly discovered in-scope issues as a LIFO stack inside that task;
- producer and consumer writers use disjoint files, isolated worktrees, and
  protected publication so they can progress asynchronously without ledger or
  Git conflicts;
- cold starts reconstruct from repository bytes, not chat history;
- nightly work runs while consumers are idle, checks public repositories for
  inappropriate tracked content, compacts ledgers/skills only when benchmarks
  prove lower time or tokens, then validates, publishes, and cleans each
  repository independently; and
- Personal and Students details never enter public Harness or Website state.

## Scope and non-goals

In scope: repository instructions, producer/task ledger schema, consumer
execution ledger contract, validators, focused tests, cold-start routing,
nightly protocol, public-content checks, isolated worktree/publication rules,
assignment-neutral task packets, migration of current active/pending tasks,
and final guarded cleanup.

Out of scope unless a later owner decision adds it: a network task broker,
daemon, scheduler, new credentials, separate GitHub identities, automatic
deployment, automatic external writes, new tmux panes, or moving sensitive
payloads between repositories. Existing approval counts remain zero and are
never changed. Existing project-specific privacy, research, compute,
deployment, and external-action gates remain authoritative.

## Confirmed current state

1. Harness, Personal, and Website are clean on current protected `main` and
   have no open pull requests.
2. Students and Swallow canonical checkouts are still live legacy task
   branches. Current `origin/main` uses the new `Stu-*` and `Swa-*` namespaces;
   Har-371 forbids moving either runtime before an owner-visible idle or cold
   boundary.
3. Personal and Students are private. Harness, Swallow, and Website are
   publicly readable; the requested mandatory public-content audit applies at
   least to Harness and Website and must never use private repository content
   as a comparison corpus.
4. Existing always-read byte baselines are:

   | Repository | AGENTS | board/session | installed skill text |
   | --- | ---: | ---: | ---: |
   | Harness | 6,058 | 2,226 | 37,934 |
   | Personal | 2,492 | 818 | 37,934 |
   | Students `origin/main` | 6,834 | 1,421 | 45,965 |
   | Swallow `origin/main` | 6,581 | 1,914 | 35,038 |
   | Website | 6,645 | 1,604 | 24,264 |

5. Existing repository boards mix goal creation and execution state, which
   gives producer and consumer overlapping write surfaces. Website also has a
   mutable driver session ledger. A disjoint single-writer protocol is needed.
6. All agents use the same owner OS and GitHub identities. Instructions and
   validators can strongly enforce role separation for compliant agents, but
   cryptographic writer separation requires a distinct identity or credential
   and is not currently available.

## Proposed repository-local file contract

Each repository receives the same small conceptual contract using its native
task prefix and local validation style:

1. `PRODUCER.md` — always-read compact queue and protocol header. Producer-only
   writes. Consumers read it before `TODO.md` and never modify it.
2. `docs/producer/tasks/<ID>.md` — immutable producer task packet containing
   objective, priority/order, scope, non-goals, dependencies, authority already
   granted, gates still requiring the owner, acceptance checks, and suggested
   consumer class. It contains only repository-local information.
3. `docs/producer/index.tsv` — producer-owned compact disposition/index. A
   consumer never marks a producer task complete here.
4. Existing `TODO.md` plus `docs/tasks/<ID>.md` — consumer-owned execution
   state. Claiming a producer task creates or updates only these files and its
   implementation surfaces. The task ID is allocated by the producer; a
   consumer cannot allocate another durable goal.
5. `docs/consumer/receipts/<ID>.md` — task-specific completion or blocked
   receipt written by the consumer. The producer later reconciles it into its
   own index without editing consumer history.

The exact filenames may adapt to a repository's closer schema, but the writer
partition and cold-start order are invariant. Producer queue changes and
consumer implementation changes use separate branches/worktrees and PRs.

## Consumer protocol

1. Read root instructions, then `PRODUCER.md`, then the referenced producer
   packet, then `TODO.md` and only the matching execution record/policies.
2. Select only a producer task whose state is ready and whose dependencies and
   authority gates are satisfied. Never convert an idea or finding into a
   durable goal.
3. Create an isolated task worktree from freshly fetched protected `main`.
4. During execution, push each newly found in-scope issue onto the matching
   task record's LIFO stack, solve it immediately when safe, validate, and pop
   back. An issue outside task scope or authority becomes a blocked receipt,
   not a new task.
5. Publish one coherent protected pull request, independently verify current
   head/checks, clean only task residue, and leave the producer ledger
   untouched.
6. If no ready packet is assigned to that repository, remain idle.

## Producer protocol

1. Convert owner input into the smallest repository-local task packet. Do not
   copy another repository's context, evidence, or conclusions.
2. Allocate IDs and write only producer-owned files during ordinary dispatch.
   Publish the packet before a consumer can claim it.
3. Reconcile consumer receipts and dependencies without rewriting consumer
   execution history.
4. Keep assignment as packet metadata, not a fixed tmux path, so Personal and
   Students slots can later be replaced by Swallow or Website without changing
   repository semantics.
5. Use opaque cross-repository progress locally when coordination is required;
   public Git records contain no private task title, finding, or evidence.

## Nightly protocol

Nightly execution is producer-only and begins only after all consumer panes are
metadata-verified idle under the frozen scheduling decision. For each
repository independently:

1. Fetch and inventory branch/worktree/PR/temp state without reading unrelated
   histories or private payloads.
2. Read its producer queue, consumer receipts, active board, routed policies,
   and only evidence needed for open work.
3. Run credential-free public-content checks for Harness and Website before
   publication. Never scan a private repository into a public artifact or
   report private matches publicly.
4. Benchmark cold-start bytes, routed bytes, command count, wall time, and
   validation cost. Compact ledgers or skills only when capability tests stay
   equivalent and measured time/token-to-task improves.
5. Preserve existing goals and gates; cancel or create durable goals only by
   producer action backed by evidence. Consumers remain idle and never race
   these files.
6. Validate, publish, and guarded-clean each repository independently. One
   blocked repository does not hold another repository's worktree or ledger.

## Ordering and conflict controls

- Producer files have one writer. Consumer files and implementation paths have
  one active task owner per repository.
- Producer packets are append-only after publication. Corrections create a new
  packet revision/disposition rather than silently changing consumer scope.
- Consumers fetch after packet publication and before push. Producer work
  rebases only producer-owned paths; consumers never resolve a conflict by
  editing producer files.
- Nightly compaction requires consumers idle and no overlapping open worktree.
- Har-371 migration must finish for a selected Students/Swallow consumer before
  that canonical checkout can participate. The ledger protocol itself can be
  developed from isolated `origin/main` worktrees first.

## Validation and acceptance

Per repository, add focused tests proving:

- cold-start ordering is producer ledger, packet, own board, own record;
- a consumer modification to producer-owned paths is rejected;
- consumers cannot allocate durable task IDs or promote LIFO issues to goals;
- producer and consumer changes on disjoint paths merge/rebase without a
  synthetic conflict;
- blocked/complete receipts survive interruption and never grant authority;
- assignment changes do not change task bytes;
- malformed, cross-repository, oversized, or sensitive-field packets fail
  closed; and
- repository-native full validation and publication gates still pass.

Portfolio acceptance additionally requires a privacy canary showing no
private task payload reaches Harness/Website, measured cold-start routing no
larger than the frozen budget without demonstrated benefit, clean protected
main in all five repositories, zero task worktrees/branches/temp residue, and
consumer sessions left idle on current published instructions.

## Rollback and interruption

Every repository uses an isolated branch/worktree and its own protected PR.
Before any consumer uses the new protocol, validators and cold-start tests must
pass on all applicable clients. If one repository fails, do not publish or
activate that repository; continue safe independent streams. Published schema
rollback is a normal reverting PR that preserves task packets and receipts as
history. Never delete an ambiguous queue, packet, receipt, or worktree.

Checkpoint after each owner decision, each repository's schema commit, every
failed gate, each protected merge, each rollout/activation, and final cleanup.

## Decision register

### D-001 — Does a producer packet authorize automatic consumer execution?

Selected: yes, but only for the packet's explicit repository-local scope.
Existing external writes, deployment, messages, credentials, scheduler,
hosting settings, destructive operations, and person-only gates still require
their normal exact authority. Consumers work asynchronously without another
generic `go`; no packet can widen a closer safety boundary.

### D-002 — Strength of producer-only write enforcement

Open. Recommended: instruction + validator + role-aware repository command,
with no new credential. This is strong for compliant Codex/Claude agents but
not cryptographic because all sessions share the owner's identities. A truly
cryptographic boundary requires a separate producer Git identity/credential.

### D-003 — Top-level task selection order

Open. Recommended: producer-defined priority, then oldest ready packet. LIFO is
reserved for nested issues discovered while executing one task; global LIFO
would starve older durable work.

### D-004 — Nightly trigger

Open. Recommended: owner-started duration/end-time runs initially. Do not add a
recurring daemon until at least two clean runs establish runtime, idle, privacy,
and publication behavior. A later producer task can propose scheduling.

### D-005 — Publication responsibility

Open. Recommended: consumers publish their own implementation PRs; the
producer publishes producer-ledger/nightly-compaction PRs. Each repository
retains its native validation and deployment boundaries.

## Exact next action

Ask D-002 only. Record the answer before asking D-003. No target repository,
runtime, schedule, assignment, or external state may change before all five
decisions are frozen and the owner gives an explicit `go`.
