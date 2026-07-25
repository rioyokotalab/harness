# Personal harness task board

This is the authoritative resume point for the portable Codex and Claude
harness. Keep only current state, active decisions and gates, exact next
actions, and compact completion pointers here. Git history and the linked audit
documents retain completed execution detail.

Next free ID: T-312.

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
  housekeeping remain installed. Its rollback is
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
- Closed non-goals remain plugins/connectors/accounts, administrator settings,
  automatic publication, background login mutation, active-session reload,
  and guessing lost unknown configuration.
- Project safety and collaboration rules in root `AGENTS.md` remain
  authoritative. `.codex/AGENTS.md` is only the out-of-project launch
  sentinel. Never inspect credentials or use raw recursive/bulk deletion.
- Whenever owner input or approval is requested, or a task completes, report a
  fresh compact health snapshot for every managed Linux node and all four Mac
  route pairs. Count abq as Linux and mark it ready only when both abq and abq2
  routes pass; do not include that pair in the Mac total. Omit `abci_login` and
  `alps_login` unless a task targets those transports.

## Next resume checkpoint

1. Resume T-311 at decision D-001; no hardening mutation is authorized before
   the interview completes and the owner gives explicit `go`.
2. Resume T-310 closeout only through its isolated branch and existing CI
   blocker; do not create another push-only retry.
3. Resume T-309 by adding failing command-contract fixtures for the canonical
   fleet-health probe.
4. On or after 2026-07-26, query only the seven T-196 successor job IDs below.

## Active tasks

### T-311 — Harden the fleet and independent project repositories

**Phase:** executing after explicit owner `go`.

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

**LIFO gate active 2026-07-26:** the known off/off Mac firewall and stealth
posture is not represented in `macos-inventory` or `macos-doctor`, so routine
readiness can report zero warnings while D-003 remains unresolved. Add only
value-minimized enabled/disabled/unavailable facts, warn rather than fail while
administrator action is deferred, cover parsing and malformed facts, and
validate on all four Macs. Continue safe Harness work below the administrator
gate.

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
SHA-256 is `536627e7068c036ae36c246b0f93e0c5267ff15e3e42658efb6a5f89a2cf6706`.
It enables signed and built-in access before the firewall and stealth mode,
validates on/on, and offers an explicit off/off rollback. Administrator
authentication is the only remaining gate; do not bypass it, and exact-unlink
each helper after successful execution and route validation. Continue the
other independent stacks.

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

**Next action:** add value-minimized Mac firewall/stealth visibility while the
administrator-authentication helper remains deferred. Students T-004, Website
T-207, and Swallow SW-018 are independently closed; continue any newly
discovered repository-local stack without waiting on another repository.

### T-310 — Make Codex resilient to transient service failures

**Phase:** validating; implementation complete locally.

Implement a portable foreground `harness codex-resilient` supervisor for the
existing tmux topology. It must launch through `bin/harness-codex`, recover
only by resuming a saved chat without a prompt, gate retries with Codex's
redacted native doctor, and use bounded exponential backoff with jitter. Exit
0, operator signals, and local authentication/configuration/installation/state
failures stop rather than loop. Runtime state must be value-free, mode 0600,
atomically replaced, exclusively owned, and contain no captured terminal or
diagnostic output.

Support fresh, repository-most-recent, globally-most-recent, and explicit
session selection. Explicit IDs are preferred; `--last` requires the existing
one-active-Codex-per-checkout contract. Keep the process in the foreground and
install no service or owner configuration. Do not interrupt or replace any
currently running Codex during rollout; adopt it at the next deliberate tmux
restart.

The complete frozen plan, risk boundaries, rollback, and acceptance gates are
in `docs/plans/t310-codex-service-resilience.md`. Work is isolated on
`task/t-310-codex-resilience` from clean/current `c9926be`.

The portable foreground supervisor, CLI route, owner documentation, durable
no-replay rule, and reboot-recovery integration are implemented. Focused
fixtures pass fresh/repository/global/explicit selection, resume-without-prompt,
native-doctor gating, authentication and usage-error stops, terminal signals,
15–300-second backoff, 15-minute reset, bounded Darwin paths, live/stale lock
ownership, safe status, and value-free mode-0600 state. The updated
reboot-recovery skill validates and its focused suite accepts both legacy Codex
and supervised backoff panes. Shell syntax, warning-level ShellCheck, and
`git diff --check` pass.

Next run the complete phase-one suite, independently inspect the final diff,
fetch/integrate current `origin/main`, commit and publish through protected CI,
then guarded-sync clean managed checkouts. Do not interrupt active Codex
processes; the standard supervisor takes effect at each next deliberate tmux
creation.

The first complete-suite attempt from the isolated linked worktree is not
authoritative: five legacy fixtures require `.git` to be a directory and
rejected the worktree's normal `.git` file; two existing parallel macOS timing
fixtures also failed. The new supervisor suite and reboot-recovery suite both
passed in that run. Retry is safe because the suite changes no live target.
Commit the focused-validated tree, create a disposable full clone with a real
`.git` directory, and rerun the complete suite there, sequentially if the
known parallel timing fixtures recur.

The authoritative rerun from disposable full clone
`/tmp/t310-validation.nBf3TH` passed all focused shards and every phase-one
integration gate with `HARNESS_TEST_JOBS=1`. The clone contained 902 entries
and 22,220,376 bytes; guarded deletion manifest
`/tmp/t310-validation-delete.manifest` revalidated it, deleted only that clone,
and proved protected anchors unchanged and the target absent. The manifest was
then exact-unlinked. No validation residue remains.

Final review tightened strict state-schema validation and kept the doctor
temporary-file identity in the parent supervisor so its exit trap can retain
cleanup responsibility on an unlink failure. The new supervisor and updated
reboot suites passed again. A second full-clone run passed every T-310 and
integration check but hit the previously documented, unrelated
`test-personal-macos-ssh-supervisor.sh` 30-second watchdog cleanup race; that
exact suite passed immediately in isolation. The earlier authoritative
complete suite remains green, and protected CI is the remaining authority.
The second clone (902 entries, 22,148,614 bytes) and its manifest were removed
through the same verified guarded workflow with no residue.

### T-309 — Canonicalize fleet-health probing

**Phase:** planned; ready to execute.

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

### T-303 — Observe intermittent NFS I/O latency

**Phase:** monitoring/time-gated. A read-only, non-sudo client monitor is
active on Local as transient user unit
`nfs-io-monitor-20260724T083822.service`. It started at 2026-07-24 08:41 JST
and is scheduled to stop after 24 hours at 2026-07-25 08:41 JST. Raw evidence
is on local ext4, outside every measured NFS filesystem, in the
current-user-owned mode-0700 directory
`/var/tmp/nfs-monitor-20260724T083822+0900`; logs are mode 0600. The monitor
samples all five NFS mounts and their three storage servers every ten seconds,
with full mount statistics every five minutes.

The initial client baseline found healthy sub-millisecond network latency,
zero NFS RPC retransmissions, no local CPU/I/O pressure, current direct reads
around 410–435 MiB/s, and fast cached metadata. The primary `/home` export and
the separate `/mnt/nfs` export were both 95% full; the NFSv4 project exports
were 1–38% full. The extreme slowdown was not reproduced during the baseline,
so capacity, intermittent server-side load, uncached write allocation, and
workload-specific metadata behavior remain hypotheses.

After 2026-07-25 08:41 JST, verify the unit reached a clean terminal state,
preserve the exact evidence directory, and correlate any latency spikes across
the recorded NFS, mount, client, network, and capacity series. Do not claim a
server-side cause without server evidence. Local sudo is not currently
required; server administration or Local sudo becomes useful only if the
client trace identifies an unexplained interval. The monitor has `Linger=no`
and can stop if every `rioyokota` login session ends. Evidence and exact
follow-up are in
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

**Status:** time-gated. Progress is 1/8 successful weekly chains everywhere.
Execution requires eight successful chains, two verified restores per node,
and a current independent generation.

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
Evidence is in `docs/backup-lifecycle-phase2.md`, `docs/home-backup.md`, and
`docs/audits/restic-first-weekly-2026-07-19.md`.

## Completed anchors

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
