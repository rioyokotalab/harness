# Claude midpoint review — Har-379 T-293 Aist validation

- Request ID: `aist-20260802-midpoint-01`
- Reviewer: Claude Code (read-only co-pilot), 2026-08-02, after slice 3
- Scope reviewed (each read completely): worktree `AGENTS.md`, `PRODUCER.md`,
  `docs/producer/tasks/Har-379.md`, `TODO.md`, `docs/tasks/Har-379.md`,
  `docs/plans/har379-t293-aist-validation.md`,
  `docs/audits/har379-t293-aist-validation/time-slices.md`, and
  `docs/audits/har379-t293-aist-validation/claude-plan-review.md`, plus the
  read-only repository verification listed at the end. Evidence considered
  only through the slice-3 close at 16:47:47 JST.

## Verdict

**CONTINUE-WITH-CONDITIONS.**

The frozen pilot requirements were satisfied as recorded: every pre-pilot
condition from plan review `aist-20260802-01` was pinned before the kick, the
sole authorized kick was exactly acknowledged and never retried, the managed
generation changed, both routes were healthy within three seconds against the
frozen 30-second bound, the sibling stayed ready at every snapshot, and
post-pilot ownership, authentication, watchdog, and fleet health passed.
Slices 1–3 closed healthy on cadence. The producer/consumer reconciliation is
verifiable in repository history and preserved every prior ref. No T-293
self-healing defect is demonstrated. The conditions below concern ledger
classification and final-audit reporting, not target safety; none requires
stopping observation or permits new target mutation.

## Assessment against the request

### Frozen pilot requirements

All five conditional-go gates from the plan review are resolved in the task
record's "Pre-pilot protocol" section: a 30-second wall-clock recovery bound
with one-second snapshot cadence (F1), a control channel — the ordinary
`login` ControlMaster, current-user-owned and distinct from both launchd
reverse-tunnel processes, with `ControlMaster=no`/`ControlPath=none` return
probes (F2), per-snapshot sibling checks with immediate stop on sibling
failure (F4), an exact three-class acknowledgement contract for
`harness macos-tunnel-supervisor --host aist --kick tunnel` with ambiguity
permanently foreclosing retry (F5), and the slice-3 midpoint boundary (F6).
The recorded pilot outcome (14:03:56 JST exact acknowledgement, changed
generation, three-second recovery, sibling ready in both snapshots, healthy
14:04:00 watchdog run, passing 14:04:48 fleet-health) satisfies acceptance
items 3 and 4 as written. I cannot independently re-observe runtime state
from this review's file-scoped vantage; the recorded evidence is internally
consistent, timestamped, and value-free.

### Disclosed file-tooling deviation

Properly handled. The deviation from the original "no tools" shorthand is
pinned in the task record, reflected in amended plan steps 2 and 6, and
repeated in the slice ledger. The security boundary it preserves — no target
tools, credentials, private logs, pane or transcript reads, or target
mutation — held for the plan review and holds for this midpoint review.
Condition: the final acceptance audit must report the deviation against the
still-unchanged literal wording of acceptance item 6, as the record already
requires.

### Producer/consumer reconciliation

Verified in repository history from this worktree: protected main advanced
`572a62a` → `2568e1f` (producer protocol) → `708334a` (Har-379 packet) →
`69ba0a6` (transport fixes); the consumer chain `00b9f42` (claim) →
`a1e5301` → `3b0519e` → `bc71c4d` (clean merge of `69ba0a6`) → `3a7f9bd` →
`176686f` is clean, and the worktree has zero dirty paths. All six pre-squash
checkpoints (`1104e51`, `d35bf9d`, `95df6a4`, `477514e`, `682157e`,
`bf5236a`) still resolve locally, and both preservation branches
(`codex/har377-t293-aist-cowork-pre-reconcile`,
`codex/har379-t293-aist-pre-producer-reconcile`) exist — the packet's
preserve-both-refs gate is met on the local side. The local branch retains
the frozen old name `codex/har377-t293-aist-cowork` for the running observer,
consistent with the packet. Remote state (the stale `har378` branch at
`bf5236a`, the `har379` remote branch) was not re-verified because this
review performs no network operations; treat that as unverified-here, not
absent. The record's claim that producer validation, consumer-diff
enforcement, and task-ledger routing pass on the protected base was not
rerun here (no runtime tools) and belongs in the final integrated check.

### Is any self-healing defect demonstrated?

**No.** Every recorded observation of the T-293 system is healthy: the pilot
recovered in three seconds without watchdog intervention, three slices show
exclusive managed ownership, ready unattended authentication, healthy
no-recovery watchdog runs, and passing Local-vantage probes for every
declared pair. No speculative change is therefore authorized — acceptance
item 7's null branch applies to the self-healing system.

However, one *non-target* defect was demonstrated during the window: the
slice-2 checkpoint push continued after its expected-old-main comparison
failed because a fail-fast guard was missing, advancing the stale Har-378
branch to `bf5236a` — an unintended external write, bounded and disclosed.
See F1; this is the main open classification decision.

## Findings (severity-ranked)

### F1 — MEDIUM: the fail-fast push gap is demonstrated but unclassified

The record narrates the missing expected-old-main fail-fast guard and its
consequence (an unintended advance of the stale branch), but the ledger never
classifies it. Two consistent resolutions exist: (a) if the guard belongs to
repository-native tooling used by this task, it is a demonstrated in-window
defect — the fix needs reproduction, owning focused tests, deterministic
validation, and protected publication before the 19:47:47 cutoff under
acceptance item 7; or (b) if it is task-execution scripting outside the
T-293 scope, `PRODUCER.md`'s writer contract requires a blocked receipt under
`docs/consumer/receipts/` (out-of-scope finding), not silence. The completion
audit's current "No defect demonstrated" wording conflates "no self-healing
defect" (true) with "no defect at all" (false as recorded). Classify
explicitly before final acceptance; do not leave it narrative-only.

### F2 — LOW: two acceptance wordings now require deliberate final-audit reconciliation

Besides the disclosed "no tools" deviation, acceptance item 1 and the frozen
benchmark still name baseline `bbc2a4b`, while protected main legitimately
advanced through `572a62a`, `708334a`, and `69ba0a6` and the task reconciled
onto each cleanly. The final audit must read item 1 as "clean/aligned on
current protected main, with the advance chain recorded" and say so, exactly
as it must report the tooling-wording deviation — otherwise a literal reading
fails a criterion the evidence actually satisfies.

### F3 — LOW: pilot and slice evidence is single-vantage narrative

Slice entries record timestamps and value-free states but not the raw
snapshot outputs. That matches acceptance item 5 as written; note for final
acceptance that the durable proof is the ledger narrative plus repository
identity, and cite watchdog run times and snapshot timestamps exactly as
recorded. No change requested — just do not claim raw-output provenance the
artifacts do not contain.

### F4 — LOW: stale-ref disposition needs recorded authority at handoff

The stale remote Har-378 branch and the two local preservation branches must
outlive the observer, then be dispositioned. Branch deletion is a separate
external-write authority; the handoff should record the exact refs, the
condition for release (observer completion), and the required authority
rather than cleaning up inside this window.

### F5 — LOW: remaining slices depend on the armed observer

Slices 4–7 must come from the 14:07:03 observer at the exact boundaries. If
the observer fails or a boundary sample is missing, record the gap honestly
and continue; do not fabricate or split observations (the ledger already
states this), and do not rename the frozen branch before the observer
completes. Slice 7 must contain only integrated validation and handoff.

## Exact remaining evidence for final acceptance

1. Slice 4, 5, 6, and 7 entries recorded at 17:47:47, 18:47:47, 19:47:47,
   and 20:47:47 JST respectively, each with repository identity, value-free
   connection state, unexpected findings, Claude evidence when scheduled, and
   next safe action; slice 7 validation/handoff only.
2. This midpoint artifact retained, and its claims independently verified by
   the driver (acceptance item 6, review two of three).
3. One final file-scoped Claude acceptance audit after the material cutoff
   (review three of three), reporting the F2 wording reconciliations.
4. Explicit F1 classification: either a validated, protected-published fix
   with owning tests before 19:47:47 JST, or a blocked receipt under
   `docs/consumer/receipts/` — plus correction of the completion-audit row to
   "no self-healing defect; one non-target tooling defect classified".
5. Final integrated checks on the final tree: `python3
   tools/producer-ledger.py validate`, the consumer diff check against the
   protected base, task-ledger routing, and the `harness validate`
   deterministic tier.
6. Fail-fast authenticated fetch, then protected publication of the final
   ledger through `codex/har379-t293-aist-cowork` only — never the stale
   Har-378 branch — with no force update.
7. Recorded disposition plan and required authority for the stale Har-378
   remote branch and both local preservation branches (F4).
8. The durable final summary and the owner summary, each with exactly seven
   evidence-backed slices and at least 350 words.
9. Closing status: both aliases exclusively managed with ready unattended
   authentication and a healthy watchdog; protected main and the task
   worktree clean at their recorded final revisions; restated confirmation
   that no credential bytes were inspected.

## Checks performed (all read-only, no network, no runtime tools)

- Read completely the eight requested files listed in the scope above.
- Verified the task worktree is clean on frozen-name branch
  `codex/har377-t293-aist-cowork` at `176686f`, with history `708334a` →
  `00b9f42` → `a1e5301` → `3b0519e` → `bc71c4d` (merge of `69ba0a6`) →
  `3a7f9bd` → `176686f`, matching the record.
- Verified protected `main` in the primary checkout is clean at `69ba0a6`,
  matching the record's current protected revision.
- Verified commits `1104e51`, `d35bf9d`, `95df6a4`, `477514e`, `682157e`,
  and `bf5236a` all resolve locally, and preservation branches
  `codex/har377-t293-aist-cowork-pre-reconcile` and
  `codex/har379-t293-aist-pre-producer-reconcile` exist.
- Performed no fetch or push, ran no producer/consumer validators, inspected
  no credentials, panes, transcripts, private logs, or supervisor/SSH state;
  altered no existing file; wrote only this single named artifact.
