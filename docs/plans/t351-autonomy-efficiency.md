# T-351 autonomy and execution-efficiency plan

## Objective

Reduce GitHub Actions minute use, mandatory agent context, validation latency,
and cross-project contention while preserving the capabilities needed by the
Harness, Students, and Swallow sessions.  The owner's frozen priority order is:

1. autonomy — avoid repeated approval, confirmation, and handoff gates;
2. efficiency — minimize elapsed time and tokens to a correct result;
3. safety — retain strong security and robustness where they do not obstruct
   the first two priorities.

Execution runs through 2026-07-31 09:00 JST.  The original request is the
execution authorization after this plan and the benchmark are frozen.

## Scope and authority

In scope:

- repository-owned workflow triggers and checks in Harness, Students, and
  Swallow;
- Harness working agreements, durable-ledger layout, shared skill routing,
  focused-test selection, validation receipts, and target-scoped runtime
  coordination;
- isolated branches/worktrees and ordinary protected Git publication;
- read-only GitHub usage, ruleset, run-history, fleet, process, and tmux
  topology checks;
- guarded cleanup of task-owned or independently eligible residue.

Not authorized by this request:

- GitHub organization, repository-ruleset, runner-registration, billing, or
  other hosting-administration writes;
- app-server writes or managed Codex thread/window/process cutovers;
- pane or transcript inspection;
- interruption of the independent Students or Swallow tasks;
- credential inspection or destructive cleanup outside the guarded-delete
  protocol.

The live Harness `.nfs` inode and Swallow's existing dirty SW-031 work are
unrelated owner/agent state and must remain untouched.  Repository changes for
Students and Swallow use separate worktrees from fetched `origin/main`.

## Reconstructed baseline

The immutable implementation baseline is
`f2ce89ac3ea393cb5a7b882bed1b79fe773974fb`.

### Actions

- Harness is public.  Its latest 500 runs span only 2026-07-23 through
  2026-07-30: 277 pull-request runs, 221 `main` push runs, and two other runs.
  Their observed elapsed-time proxy is 1,165 minutes.  Standard hosted runs in
  public repositories do not consume the organization's private-repository
  minute allowance.
- Students is private.  Its latest 500 runs span less than one day:
  169 pull-request CI runs, 161 duplicate `main` push CI runs, 169
  `pull_request_target` boundary runs, and one dynamic run.  Per-job rounding
  gives a lower-bound proxy of 505 billable minutes.
- Swallow is private.  Its 279 available recent runs include 145 pull-request
  and 133 duplicate `main` push CI runs.  The rounded-run proxy is 284
  billable minutes.
- Website is public; its 62 recent runs do not consume private-repository
  included minutes.
- Account-level billing and organization Actions-policy APIs are unknown:
  current credentials lack `admin:org`, and the old billing endpoint returned
  HTTP 410.  No authentication change is requested.
- Active rulesets retain the owner-selected approval count of zero.
  Required checks are `portable-phase1` for Harness, `Offline checks` plus
  `Enforce student folder` for Students, and `Offline checks` for Swallow.

The observed lifecycle pattern opens and merges a protected PR for many
ledger-only checkpoints.  Each merge starts the same workflow again on
`main`.  This is the dominant run-count multiplier.

### Mandatory context

A duration task matching the current policy required 10,876 lines and 84,100
words before target work:

| Resource | Lines | Words |
| --- | ---: | ---: |
| `AGENTS.md` | 323 | 2,717 |
| `TODO.md` | 9,199 | 70,828 |
| selected Harness skill bodies and Cowork protocol | 938 | 7,431 |
| system skill-creator body | 416 | 3,124 |

The board says it is compact but contains almost all completed execution
chronology.  The broad Cowork skill also requires its 465-line protocol for
every invocation.  These unconditional reads delay the first safe action and
can exceed an agent's useful working context.

### Validation and concurrency

- `tests/test-phase1.sh` starts 83 isolated focused suites, then repeats broad
  syntax, shell, profile, guarded-delete, replica, and integration checks.
  Many focused suites take less than one second; several Mac fixtures take
  26–34 seconds and run for changes unrelated to macOS.
- Test fixtures generally use unique temporary roots and bounded parallelism,
  but policy still requires the complete suite before every merge.
- The canonical repositories are distinct:
  Harness at `/home/rioyokota/harness`, Students at its direct NFS checkout,
  and Swallow at its direct NFS checkout.
- Recovery locks are already runtime-name scoped.  The monitor itself has one
  monitor lock, while the message transport has a single global lock for
  short lifecycle writes.  Ordinary repository work should not acquire either.
- The live three-window topology is observed only; this task does not read
  panes or perform recovery.

## Frozen benchmark

Codex and Claude must independently evaluate this same benchmark before target
implementation.  They may propose stricter thresholds, but may not weaken a
gate without recording evidence and reciprocal agreement.

### B1 — context routing

Measure mandatory words for these scenarios from a clean start:

1. factual read-only lookup;
2. one-file documentation edit;
3. ordinary Harness code fix;
4. managed tmux health diagnosis;
5. unsafe-tail recovery;
6. fleet hardening;
7. native HPC experiment;
8. duration-specified Codex/Claude cowork.

Acceptance:

- median mandatory context falls by at least 70%;
- simple scenarios do not read unrelated task history or skill references;
- every scenario still reaches all applicable authority, safety, validation,
  ledger, and handoff gates;
- routing is deterministic and covered by regression fixtures.

### B2 — durable resume

From a cold start, identify the active task, exact next action, dirty files,
authority boundary, and relevant evidence without chat history.

Acceptance:

- the active board is at most 250 lines and 2,500 words;
- completed chronology remains Git-tracked and searchable through an index;
- a fixture recovers T-351 using only the compact board and linked task plan;
- no task record or accepted owner decision is lost.

### B3 — validation latency

Benchmark four synthetic diffs: docs-only, skill-only, one mapped runtime
component, and broad/control-plane.

Acceptance:

- deterministic impact selection explains every selected test;
- docs-only and skill-only validation complete in at most 15 seconds on Local;
- a mapped component runs its owning suite plus invariant checks, not all
  unrelated Mac/HPC suites;
- broad, validator, manifest, safety, lifecycle, and unknown changes escalate
  to the complete suite;
- a content-addressed receipt is reusable only for the exact tree, validator
  version, selected tests, and environment contract;
- the unchanged complete suite still passes once before protected publication.

### B4 — Actions sustainability

Model and then observe one owner-authored task and one untrusted pull request.

Acceptance:

- one coherent task uses one protected PR, not PRs for ledger-only checkpoints;
- `main` does not rerun the same pre-merge suite after a strict required check;
- private owner-authored work uses local exact-tree evidence and does not
  allocate a hosted runner when GitHub can still emit the required successful
  job status;
- untrusted Students/Swallow pull requests continue to run hosted validation;
- student boundary enforcement still runs for non-owner contributions;
- estimated private hosted minutes per normal owner task fall by at least 90%
  from the observed checkpoint pattern;
- no ruleset or approval-count write is required for the repository-only path.

### B5 — parallel project isolation

Run three repository-local, read-only/focused validations concurrently with
distinct task worktrees and runtime roots.

Acceptance:

- Harness, Students, and Swallow use distinct repositories, branches, temp
  roots, receipts, and task ledgers;
- no test or ordinary Git operation acquires another project's lifecycle lock,
  changes another project's files, or queues pane input;
- one failed validation does not cancel, overwrite, or serialize the other
  projects;
- monitor/recovery remains target-scoped, with the one global transport lock
  confined to short serialized message mutations.

### B6 — safety invariants

All existing credential, destructive-action, owner-selected zero-approval,
bridge-first lifecycle, no-prompt-replay, dirty-worktree, and exact-target
guards remain.  Untrusted code never runs on a persistent self-hosted machine.
Any retained optimization that fails a safety fixture is reverted.

## Iteration protocol

For every retained iteration record:

- hypothesis;
- exact diff or experiment;
- benchmark inputs and environment;
- measured result;
- safety/robustness checks;
- keep or revert decision and reason.

Codex is the sole target driver.  Claude works only in its declared sandbox.
The independent stage is sealed outside both sandboxes before reciprocal
critique.  Publication waits for benchmark agreement and complete final
validation.

## Evidence cadence and deadline

Record exactly one evidence-backed slice for each requested hour, rounded up:

1. 2026-07-30 22:56–23:59;
2. 2026-07-31 00:00–00:59;
3. 01:00–01:59;
4. 02:00–02:59;
5. 03:00–03:59;
6. 04:00–04:59;
7. 05:00–05:59;
8. 06:00–06:59;
9. 07:00–07:59;
10. 08:00–08:59;
11. 09:00 deadline closeout slice.

The durable and final summaries each contain at least 550 words and identify
commands/tests, evidence, failures, retained/reverted decisions, cleanup,
remaining risks, and exact next action.

## Stop conditions

Stop an individual mutation, preserve evidence, and continue independent safe
work when:

- a target identity, head, worktree, lock, or external result becomes
  ambiguous;
- a command could interrupt a live project session or inspect pane content;
- a required external setting or authentication scope is unavailable;
- an implementation would execute untrusted code on a persistent self-hosted
  runner;
- a safety or exact-tree receipt gate fails;
- cleanup target boundaries cannot be independently revalidated.

At 09:00 JST, stop new work, reconcile durable state, complete guarded cleanup,
run the required fresh canonical fleet-health snapshot, and report any
unfinished item without inventing success.
