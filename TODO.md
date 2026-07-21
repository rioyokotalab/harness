# Personal harness task board

This is the authoritative resume point for the portable Codex and Claude
harness. Keep only active decisions, blockers, exact next actions, and compact
completion pointers here. Full pre-housekeeping chronology is available at
published commit 90451d49ac96; detailed T-288 execution through Home Git
catch-up is preserved at 378df00159d59e8abee645f2bdaebd20cf467cc2.

Next free ID: T-290.

## Current state

- Protected public main is 3e4ad6705ad1310560601e079169d1ab7c52037d.
  PR #170 merged the T-288 generic fixes; its exact task branch is absent
  locally and remotely. This ledger-only closeout branch records post-merge
  fleet evidence while Aist catch-up remains blocked on transport.
- Managed Linux nodes are local, ab, ab2, ri, al, rc, and t4.
  abci_login and alps_login are transports, not targets; retired si is out of
  scope.
- Home, Office, and riken accepted clean public/private main after PR #170,
  updater/startup no-op state, both doctors, zero formula-policy residue,
  absent .bash_common/run_this.sh, and only local main. Aist last accepted the
  prior public/private main and is now behind protected main because both
  routes are unavailable; no live Aist config was changed.
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

1. When either Aist route returns, apply PR #170 through the native Mac updater
   and run the frozen post-shell acceptance. This is T-288's only remaining
   host action.
2. On or after 2026-07-26, query only T-196 recorded successor job IDs.
3. Select another independently eligible T-273 workstream only after fresh
   reconstruction of its gate and authority.

## Active tasks

### T-288 — Finish post-onboarding fleet housekeeping

**Phase/status:** executing; blocked only on both Aist routes being unavailable.
Scope is harness-owned Git, state, startup, and
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

**Linux synchronization:** after PR #170, guarded preflight found ab, ab2, ri,
rc, and t4 clean at intermediate commit 5c6e4c9 and al clean at 21fde49. Two
source-specific transactions fast-forwarded all six to 3e4ad67. Independent
checks proved clean HEAD and origin/main equality and zero transfer artifacts
on every node; local is also current and clean. T-196 remains time-gated.

**Mac acceptance:**

| Mac | Git/update | Doctors | Refs/residue | Routes |
| --- | --- | --- | --- | --- |
| Aist | clean at pre-#170 main; catch-up pending | Mac ready before merge; agent fix pending | only main; zero residue | both routes unavailable |
| Office | public 3e4ad67; private current; both clean | Mac/agent ready after fresh wrapper | only main; zero residue | both identities accepted |
| riken | public 3e4ad67; private current; both clean | Mac/agent ready after cleanup | only main; zero residue | both identities accepted |
| Home | public 3e4ad67; private current; both clean | Mac/agent ready after fresh shells | only main; zero residue | both identities accepted |

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

The generic T-288 changes preserve only strict Codex-managed tooltip state,
route Darwin installer updates through the reviewed Homebrew destination, and
require post-login-shell acceptance. Clean commit `b9c4cf4` passed all 57
focused suites in `tests/test-phase1.sh`; protected CI passed, and PR #170
squash-merged as 3e4ad67. The exact task branch was deleted locally and
remotely by the merge workflow.

**Fresh resumed drift:** both Aist routes briefly returned and resolved to the
same host. Authenticated fetch proved clean/equal public/private `main`, updater
and Bash plans were current, Mac doctor was ready, and residue remained zero.
Agent doctor alone failed because Codex had added one strict
`[tui.model_availability_nux]` entry. The current official Codex manual defines
that nested table as internal tooltip state usually managed by Codex. The
public adapter must preserve only its quoted safe model-slug/nonnegative-integer
shape and continue rejecting arbitrary TUI settings. Both routes then dropped
together; no live config was changed.

Home's exact 99-byte thin-profile tail recurred at 14:05:11, 17 minutes after
the latest Bash transaction. A write-restricted macOS sandbox ran the managed
login shell against private disposable copies: it returned zero, changed
neither startup copy, and left the live profile unchanged, disproving direct
login-shell causality. The tail contains the Codex-installer marker and local-bin
PATH entry; standalone-package state, the new local-bin Codex link, and the
profile share the exact 14:05:11 modification time. That link and Homebrew's
link resolve to the same official package, while local-bin currently wins PATH.
The reviewed installer edits a profile unless its destination is already on
PATH. The generic Darwin launcher now exports the Homebrew bin as
`CODEX_INSTALL_DIR` and prepends it to PATH so installer-based updates inherit
the reviewed destination. After publication, Home revalidated both links as
the same official standalone package, exact-unlinked only the duplicate local
link, and applied the frozen preservation transaction. Noninteractive and
interactive managed login shells both passed; a subsequent startup plan and
both doctors remained ready, the profile stayed canonical, and no duplicate
link or formula residue recurred.

Office updated to 3e4ad67 and retained its sole official local-bin Codex link
because no Homebrew-bin duplicate exists. Its fresh wrapper, login shell,
startup plan, and both doctors passed. Five old eligible formula-policy leaves
were staged content-blind and removed through guarded manifest revalidation;
protected anchors were unchanged and final residue is zero. riken likewise
updated and passed both doctors and startup acceptance; its one eligible old
formula-policy leaf was guarded-deleted with unchanged protected anchors and
zero final residue.

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

1. Retry both Aist routes without inferring state across disconnects.
2. When one route is stable, revalidate identity, forwarded-agent transport,
   clean Git, and last durable markers; fetch and apply 3e4ad67 through
   `macos-update`.
3. Confirm the strict live tooltip table is accepted without editing it,
   classify the native Codex path, run fresh wrapper/login-shell acceptance,
   and remove only separately proven residue through guarded deletion.
4. Record final Aist and compact fleet health, then close T-288.

**Safety/recovery:** no raw recursive or multi-path deletion. Eligible tree
cleanup uses a fresh guarded manifest and token. Authentication failure,
divergent/dirty Git, unsafe metadata, open handles, prompts, or loss of both
routes stops only that host. Do not reload active shells, change packages, or
touch backup/transaction state.

**Next executable action:** keep the five-minute monitor active and retry Aist.
Both `aist` and `aist2` currently refuse their local forwarded ports, so peer
recovery is impossible until either route returns. Then execute the four frozen
steps above. Do not edit live client/startup files or begin deferred
Homebrew/package work.

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
