# Charter

## Task

T-358: owner-requested overnight duration run (2026-07-31 ~23:21 JST to
2026-08-01 05:30 JST) with Claude as driver and Codex as co-pilot.

Scope, in order:

1. Extend the tmux `projects` session: add a `claude` window mirroring the
   `codex` window — three equal horizontally divided panes at
   `/home/rioyokota/harness`,
   `/mnt/nfs-03/safe/Users/rioyokota/codex-workspaces/students`, and
   `/mnt/nfs-03/safe/Users/rioyokota/codex-workspaces/swallow`, each running
   interactive `claude` with Fable primary and Opus as the sole ordered native
   fallback (`--model fable --effort high --fallback-model opus`).
2. Arm an unattended switch-back: after the owner-stated weekly limit reset
   (~04:21 local, 5 hours after request), restore the three panes to Fable
   (`/model fable` via `tmux send-keys` at 04:25) without stopping sessions.
3. Survey `TODO.md` and repo-local instructions in harness, students, swallow,
   website, and personal; identify executable issues under the owner priority
   autonomy > efficiency > safety (mandatory repository gates remain binding).
4. Execute TODO-driven development independently in those repositories until
   the material-work cutoff, batching commits and minimizing PR count for
   private repositories to conserve GitHub Actions quota.

## Boundaries

- Non-goals: hosting/account administration, workflow dispatch, deployments,
  external messages, package installation, credential access or inspection,
  destructive cleanup, force-push, and any change to the existing `codex`
  window or the `monitor` session.
- Owner authority: the originating owner request explicitly orders execution
  through 05:30 without further input; it is the controlling go for the frozen
  scope above. New material choices outside this scope stop and return to
  owner review.
- Owner priority (autonomy > efficiency > safety) guides issue selection and
  scheduling only; the always-enforce rules of each repository and the
  guarded-deletion, credential, and publication boundaries are not relaxed.
- Each repository is governed by its own closest instructions; harness policy
  is not applied to other roots. Personal stays a non-managed bounded root.
  Time-gated or blocked harness board tasks (T-196, T-328, T-303, T-354
  blocked leg) are not touched early.
- Pane and transcript content of managed Codex windows is never inspected.

## Baseline and sandboxes

- Target: the live tmux server (session `projects`) plus the five repository
  worktrees named above. Sole target writer: the Claude driver.
- Baseline identity: harness `main` at 524b3e785c9a2adfc3f5ed4c470a1b55d49e3a32;
  task branch `claude/t358-overnight-duration`. tmux baseline: `projects`
  session with exactly one window `codex` (3 panes, even-horizontal, paths as
  above).
- Immutable named baseline for sandboxes:
  `/tmp/claude-5035/-home-rioyokota-harness/f44a1376-1af5-490f-aace-349bf3ff5594/scratchpad/t358-baseline`
  (read-only copies of the driver protocol files and governing policy files).
- Two disposable sandboxes built from that baseline:
  `.../scratchpad/t358-driver-sandbox` and `.../scratchpad/t358-copilot-sandbox`.
  Stages are direct children of the co-pilot sandbox; external seals live in
  `.../scratchpad/t358-seals/` outside every co-pilot-writable tree. No
  credentials or private values enter any sandbox, prompt, or artifact.

## Acceptance

- `projects` window `claude` exists with three panes whose widths differ by at
  most one column, correct working directories, and a running `claude` process
  launched with the frozen model flags; `codex` window unchanged in pane
  count, paths, and geometry class from its baseline state.
- Switch-back timer verifiably armed (detached process with recorded PID,
  start time, script digest, and fixed pane-ID targets) and, if the run is
  still live at 04:25, its staged per-pane outcomes logged. Keystroke
  delivery is reported as delivery only; the effective model is recorded as
  confirmed solely from a content-free application surface, otherwise as
  unknown with native fallback left configured.
- A written survey slice per repository (5/5) recorded in the ledger with
  issues ranked by the owner priority.
- Development iterations recorded against the benchmark with per-repo
  validation proportional to the change; no more than one PR per private
  repository for this run unless a repository's own policy requires more.
- Final validation, durable T-358 ledger summary, and final summary each with
  7 timestamped evidence-backed hourly slices and ≥350 words.
- Cleanup: disposable sandboxes and stages removed via the guarded workflow or
  retained and recorded; no residue in the target repositories.
