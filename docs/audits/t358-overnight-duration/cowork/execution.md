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

## Deviations

- Two commentary timestamps early in the run were inferred instead of read
  natively (drift discovered at 23:42 real time); corrected thereafter with a
  fresh `date` read before each update.
- One reflexive `rm -rf` was typed against a not-yet-existing scratchpad
  preimage path (nothing existed, nothing deleted). Barred pattern
  acknowledged; end-of-run cleanup goes through `guarded-bulk-delete`.
- Driver P1 (04:40 refire) withdrawn after co-pilot rejection; timer is
  strictly one-shot.
