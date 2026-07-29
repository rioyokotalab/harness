# T-345 dedicated Codex recovery helper

**Phase:** ready-for-go
**Driver:** Local Codex
**Updated:** 2026-07-30 JST
**Branch:** `codex/t345-recovery-helper`
**Working tree:** `/tmp/harness-t345-recovery-helper`

## Outcome

Add a dedicated recovery lane at `monitor:2` that can recover a blocked
Harness, Students, or Swallow root without requiring either healthy sibling
thread to be idle. Keep the phone remote-control active list aligned with the
three canonical roots in tmux session `harness`, and retire helper-created or
otherwise proven temporary top-level roots automatically after safe
replacement. After promotion, resume the recovered role's exact durable task
without reconstructing or replaying the rejected prompt.

The canonical user-facing mapping remains:

| tmux window | role | remote-control root |
| --- | --- | --- |
| `harness:0` | Harness | exact root in the window's resilient argv |
| `harness:1` | Students | exact root in the window's resilient argv |
| `harness:2` | Swallow | exact root in the window's resilient argv |

The helper topology will be:

| tmux window | role |
| --- | --- |
| `monitor:0 tunnel` | existing connection monitor |
| `monitor:1 codex` | existing pane-blind tmux/Codex monitor |
| `monitor:2 helper` | new recovery dispatcher and ephemeral Codex worker |

## Scope

In scope:

1. A repository-managed, current-user recovery dispatcher with `--run`,
   `--once`, `--status`, and fixture-driven test modes.
2. A private mode-0700 runtime root, mode-0600 queue, event receipts, lifecycle
   journal, and one current-user lock.
3. One bounded `codex exec --ephemeral` Sol/high worker per accepted event.
4. Recovery of one exact `blocked/unsafe-tail` target at a time while either or
   both non-target project threads are active.
5. Recovery of a confirmed-absent managed remote-control app server through
   one native `codex remote-control start --json` invocation.
6. Name/archive reconciliation for the three exact tmux roots and proven
   temporary top-level roots.
7. One deduplicated post-promotion continuation that reconciles Git, the
   durable ledger, recent commits, worktree state, and mutable external state
   before resuming the recovered role's recorded next action.
8. A one-time baseline convergence of existing top-level Harness-cwd roots
   after exact read-only classification and the owner's cleanup decision.
9. Focused tests, full Harness validation, protected publication, guarded
   fleet sync, Local activation, and a safe Mac context refresh where eligible.

Out of scope:

- pane or transcript reads, prompt reconstruction, or rejected-prompt replay;
- arbitrary work inside Harness, Students, or Swallow;
- recovery of an attached blocked target;
- simultaneous lifecycle writes or parallel fresh-root cutovers;
- automatic mutation of subagent roots or roots outside
  `/home/rioyokota/harness`;
- credential, pairing, plugin, connector, MCP, account, profile, or settings
  changes;
- remote-control forced restart while a live server or active turn may exist
  unless the owner separately selects that risk;
- deleting or archiving an unclassified root;
- raw recursive/bulk deletion, process-group signals, `SIGKILL`, force-push,
  or unrelated tmux/repository changes.

## Confirmed current state

1. The repository root is `/home/rioyokota/harness`. The isolated task
   worktree starts at published `origin/main`
   `5f7ce2e3e6f061576c0b24652081cbcca4661e15`. The live root checkout remains
   at `f533310299ac86e182e03132588dbaf70396c00e`, clean and behind only the
   T-343 timestamped ledger commits. T-343's two worktrees and all earlier
   recovery worktrees are unrelated and must remain untouched.
2. Live tmux session `harness` has exactly one live pane in each canonical
   window: `@87/0:harness`, `@88/1:students`, and `@93/2:swallow`. One client
   is attached to exact Harness `@87`.
3. Live tmux session `monitor` has `@40/0:tunnel` and `@94/1:codex`; no helper
   window exists. The monitor process is
   `harness-tmux-codex-monitor --interval 30 --enforce-order --auto-recover`
   and reports `healthy=3`.
4. Exact resilient identities are:
   - Harness root `019fa3ae-6ad0-7642-aeca-b7b52421f576`, currently active;
   - Students root `019f7fea-4f00-7681-910d-81ae99a77143`, currently active;
   - Swallow root `019fafef-5ebf-72f1-b1ce-2444e7570dc1`, currently idle.
   All three have live watcher, TUI, and shared app-server process evidence.
5. T-344's current `--auto-recover` path selects only one blocked Students or
   Swallow root and then pastes a request into the Harness pane. It explicitly
   defers if Harness is active. It cannot recover blocked Harness, multiple
   blocked roots, or a target while both peers are busy.
6. Native Codex 0.145.0 supports `codex exec --ephemeral`; a long-lived
   interactive Codex TUI has no ephemeral mode. Therefore a permanently
   waiting TUI would itself create a fourth saved root and conflict with the
   requested three-root phone/tmux mirror.
7. Native remote control has `start`, `stop`, and `pair`, but no `status`
   subcommand. Current redacted doctor checks for app server, authentication,
   installation, websocket reachability, state paths, and rollout/database
   parity all report `ok`. Current app-server PID `2852569` is live.
8. The SQLite state database has six unarchived, non-subagent, top-level roots
   whose cwd is exactly `/home/rioyokota/harness`. Three are the live tmux
   roots. The other three are:
   - old exec root `019f6271-667e-7f02-9a4b-4edd2b83b725`;
   - retired Swallow root `019fa5a1-7fff-7e92-8e2a-2586c684747f`;
   - rejected T-344 provisional root
     `019fafec-3da4-77d2-a88f-e7abaa380a06`.
   None is referenced by the three live tmux process argv values. Final
   inactivity and ownership checks remain execution-time gates.
9. Native `codex archive` is reversible through `codex unarchive` and removes
   a root from active lists. Native `codex delete --force UUID` permanently
   deletes a saved root.
10. T-330 proved that periodic app-server control connections can displace
    managed recovery watchers. The monitor must continue to use tmux, process,
    socket, watcher-receipt, and direct metadata checks only. App-server
    control reads/writes are confined to a serialized accepted recovery
    transaction.

## Design

### 1. Dispatcher rather than a persistent fourth TUI

`monitor:2 helper` will run a deterministic repository command, not a
permanently saved interactive chat. It waits without consuming model turns.
When a validated event is queued, it starts one child:

```text
codex exec --ephemeral -C /home/rioyokota/harness \
  -m sol -c model_reasoning_effort='"high"' -
```

The exact prompt is repository-owned, contains only value-free event
identifiers and safety rules, requires complete `AGENTS.md`/`TODO.md` and
`recover-codex-unsafe-tail` review, forbids repository edits and unrelated
work, and permits only the accepted event transaction. Standard output and
the final structured result go to one current-user mode-0600 event log.
Because the worker is ephemeral, it never enters the saved-session or phone
remote-control lists.

### 2. Event production and serialization

The existing monitor remains pane-blind and gains a producer-only handoff.
After exact health collection it may reserve one event for:

- one or more exact canonical roots in `blocked/unsafe-tail`;
- a confirmed-absent remote-control app-server identity;
- a known canonical-name/archive mismatch for a root already present in the
  helper lifecycle journal.

Events are immutable and keyed by target root, watcher start identity,
app-server identity or absence proof, tmux window ID, and event kind. The
dispatcher handles events in deterministic creation order, one at a time.
Multiple blocked targets are queued rather than treated as ambiguous. Every
event is revalidated under the existing mode-0600
`~/.local/state/harness/agent-message.lock` before any lifecycle write.

A receipt transitions through `reserved`, `worker-started`, explicit
per-operation boundaries, and one terminal state. An acknowledged or
ambiguous operation is never retried. A new event may be created only after
the immutable identity changes or a receipt proves that no write was
attempted.

### 3. Blocked-root recovery

The target must be exact, canonical, current-user-owned, unattached, and still
`blocked/unsafe-tail`. Non-target project roots may be active, idle, or in
supervisor backoff, but their tmux/process/root identities and the shared app
server must remain stable. A healthy peer is not used as a controller.

The worker follows the bridge-first protocol:

1. freeze the target cwd, sandbox, approval policy, root and rollout identity;
2. create one distinct provisional root and persist its pre-write receipt;
3. launch one provisional tmux window/runtime without prompt replay;
4. submit the generic cold-start recovery instruction once;
5. require an assistant-bearing completed turn, no `systemError`, canonical
   cwd/policy, and exact process/socket/root evidence;
6. name and accept the provisional root;
7. rename the old target/window uniquely and promote the accepted bridge by
   rename only;
8. retire only the old exact TUI leaf, never a process group;
9. archive the old blocked root and any rejected helper-created provisional
   root only according to the selected cleanup policy;
10. require the canonical three-window mapping, unchanged attached clients,
    stable peers, and a healthy replacement watcher;
11. reserve one distinct continuation event, submit one cold-resume
    instruction to the promoted canonical thread, and record submission before
    release. The instruction must read complete applicable instructions and
    durable ledgers, inspect current Git and mutable external state, reconcile
    any side effects that may already have occurred, and continue only the
    first recorded unverified action. It must never reconstruct or replay the
    rejected prompt.

If the target is Harness, the owner may remain attached to another exact
window or no window; the helper never injects input into the blocked target.
If the target window itself is attached, recovery remains deferred.

### 4. Remote-control recovery

Periodic checks do not open the app-server control socket. Automatic native
start requires all of the following:

- no current-user process matching the exact managed
  `app-server --remote-control --listen unix://` identity;
- no reciprocal app-server peer for any surviving project TUI;
- no live managed PID record that identifies a different process;
- redacted doctor app-server/websocket checks are non-ready or unavailable;
- one private event receipt reserved before native start.

The ephemeral worker invokes `codex remote-control start --json` once, then
requires one new exact process identity, a ready redacted doctor, restored
project supervisors/TUIs without prompt replay, and unchanged pairing. A
pairing request, identity conflict, or ambiguous native result stops without
retry or account mutation.

A live but unresponsive server is report-only. The helper never signals or
restarts a live app-server identity automatically because forced shutdown can
interrupt all active turns.

### 5. Phone/tmux mirror and temporary roots

The mirror covers top-level, non-subagent saved roots for exact Harness cwd.
Subagent roots remain private implementation children and are never archived
by this controller.

The three canonical tmux argv root IDs are the source of truth. For each,
metadata must indicate unarchived and its canonical role name. A root may be
automatically removed from the active phone list only when:

- it is named in the helper's own accepted/rejected lifecycle journal or in
  the one-time frozen baseline;
- no live process argv references its UUID;
- its rollout identity is canonical and structurally inactive;
- it is not any canonical tmux root;
- the archive preimage and one-attempt receipt are durable.

The helper will not infer that every unreferenced root is temporary. New
unclassified roots produce a value-free drift report and remain untouched.

## Execution sequence

1. Reconstruct the selected D-001 reversible-archive and D-002 absent-only
   decisions, the post-promotion task-continuation requirement, and this
   `ready-for-go` plan after a separate explicit `go`.
2. Reconstruct the frozen plan from Git; fetch and integrate published main
   without touching T-343 or unrelated worktrees.
3. Add the `codex-recovery-helper` dispatcher, command routing, private state
   validation, event schema, bounded worker launcher, and status output.
4. Refactor the monitor's current controller-paste path into queue production.
   Preserve its existing health/order behavior and prohibit app-server control
   connections, pane reads, arbitrary input, and direct lifecycle writes.
5. Add the reviewed recovery and post-promotion continuation prompts plus
   deterministic transaction support for blocked-root,
   absent-remote-control, mirror, continuation, and cleanup events.
6. Add focused fixtures for:
   - blocked Harness while both peers are active;
   - blocked Students/Swallow while Harness is active;
   - two and three blocked roots queued serially;
   - attached-target deferral;
   - post-promotion resume from the durable next action without rejected-prompt
     replay, including partial-side-effect reconciliation;
   - event identity drift and duplicate/ambiguous non-retry;
   - ephemeral worker identity and no saved helper root;
   - absent app server one-start recovery;
   - live/unresponsive server report-only refusal;
   - canonical naming/archive mirror;
   - unclassified and subagent-root preservation;
   - reversible archive and unarchive rollback behavior;
   - monitor/helper restart and journal reconciliation.
7. Run Python syntax, ShellCheck where applicable, `git diff --check`, the
   focused monitor/helper/resilient suites, and `tests/test-phase1.sh`.
8. Fetch again, integrate non-conflicting contributor commits, push the exact
   task branch, open the protected PR, require CI, and merge without changing
   the owner-selected zero-approval ruleset policy.
9. Guarded-sync only clean managed checkouts and perform eligible one-shot Mac
   context refreshes. Preserve unavailable or dirty targets as explicit
   blockers.
10. Revalidate Local exact topology and healthy roots. Create one provisional
    detached helper window at free index 2, require its private receipt and
    value-free status, then promote it to exact `monitor:2 helper`. Do not
    disturb windows 0 or 1.
11. Freeze and execute the one-time baseline cleanup for only the three
    recorded noncanonical top-level roots, subject to D-001 and fresh
    inactivity/identity checks. Never retry an ambiguous archive.
12. Validate two monitor/helper intervals, exact tmux order, exact three-root
    active remote-control metadata, helper ephemerality, stable clients and
    peers, current remote-control doctor, no temporary helper roots, no pane or
    transcript reads, and fresh canonical fleet health.

## Failure, rollback, and interruption

- Before helper activation, repository rollback is the normal revert of the
  published task commit.
- After activation, stop only the exact helper pane process after matching PID,
  start time, owner, executable, argv, and private receipt. Remove only exact
  `monitor:2 helper`; preserve monitor windows 0/1 and all project windows.
- An accepted new root is never discarded because a later cleanup step fails.
  Preserve its exact mapping, mark cleanup pending, and reconcile from the
  journal.
- If an app-server start is acknowledged or ambiguous, never invoke start
  again. Read process/doctor state and stop.
- If a fresh-root launch, name, promotion, signal, or archive is
  acknowledged or ambiguous, never repeat it. Resume from the journal and
  actual metadata.
- If the post-promotion continuation submission is acknowledged or ambiguous,
  never resubmit it. Reconcile the canonical thread and durable task ledger on
  a later owner/controller turn.
- If the helper process exits, the monitor remains observe/order only and
  reports helper absence. Restart reads receipts before accepting new work.
- No recovery action modifies Git. Repository implementation and live runtime
  evidence stay separated so concurrent project work is preserved.

## Validation and acceptance

Acceptance requires:

1. exact `monitor` topology `0:tunnel,1:codex,2:helper`, one live pane each;
2. helper current status and mode-0600 journal/queue/log artifacts;
3. blocked-root events no longer depend on Harness or either peer being idle;
4. attached target, identity drift, unknown state, and ambiguous operations
   fail closed;
5. the helper worker uses Sol/high and `--ephemeral`, with no fourth saved
   helper root;
6. exact top-level active remote-control roots equal the three canonical tmux
   roots after baseline convergence, excluding subagent children by contract;
7. helper-created rejected/retired roots leave the active list under D-001;
8. confirmed-absent remote control starts once and returns healthy without
   pairing mutation or prompt replay;
9. a live unresponsive app server is reported without signal or restart;
10. every recovered canonical thread receives at most one continuation
    submission and resumes from the durable first unverified action after
    current-state reconciliation, never from the rejected prompt;
11. focused and complete suites, protected CI, guarded rollout, Local live
    checks, and fresh fleet health all pass;
12. no pane/transcript content, credential, unrelated worktree, review-count
    setting, external service, or unclassified root changed.

## Decision register

### D-001 — Meaning of “remove temporary threads”

**Recommended: reversible archive.** Automatically archive the three frozen
baseline extras and future helper-created rejected/retired roots after exact
inactivity checks. They disappear from the active phone list and can be
restored with `codex unarchive`.

Alternative: permanent `codex delete --force UUID` after the same checks. This
irreversibly removes recovery evidence and has no rollback.

**State:** selected by the owner: reversible archive. Automatic permanent
deletion is forbidden. Execution steps 3, 5, 6, 11, and acceptance item 7
must implement and test `archive`/`unarchive` semantics only. Every archived
root retains its saved history and exact rollback route.

### D-002 — Live but unresponsive remote-control server

**Recommended: recover confirmed absence only.** Automatically run native
start once when no server identity exists. If a live identity is unresponsive,
report and defer because forced shutdown may interrupt all active turns.

Alternative: allow an exact-identity two-stage `SIGTERM` and native restart
even while project threads may be active. This can disconnect remote control,
terminate in-flight turns, and requires stronger pre-signal checkpoints.

**State:** selected by the owner: confirmed-absence recovery only. A live but
unresponsive server is value-free report-only and must not be signaled,
stopped, or restarted automatically.

### D-003 — Waiting helper implementation

**Selected by constraint:** deterministic waiting dispatcher plus one
Sol/high `codex exec --ephemeral` worker per event. A persistent TUI is
rejected because it would create a fourth saved root and violate the requested
phone/tmux mirror.

## Next action

Wait for a separate explicit owner `go`. Then reconstruct this frozen plan and
selected decisions from disk, set phase `executing`, and begin implementation
at execution step 2. Until `go`, do not implement, publish target code, create
`monitor:2`, launch a worker, change remote-control state, or archive a root.
