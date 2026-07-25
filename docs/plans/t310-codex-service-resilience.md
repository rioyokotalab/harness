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

Final review moved doctor-gate cleanup ownership out of a command-substitution
subshell and made the state schema strict. Both affected focused suites passed.
A second complete run passed all T-310 coverage but reproduced the unrelated
30-second watchdog cleanup race; its exact focused suite passed immediately in
isolation. Protected CI remains authoritative. The second disposable clone and
manifest were guarded-removed with protected anchors unchanged.

## Acceptance result

PR #310 passed protected `portable-phase1` CI and merged as
`e9c3e060fc8f4b4496331b1235ca23dcb21d79b0`. Local `main` advanced by
fast-forward. Read-only inventory corrected a stale ledger assumption: all
eleven remotes were actually clean on `main` at `5b8d74e`, not `c9926be`.
Guarded fleet sync then advanced every remote directly to `e9c3e06`; the
follow-up plan reported clean `KEEP`, aligned `origin/main`, and no transfer
artifact for every target.

Exactly one post-sync context refresh was submitted to each existing Aist,
Home, Office, and Riken Codex TUI without reading pane contents or replacing
the running process. The supervisor is therefore available everywhere but
activates only at the next deliberate launch; managed Mac reboot recovery
selects it automatically. Rollback remains stopping the foreground supervisor
and launching `bin/harness-codex` directly. No credential, product
configuration, remote-control process, native Codex installation, or
persistent service changed.

Closeout PR #311's initial Harness CI run `30157956314` completed with
`startup_failure`, zero jobs, and no log artifact. Therefore it provided no
test result and made no repository or fleet change. The failure is safe to
supersede through the ordinary protected run triggered by this evidence
checkpoint; no manual workflow rerun was dispatched.

The next ordinary protected run `30158060217` also completed
`startup_failure` with zero jobs. GitHub's
[public status](https://www.githubstatus.com/) currently reports Actions
operational but records a July 25 incident in which Actions run starts were
delayed. This corroborates an external runner-start failure rather than a
repository test result. Checkpoint this evidence once for one final normal
push-triggered run; do not make empty commits or dispatch a retry loop.

The final normal run `30158172731` failed identically with zero jobs. Functional
PR #310 remains merged and synchronized; only ledger closeout PR #311 is
blocked. This terminal evidence is committed locally but is intentionally not
pushed, because another push would violate the no-retry-loop decision. Resume
by waiting for runner provisioning to stabilize or, with explicit owner
authority, run the native `gh run rerun 30158172731` once.
