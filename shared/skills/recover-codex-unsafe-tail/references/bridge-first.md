# Bridge-first fresh-root replacement

1. Preserve the old saved root and live chain as authority until the bridge is
   accepted; do not stop the old chain first. If the real TUI and launcher
   already exited and only an exact parent-owned zombie remains, treat the
   chain as exited. The zombie must not block bridge launch or promotion and
   must not be signaled.
2. Send one initialized app-server `thread/start` with frozen cwd equal to
   `TARGET`'s exact closed-map repository, plus the frozen approval policy and
   sandbox. Record the returned ID immediately; never retry a sent request.
3. Read the empty root with `includeTurns=false`. An unmaterialized
   `includeTurns=true` error does not prove creation failed.
4. Set one unique provisional name and require same-connection readback.
5. Require a canonical current-user-owned, single-link rollout below the Codex
   sessions root. If the installed version creates exact mode `0664`, use a
   no-follow descriptor identity transaction to change only that inode to
   `0600`; reject any other unexpected metadata.
6. Use a distinct provisional root, tmux window, and runtime name. Launch one
   detached bridge with `harness codex-resilient --run --name
   PROVISIONAL_RUNTIME --target TARGET --remote-session NEW_ID`; never reuse
   the canonical window or runtime. Require exact process/start identities,
   watcher readiness with zero rollback/retry counters, and a reciprocal
   established peer to the unchanged app server.
7. Under the shared mode-0600 agent-message lock, send one cold-start turn
   telling the new agent to:

   - never reconstruct or replay the rejected prompt;
   - read complete repository instructions and durable ledgers;
   - inspect branch, worktree, recent commits, and mutable external state;
   - resume only the recorded project next action;
   - preserve unrelated work and leave controller mutations to the controller;
   - remain running and idle in the same thread.

8. Monitor only thread/turn status and item type, role, and status. Accept one
   completed assistant-bearing cold-start turn with terminal tool items, zero
   active items, and no `systemError`.
9. Revalidate every protected identity. Rename the old root to a unique blocked
   label, then the accepted root to the canonical project name, using one
   read-before/write/read-after transaction per root.
10. Promotion is rename-only: rename the accepted bridge window to the
    canonical name while keeping its pane, process, root, runtime name,
    watcher, and socket. Rename a remaining old window to a unique blocked
    label. Never relaunch the bridge during promotion. Keep the attached client
    on its preflight-selected unaffected window unless the owner explicitly
    requires a switch.
11. Publish the reversible cutover checkpoint, then independently revalidate
    the canonical root, window, accepted runtime, watcher, TUI, and socket.
12. Only after promotion and that published checkpoint, revalidate the exact
    old leaf TUI's PID, parent, session, start tick, argv, root, and window.
    Send one `SIGTERM` only to that leaf; let launcher and supervisor unwind,
    and never send a second signal.
13. If the old supervisor becomes a zombie, classify the real TUI/launcher as
    absent and the parent-owned zombie as unreaped. Treat an unreaped zombie as
    already exited but not absent: never signal it or the shared tmux server,
    record its parent-owned reaping boundary, and do not claim a zero-zombie
    gate.

Accept the bridge only with its runtime identity unchanged, the old saved root
preserved, and the old TUI/launcher chain absent under the zombie rule above.

Before bridge launch, retry only a confirmed unsent request. Once a root or
bridge process identity can exist, reconcile an ambiguous acknowledgement
read-only: never create a second root, window, or runtime. After any promotion
write, reconcile names and identities without relaunching. On drift, stop
before the next write and update the durable ledger.
