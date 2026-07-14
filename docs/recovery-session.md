# T-171 current recovery session

Updated: 2026-07-15 JST

This file is the authoritative cold-restart checkpoint for T-171. Read it
before using the chronological incident record in `TODO.md`. When the two
files appear to conflict, this file describes the current state.

## Current state

- The owner is actively completing `~/.ssh/config`. Do not edit, replace, or
  validate it until the owner says the edit is finished.
- The config was reconstructed from the durable, value-redacted connection
  history with 11 aliases: `abci_login`, `ab`, `ab2`, `ri`, `alps_login`, `al`,
  `rc`, `t4`, `si`, `web`, and `github`.
- Before the owner's current edits, the reconstructed config was a regular
  owner file with mode 0600 and all 11 aliases passed `ssh -G`. Those checks
  are stale as soon as the owner changes the file and must not be presented as
  validation of the finished version.
- The owner previously supplied the missing `abci_login` account and reported
  successful strict batch no-op checks for both `ab` and `ab2` from a shell
  with a renewed SSH agent. Preserve that as historical evidence; do not rerun
  a connection merely to reproduce it.
- The owner intentionally wrote a new `~/.bashrc`. Treat it as current owner
  configuration, not as a missing-file or backup-recovery blocker. Do not read,
  replace, or append to it as part of the SSH-config task.
- The current task is SSH-config recovery, not home-wide reconstruction, tool
  installation, shell-profile reconstruction, or T-170 fleet rollout. Do not
  reopen the earlier backup-choice gate unless the owner explicitly asks to
  resume broader home recovery.
- No key, passphrase, token, private authentication material, or credential
  value belongs in this checkpoint or in `TODO.md`.

## Next action

Wait for the owner to say that `~/.ssh/config` is ready. Then perform static
validation only:

1. Check that the path is a regular owner file with mode 0600.
2. Parse all 11 aliases with `ssh -G` and report failures without printing
   expanded identity paths or other authentication values.
3. Report any remaining literal `TODO` markers by alias and field name only;
   do not print credential values or inspect keys.
4. Do not attempt a network connection unless the owner separately requests
   it after static validation.

## Working state and boundaries

- Owner-edited working file: `~/.ssh/config`.
- Owner-created file outside this task: `~/.bashrc`.
- Durable task board: `~/harness/TODO.md`.
- This immediate session checkpoint: `~/harness/docs/recovery-session.md`.
- Harness checkout: branch `main`. It includes Node-planner commit `68fb820`,
  which is valid but unrelated to the next recovery action. Do not continue
  tool-planner work during this SSH-config session.
- T-170 remote mutation remains paused while T-171 is active.

## Handoff rule

At every material change, update this file first with the current state, last
verified step, blocker, and one next action. Move detail into the chronological
T-171 record only after the immediate checkpoint is unambiguous. Never leave a
superseded statement in this file.
