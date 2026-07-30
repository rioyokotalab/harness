# External-operation policy

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
- Treat authenticated Git transport and hosting-service API or administration
  access as separate capabilities. A successful fetch or push never proves API
  or settings authority.

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
