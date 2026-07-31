# Common acceptance and handoff gates

Gates neither choose nor load a transaction.

- Require an assistant-bearing completed turn without active item or
  `systemError`; exact phone/tmux name agreement; live watcher and TUI socket;
  and accepted root/name/window/pane/runtime/process/start identities unchanged
  from their checkpoint.
- Require the accepted target unchanged and its stored CWD equal to the
  closed-map repository.
- Require route-specific saved-root and TUI/launcher state plus
  unchanged unaffected sessions, shared app server and attached client, and
  coherent Git.
- Run native doctor, focused recovery and resilience tests, Git checks, and
  canonical fleet health. A failed query is unknown, never success or absence.
- Preserve sent request IDs, acknowledgements, retry-forbidden boundary, and
  final identifiers. On drift, stop before the next write and update the
  ledger.
- For generated schema bundles, diagnostic trees, or recursive/multi-path
  cleanup, invoke `guarded-bulk-delete`; never issue recursive deletion.
