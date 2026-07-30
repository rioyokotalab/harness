# T-350 repository-native Codex sessions

## Outcome

Keep the canonical Local tmux session `projects` and its Harness-owned
monitoring/recovery control plane, while making each interactive Codex session
operate from the repository named by its window:

| Target | Window | Canonical repository |
| --- | --- | --- |
| Harness | `projects:0:harness` | `/home/rioyokota/harness` |
| Students | `projects:1:students` | `/home/rioyokota/projects/students` |
| Swallow | `projects:2:swallow` | `/home/rioyokota/projects/swallow` |

After an automatic blocked-root recovery, the accepted replacement must read
the mapped repository's complete instructions and durable ledger, reconcile
Git and mutable external state, and resume only the first recorded unverified
action. Every accepted interactive session must resolve to `gpt-5.6-sol` with
high reasoning.

## Authority and non-goals

The owner selected the exact repository map and Sol/high requirement. A later
explicit `go` authorizes only this plan's repository, protected-publication,
local project-checkout, tracked sentinel, target-aware control-plane, and
bridge-first session migrations.

Do not read credentials, change connectors or accounts, deploy project code,
run Students production work, run Swallow compute or scheduler jobs, execute a
project TODO action, restart the shared app server, move the attached tmux
client, or migrate more than one project session at a time. Preserve all old
saved roots through reversible archive. Harness's live root remains unchanged.

## Confirmed baseline

- Harness protected `main` is clean and aligned at the T-349 closeout.
- The canonical tmux session is exact `$14:projects` with
  `@87/0:harness`, `@88/1:students`, and `@98/2:swallow`; all resilient chains,
  monitor, helper, phone parity, and fleet routes are healthy.
- Current monitor and helper code require every canonical tmux path and saved
  root cwd to equal `/home/rioyokota/harness`.
- Both tracked global launch sentinels reject any repository root other than
  `/home/rioyokota/harness`.
- Authenticated Git transport reaches Students `main` at `321a2a7` and Swallow
  `main` at `258a5bc`.
- Students and Swallow each contain repository-local `AGENTS.md` and `TODO.md`
  ledgers but neither currently tracks `.codex/config.toml`.
- Students' first ready repository lane is T-037; its production lanes remain
  separately gated. Swallow SW-033 remains executing, with its recorded next
  step to publish the r3 partial result before selecting a non-GPU ready lane.
  This setup task records those facts but does not execute either action.
- Harness already tracks `gpt-5.6-sol` and
  `model_reasoning_effort = "high"` in its project Codex configuration. The
  ephemeral recovery worker also uses Sol/high, but that does not by itself
  constrain a recovered interactive session.

## Decisions

### D-001 — Repository layout

Selected: use `/home/rioyokota/projects/students` and
`/home/rioyokota/projects/swallow`; retain `/home/rioyokota/harness` for
Harness. Do not nest independent repositories inside Harness.

### D-002 — Repository-native saved roots

Selected: replace Students and Swallow with fresh interactive roots whose
persisted cwd is their canonical repository. Merely changing a tmux pane's
working directory is insufficient because the current saved roots persist
Harness cwd and recovery validates root metadata.

### D-003 — Sol/high

Selected: each project tracks its own `.codex/config.toml` with exact model,
reasoning, approval, and sandbox defaults equivalent to accepted Harness
policy. Recovery launches from the mapped repository, and bridge acceptance
requires app-server/root readback proving resolved Sol/high. Do not rely on
opaque user-global settings.

## Execution sequence

### 1. Prepare independent project repositories

1. Revalidate authenticated Git transport and absent/conflict-free target
   paths.
2. Clone Students and Swallow into their selected paths on clean `main`.
3. Read each repository's complete instructions, TODO, session ledger, and
   closest task instructions.
4. In separate repository-local task branches, add the minimal tracked Codex
   project configuration and focused static validation required to guarantee
   Sol/high without importing Harness runtime files or policy dynamically.
5. Run each repository's declared login-safe validation, publish through its
   protected workflow, and return each canonical checkout to clean aligned
   `main`.

No research, student, Slack, deployment, scheduler, model, data, or compute
action runs in this stage.

### 2. Make Harness target-aware

1. Define one closed mapping for only `harness`, `students`, and `swallow`.
   Reject duplicate, missing, noncanonical, symlinked, wrong-owner, or
   non-repository paths and unknown targets.
2. Update both tracked launch sentinels to admit only those exact repository
   roots and defer to each admitted repository's own root instructions.
3. Update `harness-agent-config` inventory/doctor/apply contracts and tests for
   the exact sentinel bytes without weakening collision, ownership, or
   rollback checks.
4. Update monitor and helper path/root-cwd validation to compare each window
   and saved root against its mapped repository.
5. Update helper worker and continuation prompts so Harness control state is
   reconstructed first, then the mapped repository's instructions and ledger
   govern project work. The prompt must never replay a rejected prompt and
   must continue only the first recorded unverified action.
6. Correct the tracked remote-agent communication transport's stale Local
   controller session selector from retired `harness` to exact `projects`,
   retain exact-window/process/path ambiguity checks, and add a focused
   regression test before using it for cross-window handoffs.
7. Update bridge creation and resilient launch contracts to use the mapped
   repository cwd. Require the interactive root to resolve to Sol/high before
   promotion.
8. Add focused tests for all three accepted mappings, wrong-path drift,
   unknown targets, missing repositories, prompt selection, Sol/high
   acceptance, partial migration, and backward-safe Harness behavior.
9. Run focused suites, `git diff --check`, and complete
   `tests/test-phase1.sh`; independently inspect the complete diff.

### 3. Publish and activate the control plane

1. Commit and push a small verified Harness checkpoint, pass protected CI, and
   merge normally without force-push.
2. Fast-forward clean Local `main`.
3. Apply the tracked launch-sentinel update transactionally with the native
   `harness agent-config` plan/apply/doctor flow and retain its rollback
   transaction.
4. Restart only the idle monitor/helper infrastructure required to load
   merged target-aware code. Do not touch any project TUI yet.
5. Require existing all-Harness-cwd topology to remain an explicitly accepted
   partial-migration state, with all three resilient chains healthy.
6. Guarded-sync only clean eligible managed checkouts and perform required Mac
   context refreshes. Project paths are Local-only and must not become remote
   fleet checkout requirements.

### 4. Migrate Students

1. Freeze exact old Students root/window/process/watcher/app-server/client
   identities and all unaffected peers.
2. Create exactly one new interactive app-server root with cwd
   `/home/rioyokota/projects/students`, granular approval, disabled sandbox,
   and project-resolved Sol/high defaults. Never retry an acknowledged or
   ambiguous start.
3. Launch one distinct provisional tmux window/runtime from that repository.
4. Submit one generic Students cold-start instruction and require a completed
   assistant-bearing turn, no active/error tail, repository instructions and
   ledger reconstruction, and resolved Sol/high.
5. Stop for explicit physical-phone visibility confirmation.
6. After confirmation, rename-only promote the accepted root/window, then
   signal only the old exact TUI leaf once. Require normal chain unwind and
   reversibly archive the retired old root after zero-reference proof.
7. Require exact canonical index/name, healthy watcher/monitor/helper, phone
   parity, unchanged Harness/Swallow/client/app-server identities, and clean
   Students Git.

Checkpoint every sent request and non-retry boundary before proceeding.

### 5. Migrate Swallow

Repeat the Students transaction with exact cwd
`/home/rioyokota/projects/swallow`. Stop separately for physical-phone
confirmation. Do not infer Swallow acceptance from Students acceptance. After
promotion, the recovered Swallow thread must identify SW-033's durable next
action but must remain idle; T-350 does not authorize executing it.

### 6. Final validation and closeout

1. Require exact three-window topology and one saved root per canonical target,
   with persisted cwd matching the closed mapping.
2. Require each canonical app-server root and interactive TUI to report
   `gpt-5.6-sol` and high reasoning under the strongest value-free readback the
   installed protocol supports.
3. Require two interval-separated healthy monitor/helper receipts, exact phone
   parity, native redacted doctor, focused recovery/resilience/helper/monitor
   tests, complete phase-one validation, clean aligned Git in all three
   repositories, and canonical fleet health.
4. Guarded-delete only generated schema or disposable diagnostic trees.
   Preserve archived saved roots and non-retry journals.
5. Publish the durable closeout through protected Harness `main`.

## Failure and rollback

- Any unknown target/path, dirty canonical checkout, sentinel mismatch,
  app-server identity drift, attached target, active ambiguous operation, or
  failed model/effort readback stops before the next write.
- A confirmed unsent request may be retried only under a new exact checkpoint.
  An acknowledged or ambiguous root start, name write, launch, input,
  promotion, signal, or archive is never blindly retried.
- Before promotion, abandon only a helper-created provisional root after exact
  inactivity and zero-reference proof, using reversible archive rather than
  deletion.
- After promotion, preserve the accepted runtime and reconcile read-only;
  never relaunch it to repair names or topology.
- The `harness agent-config` transaction supplies sentinel rollback. A
  repository-native session is rolled back by rename-only promotion of a
  separately accepted root, never by rewriting saved-root cwd metadata.
- Migrate one project at a time so an accepted Students failure cannot affect
  Swallow and vice versa.

## Estimate

Expected active execution is 4–6 hours under stable conditions:

- 2–3 hours: repository preparation, target-aware implementation, focused and
  complete validation;
- 30–60 minutes: protected publication, Local activation, and fleet
  synchronization;
- 1–2 hours: two sequential bridge-first migrations and acceptance.

Time waiting for two owner physical-phone confirmations is excluded. Identity
drift, protected-CI delay, scheduler-independent repository gate failures, or
an ambiguous non-retryable acknowledgement can extend the elapsed time.

## Ready-for-go gate

All material scope decisions are selected. Before execution, re-read this plan,
root `AGENTS.md`, Harness `TODO.md`, each project repository's own instructions
and ledger, and fresh Git/runtime state. Begin only after the owner explicitly
says `go`, `proceed`, or `execute`.
