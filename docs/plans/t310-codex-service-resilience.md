# T-310 Codex transient-service resilience

## Objective

Turn transient Codex service failures into a bounded pause followed by safe
continuation of the same saved chat, without replaying a prompt or duplicating
tool and external side effects.

## Frozen design

- Add a portable foreground `harness codex-resilient` supervisor intended to
  run as the Codex command inside the existing persistent tmux topology.
- Launch through the existing `bin/harness-codex` policy wrapper. Do not alter
  credentials, product configuration, remote-control state, or the native
  Codex installation.
- Support a fresh chat, the most recent chat in the current repository, the
  globally most recent chat, or an explicit saved session identifier. Prefer
  the explicit identifier; the two `--last` modes require the established
  one-active-Codex-per-checkout contract.
- After the first launch, every recovery invocation is resume-only and carries
  no prompt. Never replay or synthesize the failed turn.
- Treat exit 0, operator signals, and the CLI usage-error exit as terminal. On
  other nonzero exits, run Codex's redacted native doctor and stop on local
  authentication,
  configuration, installation, or state failure. Retry a locally healthy
  client as a transient service failure.
- Use exponential delays of 15, 30, 60, 120, 240, then 300 seconds, adding
  bounded local jitter. Reset the delay after a Codex process remains alive
  for 15 minutes.
- Keep only value-free, mode-0600 runtime state under a validated
  current-user-only runtime directory. Hold an exclusive per-name lock, write
  state atomically, and leave no captured terminal transcript or private
  diagnostic log.
- Expose read-only plan and status modes. Keep the supervisor in the
  foreground so tmux, launchd, systemd, or a human shell remains the explicit
  lifetime owner.

## Safety and recovery boundaries

- A 503 can occur after a tool or external side effect succeeded. Resuming the
  chat is safe; automatically resubmitting its last prompt is not.
- Codex does not document stable exit-code classes for every provider failure.
  Native doctor therefore gates local permanent failures; a nonzero exit with
  healthy local prerequisites is retried as transient.
- `--last` is deterministic only while no competing Codex session is created
  in the selected scope. Use `--session ID` where concurrent chats are normal.
- The supervisor cannot make an OpenAI outage shorter. It preserves the local
  terminal/session topology and removes the need for repeated manual restarts.
- Rollback is to stop the foreground supervisor and launch
  `bin/harness-codex` directly. No persistent service or owner configuration is
  installed by this task.

## Execution and acceptance

1. Add failing fixtures for argument validation, launch/resume selection,
   no-prompt recovery, terminal exits, doctor-gated permanent failure,
   exponential backoff/reset, exclusive ownership, and value-free state.
2. Implement the command, CLI routing/help, focused-suite registration, and
   operator documentation.
3. Pass shell syntax, warning/error ShellCheck, focused fixtures,
   `git diff --check`, and `tests/test-phase1.sh`.
4. Publish through protected CI, merge, and guarded-sync only clean managed
   checkouts. Do not replace running Codex processes during rollout; adoption
   occurs on their next deliberate tmux restart.

## Current checkpoint

The owner accepted the design and gave explicit go on 2026-07-25. Repository
`main` was clean/current at `c9926be`, including the independently added T-309
plan. Work is isolated in branch `task/t-310-codex-resilience`.

Implementation and focused validation are complete. The supervisor, CLI route,
documentation, durable no-replay rule, and reboot-recovery integration pass
shell syntax, warning-level ShellCheck, `git diff --check`, the new focused
suite, and the updated reboot-recovery focused suite. Complete phase-one and
protected validation remain; rollout must not replace a running Codex process.

The first complete-suite attempt ran from the linked feature worktree. The new
and updated focused suites passed, but legacy fixtures that require `.git` to
be a directory rejected the normal worktree `.git` file, and two existing
parallel Mac timing fixtures failed. The run is non-authoritative and
side-effect free. Rerun from a disposable full clone after the first commit.

The sequential rerun from a disposable full clone passed all focused shards
and every phase-one integration gate. The clone was removed through a guarded
manifest that revalidated 902 entries and 22,220,376 bytes, proved the target
absent and protected anchors unchanged, and was then exact-unlinked.
