# Personal harness task board

This is the authoritative resume point for the portable Codex and Claude
harness. Keep only active decisions, blockers, exact next actions, and compact
completion pointers here. Full pre-housekeeping chronology is available at
published commit 90451d49ac96; detailed T-288 execution through Home Git
catch-up is preserved at 378df00159d59e8abee645f2bdaebd20cf467cc2. Final
T-288 through T-292 execution is in
`docs/audits/macos-ssh-finalization-2026-07-21.md`. Full T-295 execution before
compaction is preserved at `5d551883648760fcc373973a575a403b18637f44`.

Next free ID: T-297.

## Current state

- Protected public `main` includes PR #185's functional closeout and PR #186's
  durable audit, the schema-3 per-Mac SSH engine, and failover isolation.
  Superseded T-288/T-291/T-292 branches are absent locally and remotely.
- Managed Linux nodes are local, ab, ab2, ri, al, rc, t4, and abq; abq2 is the
  second route to the same ABQ node.
  abci_login and alps_login are transports, not targets; retired si is out of
  scope.
- T-288 through T-292 are functionally complete. Local, all six remote Linux
  nodes, and all four Macs have the canonical terminal SSH include and shared
  fragment. All four private Mac profiles use schema 3 with exactly four
  per-host SSH payloads and no legacy payload. Final execution preserved every
  Mac's distinct non-shared SSH bytes.
- T-295 is complete. Its thirteen frozen workstreams converged the SSH, X11,
  terminal, Codex, arg0, package, Python, ABQ, benchmark, fleet-inventory, and
  external-user onboarding contracts. Final owner-side reauthorization and
  independent validation restored all eight launchd-managed Mac routes.
- The final Mac acceptance proved clean/current public and private Git, current
  updater/startup/SSH plans, managed non-login/login shells, both doctors, and
  zero formula-policy residue. Home's recurring known Codex-installer tail and
  duplicate link were remediated through the established exact transaction;
  no package or unknown state changed.
- Post-housekeeping synchronization left local, all seven remote Linux
  checkouts, and all four Macs clean/current at `b0f4548`; private Mac
  checkouts remained clean/current.
- Routine post-T-295 housekeeping guarded-deleted six released local arg0
  entries and one on each Mac without stopping Codex. Every post-plan reports
  `live=3 eligible=0 young=0 unexpected=0`; exact manifests, targets, and
  residue checks are recorded in
  `docs/audits/post-t295-housekeeping-2026-07-23.md`.
- All four Macs run two independent current-user `launchd` supervisors using
  dedicated restricted identities. The tmux session
  `harness-connection-monitor` probes every pair at 300-second cadence,
  classifies healthy/degraded/unrecoverable state, and uses only a healthy
  sibling to kick one failed service. Simultaneous route loss recovers locally
  through `launchd` without controller or owner intervention for tested
  process/network failures; power, sleep, and external-provider loss remain
  outside that guarantee.
- Aist alone has since shown repeated simultaneous `0/2` intervals after fresh
  dedicated-authentication and supervisor acceptance. One bounded observation
  recovered both routes locally after roughly twelve minutes; another during
  post-T-295 synchronization recovered both after roughly four and a half
  minutes while the other Mac pairs remained healthy. T-296 owns diagnosis of
  that variable recovery latency.
- Exactly one future native weekly primary backup job exists on each managed
  Linux node. First runs passed on 2026-07-19; keep-all remains effective.
- Global safety and collaboration invariants in `.codex/AGENTS.md` remain
  authoritative. Never inspect credentials or use raw recursive/bulk deletion.
- Whenever owner input/approval is requested or a task is completed, report a
  fresh health snapshot for all managed Linux nodes and all four Mac route
  pairs. At the owner's standing request, omit `abci_login` and `alps_login`
  from routine health reports unless a task specifically targets a transport.

## Next resume checkpoint

1. Execute the frozen T-296 Mac-local watchdog plan, beginning with synthetic
   tests and an Aist-only reversible pilot. The 30-second observe-only night
   watch is active alongside the existing five-minute recovery monitor.
2. On or after 2026-07-26, query only T-196 recorded successor job IDs.

## Active tasks

### T-296 — Diagnose recurrent Aist dual-route recovery latency

**Phase/status:** executing the one-time Local authorization hardening after
the five-hour nightly implementation and observation window. The owner
confirmed that `local` is the fleet's only JumpCloud-managed node and that
neither its live `~/.ssh/authorized_keys` nor the empty
`~/.ssh/authorized_keys.jcorig` contains any of the four restricted tunnel
entries. `jcagent.service` and `ssh.service` are active. This makes JumpCloud
reconciliation of the account-level authorization file the probable source of
the drift; `.jcorig` is not being used as the durable tunnel boundary.
The durable plan is
`docs/plans/t296-mac-connectivity-resilience.md`; the evidence handoff is
`docs/audits/t296-mac-connectivity-resilience-2026-07-23.md`. The temporary
observe-only monitor and its mode-0600 log were removed after the endpoint; the
existing five-minute recovering monitor remains active and unchanged.
T-295 proved Aist's existing dedicated identity, both tunnel aliases, exclusive
launchd ownership, current clean checkout, and zero-warning doctor immediately
before repeated later `0/2` intervals. Home, Office, and Riken remained healthy,
so the new evidence is Aist-specific and does not reopen T-295.

**Observed evidence:** Aist first returned from a simultaneous outage after a
roughly twelve-minute controller-side observation, with both routes and both
managed services healthy. It later dropped both routes again while Local was
attempting the documentation-only `b0f4548` Mac update, then returned both
unattended after roughly four and a half minutes. The pending update transaction
`20260722T151504Z-26956` then completed; its follow-up plan was current, both
services reported `loaded=yes running=yes managed=1 external=0`, and the doctor
had zero failures and warnings. Local cannot inspect or kick either service
while both reverse routes are absent. No credential, SSH configuration, or
service mutation was performed during either outage.

The owner's Aist-side report then isolated the repeatable failure: dedicated
authentication remains ready, but both real reverse-forward binds fail while
stale fixed TCP listeners remain on Local. Immediate launchd retries exit 255
and keep repeating. Unloading the two exact services, waiting for the Local
listeners to drain, probing real binds, and bootstrapping sequentially restored
both routes. A fresh live recurrence at 00:35 JST again left Aist at `0/2`
while the other three Mac pairs stayed `2/2` and both Aist listener ports
remained occupied on Local. Listener ownership cannot be tied safely to an
exact process from the unprivileged Local account, so a controller-side kill
is rejected.

The 30-second watch measured that recurrence returning at 00:47 JST, roughly
twelve minutes after first detection. Because the owner-launched Codex process
on Aist remained active and did not acknowledge an observe-only request, this
sample and later live recoveries prove convergence but cannot be attributed
solely to the watchdog. No Codex process was killed. A value-free two-hour power
comparison found no Aist or Home sleep/wake event around the sample. Both Aist
services were again `managed=1 external=0`; Home's launchd history showed that
the same exit-255 retry mechanism has occurred there even though its pair stayed
reachable. The frozen implementation now has synthetic coverage for healthy
no-op, dual drain/restore, live and stale recovery locks, authentication
refusal, bounded timeout with baseline restoration, and exact rollback. Its
focused supervisor, connection-monitor, and public-audit suites pass. The first
full phase-1 run reached every suite; its two intentionally clean-checkout
tmux/terminfo gates refused the uncommitted draft. After the checkpoint commit,
the clean rerun passed all focused suites, guarded-delete tests, and the full
phase-1 gate in 102 seconds.

Protected PR #257 published the initial watchdog at
`d188c3e9d0c045c185e6312cf43cddbc5b563064`; guarded fleet-sync advanced all
seven remote Linux nodes and all four Macs cleanly. Aist installed watchdog
transaction `20260722T160219Z-66174`. Its primary and secondary single-unload
drills recovered autonomously, with the measured secondary recovery taking 23
seconds. The simultaneous unload then reproduced genuine stale listeners:
Local had no Aist route while both fixed ports remained occupied. The Aist-local
watchdog drained them without controller access, restored the primary first,
then converged both services to `managed=1 external=0` with last exit 0 after
roughly seven minutes.

Protected PRs #258 through #260 subsequently published independent single-route
drain, controller use of the same state machine, fresh-auth auditing, and
explicit authorization-blocked recovery outcomes. Their protected commits are
`55693c581556446bb374fe2b32d64e700eae7aca`,
`d91857b2ff11eaaf464136915bf23cfa089bba93`, and
`2ca91146021989014ed9b5108e99dfc8e67a0528`; all managed checkouts were then
clean and current at that commit.

The live soak also caught Home2 down while Home stayed healthy. Unlike Aist's
stale-listener sample, Home2's Local listener was absent and a fresh dedicated
authentication probe from Home failed before restart. The published watchdog
therefore correctly would not mutate that route. A follow-up draft extends the
bounded drain to one stopped, authenticated route while preserving its healthy
sibling and makes the controller request that state machine instead of a blind
kick. Its supervisor and monitor focused suites pass; Home2's distinct
authentication/upstream failure remains a value-free diagnosis item.

Fresh isolated checks then proved Aist `2/2` authentication-ready but Home,
Office, and Riken `0/2` authentication-ready despite their established routes.
Home's private trace classified both failures as authorization rejection; the
mode-0600 trace was exact-unlinked without exposing endpoint or key data. This
is server authorization drift, not a tunnel client failure. Agent policy
categorically prohibits reading or modifying `authorized_keys`, so no
credential repair was attempted. A third focused follow-up adds public
`--auth-status` and makes the five-minute recovering monitor classify a healthy
old pair with blocked replacement authentication as
`state=at-risk action=authorization-blocked`. Synthetic ready/blocked and
monitor classifications pass. Permanent repair requires owner-managed
reauthorization; a root-owned secondary sshd `AuthorizedKeysFile` for
restricted harness tunnel entries is the recommended isolation so unrelated
ordinary-key changes cannot remove them again.

At 01:36:28 JST the observer recorded another Aist `0/2` interval and both
routes were ready by 01:37:07, a 39-second observer bound. The watchdog again
exited 0, but the active Aist Codex makes sole attribution unavailable. PR
#261 (`c0772af617fe9ddf884c104b7be54a63daf09d27`) then added private atomic
last-run receipts so future recovery can be attributed without retaining raw
SSH output.

At 02:05:44 Aist entered a new `0/2` interval. Both Local listeners were still
occupied at 02:15 and absent by 02:23, but neither route rebound. The deployed
retry-count limit omitted SSH probe duration and could stretch its nominal
20-minute bound to roughly 41 minutes. PR #262
(`972988297d01a0c79d9df26a6796a059087abaa1`) now enforces 1,200 elapsed seconds
and distinguishes mid-drain authorization loss from a bind timeout while
restoring the exact launchd baseline in either failure case. The owner-only
credential gate prevented deployment on Aist before this outage.

The at-risk warning also predicted subsequent loss: Office's last old route
ended at 02:37:09 and Home's at 02:37:46. Current Mac state is Aist `0/2`, Home
`0/2`, Office `0/2`, and Riken `2/2`; Riken is still fresh-auth blocked. Local,
the managed Linux checkouts, and Riken are clean/current at `2375ec0`; the
other Macs remain at `2ca9114` because guarded sync preflight could not reach
them and made no change.

PR #264 (`2375ec049aee107ac1501f5306aeed9237d4b144`) also removed a latent
shared-checkout failure: watchdog recovery no longer requires unrelated work
to be clean on branch `main`. It now runs directly and permits unrelated
feature branches or dirty files only while every runtime-critical input exactly
matches the local `main` ref. This defect is confirmed synthetically but cannot
be attributed to the live Aist outage without Aist-side checkout evidence.

The five-hour job ended at 05:23:12 JST. Its dedicated observer covered
00:40:09--05:23:10, 4h43m01s, with 431 value-free samples per node. Aist had
eight changes after its initial state, Home and Office had two each, and Riken
and ABQ had none. At the endpoint Aist had remained `0/2` for at least 3h17m28s,
Office for 2h46m03s, and Home for 2h45m26s; Riken and ABQ remained `2/2` for
the full observer window. The temporary observer stopped and its private log
was exact-unlinked; `harness-connection-monitor` remains alive. Routine arg0
housekeeping preserved three live invocations, removed six eligible residues,
and ended with zero eligible or unexpected candidates.

**Current execution checkpoint:** a reviewed value-free `~/run_this.sh` is
ready on Local. Each Mac runs `--stage LOGICAL_ID` to derive only the public
half of its existing `~/.ssh/harness-reverse`, reconstruct its two exact
listener restrictions from `ssh -G tunnel{,2}`, and transfer one mode-0600
entry to Local without printing it. No identity is generated or changed. Once
all four stages exist, Local `--plan` and `--apply` install a JumpCloud-
preserved `Match User rioyokota` fragment and a root-owned mode-0644 secondary
authorization file, validate `sshd -t` and `sshd -T -C`, reload rather than
restart `ssh.service`, and add/validate one Mac at a time. A failed live check
removes only that Mac's exact staged entry. Mode 0644 is intentional: OpenSSH
opens an `AuthorizedKeysFile` under the target user's UID; root ownership and
the root-owned `/etc/ssh` parent provide the integrity boundary, while the
entries themselves are public keys.

**Next action:** stage Aist, Home, Office, and Riken, then run the Local plan
and apply. Require fresh dedicated authentication and both inbound routes for
each Mac before proceeding. After all eight routes pass, upgrade and drill each
Mac one at a time and run the post-hardening acceptance soak. Do not put these
tunnel entries only in `.jcorig`, modify JumpCloud's global
`AuthorizedKeysFile`, or propagate the Local-only Match block to another node.

Do not drill or install on any Mac until the owner restores the restricted
authorizations and all eight fresh checks pass. Then roll out/drill those Macs
one at a time. Preserve potentially private native logs unread in mode-0600
temporary files and exact-unlink them after extracting only nonprivate
classifications. Do not use
`codex-claude-cowork` unless the owner explicitly reverses the prior exclusion
for this connection work.

**Acceptance:** identify a reproducible cause or a precisely bounded external
failure class; prove unattended recovery under matched primary, secondary, and
simultaneous-loss drills; set a justified recovery bound; retain two
launchd-managed routes with `managed=1 external=0`; and verify all four Mac
pairs remain healthy without credential or unrelated SSH changes.

### T-273 — Resolve intentionally deferred maintenance

**Phase/status:** executing. Workstreams 1, 2, 3, 5, 7, and 9 are complete.
Each remaining item keeps its independent gate.

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
7. **One-way local-to-t4 SSH mirror — complete.** T-295 repaired the declared
   symlink handling, applied the separately authorized mirror transaction, and
   verified `agreement=yes action=none` with rollback retained.
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

- T-295 completed thirteen frozen fleet-convergence workstreams in protected
  PRs #212 through #254, ending at `5d55188`. All eight Mac routes passed fresh
  dedicated authentication and exclusive launchd ownership; ABQ onboarding,
  Python/Homebrew convergence, AL terminal repair, local-to-t4 mirroring,
  Codex/arg0 work, the gated paired benchmark, fleet documentation, and the
  external-user skill reached their acceptance states. The frozen plan is
  `docs/plans/t295-fleet-convergence.md`; full pre-compaction chronology is at
  `5d551883648760fcc373973a575a403b18637f44`.
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
