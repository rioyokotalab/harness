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

1. Resume executing T-293 from Codex on `local` at the exact checkpoint below;
   do not initialize or resume cowork.
2. On or after 2026-07-26, query only T-196 recorded successor job IDs.
3. Select another independently eligible T-273 workstream only after fresh
   reconstruction of its gate and authority.

## Active tasks

### T-293 — Make managed fleet connections durably self-healing

**Phase/status:** executing with Codex on `local` as the owner-selected driver;
the owner supplied the required `go` on 2026-07-22. The attempted Aist-hosted run
never entered cowork because Claude Code was absent. The owner reports that all
attempted live state was rolled back. Protected Git contains no Aist-attempt
branch, pull request, or artifact. There is therefore no predecessor cowork
session, no co-pilot evidence to import, and no prior result to trust. Before
any mutation, the local driver must independently revalidate Aist's live,
private, process, and launch state.

**Outcome:** remove owner-dependent reconnection from the managed fleet. First
diagnose and solve Aist's repeated simultaneous `aist`/`aist2` loss. After
the Aist pilot passes, audit and, only where evidence requires it, converge the
Office, riken, and Home reverse-route pairs and the managed Linux routes local,
ab, ab2, ri, al, rc, and t4. “Gone forever” is an engineering objective, not a
claim that a finite soak can prove: acceptance requires persistent supervision,
automatic recovery from tested expected failures, bounded observability, exact
rollback, and no routine owner intervention; record any external-provider,
power, sleep, or network failure outside those guarantees.

**Required workflow:** use Codex only, driven from `local`. Apply
`plan-interview-execute` and `long-running-task-ledger`; do not use
`codex-claude-cowork`, invoke Claude, or substitute a same-product co-pilot.
Keep Git and this ledger authoritative. Separate confirmed facts from
inferences, perform safe read-only discovery before freezing the plan, execute
only after the owner says `go`, checkpoint every material result or failure,
and retain bounded value-free evidence in a tracked audit. ChatGPT Remote
Control is an owner-operated emergency path, not an API available to the local
driver and not an execution dependency.

**Local-driver continuity:** losing both Aist routes must pause only Aist live
mutation, not the task. While Aist is unreachable, continue repository
experiments, supervisor/watchdog fixture development, monitor-state modeling,
Office/riken/Home classification, Linux route auditing, tests, documentation,
and review. Never infer Aist state across a disconnect. Resume Aist from the
last durable checkpoint only after a fresh route, identity, Git, process, and
rollback preflight.

**Ordered plan:**

1. From `local`, reconstruct current Git, monitor history, fresh route state,
   and all existing public contracts without reading private payload values.
   When Aist is reachable, collect bounded value-free facts for process
   ownership, exit status, launch source, duplicate instances, bind conflicts,
   keepalive timing, and local-versus-controller observations.
2. Diagnose why each reverse connection exits, remains falsely alive, or fails
   to recover. Preserve exact timing and status classes while excluding
   endpoints, account values, credentials, keys, raw configuration, and
   unrelated process detail. Distinguish confirmed cause from inference.
3. Build disposable matched fixtures on `local` for current manual operation,
   current-user `launchd` supervision, and supervision plus an active health
   watchdog. Prefer the smallest native design that detects both a dead SSH
   process and an unusable forward; Codex itself must not be the production
   watchdog.
4. Freeze a reversible Aist pilot plan covering installation, unload, exact
   rollback, bounded logs, retry/backoff, duplicate exclusion, stale listeners,
   connection throttling, process ownership, and failure-injection gates.
   Implementation must travel through reviewed repository code and focused
   tests rather than opaque one-off shell state.
5. Revalidate Aist clean public/private Git and the owner's rollback before
   applying anything. Install only the frozen current-user pilot, first prove
   ordinary start/restart and exact rollback/reapply, then test each tunnel
   separately.
6. Do not intentionally drop both Aist routes until single-route recovery has
   passed repeatedly and Aist has a prevalidated local automatic
   recovery/rollback path that does not depend on either reverse route. If that
   gate is not met, keep the dual-failure drill pending rather than gambling
   the only agent-access path. After the gate passes, prove bounded dual-route
   recovery as observed from `local`, with no duplicate process, forward, or
   bind collision and no unrelated state change.
7. Only after Aist passes, classify Office, riken, and Home against the same
   failure model. Roll out only generic evidence-supported behavior,
   sequentially with per-host preflight and rollback, preserving each Mac's
   distinct private SSH bytes. A healthy host remains unchanged when it already
   satisfies the frozen acceptance gates.
8. Audit local and all six remote Linux SSH routes for clean/current Git, fresh
   non-multiplexed reachability, stale-control-socket behavior, bounded
   keepalive failure, and monitor false positives. Do not impose the Mac reverse
   tunnel design on direct Linux routes. Change Linux behavior only for a
   reproduced shared defect and validate it independently.
9. Run five-minute managed-fleet observation for the longest practical window.
   Record exact duration, every transition, and automatic recovery rather than
   extrapolating permanence from silence. Finish with rollback drills, focused
   tests, full phase-one tests, protected CI, guarded fleet synchronization of
   clean checkouts, final Mac updater acceptance where applicable, and fresh
   managed-fleet health.

**Owner-authorized live pilot bundle:** a future explicit local-driver `go`
authorizes creation, loading, testing, and rollback of narrowly scoped
current-user `launchd` state on managed Macs; bounded intentional
termination/restart of only the `login`/`login2` tunnel processes; ordinary
in-scope Git publication; and sequential rollout after the Aist gate. It does
not authorize `sudo`, package installation/removal, credentials or key access,
Remote Control or account changes, system daemons, reboot/sleep, destructive
cleanup, unrelated process interruption, private-value publication, or
mutation of unmanaged systems. A new authority boundary stops only the
affected action while other safe work continues.

**Stop/recovery:** target identity mismatch, dirty/divergent Git, private-state
ambiguity, an unclassified existing launcher, missing rollback, duplicate
process ownership, or loss of the last Aist route before the automatic recovery
gate stops Aist mutation. A route process existing is not proof of a usable
forward. If a drill exceeds its frozen recovery bound, stop further injection,
preserve bounded facts, use only a still-available verified route for
unchanged-only rollback, and continue safe local work. Do not ask the owner to
manually restart routine connections as part of the accepted design.

**Acceptance:** Aist must pass cause-specific tests, repeated single-tunnel
failures, safely gated dual-tunnel failure, bounded recovery observed from
`local`, exact rollback/reapply, no duplicate/bind conflict, and a meaningful
recorded soak. Each other Mac must pass both fresh routes,
supervision/rollback classification, and clean/current public/private state.
Local and six Linux nodes must pass direct-SSH-appropriate fresh route and
clean/current checks. The monitor must distinguish healthy, degraded,
recovering, and unrecoverable states without routine owner help. Focused and
full tests plus protected CI remain authoritative. Preserve a final
value-minimized audit and leave only main branches and no unguarded temporary
trees.

**Decision register:** driver location is resolved as Codex on `local`.
Cowork/Claude is explicitly excluded. The failed Aist attempt supplies no
evidence and creates no predecessor. The owner supplied the frozen plan's
explicit `go` on 2026-07-22. One new execution boundary is unresolved:
unattended SSH authentication must be provisioned by the owner because agents
must not create, inspect, copy, load, or authorize credentials.

**Execution checkpoint:** protected PR #191 published the control plane and
audit at 4777c7fcf2ef299a26aa08d0cf6fa478c2158e38. All six clean Linux
mirrors were guarded-synchronized to that commit. Aist's clean public/private
checkouts advanced through updater transaction `20260721T203627Z-61158`; no
package or live SSH action occurred. The prior implementation working files are
`TODO.md`, `bin/harness`, `libexec/harness-macos-ssh-supervisor`,
`libexec/harness-connection-monitor`, their focused tests, the focused-suite
registry/phase-one runner, `docs/personal-macos.md`, and
`docs/audits/t293-connection-self-healing-2026-07-22.md`.

Read-only reconstruction confirmed Aist has two independent alias-specific SSH
processes under distinct tmux retry loops, no matching launch agent, a valid
engine-3 private profile, and a clean but behind public `main`. The retained
local monitor history contained 182 Aist samples: 64 dual-ready, 22 degraded,
96 dual-down, and 62 state transitions. The other Mac pairs remained stable in
that loop. Both Aist aliases failed authentication from a launchd-like minimal
environment even though the active session path authenticated; the GUI launchd
domain exported no usable agent socket. Thus unattended local authentication
is a confirmed precondition failure. Creating/loading/authorizing a key remains
an ungranted credential boundary, so live Aist supervision mutation is
prohibited. The published read-only plan confirmed both aliases blocked for
`unattended-auth`, with two external predecessor processes, zero staged files,
and zero loaded managed services.

The local implementation now stages two exact current-user launch agents,
revalidates unattended authentication, migrates one alias at a time, refuses
external duplicate ownership, provides launchd-native kick/deactivate/status
and exact inactive rollback, and adds a value-free local monitor that reports
healthy/degraded/unrecoverable states and uses only a healthy sibling for
supervisor recovery. Focused supervisor and monitor fixtures, source-contract,
shell syntax, ShellCheck, and diff checks pass. One initial combined Aist probe
failed on local quoting after the value-free profile check; it mutated nothing
and the literal-stdin retry passed. The first full phase-one run passed 59
focused suites; the existing tmux fixture alone rejected the intentionally
uncommitted checkout. It changed no target state and is safe to retry after the
working set is committed. The clean-commit retry passed the complete phase-one
gate; native MPI remained the declared environment-only skip. A later rerun
raced Git's automatic background packing while an existing fixture copied the
object store; `git fsck` passed, packing became idle, and an unchanged retry
passed the full gate.

Value-free comparison on Office, riken, and Home also found zero of two aliases
capable of launchd-like authentication and no managed supervisor service. Office
and Home each exposed two external predecessor processes; riken exposed one
alias-ending predecessor despite both routes probing healthy, so its distinct
launcher topology requires separate classification after the Aist gate. The
authentication prerequisite is therefore fleet-wide, not Aist-only.

**Next executable action:** checkpoint these published/live results, then wait
for the owner to provision one dedicated unattended identity per Mac for both
of that Mac's `login`/`login2` aliases, or to select another owner-managed
unattended authentication design. Retry Aist's read-only supervisor plan; only
if it reports both aliases ready may staging and one-route-at-a-time pilot
activation begin. Continue the existing observer meanwhile. Do not initialize
or resume cowork.

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
