# Common acceptance and handoff gates

These common gates neither choose nor load a transaction.

- Require an assistant-bearing completed turn, no active item or `systemError`,
  exact phone/tmux name agreement, a live watcher and TUI socket, and every
  accepted root, name, window, runtime, process, and start identity unchanged
  from its transaction checkpoint.
- Require the accepted target unchanged and the thread's stored CWD equal to
  that closed target's exact repository.
- Require the route-specific saved-root and TUI/launcher state. Require
  unchanged unaffected sessions, shared app server, and attached client, plus
  coherent Git.
- Run native doctor, focused recovery and resilience tests, Git checks, and
  canonical fleet health. Treat every failed query as unknown, never success
  or absence.
- Preserve every sent request ID, acknowledgement, retry-forbidden boundary,
  and final identifier. On drift, stop before the next write and update the
  durable ledger.
- For generated schema bundles, diagnostic trees, or any recursive or
  multi-path cleanup, invoke `guarded-bulk-delete`; never issue recursive
  deletion directly.
