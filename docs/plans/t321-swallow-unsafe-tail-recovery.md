# T-321 Swallow unsafe-tail recovery

## Objective

Restore a working phone-visible and tmux-visible Swallow Codex thread without
discarding real SW-031 work from the current poisoned root.

## Confirmed state

- At 2026-07-27 20:24 JST, tmux window `@58`, index 2, remains named
  `swallow` and is not the owner's active Harness window.
- Exact resilient supervisor PID `382132` still selects remote root
  `019fa27c-6280-7f00-8e46-ef878875562b`.
- Exact watcher PID `382211` remains its child.
- Supervisor status is `running/remote-explicit`, attempt zero, delay zero.
- Watcher status is `blocked/unsafe-tail`, with one recovery and one rolled
  back turn already recorded.
- The owner observes persistent `Request blocked`.
- No pane or rollout content was read. Diagnosis changed no process, tmux,
  thread, prompt, app-server, repository, or external state.

The watcher refusal is a safety result, not a failed supervisor. The current
tail is not proven assistant-less and side-effect-free. Another rollback could
remove tool-bearing project work. Restarting the current TUI would resume the
same root, and the earlier T-318 incident proved that forking a poisoned root
can inherit the error.

## Scope and non-goals

Scope is limited to Local's exact Swallow remote root, its exact tmux window,
one new app-server thread, one provisional remote-backed TUI/supervisor, and
one identified cold-start instruction.

Do not:

- roll back, archive, delete, rename, or otherwise mutate the blocked root
  before the new root is independently accepted;
- replay, reconstruct, or reinsert the rejected prompt;
- inspect pane text, transcript payloads, credentials, or private project
  contents;
- restart or signal the shared app server, Harness, or Students clients;
- change the Swallow repository or execute SW-031 research from Harness;
- reuse a request after ambiguous acknowledgement.

## Execution plan

1. Publish this plan and record decision D-001. Wait for a separate explicit
   owner `go`.
2. Revalidate exact Git, tmux window, supervisor/watcher/TUI identities,
   current root ID, app-server identity/socket, value-free doctor result, and
   the unchanged `blocked/unsafe-tail` receipt. Stop on drift.
3. Through one initialized Unix-WebSocket transaction, invoke one exact
   `thread/start` with the current frozen cwd, approval, and sandbox settings.
   Require an acknowledged response with exactly one new root, then read it
   back as idle with zero turns. An ambiguous acknowledgement is
   non-retryable.
4. Give the new root a unique provisional name through one acknowledged
   `thread/name/set` and same-connection readback. Preserve the old root name
   and metadata until acceptance.
5. Create one detached provisional tmux window and launch
   `harness codex-resilient --remote-session NEW_ID` with a distinct
   provisional supervisor name. Require exact process/start identities, one
   ready watcher receipt, and an established peer to the unchanged app-server
   socket. Stop and remove only the provisional chain if launch acceptance
   fails unambiguously.
6. Under the shared mode-0600 agent-message lock, submit exactly one identified
   cold-start instruction to the new root. It must tell Swallow Codex to read
   its own `AGENTS.md` and `TODO.md` completely, inspect its branch, worktree,
   recent commits, and mutable external state, and resume only the durable
   SW-031 next action. It must explicitly prohibit reconstructing or replaying
   the rejected prompt. Treat an ambiguous submission as non-retryable.
7. Accept the new root only after value-free protocol metadata proves a
   completed turn with at least one assistant message, balanced tool-call
   records if any, and no `systemError`. Do not judge research correctness or
   inspect message text from Harness.
8. Revalidate Harness and Students unchanged. Rename the old tmux window to a
   unique blocked label, rename the accepted provisional window to `swallow`,
   and keep the owner on `harness`. Set the accepted root's visible name to
   `swallow` only after exact read-before/write/read-after gates; retain the
   old root with a unique blocked name rather than deleting it.
9. Stop only the old Swallow TUI by its exact immutable identity and let its
   supervisor/watcher unwind normally. Do not signal a process group or shared
   server. Preserve the old saved root.
10. Validate exact three-window mapping, new remote root/watcher readiness,
    absent old live chain, unchanged app server/Harness/Students, native
    doctor, Git, and canonical fleet health. Record all identifiers and
    acknowledgements in `TODO.md`.

## Failure handling and rollback

- Before step 6, rollback removes only an unambiguously created provisional
  window/process chain; the new empty root remains preserved if permanent
  deletion is not separately authorized.
- After the cold-start instruction is acknowledged, do not retry or remove
  the root. Reconcile read-only state and stop on ambiguity.
- Before cutover, the old `swallow` window remains authoritative.
- After cutover, the preserved blocked saved root remains rollback evidence,
  but its poisoned TUI must not be relaunched without a new plan.
- No failure authorizes `thread/rollback`, app-server restart, `SIGKILL`,
  process-group signaling, prompt replay, archive, or deletion.

## Acceptance

- The phone and tmux `swallow` surfaces identify the same new exact root.
- Its supervisor and watcher are live and value-free status is not blocked.
- A completed assistant-bearing cold-start turn exists without
  `systemError`.
- Harness and Students processes, roots, sockets, and windows are unchanged.
- The old blocked root remains preserved while its live process chain is
  absent.
- No rejected prompt was replayed and no pane/transcript content was read.
- Git remains coherent and canonical fleet health passes.

## Decision register

### D-001 — Recovery action

Selected by the owner as recommended: create the reversible fresh root and cut
over only after its cold-start turn passes all gates. This restores Swallow
while preserving the blocked root and its real work.

Alternative: make no live change and leave Swallow unavailable. This has the
lowest immediate mutation risk but provides no working SW-031 agent.

No other decision is open. The plan is frozen at `ready-for-go`; wait for a
separate explicit execution instruction. Recording D-001 changed no thread,
tmux, process, app-server, prompt, or project state.
