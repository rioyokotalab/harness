# Personal harness task board

This is the authoritative resume point for the portable Codex and Claude
harness. Keep only current state, active decisions and gates, exact next
actions, and compact completion pointers here. Git history and the linked audit
documents retain completed execution detail.

Next free ID: T-300.

## Current state

- Public `main`, Local, and all eleven remote managed checkouts were verified
  clean/current after T-298; all four private Mac SSH payloads are also
  current.
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

### T-299 — Refresh and reprioritize README

**Status:** executing. Verify the current fleet inventory, add the canonical
node table to the README, and reorder the document around owner-facing quick
start, fleet reference, routine operations, specialized workflows, and
implementation detail. Preserve technical contracts and links while removing
stale deployed-state claims. The value-free live OS/hostname inventory has
been reconciled with `docs/fleet-inventory.md`; the README and its focused
inventory regression test are updated. Focused inventory, takeover, public
audit, evaluation, link, and whitespace checks pass. The first full phase-one
run reached every suite but ran from the intentionally dirty documentation
checkout: the tmux and terminfo clean-checkout gates refused it, and the
parallel evaluation interrupt self-test raced before writing `child.pid` even
though standalone evaluation passed both before and after that run. Retry is
safe. Next: checkpoint the intended files, rerun full phase-one validation from
the clean feature branch, then publish and synchronize the managed fleet.

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
