# Driver execution

## Steps and results

All timestamps are fresh native local reads.

- 23:24 — Session init (driver claude), branch
  `claude/t358-overnight-duration` from `524b3e7`; T-358 record and board
  entry created; next free ID bumped to T-359.
- 23:29 — Driver experiment (scratch session `t358x`, 152x40): three-pane
  even-horizontal reproduces 50x40 exactly; claude 2.1.220 accepts the frozen
  flags interactively; `/model fable` executes at an idle prompt and persists
  the default. Session killed cleanly.
- 23:31 — Iteration 1 (distinct observed failure): first independent codex
  stage from a non-Git scratchpad sandbox was refused by the co-pilot under
  the owner launch sentinel (root not admitted). Kept stage+seal evidence;
  fresh in-repo gitignored sandbox `~/harness/.t358-copilot-sandbox` (repo
  root admitted) staged as `stage-ind2`. No relaunder/blind retry.
- 23:52 — Codex independent evidence imported (receipt valid). Verdict:
  rejected — C3 delivery-vs-switch conflation; index-based targeting. All 12
  proposed changes applied to charter/plan/benchmark.
- 23:58 — Reciprocal pass imported (receipt valid): benchmark accepted as
  amended with 4 clarifications (one-shot only, conjunctive identity guard,
  /proc argv as C1 evidence, readiness joins C3). Reconciliation written;
  both agreement lines recorded; advanced to `executing`.
- 23:44 (real clock; see Deviations) — C1/C2 target execution:
  - Preflight fingerprint: session 152x40; codex window `@87` layout
    `dd6f,...{50x40 %87, 50x40 %99, 50x40 %100}` at harness/students/swallow.
  - Created window `claude` (`@106`) with panes %108 (harness), %109
    (students), %110 (swallow), each pane command
    `exec claude --model fable --effort high --fallback-model opus`.
  - Iteration 2 (distinct observed failures): detached creation defaulted to
    80x24 and `-d` splits mis-ordered panes (harness, swallow, students).
    Fixed with `swap-pane %110<->%109` + `resize-window -x 152 -y 40` +
    idempotent `even-horizontal`. Result: panes 0/1/2 = %108/%109/%110 at the
    three admitted roots, all exactly 50x40.
  - C1 receipt: `/proc/{3062620,3062624,3062635}/cmdline` each exactly
    `claude --model fable --effort high --fallback-model opus`.
  - C2 receipt: post-execution codex fingerprint byte-identical
    (`@87` dd6f layout, panes %87/%99/%100, same paths/commands/geometry).
    Side observation: the codex pane PIDs hold the open handles behind the
    three `libexec/.nfs*` residue files — confirmed non-actionable while
    those sessions live.
- 23:44 — C3 timer armed: detached PID 3069131, fire epoch 1785525900
  (2026-08-01 04:25:00), script digest
  `5681a204ff566454d378e41309ff0f60bb3f64938f9b75a7f7489e0eab17a255`,
  staged log at scratchpad `t358-driver-only/switchback.log` ("timer armed"
  entry present). Guards embedded: fixed pane IDs, expected paths, pane PIDs
  3062620/3062624/3062635, starttimes 124400922/3/4, argv sha
  `5a7f801e...`, claude|node advisory check, readiness by-construction for
  %108/%110 and idle-title match (`✳ Claude Code`) for %109, one-shot
  delivery, no retries, advisory titles logged.
- C4 survey receipts (5/5):
  - harness: active queue fully blocked/time-gated (T-354 blocked, T-196
    gated to 2026-08-02, T-328 gated to outage, T-303 blocked on admin);
    `.nfs` residue non-actionable (live handles); T-358 is tonight's work.
  - students: branch `codex/t043-cli-exchange-diagnostic` at `ce7948b`,
    preserved dirty T-043 record + two cowork handoff dirs; recorded next
    action = fresh Claude session follows successor `START_HERE.md`
    (planning only; owner go required before implementation).
  - swallow: both board tasks owner-blocked (SW-034 W&B connector; SW-031
    owner-stopped). Health: full static suite passes with documented
    `SW031_NVIDIA_RUNTIME_PLAN_MODE=render-only`
    (secret/portability/sw030/sw031/sw032/sw034/ledger/router all pass).
    Cross-task anchors bar new PRs/submissions without fresh authority.
  - website: main clean at `9e1cd10`; board idle ("No active task"); only
    open item is the ruleset zero-approval vs T-198 drift, which requires an
    owner hosting-policy decision; session ledger idle since 2026-07-27.
  - personal: main clean at `a8e60d9`; board empty ("No active Personal
    task"); deferred gates all owner-gated (PIE per budget source; assistant
    GitHub access).

- 23:51–23:54 — C5 harness iteration 3 (distinct observed failure → fix):
  phase-1 run failed four focused suites. Two were real fixture drift from
  the T-358 board entry: `test-task-ledger-routing` (index.tsv must list
  every board task with Next free ID = max+1) and
  `test-context-routing-benchmark` (recorded table pinned to live board
  bytes). Fixed by adding the T-358 `active` index row and regenerating the
  benchmark table/median (96.5%→96.4%); both suites pass. Two remain
  environment-bound: tmux-config and terminfo demand a clean checkout and
  fail on this host solely due to the live `.nfs` handles (same class T-357
  recorded); protected hosted CI remains authoritative. Committed `645ed7e`.
- 23:48–23:54 — website T-211 (verified no-op audit, T-207 pattern): offline
  suite, metrics validate, hook doctor all green on `9e1cd10`; ledger,
  driver report, metrics row, and log line recorded; PR #37 open awaiting
  `Offline checks` (public repo, no private Actions quota impact).
- 23:46 — students pane %109 kickoff delivered; title surface confirmed
  active T-043 BG-003 work; progress monitored via durable repo state only.

- 00:45 checkpoint — students T-043 BG-003 planning is COMPLETE within its
  charter: driver evidence 23:54; staged codex critique imported (26,438
  bytes, receipts `749a4e47…`/`d2e9a0fb…`); reconciliation + benchmark rev 2
  frozen 00:15 (rev 1 rejected by co-pilot over exactly-once semantics;
  driver accepted and added operation-specific terminal cases); T-043 record
  updated 00:16 with an exact owner-go phrase; session at `discussing`;
  nothing implemented, nothing pushed, worktree preserved. Pane %109 idle.
  Switch-back timer PID 3069131 alive; all three panes healthy (`claude`,
  idle titles). No further owner-executable work exists in any of the five
  repositories tonight; remaining slices record stable waits and the frozen
  timer/validation events.

- 02:47–03:40 — T-359 (exact owner order, superseding the frozen T-358
  boundary for this addition): built and deployed Claude pane recovery
  parity. `harness_claude_targets.py` + `claude-session-targets.tsv`
  (closed map, CLAUDE.md marker), `harness-tmux-claude-monitor`
  (content-blind health/order/rate-limited enqueue, `@harness_claude_target`
  roles), `harness-claude-pane-recovery` (respawn-only worker, no -k, dead
  panes only, --continue then plain), additive `--enqueue-claude-blocked`
  helper mode dispatching that worker. Deployed: `remain-on-exit on` on
  projects:claude; monitor session reordered to tunnel/codex/claude/helper
  with the claude monitor live; pane-border titles (top) mirrored onto
  projects:claude and all monitor windows. bin/harness dispatch added.
  Owning suites pass: new claude suite, tmux-codex-monitor, codex-targets,
  codex-recovery-helper (codex path behavior-identical). Committed
  `dc1424b`.
- 03:17 live drill: killed swallow pane claude (pid 3062635) → pane dead
  (remain-on-exit held pane %110). Iterations from observed failures:
  (1) dead panes report empty cwd → dead check now precedes cwd check in
  health/topology/worker verify; (2) recovery correctly deferred
  `deferred-target-attached` because the owner's client sat focused on the
  dead pane — guard demonstrated live; a bounded 600s attached-dead grace
  was then added (live panes remain unconditionally protected), suite
  extended, monitor redeployed 03:40.

## Deviations

- Two commentary timestamps early in the run were inferred instead of read
  natively (drift discovered at 23:42 real time); corrected thereafter with a
  fresh `date` read before each update.
- One reflexive `rm -rf` was typed against a not-yet-existing scratchpad
  preimage path (nothing existed, nothing deleted). Barred pattern
  acknowledged; end-of-run cleanup goes through `guarded-bulk-delete`.
- Driver P1 (04:40 refire) withdrawn after co-pilot rejection; timer is
  strictly one-shot.
- One bare `git push` under the repo's `push.default=matching` fast-forwarded
  local `codex/t356-riken-oauth-bridge` to `3910e45`; that commit is
  already-merged public main history, so no new content was published.
  Explicit refspecs are used for every subsequent push.
