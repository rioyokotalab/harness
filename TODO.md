# Personal harness task board

This is the authoritative resume point for the portable Codex and Claude
harness. Keep only current state, active decisions and gates, exact next
actions, and compact completion pointers here. Git history and the linked audit
documents retain completed execution detail.

Next free ID: T-305.

## Current state

- Public `main`, Local, and all eleven remote managed checkouts were verified
  clean/current at T-301's functional revision
  `5a8a0901ce82b7bb187d74c479125e61e0cb8fe7`; all four private Mac SSH
  payloads are also current.
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
- Global safety and collaboration rules in `.codex/AGENTS.md` remain
  authoritative. Never inspect credentials or use raw recursive/bulk
  deletion.
- Whenever owner input or approval is requested, or a task completes, report a
  fresh compact health snapshot for every managed Linux node and all four Mac
  route pairs. Count abq as Linux and mark it ready only when both abq and abq2
  routes pass; do not include that pair in the Mac total. Omit `abci_login` and
  `alps_login` unless a task targets those transports.

## Next resume checkpoint

1. On or after 2026-07-26, query only the seven T-196 successor job IDs below.

## Active tasks

### T-304 — Make harness the sole Codex and Claude project context

**Phase:** interviewing. The owner selected `~/harness` as the required launch
directory for Codex and Claude on all eight Linux systems and four Macs. Move
shared policy, settings, rules, and all 13 skills into repository-scoped
discovery surfaces; remove only exact harness-managed global behavior and
discovery paths; and leave a minimal client-specific global startup sentinel
that directs accidental home-directory launches back to `~/harness`.

Read-only fleet inventory found current managed global guidance, settings,
rules, launcher, and 13 skill links everywhere. Codex's vendor-owned `.system`
skill directory exists on some systems and is unrelated state that must remain.
`~/.claude.json` exists on four systems and may combine OAuth, preferences,
trust, MCP, project state, and caches; it cannot be safely split or removed.
Authentication, sessions, memories, caches, databases, installed clients,
remote control, and unrelated global skills are proposed non-goals.

The complete plan, evidence, open decisions, rollback, and acceptance gates are
in `docs/plans/t304-project-scoped-agent-config.md`. Ask exactly one unresolved
decision at a time. Do not modify target configuration until all decisions are
frozen and the owner gives an explicit `go`. D1 is frozen: credentials and
mixed runtime state remain because project-scoped Codex and Claude still
consume them; the owner's deletion authority was conditional on not affecting
that operation.
D2 is frozen: the minimal global sentinels refuse task work outside
`~/harness`, explain where to restart, and leave the client process open; no
shell launcher guard is added.
D3 is frozen: after validation, restart and resume the four Mac Codex tmux
sessions sequentially from `~/harness` while preserving remote control and
reachability.
D4 is frozen: retain the current non-interactive Codex and Claude permission
posture in tracked project settings. The implementation must also update and
test `onboard-external-user` so Linux/external onboarding validates these
project-scoped settings and does not recreate global behavioral configuration.
All decisions are frozen; wait for the owner's explicit `go` before target
configuration changes.
Execution is authorized. The pre-change focused baseline passed
`test-agent-config`, `test-agent-config-fleet`, `test-onboard-external-user`,
and `test-claude-takeover`; implementation is now in progress.
The project-native settings/skills, sentinels, schema-2 migration, and updated
external-user workflow are implemented. Their four focused suites pass. The
first phase-one run identified three stale global-layout tests to update;
tmux/terminfo clean-checkout failures require a rerun after this checkpoint is
committed.
All compatibility assertions are now updated, and the clean committed
`tests/test-phase1.sh` run passed. Documentation reflects the schema-2
project-scoped contract. Next: protected CI, then Local/Linux/Mac pilots before
fleet rollout.

### T-302 — Reduce AL authentication intervention

**Phase:** monitoring/time-gated (restart-resilience extension). CSCS requires
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
