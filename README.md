# Personal Codex and Claude harness

This repository versions the portable, non-sensitive part of the personal
agent setup. It lives at `~/harness` instead of turning either client runtime
directory into a Git repository.

## Tracked

- `codex/AGENTS.md`: canonical shared global working agreements.
- `codex/rules/default.rules`: reviewed Codex command rules.
- `codex/config.example.toml`: non-secret Codex settings template.
- `claude/CLAUDE.md`: a repository symlink to the shared working agreements.
- `claude/settings.example.json`: non-secret Claude settings template.
- `shared/skills/`: reusable workflows exposed to both clients.
- `install.sh`: idempotent, fail-closed discovery symlink installer.
- `TODO.md`: harness-owned planned and active work.

The installer exposes the same global guidance as `~/.codex/AGENTS.md` and
`~/.claude/CLAUDE.md`. It links every shared skill into
`~/.codex/skills/`, `~/.agents/skills/`, and `~/.claude/skills/`.

## Deliberately excluded

The live `~/.codex/config.toml`, `~/.claude/settings.json`,
`~/.claude/.credentials.json`, `~/.claude.json`, authentication, sessions,
histories, project transcripts, logs, goals, memories, databases, shell
snapshots, caches, packages, plugins, daemon state, temporary files, backups,
installation identifiers, and model caches remain outside this repository.
They may contain secrets, private prompts, machine state, or high-churn data.
Existing project- or tool-local instruction files are also not absorbed into
this global harness.

Never commit a real configuration file until every credential and private
endpoint has been replaced by an environment variable or another secret
manager. A private Git remote does not make committed secrets safe.

## Restore

Clone this repository to `~/harness`, inspect it, then run:

```bash
./install.sh
```

The installer creates only known symlinks. It refuses to replace an existing
regular file or a symlink with a different target. It does not edit either
client's live settings, install packages/plugins, or change authentication.

After installation, start new Codex and Claude sessions so both clients rebuild
global instruction and skill discovery. If `~/.claude/skills/` was created for
the first time, Claude must be restarted before those skills appear.

## Local shell compatibility

The live shell startup files are intentionally not versioned here. On systems
where Bash completion defines functions that require nondefault parser options,
load the system completion script only for interactive shells. This prevents a
noninteractive Codex shell snapshot from serializing completion-only functions
while preserving normal terminal completion:

```bash
if [[ $- == *i* && -f /usr/share/bash-completion/bash_completion ]]; then
  . /usr/share/bash-completion/bash_completion
fi
```

This workaround is based on a local Codex CLI 0.144.3 diagnosis. Validate it
against the installed CLI before applying it on another machine.
