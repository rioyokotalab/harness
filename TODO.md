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

**Next executable action:** publish and synchronize the dedicated-identity
supervisor revision. Then the local driver may place the reviewed, plan-first
Aist-local `~/run_this.sh`, but must not run it or inspect its generated key.
The owner runs its plan and explicit apply to provision one dedicated identity
for both of Aist's `login`/`login2` aliases. Retry Aist's read-only supervisor
plan; only if it reports both aliases ready may staging and one-route-at-a-time
pilot activation begin. Continue the existing observer meanwhile. Do not
initialize or resume cowork.

**Owner helper checkpoint:** protected PR #193 merged the dedicated-identity
gate at `f66e26eb1a5f56bc29173805acdf45d067284875`; local full phase one and
protected `portable-phase1` passed. Aist advanced cleanly through updater
transaction `20260721T205722Z-66505`. The reviewed mode-0700 helper is now at
Aist `~/run_this.sh` with SHA-256
`8c48372f1e428057dc7507779702435d51bfd3d1c2c0cb9a9cb3c651253fda7c`;
its authorization combines `restrict,port-forwarding` with forced
`/usr/bin/true`, preventing general command use while retaining the required
forward and probe. The driver did not execute it and removed its local transfer
source. The owner
next runs `~/run_this.sh --plan`, then `~/run_this.sh --apply` and types the
script's exact confirmation. After the owner reports completion, the local
driver must freshly revalidate both routes and the value-free supervisor plan
before staging or stopping either predecessor tunnel.

A final fleet probe at 06:08 JST found only Home's primary route down while
`home2` remained ready. Value-free inspection showed its existing tmux `%0`
`ssh login` process had restarted but remained stuck for more than 30 seconds.
Under the standing single-route reconnect authority, the driver used native
`tmux respawn-pane -k -t %0 'ssh login'`; `home` recovered on the second
three-second probe and `home2` was never interrupted. This is additional live
evidence for replacing the unbounded manual launcher, not an Aist helper state
change.

The owner's first Aist helper plan passed. During `--apply`, key creation and
both authorization steps completed, but the final supervisor plan refused
`login` because its effective configuration had zero remote forwards; the
helper then reported `ROLLBACK status=complete`. Value-free verification
confirmed both local identity paths were absent. The owner explained that they
had temporarily disabled forwarding for the first check. A value-free diff
proved the only live/canonical differences were commented `LocalForward` and
`RemoteForward` directives for `login`; canonical `login` and `login2` each
resolved to exactly one remote forward. The driver deliberately rejected
`macos-ssh-sync`'s initial `action=publish`, restored the exact canonical
per-host file through private transaction `20260721T212129Z-73841`, and
retained unchanged-only rollback evidence. Both aliases now resolve to one
remote forward and pass current authentication with forwarding cleared;
`macos-ssh-sync` reports `agreement=yes action=none`. Credential state remains
absent, so the owner may safely rerun the helper plan and apply.

The owner's second `~/run_this.sh --apply` completed successfully after the
canonical SSH-config restore. It created the dedicated identity, authorized it
on both routes, passed isolated agentless authentication, and ended with the
supervisor plan reporting both aliases `stage=create`,
`unattended_auth=ready`, `external=1`, and `blocked=0`. Independent metadata
revalidation confirmed a regular, non-symlink, single-link, current-user-owned
mode-0600 identity without reading its contents. Both existing tmux predecessors
remain present; managed status is `loaded=no running=no managed=0 external=1`
for each alias. No supervisor plist or transaction has been staged yet. The
next action is to advance Aist's clean public checkout to protected `main`,
repeat the plan, and run stage-only supervisor apply; do not stop either
predecessor until that transaction is verified and the sibling route is fresh.

Protected PR #198 merged the credential checkpoint at
`925761ff743cd6c1c188f6716b039ea10058c293`; Aist advanced cleanly through
updater transaction `20260721T213111Z-78719`. An initial combined plan/apply
invocation returned no output, so the driver treated state as unknown; fresh
inspection proved both routes healthy with no transaction, plist, or loaded
service. Standalone stage transaction `20260721T213202Z-82311` then created two
plists and zero services, passed exact inactive rollback, and left both tmux
predecessors healthy. Reapply transaction `20260721T213306Z-85543` is current.

The driver migrated `login` through healthy `aist2`, replacing only tmux pane
`%5`; activation yielded `managed=1 external=0` while `login2` remained its
external predecessor. Three native kick restarts recovered in 4, 15, and 4
seconds. One unexpected `launchctl kill SIGTERM` recovered automatically in 5
seconds. The driver then migrated `login2` through managed `aist`, replacing
only tmux pane `%6`; both aliases reached `loaded=yes running=yes managed=1
external=0`. Three `login2` kick restarts recovered in 4, 14, and 14 seconds,
and an unexpected `SIGTERM` recovered in 2 seconds. Each drill retained a fresh
sibling route and exact single-process ownership. The Aist pilot now satisfies
the frozen gate for a bounded dual-route failure/recovery drill observed from
`local`; do not roll out to another Mac before that drill and its post-state
checks are durably recorded.

Protected PR #199 merged the single-route pilot checkpoint at
`5b858a8bc6161c4053f7480eeab57457bb33f5f9`; Aist advanced through updater
transaction `20260721T214154Z-97235`. The bounded dual-route drill dispatched
two delayed, self-terminating native `launchctl kill SIGTERM` actions locally
on Aist. The `local` observer saw both routes ready at 1 second, both down at 3
seconds, and both ready at 4 seconds. Post-recovery checks proved both process
generations changed and each alias returned to `loaded=yes running=yes
managed=1 external=0`; the complete drill validation took 6 seconds. No manual
or sibling-mediated recovery was used. The next gate is the sequential active
rollback/reapply drill using the preserved `%5`/`%6` tmux panes, followed by a
meaningful soak. Other Macs remain rollout-prohibited until Aist's exact active
rollback/reapply is verified.

The active rollback/reapply gate passed. Managed `login` deactivated cleanly,
but the historical tmux server had already exited, so preserved pane `%5` was
unavailable. A newly named temporary `ssh login` predecessor remained unusable
after its creating control session ended, further confirming session-bound
authentication; replacing only that session with the dedicated, agent-disabled
SSH invocation restored `aist`. `login2` then deactivated and was restored by
the symmetric dedicated temporary predecessor. Transaction
`20260721T213306Z-85543` rolled back exactly with both external routes healthy.
Aist advanced through updater transaction `20260721T214844Z-4393`, new
supervisor transaction `20260721T214904Z-6974` staged, and both temporary
sessions were removed one at a time before successful reactivation. Final
status is `loaded=yes running=yes managed=1 external=0` for both aliases; one
post-reapply kick per alias also passed. Aist has now passed staged and active
rollback/reapply, repeated single-route restarts, unexpected exits, and observed
dual-route loss/recovery. Begin the meaningful Aist soak. The next fleet gate
is owner provisioning of one dedicated identity on each of Office, riken, and
Home before per-host classification and sequential rollout.

Office, riken, and Home each passed clean public/private Git, canonical
`macos-ssh-sync agreement=yes action=none`, absent identity/helper paths, and
exactly one remote forward per alias. They advanced to protected
`88e6c4419efabfec0dbc1f7ef1fd7d10579f64d0` through updater transactions
`20260721T215509Z-6673`, `20260721T215523Z-37906`, and
`20260721T215527Z-94774`, respectively; packages and tunnel processes were
unchanged. The driver hardened the owner helper to check the one-forward
contract before key creation, validated three host-pinned variants with Bash
syntax and ShellCheck, atomically placed them mode 0700 at each Mac's
`~/run_this.sh`, did not execute them, and exact-unlinked all local transfer
sources. SHA-256 values are Office
`b5b8589c57525f3d043e35d921bfa43cba94071936c7a12e90c1131f2a89e197`, riken
`ac1298ca42e6213f0d0929826a630d25a3fc398629eceec9b12b1cc5bc2f7789`, and Home
`d0d10b6e43fb2d9a3cf7688e1bdacae3300ac773d2a4d22d885cd5b6390ffb6b`.
The owner next runs `~/run_this.sh --plan` and `~/run_this.sh --apply` locally
on each Mac, typing `provision-office`, `provision-riken`, or `provision-home`.
No other Mac supervisor may be staged until its helper completes and the local
driver independently revalidates that host.

Office rollout is complete. The owner provisioned the reviewed dedicated
identity; metadata-only validation and isolated unattended authentication
passed. Office advanced cleanly to protected
`ef97b55cf8170508c40eae2c52c339296eba0e12` through updater transaction
`20260721T221819Z-14095`. Inactive staging/rollback, sequential migration,
three kicks and one unexpected exit per alias, listener-observed dual-route
loss/recovery, exact active rollback/reapply, and final post-reapply kicks all
passed. Transaction `20260721T223035Z-31774` is current; both aliases report
`loaded=yes running=yes managed=1 external=0`; both routes and clean/current
public/private Git passed; no temporary session remains; and the spent helper
was hash-revalidated and exact-unlinked. Full evidence, including one rejected
slow-observer drill and its unchanged high-frequency retry, is in
`docs/audits/t293-connection-self-healing-2026-07-22.md`.

**Next executable action:** the owner runs riken's reviewed
`~/run_this.sh --plan`, then `~/run_this.sh --apply` and types
`provision-riken`. The local driver must independently revalidate riken before
staging or interrupting either tunnel. Home remains unchanged and independently
owner-gated after riken.

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
