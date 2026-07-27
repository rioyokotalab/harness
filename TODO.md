# Personal harness task board

This is the authoritative resume point for the portable Codex and Claude
harness. Keep only current state, active decisions and gates, exact next
actions, and compact completion pointers here. Git history and the linked audit
documents retain completed execution detail.

Next free ID: T-322.

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
- New interactive shells use native TTY-aware `ls` color on every managed
  system: `-G` on Darwin and `--color=auto` on Linux. Existing shells retain
  their previously loaded alias until they re-source the common aliases or
  start a new shell.
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
  rules, and 15 skills when started from `~/harness`. All 12 systems retain the
  two global launch sentinels and Codex launcher. Codex's opaque product-owned
  user configuration is private and accepted on Local, T4, and the four Macs;
  it is absent on the other six nodes. Schema-2 doctor, repository convergence,
  external onboarding preflight, and all four resumed Mac TUIs pass. See
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
- Before yielding every Harness turn, report a fresh compact health snapshot
  for every managed Linux node and all four Mac route pairs. Count abq as
  Linux and mark it ready only when both abq and abq2 routes pass; do not
  include that pair in the Mac total. Omit `abci_login` and `alps_login`
  unless a task targets those transports.

## Next resume checkpoint

1. T-314 through T-318 are complete. Students and Swallow are owned by their
   independent project agents and ledgers; Harness has no project-research
   resume action for either repository.
2. T-311 is complete, including administrator-authenticated Mac changes and
   D-007's private product-owned Codex user layer.
3. T-303 is externally blocked: the owner confirmed no access to or prior
   login on `nas-03.yokota` / `192.168.33.30`. Resume only if the responsible
   administrator or a trusted physical/hypervisor console can independently
   confirm the recorded host fingerprint and intended login account.
4. Continue T-196 only at its exact time/identity gates: all eight nodes are
   now 2/8 with next-week successors waiting. Retry RI accounting ID `7242`
   without touching successor `10386`; otherwise wait for the exact 2026-08-02
   successors recorded below.

## Active tasks

### T-321 — Recover recurring Swallow unsafe-tail `Request blocked`

**Phase:** validating.

At 2026-07-27 20:24 JST, the owner reported that the phone/tmux Swallow
thread was again stuck at `Request blocked`. Read-only metadata proves exact
tmux window `@58:2` remains live under supervisor PID `382132`, watcher PID
`382211`, and remote root `019fa27c-6280-7f00-8e46-ef878875562b`.
`codex-resilient --status` is `running/remote-explicit` at attempt/delay zero;
its watcher reports `blocked/unsafe-tail`, with one prior safe recovery and
one rolled-back turn. No pane or rollout content was read, and no process,
thread, prompt, or tmux state changed.

The watcher is correctly refusing another automatic rollback: the retained
tail is not proven side-effect-free, so rollback could discard real SW-031
tool work. Restarting the TUI would reconnect the same poisoned root, and
forking previously inherited this error. The recommended recovery is the
proven fresh-root cutover: preserve the blocked root, create and validate one
empty app-server root, launch it provisionally under an exact remote
supervisor/watcher, submit one identified cold-start instruction that resumes
only from Swallow's durable repository ledger, then atomically transfer the
`swallow` name/window after a completed assistant turn. Never replay the
rejected prompt, restart the shared app server, inspect pane/transcript
content, or delete/archive the old root.

Decision D-001 is selected: the owner chose the recommended reversible
fresh-root cutover while retaining the blocked root as rollback evidence.
The frozen execution and safety gates are in
`docs/plans/t321-swallow-unsafe-tail-recovery.md`. The plan now waits for a
separate explicit `go`. No thread, tmux, process, app server, prompt, or
project state changed while recording this decision.

**Execution authorization 2026-07-27 20:35 JST:** the owner gave the separate
explicit `go`. Exact read-only preflight revalidated clean/aligned Harness
`main` at `36d938f`, the three-window mapping with Harness active, Swallow
window `@58:2`, supervisor PID `382132`, watcher PID `382211`, remote root
`019fa27c-6280-7f00-8e46-ef878875562b`, attempt/delay zero, and unchanged
`blocked/unsafe-tail` with one prior recovery/rollback. No target mutation has
run. Commit and push this authorization checkpoint, then complete the narrow
app-server/process/socket/doctor identity gate before one `thread/start`.

**Pre-write plan correction:** installed schema and T-318 evidence show a new
0.145.0 rollout is created mode `0664`, while watcher readiness requires
`0600`. The frozen plan now explicitly requires the prior proven
descriptor-identity transaction: only a current-user-owned, single-link,
canonical new rollout with exact initial mode `0664` may be opened without
following links, identity-revalidated through the descriptor, and changed to
`0600`. No root has been created yet. Commit and push this correction, rerun
the narrow live preflight, then invoke `thread/start` once.

**Thread-start result:** one acknowledged `thread/start` created exact root
`019fa36c-cfa9-7143-ae11-1f538e07bfee`, then the immediate rollout gate
stopped because the declared path did not yet exist. No chmod or name request
ran, and `thread/start` must not be retried. Fresh protocol reconciliation
proves the exact root is in app-server memory, idle, zero-turn, unnamed,
cwd-matched, absent from the state DB, and has no on-disk rollout yet. This
matches T-318's actual persistence order: one acknowledged name write creates
the durable surfaces, after which the descriptor transaction can tighten the
rollout. Commit and push this non-retryable result and order correction, then
send only the provisional `thread/name/set`.

**New-root acceptance:** exactly one `thread/name/set` named root
`019fa36c-cfa9-7143-ae11-1f538e07bfee`
`swallow-recovery-20260727`. Same-connection readback proved exact identity,
idle state, zero turns, and the expected cwd. Its newly persisted rollout was
a canonical current-user-owned, single-link regular file at exact mode `0664`;
the descriptor-identity transaction changed only that inode to `0600`, and
stable post-readback passed. Neither `thread/start` nor the name write may be
retried. Commit and push this accepted identity, then launch one detached
provisional `swallow-next` window under supervisor name `swallow-recovery`.

**Provisional-client acceptance:** one detached launch created exact window
`@59:3` / pane `%59`, supervisor PID `2876863`, watcher PID `2876942`,
and real TUI PID `2877595` for the new UUID. Value-free status is
`running/remote-explicit` plus `watching/thread-idle`, with attempt/delay and
recovery/rollback counts all zero. Process argv, session identity, four-window
mapping, and the established Unix peer to unchanged app server PID `2852569`
pass. Harness remains active and Students plus blocked Swallow are unchanged.
Commit and push this accepted identity before submitting the one cold-start
turn.

**Cold-start acceptance:** under the shared agent-message lock, exactly one
identified `turn/start` was acknowledged for new root
`019fa36c-cfa9-7143-ae11-1f538e07bfee` as turn
`019fa370-3c31-75b2-8d0b-d7b6cd72b0e4`. A persistent read-only monitor
connection timed out once after observing assistant-bearing progress; no write
was retried, and fresh read-only connections safely continued. Final
value-free protocol structure proves the turn completed with one user item,
13 assistant items, one terminal file-change item, no active item, and no
`systemError`. Harness did not inspect message, pane, command, patch, or
project content. Commit and push this acceptance, then execute only the
read-before/name-set/read-after root-name transfer and exact tmux window
renames.

**Root-name cutover:** complete preflight revalidated both process chains,
immutable start ticks, unchanged app server PID `2852569`, Harness selection,
Students, and exact old/new protocol state. One acknowledged name write plus
readback changed only poisoned root
`019fa27c-6280-7f00-8e46-ef878875562b` from `swallow` to
`swallow-blocked-20260727`; a second acknowledged write plus readback changed
only accepted root `019fa36c-cfa9-7143-ae11-1f538e07bfee` from its
provisional name to `swallow`. Old remains `systemError`; new remains idle.
Neither write is retryable. Commit and push, then rename exact tmux `@58` to
`swallow-blocked` and exact `@59` to `swallow`, leaving the owner on `@49`.

**Tmux cutover:** exact preconditions passed and native `tmux rename-window`
ran once per target. The four-window mapping is now `@49:harness` active,
`@50:students`, `@58:swallow-blocked`, and `@59:swallow`; every window has
one pane. No client switch, pane input, or process signal ran. Commit and push
this reversible checkpoint, then revalidate old real TUI PID `382364` /
start tick `87255666` and send one `SIGTERM` only to that leaf so its exact
wrapper, watcher, and supervisor unwind without respawn.

**Old-chain retirement:** exact PID, parent, session, start-tick, argv, root,
window, and unaffected-target gates passed. One `SIGTERM` was sent only to
old real TUI PID `382364`; real TUI, wrapper PID `382272`, watcher PID
`382211`, and supervisor PID `382132` all exited within four seconds without
respawn. No second signal, process-group signal, `SIGKILL`, archive, delete,
rollback, prompt, or app-server action ran. The saved poisoned root remains
preserved as `swallow-blocked-20260727`. Commit and push, then perform
independent final process/socket/thread/tmux/doctor/Git validation and guarded
cleanup of only the generated schema bundle.

**Live execution validation:** the old window disappeared with its exact
process chain. Tmux now has exactly `@49:harness` active, `@50:students`, and
`@59:swallow`; accepted supervisor PID `2876863`, watcher PID `2876942`, and
real TUI PID `2877595` retain their immutable start identities and exact new
UUID. Value-free status is `running/remote-explicit` plus
`watching/thread-idle`, with all retry/recovery counters zero. The established
Unix peer reaches unchanged app server PID `2852569`; native doctor is
`overall=ok` with zero failed checks. Protocol readback proves old root
preserved as `systemError/name=swallow-blocked-20260727`, new root
`idle/name=swallow`, and the accepted turn completed with assistant output and
no active items. Harness and Students pane identities are unchanged.

The `guarded-bulk-delete` workflow removed only generated schema bundle
`/tmp/t321-app-server-schema.sBpGch` (350 entries / 3,332,549 bytes; token
`d43c69b3d55a924cb6cf088e3fa4b4c79afa23763b3497616ac4d32528b613e4`)
and task-created `/home/rioyokota/harness/libexec/__pycache__` (two entries /
42,026 bytes; token
`3a1ab0b1071d49111bb2dd7d4de3bbbb65937e7fc61c3e783ab70803a7557d95`).
Protected anchors were unchanged, targets are absent, and both mode-0600
manifests were exact-unlinked. The live `.nfs…` inode remains untouched.
Commit this validation, run diff hygiene and protected CI, publish/merge the
execution ledger, then perform a fresh final live readback and canonical fleet
health before marking T-321 complete.

### T-320 — Make interactive `ls` color portable across the fleet

**Phase:** complete.

The owner observed that SSH sessions from Local to the managed Macs lost
`ls` color even though reverse SSH sessions from a Mac to Local retained it.
Forced-PTY evidence established that terminal negotiation is healthy:
`TERM=tmux-256color`, terminfo is present, and `tput colors` reports 256 on all
four Macs. Local uses GNU coreutils 9.4, whose `ls --color=auto` emits ANSI
color on a terminal without `CLICOLOR`. The Macs use the system Apple/BSD
`ls`; `ls -G` and `CLICOLOR=1 ls --color=auto` emitted ANSI, while the shared
`ls --color=auto` alias did not.

Use the native TTY-aware option in `shell/common-aliases.sh`: `-G` on Darwin
and `--color=auto` elsewhere. Keep `CLICOLOR` unset so noninteractive child
processes and unrelated tools do not inherit a new global color policy. Add a
focused test that executes both OS branches through a mock `uname`, verifies
the exact alias, and proves the temporary selection variable does not leak.

Implementation is isolated at `/tmp/harness-t320-ls-color/repo` on branch
`codex/t320-portable-ls-color`; Local's live supervisor-held
`libexec/.nfs…` placeholder remains untouched. Bash and POSIX-shell syntax,
ShellCheck, the startup-normalization test, and diff hygiene pass. The focused
test executes both OS selections, verifies exact alias values, and proves the
temporary selector is absent after sourcing. Implementation checkpoint
`8125981` passed the complete eight-worker `tests/test-phase1.sh` from its
clean exact revision with inherited `HARNESS_ROOT` removed: all 75 focused
suites and integration gates passed, with only the declared native-MPI smoke
skipped outside a declared MPI environment.

PR #347 passed protected `portable-phase1` CI in 2m25s and squash-merged as
`f689b8f`. The first fleet-sync plan used stale ledger source `6349928` and
failed closed on AB before any node changed; exact readback established common
fleet source `5fcbfd36`. A corrected explicit eleven-target plan/apply advanced
ab, ab2, ri, al, rc, t4, abq, aist, home, office, and riken from that verified
ancestor to `f689b8f`; every head and `origin/main` matched the target and
every transfer artifact was absent after apply. Aist, Home, Office, and Riken
each returned exactly one context-refresh `status=submitted`, and the private
message was exact-unlinked.

Fresh interactive pseudo-terminal acceptance passed on Local and all eleven
remote checkouts: every transport succeeded, every Linux shell reported exact
`alias ls='ls --color=auto'`, every Mac reported exact
`alias ls='ls -G'`, and every `ls` emitted ANSI color. Local's live
supervisor-held `libexec/.nfs…` placeholder remained untouched throughout.

### T-319 — Report fleet health every Harness turn

**Phase:** complete.

The owner requires a fresh canonical fleet-health result in every Harness
turn's final response. Root `AGENTS.md` and the compact current-state contract
now require `harness fleet-health` immediately before yielding, explicit
reporting of failed or unknown checks, and no reuse of a prior turn's result.
The focused fleet-health suite and `git diff --check` pass.

**LIFO validation gate 2026-07-27:** the first complete eight-worker phase-one
run passed 73 focused suites; only tmux and terminfo failed because their apply
fixtures require a clean committed checkout and the primary checkout retains
the known live supervisor-held `libexec/.nfs…` placeholder. The placeholder
must remain untouched. Commit this evidence, run the unchanged complete suite
from a disposable clean full clone of the exact task revision, then
guarded-delete only that clone and exact-unlink its mode-0600 manifest after
successful verification.

**LIFO validation gate 2026-07-27:** the exact clean full clone at `1ddfd83`
made terminfo pass, but the eight-worker run still failed only tmux when its
apply preflight briefly observed a dirty checkout. After the runner exited,
the clone was clean with no tracked or untracked changes; the runner had
already removed its temporary detailed log. This is evidence of a transient
parallel validation interaction, not yet proof of its source. Preserve the
clone, commit this gate, fast-forward it to the checkpoint, run the tmux suite
alone, then run the complete phase-one suite with one focused worker to remove
cross-suite checkout-state concurrency from the acceptance result.

**LIFO validation gate resolved 2026-07-27:** the isolated tmux retry proved
the apparent transient-dirty hypothesis wrong. The managed shell had exported
`HARNESS_ROOT=/home/rioyokota/harness`, so the clean clone's helper inspected
the primary checkout and correctly rejected its preserved live `.nfs…`
placeholder. The clone remained clean throughout. Exact-unlink the single
mode-0600 trace, update the clone to this checkpoint, and rerun isolated plus
complete validation with `HARNESS_ROOT` absent from the test environment.

**Completion 2026-07-27:** the isolated tmux suite and complete eight-worker
phase-one suite pass from the clean exact clone with the inherited
`HARNESS_ROOT` removed; all 75 focused suites and integration gates passed,
with only the declared portable Codex and native MPI skips. Guarded deletion
removed the exact 944-entry / 23,224,109-byte validation clone and two empty
diagnostic probe directories, protected anchors were unchanged, and the exact
mode-0600 manifest was unlinked. Root instructions, the ledger, and focused
coverage now make a fresh canonical fleet-health result mandatory before every
Harness turn yields.

**Rollout 2026-07-27:** the first fleet-sync plan supplied ledger-only merge
`bdde90a` as its source and failed closed on AB before any node changed because
all remotes were still at exact T-318 merge `bd3f80f`. Corrected guarded
plan/apply transactions advanced all eleven clean remote checkouts from
`bd3f80f` to protected T-319 merge `5fcbfd3`; every transfer artifact is
absent. The required Aist, Home, Office, and Riken context refreshes each
returned exactly one `status=submitted`. Guarded deletion removed only the
925-entry / 23,133,602-byte sync clone with protected anchors unchanged, and
the private message plus exact mode-0600 deletion manifest were unlinked.

### T-318 — Recover poisoned remote Codex threads

**Phase:** complete.

The owner asked to extend T-310/T-317 transient-service resilience after exact
Local evidence exposed a second failure class: Swallow's remote TUI and shared
app server remained healthy, but six consecutive assistant-less turns
completed with `Request blocked`, and `thread/read` reported `systemError`.
Restarting only the TUI preserved the error. One exact app-server
`thread/rollback` of those six turns restored the prior 37-turn history and a
new diagnostic completed with an assistant response.

The bounded design is in
`docs/plans/t318-codex-thread-system-error-recovery.md`. Recovery is limited to
an exact remote thread whose status is `systemError` and whose logical rollout
tail contains only completed assistant-less turns with no tool, command, file,
web, or unknown event. Earlier rollback markers must be applied before
counting; more than eight turns, any active/incomplete turn, identity/path
drift, unsafe event, protocol ambiguity, or unrecognized schema fails closed.
The mechanism never replays the rejected prompt and never restarts the shared
app server.

Implementation used `/tmp/harness-t318-thread-recovery` on branch
`t318-codex-thread-recovery`. The primary checkout's two live
supervisor-held `.nfs…` inodes remained untouched.

Implementation checkpoint:

- Added dependency-free Python-3.6-compatible
  `harness codex-thread-recovery` plan, status, one-shot, and watch modes.
  The helper validates exact app-server identity, reconstructs logical rollout
  turns after durable rollback markers, serializes the final recheck against
  agent-message injection, caps rollback at eight safe turns, and treats a
  sent request without an unambiguous acknowledgement as non-retryable.
- Added deterministic safe, existing-marker, tool-bearing, unknown-event,
  active-turn, excessive-tail, session-identity, rollout-drift, idle-thread,
  and ambiguous-acknowledgement fixtures plus a real Unix-WebSocket fake
  app-server method-sequence test.
- Integrated one exact watcher only for `codex-resilient --remote-session`.
  A one-shot safety transaction and watcher-owned readiness receipt are
  required before TUI launch; supervisor cleanup signals and reaps only its
  exact child. Unsafe or unavailable recovery blocks before Codex launch.
  Status and plan output expose the value-free watcher contract.
- PR #338 passed protected CI and squash-merged as `5a73695`. Local and all
  eleven managed checkouts synchronized to that exact revision; the four Mac
  context refreshes each returned one acknowledged submission. Both disposable
  validation/sync clones were guarded-deleted and their exact manifests
  exact-unlinked.
- The durable-marker/aborted-turn correction passed protected CI in 2m24s and
  PR #339 squash-merged as `c47805a`. Local and all eleven managed checkouts
  synchronized to that revision, every transfer artifact was absent after
  apply, and the four required Mac refreshes again returned exactly one
  `status=submitted` each.

**Recurring Swallow incident 2026-07-27 15:45 JST:** exact read-only
`thread/read` again reports `systemError` for Swallow root
`019f9f69-6b94-70a3-be12-8bef23b88a96`, while its exact supervisor/TUI/app
server remain live at attempt/delay zero and native Codex doctor passes 18/18.
The watcher is not yet deployed. Its analyzer failed closed before reading the
tail because the rollout is mode `0664`. Metadata proves a current-user-owned,
single-link regular file whose group is the current user's private primary
group, with zero explicit members and one primary account.

The owner said `proceed`. An exact descriptor-identity transaction tightened
only that rollout from `0664` to `0600`. One recovery attempt then failed
closed as `unsafe-tail`; no rollback request was sent and it is not retryable
without new safety evidence. Value-free lifecycle analysis proved why:

- a durable six-turn rollback marker exists at rollout line 8411;
- a later explicit `turn_aborted` supersedes one incomplete turn;
- the latest completed turn contains many tool records and ends with an error.

Rollback would discard real project work, so the poisoned root remains intact.
A native remote fork `019fa265-a94d-72d3-ae88-aa1d610fed6c` initially read
`idle` with zero turns, but its first rejected cold-start turn was safely
rolled back once and exposed the inherited tool-bearing error. The watcher then
blocked it as `unsafe-tail`; no project action occurred and the fork remains
preserved rather than retried.

The published analyzer incorrectly evaluated superseded records before the
latest durable rollback marker and treated `turn_aborted` as unknown. The
current amendment uses the latest validated rollback marker as a hard history
boundary and recognizes only a matching aborted turn after it. Any later
overlap, mismatched turn identity, active tail, assistant/tool/unknown event,
or other existing refusal remains fail closed. Focused recovery/resilience,
Python compilation, and diff hygiene pass with new deterministic fixtures for
both exact protocol cases. The initial complete runs exposed only validation
environment gates: first an intentionally uncommitted checkout, then inherited
`HARNESS_ROOT=/home/rioyokota/harness` redirected a direct self-test to the
primary checkout's live `.nfs…` files. With the amendment committed and that
override removed, both focused configuration tests and the complete clean
eight-worker `tests/test-phase1.sh` pass; only native MPI is skipped outside a
declared MPI environment.

**Completion 2026-07-27:** the installed 0.145.0 protocol schema established
that a bare remote TUI does not persist a root before a first turn, while
`thread/start` creates an exact empty root. One acknowledged `thread/start`
with the frozen cwd/approval/sandbox settings created
`019fa27c-6280-7f00-8e46-ef878875562b`; one acknowledged name write and fresh
read proved `status=idle`, name `swallow`, cwd `/home/rioyokota/harness`, and
zero turns. Its single-link current-user rollout was descriptor-tightened from
`0664` to `0600` with stable identity. The generated schema bundle and sync
clone were guarded-deleted with protected anchors unchanged and exact
mode-0600 manifests exact-unlinked.

Only the inactive target chains/windows were stopped. The surviving owner
view stayed on Harness, Students was untouched, and the shared app server
remained PID `2852569` with the new TUI's exact Unix peer. Swallow is now only
window `@58:2` on supervisor `382132`, watcher `382211`, and exact remote root
`019fa27c-6280-7f00-8e46-ef878875562b`; status is
`running/remote-explicit` plus `watching/thread-active`, attempt/delay zero,
recoveries/rollbacks zero. One lock-serialized identified cold-start
instruction was submitted. Value-free rollout structure proves an active turn
with assistant messages and completed tool-call pairs, not an idle or poisoned
TUI. The Swallow agent owns all further SW-031 work from its repository ledger;
Harness must not replay the prompt or inspect pane content.

### T-316 — Map Local tmux to three phone-visible Codex roots

**Phase:** complete.

The owner renamed tmux window `@42` from `swallow` to `harness` and selected
the following exact mapping:

- existing phone Students root
  `019f7fea-4f00-7681-910d-81ae99a77143` remains tmux `students`;
- existing phone Swallow root
  `019f9f69-6b94-70a3-be12-8bef23b88a96` becomes a remote-backed tmux
  `swallow`;
- the current conversation is preserved as a forked, distinct phone-visible
  root and becomes remote-backed tmux `harness`.

Read-only discovery at 06:53 JST confirms the existing `students` client
remains connected through `--remote unix://` to app-server PID `2852569`.
Current `harness` still contains standalone real TUI PID `2727307`, launched
through ambiguous `resume --last`, and owns the Swallow rollout. The same
app server has that rollout open for phone Remote, but PID `2727307` has no
control-socket peer. Codex 0.145.0 officially supports both
`resume --remote unix:// SESSION_ID` and
`fork --remote unix:// SESSION_ID`; fork creates a new chat while preserving
the original transcript. `/rename` is the supported TUI command for assigning
the new chat a recognizable name.

No live client, process, app server, socket, tmux pane, saved thread, or
configuration changed during planning beyond the owner's window rename.
Branch `t316-local-three-thread-mapping` was created from clean aligned
revision `efd63bf`. The frozen execution, rollback, and acceptance gates are in
`docs/plans/t316-local-three-thread-mapping.md`. All required mapping decisions
are resolved.

**Execution authorization 2026-07-27 07:02 JST:** the owner gave the required
separate `go`. The complete instructions, board, and frozen plan were reread.
Authenticated fetch and read-only preflight find the task branch clean and
exactly aligned at pushed revision
`a5a94539d79e750b8a89f957702844fd1bf2b6f0`; the sole attached client remains
on exact `@42:harness`, and exact `@46:students` is unchanged. The recorded
process chains, current-user ownership, parent/session identities, executable
paths, argv, rollout descriptors, app-server PID `2852569`, Students control
socket peer, and both root rows all match the frozen state. Immutable Linux
start ticks are `82962590` for standalone real TUI PID `2727307`,
`83381863` for app-server PID `2852569`, and `83627668` for Students real TUI
PID `3025057`. Filtered native doctor overall status remains `ok`.

No client has yet been launched, renamed, signaled, or given input. Commit and
push this authorization checkpoint, rerun the complete assertion preflight
against the pushed revision, then create only provisional `harness-next`.

**Stage-1 preflight 2026-07-27 07:04 JST:** every fail-closed assertion passed
against pushed authorization revision
`dfbff56629f813d1a3e6a0c2211cab8a01c6e253`. Git, tmux topology, all seven
recorded processes and immutable start ticks, exact argv/executables, both
rollout descriptors, Students' Unix peer, the standalone client's lack of that
peer, both root rows, native doctor overall status, and all 18 doctor checks
match. The unchanged app-server socket inode is `165762130`. The pre-fork
thread index has 24 rows and maximum `created_at_ms=1785085914011`; require
exactly one attributable new root beyond this baseline. No target changed.
Commit and push this checkpoint, revalidate the narrow live identities, then
create `harness-next` once without a prompt.

**Stage-2 LIFO gate 2026-07-27:** the exact fork command ran once and created
provisional window `@47:harness-next`, wrapper PID `3184180`, real TUI PID
`3184653`, and exactly one new root
`019fa076-7132-7992-800e-f6c6d4aeadfb`. The first acceptance loop then timed
out only because it required the new client to share Students' accepted server
socket inode `165762130`. Each app-server client correctly has its own accepted
pair: app-server PID `2852569` owns inode `166156785` with peer `166153028`,
and new real TUI PID `3184653` owns the reciprocal peer. The app server also
owns the new rollout. Its first metadata record proves
`forked_from_id=019f9f69-6b94-70a3-be12-8bef23b88a96`, exact new ID, and
Harness cwd. Do not replay the fork.

A corrected full validator then stopped at its original-window active-selector
assertion. Immediate readback and an isolated byte-level comparison both show
unchanged exact `@42 harness 1 1`; the sole attached client, all three original
windows/process chains, the new window/process chain, and Git remain
unchanged. No input, rename, signal, or second launch occurred. The validation
retry is safe: consume a fresh selector snapshot, require the corrected
per-client socket pair and exact fork metadata, then proceed to `/rename` only
after every gate passes.

**Stage-2 fork acceptance 2026-07-27 07:08 JST:** the full-consuming retry
passed exact Git, tmux, original/new process, per-client socket, thread
cardinality, rollout ownership, fork metadata, and all doctor gates. Accepted
Harness root is `019fa076-7132-7992-800e-f6c6d4aeadfb`; accepted provisional
window/processes are `@47`, wrapper `3184180`, and real TUI `3184653` with
start tick `83855518`. Its app-server/client inode pair is
`166156785`/`166153028`. The original active window and every protected
identity remain unchanged. Commit and push this accepted identity, then send
the `/rename` interaction exactly once to pane `%47` and require persisted
thread name `harness` before creating Swallow.

**Stage-2 naming gate 2026-07-27:** the planned interaction was sent once to
exact pane `%47` with separate one-second paste/submit steps: `/rename`, then
`harness`. The ten-second persistence loop timed out with the new thread's
name still empty. It is unsafe to replay the input. Value-free log indexing
proves the TUI received key-handling activity but emitted zero
`thread/name/set`, name-update, session-renamed, empty-name, or `/rename`
markers. The accepted fork process, its reciprocal app-server socket, exact
root/rollout, original active window, and Git remain unchanged.

Do not read the pane or send another key. Inspect the installed official
app-server protocol for the exact native `thread/name/set` request. If it can
be invoked through the existing local authenticated control socket with exact
thread ID and readback, revise only the naming mechanism in the frozen plan
and checkpoint it before execution; otherwise leave the fork unnamed and stop
for owner direction. No Swallow client has been created.

**Stage-2 native naming discovery 2026-07-27:** the installed experimental
schema generator created private temporary bundle
`/tmp/t316-app-server-schema.BnxRrl` with 347 files, three directories, and
3,303,877 bytes. It proves exact method `thread/name/set`, required parameters
`threadId` and `name`, an empty success response, and the normal
initialize/initialized handshake. Preserve this directory for guarded cleanup.

A read-only attempt to use native `codex app-server proxy` for `initialize`
plus `thread/read(includeTurns=false)` exited zero but emitted no JSON records.
Its mode-0600 capture was exact-unlinked. The command proxies raw bytes to the
Unix WebSocket endpoint; it is not a JSONL bridge, so no read or name mutation
was proved and replaying the same request is not useful. The fork name remains
empty and every live identity is unchanged. Inspect installed WebSocket client
capability next; prove `thread/read` before revising or invoking the naming
request.

**Stage-2 native transport gate 2026-07-27:** read-only transport discovery
failed closed several times before reaching app-server JSON-RPC: a plain
`socketPath` option is discarded by Debian's installed `ws`; `ws+unix` at
both `/` and `/rpc` reset during upgrade; raw JSONL closed before an initialize
response; and an HTTP agent matching `ws://localhost/rpc` still reset while
advertising per-message compression. None sent `thread/name/set`.

Exact official `rust-v0.145.0` source at tag object
`1635de866c61d1b76e50b31928ee6d61482435a8` proves the Unix listener uses
`accept_async`; its test connects a Unix stream with
`client_async("ws://localhost/rpc", stream)`. Repeating that topology with a
Node HTTP agent bound to the private control socket and
`perMessageDeflate:false` passed `initialize`, `initialized`, and
`thread/read(includeTurns=false)`: exact root
`019fa076-7132-7992-800e-f6c6d4aeadfb`, zero turns, and a nonempty inherited
name classified as neither empty nor exact `harness`. The local SQLite
`threads.name` field remains NULL. The accepted fork, socket pair, original
clients, app server, tmux selection, and Git remain unchanged.

The frozen plan now replaces only the failed TUI naming mechanism with one
schema-defined WebSocket transaction: read exact root state, send one
`thread/name/set` for exact name `harness`, then read it back on the same
connection. Commit and push this amendment before the write. If the request
or response is ambiguous, do not retry; use read-only reconciliation and stop.
No Swallow client has been created.

**Stage-2 pre-write gate 2026-07-27 07:50 JST:** naming amendment commit
`58be67080838f31f137718a0ada727934c60c948` is pushed and the branch is
clean/aligned. Exact windows, all nine recorded process/start identities, both
accepted app-server socket pairs, 25-thread cardinality, all three rollout
descriptors, and filtered native doctor (`overall=ok`, 18/18 checks `ok`)
match. The sole mismatch is that tmux session `harness` reports
`session_attached=0` and `tmux list-clients` is empty; the frozen gate requires
exactly one attached client before a rename or launch. No
`thread/name/set`, new client, signal, pane input, or tmux mutation occurred.
The private schema bundle remains at
`/tmp/t316-app-server-schema.BnxRrl`. Reattach to the existing session without
restarting anything, then repeat the complete pre-write gate.

**Stage-2 LIFO gate 2026-07-27:** after the owner reattached one exact client
to `@42:harness`, the first repeat validator stopped at its initial Git check
because it compared HEAD to an incorrectly expanded form of the recorded short
commit ID. The actual clean, aligned revision is
`f77ac28ee59b05bc33f3afbae17fc3d950504143`; no later assertion, name request,
launch, signal, pane input, or tmux mutation ran. The retry is safe: commit and
push this failure checkpoint, substitute only Git's exact resolved revision,
then repeat the complete pre-write gate.

**Stage-2 LIFO gate 2026-07-27:** the corrected repeat passed Git, attachment,
all nine immutable process identities, both accepted socket pairs, and exact
thread cardinality/rows, then stopped in fork metadata because its `lsof -Fn`
parser required a bare rollout pathname. On this NFS home, `lsof` appends the
parenthesized mount source to each name record. Isolated readback proves the
first rollout record still has the exact accepted ID, parent, and cwd and
app-server PID `2852569` still owns all three expected rollouts. No name
request or target mutation ran. Commit and push this retry-safe checkpoint,
change only the ownership checks to full-consuming exact-path prefix matches,
then repeat the complete pre-write gate.

**Stage-2 pre-write acceptance 2026-07-27 07:49 JST:** the complete
full-consuming retry passed from pushed revision
`0032d12fe67699e9450836ab6a29872679b0a61d`. Exact attached client PID
`3283828` selects `@42:harness`; all nine recorded process/start/argv/executable
identities, both accepted app-server socket pairs, 25-thread cardinality, all
three thread rows, exact fork lineage, app-server rollout ownership, private
schema bundle, clean aligned Git, and redacted doctor 18/18 match. No target
mutation ran. Commit and push this acceptance checkpoint, recheck its narrow
live identities, then perform the one D-003 read-before/name-set/read-after
transaction.

**Stage-2 native naming result 2026-07-27:** pre-write checkpoint
`720548c5e2ace6f775b17057fba82f6ac834155d` was pushed, the narrow live
identities revalidated, and one D-003 WebSocket transaction ran. Its
read-before matched exact fork ID, zero turns, and a name other than
`harness`; exactly one `thread/name/set` was sent; the empty success response
was acknowledged; and same-connection read-after matched exact ID, zero turns,
and exact name `harness`. No retry path ran.

The first bounded SQLite check then left `threads.name` NULL, so execution
stopped before creating Swallow and used only read-only reconciliation. A
fresh, independent initialized WebSocket connection again returned exact
`harness`. Exact official `rust-v0.145.0` source shows the prior validation
assumption was wrong: `thread/name/set` routes through
`thread_processor.rs` to `thread-store/src/local/update_thread_metadata.rs`;
legacy threads update SQLite `title` and append
`$CODEX_HOME/session_index.jsonl`, while only paginated threads update SQLite
`name`. This accepted fork is `history_mode=legacy`, with exact
`title=harness`, `name=NULL`, and latest exact-ID session-index entry
`thread_name=harness`. The index is a current-user-owned, single-link regular
file; an added 0600 assertion failed only because the official append path
uses the process umask and the existing mode is 0664. No second name request,
new client, signal, pane input, or tmux mutation occurred.

Revise only Stage 2's persistence gate to require the version-correct legacy
surfaces, commit and push that evidence, then run the complete post-write
process/socket/thread/doctor/Git validation. No Swallow client has been
created.

**Stage-2 acceptance 2026-07-27:** the complete post-write validator passed
from pushed naming-result revision
`3283c7056fe9b613f07b602783ec1b7ecb81c7b5`. Exact attached client/window,
all nine protected process identities, both existing accepted socket pairs,
25-thread cardinality, exact legacy SQLite title, latest session-index name,
fresh-connection protocol read, fork lineage, all rollout owners, redacted
doctor 18/18, and clean aligned Git match. The single naming write is complete
and must never be replayed. Commit and push this acceptance, then create only
the Stage-3 detached `swallow` remote resume with no prompt or pane input.

**Stage-3 acceptance 2026-07-27:** one detached native remote resume created
exact `@48:swallow`, pane `%48`, wrapper PID `3323024` start tick `84158638`,
and real TUI PID `3323133` start tick `84158671`, with exact Swallow UUID
argv. Its unique accepted app-server/client inode pair is
`166524532`/`166522667`. Full validation passed all four tmux windows, all
eleven protected/new process identities, all three accepted socket pairs,
unchanged 25-thread cardinality and three unarchived target roots, exact
Harness persistence, app-server rollout ownership, redacted doctor 18/18, and
clean aligned Git. The owner remained on `@42:harness`; no prompt or pane
input was sent. Commit and push this checkpoint, then execute only the Stage-4
exact window renames and client switch. Do not signal the old standalone
process in this thread.

**Stage-4 cutover checkpoint 2026-07-27:** pushed Stage-3 revision
`a2970c1c3ec85b482c3ae40721977a2707641df6` passed narrow preflight. Exact
`@42` was renamed once to `harness-stale`, exact `@47` was renamed once from
`harness-next` to `harness`, and sole client `/dev/pts/0` switched to `@47`;
the immediate exact postcheck passed. Before the independent validator ran,
the same terminal client had returned to `@42`. Cause is unknown without
prohibited pane inspection; do not infer a process failure.

The two new names remain exact. Independent non-selector validation passes
all five key immutable real-process identities, the three accepted app-server
socket pairs, unchanged 25-thread cardinality, exact persisted Harness name,
redacted doctor 18/18, and clean aligned Git. No process changed, no signal or
pane input ran, and the old standalone chain remains intact in inactive-named
window `@42:harness-stale` while the client is presently viewing it.

Commit and push this checkpoint first. Then revalidate exact client/window and
remote-process/socket identities and switch `/dev/pts/0` once more to exact
`@47:harness` as the final old-thread action. After the owner sends `continue`
in that new Harness root, Stage 5 must verify all three remote clients and
retire only old real TUI PID `2727307` by its recorded immutable identity.
Preserve private schema bundle `/tmp/t316-app-server-schema.BnxRrl` for
guarded cleanup in Stage 5.

**Stage-4 final switch 2026-07-27:** cutover checkpoint
`7c851ea8390a3a4153014ac6990f55e37a9b1c5b` was pushed first. Exact Git,
four-window mapping, five key process/start identities, and all three accepted
socket pairs revalidated. One final reversible
`tmux switch-client -c /dev/pts/0 -t @47` then passed exact readback:
`/dev/pts/0` is attached to `@47:harness`, new Harness root is
`019fa076-7132-7992-800e-f6c6d4aeadfb`, `@46:students` and `@48:swallow`
remain remote-backed, and inactive `@42:harness-stale` retains the old
standalone chain. No pane input or signal ran.

Commit and push this final Stage-4 checkpoint from the old driver, then yield.
The owner's next instruction in the new Harness thread is `continue`; that
agent must reconcile this ledger before performing Stage 5.

**Stage-5 attachment gate 2026-07-27 08:07 JST:** the owner continued from
the exact new Harness root, and read-only reconciliation found pushed clean
revision `ddc6562447aacb6ca0909aec017c7c1ab68d12e1`, exact selected
`@47:harness`, intact remote real TUIs `3025057`, `3184653`, and `3323133`
with their accepted reciprocal app-server socket pairs, unchanged app-server
PID `2852569`, and intact old standalone real TUI PID `2727307` with start
tick `82962590` in inactive `@42:harness-stale`. The tmux session has
`session_attached=0` and no clients, so the frozen Stage-5 precondition is not
satisfied. No signal, pane input, launch, rename, window removal, saved-thread
mutation, or private-schema cleanup ran. Reattach one client to the existing
session on exact `@47:harness`, then repeat the complete Stage-5 validator;
the signal remains safe to attempt exactly once only after that gate passes.

**Stage-5 LIFO gate 2026-07-27 08:10 JST:** after the owner reattached exact
`/dev/pts/0` to `@47:harness`, the full pre-signal validator exited before its
signal marker because its first socket assertion misspelled exact client inode
`165756871` as regex `166?756871`. Immediate readback proves old real TUI PID
`2727307` still has exact parent/session/start/argv identity, all three
accepted socket pairs are unchanged, the client remains attached to
`@47:harness`, doctor is wholly `ok`, and Git is clean/aligned. No signal or
target mutation ran. Commit and push this checkpoint, replace only the typo
with exact `165756871`, then repeat the complete pre-signal validator.

**Stage-5 stale-chain result 2026-07-27 08:11 JST:** pushed retry checkpoint
`354deb4d42f48387d6f654a2867723ef4d948847` passed the corrected complete
pre-signal validator. Exactly one `SIGTERM` was sent to immutable old real TUI
PID `2727307` at `2026-07-27T08:11:20+0900`; it exited within the bounded
wait. Wrapper PID `2727170` and `swallow-research` supervisor PID `2345899`
then exited without respawn. No `resume --last` or `swallow-research` process
remains. Exact inactive `@42:harness-stale` now contains only original idle
shell PID `1963022`; the owner remains attached to exact `@47:harness`.
Commit and push this result, revalidate the three remote clients and absent
old chain, then remove only exact stale window `@42`. Do not send another
signal.

**Stage-5 completion 2026-07-27:** exact stale window `@42` was removed after
pushed retirement checkpoint `0282d40`. Tmux now contains exactly
`@47:harness`, `@46:students`, and `@48:swallow`; the sole attached client is
on `@47:harness`. All three real TUIs retain their exact root argv and
reciprocal peers to unchanged app-server PID `2852569`. The Harness root
remains exact `019fa076-7132-7992-800e-f6c6d4aeadfb`, legacy title
`harness`, unarchived, and distinct from exact Students and Swallow roots.
Thread cardinality remains 25, doctor is wholly `ok`, and the old standalone
chain is absent without respawn.

The `guarded-bulk-delete` workflow removed only private schema bundle
`/tmp/t316-app-server-schema.BnxRrl` from retained boundary `/tmp`: manifest
`/tmp/t316-schema-cleanup.manifest`, token
`7f96556d129e211aa6944fd4d9a6dfbc59bafeaef3a08d1540b38ab5d52e6c6f`,
350 entries, 3,332,549 bytes, protected anchors unchanged, target verified
absent. The single exact mode-600 manifest was then unlinked. Validation:
`tests/test-codex-resilient.sh` passed; `tests/test-phase1.sh` passed with its
documented native MPI smoke skip outside a declared MPI environment;
`git diff --check` passed; canonical fleet health passed all managed Linux
logical nodes and all four Mac route pairs. No pane content, credential,
connector, plugin, setting, saved-thread archive/delete, or unrelated
repository changed. One read-only Stage-5 diagnostic mistakenly selected and
displayed the three stored thread `title` fields despite the plan's
metadata-only output restriction; it was not repeated, and no pane content or
transcript payload was modified.

### T-315 — Restore one-to-one Local Codex thread mapping

**Phase:** complete.

The owner reported different agents in Local tmux and phone Remote immediately
after T-314. Metadata-only inspection, without reading pane contents, found one
attached tmux session with `students` and `swallow` windows. The `harness`
supervisor is configured `--last`; `swallow-research` was originally
`--new`, but its recovery path also runs `resume --last`. After T-314's forced
shutdown, both replacement real TUI processes `2727306` and `2727307` opened
the same saved root thread
`019f9f69-6b94-70a3-be12-8bef23b88a96`. This violates T-310's explicit
precondition that `--last` is deterministic only when no competing Codex
session exists in the selected scope.

The phone-side managed app server is the separate healthy process pair
`2852494`/`2852569`. Neither tmux command includes `--remote`, and socket
metadata shows no TUI connection to the managed control socket. During the
diagnostic turn, the tmux `swallow` TUI executed this task while the app server
simultaneously owned a different live agent command rooted in the separate
Students repository. This is not a same-worktree collision, but it proves the
phone and terminal are controlling distinct clients. Value-free log indexing
maps the app server's active root to
`019f7fea-4f00-7681-910d-81ae99a77143`, while this tmux `swallow` turn is
root `019f9f69-6b94-70a3-be12-8bef23b88a96`; the app server also has the
first root's `Archimedes` subagent open. Remote can therefore legitimately
show a different chat or agent.

No process, tmux session, thread, app-server state, prompt, or repository was
changed during diagnosis. Do not type into both duplicate tmux clients
concurrently. Before repair, the owner must select which saved thread belongs
in each tmux window and whether terminal TUIs should remain independent clients
or connect to the managed app server. If a later restart is allowed, the narrow
default is to preserve independent clients but relaunch each supervisor only
once with an explicit `--session ID`.

**No-restart plan:** Codex 0.145.0 supports both an in-process `/resume` picker
and a TUI connected to the existing app server through
`codex resume --remote unix:// SESSION_ID`. In-process `/resume` is rejected
for this repair: it would point the old tmux client at the same saved rollout
but leave it independent of phone Remote, retain the supervisor's ambiguous
`--last` recovery, and permit divergent simultaneous turns.

The recommended bounded repair restarts nothing. Preserve every current PID;
rename only the existing `students` tmux window to `students-stale`; create one
new detached `students` window whose TUI connects to the already-running
managed Unix-socket app server and resumes exact Students root
`019f7fea-4f00-7681-910d-81ae99a77143`. Do not switch the owner's active
window. Accept only if all pre-existing PIDs remain unchanged, the new TUI has
an established socket connection to app-server PID `2852569`, and the phone's
Students root remains active. Validate through process, socket, thread-index,
tmux, doctor, and repository metadata only; never read either pane.

Rollback is to remove only the newly created window/process and restore the old
window name; no existing process would be signaled. This provides a live
terminal view of the same app-server thread as phone Remote, but it does not
make the old `--last` supervisors durable. A later planned restart or
supervisor enhancement must bind explicit IDs before another recovery.

**Decision D-001:** recommended is the new remote-backed `students` window
above. Alternative is no live change: keep using phone Remote for Students and
the tmux `swallow` window for SW-031 until a future restart can repair the
supervisors. The owner selected the recommended repair with explicit `go` on
2026-07-27. Git preflight at 06:17 JST found the task branch clean and exactly
aligned with its upstream at `e673ad1`; tmux still has one attached `harness`
session with inactive `students` window 0 and active `swallow` window 2. No
tmux input or process launch preceded this checkpoint. The exact first
execution step is to commit and push this authorization, then revalidate every
recorded PID, app-server identity, socket, thread root, and active-window
selector immediately before renaming only window 0.

**LIFO execution gate 2026-07-27:** the first full preflight stopped before
either tmux mutation because one fixed-string rollout-suffix probe omitted
grep's `--`; its leading hyphen was parsed as an option and the command exited
2. Immediate readback proves the original `students` and `swallow` windows,
active `swallow` client selection, all nine protected PIDs, and clean aligned
Git state are unchanged. The attempt is retry-safe. Add only the missing `--`
to that probe and repeat every identity and health check before the rename.

**LIFO execution gate 2026-07-27:** the corrected full preflight passed, window
0 was renamed, and one detached remote TUI was launched. An added acceptance
loop then timed out because it incorrectly required that remote client to own
the app server's rollout file and emit thread-scoped log rows. The value-free
log index instead records temporary TUI PID `3007213` with only client-local,
threadless TUI rows, consistent with the documented remote-client/app-server
split. The planned rollback removed that temporary window/process and restored
the original name; readback again proves the nine protected PIDs and active
`swallow` selection unchanged. Socket acceptance was not durably captured and
remains unknown. Retry the frozen plan with stage-labelled checks, requiring
the new client's exact target-thread argv and established control-socket
connection while retaining rollout/thread ownership checks on app-server PID
`2852569`, where they belong.

**Execution result 2026-07-27 06:27 JST:** the corrected frozen repair passed.
Existing window 0 is now `students-stale` with unchanged pane/supervisor PID
`3837157`. New detached window 1 is `students`, with wrapper PID `3024942`
and real TUI PID `3025057`; its exact argv resumes
`019f7fea-4f00-7681-910d-81ae99a77143` through `--remote unix://`. Socket
metadata proves its established Unix peer matches the unchanged control-socket
endpoint on app-server PID `2852569`. That server still owns the Students
rollout and has current thread-scoped rows; filtered doctor remains wholly
`ok`. Every pre-existing protected PID is live with its original start time,
and the sole attached tmux client remained on active `2:swallow`. No existing
process was signaled, restarted, or given input. Finish independent
process/socket/tmux/doctor/Git validation, then run canonical fleet health.

**LIFO validation gate 2026-07-27:** the first final-validation wrapper exited
141 before fleet health because its socket parser deliberately stopped after
one record while shell `pipefail` treated the upstream `ss` SIGPIPE as an
error. This did not mutate tmux or any process. Immediate readback proves the
three-window repair, active `swallow` selection, all protected and new PIDs,
and clean aligned Git state remain stable. Make the parser consume all socket
rows, repeat the complete independent validation, and invoke fleet health only
after it passes.

**Completion:** the full-consuming retry passed every independent gate. Exact
process argv, start-time, tmux, Unix peer-inode, app-server rollout, thread
index, redacted doctor, supervisor-status, and Git checks all passed while the
remote-backed window remained live. `tests/test-codex-login.sh` and
`tests/test-codex-resilient.sh` pass. Canonical fleet health reports Local and
all seven remote Linux logical nodes ready—including both ABQ routes—and all
four Mac route pairs at 2/2. No existing process was signaled or restarted,
and no pane received input.

The active view after the initial repair was one-to-one: `1:students` is the
app-server-backed Students root used by phone Remote, and `2:swallow` remains
the independent SW-031 client. `0:students-stale` deliberately preserves the
old duplicate client for rollback evidence but must not receive input. The
owner-authorized cleanup below subsequently removed that stale client and
window. The live repair does not change the remaining `swallow-research`
supervisor's ambiguous recovery selector. Before any future TUI restart or
recovery, freeze and implement its explicit thread ID; do not claim recurrence
is impossible until that separate durability step is complete.

**Post-completion cleanup 2026-07-27:** the owner explicitly requested deletion
of both the `students-stale` Codex session and its tmux window. Read-only
preflight at 06:35 JST proves there is no independently deletable saved session
behind that name: stale real TUI PID `2727306` and active `swallow` PID
`2727307` both own saved root
`019f9f69-6b94-70a3-be12-8bef23b88a96`. Native `codex delete` permanently
deletes a saved session, so invoking it would delete the active SW-031 thread,
including this turn. It is excluded.

Interpret the authorized cleanup narrowly: require the sole attached client to
remain outside exact window `@0`, revalidate window 0's exact pane/supervisor
and child identities plus both surviving windows, then run native
`tmux kill-window -t @0` once. This terminates only the stale live supervisor
and TUI chain while removing its tmux window; it preserves the shared saved
thread. Accept only if window `@0` and PIDs `3837157`, `2727171`, and `2727306`
are absent, `1:students` remains connected to unchanged app-server PID
`2852569`, active `2:swallow` and its process chain remain unchanged, doctor
passes, and Git is clean. Never invoke `codex delete` for the shared UUID.

**LIFO cleanup gate 2026-07-27:** the first deletion preflight failed before
`tmux kill-window` because it added an exact managed-wrapper PID check and
wrapper `2852494` had exited since the prior checkpoint. Immediate readback
proves window `@0`, its three target PIDs, both surviving windows, and every
TUI remain unchanged. Real app-server PID `2852569` retains its exact
05:46:46 start, argv, control-socket listener and established Students peer;
it is now reparented to PID 1 and redacted doctor remains `ok`. The retry is
safe. Re-run the complete preflight against the real server identity required
by the frozen acceptance gate, without requiring the transient wrapper.

**LIFO cleanup gate 2026-07-27:** corrected preflight passed and native
`tmux kill-window -t @0` removed the exact stale window, but its process chain
did not receive a terminating signal and remained live beyond the bounded
20-second wait. The command stopped without escalation. The sole attached
client stayed on `swallow`; `students`, `swallow`, their process chains, and
the app server are unchanged. The three stale processes now share exact
session/process group `3837157` and only deleted PTY `/dev/pts/8`.

Do not signal the whole group. Revalidate real TUI PID `2727306`, its exact
start/argv/parentage, shared rollout, and the surviving topology, then send one
`SIGTERM` only to that real TUI. The managed arg0 launcher will retain its
normal postflight path and propagate status 143; the resilience supervisor
classifies that as an operator stop rather than restarting. Wait up to
20 seconds for all three exact stale PIDs to disappear and require their arg0
lock to be released. No `SIGKILL`, second signal, process-group signal, or
saved-session deletion is authorized; stop if the exact chain remains.

**LIFO cleanup result 2026-07-27:** every corrected identity gate passed and
one `SIGTERM` was sent only to real stale TUI PID `2727306`. The real TUI,
managed arg0 wrapper PID `2727171`, and resilience supervisor PID `3837157`
all exited within the bounded wait, with no respawn. No second signal was sent.
The postflight wrapper then exited 1 only because it required supervisor phase
`stopped`; actual value-free status is the safe
`phase=stale owner_pid=none reason=owner-absent`. Window `@0` remains absent,
the sole attached client remains on `swallow`, both surviving windows and all
their PIDs are unchanged, the Students control-socket peer and app server are
healthy, and redacted doctor is `ok`.

Arg0 planning reports `live=4 eligible=0 young=2 unexpected=0`; the terminated
process released its lock, and no housekeeping deletion is eligible or
authorized. Treat the stale value-free supervisor state as accurate residue
from removing its tmux owner, not as a live Codex session. Run independent
final topology/socket/thread/doctor/Git validation and canonical fleet health,
then close this cleanup. Permanent `codex delete` remains excluded because the
saved UUID is the active SW-031 thread.

**Cleanup completion:** exact window `@0` and stale PIDs `3837157`, `2727171`,
and `2727306` are absent. Native tmux removal ran once; after tmux left the
process chain detached, one exact leaf `SIGTERM` let the managed launcher and
supervisor unwind without respawn. No second signal, `SIGKILL`, process-group
signal, pane input, or permanent `codex delete` occurred. Saved SW-031 root
`019f9f69-6b94-70a3-be12-8bef23b88a96` remains unarchived and active in
`swallow`; deleting it would not have been a stale-only operation.

Independent final validation finds only the intended `students` and `swallow`
windows, with the sole attached client still on `swallow`; the remote-backed
Students peer, real app server, thread index, and redacted doctor pass. The
removed supervisor's value-free residue correctly reports
`phase=stale owner_pid=none`; it is not a live process. Arg0 planning reports
`eligible=0 young=3 unexpected=0 removed=0`, so no cleanup ran. Focused
resilience validation passes, Git is clean/aligned, and canonical fleet health
passes Local, all seven remote Linux logical nodes including both ABQ routes,
and all four Mac route pairs at 2/2.

### T-314 — Recover Local Slack connector availability

**Phase:** complete.

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

**Decision D-003:** selected by owner `Go`. The bounded path is to arm a
detached exact-identity helper before signaling; it sends one second
`SIGTERM`, never `SIGKILL`, waits up to ten seconds for the exact old identity
to disappear, then invokes native managed start once and verifies the managed
PID, redacted doctor, and both TUIs. The owner then gave the separately
required execution `Go`. No second signal or native start preceded this
checkpoint. Push it in Harness and Swallow before preparing the gated helper.

The first arm preflight rejected an incorrectly expanded authorization commit
SHA before launching the helper; it made no change. The unchanged helper then
passed corrected preflight, exact-unlinked itself, and armed as PID `2711446`
at 2026-07-27 04:33:42 JST. Gate `/tmp/t314-d003-gate.fHfr6Q` is the original
current-user mode-0600 inode `2050:8389271`, so the helper is inert. Result,
native-start, and redacted-doctor files are
`/tmp/t314-d003-result.CKPSpM`, `/tmp/t314-d003-start.knkAbQ`, and
`/tmp/t314-d003-doctor.OGZlx4`. Push this armed checkpoint before changing only
the gate mode to `400`; on reconnect, inspect the result and never replay the
gate release or either signal.

**D-003 execution result:** the exact gate changed once from mode `600` to
`400` at 04:36:35 JST. The helper passed every frozen identity check and sent
the separately authorized second `SIGTERM` once to PID `3676694`. Its
ten-second wait ended at `waiting_for_forced_exit`, so it failed closed before
native start. The old server and both original TUI children subsequently
exited; the two unchanged resilience supervisors replaced only their TUI
children at 04:36:53. No prompt was replayed.

At 05:46:46 JST, readback proved that the helper had exited without starting a
server and that the old PID was absent, so the already-authorized native
`codex remote-control start --json` was invoked exactly once. It succeeded
with managed wrapper PID `2852494` and one real Codex 0.145.0 app-server child,
PID `2852569`. The PID record matches the wrapper start time; exactly one real
app server is present; filtered doctor is `ok`; both supervisors and their
replacement TUI chains remain live. A post-success verifier exited nonzero
only because it expected the PID record to name `codex.real` rather than the
native shell wrapper. Start was not retried.

**Slack acceptance turn 1:** the enabled Slack plugin remains at revision
`11c74d6b`. This chat listed `RioYokotaLab` (`T1251HXB4`), resolved public
`#swallow` (`C058CUU8HK8`), and returned 20 bounded `Qwen3` results from that
channel. No Slack write occurred. The separate-turn `Megatron` search remains
the only connector acceptance gate before T-314 can close.

**Completion:** on the next turn, the unchanged connector returned 20 bounded
`Megatron` results from the same `#swallow` channel. This supports the narrow
causal conclusion that the controlled app-server refresh repaired the observed
tool-registration state; it is not a general Codex guarantee. No plugin,
setting, pairing, credential, or Slack state changed. The four reviewed D-003
temporary evidence files were exact-unlinked only after both repositories had
the recovery evidence, and their absence was verified. Resume SW-031 without
another restart or reinstall.

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

**Phase:** complete.

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

**Decision D-007 frozen 2026-07-27:** the owner accepted the recommended
supported Codex user layer. Harness retains project-scoped instructions,
permissions, rules, and skills, while `~/.codex/config.toml` is opaque
product-owned state. Accept only absence or a mode-0600, current-user-owned,
single-link regular file; reject unsafe metadata without reading content.
Never parse, copy, hash, remove, restore, or write the file, and never stop or
reload Codex. Value-free metadata confirms the six present files on Local, T4,
Aist, Home, Office, and Riken already satisfy this contract; the other six
nodes are absent. The frozen plan, risks, tests, and acceptance criteria are in
`docs/plans/t311-codex-user-config-policy.md`. Implementation is isolated at
`/tmp/harness-t311-user-config/repo` on branch
`codex/t311-product-owned-user-config`; Local's live `.nfs…` placeholder
remains untouched.

**D-007 implementation checkpoint 2026-07-27:** the schema-2 engine now emits
a value-free `preserve` record and contains no product-file content parser,
backup, removal, restore, or write path. Focused apply/rollback/drill tests
preserve arbitrary opaque bytes, accept absence, do not recreate a file Codex
removed, prove no product backup exists, and reject broader mode, symlink, and
hard-link states. Shell syntax, warning-level ShellCheck, agent-config,
fleet-controller, source-contract, repository-independence, external-user,
Claude-takeover, and diff-hygiene checks pass. This checkpoint was committed as
`1759b8a`; complete clean-tree validation follows below.

**D-007 validation checkpoint 2026-07-27:** clean implementation commit
`1759b8a` passed the complete eight-worker `tests/test-phase1.sh`: all 75
focused suites and integration gates passed, with only the declared native-MPI
smoke skipped outside a declared MPI environment.

**D-007 completion 2026-07-27:** PR #349 passed protected
`portable-phase1` in 2m19s and squash-merged as `6dfe35d`. Guarded explicit
eleven-target synchronization advanced every clean remote checkout from
`a4b1e59` to that revision; every head and origin matched and every transfer
artifact was absent. Aist, Home, Office, and Riken each returned exactly one
context-refresh `status=submitted`, and the private message was exact-unlinked.

All eleven remote value-free doctors passed: T4 and the four Macs reported
`product-owned:none`, while AB, AB2, RI, AL, RC, and ABQ reported
`absent:none`. Local's first clean-clone doctor correctly found the product
path ready but rejected three managed links whose absolute targets name the
live checkout. Two exact-exclude attempts, a disabled user-namespace preflight,
and an alternate-index preflight each failed before a doctor could run; all
temporary files were exact-unlinked and no retry changed live state. A
disposable native-Git validation view finally presented the clean exact tree
at the live worktree identity without changing its index or files. Local then
reported `product-owned:none` and doctor `status=ready failures=0`. No product
configuration bytes, credentials, live configuration, active process, or
Local's supervisor-held `.nfs…` inode changed. T-311 has no remaining action.

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

**LIFO gate resolved 2026-07-27:** Aist, Home, Office, and Riken's
owner-authenticated helpers completed one Mac at a time with exact
on/on/on/on/off readback. Independent plans re-read all five values, canonical
fleet health proved both routes for every Mac, and every exact checksum-matched
helper was unlinked and verified absent. Final value-free doctors report
`status=ready failures=0 warnings=0` on all four Macs, including enabled
firewall/stealth/signed access and disabled block-all. The administrator-
authentication gate is complete; the separate Codex user-config policy choice
below remains.

**Post-closeout route observation 2026-07-27:** the first canonical health
check after PR #345 briefly found Riken primary down while secondary remained
ready. Both tunnel supervisors were still managed/running; the watchdog's
latest prior run reported `invariant-failed`. Before the bounded
`connection-monitor --once --recover` reached Riken, the primary route had
already returned, so the monitor reported both ready with `action=none`; it
performed no Riken recovery. A fresh canonical check then passed all Linux
nodes and all four Mac route pairs. The evidence does not establish firewall
causation, an authentication failure, or a persistent route defect.

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

**Next action:** implement, validate, publish, and roll out D-007, then continue
the independently time-gated backup checkpoints.
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

**Phase:** blocked on external server administrator access.

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

At 2026-07-27 19:58 JST, Local resolved `nas-03.yokota` to
`192.168.33.30` and found a direct SSH route as `rioyokota`, but the first
batch-mode connection stopped at host-key verification before authentication.
Neither the IP address nor hostname has a saved Local host-key entry. SSH
negotiation and an independent key scan consistently observed ED25519
fingerprint `SHA256:nxj4PfZ55OqTcVm5HReHI6IVy9MMcBQ+BbfrJfZRHes`; that
agreement does not establish identity. Independently confirm the fingerprint
through the server console or its administrator, then add only that confirmed
key and run the bounded read-only procedure recorded in the audit. Do not use
`StrictHostKeyChecking=no`, accept a key based only on this network path,
escalate privilege, or change NFS/storage state.

At 2026-07-27 20:10 JST, bounded service discovery found only SSH reachable
among ports 22, 80, and 443. The public banner identifies Ubuntu OpenSSH
`9.6p1 Ubuntu-3ubuntu13.18`; there is no observed browser-management route.
Exact hostname/IP lookups found no historical `known_hosts` record on Local or
any of the twelve other managed SSH routes. No login was attempted. The owner
has never logged in to this server, so first establish who installed or
currently administers it, or obtain its physical/virtual Ubuntu console. That
trusted path must confirm the recorded ED25519 fingerprint and the intended
login account before Local attempts SSH.

The owner then confirmed having no access to the machine. T-303 is blocked
rather than complete because server-side correlation remains unavailable.
Do not retry SSH, guess credentials, recover an account, or alter the NFS
client mounts. Resume only when the owner identifies the responsible
administrator or obtains a trusted physical/hypervisor console; the first
action remains independent confirmation of both the recorded fingerprint and
the intended login account.

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

**Status:** time-gated. All eight nodes are at 2/8 successful weekly chains.
Execution requires eight successful chains, two verified restores per node,
and a current independent generation.

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

**2026-07-27 read-only retry:** exact RI accounting command
`sacct -n -X -j 7242 --format=JobIDRaw,JobName,User,State,ExitCode,Start,End`
again failed before job lookup because Slurm could not resolve its DNS SRV
configuration source. It printed no job data, and no scheduler state changed.
Keep the observation open for exact ID `7242`; successor `10386` remains
untouched.

**2026-07-27 AL checkpoint:** exact job `4238363` matched
`hal2607260100` and completed with `0:0`. Private state is active/success with
a present 64-hex snapshot, warning output is silent, and exact successor
`4275926` (`hal2608020100`) is pending for 2026-08-02 01:00 Europe/Zurich.
AL is now 2/8. No scheduler or backup state changed.

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

- **T-317:** the owner ended the scheduled 12-hour run early at 15:13 JST
  after remote-aware Codex supervision, bounded fleet/repository housekeeping,
  dependency maintenance, backup verification, and project-ledger separation
  were complete. Students and Swallow remain independently owned. The early
  readback found all three exact remote supervisors running, Codex doctor
  18/18, Local arg0 with zero eligible/unexpected residue, every managed route
  healthy, all four Mac doctors ready with only the two known firewall
  warnings, and all eight future backup chains present with primary access
  passing. The detailed evidence and deferred authority gates remain in
  `docs/audits/t317-fleet-housekeeping-2026-07-27.md`. The complete clean
  Phase-1 suite passed at `d9bf212`; guarded deletion then removed its exact
  4,168-entry / 47,314,593-byte validation clone and the mode-0600 manifest
  was exact-unlinked. Protected publication is PR #337.
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
