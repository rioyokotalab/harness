# Personal Codex and Claude harness

This repository versions the portable, non-sensitive part of the personal
agent setup. It lives at `~/harness` instead of turning either client runtime
directory into a Git repository.

## Tracked

- `.codex/AGENTS.md`: canonical shared global working agreements.
- `.codex/rules/default.rules`: reviewed Codex command rules.
- `.codex/config.example.toml`: non-secret Codex settings template.
- `.claude/CLAUDE.md`: a repository symlink to the shared working agreements.
- `.claude/settings.example.json`: non-secret Claude settings template.
- `shared/skills/`: reusable workflows exposed to both clients.
- `install.sh`: idempotent, fail-closed discovery symlink installer.
- `bin/harness` and `libexec/`: value-free inventory, planning, and health
  checks for the portable environment.
- `profiles/`: selected tool policy and logical host capabilities.
- `tests/fixtures/`: value-free environment evidence used by the shell tests.
- `docs/`: architecture and operating notes for the portable environment.
- `TODO.md`: harness-owned planned and active work.

The installer exposes the same global guidance as `~/.codex/AGENTS.md` and
`~/.claude/CLAUDE.md`. It links every shared skill into
`~/.codex/skills/`, `~/.agents/skills/`, and `~/.claude/skills/`. It also links
the read-only `harness` command into `~/.local/bin/`.

## Environment observation and planning

Phase 1 provides three dependency-free commands:

```bash
harness inventory --host local
harness plan --host local
harness doctor --host local
```

`inventory` emits a strict value-free fact stream: logical host, OS and
architecture, selected command presence, managed-link state, and shell-startup
file type. It does not read startup-file contents, arbitrary environment
values, credentials, histories, projects, or caches. Use `--format json` when
machine-readable JSON is needed. The inventory executable is self-contained and
can be streamed to an explicit remote POSIX shell without creating a file:

```bash
ssh HOST 'sh -s -- --host HOST' \
  < libexec/harness-inventory
```

`plan` compares current or captured facts with a reviewed logical host profile.
It is read-only and ends with `remote_changes=none`. `doctor` treats a host or
bootstrap mismatch as a failure while reporting not-yet-installed selected
tools and discovery links as warnings.

Captured facts can be checked without connecting to a host:

```bash
harness plan --host al --facts tests/fixtures/al.facts
harness doctor --host al --facts tests/fixtures/al.facts
```

Run the phase-1 validation suite with:

```bash
tests/test-phase1.sh
```

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
