---
name: onboard-external-user
description: Set up or repair a first-time external user's clean Linux/macOS Harness account without assuming owner credentials, hidden files, storage, backups, remote nodes, or prerequisites.
---

# Onboard External User

Keep this workflow local-first and limited to one current-user Linux or macOS
account. Install only public discovery links from one selected clean checkout.
Remote hosts, private companion repositories, fleet profiles, SSH routes,
storage migration, backups, schedulers, plugins, authentication, and external
services are out of scope.

Never inspect or request credentials. Preserve every existing dotfile and
symlink; package installation, administrator commands, client authentication,
and collision adoption are separate approval boundaries. Never pipe a remote
installer into a shell. There is no broad uninstall, and clone deletion
requires `guarded-bulk-delete`.

Read exactly the reference for the next recorded phase, completely, before
that phase:

- repository/account boundary:
  [boundary.md](references/boundary.md)
- native prerequisites, clone, and value-free preflight:
  [preflight.md](references/preflight.md)
- project contract and installation:
  [installation.md](references/installation.md)
- acceptance, rollback, and handoff:
  [acceptance.md](references/acceptance.md)

Do not preload later phases or reread a completed phase merely because the
session resumed. Record its result and next phase durably. Stop on dirty,
divergent, ambiguous, or colliding state; never overwrite it to continue.
