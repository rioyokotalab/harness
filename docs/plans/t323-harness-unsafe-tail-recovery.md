# T-323 Harness unsafe-tail recovery

## Objective

Restore a working phone-visible and tmux-visible Harness thread without
discarding real work from poisoned root
`019fa076-7132-7992-800e-f6c6d4aeadfb`.

## Confirmed state and decision

The active root is `systemError`, and the published analyzer refuses recovery
at old-rollout metadata validation because that rollout remains group-writable.
Its tail is therefore not proven safe for rollback. Window `@49:harness` is live under
supervisor `4063793`, wrapper `4063851`, and real TUI `4064616`, but legacy
runtime name `harness-canary` has no watcher. App server `2852569`, Students,
and Swallow are healthy and out of mutation scope.

The owner authorized the recommended fresh-root cutover with explicit `go`.
No decision remains open.

## Scope and prohibitions

Create exactly one empty app-server root, one provisional name, and one
provisional watched TUI. Submit exactly one identified cold-start turn that
recovers exclusively from the repository instructions, ledger, Git, and
mutable-state checks.

Do not roll back, fork, resume, archive, delete, or inspect content from the
poisoned root; replay or reconstruct its rejected prompt; restart or signal
the shared app server; inspect panes/transcripts; change Students or Swallow;
retry an ambiguously acknowledged request; send a second signal; use
`SIGKILL` or process-group signaling; or touch the live `.nfs` inode.

## Execution

1. Publish this plan and the exact old identities before any live write.
2. Revalidate clean/aligned Git apart from the known `.nfs` inode, exact tmux
   mapping, old process/start/argv identities, app-server identity/socket,
   `systemError` plus unsafe-tail classification, and value-free doctor.
3. Send one initialized Unix-WebSocket `thread/start` with Harness cwd,
   danger-full-access sandbox, and never approval. Require one acknowledged
   new ID, exact idle/zero-turn readback, and no retry on ambiguity.
4. Set provisional name `harness-recovery-20260727` once, then require its
   canonical current-user/single-link rollout. If initial mode is exactly
   `0664`, tighten only its descriptor to `0600`; reject all other unsafe
   metadata or modes.
5. Launch detached `harness-next` under supervisor name `harness-recovery`
   with `--remote-session NEW_ID`. Require exact process identities, watcher
   readiness, retry counters zero, and an established peer to unchanged app
   server `2852569`.
6. Under the shared agent-message lock, submit exactly one identified
   cold-start instruction. It must read `AGENTS.md` and `TODO.md` completely,
   inspect branch/worktree/recent commits and mutable external state, resume
   only the recorded T-323 next action, prohibit rejected-prompt replay, and
   remain in the new Harness thread.
7. Accept only after value-free protocol structure proves one completed
   assistant-bearing turn, balanced tool records, no active item, and no
   `systemError`. Do not inspect message text.
8. Revalidate Students/Swallow/app server unchanged. Rename old root to
   `harness-blocked-20260727`, new root to `harness`, old window to
   `harness-blocked`, and provisional window to `harness`; switch the exact
   attached client only after complete read-before/write/read-after gates.
9. Revalidate immutable old leaf identity and send one `SIGTERM` only to that
   real TUI. Let wrapper/supervisor unwind without respawn; preserve the saved
   poisoned root. Remove only an empty stale tmux window if independently
   proven safe.
10. Validate new root/watcher/TUI/socket, absent old chain, preserved blocked
    root, exact tmux mapping, unchanged Students/Swallow/app server, doctor,
    Git, residue, and canonical fleet health. Publish the execution ledger
    through protected Git.

## Failure and recovery

Before cold-start submission, remove only an unambiguously failed provisional
window/process chain; preserve every created root. After an acknowledged
cold-start, do not retry or remove it—reconcile read-only state. Before
cutover, old Harness remains authoritative. After cutover, the old saved root
remains rollback evidence but must not be relaunched without a new plan.

## Acceptance

- Phone and tmux `harness` identify the same new exact root.
- Its supervisor and watcher are live and not blocked.
- One completed assistant-bearing cold-start turn exists without
  `systemError`.
- Students, Swallow, and app server retain their exact identities.
- The poisoned root remains preserved and its live chain is absent.
- No prompt replay, unsafe rollback, pane/transcript read, app-server restart,
  archive, deletion, second signal, process-group signal, or `SIGKILL`
  occurred.
- Git is coherent and canonical fleet health passes.

## Execution result

Fresh root `019fa3ae-6ad0-7642-aeca-b7b52421f576` and cold-start turn
`019fa3b1-741c-77b2-aa01-60285d99e39a` passed every persistence, watcher,
assistant-bearing completion, name, tmux, process, socket, doctor, and Git
gate. Phone and active tmux name are `harness`; runtime supervisor name is
`harness-recovery`.

The poisoned root remains preserved as `harness-blocked-20260727` with no live
process chain. Students, Swallow, and the shared app server were unchanged.
Only the generated schema bundle and task-created Python cache were removed
through guarded deletion.
