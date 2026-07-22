# Personal harness task board

This is the authoritative resume point for the portable Codex and Claude
harness. Keep only active decisions, blockers, exact next actions, and compact
completion pointers here. Full pre-housekeeping chronology is available at
published commit 90451d49ac96; detailed T-288 execution through Home Git
catch-up is preserved at 378df00159d59e8abee645f2bdaebd20cf467cc2. Final
T-288 through T-292 execution is in
`docs/audits/macos-ssh-finalization-2026-07-21.md`.

Next free ID: T-296.

## Current state

- Protected public `main` includes PR #185's functional closeout and PR #186's
  durable audit, the schema-3 per-Mac SSH engine, and failover isolation.
  Superseded T-288/T-291/T-292 branches are absent locally and remotely.
- Managed Linux nodes are local, ab, ab2, ri, al, rc, and t4.
  abci_login and alps_login are transports, not targets; retired si is out of
  scope.
- T-288 through T-292 are functionally complete. Local, all six remote Linux
  nodes, and all four Macs have the canonical terminal SSH include and shared
  fragment. All four private Mac profiles use schema 3 with exactly four
  per-host SSH payloads and no legacy payload. Final execution preserved every
  Mac's distinct non-shared SSH bytes.
- The final Mac acceptance proved clean/current public and private Git, current
  updater/startup/SSH plans, managed non-login/login shells, both doctors, and
  zero formula-policy residue. Home's recurring known Codex-installer tail and
  duplicate link were remediated through the established exact transaction;
  no package or unknown state changed.
- Guarded fleet synchronization advanced all six clean Linux mirrors, and the
  schema-3 updater advanced all four clean Mac public checkouts without a live
  SSH transaction. Private Mac checkouts remained clean/current.
- All four Macs run two independent current-user `launchd` supervisors using
  dedicated restricted identities. The tmux session
  `harness-connection-monitor` probes every pair at 300-second cadence,
  classifies healthy/degraded/unrecoverable state, and uses only a healthy
  sibling to kick one failed service. Simultaneous route loss recovers locally
  through `launchd` without controller or owner intervention for tested
  process/network failures; power, sleep, and external-provider loss remain
  outside that guarantee.
- Exactly one future native weekly primary backup job exists on each managed
  Linux node. First runs passed on 2026-07-19; keep-all remains effective.
- Global safety and collaboration invariants in `.codex/AGENTS.md` remain
  authoritative. Never inspect credentials or use raw recursive/bulk deletion.
- Whenever owner input/approval is requested or a task is completed, report a
  fresh health snapshot for all managed Linux nodes and all four Mac route
  pairs. At the owner's standing request, omit `abci_login` and `alps_login`
  from routine health reports unless a task specifically targets a transport.

## Next resume checkpoint

1. Select another independently eligible T-273 workstream only after fresh
   reconstruction of its gate and authority.
2. On or after 2026-07-26, query only T-196 recorded successor job IDs.

## Active tasks

### T-295 — Fleet convergence, ABQ onboarding, and external-user bootstrap

**Phase/status:** interviewing. The owner requested one upfront PIE plan for
thirteen coupled workstreams, then selected PIE's normal one-question-at-a-time
interview. Read-only discovery and the complete decision register are recorded in
`docs/plans/t295-fleet-convergence.md`. No target mutation has started.

Confirmed planning facts:

- All seven currently managed Linux nodes and all four Mac primaries respond;
  all eight Mac reverse routes are healthy. ABQ is reachable as a RHEL 9.4
  x86-64 interactive node through the existing nested `ab` route and through
  Aist for emergency access; its planned `ab2` secondary route is not yet
  configured. `web` rejected the available noninteractive authentication.
- Every Mac's interactive `login` and `login2` alias requests one fixed remote
  forward in addition to the launchd-owned connection. Dedicated tunnel-only
  aliases are required to eliminate bind conflicts without weakening
  fail-fast supervision.
- Global `ForwardX11 yes` explains irrelevant X11 rejection warnings. AL also
  lacks the `tmux-256color` terminfo entry while its `screen-256color` and
  `xterm-256color` entries are healthy.
- All four Macs run Codex 0.145.0, the current published npm version observed
  on 2026-07-22, with two Codex processes and three live arg0 locks each.
  Their clean `main` checkouts are at `c182bf4`, behind current public main.
- The existing managed Homebrew baseline is satisfied everywhere, and the
  owner has now selected a strict cross-Mac package set from the complete
  union inventory. `.sync_get.sh` is absent on the seven Linux nodes and is a
  regular file on each Mac.
- Linux already provides the selected Python 3.12 interface everywhere; five
  remotes use managed 3.12.12, while local and RI retain host 3.12.3. Macs
  expose Python 3.13 or 3.14 and do not expose `python3.12`.
- The existing local-to-t4 SSH mirror plan fails before contacting t4 because
  it rejects the harness-managed `~/.local` symlink. This is a code defect, not
  evidence of t4 divergence.
- The README defines a Codex-only frozen acceptance evaluator, not a current
  paired Codex/Claude benchmark. A new matched experiment must preserve the
  historical T-181 results rather than overwrite them.
- ABQ's group disk now has a verified 1,024 GiB quota. Its accepted persistent
  and cache roots are `/groups/qgai50157/yokota` and
  `/groups/qgai50157/yokota/cache`; they remain uncreated until the final go.
  Its accepted hidden-home policy moves large `.local` data only, moves no
  latency-sensitive path, deletes no source after backup, and requires no
  owner-only migration step.
- ABQ's accepted backup topology uses
  `/groups/qgai50157/yokota/restic/home-control` as the primary Restic
  repository and local's
  `/mnt/nfs-03/safe/Users/rioyokota/restic-replicas/abq` as its independent
  replica. The owner provisioned the Restic password on ABQ; a value-free
  check verified a current-user-owned regular file with mode `0600`.

**Next action:** receive the complete owner decision bundle, checkpoint the
answers, audit the plan, move to `ready-for-go`, and request the final explicit
execution go required by PIE.

### T-273 — Resolve intentionally deferred maintenance

**Phase/status:** executing. Workstreams 1, 2, 3, and 9 are complete. Each
remaining item keeps its independent gate.

1. **Failed transaction evidence — complete/retain.** Small paired recovery
   preimages lack a cleanup contract.
2. **Linux agent replacement — capability complete.** PR #143 published
   1ed9712bc8c3fd4896df2654b2a3379412e5984b; no live replacement or old-tree
   cleanup is authorized.
3. **Fourth Mac — complete.** T-268/T-269/T-286 acceptance passed.
4. **Backup successors — time-gated.** On or after 2026-07-26, query only the
   seven T-196 IDs; never duplicate a delayed job.
5. **Vendor arg0 directories — complete/live-managed.** T-294 installed the
   version-scoped NFS wrapper and added lock-aware guarded routine housekeeping.
6. **Container capability — requirement-gated.** Install nothing merely for
   warning parity.
7. **One-way local-to-t4 SSH mirror — separate authority.** Execute only after
   explicit authorization for that external mutation.
8. **Package maintenance — freshness/selection-gated.** No blanket upgrade,
   cleanup, autoremove, cask, service, tap, or unmanaged-dependent mutation.
9. **Orphaned .bash_common — complete.** Absent on all four Macs; do not
   recreate it.

Closed non-goals remain plugins/connectors/accounts, administrator settings,
automatic publication, background login mutation, active-session reload, and
guessing lost unknown configuration.

### T-196 — Backup lifecycle phase 2

**Phase/status:** policy-resolved; execution remains gated on eight successful
weekly chains, two verified restores per node, and a current independent
generation. Progress is 1/8 everywhere.

| Node | Recorded 2026-07-26 successor |
| --- | --- |
| local | 91840 |
| ab | 2048464.pbs1 |
| ab2 | 2048468.pbs1 |
| ri | 7242 |
| rc | 212389 |
| t4 | 8194556 |
| al | 4238363 |

On or after eligibility, identity-match and query only these IDs. Record
terminal success, snapshot succession, warning silence, and chain count. Delay
is healthy; do not replace a pending job. Keep-all remains effective. No
forget, prune, recurring check/restore, or replica automation is authorized.
Evidence remains in docs/backup-lifecycle-phase2.md, docs/home-backup.md, and
docs/audits/restic-first-weekly-2026-07-19.md.

## Completed anchors

- T-294 diagnosed the Codex 0.145.0 NFS arg0 lock/delete failure, removed 3,158
  stale directories without stopping Codex, and published shared housekeeping
  in PR #208. PR #209 at `f7cdacd` added guarded lock-aware cleanup and a
  transactional version-scoped launcher, restored ordinary harness push
  authority while retaining the remote-change prohibition, and passed all 61
  focused suites plus protected CI. Live install, exact binary-hash rollback,
  and reapply passed; two short calls and a deliberate nonzero exit were
  warning-free, remote-control help was ready, all three original held-lock
  identities survived, and acceptance ended with three live, one young empty,
  and zero unexpected. After its grace elapsed, guarded-delete manifest
  `/home/rioyokota/.codex/tmp/.harness-delete.pHVd67/manifest` removed that
  final empty directory and was exact-unlinked, leaving only the three live
  entries. Current rollback is
  `harness codex-arg0-wrapper --rollback`; an official Codex upgrade supersedes
  the version-scoped wrapper and requires fresh diagnosis before reinstallation.

- T-293 published and rolled out independent managed Mac reverse-route
  supervision, state-aware monitoring, bounded single/dual-failure recovery,
  exact rollback, and final fleet convergence in PRs #191 through #206, ending
  at `97162ef3c554a80a29c63a4b83d39d292ad4fb14`. Full value-minimized evidence
  is in `docs/audits/t293-connection-self-healing-2026-07-22.md`.
- T-292 isolated `login`/`login2` from multiplexing and enabled forward-bind
  fail-fast behavior in protected PRs #182 through #184, ending at 936a54f.
- T-291 converged the canonical SSH fragment on all eleven managed systems,
  published four distinct per-Mac payloads, finalized private schema 3, and
  preserved all live non-shared SSH bytes. Detailed execution and transaction
  identifiers are in `docs/audits/macos-ssh-finalization-2026-07-21.md`.
- T-290 diagnosed Aist route oscillation followed by the keepalive window. Its
  unpublished raw local checkpoint was compacted value-free and the sole
  preservation ref exact-deleted; no process/network details were published.
- T-288 completed post-onboarding Git, startup, doctor, and exact-residue
  housekeeping on all four Macs. The generic fix shipped in PR #170 and the
  final evidence is in `docs/audits/macos-ssh-finalization-2026-07-21.md`.
- T-289 published sourced harness-evolution artifacts in PR #168 at f2ffdd99685d;
  protected CI and clean phase-one passed.
- T-287 converged the fourth Mac startup files and published PR #166 at
  90451d49ac96.
- T-286 independently onboarded the fourth Mac and superseded T-285.
- T-284 published accelerated/instrumented cowork in PR #163 at 54454b3.
- T-283 published symmetric Codex-Claude cowork in PR #161 at 535a492.
- T-282 compacted the ledger and removed proven-obsolete refs in PR #159.
- T-281 completed three-Mac convergence; T-280 onboarded Home; T-279 repaired
  its prior Bash drift.
- T-274 published unified Bash startup and Mac onboarding; T-268/T-269
  completed the private Mac fleet.
- T-191 accepted first native weekly backup runs on all seven nodes.
- T-181 acceptance finished at 69/70 with zero safety failures.
- T-210 is complete and must not be repeated.

Consult Git history at or before 378df00159d59e8abee645f2bdaebd20cf467cc2
for superseded plans, exact transaction chronology, prior PR/run identifiers,
and detailed T-288 evidence.
