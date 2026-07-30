# Personal harness task board

This is the authoritative active queue. Read it completely at cold start.
Read linked plans only for the selected task; do not read the historical
snapshot unless an index entry or contradictory evidence makes it relevant.
The exact pre-T-351 board is preserved at
`docs/history/TODO-full-archive-2026-07-30.md` and indexed by
`docs/tasks/index.tsv`.

Next free ID: T-352.

## Resume contract

1. Read root `AGENTS.md` and this board.
2. Confirm branch, worktree, recent commits, and the selected task's mutable
   inputs.
3. Resume only the first unverified action in that task record.
4. Preserve unrelated dirty files and independent Students/Swallow work.
5. Read archived chronology selectively through `docs/tasks/index.tsv`; chat
   history and client memory are never authoritative.

## Current control-plane facts

- Local's live Harness checkout intentionally has one untracked `.nfs` inode
  held by its recovery process. Preserve it; it is not cleanup residue.
- Canonical Local tmux session `projects` has repository-native windows
  `0:harness`, `1:students`, and `2:swallow`. The independent project agents
  own their repositories and ledgers. Ordinary Git or validation work must not
  acquire another project's lifecycle lock or queue pane input.
- Managed Linux targets are local, ab, ab2, ri, al, rc, t4, and abq; abq is
  ready only when both abq and abq2 routes pass. Managed Macs are aist, home,
  office, and riken, each with two route checks.
- The owner-selected required pull-request approval count is zero. It is
  accepted policy, not a hardening finding; no active task authorizes changing
  it.
- Runtime and hosting state are volatile. Revalidate only the inputs used by
  the selected action; a failed query is unknown, never absence.

## Active queue

### T-351 — Reduce Actions, context, contention, and execution latency

**Phase:** executing through 2026-07-31 09:00 JST.

**Objective:** optimize in the frozen order autonomy, efficiency, then
non-obstructive safety. Reduce private hosted Actions, mandatory context,
validation latency, repeated authorization, and cross-project contention
without weakening critical credential, deletion, lifecycle, dirty-worktree,
or untrusted-code boundaries.

**Plan and evidence:**

- `docs/plans/t351-autonomy-efficiency.md`
- `docs/audits/t351-autonomy-efficiency/cowork/`
- `docs/audits/t351-autonomy-efficiency/time-slices.md`

**Verified results:**

- Codex and Claude accepted benchmark `t351-autonomy-efficiency-v1`.
- The clean immutable Harness baseline passed the complete phase-one suite in
  114.77 seconds.
- Private Actions transition is protected and complete: Students PRs #490 and
  #491 end at `dafb4a3`; Swallow PRs #136 and #137 end at `0e9029b`.
  Owner-only jobs now skip without allocating runners, mixed/non-owner events
  retain hosted checks, duplicate `main` push triggers are gone, and weekly
  full plus manual runs remain. Both reviewed trees matched their squash-merge
  trees and neither merge started a push run. No ruleset changed.
- Account plan, billing cycle, budget, payment, and organization Actions
  policy remain unknown because current read-only credentials lack
  `admin:org`. This does not block the repository-only path.

**Working files:** this board and archive/index; root `AGENTS.md`; Harness
validation router/tests; ruleset fixture/docs; T-351 plan/audit; isolated
skill-routing and runtime-isolation worktrees.

**Next action:** integrate and review the two isolated Harness implementation
slices, add the risk-tier validation router and exact-tree receipt, reconcile
the live Harness ruleset fixture from read-only evidence, run matched context,
latency, and three-project isolation benchmarks, then complete protected
publication, cleanup, and the 09:00 handoff.

**Authority boundary:** ordinary repository Git and task pull requests are
authorized. Do not write hosting settings, rulesets, billing, app-server,
tmux, pane, transcript, scheduler, credential, or live project-agent state.

### T-196 — Backup lifecycle phase 2

**Phase:** time-gated; all eight chains are 2/8.

On or after 2026-08-02, query only these recorded successors:

| Target | Exact successor | Earliest local time |
| --- | --- | --- |
| local | `94950` | 00:30 JST |
| ab | `2064918.pbs1` | 01:00 JST |
| ab2 | `2064919.pbs1` | 01:30 JST |
| ri | `10386` | 02:00 JST |
| rc | `260847` | 02:30 JST |
| t4 | `8270230` | 03:00 JST |
| abq | `176525.qjcm` | 03:30 JST |
| al | `4275926` | 01:00 Europe/Zurich |

Delay is healthy. Preserve pending successors and never seed or replace a
healthy chain. RI's old accounting ID `7242` may be retried read-only; an
unavailable query is unknown and must not touch successor `10386`. Acceptance
requires eight successful weekly chains, two verified restores per node, and
a current independent generation. No forget, prune, recurring restore, or
replica automation is authorized. Evidence:
`docs/backup-lifecycle-phase2.md`, `docs/home-backup.md`, and
`docs/audits/restic-first-weekly-2026-07-19.md`.

### T-328 — Complete the deferred Local reboot

**Phase:** time-gated to the Institute of Science Tokyo Ookayama outage.

All other authorized T-311/T-324 actions and accepted-risk reconciliations are
complete. Required approval count zero is the owner's later selected policy
and must remain unchanged.

Primary outage: 2026-08-08 and 2026-08-09, approximately 09:00–18:00 JST.
Contingency dates: 2026-08-29 and 2026-08-30, same hours, only if the Institute
invokes them because inspection cannot proceed.

Before the primary window, confirm the official outage remains active and
prove a physical or firmware power-on path. Shut Local down orderly before
09:00 on August 8 and keep it off through both outage days. Recover only after
confirmed restoration after 18:00 on August 9. Then apply the `reboot-recovery`
skill and validate routes, services, remote control, `projects` tmux,
repositories, supervisors, kernel, and fleet health. Do not infer that the
contingency dates are active.

### T-303 — Observe intermittent NFS I/O latency

**Phase:** blocked on trusted administrator or console access.

Resume only after a responsible administrator or trusted physical/hypervisor
console independently confirms both the intended login account and the
ED25519 fingerprint for `nas-03.yokota`:
`SHA256:nxj4PfZ55OqTcVm5HReHI6IVy9MMcBQ+BbfrJfZRHes`.

Until then, do not retry SSH, accept a key from the network path, guess
credentials, escalate privilege, or change NFS/storage state. Existing
client-side observation evidence is
`docs/audits/t303-nfs-observation-2026-07-24.md`.

## Recent completion pointers

- T-350 completed repository-native Harness, Students, and Swallow session
  mapping; plan: `docs/plans/t350-repository-native-codex-sessions.md`.
- T-349 renamed the canonical Local session to `projects`.
- T-348 completed phone/tmux root mirroring and recovery acceptance.
- T-343/T-342 established durable Claude handoff and benchmark-first Cowork.
- T-333/T-334 made fleet health maintenance-aware.
- T-325 established unsafe-tail recovery; T-337 added bridge-first cutover.
- T-311/T-324 hardening is complete except the T-328 reboot gate.

Use `docs/tasks/index.tsv`, the linked plan/audit, and Git history for details.
