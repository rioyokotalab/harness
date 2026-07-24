---
name: onboard-external-user
description: Safely set up a clean local Linux or macOS account to use the Codex/Claude harness without assuming the owner's hidden files, credentials, remote nodes, storage, backups, or installed prerequisites. Use when an external or first-time user asks to clone, install, validate, repair, or understand a local harness installation before any separate mirrored-node onboarding.
---

# Onboard External User

Keep this workflow local-first. Install only public discovery links from one
clean checkout; do not activate fleet profiles, SSH routes, storage migration,
backups, schedulers, plugins, authentication, or external services.

## Establish the boundary

1. Confirm the task covers one current-user account on Linux or macOS. Treat
   every remote host and private companion repository as out of scope.
2. Inspect repository instructions when already inside a checkout. Otherwise
   ask for the repository locator and desired absolute clone path; do not guess
   a private URL or request a credential.
3. Preserve every existing dotfile and symlink. Package installation,
   administrator commands, client authentication, and collision adoption are
   separate approval boundaries.

## Preflight prerequisites

Before cloning, use native read-only command discovery to require a POSIX shell
and Git. `mkdir`, `ln`, and `readlink` are also required by the installer.
Codex and Claude are optional at this stage; report each as present or absent
without installing or authenticating it.

If a required command is missing, identify the operating system and available
native package manager, propose the smallest official installation command,
and pause for approval before running it. Never pipe a remote installer into a
shell. On macOS, treat Command Line Tools installation as an interactive owner
step. On Linux, do not infer sudo or package-manager authority.

## Clone and inspect

Clone with ordinary Git into an absent destination, or reuse only a strict,
clean checkout whose repository identity the user selected. Do not copy a
working tree, SSH configuration, client state, or credentials. Record the full
commit ID and read the checkout's `AGENTS.md`, `README.md`, and license or
distribution terms before installation.

Run the deterministic preflight from the checkout:

```bash
shared/skills/onboard-external-user/scripts/preflight --repo "$ABSOLUTE_CHECKOUT"
```

It emits only OS/architecture classes, command presence, checkout cleanliness,
and aggregate link states. It never reads destination contents. Stop if it
reports `status=blocked`, a dirty checkout, or any collision. Explain the
colliding category and let the user choose whether to retain it, move it, or
perform a separately reviewed adoption; do not overwrite it.

## Install and validate

From the recorded clean commit, first require the repository-native client
contract:

- root `AGENTS.md` and `CLAUDE.md`;
- `.codex/config.toml` with `approval_policy="never"` and
  `sandbox_mode="danger-full-access"`;
- `.claude/settings.json` with `bypassPermissions` and warning suppression;
- every canonical skill linked from `.agents/skills/` and
  `.claude/skills/`.

Then run `./install.sh` as the current user without sudo. The installer
preflights every link before mutation and is idempotent. It exposes only the
`harness` command and minimal Codex/Claude launch sentinels that refuse task
work outside this checkout. It does not install either client, create
user-global behavioral settings or skill links, or alter
authentication/runtime state.

Run the preflight again and require `status=ready`, `collisions=0`, and
`links_absent=0`. Then verify:

- `harness help` and `harness version` succeed;
- each installed sentinel/command link still points to the selected checkout;
- both project settings have the reviewed non-interactive permission values;
- `.agents/skills/` and `.claude/skills/` expose every canonical skill using
  exact repository-relative symlinks;
- a newly started installed client can discover `onboard-external-user`;
- no remote host, storage root, backup repository, scheduler, plugin, or
  authentication state was created; and
- rerunning `./install.sh` changes nothing.

Do not claim the owner-specific fleet profiles are usable on the external
machine. If the user later supplies one explicit SSH alias and asks to manage
it, hand off that separate task to `onboard-mirrored-node`.

## Roll back or hand off

There is no broad uninstall. For rollback, inventory the exact links created by
the selected checkout and exact-unlink only links that still point there;
preserve changed or colliding paths and do not recursively remove client
directories. Delete a clone only under a separately reviewed bounded-deletion
workflow.

Report the commit, OS/architecture, prerequisite state, link totals, installed
client presence, validation performed, retained collisions or owner actions,
and the exact next step. Never record usernames, home paths, credentials, or
machine identifiers in a shared artifact.
