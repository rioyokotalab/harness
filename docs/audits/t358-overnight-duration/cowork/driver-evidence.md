# Driver evidence

## Sandbox and baseline

Driver sandbox `scratchpad/t358-driver-sandbox` built from immutable named
baseline `scratchpad/t358-baseline` (charter, plan, benchmark, AGENTS.md,
duration/managed-codex/repository-git policies). The tmux experiment ran in a
disposable scratch session `t358x` (152x40, same geometry class as
`projects`), never touching `projects` or `monitor`. No credentials or
private values entered any sandbox or pane.

## Commands and results

- Q1 (layout): `tmux new-session -d -s t358x -x 152 -y 40 -c ~/harness`;
  `split-window -h` twice with `-c` students, swallow;
  `select-layout even-horizontal`. Result: panes 0/1/2 at harness, students,
  swallow, each exactly `50x40` — zero-column variance, identical to the live
  `codex` window geometry (`dd6f` layout class). Pane order matched the codex
  window without reordering.
- Q3 (flags): `claude --model fable --effort high --fallback-model opus`
  launched interactively in pane 0 with no flag error; TUI reached the idle
  prompt (a promotional Fable notice and "bypass permissions on" from the
  owner's saved settings were displayed; effort indicator showed `high`).
- Q2 (slash command): `tmux send-keys '/model fable' Enter` at the idle
  prompt returned "Set model to Fable 5 and saved as your default for new
  sessions". Observed side effect: the command also persists the default for
  new sessions, which is desirable for the 04:25 switch-back. No preceding
  `C-u` was needed at an idle prompt.
- Cleanup: `/exit` then `kill-session -t t358x`; `list-sessions` shows only
  `monitor` and `projects`.

## Critique

- The benchmark's C1 "pane command `claude` (or `node` hosting it)" is
  correct: the TUI runs under the launching shell, so `pane_current_command`
  may report the node binary name; acceptance should match either.
- The 04:25 switch-back risk list (plan Q5) is real but bounded: if a pane's
  claude exited, `/model fable` types into a shell — mitigate by having the
  timer log pane commands at fire time (no content capture) and skip panes
  whose foreground process is not a claude/node TUI.
- `/model fable` writing the global default means a mid-window fallback to
  Opus does not survive as default; acceptable because the owner wants Fable
  restored at reset anyway.
- The owner's "in 5 hours" reset (~04:21) is approximate; firing at 04:25
  risks a few minutes early if the owner's clock differed. A retry at 04:40
  would cap that risk cheaply.

## Proposed plan changes

- P1. Timer fires twice (04:25 and 04:40) for idempotent robustness;
  `/model fable` at an already-Fable prompt is a no-op-equivalent.
- P2. Timer checks `pane_current_command` per pane and logs a skip instead of
  typing into a dead pane's shell.
- P3. Acceptance C1 explicitly accepts `claude` or `node` as pane command.
