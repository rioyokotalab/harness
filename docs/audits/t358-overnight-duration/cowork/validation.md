# Validation

## Checks

Frozen acceptance gates C1–C7, verified 05:00–05:25 local 2026-08-01.

- C1 (claude window): `tmux list-panes -t projects:claude` → panes %108/%109
  /%110 at indices 0/1/2, paths `/home/rioyokota/harness`,
  `codex-workspaces/students`, `codex-workspaces/swallow`, all 50x40 (zero
  width variance, equal heights). Launch argv proven from
  `/proc/PID/cmdline`: each pane exactly
  `claude --model fable --effort high --fallback-model opus` at launch;
  the recovered swallow pane (pid 537897) additionally carries `--continue`
  as designed. PASS.
- C2 (codex untouched): pre/post fingerprint of window `@87` identical —
  layout `dd6f,152x40,0,0{50x40,0,0,87,50x40,51,0,99,50x40,102,0,100}`,
  panes %87/%99/%100, same paths and commands. The only new `projects`
  window is `claude` (`@106`). PASS.
- C3 (switch-back, staged): timer v2 (pid 543772, armed 03:51:55, script
  digest recorded) fired at exactly 04:25:00. Per-pane: %110 readiness
  by-construction → one-shot delivery ok; %108/%109 skipped fail-closed on
  the exact-idle-title gate, then %109 received its single first attempt at
  04:27:08 after full identity + `✳ `-prefix idleness re-verification; %108
  needed none (this driver session is itself Fable). No pane received two
  attempts; no ambiguous send was retried; keystroke delivery is reported as
  delivery only. PASS with the recorded finding that the readiness surface
  must match the `✳ ` prefix rather than the launch-time title.
- C4 (survey 5/5): harness, students, swallow, website, personal each have a
  dated survey block in `execution.md` naming instructions read, board state,
  and ranked issues. PASS.
- C5 (per-repo validation, change-class routed):
  - website (docs/ledger + metrics): full offline security suite, metrics
    validate (0 errors), hook doctor ok on `9e1cd10`; merged as `736e14a`.
  - swallow (survey-only): login-safe `tests/test-static.sh` green with the
    documented `SW031_NVIDIA_RUNTIME_PLAN_MODE=render-only`.
  - students (planning-only, no code change): its own cowork protocol,
    receipts `749a4e47…`/`d2e9a0fb…`, worktree preserved uncommitted.
  - personal: survey-only; board empty, all gates owner-held; untouched.
  - harness (lifecycle/validator class → full suite): see phase-1 below.
  PASS.
- C6 (PR economy): website PR #37 (public repo, free Actions) and exactly one
  private-repo PR for harness carrying T-358 + T-359 together as one coherent
  overnight publication. students/swallow/personal: zero PRs. PASS.
- C7 (duration artifacts): seven timestamped evidence-backed slices in both
  the final and durable summaries, each ≥350 words, completed before 05:30.
  PASS.

Harness `harness validate --base main --plan` selected tier R3
(`tests/test-phase1.sh`). Final integrated-tree run: 92 suites PASS,
including the new `test-tmux-claude-monitor.sh` and the unchanged
`test-tmux-codex-monitor.sh`, `test-codex-targets.sh`,
`test-codex-recovery-helper.sh`. Two suites fail on this host only:
`test-tmux-config.sh` and `test-terminfo.sh`, both of which refuse to run
against a dirty checkout; the dirt is the three untracked `libexec/.nfs*`
silly-rename files whose open handles belong to the live codex panes
(`fuser` → pids 1612366/2652612/2995423). Same class recorded in T-357;
protected hosted CI remains authoritative. ShellCheck gate: clean after the
final commit.

## Outcome

All frozen acceptance gates pass. The tmux target reached its accepted state
(claude window mirroring codex; codex byte-identical), the switch-back
executed within its one-shot contract, four of five repositories were
surveyed with no owner-executable work available and the fifth (website)
completed and merged a verified no-op audit, and the owner-ordered T-359
recovery parity shipped with a live drill: killed pane → correct
owner-focus deferral → automatic respawn at 03:50:37 → helper receipt
`completed/worker-success` → monitor 3/3 healthy.

Two additions arrived mid-run by exact owner order and were executed inside
the same session rather than deferred: T-359 (claude pane monitor, recovery
worker, helper client support, pane-border titles) and enabling Claude
Remote Control on the three panes. Both are recorded in `execution.md` with
their own evidence.

## Residual risks

- The idle-title readiness gate is prefix-sensitive (`✳ `); the timer's
  exact-match form would skip a busy-titled idle pane again. Fixed in
  practice this run by the guarded manual attempt; the timer script itself
  still holds the exact-match form and should be updated before reuse.
- `--fallback-model` weekly-limit semantics remain unproven; recorded as
  configured native fallback only. Effective models on %109/%110 are
  delivery-confirmed, not consumption-verified.
- `test-tmux-config.sh` / `test-terminfo.sh` cannot pass locally while the
  `.nfs` handles persist; they clear only when those codex panes restart.
- Claude Remote Control is a research-preview surface; the three Linux panes
  are paired, and pairing is not covered by any harness test.
- Mac remote control is NOT deployed: aist and riken have no Claude
  credentials (OAuth login required, browser-bound) and office is stopped at
  the Bypass Permissions acceptance prompt. Three `claude-rc` tmux sessions
  are parked at those prompts, harmless and reversible
  (`tmux kill-session -t claude-rc`).
- The monitor's attached-dead grace (600s) means an owner watching a crashed
  pane sees repair deferred for ten minutes; live panes are never touched.
