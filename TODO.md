# Personal harness task board

This is the authoritative resume point for the portable Codex and Claude
harness. Keep only current state, active decisions and gates, exact next
actions, and compact completion pointers here. Git history and the linked audit
documents retain completed execution detail.

Next free ID: T-303.

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
  route pairs. Omit `abci_login` and `alps_login` unless a task targets
  those transports.

## Next resume checkpoint

1. On or after 2026-07-26, query only the seven T-196 successor job IDs below.

## Active tasks

### T-302 — Reduce AL authentication intervention

**Phase:** interviewing. CSCS requires personal SSH keys to be CSCS-signed and
limits personal certificates to one day; `cscs-key 1.1.0` offers only `1d` and
`1min`. Local currently has a valid agent socket, a fresh non-multiplexed
`al` login passes, the Ela jump-host master is running, and no `al` master is
running. Official CSCS guidance reserves API-key authentication for separate
service accounts and explicitly warns against setting `CSCS_API_KEY` globally.

No supported configuration can make fresh personal-account connections
authenticate indefinitely. The owner selected the hybrid design: reuse a live
personal `al` transport where possible and add a separate service account for
unattended automation while retaining personal MFA for interactive work. The
frozen boundaries, conditional decisions, validation experiment, and official
sources are in `docs/plans/t302-al-authentication.md`.

The owner confirmed service-account eligibility but requires selected
personal-home access. Read-only AL metadata shows the home is mode 0700 and the
existing harness checkout has no named ACL, so the service identity currently
has no route into it. CSCS supports targeted ACLs. Broad home access is
rejected; next action is to select a dedicated automation checkout, the
existing harness checkout only, or other exact home subtrees.

The owner selected the existing `$HOME/harness` checkout and requested
`$HOME/.*`, expecting future additions to remain possible. The checkout is an
exact reviewable scope. The dotfile glob is rejected because it includes SSH,
agent, Codex/Claude authentication, history, cache, snapshot, and unrelated
private state. The repository installer already supports a layered model:
canonical non-secret guidance, rules, skills, scripts, and documentation can
be shared from the harness checkout through service-owned discovery links,
while credentials and mutable client/runtime state remain account-local. The
owner requires the service identity to edit the existing checkout and prefers
a service-owned dotfile/state tree linked into the personal account. Writable
cross-identity checkout access is now selected and will require inherited ACLs
and explicit Git locking/ownership validation. The owner selected
`.ssh/config` and `.ssh/config.d` as the first exact shared paths and requested
symlinks. OpenSSH checks the resolved owner of both the root user config and
every included file; a personal account therefore cannot use service-owned
symlink targets. Next action: decide whether to use service-owned canonical
SSH configuration sources with atomic synchronized, account-owned live copies.

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
