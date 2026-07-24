# T-308 managed Mac reboot recovery

## Objective

Make recovery after an ordinary reboot predictable for any managed Mac while
preserving the existing SSH, Git, credential, and remote-control boundaries.

## Frozen design

- Cover only the managed Mac logical hosts `aist`, `home`, `office`, and
  `riken`, each with its independent secondary route.
- Treat physical or local login to the rebooted account and restarting Codex
  remote control as owner actions when macOS does not restore them.
- Preserve the existing remote-control pairing. Re-pair only when the native
  client explicitly requests it.
- Require both reverse routes, current launchd tunnel services and watchdog,
  a clean/current `main` checkout, and the expected remote-control daemon
  topology before Local starts the standard detached Codex tmux session.
- Never inspect tmux pane contents, SSH material, credentials, or private
  process arguments.
- Make status read-only and tmux creation idempotent. Stop on ambiguity.
- Keep repository housekeeping separate. Do not remove, ignore, or specially
  classify `.DS_Store`; any checkout dirtiness blocks automated recovery.

## Acceptance

1. The skill validates structurally and is discoverable by Codex and Claude.
2. Focused fixtures cover route loss, dirty/divergent Git, missing services,
   absent remote control, conflicting tmux state, successful creation, and
   idempotent retention.
3. The complete phase-one suite and protected CI pass.
4. A live read-only status check recognizes Riken's recovered state without
   changing it.
5. Guarded fleet sync advances every clean managed checkout, followed by one
   context refresh for each managed Mac Codex session.

## Acceptance result

PR #306 passed protected CI and merged as
`9203033b3b2d21aab4f0538dfe534e20695d7140`. The skill validator,
warning/error-level ShellCheck, focused fixtures, and complete phase-one suite
passed. Two eight-worker local runs reproduced the existing watchdog cleanup
timing sensitivity; that fixture passed independently and the authoritative
complete suite passed with `HARNESS_TEST_JOBS=1`.

Guarded fleet sync advanced all eleven clean remote checkouts with aligned
`origin/main` and no transfer residue. Exactly one context-refresh instruction
was submitted to each managed Mac Codex session. Final live status recognized
Aist, Home, Office, and Riken with two routes, clean/current `main`, both
tunnel services, watchdog, remote control, and a healthy detached tmux
session. No recovery action removed or classified `.DS_Store`.
