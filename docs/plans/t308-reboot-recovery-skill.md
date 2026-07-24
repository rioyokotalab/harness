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

## Current checkpoint

The skill validator, warning/error-level ShellCheck, focused fixtures, and a
live read-only Riken status check pass. Riken was recognized with two routes,
clean/current `main`, both tunnel services, watchdog, remote control, and a
healthy detached tmux session. The first complete phase-one run passed the new
suite; only the existing tmux and terminfo fixtures refused because they
require a clean committed checkout. From the clean implementation commit, two
eight-worker runs reproduced the existing watchdog cleanup timing sensitivity;
that fixture passed independently and the complete phase-one suite passed with
`HARNESS_TEST_JOBS=1`, including all focused shards and integration gates.
Protected publication is next.
