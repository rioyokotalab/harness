# Har-379 seven-hour evidence ledger

Window: 2026-08-02 13:47:47–20:47:47 JST. Exactly seven completed slices are
required. Do not split or invent observations to simulate cadence.

| Slice | Window (JST) | Status |
| --- | --- | --- |
| 1 | 13:47:47–14:47:47 | complete |
| 2 | 14:47:47–15:47:47 | complete |
| 3 | 15:47:47–16:47:47 | complete |
| 4 | 16:47:47–17:47:47 | pending |
| 5 | 17:47:47–18:47:47 | pending |
| 6 | 18:47:47–19:47:47 | pending |
| 7 | 19:47:47–20:47:47 | pending |

## Pre-pilot evidence

- Claude request `aist-20260802-01` produced the retained conditional-go plan
  review. Its findings were independently checked against the historical
  T-293 audit and current supervisor/monitor implementation.
- The pre-pilot protocol now pins a 30-second recovery bound, one-second delay
  between completed repository-native snapshots, per-snapshot sibling checks,
  an ordinary-`login` control path independent of the kicked reverse route,
  exact acknowledgement classes, the slice-3 midpoint boundary, and the
  file-scoped Claude-tooling deviation.
- At 14:01:55–14:02:02 JST the ordinary `login` ControlMaster was a live,
  current-user-owned socket, while the managed primary was a distinct
  launchd-owned process with multiplexing disabled. Local's repository-native
  monitor freshly reported `aist=ready`, `aist2=ready`, `state=healthy`, and
  `action=none`. Aist simultaneously reported both aliases loaded/running with
  `managed=1 external=0`, both unattended-auth checks ready, and the watchdog
  loaded with its latest run classified healthy.
- At 14:03:56 JST the one authorized primary kick returned the exact success
  acknowledgement and was not retried. Its managed generation changed. Two
  Local snapshots observed no sibling failure, and both routes were healthy
  within three seconds, well inside the frozen 30-second bound. Final status
  remained exclusively managed with ready unattended authentication; the
  watchdog's 14:04:00 JST run was healthy. A fresh Local-vantage fleet-health
  check at 14:04:48 JST passed every declared Linux and Mac target.
- A read-only, no-recovery observer was armed at 14:07:03 JST for each exact
  slice boundary. The next evidence mutation is due only after slice 1 closes
  at 14:47:47 JST.
- Protected main advanced to `572a62a` and consumed Har-377. The validation
  ledger was renumbered Har-378 and squash-reconciled onto that protected base
  as clean checkpoint `d35bf9d`; live target state was untouched.

## Slice 1 — 13:47:47–14:47:47 JST

- Repository identity: the 14:47:48 sample found clean, aligned protected
  `main` at `572a62a` and a clean task worktree at `95df6a4`.
- Connection state: both Aist aliases were loaded/running with
  `managed=1 external=0`, unattended auth was ready, and the watchdog's latest
  run was healthy. At 14:47:55, fresh Local-vantage probes reported `aist` and
  `aist2` ready with `state=healthy action=none`; every other declared pair was
  healthy in the same repository-native snapshot.
- Unexpected findings and Claude evidence: protected main independently used
  Har-377 during this slice; the collision was reconciled as Har-378 without
  target mutation or overwritten history. Claude's conditional-go plan review
  remains the only scheduled review so far, and its gates were resolved before
  the successful pilot.
- Next safe action: remain observation-only through slice 2. Do not repeat the
  pilot or send an unscheduled Claude request.

## Slice 2 — 14:47:47–15:47:47 JST

- Repository identity: the 15:47:48 sample found clean, aligned protected
  `main` at `572a62a` and the clean task checkpoint at `682157e`.
- Connection state: both Aist aliases remained loaded/running with exclusive
  `managed=1 external=0` ownership and ready unattended authentication. The
  watchdog's 15:47:34 run classified the pair healthy with no recovery
  attempt. Fresh Local-vantage probes at 15:47:55 reported both Aist routes
  and every other declared pair healthy.
- Unexpected findings and Claude evidence: none. The pre-pilot Claude review
  remains resolved evidence; the scheduled midpoint review is not due until
  slice 3 closes.
- Next safe action: remain observation-only through slice 3, then send exactly
  one bounded midpoint-review request after 16:47:47 JST. Do not repeat the
  pilot.

## Slice 3 — 15:47:47–16:47:47 JST

- Repository identity: the exact 16:47:47 sample found clean, aligned
  protected `main` at `69ba0a6` and the clean task checkpoint at `3a7f9bd`.
- Connection state: both Aist aliases remained loaded/running with
  `managed=1 external=0` and ready unattended auth. The watchdog's 16:47:30
  run classified the pair healthy with no recovery attempt. Fresh
  Local-vantage probes at 16:47:54 reported both Aist routes and every other
  declared pair healthy.
- Unexpected findings and Claude evidence: protected main introduced the
  producer protocol and independently consumed Har-378. One checkpoint push
  continued after a missing fail-fast guard detected that advance, but changed
  only the stale task branch. The Local producer assigned Har-379, the Aist
  consumer reconciled only its permitted paths, and the correct remote branch
  now contains current protected transport fixes. No PR, merge, rollout, or
  target mutation resulted. Claude's plan review remains resolved evidence;
  the midpoint review is now due.
- Next safe action: submit exactly one file-scoped Claude midpoint request,
  never retry an acknowledged or ambiguous submission, and then remain
  observation-only through slice 4.

## Midpoint review request

Request `aist-20260802-midpoint-01` was submitted once at 16:49 JST through
the installed content-blind Claude transport. Local `status=submitted` proves
submission only; the private input was exact-unlinked, no retry is permitted,
and the named artifact remained pending after the first bounded poll.

## Final durable summary

Pending completion. It must contain exactly one evidence-backed entry for each
hour above, the validated outcome, residual risks, and the exact next action,
and must total at least 350 words.
