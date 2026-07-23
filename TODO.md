# Personal harness task board

This is the authoritative resume point for the portable Codex and Claude
harness. Keep only current state, active decisions and gates, exact next
actions, and compact completion pointers here. Git history and the linked audit
documents retain completed execution detail.

Next free ID: T-302.

## Current state

- Public `main`, Local, and all eleven remote managed checkouts were verified
  clean/current after T-298; all four private Mac SSH payloads are also
  current.
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
- All managed systems use the canonical terminal SSH include and fragment.
  The four Mac private profiles use schema 3 with one distinct per-host SSH
  payload and no legacy root payload.
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
  route pairs. Omit `abci_login` and `alps_login` unless a task targets
  those transports.

## Next resume checkpoint

1. On or after 2026-07-26, query only the seven T-196 successor job IDs below.

## Active tasks

### T-301 — Review canonical SSH defaults

**Phase:** executing. Review only the default `Host *` policy in
`~/.ssh/config.d/harness.conf`, its repository-managed source and tests, its
effective OpenSSH behavior, and fleet consistency. Develop evidence-based
recommendations for settings to retain, remove, change, or add. Non-goals
during planning/interview are changing SSH files, restarting tunnels, or
altering credentials, keys, agents, server configuration, or host-specific
contracts. The complete evidence, five-decision register, provisional target,
transaction sequence, rollback policy, and acceptance gates are in
`docs/plans/t301-ssh-defaults-review.md`. Material findings: global agent
forwarding contradicts the existing six-host scoped policy; indefinite mux
persistence has left 20 live sockets fleet-wide; `%C` works everywhere; OS
defaults make known-host hashing inconsistent; and five Linux fragments carry
an older exception revision even though their `Host *` bytes match. No target
configuration has been changed. D1 is selected: retain global
`ForwardAgent yes` so future Linux aliases inherit it; the owner accepts the
wildcard scope. D2 is selected: retain global trusted X11 with the existing
GitHub, tunnel, Mac-route, and web exclusions so future Linux aliases inherit
it. D3 is selected: retain `AddKeysToAgent yes` and its agent-default lifetime
to minimize intervention. D4 is selected: keep opportunistic multiplexing,
change the path to `~/.ssh/cm-%C`, expire idle masters after 10 minutes, and
gracefully drain validated old masters without terminating active sessions.
D5 is selected: explicitly set a 15-second connection timeout, alive count 3,
future known-host hashing, and authenticated host-key updates. The decision
audit was reopened before execution: the owner withdrew `ControlPersist 10m`
and selected alphabetic directive ordering, then selected current indefinite
`ControlPersist yes` with the new `%C` path. No target changed. The decision
audit is complete, the owner gave explicit `go`, and execution began from
clean/current public main `f654a374311ca2bb62c65c4b4aa5b514eebdc547` with
only the plan/ledger checkpoint uncommitted. The task branch now implements the
frozen canonical defaults, alphabetic directive enforcement, and operator
documentation. Whitespace, layout, Mac SSH sync, Mac plan/doctor, and SSH
mirror tests pass. No live SSH file has changed. Next: checkpoint the
implementation, run full phase-one validation from a clean commit, then publish
before touching any live SSH fragment.

Implementation checkpoint `c368b60` passed the complete phase-one suite from a
clean checkout. Next: publish through protected CI and guarded-sync the exact
merge before any live SSH rollout.

PR #274 protected run `29975574360` failed only in the unchanged Mac watchdog
signal-cleanup timing test after its five-second wait; every T-301-focused
surface passed. The supervisor suite immediately passed standalone and had
passed in the complete local run. Retry is safe; no live state changed. Next:
checkpoint this evidence to trigger a fresh protected run. Stop before rollout
if the same failure repeats.

Fresh protected run `29975671674` passed; PR #274 merged as `5897e248` and all
remote repositories synchronized. Local transaction
`20260723T030031Z-3024814` applied and validated, then 16 old masters received
non-terminating `-O stop`. `ab` transaction `20260723T030342Z-541548` applied,
but its first fresh non-multiplexed probe timed out through the proxy. Both
Local and `ab` were exactly rolled back; no other live fragment changed. The
route was intermittent even after rollback, and three old Local mux sockets
remain for active clients. Next: run matched read-only route probes and revise
the sequence to validate new paths before draining old masters. Do not resume
live rollout until the failure is classified.

Three matched rollback-state `ab` probes passed in 3, 0, and 1 seconds. The
sequence is revised to validate all new paths before draining old masters. A
Local retry apply then refused the dirty ledger checkout as designed; no live
state changed. Next: push this checkpoint on a task branch, return to clean
merged main, and retry only Local.

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
