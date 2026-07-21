# Personal harness task board

This is the authoritative resume point for the portable Codex and Claude
harness. Keep only active decisions, blockers, exact next actions, and compact
completion pointers here. Full pre-housekeeping chronology is available at
published commit 90451d49ac96; detailed T-288 execution through Home Git
catch-up is preserved at 378df00159d59e8abee645f2bdaebd20cf467cc2.

Next free ID: T-290.

## Current state

- Protected public main is 21fde49259193a0ba2df2259e192b5a8c36bc75d.
  Active T-288 branch task/t-288-housekeeping-closeout-v2 contains that main
  and is pushed.
- Managed Linux nodes are local, ab, ab2, ri, al, rc, and t4.
  abci_login and alps_login are transports, not targets; retired si is out of
  scope.
- All four Macs last accepted current clean public/private main, updater no-op
  state, ready Mac/agent doctors, zero formula-policy residue, absent
  .bash_common/run_this.sh, and only local main. Aist's two routes are currently
  unavailable; do not infer fresh host state until one returns.
- The tmux session harness-connection-monitor probes Aist/Aist2,
  Office/Office2, riken/riken2, and Home/Home2 every 300 seconds. It reconnects
  a dropped primary through its secondary with ssh login, or a dropped
  secondary through its primary with ssh login2. It is an owner-requested task
  monitor, not a login service or profile change.
- Exactly one future native weekly primary backup job exists on each managed
  Linux node. First runs passed on 2026-07-19; keep-all remains effective.
- Global safety and collaboration invariants in .codex/AGENTS.md remain
  authoritative. Never inspect credentials or use raw recursive/bulk deletion.
- Whenever owner input/approval is requested or a task is completed, report a
  fresh health snapshot for all managed Linux nodes and all four Mac route
  pairs. Report transport aliases separately from managed targets.

## Next resume checkpoint

1. Complete T-288 Home Bash/ref review, final acceptance, protected publication,
   post-merge fleet catch-up, and exact task-ref cleanup.
2. On or after 2026-07-26, query only T-196 recorded successor job IDs.
3. Select another independently eligible T-273 workstream only after fresh
   reconstruction of its gate and authority.

## Active tasks

### T-288 — Finish post-onboarding fleet housekeeping

**Phase/status:** executing. Scope is harness-owned Git, state, startup, and
exact updater residue. Homebrew/package maintenance is explicitly deferred.
Backups, transaction/failure evidence, credentials, active sessions,
package/cache data, unknown residue, and private payloads are retained or
excluded.

**Published fix and controller cleanup:** the macOS updater public-fast-forward
re-exec path omitted one formula-policy temporary from its exact unlink list.
The fix and isolated no-leak regression passed focused privacy/source checks,
clean full tests/test-phase1.sh, and protected CI. PR #167 merged at
5c6e4c9c2f9a789463e97473f357d2a11ee5b083. Guarded controller cleanup removed
exactly 192 proven formula-policy leaves plus one synthetic refused-test tree
(2,828 entries, 6,652,804 bytes), verified protected anchors unchanged, and
removed the empty staging boundary. No other temporary class was selected.

**Linux synchronization:** ab, ab2, ri, rc, and t4 were cleanly guarded-synced
from 535a492 to the published fix at 5c6e4c9; al later guarded-synced from the
same ancestor to current 21fde49. Every transfer artifact was verified absent.
local is current. T-196 is the only scheduled future al work and remains
time-gated.

**Mac acceptance:**

| Mac | Git/update | Doctors | Refs/residue | Routes |
| --- | --- | --- | --- | --- |
| Aist | public/private current and clean | Mac/agent ready | only main; zero residue | both identities accepted |
| Office | public/private current and clean | Mac/agent ready | only main; zero residue | both identities accepted |
| riken | public/private current and clean | Mac/agent ready | only main; zero residue | both identities accepted |
| Home | public/private current and clean | Mac/agent ready | only main; zero residue | both identities accepted |

Aist stale T-280 refs were deleted only after each showed zero unique patches,
one patch-equivalent commit on main, no remote ref, and merged PR #151 or #152.
The first T-288 closeout branch was similarly removed after v2 proved both
patches preserved and zero open PRs.

**Home completion:** the explicit `--merge-thin-profile-tail` transaction moved
only the unread 99-byte appended profile tail into `.bashrc` login-only state
and restored the exact canonical thin profile. Syntax, fresh non-login/login
shells, the managed Bash launcher, no-op startup/update plans, and both doctors
passed. Unchanged-only rollback restored the exact prior drift and one expected
doctor failure; an identical reapply then passed the full acceptance again.
Transaction identifiers and startup bytes remain private.

After authenticated prune proved every corresponding remote ref absent, all
ten exact local T-276 refs were deleted. Seven had zero unique patches, one
pointed at main, the two apparently unique CI-fix commits were the exact commits
recorded in merged PR #128, and the obsolete ledger commit was closed PR #126,
superseded by merged PR #127 and completed through #134. Home now has only
local `main`.

Final inventory found five old unopened, current-owner, regular, single-link
formula-policy temporaries aged about 38 minutes to 16 hours. They were moved
content-blind with per-file identity checks into one fresh mode-0700 target.
Guarded-delete manifest revalidation accepted one target with six entries and
1,009 bytes, deleted it, and verified protected anchors unchanged. The two
mode-0600 bookkeeping files and empty boundary were exact-unlinked. A fresh
updater plan created no new residue; final count is zero.

Clean checkpoint `a3616bf` passed the complete `tests/test-phase1.sh` suite
after Home acceptance; no focused suite failed.

**Connection monitoring:** initial monitor recovery restored aist2 through live
aist with ssh login2. The symmetric mapping is active: secondary to ssh login
restores a primary; primary to ssh login2 restores a secondary. After any route
switch, revalidate host, forwarded-agent, Git, and last durable-step markers.
Never infer completion across a disconnect. Use
tmux capture-pane -p -t harness-connection-monitor:monitor for recent
value-free status. No automatic recovery is possible if both routes to one Mac
are simultaneously down. Both Home routes recovered and accepted the completed
work. Aist and aist2 are both currently unavailable; the owner deferred that
transport investigation until after the independent Home work.

**Frozen remaining order:**

1. Investigate and restore at least one Aist route, then reconstruct both route
   and host state; do not repeat accepted Home work.
2. Reconcile fresh contributor main, validate the compact ledger, publish the
   closeout through protected CI, and remove only proven T-288 refs.
3. Apply required post-merge guarded Linux sync and native Mac update catch-up;
   finish with a full fleet health report.

**Safety/recovery:** no raw recursive or multi-path deletion. Eligible tree
cleanup uses a fresh guarded manifest and token. Authentication failure,
divergent/dirty Git, unsafe metadata, open handles, prompts, or loss of both
routes stops only that host. Do not reload active shells, change packages, or
touch backup/transaction state.

**Next executable action:** checkpoint and push the verified Home completion.
Then restore/reconstruct Aist when its transport investigation resumes. Do not
repeat Home work or begin deferred Homebrew/package work.

### T-273 — Resolve intentionally deferred maintenance

**Phase/status:** executing. Workstreams 1, 2, 3, and 9 are complete. Each
remaining item keeps its independent gate.

1. **Failed transaction evidence — complete/retain.** Small paired recovery
   preimages lack a cleanup contract.
2. **Linux agent replacement — capability complete.** PR #143 published
   1ed9712bc8c3fd4896df2654b2a3379412e5984d; no live replacement or old-tree
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
