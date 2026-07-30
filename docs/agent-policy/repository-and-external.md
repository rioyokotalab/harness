# Repository and external-operation policy

Read this file completely before the matching action selected by root
`AGENTS.md`.

## Authority and external boundaries

- When exact owner authorization exists, preserve unrelated owner settings and
  make the smallest atomic change. Otherwise collect one approval bundle and
  continue all safe in-scope work.
- At the owner's standing request, an agent may execute and exact-unlink
  `~/run_this.sh` only after reviewing that it embeds and prompts for no
  credential and passes an existing credential solely by file path to its
  intended application. Redirect potentially private output to an unread
  mode-0600 temporary log and exact-unlink it after success. Never read, print,
  hash, or copy credential contents.
- Do not automatically change `~/.codex/config.toml`,
  `~/.claude/settings.json`, profiles, hooks, MCP servers, plugins, connectors,
  authentication, credentials, system files, installed packages, or external
  services. Unless exact authority already exists, collect one proposal bundle
  with files, impact, commands, and rollback, then continue safe work.

## Collaborative Git and hosting

- Ordinary Git operations inside the active task are standing-authorized,
  including fetch, branch, commit, rebase, push, task pull-request, and merge.
  They do not authorize hosting administration, workflow dispatch,
  deployments, messages, cleanup, or credential access.
- For an owner-authorized collaborative repository, fetch before work and
  again before pushing. Integrate non-conflicting contributor commits and push
  small verified branch checkpoints. Use one coherent protected pull request
  for the task; do not open or wait on a PR merely to publish a ledger
  checkpoint. Never force-push or overwrite ambiguous remote work.
- Treat authenticated Git transport and hosting API or administration as
  separate capabilities. Preflight and report them independently; successful
  fetch or push never proves settings authority.
- During hardening, a live required pull-request approval count of zero is
  owner-selected accepted policy. Do not report or change it without separate
  authorization for the exact repository and ruleset.
- Publish Harness through protected `main`. Ordinary Git authorization does
  not include workflow dispatch, deployment, repository settings, rulesets,
  billing, or organization administration.

## Authentication and native commands

- When Git or SSH needs agent authentication, require `SSH_AUTH_SOCK` to name a
  current-user-owned Unix socket. If the process socket is unusable under tmux,
  recover only from that session's exact socket and then a host-declared fixed
  socket; never use tmux's global environment. Bind recovery only to the
  intended command and otherwise fail closed. Never list, inspect, copy, or
  request SSH keys or passphrases.
- Prefer recognizable native platform commands over opaque wrappers. Keep
  portability mapping in the workflow and report the resolved native command.

## Installer deletion exception

A reviewed vendor installer or trusted package manager may perform its own
internal recursive cleanup only when all of these hold:

- obtain exact bytes from an official HTTPS source; never pipe remote code to a
  shell;
- review syntax, destructive primitives, and target derivation;
- use explicit non-interactive destinations;
- confine deletion to declared package-owned release, cache, staging, or
  temporary roots;
- exclude account-home roots, repositories, workspaces, credentials, backups,
  and unrelated data;
- execute the exact reviewed artifact and verify installed state and residue.

Ambiguity falls back to `guarded-bulk-delete`. Owner approval alone never
creates an exception.
