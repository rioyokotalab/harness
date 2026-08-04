# Bridge-first fresh-root replacement

1. Preserve the old root and chain until bridge acceptance; do not stop them
   first. If TUI and launcher exited and only an exact parent-owned zombie
   remains, treat the chain as exited. The zombie
   must not block bridge launch or promotion and must not be signaled.
2. Send one initialized app-server `thread/start` with cwd equal to
   `TARGET`'s exact closed-map repository, frozen approval policy, and sandbox.
   Record its ID; never retry a sent request.
3. Read empty root with `includeTurns=false`. An unmaterialized
   `includeTurns=true` error does not prove creation failed.
4. Set a unique provisional name; require same-connection readback.
5. Require current-user-owned single-link rollout below the Codex sessions
   root. If installed version creates exact mode `0664`, use a no-follow
   descriptor transaction to change only that inode to `0600`; reject other
   metadata.
6. Use distinct provisional root, tmux window, and runtime name. Launch one
   detached bridge with `harness codex-resilient --run --name
   PROVISIONAL_RUNTIME --target TARGET --remote-session NEW_ID`; never reuse
   canonical window or runtime. Require process/start identities, watcher
   readiness with zero rollback/retry counters, and a reciprocal peer to
   unchanged app server.
7. Under the shared mode-0600 agent-message lock, send one cold-start turn
   telling the new agent to:

   - never reconstruct or replay the rejected prompt;
   - read complete repository instructions and durable ledgers;
   - inspect branch, worktree, recent commits, and mutable external state;
   - resume only the recorded project next action;
   - preserve unrelated work and leave controller mutations to the controller;
   - remain running and idle in the same thread.

8. Require assistant-bearing completion, terminal tools, zero active items, and
   no `systemError`. `thread/read` projection may omit TUI tool items; fallback
   through a no-follow descriptor and require paired completed tool-call/output IDs
   without payloads.
9. Revalidate every protected identity. Rename the old root to a unique blocked
   label, then the accepted root to the canonical name, using one
   read-before/write/read-after transaction per root.
10. Root promotion is rename-only. For a window-native target, rename the
    accepted bridge window to the canonical name while keeping its pane,
    process, root, runtime name, watcher, and socket, and rename a remaining
    old window to a unique blocked label. For a declared pane-native target,
    first move the frozen old pane into a unique blocked window with
    `break-pane -d`, then move only the frozen accepted bridge pane into the
    canonical window with `join-pane -d`; set its declared pane-local role,
    canonical title, and position without relaunching either process. Never
    identify a target by the shared window alone. Keep the attached client on
    its preflight-selected unaffected pane unless the owner explicitly
    requires a switch.
11. Publish the reversible cutover checkpoint, then independently revalidate
    the canonical root, window, pane, accepted runtime, watcher, TUI, and
    socket.
12. Only after promotion and that published checkpoint, revalidate the exact
    old leaf TUI's PID, parent, session, start tick, argv, root, window, and
    pane.
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
