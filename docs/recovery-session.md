# T-171 current recovery session

Updated: 2026-07-15T06:09+09:00

This file is the authoritative cold-restart checkpoint for T-171. Read it
before using the chronological incident record in `TODO.md`. When the two
files appear to conflict, this file describes the current state.

## Current state

- The owner said "continue" after this recovery handoff, which was treated as
  the readiness signal for the owner-edited `~/.ssh/config`. Static validation
  is complete: the path is a regular owner file with mode 0600; all 11 expected
  names parse successfully with `ssh -G`; no literal `TODO` marker remains;
  and no `Match exec` directive is present. An independent declaration audit
  found only 10 of the 11 expected aliases: `si` is not declared. `ssh -G si`
  succeeds only because OpenSSH can expand an undeclared hostname, so that
  parse result is not evidence that the alias exists. No network connection
  was attempted and the file was not changed.
- The owner confirmed that `si` was intentionally removed because its
  configuration could not be recovered. The expected inventory is now 10
  aliases, so the SSH-config recovery subtask is complete.
- After the deletion incident, the owner requested strict reusable guardrails
  for autonomous bulk deletion without approval prompts. The local harness now
  has global guidance, a `guarded-bulk-delete` skill, a deterministic
  `harness guarded-delete` plan/apply tool, Codex execpolicy rejection of raw
  recursive `rm` forms, and a dedicated adversarial regression suite. The
  skill validator, POSIX syntax checks, policy checks, dedicated suite, and
  full phase-1 suite pass. ShellCheck could not run because it is unavailable
  on the recovered node; no package was installed. The fail-closed installer
  created the three intended Codex/shared-agent/Claude discovery links and an
  idempotent repeat retained them. A fresh tool-free Codex process loaded the
  global deletion rule and new skill metadata and returned `GUARD_OK` under
  never/full-access. Final review additionally hardened partial-inventory
  failure, race-free manifest publication, canonical manifest handling, and
  shell-quoted apply output; the dedicated and full suites passed again. The
  implementation and this completed checkpoint form one intended local commit.
- The agent autonomy/configuration recovery is complete. Website T-179
  reconstructed T-11 and the superseding T-170--T-173 global/local split.
  `~/.codex/config.toml` is mode 0600 and now combines the current model
  settings with `approval_policy = "never"`, `sandbox_mode =
  "danger-full-access"`, and trusted entries for both `/home/rioyokota` and
  `/home/rioyokota/website`.
- Harness transaction `20260714T202625Z-3548153` recreated 17 missing links
  and retained eight surviving Claude links. The live discovery surfaces now
  include global Codex guidance, default rules, the harness command, seven
  Codex skill links, and seven shared-agent skill links. A fresh host Codex
  process reported the recovered never/full-access policy and returned
  `GLOBAL_OK SKILL_OK` after loading the global agreements and ledger skill.
- The website task ledger is idle with T-179 complete at local commit
  `e9ac8a0`. The website branch is one commit ahead of `origin/main`; do not
  push it unless the owner asks.
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
- The current task is local deletion-safety hardening after completing the
  SSH-config recovery. It is not home-wide reconstruction, tool installation,
  shell-profile reconstruction, or T-170 fleet rollout. Do not reopen the
  earlier backup-choice gate unless the owner explicitly asks to resume broader
  home recovery.
- No key, passphrase, token, private authentication material, or credential
  value belongs in this checkpoint or in `TODO.md`.

## Next action

No automatic recovery action remains. Wait for the owner; do not modify owner
hooks or product config, push, reopen broader home recovery, or resume T-170
fleet mutation without a new request.

## Working state and boundaries

- Owner-edited working file: `~/.ssh/config`.
- Owner-created file outside this task: `~/.bashrc`.
- Durable task board: `~/harness/TODO.md`.
- This immediate session checkpoint: `~/harness/docs/recovery-session.md`.
- Harness checkout: branch `main`. It includes Node-planner commit `68fb820`,
  the pushed recovery checkpoints through `bc2603f`, and this updated handoff.
  The Node-planner work is valid but unrelated to the next recovery action; do
  not continue tool-planner work during this SSH-config session.
- T-170 remote mutation remains paused while T-171 is active.

## Publication status

- The owner corrected `origin` to `github:rioyokotalab/harness`.
- The owner pushed the recovery checkpoints through `bc2603f`. This handoff
  update is local until separately pushed.
- Website commit `e9ac8a0` records the global-configuration recovery locally
  and is one commit ahead of its remote.

## SSH agent state

- This Codex process inherited `SSH_AUTH_SOCK=~/.ssh/agent.sock`, but deletion
  had removed that stable path even though the owner's renewed agent remained
  live elsewhere.
- Restored `~/.ssh/agent.sock` as a symlink to the live renewed-agent socket.
  An output-suppressed identity probe and a strict read-only GitHub remote-head
  check both pass through the inherited stable path. No identity was listed and
  no key was read.
- The symlink is intentionally machine-local and ephemeral. It survives a
  Codex process restart while that agent remains alive, but must be refreshed
  after the agent exits or the machine restarts. Never commit its target or a
  key passphrase.

## Handoff rule

At every material change, update this file first with the current state, last
verified step, blocker, and one next action. Move detail into the chronological
T-171 record only after the immediate checkpoint is unambiguous. Never leave a
superseded statement in this file.
