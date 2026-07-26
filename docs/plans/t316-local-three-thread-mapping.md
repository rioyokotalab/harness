# T-316 Local three-thread mapping

## Objective

Establish three distinct phone-visible root chats with a one-to-one Local tmux
view:

| tmux window | Phone root | Client |
| --- | --- | --- |
| `students` | existing Students `019f7fea-4f00-7681-910d-81ae99a77143` | existing remote TUI |
| `swallow` | existing Swallow `019f9f69-6b94-70a3-be12-8bef23b88a96` | new remote TUI |
| `harness` | new fork of the current Swallow transcript | new remote TUI |

The fork must preserve the current transcript through the frozen-plan turn,
then diverge under a new root ID. The existing app server and Students client
must not restart.

## Scope and non-goals

In scope:

- the Local `harness` tmux session;
- the current standalone client in window `@42`;
- the existing remote-control app server and its default Unix socket;
- one exact remote resume and one exact remote fork;
- chat naming, metadata-only validation, and exact stale-client cleanup;
- durable recording of the new Harness root ID.

Out of scope:

- app-server restart, re-pairing, connector, plugin, credential, or settings
  changes;
- modification of Students, Swallow SW-031, or another repository;
- prompt injection into Students or Swallow;
- pane-content inspection;
- saved-session deletion, archive, or transcript rewriting;
- changing the generic resilient supervisor in this live transition.

The current `swallow-research` supervisor is intentionally retired after the
remote clients pass. A separate focused implementation may later teach the
supervisor to preserve a remote endpoint across retries; this transition must
not improvise that repository change.

## Confirmed state

At 2026-07-27 06:53 JST:

1. Git branch `t314-local-slack-recovery` was clean and aligned at
   `efd63bf296efa6b021349e51f93f23c150543f93`; this plan branch was created
   directly from that revision after a successful authenticated fetch.
2. The sole attached tmux client selected window `@42`, now named `harness`.
   Window `@46` remains `students`.
3. Window `@42` contains shell PID `1963022`, supervisor PID `2345899`,
   managed launcher PID `2727170`, and real TUI PID `2727307`. The real TUI
   was launched with `resume --last` and owns rollout
   `019f9f69-6b94-70a3-be12-8bef23b88a96`.
4. Window `@46` contains wrapper PID `3024942` and real TUI PID `3025057`.
   Its exact argv uses `resume --remote unix://
   019f7fea-4f00-7681-910d-81ae99a77143`, and socket metadata proves an
   established peer to app-server PID `2852569`.
5. App-server PID `2852569` started at 05:46:46 JST, listens on the default
   current-user Unix socket, and has both the Students and Swallow rollouts
   open. The current standalone TUI has no app-server control-socket peer.
6. The installed CLI and current official manual document `--remote` for
   `resume` and `fork`. The manual describes fork as preserving the original
   transcript while creating a new chat. The TUI exposes `/rename`; installed
   UI strings confirm it opens a name prompt.

Process IDs and timestamps are evidence, not assumptions: every one must be
revalidated immediately before execution.

## Decision register

### D-001 — Identity mapping

Selected directly by the owner:

- retain the existing phone Swallow root as Swallow;
- fork the current transcript into a distinct Harness root;
- expose both through remote-backed tmux windows.

Consequence: Swallow and Harness share history only through the fork point and
then become independent roots.

### D-002 — Transition strategy

Recommended and frozen: staged replacement with rollback evidence.

Create and validate both remote clients before switching the attached view or
stopping the current standalone client. Rename the old window
`harness-stale`, switch the attached client only after the new `harness`
window is accepted, and retire the old exact process/window from the new
Harness root on the continuation turn. This avoids self-termination in the
agent currently driving the transition.

Rejected alternatives:

- hot-attaching PID `2727307` is unsupported;
- in-process `/resume` would remain independent of phone Remote;
- relaunching through `--last` would retain the ambiguity;
- deleting or archiving the shared Swallow root would destroy the desired
  phone thread.

No unresolved owner decisions remain. Execution requires a separate `go`.

## Frozen execution

### Stage 0 — Durable authorization

1. Commit this plan and task-board checkpoint alone.
2. Fetch again, rebase only if the branch is clean and integration is
   unambiguous, and push with an explicit refspec.
3. Do not mutate live clients until the pushed authorization commit is exact.

### Stage 1 — Full preflight

1. Require repository root `/home/rioyokota/harness`, clean task branch, and
   exact pushed HEAD.
2. Require one attached client in tmux session `harness`, active exact window
   `@42` named `harness`, and exact existing `students` window `@46`.
3. Match every recorded process by current user, parent, session, start time,
   executable, and argv. Reject any replacement or extra target client.
4. Match the current rollout descriptor to the exact Swallow UUID.
5. Match the Students process argv and its peer to the unchanged app-server
   control socket. Require filtered native doctor status wholly `ok`.
6. Snapshot metadata-only thread rows and rollout paths. Do not read chat or
   pane content.

Any mismatch stops before a launch, rename, signal, or input.

### Stage 2 — Create the Harness fork

1. Create one detached provisional tmux window named `harness-next` whose
   command is the recognizable native equivalent of:

   `codex --ask-for-approval never --sandbox danger-full-access fork --remote unix:// 019f9f69-6b94-70a3-be12-8bef23b88a96`

   Do not include a prompt.
2. Require one new wrapper/real-TUI chain, an established peer to the unchanged
   app-server socket, and exactly one newly created unarchived root attributable
   to this fork. Record its exact UUID and rollout path.
3. Send `/rename` literally to only the provisional pane, submit it after a
   paste-settle delay, then send `harness` and submit separately. Do not read
   the pane. Require the new thread's persisted name to become `harness`.
4. If identification or naming is ambiguous, leave all original clients
   untouched and remove only the provisional window after exact identity
   revalidation.

### Stage 3 — Create the Swallow view

1. Create one detached tmux window named `swallow` whose command is:

   `codex --ask-for-approval never --sandbox danger-full-access resume --remote unix:// 019f9f69-6b94-70a3-be12-8bef23b88a96`

2. Require its exact target UUID, one new wrapper/real-TUI chain, and an
   established control-socket peer to the unchanged app server.
3. Do not send any input. The existing phone Swallow thread remains the
   authoritative saved root.

### Stage 4 — Cut over the tmux names

1. Revalidate both new clients, Students, the app server, active attached
   client, and current standalone chain.
2. Rename only window `@42` from `harness` to `harness-stale`.
3. Rename only the accepted provisional fork window from `harness-next` to
   `harness`.
4. Switch the sole attached tmux client to the new remote-backed `harness`
   window. Do not type into `students`, `swallow`, or `harness-stale`.
5. Checkpoint the new Harness UUID, process IDs, window IDs, socket peers, and
   exact next action before the current driver yields.

At this point all three desired roots are visible and the active terminal view
is the remote Harness fork. The old standalone process is retained only as
rollback evidence and must not receive input.

### Stage 5 — Continue from the new Harness root

The first owner instruction in the new Harness thread should be `continue`.
That agent must read `AGENTS.md`, `TODO.md`, and this plan completely, inspect
Git and live metadata, and resume only this stage.

1. Verify that the owner is attached to the new remote-backed `harness`
   window, all three remote clients remain connected, and the old exact window
   is inactive.
2. Send one `SIGTERM` only to the old exact real TUI after matching its
   immutable identity. The managed launcher and `swallow-research` supervisor
   must unwind without respawn. Do not signal a process group and do not send
   a second signal or `SIGKILL`.
3. Wait boundedly for the exact old chain to exit. If it remains, stop without
   escalation.
4. Remove only the now-empty `harness-stale` tmux window if it still exists.
   Never invoke `codex delete` or `archive`.
5. Verify the supervisor reports safe stopped or owner-absent residue and that
   no ambiguous `--last` process remains.

## Rollback

- Before name cutover: terminate only a newly created provisional remote TUI
  by exact leaf identity, remove only its window, and preserve both original
  windows and the app server.
- After cutover but before old-client retirement: switch the attached client
  back to exact `harness-stale`, restore its name to `harness`, terminate only
  the two new remote clients, and remove only their windows.
- After the old standalone exits: rollback cannot reconstitute its live
  process. The transcript remains in the Swallow root; start an exact
  remote-backed client for that root rather than using `--last`.

No rollback deletes, archives, rewrites, or re-pairs a saved thread.

## Acceptance

Completion requires all of the following:

1. tmux contains exactly `students`, `swallow`, and `harness` Codex windows,
   with the sole attached client on `harness`;
2. each real TUI has an established peer to the same unchanged app-server
   control socket;
3. Students and Swallow retain their exact original root IDs;
4. Harness has one distinct recorded root ID, a persisted `harness` name, and
   a transcript-preserving fork relationship established by the native
   operation;
5. app-server PID/start identity, pairing, and filtered doctor remain healthy;
6. the old standalone chain and ambiguous supervisor are absent, with no
   respawn;
7. no pane content, credential, chat payload, connector, plugin, setting,
   saved-session archive/delete, or repository outside Harness changed;
8. Git is clean and aligned, focused resilience tests pass, and canonical
   fleet health passes every managed Linux logical node and all four Mac route
   pairs.

## Interruption contract

After any failure or interruption, inspect Git, tmux metadata, exact process
identity, socket peers, state rows, and the task ledger before acting. Never
replay a launch, TUI input, rename, signal, or window removal whose outcome is
ambiguous. Resume from the first unverified numbered step.
