# Personal harness task board

This is the authoritative resume point for the portable Codex and Claude
harness. Keep only current state, active decisions and gates, exact next
actions, and compact completion pointers here. Git history and the linked audit
documents retain completed execution detail.

Next free ID: T-315.

## Current state

- Public `main`, Local, and all eleven remote managed checkouts are
  clean/current. T-306's context-refresh policy is current; all four private
  Mac SSH payloads remain current.
- The README now leads with owner-facing startup and daily operations, carries
  a pointer to the canonical fleet reference, and separates logical nodes from
  transport-only aliases and the service-only web endpoint.
- `docs/fleet-inventory.md` is the sole node table and carries a verified user
  guide for every Linux-facing entry; the private Hinadori link is identified
  as private and no private guide content is stored here.
- Managed Linux nodes are local, ab, ab2, ri, al, rc, t4, and abq; abq2 is a
  second route to the same ABQ node. Managed Macs are aist, home, office, and
  riken, each with two independent reverse routes. `abci_login` and
  `alps_login` are transports, not health-report targets; retired si remains
  out of scope.
- All managed systems use the canonical terminal SSH include and byte-identical
  fragment. Shared defaults use a 30-second connection timeout,
  collision-resistant `%C` multiplex paths with indefinite persistence, global
  agent forwarding and trusted X11 with explicit exclusions, and alphabetic
  directives. The four Mac private profiles use schema 3 with one distinct
  per-host SSH payload and no legacy root payload.
- Each Mac runs two current-user launchd tunnel supervisors and a 30-second
  local watchdog. Local keeps their four restricted authorizations in the
  root-owned secondary file
  `/etc/ssh/harness_tunnel_authorized_keys`, selected by
  `/etc/ssh/sshd_config.d/99-harness-tunnel-auth.conf`. The five-minute
  `harness-connection-monitor` remains active.
- T-296 acceptance passed primary, secondary, and simultaneous-loss drills on
  all four Macs with `managed=1 external=0`. Power loss, loss of both upstream
  networks, Local/sshd failure, and root-policy damage remain external bounds.
- T-297 left zero orphaned Mac muxes, legacy keepalive agents, SSH/helper
  staging candidates, or dead recovery panes. Expected managed tunnels,
  watchdog state, active Codex sessions, live agent sockets, and rollback
  transaction evidence remain.
- The Codex 0.145.0 NFS arg0 launcher wrapper and lock-aware guarded
  housekeeping remain installed on Local's standalone release. Its rollback is
  `harness codex-arg0-wrapper --rollback`; an official Codex upgrade requires
  fresh validation before reinstalling the version-scoped wrapper.
- Codex and Claude now use only project-scoped policy, permission settings,
  rules, and 15 skills when started from `~/harness`. All 12 systems retain
  only the two global launch sentinels and the Codex launcher; schema-2 doctor,
  repository convergence, external onboarding preflight, and all four resumed
  Mac TUIs passed at `309de20`. See
  `docs/audits/t304-project-scoped-agent-config-2026-07-24.md`.
- Codex's native startup update offer is disabled in the project because Linux
  releases are harness-managed. All seven remote Linux nodes use verified
  managed Codex 0.145.0; Local retains its official standalone 0.145.0 plus
  the T-294 NFS wrapper. Tree evidence now explicitly uses deterministic GNU
  tar format. See `docs/plans/t305-codex-managed-update.md`.
- Remote Codex communication separates visible best-effort TUI injection from
  acceptance-critical same-channel requests. All four Macs passed new bounded
  requests whose replies returned on the originating Local-to-Mac SSH
  connection without reverse `login`, agent forwarding, pane reads, checkout
  changes, or private residue. See
  `docs/plans/t307-remote-agent-communication.md`.
- Exactly one future native weekly primary backup job exists on each managed
  Linux node. First runs passed on 2026-07-19 and keep-all remains effective.
- Container and package work are requirement-gated guardrails, not pending
  tasks. Install container capability only for a specific workload. Perform no
  blanket package upgrade, cleanup, autoremove, cask, service, tap, or
  unmanaged-dependent mutation; require current freshness evidence and an
  explicit package selection.
- Closed non-goals remain broad plugin/connector/account changes,
  administrator settings, automatic publication, background login mutation,
  active-session reload, and guessing lost unknown configuration. T-314
  narrowly reopens Local's already-installed Slack connector lifecycle after
  exact owner authorization; it does not authorize credentials or other
  connectors.
- Project safety and collaboration rules in root `AGENTS.md` remain
  authoritative. `.codex/AGENTS.md` is only the out-of-project launch
  sentinel. Never inspect credentials or use raw recursive/bulk deletion.
- Whenever owner input or approval is requested, or a task completes, report a
  fresh compact health snapshot for every managed Linux node and all four Mac
  route pairs. Count abq as Linux and mark it ready only when both abq and abq2
  routes pass; do not include that pair in the Mac total. Omit `abci_login` and
  `alps_login` unless a task targets those transports.

## Next resume checkpoint

1. Resume T-314 at Decision D-003. The exact first `SIGTERM` was already sent;
   never replay it. Select whether one detached exact-identity helper may send
   a second `SIGTERM` and perform native start after forced exit. A separate
   `go` is required after selection.
2. Complete the four deferred T-311 Mac firewall helpers only when the owner
   can authenticate locally, then validate both routes and exact-unlink each
   helper. Resolve the separate Codex user-config policy choice afterward.
3. Continue T-196 only at its exact time/identity gates: AB and AB2 are now
   2/8 with next-week successors waiting; retry RI accounting ID `7242`
   without touching successor `10386`, and inspect AL ID `4238363` only after
   its later eligibility.

## Active tasks

### T-314 — Recover Local Slack connector availability

**Phase:** interviewing Decision D-003.

Restore read-only Slack tools to Local Codex after the installed and enabled
Slack plugin initially listed `RioYokotaLab` and searched `#swallow`, then
later returned `unsupported call` before reaching Slack. T4 has no Slack
plugin installed, so it was not the source of the earlier successful access.
Local's two supervised TUIs started after the current task began, but its
separate remote-control app server has remained live since 2026-07-22 and
predates the plugin enablement recorded by Swallow.

The exact plugin mention still failed, while native doctor reports healthy
Codex auth, network, websocket, state, installation, and persistent app-server
state. The resilience launcher manages only foreground TUI restart/resume and
Linux worker limits; it neither creates nor refreshes the app server. Do not
couple every TUI launch to a remote-control restart.

The frozen recovery, rollback, two-turn Slack acceptance test, and decision
register are in `docs/plans/t314-local-slack-connector-recovery.md`. No service,
setting, connector authorization, pairing, TUI, or remote node has changed.

**Decision D-001 result:** the owner selected the recommended one-time native
`codex remote-control stop` / `start` recovery and separately said `go`.
Harness `124822d` and Swallow `5e7baf2` durably captured the pre-signal state.
The exact native stop was then invoked once and exited `1` with
`app server is running but is not managed by codex app-server daemon`. Native
start was not invoked. PID `3676694`, both supervisors, and both TUI children
remain live and unchanged, so the failed command is not safe to replay.

Value-free state inspection found no managed `app-server.pid`. Official Codex
0.145.0 source confirms that native stop deliberately refuses a socket-serving
process without a managed backend. The managed implementation matches PID and
start time, sends `SIGTERM`, waits 60 seconds, and only then permits forced
termination. The revised plan proposes one current-user, exact-start-time,
exact-executable, exact-argv checked `SIGTERM`, no `SIGKILL`, followed by
native start only after confirmed exit.

**Decision D-002:** the owner selected the recommended guarded one-time
`SIGTERM` and then gave the separately required explicit `go`. No signal or
start preceded that authorization checkpoint; Harness and Swallow pushed it
before execution. If interrupted, resume from this ledger and reconcile live
state before acting; never replay the failed native stop or an ambiguous
signal/start.

**D-002 execution result:** every frozen identity check passed and one
`SIGTERM` was sent to PID `3676694`. The same process remained live for the
full 60-second grace window, so the guard exited `75`; no second signal,
`SIGKILL`, or native start occurred. Redacted doctor then remained `ok`, with
the old unmanaged 0.145.0 server and both supervised TUIs live.

The installed-version Codex test confirms the first `SIGTERM` waits for a
running app-server turn, while a second forces exit. That supported a
lower-risk no-signal continuation: wait for the exact old identity to
disappear after the turn yielded, then run native start and verify the managed
PID record, redacted doctor, and both TUIs. Its mode-0600 handoff was
`/tmp/t314-post-turn-result.fE4BY3`; the prepared native-start and doctor logs
were `/tmp/t314-remote-control-start.cMgpXI` and
`/tmp/t314-post-turn-doctor.qJnJvK`.

The first helper launch failed closed before mutation because it contained UID
`1000` instead of Local's actual `5035`. The corrected helper passed `bash -n`
and `shellcheck`, exact-unlinked itself, and armed as PID `2562922` at
2026-07-27 03:18:54 JST. It sent no signal and waited for the unchanged old
PID/start identity to disappear after the turn yielded.

**Post-turn result:** the corrected helper waited five minutes after the prior
turn yielded and failed closed at `waiting_for_graceful_exit` at 03:25:01 JST.
It sent no signal and did not run native start. At 03:56 JST, the original
server identity was still live, the managed PID file remained absent, both
TUIs were unchanged, and filtered redacted doctor remained `ok`.

Installed 0.145.0 source confirms a second forceable signal sets forced
shutdown, exits even with running assistant turns, and skips orderly
connection/task/thread cleanup; its exact test expects a second `SIGTERM` to
exit successfully within two seconds. This may interrupt in-flight app-server
turns even though the two TUI OS processes are preserved.

**Decision D-003:** open. The recommended bounded path is to arm a detached
exact-identity helper before signaling; it sends one second `SIGTERM`, never
`SIGKILL`, waits up to ten seconds for the exact old identity to disappear,
then invokes native managed start once and verifies the managed PID, redacted
doctor, and both TUIs. If selected, checkpoint the choice and obtain a
separate explicit `go`. Until then, do not signal or start anything.

### T-313 — Enable repository auto-merge and limit login-node Codex threads

**Phase:** complete.

Enable only the repository-level auto-merge capability on Harness, Students,
Swallow, and Website; add and fleet-publish a Linux-only Harness Codex launcher
with eight Rayon and Tokio workers; expose it through the shared interactive
shell policy; then gracefully restart Local and the four managed Mac TUIs under
the resilient supervisor without restarting remote-control app servers.

Read-only GitHub checks prove auto-merge is currently disabled on all four
repositories. The exact limited version command passes on Local and all seven
remote Linux nodes across both supported architectures, and the native binary
contains both runtime controls. Local is already supervised; each Mac retains
one detached unsupervised TUI and a separate live app server. No setting,
tracked implementation, shell environment, or process has changed.

The complete plan, safety gates, rollback, acceptance criteria, and confirmed
decision D-001 are in
`docs/plans/t313-codex-login-automerge.md`. Implement the focused-tested
launcher next. The GitHub API enabled only `allow_auto_merge` on all four
repositories and exact readback is true; no pull request was opted in. Publish
and sync, then restart detected TUIs with Local last.

**LIFO gate resolved 2026-07-26:** the first focused run passed the new
login-node launcher suite, then the existing resilience suite rejected removal
of the explicit underlying `harness codex-resilient --run` command from the
README. No target or process changed. The README now presents both the standard
`codex` alias and its transparent native Harness command; rerun all affected
focused gates.

**LIFO gate resolved 2026-07-26:** the first complete four-worker suite passed
all changed coverage and every independent suite except tmux and terminfo.
Those two fixtures intentionally require a clean committed Harness checkout
before their synthetic apply paths and rejected the coherent uncommitted T-313
increment. No live target changed. Review and commit only this increment, then
rerun the authoritative complete suite from the clean revision. Commit
`2b4a437` then passed all 75 focused suites, guarded-delete coverage, and every
phase-one integration gate. Publish through protected CI next.

**LIFO rollout gate resolved 2026-07-26:** protected PR #332 passed and merged as
`12054b9`, but advancing Local `main` replaced the currently executing
resilience supervisor script. NFS retained its old inode as one untracked
`.nfs` placeholder held only by the exact current supervisor PID, so guarded
fleet-sync refused the dirty source before contacting any node. Preserve the
live placeholder. Run the reviewed sync from a clean detached worktree at the
same exact merge revision, restart Local last, and require the placeholder to
disappear naturally when the old supervisor exits. The exact clean full-clone
sync later advanced all eleven remotes successfully with absent artifacts.

**LIFO rollout sub-gate resolved 2026-07-26:** the clean detached rollout
worktree was created at exact merge `12054b9`, but fleet-sync requires a full
Git checkout and rejected its normal `.git` pointer before contacting any
node. Preserve that clean worktree for guarded cleanup. Create a disposable
full local clone with a real `.git` directory at the same revision, run the
unchanged plan/apply there, and guarded-delete both rollout checkouts after
Local restart. Full clone `/tmp/t313-rollout-clone.atxL0w` passed plan/apply;
both rollout checkouts remain for the recorded guarded cleanup.

**LIFO validation gate resolved 2026-07-26:** the clean full-clone sync advanced
all eleven remotes successfully, but the first seven-node Linux readback used
an incorrectly escaped exact alias comparison. Every invocation stopped after
printing the planned native command, making the aggregate look like a launcher
failure. An isolated direct check proves `harness codex-login --version` exits
zero with Codex 0.145.0, and direct alias output is exact. Repeat the value-free
readback with a literal fixed-string comparison; no session or configuration
changed. The corrected readback passed launcher, alias, and version checks on
all seven remote Linux targets.

**LIFO restart gate resolved 2026-07-26:** T4's direct TUI stopped gracefully and
the published supervisor reached running state, but the first helper treated
its session-owned background Codex daemons as a persistent remote-control app
server. Their expected PID change caused the prepared rollback to restore the
direct TUI; the session is live and supervisor status is safely stale. Require
exact app-server identity only for Local and Macs, where remote control is in
scope, then retry T4 once through the same graceful transition. The narrowed
retry passed and T4 now reports managed running supervisor state.

**LIFO Mac restart gate resolved 2026-07-26:** Aist's direct TUI also stopped
gracefully and the supervisor reached running state, but Codex automatically
replaced the remote-control app-server PID as part of the TUI lifecycle even
though the helper never addressed that process. The prepared rollback restored
the direct TUI and remote control remains present. Preserve pairing and require
a ready remote-control server after restart rather than an impossible
same-process identity, then retry Aist once before continuing.

The first narrowed retry reached preflight but a single `Ctrl-C` only canceled
the just-submitted context-refresh turn; it did not exit the TUI before the
bounded wait, so rollback again restored a direct client. Submit Codex's
explicit `/quit` after the cancel signal, with separate paste-settle and Enter,
then require the old process to exit before respawn. Never inspect the pane.
That exact method passed on Aist, Home, Office, and Riken; all four report
managed running supervisor state, ready remote control, and healthy dual
routes.

**Next action before controller interruption:** Local alone remains on its old
running supervisor and therefore holds the expected `.nfs` placeholder. Commit
and push this checkpoint, then run the reviewed graceful helper against the
attached Local `harness` pane. On resume, do not replay the owner request:
verify Local supervisor status and eight-thread child path, require the
placeholder to be absent, guarded-delete the exact rollout clone/worktree and
helper, publish a compact closeout, and run canonical fleet health.

The first detached Local handoff failed before sending any signal because the
session attachment count changed from one to zero during its three-second
delay. The old supervisor, message, and placeholder remain unchanged. The
owner authorized the restart in either attachment state; retain strict detached
checks for remote targets, but let the explicit Local override accept either
state and retry once.

**LIFO validation gate resolved 2026-07-26:** the first post-restart remote
supervisor query appended its positional argument outside the intended remote
shell script, so Local passed but every remote command returned usage status 2.
No target changed. The corrected native SSH commands passed on T4, Aist, Home,
Office, and Riken.

**Final validation 2026-07-26:** Local restarted gracefully under the published
supervisor, its remote-control server remained ready, and the old supervisor's
NFS placeholder disappeared naturally. Local, T4, Aist, Home, Office, and
Riken all report running managed supervisors. The Linux-only launcher contract,
syntax, ShellCheck, and focused routing suite pass. All eleven remote checkouts
are clean `main` at `12054b9`, aligned with `origin/main`, with one worktree
and zero stashes. Exact GitHub readback keeps `allow_auto_merge=true` on
Harness, Students, Swallow, and Website, with no pull request opted in by this
task. Guarded deletion removed only the 918-entry rollout clone and 874-entry
rollout worktree; protected anchors were unchanged, stale Git registration was
pruned, and all helper, log, message, and manifest residue is absent. Canonical
health reports `Fleet: Linux pass; Macs pass.` Protected closeout publication
and synchronization carry only this durable evidence.

### T-311 — Harden the fleet and independent project repositories

**Phase:** nightly safe work complete; deferred owner/admin gates remain.

Audit and harden all managed Linux and Mac nodes plus `harness`, `students`,
`swallow`, and `website`, while each repository owns its own task, branch,
tests, publication route, and handoff. Work ends at 2026-07-26 05:00 JST.
Pre-existing work is never stashed; new hardening work uses isolated
worktrees. On any new ambiguity or failed gate, pause the interrupted change,
preserve safe evidence, stash only explicitly named task-owned WIP when a
coherent commit is impossible, and push the issue onto that repository's TODO
as a LIFO item. Resolve the new top item when safe, record the pop, resume the
interrupted task, and keep all repositories progressing independently. If the
top item requires unavailable owner or administrator action, leave it deferred,
continue the next highest safe independent item in that same repository, and
never cross it for dependent work.

**LIFO gate resolved 2026-07-26:** a final read-only fleet-sync check supplied
the same exact commit as both source and target. The command rejected the
invalid no-op locally before contacting any node. Use direct exact
revision/status/artifact checks for the final aligned-fleet readback; do not
bypass the transaction contract or invent a synchronization change.

**Final validation checkpoint 2026-07-26:** protected PRs #323–#325 passed and
merged through `491475eef2eb576765c5b98858429b47cfeffe85`; guarded sync advanced
all 11 clean remote checkouts after each control-plane change with no transfer
residue. Harness, Students, Swallow, and Website pass the value-free repository
audit; each has one active ruleset, read-only/non-approving Actions defaults,
and zero open Dependabot alerts. Native secret scanning passes for Harness and
Website; Students and Swallow retain the approved pinned CI fallback because
their private repositories do not expose that entitlement. All 12 systems
report Codex 0.145.0 and Claude Code 2.1.220. Routine arg0 cleanup guarded-
deleted one eligible expected directory per Mac, preserved every live lock,
and left zero eligible/unexpected state. All four Mac doctors remain ready
with only the two expected firewall/stealth warnings; their identical reviewed
helpers remain mode 0700 and unchanged. The installed canonical health command
reports `Fleet: Linux pass; Macs pass.` Four post-sync Mac context refreshes
were submitted exactly once.

**LIFO gate resolved 2026-07-26:** the first closeout publication command
fetched successfully but then attempted to rebase while the coherent ledger
edit was still unstaged. Git refused before commit or publication. The remote
base was unchanged; record this gate in the same edit, commit locally, then
rebase the clean branch before its explicit push.

**LIFO gate resolved 2026-07-26:** the RI accounting retry used ordinary SSH
and emitted `X11 forwarding request failed` before the scheduler error.
Effective-policy readback proves every Linux target intentionally retains
`ForwardX11 yes`, while all Mac reverse aliases retain the owner-selected
`ForwardX11 no`; no configuration drift exists. Use `ssh -x` for value-free
noninteractive probes that do not need X11, without changing the interactive
Linux default.

**LIFO gate resolved 2026-07-26:** the first PR #323 fleet-sync plan used an
incorrect expanded target hash and failed locally before contacting any node.
The exact Git-resolved 40-character revision passed plan/apply and advanced all
11 clean managed remotes from `70aefb45b8a8c45f7977086ae8bcdffe9130d200`
to `63ae6fdbde7aa2c657102e5897fc799c79e6f892`; every transfer artifact is
absent.

**LIFO gate resolved 2026-07-26:** the first post-rollout AL validation command
expanded an unescaped remote `awk` field under `set -u` and stopped before
invoking Harness. The corrected value-free sequence passed: wrapper doctor is
ready, Codex remains 0.145.0, the managed tree reports `KEEP`, process count
remained zero, and housekeeping stayed
`live=0 eligible=0 young=0 unexpected=0` before and after the agent plan.

**LIFO gate resolved 2026-07-26:** the first complete portable run after the
watchdog race fix passed the changed supervisor suite and every other focused
suite except tmux and terminfo, which intentionally reject a dirty checkout.
The coherent three-file increment was still uncommitted. No live or external
state changed; commit the increment and rerun the authoritative full gate from
that clean revision.

**LIFO gate resolved 2026-07-26:** protected PR #323 run `30167537954` passed
the changed managed-agent suite and every other focused suite, but the
unchanged watchdog signal fixture again retained its recovery lock after the
test signaled the watchdog. The recovery supervisor acquired its lock before
installing the signal/exit trap, leaving a narrow crash window that the
lock-driven fixture can reach under hosted-runner scheduling. Install cleanup
traps before lock acquisition for both pair recovery and single-route kick,
exercise a deterministic post-lock delay, retain the exact
signal/no-child/no-lock assertions, run concurrent focused and full portable
validation, then publish the correction on the same PR before resuming the AL
pilot. Eight concurrent focused runs and the full four-worker portable suite
passed; protected run `30170137249` passed and PR #323 merged as
`63ae6fdbde7aa2c657102e5897fc799c79e6f892`.

**LIFO gate resolved 2026-07-26:** AL's managed wrapper installed successfully,
doctor passed, Codex stayed at 0.145.0 with process count unchanged, and the
managed package digest reported `KEEP`; however, that agent plan invoked the
package launcher directly for its version check and left one young expected
arg0 directory, bypassing the stable wrapper. Preserve the young state. When a
current managed wrapper has already passed doctor, run only the version probe
through the stable wrapper while continuing to hash the original package tree;
cover zero-residue wrapped planning and repeat AL validation after protected
publication. PR #323 now routes the version probe through the validated stable
wrapper; the post-sync AL plan retained `KEEP` and created no arg0 residue.

**LIFO gate resolved 2026-07-26:** publishing the declared-storage-link fix to
the already-merged PR #321 head name was rejected non-fast-forward because the
remote task branch retains its pre-rebase history. Nothing changed remotely
and force-push is prohibited. Rename the clean local branch, push the same
commit to a fresh explicit ref, open a new protected PR, then pop this
publication-only gate. Fresh PR #322 passed protected CI and merged as
`70aefb45b8a8c45f7977086ae8bcdffe9130d200`.

**LIFO gate resolved 2026-07-26:** after PR #321, fleet sync, and a passing AL
plan, the first apply failed closed at `managed wrapper parent is unsafe`
before switching the stable launcher. Inspect only type/owner/mode/link
metadata for `~/.local` and `~/.local/opt`, account for AL's NFS path topology
without accepting a symlinked leaf parent, verify whether any task-owned empty
directories were created, and repeat plan/apply only after focused/protected
coverage. No Codex process was stopped. PR #322 accepts only the exact
fleet-declared current-user-owned storage link while keeping `.local/opt`
real and owned; the AL apply and doctor passed.

**LIFO gate resolved 2026-07-26:** protected PR #321 run `30166634389` failed in
the unchanged watchdog-signal cleanup fixture after its five-second
post-termination poll retained a recovery child or lock; every other suite,
including the changed NFS-alias wrapper fixture, passed. This is the second
protected occurrence after PR #317. The production bind probe has an
eight-second connection timeout while the fixture allowed only five seconds
for the trap chain. Its poll ceiling now matches that bound plus cleanup margin
without adding a fixed wait or weakening the exact no-child/no-lock assertion.
Eight concurrent focused runs, a normal full suite, a matched four-worker
portable suite, and protected rerun `30166987349` pass.

**LIFO gate resolved 2026-07-26:** the first NFS-alias fixture ShellCheck stopped
before test execution because a multiline `[` comparison omitted its shell
continuation. The corrected fixture passes syntax, ShellCheck, and the complete
managed/standalone wrapper transaction suite. No production or external state
changed.

**LIFO gate resolved 2026-07-26:** the first AL wrapper plan after PR #320 and
fleet sync failed closed before mutation. AL's stable link text is the exact
declared absolute managed path under `/users/ryokota`, but `realpath` resolves
the NFS file through `/capstor/...`; classifying the canonical spelling
therefore rejects a valid managed launcher. The ordinary managed-agent plan
still reports `KEEP`, and no process, link, package, or wrapper state changed.
Classify managed and managed-wrapper targets from the exact absolute stable-link
text, retain file/owner/hash checks through the resolved object, keep
standalone current-link resolution unchanged, add an NFS-alias fixture, and
repeat the AL pilot. PR #321 implemented that contract, and the later AL
wrapper plan/apply/doctor passed without changing a Codex process.

**LIFO gate resolved 2026-07-26:** pre-rollout review showed that the first
managed-layout implementation would rename and replace files inside the
harness-managed npm tree, invalidating the installer transaction's recorded
whole-tree digest even though wrapper-local tests pass. AL's current
`harness agent --host al --name codex --plan` still reports the unmodified
managed tree as `KEEP`. Nothing has been applied. Redesign only the managed
path to keep that tree byte-identical and install a separate version-scoped
wrapper target behind the stable symlink; prove agent `KEEP` before and after
the wrapper transaction, while preserving standalone behavior. PR #320
implemented the separate wrapper target; matched tests and the AL pilot prove
the package digest remains `KEEP`.

**LIFO gate resolved 2026-07-26:** the first full suite ran with the coherent
managed-wrapper increment still uncommitted. The tmux and terminfo fixtures
correctly refused their synthetic apply paths because they require a clean
committed checkout; every other focused suite, including the changed wrapper
suite, passed. The intended increment was committed alone, and the complete
eight-worker phase-one suite then passed from that clean commit.

**LIFO gate resolved 2026-07-26:** after the semver fix, the managed invocation
fixture expected postflight cleanup without creating the pre-existing arg0 root
that activates wrapper baseline tracking. AL has that root, and the standalone
fixture already models it. The managed fixture now establishes the same private
root; both success and preserved-exit-status failure paths clean their observed
residue, and focused syntax, ShellCheck, and transaction tests pass. No
production or external state changed.

**LIFO gate resolved 2026-07-26:** the first managed-layout focused test failed
before mutation because `normalized_semver` is private to `harness-agent` and
was not available to the wrapper command. The wrapper now carries the same
strict local normalized-semver predicate; syntax, ShellCheck, and both layout
transactions pass.

**LIFO gate resolved 2026-07-26:** all 12 systems run Codex 0.145.0, but AL alone
emits the stale-arg0 cleanup warning. Its lock-aware housekeeping plan reports
`live=0 eligible=0 young=2 unexpected=0`, so nothing is currently safe to
remove. The wrapper doctor fails closed because AL's harness-managed npm
launcher lives under `~/.local/opt/agents/codex/0.145.0/linux-aarch64/`, while
the version-scoped wrapper currently recognizes only Local's official
standalone release tree. Extend the wrapper transaction and tests to accept
only the exact managed npm layout without weakening standalone validation;
publish and fleet-sync that increment, then pilot it on AL without stopping
Codex processes. Never remove young arg0 state directly. PRs #320–#323
completed the managed layout, NFS path, storage-link, and stable-probe
increments; normal wrapper preflight removed the expected completed residue,
and final AL housekeeping reports all four counts at zero.

**LIFO gate resolved 2026-07-26:** Harness PR #317 passed the full four-worker
suite locally but protected run `30163867667` failed in the unrelated Mac
tunnel-watchdog signal fixture when its five-second cleanup poll expired.
Four concurrent isolated repetitions then passed, including child/lock cleanup,
and the unchanged protected rerun `30164109873` passed every suite. This was a
timing-only fixture failure; no production or test relaxation was needed.
Swallow's independent stack continued throughout.

**LIFO gate resolved 2026-07-26:** one parallel PR-status query used a
misspelled local worktree path and failed before invoking the GitHub CLI. The
corrected bounded queries immediately succeeded; no repository or external
state changed.

**LIFO gate resolved 2026-07-26:** the first focused assertion for the
same-repository continuation contract searched one phrase across a Markdown
line break and failed without changing external state. The test now matches
the stable unbroken clause while retaining the exact behavioral requirement.

**LIFO gate active 2026-07-26:** value-free `agent-config --doctor` reports an
unmanaged `~/.codex/config.toml` collision only on nodes with active Codex
sessions: Local, T4, Aist, Home, Office, and Riken. AB, AB2, RI, AL, RC, and
ABQ retain the intended global-absence state. The current official Codex manual
documents this path as the shared CLI/app user layer and says provider,
notification, telemetry, profile, and some plugin settings cannot live in
project config. Do not inspect, delete, or rewrite these live product files or
stop sessions. At owner review, choose between revising T-304 to permit a
minimal product-owned user layer or removing the files after sessions exit,
knowing Codex may recreate them. Continue safe Harness work below this policy
decision.

**LIFO gate resolved 2026-07-26:** a value-free SSH metadata audit found modes
0640 on AB/AB2 client configs, 0644 on AL's client config, and 0644 on RC plus
all four Macs' `authorized_keys`; every path is a current-user-owned,
single-link regular file. Only those eight modes were tightened to 0600.
Client parsing and doctor checks pass on AB, AB2, and AL; fresh RC
authentication and both independent inbound routes for every Mac pass. The
complete 12-system rerun reports `findings=0`, and all temporary helpers are
absent. No SSH contents or identity values were read, printed, copied, or
hashed.

**LIFO gate resolved 2026-07-26:** the first temporary SSH metadata helper
failed its ShellCheck warning gate on three bare-word assignments before any
audit ran. Quoted literal assignments passed syntax and ShellCheck; the helper
then ran value-free and was exact-unlinked from every remote after use.

**LIFO gate resolved 2026-07-26:** the known off/off Mac firewall and stealth
posture is not represented in `macos-inventory` or `macos-doctor`, so routine
readiness previously reported zero warnings while D-003 remained unresolved.
PR #318 added value-minimized five-setting facts, warning-only posture checks,
and parsing/malformed coverage; protected CI passed and guarded fleet sync
advanced all 11 remotes to `a9569f8`. Every Mac now reports exactly the expected
two disabled firewall/stealth warnings while signed built-in/downloaded access
passes and block-all remains disabled.

**LIFO gate resolved 2026-07-26:** the first passing firewall visibility
increment covered global and stealth state but omitted the signed built-in,
signed downloaded-app, and block-all settings that are part of D-003's access
preservation contract. The schema, doctor, enabled/disabled/unavailable/unknown
parsers, malformed-fact refusal, and warning tests now cover all five settings;
focused tests and a second full four-worker suite pass. No firewall state
changed.

**LIFO gate resolved 2026-07-26:** review of the deferred Mac helper found that
its loose parser treated query failure as off, it did not verify signed or
block-all policy, and it did not explicitly disable block-all before enabling
the firewall. None had been applied. All four mode-0700 helpers were
transactionally replaced with checksum
`f83690717bc2826af203336196d8ce73b26adc33939762bb325ed66de684d33b`;
strict plans prove the current off/off/on/on/off baseline and the target
on/on/on/on/off posture. Staging residue and the local helper are absent.

**LIFO gate resolved 2026-07-26:** Linux `harness doctor` reported
`codex_rules=not-installed` on every host even though T-304 intentionally
removed the user-global rule and retained it only as repository-scoped policy.
PR #317 now treats absence as the required project-scoped state and no longer
plans to recreate the prohibited global link. Protected CI passed; guarded
fleet sync advanced all 11 remote checkouts to `967dcf1`; and doctor/plan
readback passes the exact contract on Local, AB, AB2, RI, AL, RC, T4, and ABQ.

**LIFO gate resolved 2026-07-26:** the first fleet-sync plan used an abbreviated
new revision and failed closed before any node changed. The exact 40-character
revision passed plan/apply and every bundle artifact was absent afterward.

**LIFO gate resolved 2026-07-26:** the first sequential doctor-validation loop
stopped while entering T4 after six hosts had passed. Immediate isolated T4
doctor and plan checks both passed, as did the resumed T4/ABQ suffix; no target
state changed during the interrupted read-only loop.

**LIFO gate resolved 2026-07-26:** the new value-free hardening audit initially
reported zero findings on 11 systems but failed on AL because its system Python
predates `from __future__ import annotations`. PR #316 removed modern
annotation/runtime conveniences and added a Python 3.6 grammar/API contract;
protected CI passed and the merged command now completes on AL with
`findings=0`. No target state changed during the failed attempt.

**LIFO gate active 2026-07-26:** all four Mac firewall/stealth plans remain
off/off and `sudo -n` is unavailable. An identical reviewed, credential-free
`~/run_this.sh` is staged mode 0700 on Aist, Home, Office, and Riken; its
SHA-256 is `f83690717bc2826af203336196d8ce73b26adc33939762bb325ed66de684d33b`.
It strictly verifies all five settings, enables signed and built-in access,
disables block-all before the firewall, enables stealth mode, validates
on/on/on/on/off, and offers an explicit off/off/on/on/off rollback.
Administrator authentication is the only remaining gate; do not bypass it,
and exact-unlink each helper after successful execution and route validation.
Continue safe work in this repository and every other independent stack.

**LIFO gate resolved 2026-07-26:** Office had no running XQuartz process,
local X11 client, or TCP 6000 listener. Its XQuartz 2.8+ preference domain now
sets `nolisten_tcp=true`; the current listener count remains zero and the
preference takes effect on the next XQuartz start without interrupting work.

**LIFO gate resolved 2026-07-26:** corrected ABCI-Q smoke job `176517.qjcm`
was accepted with the exact group/CPU request but reached scheduler state `E`;
the value-free schedule status classifies it as `failed`, and no weekly chain
has been seeded. Event state classified `smoke-restic-failed`; the login-node
check passes. Allocated probe `176518.qjcm` found Harness, declared storage,
repository, password-file metadata, and Restic ready, but its inherited
`TMPDIR` unavailable. Set only ABCI-Q job scripts to compute-local `/tmp`, add
an exact fake-scheduler contract, pass CI, and require a fresh bounded smoke
before seeding. PR #315 passed protected CI and merged. The fresh smoke passed,
its captured successor `176520.qjcm` was exact-cancelled and verified absent,
and weekly job `176521.qjcm` is active/waiting for
2026-07-26 03:30 JST. No private path or credential value was emitted or read.

**LIFO gate resolved 2026-07-25:** ABQ's first bounded Restic schedule smoke
failed before allocation with scheduler error `SIM1400`: ABCI-Q requires a
mail-user value even when `qsub -m n` disables mail. No job ID was returned,
no backup ran, and no chain state was captured. The official guide confirms
that any `-m` requires `-M`; the ABCI-Q path now omits mail flags while generic
PBS retains `-m n`. The fake scheduler distinguishes both contracts, and the
focused schedule suite, shell syntax, ShellCheck warning gate, and whitespace
check pass. Run full CI, then retry only the smoke before seeding.

**LIFO gate resolved 2026-07-25:** post-merge SSH-layout plans pass on Local and
ten remote systems, but a fresh direct AL probe now fails public-key
authentication. The repository sync to AL had already succeeded through the
managed route, and no AL configuration mutation was attempted after the
failure. `harness al-session --status` reports target/jump ready with managed
ownership, and the normal `ssh al` route passes the plan. The failed probe had
incorrectly disabled multiplexing and therefore bypassed AL's declared
authenticated session; use the managed route for AL. Pop back to rollout.

**LIFO gate resolved 2026-07-25:** after the Claude 2.1.220 increment, the full
suite again passed all 73 focused suites and guarded-delete tests but a later
tool-plan integration exited with `tool plan contains blocked paths`. The
first run was affected by a concurrent ledger edit, but a subsequent clean
trace isolated a real regression in the generalized predecessor predicate:
POSIX equal-precedence `&&`/`||` chaining made a valid uv predecessor also
evaluate the Claude version clause. An explicit tool dispatch now validates uv
and Claude independently. The existing uv replacement integration and the new
Claude plan cover both paths. The first guarded cleanup correctly refused after
the trace added one file; a fresh 13-entry/39,727-byte manifest then deleted
the exact fixture and proved protected anchors unchanged. Both mode-0600 traces
and manifests were exact-unlinked. No installation or external state changed.

**LIFO gate resolved 2026-07-25:** the official Claude native installer was
downloaded once to a mode-0600 temporary file for required review, but the
first syntax check used POSIX `sh -n`; the artifact uses Bash syntax and that
check failed before execution. Bash syntax passes, but the script downloads and
executes the current native binary's opaque `install` subcommand, so it does
not satisfy the reviewed-installer exception. It was not run and was
exact-unlinked. D-005 will instead use checksum-pinned direct native binaries
and a repository-managed atomic launcher transaction.

**LIFO gate resolved 2026-07-25:** the local Claude predecessor smoke passed, but
its cleanup attempted obsolete guarded-delete arguments. No deletion occurred;
the exact synthetic directory `/tmp/claude-plan.NaSyB1` remains and contains
only the generated fake managed-Claude layout. The current manifest protocol
validated 9 entries/28,781 bytes, deleted that exact target, proved protected
anchors unchanged and the target absent, and its single manifest was then
exact-unlinked. Resume D-005.

**LIFO gate resolved 2026-07-25:** official Claude 2.1.220 artifact verification
succeeded for both Linux architectures, but the cleanup command incorrectly
passed two exact files to POSIX `unlink`, which accepts one operand. The two
current-user-owned mode-0600, single-link temporary artifacts remain at their
exact discovered paths; no installation or live state changed. Each was
exact-unlinked separately and a bounded read-only inventory proves zero
matching residue. Resume D-005.

**LIFO gate resolved 2026-07-25:** the third full phase-one run passed all 73
focused suites, then stopped at ShellCheck warning SC1007 in the new
hardening-skill test because `CDPATH= cd` contains an ambiguous empty
assignment. The test now uses the repository's canonical `CDPATH='' cd`
spelling; its focused contract, ShellCheck warning gate, and whitespace check
pass. No external state changed; restart the full suite.

**LIFO gate resolved 2026-07-25:** the second full phase-one run reached 65
focused passes and five failures. A linked-worktree fixture copied its `.git`
pointer and then created an unintended empty local commit named `baseline` on
the T-311 branch; nothing was pushed and its tree is byte-identical to its
parent. The reflog evidence was preserved and the local ref atomically restored
to its verified parent. The missing skill discovery links are now tracked;
checkout validation accepts both normal and linked worktrees; and the copied
fixture exact-unlinks only a regular `.git` pointer before initializing its
synthetic repository. All five previously failing focused suites now pass. No
external state changed; restart the full gate.

**LIFO gate resolved 2026-07-25:** plain `git push` also advanced the existing
T-310 closeout branch from `43c8a8a` to its already reviewed local checkpoint
`cad2e40`. Cause is the owner's global `push.default=matching`; no unrelated
bytes were created or overwritten and local/remote T-310 now match. All T-311
publications will use an explicit `HEAD:refs/heads/BRANCH` refspec. Changing
the global Git preference is outside this task.

**LIFO gate resolved 2026-07-25:** the first ABQ schedule focused run stopped at
the fixture's hard-coded seven-row count after the eighth `abq` row was added.
The failure is local and retry-safe; no scheduler job or live schedule changed.
The expected count now covers all eight rows, ABCI-Q participates in exact PBS
job identity and cancellation handling, and the full Restic schedule suite
passes. T-311 has popped back to the ABQ schedule increment.

**LIFO gate resolved 2026-07-25:** the first skill-scaffolder help invocation
used an unversioned `python` command, which is intentionally absent on Local.
No file was created by that attempt. The exact system skill-creator succeeded
with `python3`, and the new skill records that portable entry point.

**LIFO gate resolved 2026-07-25:** overlapping `sed` ranges made the unknown
command diagnostic appear twice during review. Direct inspection proved the
source contains exactly one line, so no pre-existing dispatcher bug exists.
The hardening audit test still asserts diagnostic cardinality.

**LIFO gate resolved 2026-07-25:** the first audit-command fixture reported zero
unpinned Actions because its parser expected `uses:` without YAML's list-item
dash. The value-free trace confirmed every other field and guarded cleanup.
The parser now accepts required `- uses:` syntax while retaining
immutable-commit enforcement; the focused test and a live value-free audit
pass. T-311 popped back to command closeout.

**LIFO gate resolved 2026-07-25:** the first full phase-one run stopped
immediately because the Python hardening-audit executable was mistakenly added
to the shell `sh -n` list. No later test ran and no external state changed.
It now uses the Python AST gate; focused command coverage and whitespace checks
pass. Restart the full suite from its first step.

Read-only discovery found P0 risks in the students cryptography lock and
Swallow's absent protected-main/CI controls; repository-default Actions
permissions in Harness and Swallow are also overbroad. All Mac firewalls are
off and Office exposes X11 on TCP 6000. ABQ's primary Restic check passes but
its weekly schedule declaration is absent. Website's current controls and
locked dependencies passed the matched audit.

The complete baseline, six-decision register, execution order, safety and
rollback gates, acceptance criteria, evidence, and deadline protocol are in
`docs/plans/t311-fleet-repository-hardening.md`.

Decision D-001 is confirmed: use a one-review, strict-CI, linear-history,
conversation-resolution floor for non-admin writers with an owner/admin
bypass; preserve Students' stronger code-owner and last-push gates.

Decision D-002 is confirmed: use read-only Actions defaults, Dependabot
security and grouped monthly update pull requests, and secret scanning with a
reviewed CI fallback when private-repository hosting does not provide it;
never auto-merge dependency updates.

Swallow is now clean and current at `76de582`, so an isolated Swallow
hardening worktree may be created after the interview and explicit `go`.

Decision D-003 is confirmed: enable the Mac firewall and stealth mode while
preserving signed/built-in access, disable Office's X11 TCP listener, and
validate routes and managed ownership one Mac at a time. Administrator changes
remain gated by D-006.

Decision D-004 is confirmed: repair ABQ's missing weekly Restic schedule only;
do not expand or add tasks for Mac-state or Swallow-artifact backups.

Decision D-005 is confirmed: converge Claude Code to verified release
`2.1.220` on every managed Linux node and Mac without interrupting active
sessions. This explicitly supersedes T-295's Aist removal; Home had no recorded
intentional-absence decision.

Decision D-006 is confirmed: use only existing narrow non-interactive
authority; stage exact reviewed helpers and top-priority TODO blockers for
password-, TCC-, or root-gated work, then continue independent work.

**Next action:** continue safe hardening and scheduled backup checkpoints below
the deferred Codex user-config policy decision and Mac administrator helper.
Students T-004, Website T-207, and Swallow SW-018 are independently closed;
continue any newly discovered repository-local stack without waiting on
another repository.

### T-309 — Canonicalize fleet-health probing

**Phase:** complete.

Routine fleet health already requires AL to pass both
`harness al-session --status` and a normal multiplexed `ssh al true`. A
2026-07-25 ad hoc parallel probe nevertheless forced `ControlMaster=no` and
`ControlPath=none` on every target. That bypassed AL's healthy managed session,
tested whether a fresh daily certificate was available, and falsely reported
AL down. Immediate prescribed checks returned
`target=ready ownership=managed jump=ready action=none` and normal
`ssh al true` exited 0. This was a probe artifact, not an AL outage.

Implement one value-free, read-only `harness fleet-health` command and require
routine health reports to use it instead of agent-authored SSH loops. The
command must encode target-specific contracts:

- local is checked locally; ab, ab2, ri, rc, and t4 use ordinary
  configuration-preserving SSH probes;
- AL first requires the managed `al-session --status` contract, then runs a
  normal multiplexed `ssh al true`; it must never override `ControlMaster` or
  `ControlPath` in routine health;
- abq is one Linux node and passes only when both `abq` and `abq2` routes pass;
- each managed Mac passes only when both independent reverse aliases pass,
  using the existing independent-route semantics rather than AL's managed
  multiplex contract;
- `abci_login`, `alps_login`, web, and retired aliases are excluded from the
  routine summary.

Use bounded parallelism but emit results in canonical inventory order, return
nonzero if any logical node fails, and expose deterministic per-node
machine-readable results plus the established compact summary that names only
failures. Preserve only value-free route/error classifications; never relay
raw SSH diagnostics. Keep fresh-authentication diagnosis separate and explicit
so certificate renewal readiness can never be confused with current
managed-session reachability.

Add failing focused fixtures first. They must prove that AL receives no
`ControlMaster`/`ControlPath` override, both ABQ routes are required, both
routes of every Mac are required, excluded transports are never probed,
timeouts/SSH failures remain failures, result order is stable despite
concurrency, aggregate exit status is nonzero on any failure, and output is
value-free. Then add the command, CLI routing/help, focused suite registration,
documentation, and the AGENTS contract requiring the canonical command. Run
ShellCheck, the focused suite, `tests/test-phase1.sh`, protected CI, and a live
matched case where the managed AL route passes while one separately controlled
fresh non-multiplexed diagnostic requires renewal. Publish and guarded-sync
only clean managed checkouts.

**Acceptance:** routine fleet health cannot report AL down solely because a
fresh daily CSCS certificate is unavailable; all logical-node and route-count
semantics match the canonical inventory; no credential value or private SSH
diagnostic is read or logged.

The failing focused fixture was added first and stopped because
`harness-fleet-health` did not exist. The initial implementation now uses
three bounded four-probe batches, emits results in canonical inventory order,
requires managed AL status before a normal multiplex-preserving route probe,
requires both independent routes for ABQ and every Mac, excludes transport-only
aliases, suppresses private SSH diagnostics, and returns nonzero if any logical
node fails. The focused fixture passes healthy and mixed-failure cases.
Register the suite, validate shell/static contracts, run the full phase-one
gate, then perform one live matched fleet check before protected publication.

The suite is registered and passes with shell syntax, warning-level ShellCheck,
the focused-runner contract, source contract, whitespace validation, and the
complete four-worker portable phase-one gate. A live matched run reports every
Linux logical node ready—including both ABQ routes—every Mac ready through
both independent routes, and AL ready through managed status plus its normal
multiplexed command. Publish through protected CI, merge, guarded-sync the 11
clean remote checkouts, perform the required four Mac context refreshes, and
rerun the installed command from Local.

Protected PR #325 passed run `30170878451` and merged as
`491475eef2eb576765c5b98858429b47cfeffe85`. Guarded fleet sync advanced all
11 clean remotes with absent transfer artifacts; all four Mac refreshes were
submitted once. The installed Local command then reproduced
`Fleet: Linux pass; Macs pass.` T-309 is complete.

### T-303 — Observe intermittent NFS I/O latency

**Phase:** client observation complete; server-side correlation remains.

The read-only monitor ended cleanly after exactly 24 hours and preserved its
mode-0700 ext4 evidence directory. Across 148,176,545 new NFS RPC calls, the
client saw only five retransmissions, no NIC error/drop increase, and no
sustained server packet loss. Network health therefore does not explain the
reported stalls.

The trace reproduced a common failure domain on `192.168.33.30`: all three
low-utilization exports repeatedly timed out bounded capacity/statfs probes
between 08:42 and 11:04 JST, `safe` write latency reached 3.936 seconds, and
later `fast` reads reached 439.5 ms. `/home` separately accumulated roughly
one second of client write queue while server RTT stayed below 18 ms. Preserve
the raw directory unchanged and ask the `192.168.33.30` administrator to
correlate pool/disk, NFS-daemon, cache, and system evidence for the recorded
intervals. Local sudo is not required. Full results and limitations are in
`docs/audits/t303-nfs-observation-2026-07-24.md`.

### T-302 — Reduce AL authentication intervention

**Phase:** complete. CSCS requires
personal
SSH keys to be CSCS-signed and limits personal certificates to one day. The
owner rejected the higher-complexity service-account/ACL/shared-state design;
none of it was applied. The selected personal-only design accepts
reauthentication after a real transport loss and never signs, renews, lists,
or exposes credentials.

`harness al-session` now provides value-free status, one non-interactive start
attempt, authentication-vs-availability classification, socket-identity
ownership, and managed-only graceful stop. The foreground master runs in a
collected, non-restarting transient user-systemd unit with null output, so it
survives the Codex command that launched it without installing a unit file.
PRs #277–#279 passed protected CI; final implementation revision is
`0391eab`. ShellCheck, focused/public/source-contract coverage, all 68 focused
shards, the complete phase-1 suite, live start/stop/reapply, and cross-command
reuse pass. Guarded fleet sync advanced all 11 managed remotes cleanly with no
transfer residue.

At 2026-07-23 15:09 JST, the receipt-matched `al` and `alps_login` masters
were ready, the transient unit was active/running, all eight Linux targets
were healthy, and every monitored route pair was 2/2. Implementation and
rollout are complete. Full evidence, rollback, and official sources are in
`docs/plans/t302-al-authentication.md`.

The time-gated experiment was invalidated before its gate: the managed SSH
process exited 255 at 2026-07-23 22:35 JST after 7.5 hours, and its transient
unit had `Restart=no`. No recovery ran while fresh authentication was still
available; by morning, the absent session correctly required renewal. The
transport's private output was null, so the exact network/server cause is
unknown. Certificate expiry itself does not terminate an established session.

The restart-resilience extension is planned in
`docs/plans/t302-al-session-resilience.md`. It preserves personal MFA and adds
value-free exit classification, automatic retry only for transport failures,
restart-aware marked-unit ownership, focused/full tests, one live restart
drill, protected publication, and guarded fleet sync. The owner selected
indefinite 60-second retries for classified availability failures, with
immediate stop on authentication or permanent local errors. The owner gave
explicit `go` at 2026-07-24 06:30 JST; execution begins with failing focused
fixtures. The tracked value-free runner, 60-second restart policy, schema-2
marked-unit receipt, restart-aware status/stop behavior, terminal failure
classification, and focused fixtures are implemented locally. The focused
suite passes, including a replacement socket, non-restarting authentication
and permanent failures, schema-1 compatibility, and marker-collision refusal.
A disposable user-systemd probe independently accepted the exact restart
properties. Static/full validation, protected publication, the live AL restart
drill, merge, and guarded fleet synchronization remain. Implementation commit
`180d432` passes shell syntax, warning/error-level ShellCheck, `git diff
--check`, the focused AL suite, and the complete phase-one suite. The latter
passed all 68 focused shards and every integration gate. An earlier sequential
shard run's one unrelated watchdog timing failure passed immediately in
isolation and passed again in the authoritative complete suite.

PR #281 passed its first protected CI run. The owner renewed AL access. Two
live `TERM` drills demonstrated OpenSSH's graceful zero exit, for which no
restart is correct, and rolled back cleanly. An exact identity-checked `KILL`
drill then exposed a real crash edge: systemd reached `NRestarts=1` with a new
runner, but the killed OpenSSH process left an unusable Unix socket that
prevented the replacement from publishing its control master. The bounded
drill failed safely; the exact marked unit, unusable current-user socket, and
receipt were removed, leaving absent clean state. A failing focused fixture now
requires receipt-and-marker-validated stale-socket cleanup in the runner before
the live drill is repeated. That cleanup and restart-window status handling are
now implemented locally. The focused suite passes matched cleanup,
mismatched-marker preservation, and stale-socket `retrying` coverage; full and
protected validation remain before the next live drill. Managed stop also
removes only the same safe, unusable receipt-matched socket after stopping the
marked unit, and its focused rollback fixture passes.

The next protected live drill proved restart and socket recovery, but the final
gate rejected the active session because its private diagnostic file kept a
pathname for the lifetime of SSH. Rollback again left absent clean state. A
failing focused fixture now requires anonymous open descriptors: exact-unlink
the mode-0600 pathname before launching SSH while retaining post-exit
classification. This behavior is now implemented and the focused suite passes
all four exit classes plus diagnostic-path absence. Full and protected
validation remain before the final live drill.

Commit `2b4bc9e` passed the complete phase-one suite and protected CI. The
final identity-checked hard-crash drill passed at 2026-07-24 07:34 JST:
systemd restarted once after 60 seconds, both process generations changed, the
stale socket became a safe usable managed master, `ssh al true` passed, and no
named diagnostic path existed. The recovered unit is active/running with
`NRestarts=1`. Commit and protect this evidence, merge PR #281, guarded-sync
the clean fleet, then observe the same master across the certificate boundary
no earlier than 2026-07-25 07:35 JST.

PR #281 merged as `0fa3949`, but the merge exposed that unlinking an open file
under this node's NFS-backed checkout or `~/.ssh` creates visible `.nfs…`
placeholders. The managed session was stopped cleanly, which released its
repository and diagnostic placeholders; unrelated live `.ssh/.nfs…`
placeholders were not touched. Work continues on
`t302-al-session-runtime-log`: a failing fixture requires the private
diagnostic descriptors to originate in the validated current-user runtime
directory instead of NFS before the session is restarted and fleet sync runs.
Local's runtime directory is owner-only mode 0700 on tmpfs. Both helper and
runner now enforce that boundary; focused fixtures pass runtime-origin,
pathname-absence, stale-socket, restart-status, stop, and exit-classification
coverage. Full, protected, and live validation remain.

Commit `9942d46` passed the complete suite and PR #282 protected CI. A first
over-broad `.ssh/.nfs…` total-count preflight stopped before signaling and
rolled back; unrelated placeholders stayed untouched. The corrected
runner-owned hard-crash drill passed at 2026-07-24 07:49 JST: one restart after
60 seconds, replaced process generations, recovered stale socket, successful
AL command, zero runner-held/repository/runtime `.nfs…` paths, and a diagnostic
held only by deleted tmpfs descriptors. The unit is active/running with
`NRestarts=1`. Commit/protect this evidence, merge PR #282 without replacing
the live runner inode, guarded-sync the fleet, then observe the same master no
earlier than 2026-07-25 07:50 JST.

PR #282 merged as `b5c4c7854e1b291531928a8b77c14b27e6c3b126`.
Local `main` was advanced only after exact tree-identity proof, avoiding live
runner inode replacement. Guarded fleet sync advanced all 11 remote checkouts
from `7965d4190e4cf3faa6f2f8ea685cef750207ff86` to `b5c4c78`; a second plan
reported clean `KEEP`, aligned `origin/main`, and absent transfer artifacts for
every target. The managed AL unit remains active/running with `NRestarts=1`,
managed status, a usable AL command path, and no repository `.nfs…` residue.

Implementation and rollout are complete. The only remaining T-302 action is
time-gated: no earlier than 2026-07-25 07:50 JST, do not replace the master;
verify the same marked unit remains managed, run multiplexed `ssh al true`, and
run one private fresh non-multiplexed probe to distinguish continued reuse from
renewal-required. Record the observation without inspecting credentials.

The final certificate-boundary observation passed at 2026-07-25 13:22 JST.
The marked unit remained managed and active/running, with `NRestarts=2` and
its current generation active since 2026-07-24 21:19:42 JST. Normal
multiplexed `ssh al true` passed. One private non-multiplexed probe required
renewal, proving that continued access came from the persistent managed
session rather than a fresh certificate. Its mode-0600 runtime log was not
read and was exact-unlinked. Routine fleet health now uses the managed status
and normal route instead of bypassing multiplexing. No further T-302 action
remains.

### T-196 — Backup lifecycle phase 2

**Status:** time-gated. Local, AB, AB2, RI, RC, T4, and ABQ are at 2/8
successful weekly chains, and AL remains 1/8 until its later eligibility. Execution
requires eight successful chains, two verified restores per node, and a
current independent generation.

**LIFO observation issue resolved 2026-07-26:** after RI's live status proved the
chain had advanced to exact successor `10386`, the first safe history/private
parser failed before reading state because the remote shell expanded an
unescaped awk field under `set -u`. The corrected parser read only whitelisted
metadata and proved private state `active`, result `success`, and a present
64-hex snapshot without exposing its value. No state or scheduler action
changed.

**LIFO observation issue active 2026-07-26:** RI's first exact `sacct -j 7242`
query at the 02:00 eligibility boundary returned unavailable without printing
job data. Exact live/status queries prove the old ID is no longer queued, the
chain is active with silent warnings, private result is successful with a
present snapshot, and exact successor `10386` is pending for 2026-08-02 02:00
JST. A second exact retry at 03:50 JST failed before job lookup because Slurm
could not resolve its DNS SRV configuration source. Terminal scheduler history
is still not visible, so keep this observation open and retry only exact ID
`7242`; do not alter successor `10386`.

| Node | Recorded 2026-07-26 successor |
| --- | --- |
| local | 91840 |
| ab | 2048464.pbs1 |
| ab2 | 2048468.pbs1 |
| ri | 7242 |
| rc | 212389 |
| t4 | 8194556 |
| abq | 176521.qjcm |
| al | 4238363 |

**2026-07-26 checkpoint:** exact Local job `91840` completed with `0:0`;
private state is active/success with a present 64-hex snapshot, warning output
is silent, and exact successor `94950` is pending for 2026-08-02 00:30 JST.
Local is now 2/8. Exact AB job `2048464.pbs1` and AB2 job
`2048468.pbs1` later reached terminal PBS state `F` with exit 0 during the
T-311 final observation window. Both private chains are active/success with a
present 64-hex snapshot, warnings are silent, and exact successors
`2064918.pbs1` and `2064919.pbs1` are waiting for 2026-08-02 01:00 and 01:30
JST respectively. AB and AB2 are now 2/8. The first AB safe-field parser
expected the historical `Job_Id =` label instead of live `Job Id:` and failed
read-only; the corrected exact-ID query passed. No job was replaced.

Exact RC job `212389` completed with `0:0`; private state is active/success
with a present 64-hex snapshot, warnings are silent, and exact successor
`260847` is pending for 2026-08-02 02:30 JST. Exact T4 job `8194556` completed
with `failed=0 exit=0`; its private state and warning checks passed, and exact
successor `8270230` is present for 2026-08-02 03:00 JST. Exact ABQ job
`176521.qjcm` reached terminal state `F` with exit 0; its private state and
warning checks passed, and exact successor `176525.qjcm` is waiting for
2026-08-02 03:30 JST. No job was replaced or modified.

On or after eligibility, identity-match and query only these IDs. Record
terminal success, snapshot succession, warning silence, and chain count. Delay
is healthy; do not replace a pending job. Keep-all remains effective. No
forget, prune, recurring check/restore, or replica automation is authorized.
Evidence is in `docs/backup-lifecycle-phase2.md`, `docs/home-backup.md`, and
`docs/audits/restic-first-weekly-2026-07-19.md`.

## Completed anchors

- **T-310:** implemented portable foreground Codex transient-service
  resilience in functional PR #310, merged as `e9c3e06`. The supervisor
  resumes the same saved chat without replaying a prompt, gates retries through
  native doctor, uses bounded backoff, and keeps only value-free private
  runtime state. Protected CI, guarded eleven-node fleet sync, and four Mac
  context refreshes passed. The stale closeout PR #311 was superseded after its
  protected check recovered because its only conflict was obsolete task-board
  history. Acceptance evidence and rollback are in
  `docs/plans/t310-codex-service-resilience.md`.
- **T-312:** completed post-hardening housekeeping in protected Harness PR
  #329 (`328968b`) and Website PR #34 (`b527463`). Guarded cleanup removed
  seven merged worktrees, four eligible arg0 directories, two Students
  caches, and two exact Swallow `.DS_Store` hard links; 33 remote and 21 local
  merged task branches were pruned. Active tasks and all private, runtime,
  research, credential, and live-session state were preserved. Git integrity,
  the complete Harness suite, eleven-node synchronization, four Mac context
  refreshes, final residue checks, and canonical fleet health passed. The
  first refresh used a nonexistent shorthand helper path and failed locally
  before contact; the installed skill path then submitted exactly once to
  each Mac. Progress commentary now uses `[HH:MM:SS]` local-time prefixes.
- **T-308:** added the shared `reboot-recovery` skill and deterministic
  Local-side helper in PR #306, merged as `9203033`. Recovery now separates
  automatic launchd tunnel restoration, owner login and Codex remote-control
  restart, and fail-closed Local tmux restoration. It preserves pairing,
  requires both routes and clean/current Git, reads no pane contents or
  credentials, and keeps all repository cleanup—including `.DS_Store`
  removal—outside recovery. The skill validator, ShellCheck, focused suite,
  complete phase-one suite, protected CI, guarded eleven-node fleet sync, and
  four post-sync Mac context refreshes passed. Live status recognized Aist,
  Home, Office, and Riken as fully ready. Evidence and boundaries are in
  `docs/plans/t308-reboot-recovery-skill.md`.
- **T-307:** published symmetric visible TUI messaging and reliable
  same-channel bounded requests in PRs #296–#302. Final implementation
  `4544f7ddd263c78d9a54d80be339be64636c399c` passed protected CI and fleet
  sync. New independent requests `t307-aist-r2-20260724`,
  `t307-home-r4-20260724`, `t307-office-r4-20260724`, and
  `t307-riken-r2-20260724` all returned valid `responder=exec-request`
  replies; each Mac retained one detached live TUI, a clean/current checkout,
  zero private response directories, and zero transient message buffers. The
  durable design and failure evidence are in
  `docs/plans/t307-remote-agent-communication.md`.
- **T-306:** established a durable post-sync rule requiring the syncing agent
  to reconcile each running Mac Codex with the updated repository without
  inspecting pane contents or interrupting attached work. PR #291 merged as
  `acf2b817`; guarded fleet sync advanced all eleven clean remotes with no
  transfer residue. Aist, Home, and Office accepted one refresh immediately;
  Riken correctly deferred while attached and accepted its refresh after the
  owner detached. Validation then found that Aist, Home, and Office completed
  the instruction and exited cleanly. Their sessions were resumed without
  changing remote-control daemons, and the contract was tightened so every
  refresh requires complete `AGENTS.md` and `TODO.md` reads, Git state
  inspection, durable-ledger reconciliation, and a return to the running idle
  state in the same tmux session. The owner then confirmed that the tmux TUI is
  the same conversation shown by phone remote control, but that immediate
  `Enter` after literal injection left the text unsubmitted in the composer.
  A separate `C-m` submitted the existing prompt on all four Macs without
  reading or reinserting it. The durable workflow now requires a paste-settle
  delay followed by a separate `C-m` and does not count insertion as delivery.
  PR #294's first protected CI run encountered the unrelated timing-sensitive
  watchdog retention check; the focused macOS SSH supervisor suite and the
  complete phase-one suite both passed on immediate local retry.
- **T-305:** eliminated AB's split-install update loop, disabled the
  inapplicable native startup offer, upgraded every remote Linux managed
  installation to verified Codex 0.145.0, removed only AB's redundant npm
  package, and made agent-tree evidence independent of site tar defaults. PRs
  #288 and #289 end at `cc0e6d8`; complete artifact, transaction, validation,
  rollback, and cleanup evidence is in
  `docs/plans/t305-codex-managed-update.md`.
- **T-301:** standardized the shared SSH defaults and alphabetic stanza
  ordering, replaced readable multiplex paths with `%C`, and selected a
  30-second global connection timeout after matched nested-route evidence.
  Functional PRs #274 and #275 end at
  `5a8a0901ce82b7bb187d74c479125e61e0cb8fe7`. Local and all eleven remotes
  have byte-identical live fragments, clean/current repositories, effective
  policy checks, zero legacy mux sockets, and healthy fresh routes. All Mac
  supervisors report `managed=1 external=0`; the full evidence and transaction
  IDs are in `docs/plans/t301-ssh-defaults-review.md`.
- **T-300:** removed the duplicate README node table, made
  `docs/fleet-inventory.md` the sole cold-start table, and added guide links for
  all nine Linux-facing entries. Every public guide returned HTTP 200; existing
  authenticated GitHub access reached the private Hinadori repository and wiki
  remote. The focused inventory regression test and full phase-one suite pass.
- **T-299:** refreshed and reprioritized the README around owner-facing use,
  added the canonical public fleet table, reconciled current tools, workflows,
  route resilience, and skill inventory, and added a regression check that
  requires every README node row to match `docs/fleet-inventory.md`. Focused
  checks and the full phase-one suite pass.
- **T-298:** compacted this board to current state, the T-196 gate, durable
  guardrails, and completion pointers; superseded execution detail remains in
  Git and the linked audit documents.
- **T-297:** completed Local/four-Mac SSH hygiene, canonical layout migration,
  private payload convergence, legacy Office keepalive removal, mux cleanup,
  and final fleet synchronization. Functional PR #268 is
  `42c971627b6ab67a7866a7d481c738eda269330a`; closeout PR #269 is
  `ff52d8d2a42d84c1ef9ed7c582a7aa99bdc843fe`. Full closeout detail is
  preserved at the latter commit.
- **T-296:** published and validated the Mac-local watchdog, JumpCloud-isolated
  restricted authorization file, account-scoped sshd liveness, and matched
  failure drills. The durable plan is
  `docs/plans/t296-mac-connectivity-resilience.md`; evidence is in
  `docs/audits/t296-mac-connectivity-resilience-2026-07-23.md`.
- **T-295:** completed thirteen fleet-convergence workstreams in PRs #212
  through #254, ending at `5d551883648760fcc373973a575a403b18637f44`.
  The frozen plan is `docs/plans/t295-fleet-convergence.md`.
- **T-294:** diagnosed the Codex NFS arg0 failure and published guarded,
  lock-aware housekeeping plus the transactional version-scoped launcher in
  PRs #208 and #209, ending at `f7cdacd`.
- **T-293:** published independent Mac reverse-route supervision and recovery
  in PRs #191 through #206, ending at
  `97162ef3c554a80a29c63a4b83d39d292ad4fb14`. Evidence is in
  `docs/audits/t293-connection-self-healing-2026-07-22.md`.
- **T-288–T-292:** completed four-Mac onboarding cleanup, SSH configuration
  convergence, login isolation, and final private schema-3 migration. Evidence
  is in `docs/audits/macos-ssh-finalization-2026-07-21.md`.
- **T-283–T-284:** published symmetric and accelerated Codex-Claude cowork in
  PRs #161 and #163.
- **T-273:** closed after every concrete maintenance item completed. Backup
  successors remain under T-196; container and package policy now live as
  durable guardrails rather than pending work.
- **Earlier anchors:** T-274 and T-279–T-287 completed Bash, Mac onboarding,
  and ledger foundations; T-191 accepted the first native weekly backups;
  T-181 finished at 69/70 with zero safety failures. T-210 is complete and
  must not be repeated.

Detailed pre-compaction chronology remains available at published commits
`90451d49ac96`, `378df00159d59e8abee645f2bdaebd20cf467cc2`, and
`5d551883648760fcc373973a575a403b18637f44`.
