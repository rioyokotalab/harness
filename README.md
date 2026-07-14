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
- `bin/harness` and `libexec/`: value-free inventory, planning, health checks,
  and guarded bulk deletion for the portable environment.
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

## Autonomous deletion safety

Agents never run raw recursive or expanding deletion. They use a two-command
workflow that does not prompt for approval:

```bash
harness guarded-delete plan --within /absolute/retained/root \
  --manifest /absolute/retained/delete.manifest -- \
  /absolute/retained/root/generated
harness guarded-delete apply --manifest /absolute/retained/delete.manifest \
  --token SHA256_FROM_PLAN
```

Planning canonicalizes a narrow retained boundary and explicit targets,
rejects protected roots and overlapping trees, inventories entry and byte
counts, and writes a mode-600 manifest. Apply accepts only that unchanged
short-lived manifest, revalidates account and filesystem identities plus tree
counts, uses one-filesystem recursive removal, and verifies both target absence
and protected-anchor survival. Codex execpolicy separately forbids common raw
recursive `rm` forms and directs the agent to this workflow.

## Transactional control plane

After reviewing the read-only host plan, preview the exact managed links with:

```bash
harness apply --host HOST --plan
```

`--apply` requires a clean committed harness checkout and a passing host doctor.
It refuses every unmanaged collision before mutation, records each created link
under `~/.local/state/harness/transactions/`, and rolls back partial work if an
apply command fails. To reverse one completed transaction:

```bash
harness rollback TRANSACTION_ID
```

Rollback removes only links that still point to the source recorded in the
mode-600 manifest. It stops rather than remove a path changed after apply.

Shell loaders use a separate append-only transaction:

```bash
harness shell --host HOST --plan
harness shell --host HOST --apply
```

The transaction never copies or hashes pre-existing startup-file content. It
records original byte length and a mode-600 copy of the public harness suffix.
Rollback first validates every affected file, then truncates only exact,
unchanged managed suffixes; any later user edit blocks the entire rollback.

Reviewed host-specific defects use a separate exact-patch transaction. The
currently supported remediation disables the known Alps `uenv start` line in
`.bashrc` without copying or hashing any surrounding bytes:

```bash
harness remediate --host al --plan
harness remediate --host al --apply
```

It replaces only the reviewed equal-length public line and stores only the
original and applied public patch bytes in mode-600 transaction state. Rollback
checks the file length and exact patched region before restoring it. The Alps
interactive shell then provides `prgenv`, which prints and runs the native
`uenv start prgenv-gnu/25.11:v1 --view=default` command. Scripts, Slurm jobs,
and agent workflows should report and invoke an explicit native `uenv run ...`
or Slurm `--uenv` command instead.

Checksum-pinned portable artifacts use an explicit one-tool transaction:

```bash
harness tool --host HOST --name ripgrep --plan
harness tool --host HOST --name ripgrep --apply
```

The plan names the exact HTTPS release URL, SHA-256 value, versioned install
directory, and stable link. Apply requires a clean harness and a passing host
doctor, extracts only the declared archive member into
`~/.local/opt/TOOL/VERSION/TARGET`, validates the reported version, and then
creates the `~/.local/bin` link. Rollback first verifies the installed binary
hash and refuses any modified artifact before removing the link and directory.
Apply reports the caller-side native `hash -r` command because a long-lived Bash
process may have cached an earlier system command path; a new shell resolves the
managed link without this refresh.
The manifest covers ripgrep 15.1.0, uv 0.9.18, rclone 1.74.3, Ninja 1.13.2,
ShellCheck 0.11.0, and the native Claude Code 2.1.207 binary on Linux x86-64
and AArch64. Tar and ZIP transactions extract only the declared
binary member. A host tool is retained only when its native `--version` health
probe succeeds; an unusable host command can be shadowed by the verified
user-space artifact without modifying the site path. Other selected tools
remain plans until their official artifacts and checksums are recorded and
tested. Installing uv does not implicitly download Python or modify shell
files; managed Python is a separate reviewed action.

ShellCheck uses an exact `version: 0.11.0` line from its multi-line version
report. The invariant product banner alone is not accepted as version proof.

Agent binaries are separate from live client state. Installing Claude does not
read, create, or synchronize authentication, settings, sessions, history, or
project transcripts.

Small deterministic compiler, OpenMP, MPI, CUDA, and Python sources live under
`tests/smoke/`. They are invoked with explicit native compiler and scheduler
commands, not a normalized HPC wrapper, so agent reports retain the site's real
execution semantics.

Checksum-pinned multi-file runtimes use a separate whole-tree transaction:

```bash
harness runtime --host HOST --name node --plan
harness runtime --host HOST --name node --apply
```

The Node runtime manifest covers Node 24.16.0/npm 11.13.0 on Linux x86-64 and
AArch64. Apply validates the publisher checksum, rejects unsafe archive paths,
checks the staged Node and npm versions, records an integrity digest for the
entire owned distribution tree, and activates `node`, `npm`, `npx`, and
`corepack`. Rollback validates every link and recomputes the whole-tree digest
before removing any path; a modified runtime fails closed without partial
cleanup.

Managed CPython uses uv through a separate owned-tree transaction:

```bash
harness python --host HOST --minor 3.12 --plan
harness python --host HOST --minor 3.12 --apply
```

The transaction installs CPython 3.12.12 into a harness-specific directory
with uv 0.9.18, disables project configuration discovery and cache retention,
and creates only `python3.12`. It does not modify uv's default Python directory
or shadow site `python`/`python3`. Rollback checks all non-cache entries and
ignores only generated `__pycache__`, `.pyc`, and `.pyo` files.

Codex uses a separate two-archive agent transaction:

```bash
harness agent --host HOST --name codex --plan
harness agent --host HOST --name codex --apply
```

The manifest pins the small official npm launcher and the matching x86-64 or
AArch64 native resource package independently. Apply verifies both checksums,
reconstructs only the expected `node_modules` layout in an owned tree, requires
the pinned Node runtime, validates `codex --version`, and records a normalized
whole-tree digest. Rollback fails closed if any launcher, binary, or bundled
resource changed. Authentication, configuration, sessions, caches, and logs are
not read or copied.

The Git LFS artifact installs only the `git-lfs` command. The harness does not
run `git lfs install`, write global Git filters or hooks, or contact an LFS
remote. Enable it per project with an explicit native `git lfs install --local`
only when that repository is in scope.

SQLite uses a dedicated checksum-pinned source transaction because the
publisher provides no AArch64 Linux CLI binary:

```bash
harness build-tool --host HOST --name sqlite --plan
harness build-tool --host HOST --name sqlite --apply
```

The plan displays the publisher SHA3-256, the independently recorded SHA-256,
the four exact amalgamation members, and the complete native `cc` command.
Apply retains healthy site SQLite, builds only when needed, validates JSON,
FTS5, and RTree in memory with user initialization disabled, and activates one
owned binary through the normal fail-closed artifact rollback.

The same source transaction supports Tree 2.3.2 on a host where `tree` is
absent:

```bash
harness build-tool --host HOST --name tree --plan
harness build-tool --host HOST --name tree --apply
```

Its plan shows the independently recorded SHA-256, exact 24-regular-file
allowlist, and dependency-free native `cc` command. Apply retains any healthy
site command, extracts only the declared build inputs, validates version and
ASCII output, and owns only the compiled binary and stable link. The publisher
does not provide a separate digest for this tarball; the source URL and pinned
SHA-256 are therefore both explicit in the reviewed plan.

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
