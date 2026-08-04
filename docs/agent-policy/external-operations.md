# External-operation policy

Read completely before the matching root-`AGENTS.md` action.

## Authority and external boundaries

- Clear contextual owner approval permits the atomic change while
  preserving unrelated settings; plain approval of the latest bounded proposal
  suffices. Never require copied wording.
- The owner's standing request permits executing and exact-unlinking
  `~/run_this.sh` only after confirming it embeds/prompts for no credential and
  passes an existing credential to its intended application solely by file
  path. Send potentially private output to an unread mode-0600 temporary log;
  exact-unlink it after success. Never read, print, hash, or copy credentials.
- Do not change `~/.codex/config.toml`, `~/.claude/settings.json`, profiles,
  hooks, MCP servers, plugins, connectors, authentication, credentials, system
  files, packages, or external services without contextual authority. Bundle
  files, impact, commands, and rollback while continuing safe work.
- Git transport and hosting API/administration are separate capabilities;
  fetch or push never proves API or settings authority.

## Installer deletion exception

For installer-internal recursive cleanup, apply `guarded-bulk-delete`; its
router must select the complete
[installer exception](../../shared/skills/guarded-bulk-delete/references/installer-exception.md).
Every condition there is required. Ambiguity falls back to ordinary guarded
deletion. Owner approval alone never creates an exception.
