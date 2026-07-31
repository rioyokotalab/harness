# Reconciliation

## Evidence accepted

- Driver scratch-session experiment: 152x40 three-pane even-horizontal
  layout reproduces exactly (50 columns each); claude 2.1.220 accepts
  `--model fable --effort high --fallback-model opus` interactively;
  `/model fable` executes at a known idle prompt and persists the default.
- Codex independent pass (imported, receipt `receipts/independent.json`):
  index-based targeting and delivery-equals-switch conflations are real
  defects; 12 changes proposed, all applied to charter/plan/benchmark.
- Codex reciprocal pass (imported, receipt `receipts/reciprocal.json`):
  benchmark accepted as amended, with four clarifications, all adopted:
  1. one attempted delivery per pane at 04:25 only; no unconditional second
     fire; a conclusively skipped pane may receive its first attempt later
     only after fresh identity and readiness checks;
  2. conjunctive guard — fixed pane ID, expected path, live pane, recorded
     pane PID and process birth identity, `/proc` cmdline digest match;
     generic `node` or shell fails closed;
  3. `claude|node` compatibility applies only to the advisory
     `pane_current_command` field; C1 acceptance evidence is exact
     `/proc/PID/cmdline` argv;
  4. pre-fire readiness joins C3; if a known empty prompt cannot be
     established without prohibited content inspection, delivery is skipped
     and the effective model reported unknown.

## Disagreements and uncertainty

- Driver P1 (unconditional 04:40 refire) was rejected by the co-pilot and is
  withdrawn; the frozen timer is strictly one-shot per pane.
- Readiness without content inspection: for panes that have received zero
  input since launch (harness, swallow), the driver holds readiness is
  established by construction from the recorded input ledger; this does not
  conflict with clarification 4 because no content inspection is needed. The
  students pane will have received one kickoff prompt; its readiness must
  come from a content-free surface (launch-time idle `pane_title` match) or
  delivery is skipped and reported unknown.
- Weekly-limit fallback semantics of `--fallback-model` remain unproven and
  are recorded as configured native fallback only.
- The ~04:21 reset time is an owner-stated estimate; a single 04:25 fire with
  unknown-model reporting caps the risk without ambiguous retries.

## Frozen plan

The amended `plan.md` steps 1–7 with the clarifications above; sole target
writer is the Claude driver; the timer embeds fixed pane IDs, expected paths,
recorded pane PIDs, birth identities, and cmdline digests at arm time, logs
staged outcomes (armed identity, per-pane guard, readiness, one-shot
delivery, advisory title), and never retries an attempted or ambiguous send.

## Acceptance gates

Benchmark C1–C7 as amended, with C3 extended by clarification 4. Owner go:
the originating 2026-07-31 request explicitly orders execution through 05:30
for exactly this frozen scope. Rollback: `kill-window -t projects:claude`
restores the tmux baseline; the task branch is unpublished until validation;
sandboxes and stages are disposable and recorded.
