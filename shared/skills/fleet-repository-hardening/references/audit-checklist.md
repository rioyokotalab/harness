# Hardening audit checklist

Use only applicable rows. Record `pass`, `finding`, `expected`, `unavailable`,
or `unknown`; a failed query is `unknown`.

## Repository

- Instructions and task ledger read completely.
- Clean/dirty ownership, revision, upstream, worktrees, and active pull requests.
- Required local/focused/full test commands.
- Runtime and development dependency locks; current advisories.
- Workflow triggers, token permissions, immutable Actions, event-to-shell flow.
- Tracked credential/private/runtime paths and secret-scanning entitlement.
- Default Actions permissions and workflow-approval capability.
- Dependency graph, alerts, security updates, routine update policy.
- Branch rules: deletion, non-fast-forward, review count, stronger reviewers,
  conversation resolution, linear history, exact strict checks, bypass actors.
- Environments, deployments, external messages, and credential boundaries.
- Backup distinction between tracked source and ignored runtime artifacts.

## Linux or HPC host

- Both approved routes where redundancy is declared.
- OS/architecture, filesystem capacity/inodes, ownership and safe modes.
- Native scheduler/account/resource declarations; no inferred billing route.
- Backup repository check, schedule declaration, and exact scheduler state.
- Effective SSH options for representative direct, jump, Git, and default hosts.
- Agent executable cardinality/version and project-scoped configuration.
- Managed services and unexpected user-owned listeners/processes.

## macOS host

- Both reverse routes independently and managed tunnel ownership.
- FileVault, SIP, Gatekeeper, firewall, stealth, updates, and backups.
- Unexpected wildcard listeners, especially X11 TCP.
- Package-set drift, broken executable links, and active-session preservation.
- Login shell, canonical SSH fragment, tmux, remote control, and reboot recovery.
- Exact admin/TCC requirements and a one-host rollback gate.

## Final readback

- Current pull-request head and exact required checks.
- Merged revision and alert closure.
- Live Actions, security, environment, and ruleset settings.
- Clean working trees and no task-owned stashes or helpers without ledger entries.
- Fleet routes, services, backups, and changed effective configuration.
- Deadline handoff with blockers, retry safety, and exact next commands.
