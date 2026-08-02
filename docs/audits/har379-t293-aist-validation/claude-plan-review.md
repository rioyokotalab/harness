# Claude plan review — Har-377 T-293 Aist validation

> Post-review ledger note: protected main independently consumed Har-377, so
> the active validation was renumbered Har-378 without changing this review's
> request, findings, or historical paths. Protected producer packet Har-379
> later assigned the still-running validation its final durable identity.

- Request ID: `aist-20260802-01`
- Reviewer: Claude Code (read-only co-pilot), 2026-08-02, pre-pilot
- Scope reviewed: cowork `AGENTS.md`, `docs/tasks/Har-377.md`,
  `docs/plans/har377-t293-aist-validation.md` (each read completely), plus
  read-only repository verification listed at the end.

## Verdict

The frozen plan is structurally sound, conservative, and consistent with the
historical T-293 contract. Sequencing (critique → baseline probes → single
bounded kick → observe → midpoint review → cutoff → final audit) is correct,
stop conditions are explicit, and the no-dual-loss / no-sibling-touch
boundaries are properly frozen. However, the acceptance logic contains one
criterion that is currently unverifiable as written (the unpinned recovery
bound) and one criterion that will fail a literal final audit (the "no tools"
wording). Neither requires redesign; both require recording before the pilot.

## Findings (severity-ranked)

### F1 — HIGH: the pilot's recovery bound is referenced but never pinned

Acceptance item 4 requires the kicked route to recover "within the recorded
bound", and plan step 4 samples "until recovery or the bounded stop
condition" — but neither the plan nor the task record states the numeric
bound or the sampling cadence. The historical contract
(`docs/audits/t293-connection-self-healing-2026-07-22.md`) records
single-route kick recoveries of 4/15/4 s and 4/14/14 s per alias, later kick
generations recovering in 1–2 s, and one hung-restart incident exceeding
30 s. Without a pinned number, "bounded" is unfalsifiable: sampling has no
defined stop time, and a slow recovery could be passed post hoc. Before the
kick, record in the task record an explicit numeric bound (derived from the
historical contract, e.g. a value comfortably above the observed 15 s worst
case with the >30 s incident as the failure threshold) and the probe cadence.

### F2 — HIGH: probe/control-channel independence from the kicked route is not required

Step 3 obtains Local-vantage probes from Aist "through the approved ordinary
`login` route"; step 4 then kicks the primary Aist supervisor while sampling
both routes. If the channel carrying the sampling (the Aist→Local leg, or
Local's return probes) depends on — or multiplexes over — the route being
kicked, the kick can sever the observation channel mid-pilot. That produces
exactly the "ambiguous acknowledgement" state whose only permitted response
is a full stop, i.e. the pilot design can manufacture its own no-retry abort.
The historical contract shows the tooling supports non-multiplexed probes and
sibling-mediated observation, but the plan does not require them. Before the
kick, record which alias/route carries the control channel during the pilot
and confirm the probe path is independent of the kicked route (sibling-carried
or non-multiplexed). If independence cannot be shown, the pilot is no-go.

### F3 — MEDIUM: "no tools" acceptance wording contradicts the actual review protocol

Acceptance item 6 and plan step 2 state Claude receives "no tools", yet
request `aist-20260802-01` directed Claude to read workspace files and write
this artifact with file tools. The security intent is honored — no
credentials, panes, transcripts, private logs, or target mutation, and only
this single artifact was written — but a literal final acceptance audit
against the frozen wording will record a deviation. Record this deviation and
its rationale (file-scoped read/write, zero target authority) in the evidence
now, so the final audit reconciles it deliberately rather than discovering it.

### F4 — MEDIUM: sibling readiness during the pilot should be an explicit per-sample check

Acceptance item 3 requires the sibling ready "throughout", and dual loss is a
stop condition, but step 4 only says to sample "both Local-vantage routes".
Make explicit that every sampling iteration includes the sibling probe and
that a sibling failure observed at any sample triggers an immediate stop of
mutation (no kick retry, no sibling-mediated recovery attempt), preserving
services and continuing read-only evidence only.

### F5 — MEDIUM: acknowledgement-classification procedure and recovery interface are unnamed

Rollback requires "classifying the failed acknowledgement" and using "the
repository-native supervisor's recorded recovery interface", and stop
conditions forbid retrying ambiguity — but the plan names neither the exact
kick command, its acknowledged-vs-ambiguous criteria, nor the recovery
interface. The historical contract references a transaction-aware harness
kick command wrapping `launchctl kickstart -k`. Before the pilot, record the
exact command to be issued and what output constitutes (a) acknowledged
success, (b) acknowledged failure, (c) ambiguous — since (c) permanently
forecloses retry.

### F6 — LOW: midpoint and slice-boundary ambiguity

The window midpoint (17:17:47 JST) falls inside slice 4, but slices are the
evidence unit. Define the midpoint review as occurring at the slice 3/4
boundary (16:47:47 JST close) or explicitly inside slice 4, so acceptance
item 6's "reviews midpoint evidence" maps to a recorded slice. Also note the
seventh slice (19:47:47–20:47:47) lies entirely after the material cutoff, so
its content can only be integrated validation and handoff — consistent, but
worth stating so "next safe action" for slice 7 is the handoff itself.

### F7 — LOW: word-count acceptance criterion is a weak proxy

The ≥350-word requirement for final summaries measures length, not evidence.
No change needed; just ensure each slice cites verifiable identifiers
(commits, probe timestamps, generations) so length never substitutes for
evidence.

## Pilot recommendation

**Conditional GO.** The bounded single-route pilot is justified and low-risk
relative to the historical contract, provided all of the following are
recorded before the kick:

1. A pinned numeric recovery bound and sampling cadence (resolves F1).
2. Recorded confirmation that the probe/control channel during the kick is
   independent of the kicked route (resolves F2).
3. Fresh, timestamped pre-pilot Local-vantage probes of both routes, plus
   exclusive-ownership and unattended-auth checks, all exact.

If any of the three cannot be satisfied exactly, the pilot is **NO-GO** under
the plan's own stop conditions, and the window should continue as read-only
observation and evidence collection.

## Checks performed (all read-only)

- Read completely: cowork `AGENTS.md`, `docs/tasks/Har-377.md`,
  `docs/plans/har377-t293-aist-validation.md`, and the Harness
  `docs/agent-policy/managed-codex.md` gate for identified agent messages.
- Verified protected `main` HEAD in the primary Harness checkout equals the
  frozen baseline `bbc2a4b92e580bb20ee44facda5816c3fdc1a7e8` with a clean
  worktree.
- Verified `97162ef3c554a80a29c63a4b83d39d292ad4fb14` is an ancestor of the
  frozen baseline (`git merge-base --is-ancestor` passed).
- Verified the authoritative historical contract
  `docs/audits/t293-connection-self-healing-2026-07-22.md` exists (30,517
  bytes) and searched it (grep, no full private-content review) for recovery
  bounds, kick semantics, and probe design cited in F1/F2/F5.
- Verified the cowork worktree is on branch `codex/har377-t293-aist-cowork`,
  clean, exactly one commit (`1104e51` "Open Aist T-293 validation window")
  atop the frozen baseline.
- Did not inspect credentials, panes, transcripts, private logs, supervisor
  or SSH state; did not mutate any service, ref, or file other than writing
  this single artifact.
