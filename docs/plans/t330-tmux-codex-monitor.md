# T-330 Local tmux Codex monitor

## Outcome

Keep Local's managed `harness` tmux session pane-blind, ordered, and
value-free healthy:

| index | canonical window | expected role |
| --- | --- | --- |
| 0 | `harness` | Harness controller Codex |
| 1 | `students` | Students Codex |
| 2 | `swallow` | Swallow Codex |

Run a dedicated detached monitor every 30 seconds. Preserve exact saved
threads, attached-client selection, unrelated tmux sessions, the shared Codex
app server, and repository work.

## Scope and non-goals

In scope:

1. Metadata-only inventory of session, window ID/index/name, pane count,
   pane PID/path/dead state, resilient runtime name, watcher receipt/owner,
   process ancestry, exact remote thread ID, app-server thread status, and
   mode-0600 monitor state.
2. Order correction only after unique identity proof for exactly the three
   declared windows.
3. Periodic value-free status and a durable last-known-good mapping.
4. Narrowly gated lifecycle repair under frozen decision D-001.
5. Focused fixtures, full validation, protected publication, Local activation,
   guarded fleet rollout, and Mac context refreshes.

Out of scope:

- reading or capturing pane or transcript content;
- sending input, starting a turn, or replaying any prompt;
- rollback, fresh-root creation, root name/archive changes, or app-server
  restart;
- killing an unidentified process, a process group, the tmux server, an
  attached client, or an unrelated window/session;
- project work inside Students or Swallow;
- changing tmux user configuration, shell startup, credentials, connectors,
  system services, or root-owned files.

## Confirmed current state

- The `harness` tmux session has exactly three one-pane windows already ordered
  `0:harness`, `1:students`, `2:swallow`; both attached clients select Harness.
- Every pane is live and rooted at `/home/rioyokota/harness`.
- Harness resilient supervisor PID `3126145` is running, but its watcher
  receipt points to absent PID `3126236`; its exact root is currently active.
- Students resilient supervisor PID `4073421` is running with no recovery
  receipt; its exact root is idle.
- Swallow supervisor PID `3365669` and watcher PID `3365748` are running at
  attempt/recovery count zero; its exact root is idle.
- The separate `harness-connection-monitor` tmux session remains live at its
  established five-minute cadence. It is not a suitable owner for this cheap
  local check because SSH-agent or route failure can terminate or delay it.
- T-329 closeout PR #377 passed protected CI but remains open because ABQ and
  ABQ2 are still unavailable. T-330 must preserve that branch and blocker.

## Design

Add `harness tmux-codex-monitor` with:

- `--once [--enforce-order] [--repair]`;
- `--interval SECONDS [--enforce-order] [--repair]`, bounded to 30–3600;
- `--status`, reading only a current-user-owned mode-0600 receipt.

The monitor owns a current-user-only runtime directory and lock. Each pass
emits one value-free record per window plus one summary. It snapshots the
exact healthy mapping only from validated live process argv and app-server
metadata. No thread ID or private path is printed in ordinary output.

### Health contract

A healthy window requires:

1. exactly one declared name and one pane;
2. live pane rooted at `$HOME/harness`;
3. pane PID equal to the live resilient supervisor owner;
4. exact `--run --name NAME --remote-session ID` process identity;
5. one live watcher owned by that supervisor and a current watcher receipt for
   the same runtime/thread;
6. a live Codex TUI descendant and reciprocal Unix peer to the unchanged
   current-user app server;
7. app-server thread status `idle`, `active`, or `notLoaded`, never
   `systemError` or unrecognized;
8. no duplicate declared name, duplicate runtime, or extra `harness`-session
   window.

`active` is healthy but not repairable. Supervisor backoff with a live watcher
is `recovering`, not a reason for a second controller.

### Order enforcement

Order writes require all three window IDs to be unique, live, one-pane,
correctly named, correctly rooted, and the session to contain no extra window.
Use `tmux swap-window -d` by immutable source window ID:

1. swap exact Harness to index 0 if needed;
2. reread all IDs/indices;
3. swap exact Students to index 1 if needed;
4. reread and require Swallow at index 2;
5. require every attached client still selects its pre-write window ID.

Any drift stops before the next swap. Never rename or delete a window to make
the order pass.

### Optional safe lifecycle repair

Under recommended D-001 `safe-auto-repair`, repair at most one window per pass.
Require a private saved mapping from an earlier healthy observation, exact
canonical rollout identity, fresh app-server status `idle` or `notLoaded`,
unchanged other windows/clients/app server, and an absent or independently
identified stale chain.

- Missing watcher with a live old-inode TUI: send one `SIGTERM` only to the
  identity-checked real TUI leaf, let its chain/window unwind, then launch the
  same thread at its canonical index under current published code.
- Missing window/chain: launch the saved exact thread once at the canonical
  free index.
- Missing real TUI while resilient supervisor is in bounded backoff: defer to
  the supervisor.

After any acknowledged signal or launch, never retry ambiguously. Require the
full health contract and unchanged attached clients before acceptance.
`active`, `systemError`, unsafe rollout, missing mapping, extra windows,
identity drift, or failed read remains value-free unhealthy with no mutation.

Under D-001 `observe-and-order`, omit all signal/launch paths.

## Execution sequence

1. Checkpoint D-001 and wait for explicit owner `go`.
2. Add the command dispatcher, monitor implementation, and focused test.
3. Add deterministic fixtures for healthy, out-of-order, extra, duplicate,
   missing watcher, missing window, active, systemError, stale mapping,
   client-selection retention, one-repair-per-pass, and ambiguous launch.
4. Run syntax, ShellCheck, diff hygiene, focused tests, and complete phase one.
5. Publish through exact-head protected CI and merge via the preserved
   administrator bypass without changing review policy.
6. Guarded-sync clean reachable fleet targets and issue one context refresh
   per advanced managed Mac. Preserve the exact T-329 ABQ blocker.
7. Revalidate Local live state. Start one detached
   `harness-tmux-codex-monitor` session at 30 seconds under merged code.
8. Let the monitor snapshot all three mappings. Under D-001, Students may be
   repaired immediately because it is idle; Harness must wait until its root
   is idle after the active controller turn.
9. Validate two consecutive passes, exact order, three healthy Codex chains,
   attached-client stability, mode-0600 receipt, dedicated monitor liveness,
   no pane reads/input, and canonical fleet health.

## Rollback and interruption

- Stop only the exact dedicated monitor pane/process after identity readback;
  do not signal the shared tmux server.
- Order swaps are reversible by immutable window ID and do not alter windows,
  panes, threads, or clients.
- A completed leaf signal is not retryable; reconstruct current state and
  either accept the ensuing unwind or stop.
- Removing repository implementation after publication requires a new
  protected change; stopping the monitor leaves the existing resilient
  supervisors unchanged.
- On interruption, resume from `TODO.md`, this plan, Git, live tmux metadata,
  runtime receipts, and current app-server status only.

## Decision register

### D-001 — Lifecycle repair

- **Selected: `safe-auto-repair`.** Automatically repair only saved,
  identity-proven `idle`/`notLoaded` threads while keeping every active,
  unsafe, ambiguous, or unknown case read-only.
- **Alternative: `observe-and-order`.** Enforce ordering and report unhealthy
  lifecycle state, but require a controller turn for every process/window
  restart.

Frozen on 2026-07-28 when the owner answered “as you recommend.” No decision
remains open. Phase is `ready-for-go`; implementation must wait for an explicit
`go`, `proceed`, or `execute`.

## Acceptance

- Exactly `0:harness`, `1:students`, `2:swallow`, one pane each.
- All three satisfy the health contract on two consecutive 30-second passes.
- Both attached clients remain on their pre-activation exact window IDs.
- Monitor status reports running/current and its receipt is mode 0600.
- No pane/transcript read, prompt input/replay, root mutation, app-server
  restart, unrelated window/session change, credential access, or raw bulk
  deletion.
- Focused and complete suites pass; protected CI and reachable-fleet rollout
  are recorded; ABQ remains explicit if still unreachable.
