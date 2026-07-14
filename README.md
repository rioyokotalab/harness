# Personal Codex harness

This repository versions the portable, non-sensitive part of the personal
Codex setup. It is deliberately nested under `~/.codex/harness` instead of
turning the complete `~/.codex` runtime directory into a repository.

## Tracked

- `AGENTS.md`: global working agreements loaded before project instructions.
- `skills/`: personal reusable workflows.
- `rules/default.rules`: reviewed global command rules.
- `config.example.toml`: a non-secret template and reminder; it is not
  installed automatically.
- `install.sh`: idempotent, fail-closed discovery symlink installer.

## Deliberately excluded

The live `~/.codex/config.toml`, authentication, sessions, histories, logs,
goals, memories, databases, shell snapshots, caches, packages, plugins,
temporary files, backups, installation identifiers, and model caches remain
outside this repository. They may contain secrets, private prompts, machine
state, or high-churn reproducible data.

Never commit a real configuration file until every credential and private
endpoint has been replaced by an environment variable or another secret
manager. A private Git remote does not make committed secrets safe.

## Restore

Clone this repository to `~/.codex/harness`, inspect it, then run:

```bash
./install.sh
```

The installer creates only known symlinks. It refuses to replace an existing
regular file or a symlink with a different target. It does not edit
`config.toml`, install packages/plugins, or change authentication.

After installation, start a new Codex session so it rebuilds global instruction
and skill discovery.
