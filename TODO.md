# Personal harness task board

This is the authoritative resume point for the portable Codex and Claude
harness. Keep only active decisions, blockers, exact next actions, and compact
completion pointers here. Full pre-housekeeping chronology is available at
published commit 90451d49ac96; detailed T-288 execution through Home Git
catch-up is preserved at 378df00159d59e8abee645f2bdaebd20cf467cc2.

Next free ID: T-293.

## Current state

- Protected public main includes PR #170's T-288 generic fix and PR #171's
  post-merge evidence checkpoint. Their exact task branches are absent locally
  and remotely. Active branch `task/t-288-aist-catchup` records the remaining
  blocked host action without requiring chat history.
- Managed Linux nodes are local, ab, ab2, ri, al, rc, and t4.
  abci_login and alps_login are transports, not targets; retired si is out of
  scope.
- PRs #172 through #176 published the transactional SSH layout, rollback
  hardening, layout-only private-history bridge, global-context trailer, and
  narrow historical-input bridge, and stale-state refresh; public main is
  `c17c68a`. Local, all six remote Linux nodes, and all four Macs are
  clean/current with the strict live trailer and effective GitHub/default
  resolution; all eleven live layouts satisfy the strict invariant.
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

1. Execute T-291's owner-selected per-Mac private SSH payload migration without
   changing any live SSH bytes.
2. Resolve and close T-288 through T-291's canonical SSH-layout migration.
3. On or after 2026-07-26, query only T-196 recorded successor job IDs.
4. Select another independently eligible T-273 workstream only after fresh
   reconstruction of its gate and authority.

## Active tasks

### T-292 — Isolate SSH failover aliases from connection multiplexing

**Phase/status:** executing after explicit owner authorization. Aist's separate
local Codex restored `aist`/`aist2` by setting `ControlMaster no` and
`ControlPath none` in the private `Host login` and `Host login2` blocks. The
owner selected the safer shared form: add one exact `Host login login2`
exception before the canonical `Host *` defaults, retaining multiplexing for
every other destination. `ControlPersist no` makes the exception complete but
is otherwise inert once `ControlPath none` disables sharing. After reviewing
the initial rollout, the owner explicitly approved `ExitOnForwardFailure yes`
in the same exact block so a connection cannot report success when any of its
requested forwards failed to initialize.

**Evidence and scope:** upstream OpenSSH uses the first obtained value, so a
later override would be ineffective. The tracked fragment currently gives all
hosts `ControlMaster auto`, a configured path, and persistent masters. A global
replacement would add handshakes and authentication to Git, SCP, interactive,
and fleet operations; it is rejected. Change only the public canonical
fragment, its exact-source validator, effective-resolution regression, focused
documentation, and this ledger. Preserve all private root bytes, endpoints,
credentials, existing sessions, and the owner-managed Aist repair commit.

**Execution/acceptance:** prove `login` and `login2` resolve to disabled control
sharing while GitHub and an ordinary target retain auto/configured/persistent
multiplexing; retain canonical exactness, grammar, transactional
rollback/reapply, public privacy audit, all focused suites, and protected CI.
After merge, transactionally update only clean/current managed fragments and
verify effective classes without emitting paths. Existing masters are not
terminated; the change governs new clients. Stop on dirty Git, layout drift,
route loss, ambiguous private state, or an independently advanced public main.

**Implementation checkpoint:** branch `task/t-292-login-control-isolation` adds
the exact three-option exception before `Host *`, teaches the canonical
validator that one exact non-shared block is mandatory, documents first-value
ordering and existing-master behavior, and tests effective failover and
ordinary-host resolution. `tests/test-ssh-config-layout.sh`, the Python syntax
check, ShellCheck, and `git diff --check` pass. On this OpenSSH, a disabled
`ControlPath none` is represented by the absence of a `controlpath` line in
`ssh -G`; the regression checks that normalized behavior without exposing a
path.

The first `tests/test-phase1.sh` attempt ran every focused suite: all passed
except `test-tmux-config.sh`, whose long-TMPDIR case correctly requires a clean
committed checkout. The SSH layout, Mac SSH sync, source-contract, and public
privacy audit suites passed. This is a retry-safe repository-state gate, not a
product failure; rerun the same full suite after the intended commit.

Commit `88d9bdc` contains the implementation. From that clean commit,
`tests/test-phase1.sh` passed in full; the only reported skip was the suite's
expected native-MPI environment smoke test, which is unrelated to SSH config.

**Publication and rollout checkpoint:** PR #182 passed protected
`portable-phase1` and squash-merged as `10679a4`. Guarded fleet-sync found all
six Linux mirrors clean at their common older prerequisite `2d39f82`, then
fast-forwarded their `HEAD` and `origin/main` to the published commit. Local
and all six Linux layouts apply/current, and a representative local exact
rollback/reapply passed. An initial rollback command omitted `--host local` and
was rejected before mutation; the unchanged transaction then rolled back and
reapplied normally.

Office, riken, and Home fetched clean public/private targets and passed the
schema-3 updater plan/apply. That integrated the independently published Aist
repair where behind without exposing or modifying private payload bytes. Their
managed fragments now apply/current. Across local, all six Linux nodes, and
these three Macs, value-minimized effective checks prove canonical fragment
bytes, disabled multiplexing for `login`/`login2`, and retained automatic
persistent multiplexing for GitHub and an ordinary target.

Aist remains the sole rollout gap. Both `aist` and `aist2` fresh connections
timed out during banner exchange, including explicit non-multiplexed attempts;
the 19:39 JST monitor cycle independently reported both down. No Aist Git,
private state, or live configuration changed, so retry is safe. Existing SSH
sessions and control masters on every host were left intact.

**Fail-fast refinement:** value-minimized inspection on Office, riken, and Home
proved that `login` requests one local and one remote forward, `login2` requests
one remote forward, and both previously resolved the default
`ExitOnForwardFailure no`. OpenSSH documents that `yes` exits when any requested
forward cannot be established, but does not test the ultimate destination or a
later failure. This is adopted for the two dedicated aliases only; a legitimate
bind collision will fail the new connection, which is the intended observable
result rather than a route-less shell. The exact canonical validator and
effective regression must require `yes` for both aliases and retain the default
`no` for ordinary targets.

The exact-source and effective-resolution change passes
`test-ssh-config-layout.sh`, both relevant Mac profile/SSH-sync suites, the
public repository audit, source-contract test, Python syntax, ShellCheck, and
`git diff --check`. The controller has no authenticated localhost SSH service,
so a disposable real bind-collision experiment is unavailable without adding
test-only authentication infrastructure; no live tunnel was disturbed. The
deterministic regression instead verifies OpenSSH's resolved fail-fast value,
while existing synthetic transaction tests retain byte, rollback, and failure
coverage.

Clean implementation commit `cd9cfc2` passes the complete
`tests/test-phase1.sh`; every focused suite and guarded-delete test passed, and
native MPI was the declared environment-only skip.

**Fail-fast publication/rollout:** PR #183 passed protected
`portable-phase1` and squash-merged as `f5ae449`. Guarded fleet-sync
fast-forwarded all six clean Linux mirrors from `10679a4` to that commit and
removed every transfer artifact. Local exercised exact rollback/reapply; all
six remote Linux layouts apply/current. Office, riken, and Home fetched clean
public/private targets through private-output-safe logs, applied the schema-3
updater with private=current and package actions none, and now have current
managed fragments. A combined Mac command ended after riken's completed apply
without returning the remaining output; independent read-only checks proved
riken and Home clean at `f5ae449` with layout state current, so no result was
inferred across the output loss.

Value-minimized end-to-end checks pass on local, all six Linux nodes, Office,
riken, and Home: installed fragments equal the canonical source;
`login`/`login2` resolve to disabled multiplexing and
`ExitOnForwardFailure yes`; GitHub and an ordinary host retain automatic
persistent multiplexing and `ExitOnForwardFailure no`. Existing sessions were
not terminated. Aist/Aist2 remained down in the 20:05 JST monitor cycle and
both direct probes; no Aist state changed.

**Next executable action:** after the owner restores at least one Aist route,
fetch its clean public/private targets through a mode-0600 disposable log, run
the schema-3 updater plan/apply, then layout plan/apply and the same
value-minimized effective audit. Close T-292 only after both fresh Aist routes
are healthy under the new fail-fast policy.

### T-288 — Finish post-onboarding fleet housekeeping

**Phase/status:** executing; its SSH blocker is resolved by T-291's frozen
structure-aware migration and awaits that plan's execution. Scope is
harness-owned Git, state, startup, and
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

**Next executable action:** execute T-291 after the explicit `go`. Its
disposable three-way classification proved the private side's non-shared bytes
still equal the recorded base, while Aist alone changed non-shared bytes; the
apparent two-sided conflict is therefore resolved without guessing once the
shared stanzas are normalized. Do not begin deferred Homebrew/package work.

### T-291 — Converge shared SSH fragment across the managed fleet

**Phase/status:** externally blocked and handed off at three of four per-Mac
payloads; local layout is already complete on all eleven nodes. The owner
selected preservation of each Mac's distinct non-shared bytes and gave the
explicit `go`. The desired state
copies Aist's existing
root `Host github` and `Host *` blocks intact into regular
`~/.ssh/config.d/harness.conf` files on every managed system, then sources that
file at the end of each root SSH config. Only after the fragment is installed
and validated are those two blocks removed from every root config. Managed
targets are local, ab, ab2, ri, al, rc, t4, Aist, Office, riken, and Home;
transport-only aliases are excluded.

**Scope and non-goals:** manage only the two selected shared stanzas, their one
terminal include, and the regular fragment copy needed to supply them. Preserve
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
current-user-owned, single-link, mode 0600. Both Aist routes resolve to the same
Mac. Its safe regular mode-0600 root contains exactly one single-pattern
GitHub block and one `Host *` block, no include, and no existing fragment.

**Working set:** `config/ssh/harness.conf` if Aist's selected blocks pass the
public non-secret gate, a new or extended transactional SSH
layout adapter and command dispatch, the Mac SSH validator/sync contract,
focused synthetic tests, `docs/ssh-config-sync.md`, relevant Mac documentation,
and this ledger. The private companion and live SSH files change only after
generic publication.

**Canonical-source evidence:** disposable mode-private extraction found only
generic public-safe option classes: GitHub host/user selection, forwarding and
agent defaults, keepalive, and control-master/path/persistence settings. The
comments also pass the public boundary. Grammar is valid, credential and
external-include gates are clear, and the bytes differ from the current public
fragment. No value or content identity was emitted. A structure-aware
three-way simulation found the transformed private payload equal to its
recorded base, the transformed Aist live root locally changed, and the two
transformed results unequal. Thus normalization converts the current apparent
two-sided conflict into a valid local-only publish; non-shared remote changes
are not being discarded.

**Implementation checkpoint (2026-07-21):** both Aist routes were revalidated,
and the exact selected blocks passed the repeated public-safe option/comment,
credential, ambiguity, and isolated grammar gates before replacing the tracked
canonical source; no live SSH file changed. New `harness ssh-config-layout`
plan/apply/rollback support installs the regular fragment first, preserves all
non-shared root bytes and safe mode, refuses ambiguous patterns/`Match`/foreign
includes, validates combined grammar, recovers an injected first-replacement
failure, and performs unchanged-only two-file rollback. `harness dotfiles`
now delegates SSH work to this transaction instead of recreating symlinks.
The Mac validator permits only the one exact terminal include and strips it
through stdin before grammar validation; the Mac doctor requires the final
layout after payload adoption. The Aist-shaped private-base/live-normalized
regression selects ordinary local-only publication.

Focused layout, private-profile, Mac plan/doctor, SSH-sync, and config-sync
tests pass, as do `git diff --check`, Python/shell syntax, ShellCheck for the
changed shell files, the public audit, all 57 focused suites, and the complete
clean-checkout `tests/test-phase1.sh`. Native MPI was the declared
environment-only skip. Two integrated-fixture corrections made its synthetic
root mode explicit and used the existing non-main test bypass; production
still requires a clean committed `main`. No live host was mutated.

**Publication/rollout checkpoint:** PR #172 passed protected CI and squash-
merged as `cfb1da2`. Guarded fleet-sync updated all six remote Linux checkouts;
Office, riken, and Home then accepted public-only Mac updater transactions with
private=current and package_actions=none. Read-only layout plans pass on those
ten reachable nodes with exactly the previously inventoried stanza/fragment
classes. Aist/Aist2 remain down. Pre-live review added a focused follow-up that
preflights every Include before block removal (so a foreign include cannot hide
inside a selected stanza) and restores the self-contained root before the
prior fragment during rollback. Its focused test, public audit, all 57 focused
suites, and the complete clean-checkout phase-one suite pass; native MPI was
again the declared environment-only skip.

PR #173 then published that hardening as `a6c9ac6`; Linux and the reachable
Office, riken, and Home public checkouts are clean/current there. The owner
restored `aist`; `aist2` remained down. Aist updated cleanly to `a6c9ac6`, its
canonical root-to-source comparison passed, and layout apply, validation,
exact rollback, and reapply all passed. The subsequent private sync stopped
without commit/push because its raw private revision had advanced through a
shared-stanza-only representation change even though normalized non-shared
remote bytes equal the recorded base. The second layout transaction was rolled
back exactly, leaving the original root and absent fragment.

The active bridge change is narrowly gated on a current canonical live layout:
it normalizes only the fetched and recorded-base comparison files; when those
are equal, it permits a clean private fast-forward followed by ordinary live
publication. Any normalized remote difference, local-ahead history, or non-
fast-forward still stops. Synthetic layout-only fast-forward/publication and
non-shared divergence-refusal tests pass. The public audit, all 57 focused
suites, and complete clean-checkout phase one pass; native MPI was the declared
environment-only skip.

PR #174 published the bridge as `322fe1f`. Aist then repeated layout apply,
classified private sync as ordinary publish, fast-forwarded the clean private
checkout, committed/pushed forward, and passed exact private rollback/reapply.
Its layout, private agreement, fresh shells, and Mac doctor are ready. A
recurring 101-byte thin-profile tail was preserved through the reviewed
login-only merge with exact rollback/reapply.

Office, riken, and Home each normalized live/base/remote comparison to three
unequal non-shared payloads. Therefore no automatic private winner was chosen.
Each host instead ran the requested local-only layout apply, grammar checks,
exact rollback, and reapply, preserving every non-shared byte. Their layout
doctor invariant passes, but the legacy single whole-file private payload now
reports divergence. Home's recurring 99-byte thin-profile tail was likewise
preserved through its reviewed rollback/reapply route; its only doctor failure
is now private SSH divergence, matching Office and riken.

All seven Linux nodes converted their prior managed fragment symlinks to exact
regular mode-0600 copies, removed any selected root stanzas, and passed current
plan, combined grammar, rollback, and reapply. t4's first apply completed while
the output connection ended; exactly one complete transaction was found,
validated, rolled back, and reapplied. A final parallel check proved all eleven
layouts current, all public checkouts clean at `322fe1f`, and both GitHub and
default grammar resolution valid without emitting values.

The first final Git fetch exposed that a terminal Include alone remains under
the preceding OpenSSH Host context and can therefore skip the fragment. Local
was immediately repaired with the exact `Match all` global-context reset before
the terminal include, restoring verified GitHub hostname/user resolution and
authenticated fetch. The active correction updates the transaction, effective-
resolution regression, documentation, and all roots; publication and fleet
reapply are required before T-291 can close. Commit `54aa87c` implements the
exact two-line trailer, refuses a managed include without its context reset in
Mac private payloads, and adds an include-only upgrade regression. All 57
focused suites and complete clean-checkout phase one pass; native MPI remains
the declared environment-only skip.

PR #175 merged the correction as `b72b366`; guarded fleet-sync advanced all
six remote Linux public checkouts. Aist, riken, and Home public checkouts also
advanced through the direct public GitHub URL because their old terminal
include could not resolve the `github` alias. riken and Home now plan the live
trailer upgrade. Aist instead exposed a migration-order gap: its private
payload contains the previously published exact include-only layout, so strict
profile validation blocks the transaction that would upgrade it. The active
bridge permits that one historical form only as layout/SSH-sync migration
input; live and publication candidates remain strict. Office is unchanged
because both routes are presently down.

PR #176 merged the historical-input bridge as `05e9882`, with all 57 focused
suites and protected portable CI passing. Guarded fleet-sync advanced all six
remote Linux checkouts again. Local, ab, ab2, ri, al, rc, t4, riken, and Home
then applied the strict trailer, proved effective GitHub hostname/user and
default keepalive resolution, rolled back exactly, and reapplied. Final
transactions are local `20260721T083458Z-1811408`, ab
`20260721T083543Z-1444112`, ab2 `20260721T083543Z-3212074`, ri
`20260721T083543Z-3593946`, al `20260721T083545Z-90376`, rc
`20260721T083543Z-240525`, t4 `20260721T083544Z-2207201`, riken
`20260721T083709Z-38034`, and Home `20260721T083705Z-46261`. An independent
parallel check confirmed all nine layouts, fragments, effective fields, and
public checkouts current. Aist's public fetch lost its route before a result;
the local stuck transport was terminated without assuming remote success.

Aist later recovered clean and untouched, advanced to `05e9882`, and passed
live layout apply, rollback, and reapply at final transaction
`20260721T084044Z-52889`. Its strict private payload publish succeeded at sync
transaction `20260721T084120Z-54230`. The required sync rollback then exposed
one final narrow planner gap: when live and remote are already byte-identical
but only the recorded revision is stale, it selected a redundant publish
instead of a pull/state refresh. The active regression and fix cover that exact
historical-layout rollback path; Aist is safely left with clean/current strict
private Git and the rolled-back prior sync state until the fix is published.

PR #177 merged the stale-state refresh as `340caba`; guarded fleet-sync advanced
all six remote Linux checkouts, and Aist, riken, and Home advanced cleanly.
Aist's reapply then planned the expected pull, refreshed agreement at final sync
transaction `20260721T084828Z-59527`, and passed strict profile, effective SSH
resolution, clean/current public and private Git, and a ready Mac doctor. Office
later recovered clean at `322fe1f`, advanced directly to `340caba`, and passed
live layout apply, rollback, and reapply at final transaction
`20260721T085251Z-186`. Its private planner still stops at the previously proven
three-way non-shared divergence; its Mac doctor has exactly that one failure,
matching the deliberate retained state on riken and Home.

PR #178 published the final rollout checkpoint as `c17c68a`; guarded fleet-sync
and clean Mac fast-forwards advanced every public checkout. An independent
eleven-target check confirmed clean/current public Git, zero selected root
stanzas, the exact global-context trailer, canonical regular mode-0600
fragments, plan-current layout, and effective GitHub hostname/user plus default
keepalive resolution. Aist's doctor is ready. Office, riken, and Home each have
exactly one doctor failure: the deliberately retained private SSH divergence.
During that final check, Home's known 99-byte thin-profile tail had recurred;
the existing explicit merge route restored it with rollback/reapply and final
transaction `20260721T085840Z-56943`, leaving only the expected SSH divergence.

**Execution sequence:**

1. Revalidate Aist through both routes. Extract its existing root `Host github`
   and `Host *` blocks as the canonical source only if each is an unambiguous
   top-level single-pattern stanza, the root is a bounded safe regular file,
   and the extracted two-block candidate contains no credential material or
   external include and passes isolated OpenSSH grammar. Never print the bytes
   or a content identity.
2. Implement a cross-platform transactional layout plan that parses complete
   top-level SSH stanzas, refuses `Match`/multi-pattern/duplicate ambiguity,
   first writes the canonical two-block candidate to a mode-0600 regular
   `~/.ssh/config.d/harness.conf`, then removes only the two selected root
   blocks and installs exactly one terminal `Match all` followed by
   `Include ~/.ssh/config.d/harness.conf`. Preserve every other root byte and
   its existing safe mode.
3. Update the repository canonical source to Aist's verified public-safe exact
   bytes and use transactional copies rather than symlinks on all systems.
   Continue to prohibit path, account, network, or credential-derived values
   in public Git. Extend
   the Mac private-payload validator to allow only that exact global-context
   terminal trailer while continuing to reject every other `Include`, `Match
   exec`, credential-like material, unsafe metadata, and external reads during
   validation.
4. Add synthetic Linux/Darwin tests for all observed combinations, ambiguous
   refusal, byte preservation, idempotence, injected failure, exact
   unchanged-only rollback/reapply, private divergence convergence, and
   privacy-negative output. Run focused tests, ShellCheck, `git diff --check`,
   public audit, and all 57 phase-one suites.
5. Publish through protected CI, merge without force, then guarded-sync only
   clean Linux checkouts and update each clean Mac public checkout.
6. On Aist, copy the canonical root blocks into the fragment before removing
   them from the live root, then transform the private payload through the
   reviewed transaction so the layout migration resolves rather than guesses
   the current divergence. Publish the forward-only private commit, exercise
   exact local rollback, and reapply. Stop if non-shared bytes remain unequal.
7. Sequentially pull/apply the private root plus regular fragment copy on Office,
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
one terminal global-context managed-include trailer; eleven regular fragments
contain the exact Aist-root canonical blocks; all files retain safe
ownership/types/modes; OpenSSH grammar and effective resolution pass; all four
Macs report SSH agreement and ready doctors; all Git checkouts are
clean/current; rollback/reapply evidence exists per changed host; no credential,
private value, fragment hash, or raw payload enters public output or Git.

**Decision register:** D1 (settled) covers all eleven managed systems and
excludes proxy aliases. D2 (settled) copies Aist's complete root GitHub/`Host
*` blocks intact before removing those blocks everywhere, even if other
systems' options differ. D3 (settled by owner correction) uses regular fragment
copies on all systems rather than the current Linux symlinks. D4 (settled by
evidence) tracks the canonical bytes publicly because the extracted option set
and comments pass the existing non-secret boundary.

D5 (settled by owner, option 1) replaces the legacy shared root `ssh_config`
with one mode-0600 tracked payload at `ssh/LOGICAL_ID.conf` for every declared
Mac. Public engine schema 3 selects only the current host's payload. During the
ordered migration, schema-1 companions may contain the legacy payload plus a
partial set of per-host payloads so all four Macs can receive the new engine
before private history changes. Schema 3 requires an exact bijection between
`hosts/*.conf` and `ssh/*.conf`, prohibits the legacy root payload and the old
Bash/tmux bundle, and keeps every live root unchanged. Migration is split into
two explicit forward-only operations: `--migrate-per-host` creates only the
selected host's previously absent payload from its strictly validated live
root; after all four exist, `--finalize-per-host` removes only the legacy root
payload and raises `minimum_engine_schema` to 3. This split prevents one host
from implicitly finalizing repository-wide compatibility. Ordinary sync
compares and commits only the selected payload, so unrelated-host commits
refresh Git state instead of appearing as SSH divergence.

**Per-Mac execution checkpoint:** branch
`task/t-291-per-mac-private-ssh` is based on clean public main `2d39f82`.
The engine now validates safe per-host payload directories, schema-1 transition
sets, schema-3 exact host/payload bijection, and schema-3 long-gap targets.
SSH sync selects the current host's path before the legacy fallback; unrelated
host commits become safe state refreshes, while ordinary local/remote/retry
paths commit only the selected file. Explicit migration and finalization are
idempotent and recover cleanly from injected push failures. Synthetic tests
prove transition/final schemas, unsafe and incomplete refusal, per-host
publication/pull, unrelated-host advances, live-byte preservation, separate
finalization, forward-only retry, and privacy-negative output. All thirteen
Mac-focused suites, the public-audit test and live public audit, shell syntax,
targeted ShellCheck, and `git diff --check` pass. No live or private repository
was touched. Clean commit `daa05b2` also passes the complete
`tests/test-phase1.sh`; all 58 focused suites passed and native MPI was the
declared environment-only skip. Only after every Mac public checkout has
engine 3 may Aist,
Office, riken, and Home sequentially publish their own previously absent
payload. Finalization requires all four exact host/payload pairs and a clean
private checkout. Private Git remains forward-only; rollback restores only
unchanged live/state preimages, while reapply catches up to published history.

PR #180 passed protected portable CI and squash-merged the schema-3 engine as
`2de6a49`; its exact implementation branch is absent locally and remotely.
Rollout continuation branch `task/t-291-per-mac-private-rollout` starts from
that clean main. The next gate is public-only engine catch-up and schema-1
compatibility validation on all four Macs; no per-host private payload may be
published until all four pass.

Aist and riken fetched both origins with validated current-user agent sockets,
accepted public-only long-gap updater transactions with package actions none,
and now have clean public `2de6a49` plus valid schema-1 private profiles through
both route aliases. Their update transactions are Aist
`20260721T093205Z-78916` and riken `20260721T093235Z-54332`. Office/Office2 and
Home/Home2 were both-route unavailable during this checkpoint, while the
five-minute failover monitor remained running. No per-host payload has been
created and the fleet-wide engine gate remains closed.

The final handoff probe found riken/riken2 still ready but Aist/Aist2 had since
dropped together; its already verified engine update is durable and must not be
repeated merely because transport changed. Office/Office2 and Home/Home2 remain
down together. The monitor is running, but no peer-side reconnect is possible
for a pair with both routes down. Managed Linux local, ri, al, rc, and t4 were
ready; ab, ab2, and transport-only abci_login were down while transport-only
alps_login was ready. These route results are connectivity state, not evidence
of repository drift.

Office and Home then recovered through both aliases and accepted the same
public-only engine catch-up with package actions none. Their transactions are
Office `20260721T094521Z-20014` and Home `20260721T094544Z-70559`; both aliases
on each host prove clean public `2de6a49` and valid schema-1 private profiles.
riken/riken2 reconfirmed the same state. Aist's already accepted engine-3 state
remains durable, but Aist/Aist2 dropped together again before a fresh probe.
The four-engine prerequisite is therefore satisfied by verified transactions;
the isolated migration gate is open for reachable Macs, but finalization stays
closed until Aist is reachable and its own payload exists.

Office, riken, and Home each planned and published only their previously absent
per-host payload, retained the legacy root, and left the exact live SSH root
unchanged. Every host passed selected-path profile/agreement and clean/current
private Git checks, then rolled back its first local sync transaction exactly
and reapplied forward. Final transactions are Office
`20260721T094814Z-23169`, riken `20260721T094855Z-58479`, and Home
`20260721T094926Z-73862`. The private transition now has three of four payloads;
Aist/Aist2 remain down together. No finalization, legacy-root removal, or
minimum-engine change has occurred.

**External-commit handoff:** the owner is repairing Aist connectivity in a
separate commit and explicitly closed this rollout work unit so the external
commit can land independently. Do not amend, absorb, or duplicate that change,
and do not attempt more Aist recovery from this task. The rollout branch is to
be merged as a checkpoint and removed, leaving clean public `main`. T-291 is
not technically complete: the forward-only private transition safely remains
at three of four payloads with the legacy root and minimum engine 1 intact.

**Next executable action:** wait for the owner's separate Aist repair commit and
push. On a later explicit resume, fetch first, reconstruct and validate that
external commit without rewriting it, then revalidate Aist's completed engine
update, migrate its absent payload with exact rollback/reapply, verify the
four-payload transition, and only then run the separate finalizer and refresh
all four selected states. Do not finalize while Aist remains unreachable or
absent.

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
