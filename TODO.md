# Personal harness task board

This is the authoritative resume point for the portable Codex and Claude
harness. Keep only active decisions, blockers, exact next actions, and compact
completion pointers here. Full pre-housekeeping chronology is available at
published commit 90451d49ac96; detailed T-288 execution through Home Git
catch-up is preserved at 378df00159d59e8abee645f2bdaebd20cf467cc2.

Next free ID: T-292.

## Current state

- Protected public main includes PR #170's T-288 generic fix and PR #171's
  post-merge evidence checkpoint. Their exact task branches are absent locally
  and remotely. Active branch `task/t-288-aist-catchup` records the remaining
  blocked host action without requiring chat history.
- Managed Linux nodes are local, ab, ab2, ri, al, rc, and t4.
  abci_login and alps_login are transports, not targets; retired si is out of
  scope.
- Home, Office, and riken accepted clean public/private main after PR #170,
  updater/startup no-op state, both doctors, zero formula-policy residue,
  absent .bash_common/run_this.sh, and only local main. Aist is now caught up
  and its client/startup checks pass, but final doctor correctly refuses a
  newly observed two-sided private SSH-config divergence. No live SSH config
  was changed.
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

1. Complete T-291 planning after either Aist route returns, freeze the managed
   fragment representation, and wait for the explicit execution `go`.
2. Resolve and close T-288 through T-291's canonical SSH-layout migration.
3. On or after 2026-07-26, query only T-196 recorded successor job IDs.
4. Select another independently eligible T-273 workstream only after fresh
   reconstruction of its gate and authority.

## Active tasks

### T-288 — Finish post-onboarding fleet housekeeping

**Phase/status:** executing; blocked on the owner's choice for a genuine Aist
SSH-config divergence. Scope is harness-owned Git, state, startup, and
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
on every node. After PR #171, one final guarded transaction fast-forwarded all
six from 3e4ad67 to that evidence checkpoint and again removed every transfer
artifact. local is also current and clean. T-196 remains time-gated.

**Mac acceptance:**

| Mac | Git/update | Doctors | Refs/residue | Routes |
| --- | --- | --- | --- | --- |
| Aist | public at PR #171; private current; both clean | agent/startup ready; Mac doctor blocked only by SSH divergence | main plus retained local T-290 evidence branch; zero residue | both routes accepted |
| Office | public at PR #171; private current; both clean | Mac/agent ready after fresh wrapper | only main; zero residue | both identities accepted |
| riken | public at PR #171; private current; both clean | Mac/agent ready after cleanup | only main; zero residue | both identities accepted |
| Home | public at PR #171; private current; both clean | Mac/agent ready after fresh shells | only main; zero residue | both identities accepted |

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
link or formula residue recurred during that acceptance. The identical
installer tail and duplicate link later recurred together once more before the
PR #171 catch-up. Their equal modification time and the frozen 99-byte plan
revalidated the same cause. The duplicate was exact-unlinked, the frozen
transaction was replayed, and wrapper plus noninteractive and interactive
login-shell checks left the profile unchanged. Both doctors, startup no-op,
and zero-residue checks pass again.

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

1. Obtain the owner's explicit winner for Aist's unequal live and private
   SSH-config changes; do not infer priority from timestamps or connectivity.
2. Apply only the selected `macos-ssh-sync` reconciliation route, preserving
   its unchanged-only rollback transaction.
3. Repeat fresh wrapper/login-shell acceptance, SSH agreement, both doctors,
   updater/startup no-op plans, and zero-residue checks.
4. Compact the retained T-290 connection evidence before any public push,
   record final fleet health, and close T-288.

**Safety/recovery:** no raw recursive or multi-path deletion. Eligible tree
cleanup uses a fresh guarded manifest and token. Authentication failure,
divergent/dirty Git, unsafe metadata, open handles, prompts, or loss of both
routes stops only that host. Do not reload active shells, change packages, or
touch backup/transaction state.

**Next executable action:** ask whether Aist's current live `.ssh/config` or the
private companion's current payload is authoritative. `macos-ssh-sync` reports
`class=diverged agreement=no`; the later-divergence gate forbids automatic
adoption. Both routes are live, the public/private repositories are clean and
current, updater rollback/reapply passed, the strict Codex tooltip state is
accepted without editing, the duplicate official Codex link is removed, and
fresh wrapper/login shells leave startup files unchanged. Do not begin deferred
Homebrew/package work.

### T-291 — Converge shared SSH fragment across the managed fleet

**Phase/status:** planning. The owner's desired state is one canonical,
non-secret `~/.ssh/config.d/harness.conf` sourced at the end of every managed
root SSH config. Aist's fragment is authoritative. Exact `Host github` and
`Host *` stanzas are removed from every root config so OpenSSH first-value
precedence cannot shadow the fragment. Managed targets are local, ab, ab2, ri,
al, rc, t4, Aist, Office, riken, and Home; transport-only aliases are excluded.

**Scope and non-goals:** manage only the two public shared stanzas, their one
terminal include, and the fragment link/file needed to supply them. Preserve
all other SSH bytes, ordering, file modes, keys, `known_hosts`, agent state,
control sockets, connection processes, and private companion values. Do not
print or commit private SSH payloads, reload sessions, alter tunnels, change
packages, or broaden Linux SSH mirroring.

**Confirmed value-free inventory:** all seven Linux roots already end with one
managed include and all seven fragments are symlinks to the tracked public
fragment; combined grammar is valid. local and al duplicate both shared
stanzas, ab and ab2 duplicate GitHub only, t4 duplicates both, and ri/rc have
no root duplicate. Office, riken, and Home each have one GitHub and one
`Host *` root stanza but no fragment/include. Their configs are regular,
current-user-owned, single-link, mode 0600. Both Aist routes dropped before its
fragment and current root could be revalidated. Earlier T-288 evidence proves
its private/live roots are unequal and no automatic winner is permitted.

**Working set:** `config/ssh/harness.conf`, a new or extended transactional SSH
layout adapter and command dispatch, the Mac SSH validator/sync contract,
focused synthetic tests, `docs/ssh-config-sync.md`, relevant Mac documentation,
and this ledger. The private companion and live SSH files change only after
generic publication.

**Execution sequence:**

1. Revalidate Aist through both routes. Accept its fragment as source only if
   it is a bounded current-user-owned regular file or the exact managed link,
   contains exactly one `Host github` and one `Host *` stanza, contains no
   credential material or external include, and passes isolated OpenSSH
   grammar. Compare or adopt it without printing bytes or a content identity.
2. Implement a cross-platform transactional layout plan that parses complete
   top-level SSH stanzas, refuses `Match`/multi-pattern/duplicate ambiguity,
   removes only the two selected stanza blocks, and installs exactly one
   terminal `Include ~/.ssh/config.d/harness.conf`. Preserve every other byte
   and the root file's existing safe mode.
3. Manage the fragment through the repository-owned canonical source. Extend
   the Mac private-payload validator to allow only that exact single terminal
   include while continuing to reject every other `Include`, `Match exec`,
   credential-like material, unsafe metadata, and external reads during
   validation.
4. Add synthetic Linux/Darwin tests for all observed combinations, ambiguous
   refusal, byte preservation, idempotence, injected failure, exact
   unchanged-only rollback/reapply, private divergence convergence, and
   privacy-negative output. Run focused tests, ShellCheck, `git diff --check`,
   public audit, and all 57 phase-one suites.
5. Publish through protected CI, merge without force, then guarded-sync only
   clean Linux checkouts and update each clean Mac public checkout.
6. On Aist, transform the live root and private payload through the reviewed
   transaction so removing shared stanzas resolves rather than guesses the
   current divergence. Publish the forward-only private commit, exercise exact
   local rollback, and reapply. Stop if non-shared bytes remain unequal.
7. Sequentially pull/apply the private root plus managed fragment on Office,
   riken, and Home, with per-host plan, rollback/reapply, fresh-route checks,
   `ssh -G` validation, SSH agreement, and Mac doctor acceptance.
8. Sequentially plan/apply the same root-stanza removal on the seven Linux
   nodes, stopping at the first drift. Recheck effective GitHub/default
   resolution without printing values, clean Git, and absence of transaction
   residue.
9. Compact T-290's retained connection evidence, close T-288/T-291, merge the
   final ledger through protected CI, perform the final guarded fleet catch-up,
   and report compact fleet health.

**Safety and rollback:** every live plan must bind to the exact preimage type,
owner, link count, mode, size, and content identity without emitting private
values. Apply stores mode-0600 complete preimages in private transaction state,
atomically replaces only the root config and fragment representation, and
supports unchanged-only rollback. Private Git is forward-only; no reset,
force-push, timestamp winner, or automatic three-way payload merge is allowed.
Existing SSH sessions are not proof of new-config acceptance; both fresh route
aliases must pass after apply.

**Acceptance:** eleven roots have zero GitHub/default stanza blocks and exactly
one terminal managed include; eleven fragments resolve to the Aist-approved
canonical public bytes; all files retain safe ownership/types/modes; OpenSSH
grammar and effective resolution pass; all four Macs report SSH agreement and
ready doctors; all Git checkouts are clean/current; rollback/reapply evidence
exists per changed host; no credential, private value, fragment hash, or raw
payload enters public output or Git.

**Decision register:** D1 (settled) covers all eleven managed systems and
excludes proxy aliases. D2 (settled) intentionally discards complete root
GitHub/`Host *` blocks in favor of Aist's canonical fragment, even if their
options differ. D3 (open; recommended) represents the fragment everywhere as
a symlink to tracked `config/ssh/harness.conf`, matching all seven Linux nodes;
the alternative is eleven private copies with greater drift and rollback
surface.

**Next executable action:** when either Aist route returns, complete step 1 and
then ask only D3. After D3 is recorded, set `ready-for-go` and wait for an
explicit `go`; make no live SSH change during planning/interviewing.

### T-290 — Diagnose termination of Aist reverse SSH forwards

**Phase/status:** diagnosed; publication deferred. Detailed local evidence was
preserved exactly on Aist commit `5f03af3` and controller ref
`refs/preserve/t-290-aist-forward-diagnosis`. It indicates route oscillation
followed by the configured keepalive failure window, not authentication or a
local SSH-port refusal. The raw checkpoint contains local process/network
details and must be compacted before any public push. T-291 changes no tunnel
or keepalive setting.

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
