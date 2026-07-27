# Unsafe-tail recovery protocol

## Decision table

| Observed exact state | Action |
| --- | --- |
| Thread healthy; watcher live | No recovery mutation |
| Safe failed tail | One `codex-thread-recovery --recover`, then independent read |
| Rollback acknowledged and thread healthy | Retain the same root and TUI |
| Rollback acknowledged but `systemError` remains | Never retry; use fresh root |
| Unsafe tail or watcher refusal | Use fresh root |
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

## Fresh-root cutover

1. Preserve the poisoned root and live chain as the authority until acceptance.
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
6. Launch one detached provisional tmux window with
   `harness codex-resilient --run --name PROVISIONAL --remote-session NEW_ID`.
   Require exact process/start identities, watcher readiness with zero
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
9. Revalidate every protected identity. Rename the poisoned root to a unique
   blocked label, then the accepted root to the canonical project name. Use
   one read-before/write/read-after transaction per root.
10. Rename only the corresponding tmux windows. Keep the attached client on
    its preflight-selected unaffected window unless the owner explicitly
    requires a switch.
11. Publish the reversible cutover checkpoint.
12. Revalidate the exact old leaf TUI's PID, parent, session, start tick, argv,
    root, and window. Send one `SIGTERM` only to that leaf. Let its launcher
    and supervisor unwind; never send a second signal.
13. If the supervisor becomes a zombie, classify its real TUI/launcher as
    absent and its parent-owned zombie as unreaped. Do not signal the zombie or
    shared tmux server.

## Validation and failure rules

- Require the accepted root/name/window/watcher/TUI/socket and completed turn.
- Require the old saved root preserved and old TUI/launcher absent.
- Require unaffected sessions, app server, and attached client unchanged.
- Run native doctor, focused recovery/resilience tests, Git checks, and
  canonical fleet health.
- Preserve every sent request ID and whether retry is forbidden.
- On any drift, stop before the next write and update the durable ledger.
- Use guarded deletion for generated schema bundles or directory trees.
