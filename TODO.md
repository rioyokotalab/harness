# Personal harness task board

This is the authoritative resume point for the portable Codex and Claude
harness. Keep only active decisions, blockers, exact next actions, and compact
completion pointers here. Full pre-housekeeping chronology is available at
published commit 90451d49ac96; detailed T-288 execution through Home Git
catch-up is preserved at 378df00159d59e8abee645f2bdaebd20cf467cc2. Final
T-288 through T-292 execution is in
`docs/audits/macos-ssh-finalization-2026-07-21.md`.

Next free ID: T-294.

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
- The tmux session `harness-connection-monitor` probes Aist/Aist2,
  Office/Office2, riken/riken2, and Home/Home2 every 300 seconds. It reconnects
  a dropped primary through its secondary with `ssh login`, or a dropped
  secondary through its primary with `ssh login2`. It cannot recover a pair
  while both routes are down.
- Exactly one future native weekly primary backup job exists on each managed
  Linux node. First runs passed on 2026-07-19; keep-all remains effective.
- Global safety and collaboration invariants in `.codex/AGENTS.md` remain
  authoritative. Never inspect credentials or use raw recursive/bulk deletion.
- Whenever owner input/approval is requested or a task is completed, report a
  fresh health snapshot for all managed Linux nodes and all four Mac route
  pairs. At the owner's standing request, omit `abci_login` and `alps_login`
  from routine health reports unless a task specifically targets a transport.

## Next resume checkpoint

1. Start T-293 from the ChatGPT-paired Codex driver on Aist and execute its
   owner-authorized seven-hour cowork scope.
2. On or after 2026-07-26, query only T-196 recorded successor job IDs.
3. Select another independently eligible T-273 workstream only after fresh
   reconstruction of its gate and authority.

## Active tasks

### T-293 — Make managed fleet connections durably self-healing

**Phase/status:** planning; owner-selected Aist Codex driver has not yet
initialized the cowork session. The owner explicitly requested a seven-hour
unattended `codex-claude-cowork` run and selected Aist as the driver location
because ChatGPT Remote Control has remained available there when both reverse
SSH routes disappeared. Claude Code on Aist is the required co-pilot. The
owner will be unavailable during the run, so durable files and conservative
stop conditions must replace chat-dependent recovery.

**Outcome:** remove owner-dependent reconnection from the managed fleet. First
diagnose and solve Aist's repeated simultaneous `aist`/`aist2` loss. After the
Aist pilot passes, audit and, only where evidence requires it, converge the
Office, riken, and Home reverse-route pairs and the managed Linux routes local,
ab, ab2, ri, al, rc, and t4. “Gone forever” is an engineering objective, not a
claim that a finite soak can prove: acceptance requires persistent supervision,
automatic recovery from tested expected failures, bounded observability, exact
rollback, and no routine owner intervention; record any external-provider,
power, sleep, or network failure that remains outside those guarantees.

**Required workflow:** the Aist Codex driver must read repository instructions,
this ledger, `codex-claude-cowork`, `plan-interview-execute`,
`long-running-task-ledger`, and the complete cowork protocol. Use the default
staged/sealed cowork exchange, one immutable baseline, independent Codex and
Claude sandbox experiments, blinded evidence, reciprocal critique,
reconciliation, a frozen plan, driver-only target mutation, and final
co-pilot challenge. Checkpoint all facts, failures, retry safety, commands,
working files, and next actions. Use native clients; do not substitute a
same-product subagent. ChatGPT Remote Control is Aist's out-of-band control
path, not a third cowork agent.

**Ordered scope:**

1. Revalidate clean public/private Git, Aist identity, Codex/Claude versions,
   Remote Control continuity, current SSH/monitor state, and the exact source
   of the tunnel processes without printing endpoints or private values.
2. Diagnose why each process exits, remains falsely alive, or fails to recover.
   Preserve bounded value-free timing, exit-status, launch ownership, duplicate,
   bind-conflict, keepalive, and local-versus-observer evidence. Distinguish
   confirmed cause from inference.
3. In matched sandboxes compare current manual operation, user-level `launchd`
   supervision, and supervision plus an active health watchdog. Prefer the
   smallest native design that detects both dead processes and unusable
   forwards; do not keep Codex itself running as the production watchdog.
4. Freeze the evidence-selected Aist plan with installation, unload, rollback,
   log bounds, retry/backoff, duplicate exclusion, and failure-injection gates.
   The original seven-hour request is the go for that frozen scope only.
5. Execute the reversible Aist pilot, then repeatedly terminate each tunnel
   separately and both together. Prove bounded automatic recovery, both routes
   observable from local, no duplicate process or forward, no bind collision,
   and unchanged unrelated SSH, Codex, shell, Git, and session state.
6. Only after Aist passes, classify Office, riken, and Home against the same
   failure model. Roll out only the generic evidence-supported mechanism,
   sequentially and with per-host preflight/rollback; preserve distinct private
   SSH bytes. A healthy host may remain unchanged when its design already meets
   the frozen acceptance gates.
7. Audit local and all six remote Linux SSH routes for clean/current Git,
   fresh non-multiplexed reachability, stale-control-socket behavior, bounded
   keepalive failure, and monitor false positives. Do not force a Mac reverse
   tunnel design onto direct Linux routes. Change Linux behavior only for a
   reproduced shared defect and validate it independently.
8. Use the remaining unattended window for five-minute observation of all
   managed targets. Record exact soak duration, every transition and automatic
   recovery, rather than extrapolating permanence from silence. Finish with
   rollback drills, focused tests, full phase-one tests, protected CI, guarded
   fleet synchronization of clean checkouts, and fresh managed-fleet health.

**Owner-authorized live pilot bundle:** when the owner starts the Aist driver
with an explicit instruction to execute T-293, that instruction authorizes
creation, loading, testing, and rollback of narrowly scoped current-user
`launchd` state on the managed Macs; bounded intentional termination/restart of
only the `login`/`login2` tunnel processes; ordinary in-scope Git publication;
and sequential rollout after the Aist gate. It does not authorize `sudo`,
package installation/removal, credentials or key access, Remote Control or
account changes, system daemons, reboot/sleep, destructive cleanup, unrelated
process interruption, private-value publication, or mutation of unmanaged
systems. A new authority boundary stops only the affected action; continue
other safe evidence and validation work.

**Stop/recovery:** never depend on either reverse route as the sole rollback
channel before the Aist supervisor and local rollback path are proven. If a
failure drill does not recover within its frozen bound, preserve the exact
local state through Remote Control, roll back unchanged-only where safe, and
remain on Aist rather than transferring driver authority. Never claim a route
healthy from process existence alone. Loss of GitHub, Claude, or Remote Control
stops target mutation but leaves the durable session resumable.

**Acceptance:** Aist must pass the full cowork validator, cause-specific tests,
single- and dual-tunnel forced failures, bounded recovery, local observation,
rollback/reapply, and a meaningful recorded soak. Each other Mac must pass both
fresh routes, supervision/rollback classification, and clean current
public/private state. Local and six Linux nodes must pass fresh route and
clean/current checks appropriate to direct SSH. The monitor must distinguish
healthy, degraded, recovering, and unrecoverable states without requiring the
owner. Full tests and protected CI remain authoritative. Preserve the final
value-minimized evidence in a tracked audit and leave only main branches and no
unguarded temporary trees.

**Next executable action:** from the ChatGPT Remote session on Aist, fetch
protected public `main`, verify clean/equal public and private checkouts, create
the T-293 staged cowork session with Codex as driver and Claude as co-pilot,
and begin independent read-only diagnosis. Do not create a competing T-293
session on local.

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
5. **Vendor arg0 directories — process-gated.** Re-inventory local only after
   every Codex process exits; use guarded-delete if eligible.
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
