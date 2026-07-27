# T-318 Codex thread `systemError` recovery

## Objective

Extend the existing foreground Codex resilience path beyond process-level
transient exits. Recover an exact remote-backed thread when Codex remains live
but a rejected turn leaves the app server in persistent `systemError`, without
restarting the shared app server, replaying a prompt, or discarding a turn that
may have produced side effects.

## Evidence

- On 2026-07-27, exact Swallow thread
  `019f9f69-6b94-70a3-be12-8bef23b88a96` rejected six consecutive turns with
  no assistant item. Its TUI, resilient supervisor, and shared app server
  remained live. Restarting only the exact TUI child reconnected the same
  thread but did not clear `Request blocked`.
- An initialized app-server `thread/read` returned exact status
  `systemError`. One acknowledged `thread/rollback` with `numTurns=6`
  preserved 37 earlier turns and appended a durable `thread_rolled_back`
  marker. The next diagnostic completed and produced an assistant message.
- OpenAI's app-server protocol defines `thread/read`, thread status, and
  `thread/rollback`; rollback changes model-visible history and does not undo
  local file changes. Therefore automatic rollback is safe only when the
  rejected tail contains no possible side-effect event:
  <https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md>
- Open Codex issue #32177 independently reports the same persistent
  `Request blocked` behavior after a rejected attachment turn, including
  survival across process restart:
  <https://github.com/openai/codex/issues/32177>

## Frozen safety boundary

1. Operate only on an exact safe thread identifier selected through
   `--remote-session`; `--last`, new, and repository-relative selectors are
   excluded.
2. Require an initialized local app-server control connection, exact
   `thread/read` identity, and status `systemError`.
3. Validate the returned rollout as a current-user-owned, single-link regular
   file canonically below `$CODEX_HOME/sessions`, with matching session
   metadata.
4. Reconstruct logical turns while applying every durable
   `thread_rolled_back` marker. The recoverable suffix is one to eight
   consecutive completed turns that contain user input, contain no assistant
   message, and contain no tool call/output, command, patch, web search,
   external action, or unknown event.
5. Re-read the exact thread and revalidate rollout identity/size immediately
   before one rollback request. Serialize against Harness agent-message
   injection with its current-user mode-0600 advisory lock.
6. Treat an acknowledged rollback as committed. A transport failure after the
   request is sent is ambiguous and permanently blocks automatic retry until
   read-only reconciliation.
7. Never replay, synthesize, or reinsert the removed prompt. Never restart or
   signal the shared app server, another TUI, or a process group.

## Implementation stages

1. Add a Python-3.6-compatible, dependency-free
   `harness codex-thread-recovery` command with plan, status, one-shot recover,
   and watch modes. Keep only value-free mode-0600 runtime state.
2. Add deterministic rollout fixtures for safe tails, rollback markers,
   unsafe/unknown events, excessive tails, active turns, identity/path drift,
   and acknowledged versus ambiguous rollback.
3. Exercise the real Unix-WebSocket handshake and JSON-RPC method shapes
   against a local fake server.
4. After the helper passes independently, have
   `harness-codex-resilient --remote-session ID` own one watcher for that
   exact ID. Fail before TUI launch if the watcher cannot establish its
   value-free readiness state; stop and reap it with the supervisor.
5. Run syntax/static checks, focused suites, `git diff --check`, and the full
   Phase-1 suite from a clean full clone. Publish through protected CI before
   any live-supervisor adoption.

## Rollback

Before live adoption, revert the task commits. After publication, deliberate
TUI restarts can launch the prior direct `harness-codex-login` route or a
supervisor revision without the watcher. Existing rollback markers remain
part of Codex's durable thread history and are never edited directly.
