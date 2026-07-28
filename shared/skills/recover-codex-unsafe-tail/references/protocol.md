# Unsafe-tail recovery protocol

## Decision table

| Observed exact state | Action |
| --- | --- |
| Thread healthy; watcher live | No recovery mutation |
| Safe failed tail | One `codex-thread-recovery --recover`, then independent read |
| Rollback acknowledged and thread healthy | Retain the same root and TUI |
| Rollback acknowledged but `systemError` remains | Never retry; use bridge-first fresh root |
| Unsafe tail, watcher refusal, or authorized root/TUI replacement | Use bridge-first fresh root |
| App-server/identity/metadata unknown | Stop and checkpoint |

## Safe-tail transaction

1. Publish exact root, process, socket, tmux, Git, and unaffected-session
   identities.
2. Re-run the analyzer immediately before the write.
3. Invoke `harness codex-thread-recovery --recover --name NAME --thread ID`
   once.
4. If acknowledgement is absent or ambiguous, perform only fresh read-only
   reconciliation.
5. Independently read the root. Accept recovery only when it no longer reports
   `systemError`. If it remains poisoned, do not issue another rollback.

## Bridge-first fresh-root cutover

1. Preserve the old saved root and live chain as the authority until the bridge
   is accepted. Do not stop the old chain first. If its real TUI and launcher
   have already exited and only an exact parent-owned zombie remains, treat
   that chain as exited; the zombie must not block bridge launch or promotion
   and must not be signaled.
2. Send one initialized app-server `thread/start` with the frozen cwd,
   approval policy, and sandbox. Record the returned ID immediately. Never
   retry a sent request.
3. Read the empty root with `includeTurns=false`; an unmaterialized
   `includeTurns=true` error does not mean creation failed.
4. Set one unique provisional name. Require same-connection readback.
5. Require a canonical current-user-owned, single-link rollout below the
   Codex sessions root. If the installed version creates exact mode `0664`,
   use a no-follow descriptor identity transaction to change only that inode
   to `0600`; reject other unexpected metadata.
6. Use a distinct provisional root, tmux window, and runtime name. Launch one
   detached bridge with
   `harness codex-resilient --run --name PROVISIONAL_RUNTIME
   --remote-session NEW_ID`. Do not reuse the canonical window or runtime
   name. Require exact process/start identities, watcher readiness with zero
   rollback/retry counters, and a reciprocal established peer to the unchanged
   app server.
7. Under the shared mode-0600 agent-message lock, send one cold-start turn.
   Tell the new agent to:

   - never reconstruct or replay the rejected prompt;
   - read complete repository instructions and durable ledgers;
   - inspect branch, worktree, recent commits, and mutable external state;
   - resume only the recorded project next action;
   - preserve unrelated work and leave controller mutations to the controller;
   - remain running and idle in the same thread.

8. Monitor only thread/turn status and item type/role/status. Accept one
   completed assistant-bearing turn with terminal tool items, zero active
   items, and no `systemError`.
9. Revalidate every protected identity. Rename the old root to a unique blocked
   label, then the accepted root to the canonical project name. Use one
   read-before/write/read-after transaction per root.
10. Promotion is rename-only: rename the accepted bridge's tmux window to the
    canonical window name while keeping the same pane, process, root, runtime
    name, watcher, and socket. Rename the old window to a unique blocked label
    when it still exists. Never relaunch the accepted bridge during promotion.
    Keep the attached client on its preflight-selected unaffected window unless
    the owner explicitly requires a switch.
11. Publish the reversible cutover checkpoint and independently revalidate the
    canonical root, window, accepted runtime, watcher, TUI, and socket.
12. Only after the accepted bridge is promoted and its checkpoint is
    published, revalidate the exact old leaf TUI's PID, parent, session, start
    tick, argv, root, and window. Send one `SIGTERM` only to that leaf. Let its
    launcher and supervisor unwind; never send a second signal.
13. If the old supervisor becomes a zombie, classify its real TUI/launcher as
    absent and its parent-owned zombie as unreaped. Do not signal the zombie or
    shared tmux server.

## Validation and failure rules

- Require the accepted root/name/window/watcher/TUI/socket and completed turn.
- Require the old saved root preserved and old TUI/launcher absent.
- Require unaffected sessions, app server, and attached client unchanged.
- Run native doctor, focused recovery/resilience tests, Git checks, and
  canonical fleet health.
- Preserve every sent request ID and whether retry is forbidden.
- Before bridge launch, a confirmed unsent request may be retried. After a
  root or bridge process identity can exist, ambiguous acknowledgement is
  read-only reconciliation territory: never create a second root, window, or
  runtime. After any promotion write, reconcile names and identities without
  relaunching.
- On any drift, stop before the next write and update the durable ledger.
- Use guarded deletion for generated schema bundles or directory trees.
