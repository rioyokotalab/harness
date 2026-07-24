# Codex and Claude project configuration

The harness owns one reviewed project-settings body for each client:

- `.codex/config.toml`, mirrored by `config/agent-clients/codex.toml`;
- `.claude/settings.json`, mirrored by
  `config/agent-clients/claude.json`.

Codex and Claude load those files only when started from `~/harness`. Root
`AGENTS.md` is the self-contained shared policy; root `CLAUDE.md` imports it.
Every canonical skill has one tracked link under `.agents/skills/` and one
under `.claude/skills/`. No harness behavioral setting, rule, or skill link is
required from the user's home-directory client configuration.

Authentication, credentials, sessions, histories, memories, caches, databases,
private endpoints, and machine-specific runtime state remain outside this
contract and are never inspected or migrated.

The initial reviewed bodies contain only the frozen prompt-free posture. Codex
uses `approval_policy = "never"` with `sandbox_mode = "danger-full-access"`.
Claude uses `permissions.defaultMode = "bypassPermissions"` and suppresses the
one-time dangerous-mode warning. These choices do not suppress authentication,
macOS privacy, administrator, provider-policy, or Claude's hard-coded root/home
recursive-deletion circuit-breaker prompts.

## Project trust launcher

`bin/harness-codex` calls the installer-owned native command and passes the
frozen `never` approval and `danger-full-access` sandbox settings as explicit
CLI flags, which take precedence over ordinary configuration layers. Linux
uses `~/.local/bin/codex`. Darwin accepts Homebrew's fixed bin only when it
resolves inside the current user's official standalone Codex package; the
older local-bin path remains only as a compatible fallback.
The managed Darwin route also exports that fixed Homebrew bin as
`CODEX_INSTALL_DIR` and places it first on `PATH` before native execution.
An installer-based update launched by Codex therefore inherits the reviewed
destination and does not add its default local-bin block to a shell profile.
The managed live launcher is `~/.local/bin/harness-codex`. Fresh managed
interactive Bash shells define a shell-local `codex` function that calls it;
non-interactive and batch shells retain native resolution. The wrapper uses an
absolute native path, preventing recursion or silent fallback, and preserves
all arguments and subcommands. Client-persisted project trust stays only in the
private live regular file and never dirties public Git.

## Lock-aware arg0 housekeeping and the Linux NFS wrapper

On Linux and macOS, `codex-arg0-housekeeping` classifies immediate helper
directories without stopping Codex. Held locks are live. Linux uses native
`flock`; macOS uses Perl's nonblocking POSIX `flock` and its four-helper Darwin
layout. Old empty directories and platform-expected directories with
acquirable locks move atomically to a same-filesystem private quarantine, and
only that quarantine is removed through guarded-delete. A mode-0600 baseline
lets a launcher identify residue from an invocation whose exit it directly
observed without weakening protection for concurrent sessions.

The separately authorized version-scoped wrapper retains the exact official
binary as `codex.real` in the same standalone release, installs a small launcher
at the original release path, and preserves arguments and exit status. It runs
bounded housekeeping before and after the official binary. Apply and rollback
do not signal or reload existing Codex processes. An official upgrade changes
the `current` release link and therefore supersedes the old version's wrapper;
the new release must be re-diagnosed before another installation.

```bash
./bin/harness codex-arg0-housekeeping --plan
./bin/harness codex-arg0-wrapper --plan
./bin/harness codex-arg0-wrapper --apply
./bin/harness codex-arg0-wrapper --doctor
./bin/harness codex-arg0-wrapper --rollback
```

## Declarative components

`config/agent-clients/components.tsv` is the single public declaration surface
for reviewed hooks, plugins, marketplaces, and MCP servers. It currently has no
component entries because no exact identifier or hook command has yet passed a
separate public review. Authentication and installed caches can never be
payloads. Adding the first component requires a protected change that also adds
its exact native reconciliation adapter and rejects interactive, credential,
private-endpoint, and machine-command declarations.

## Local migration transaction

Read-only commands are value-free:

```bash
./bin/harness agent-config --inventory
./bin/harness agent-config --plan
./bin/harness agent-config --doctor
```

Schema 2 retains `~/.local/bin/harness-codex`, installs minimal launch
sentinels at `~/.codex/AGENTS.md` and `~/.claude/CLAUDE.md`, and removes only
recognized legacy harness configuration:

- the strict managed `~/.codex/config.toml`;
- the exact managed Claude settings and Codex rule links; and
- exact harness skill links from the three former user discovery directories.

Unrelated entries—including Codex's vendor-owned `.system` directory—remain.
Different symlinks, unknown regular settings, hard links, unsafe parents, dirty
checkouts, and concurrent changes fail closed. `--adopt` remains accepted for
controller compatibility but never authorizes an unrelated preimage.

Apply records a mode-0600 manifest plus exact regular-file and symlink
preimages. Rollback restores only unchanged transaction postimages. `--drill`
automates apply, rollback, reapply, and doctor. Changes activate only in fresh
Codex and Claude sessions; authentication and running processes are untouched.

## Pull-based catch-up and Linux controller

`agent-config-catch-up` is the explicit local route for a Mac that may have
been offline. It refuses dirt in both checkouts, fetches both `origin/main`
targets without prompting, and delegates public/private compatibility,
fast-forward, and local migration-state handling to `macos-update` before it
hands off to the target agent-configuration engine. It never advances the
public harness independently of its private companion, and it never runs at
login, wake, or session start.

The Linux controller takes an exact old and target public commit. It first uses
the guarded verified-bundle fleet synchronizer, then processes `local`, `ab`,
`ab2`, `ri`, `al`, `rc`, and `t4` sequentially. It stops on the first failure.
Both routes keep adoption and the rollback/reapply drill explicit:

```bash
./bin/harness agent-config-catch-up --host LOGICAL_ID --adopt --plan
./bin/harness agent-config-catch-up --host LOGICAL_ID --adopt --apply --drill

./bin/harness agent-config-fleet --from OLD --to NEW --adopt --plan
./bin/harness agent-config-fleet --from OLD --to NEW --adopt --apply --drill
```

No command automatically reloads an active client, installs a component, or
supplies authentication. Project settings are normal reviewed Git files;
catch-up stops on an uncommitted edit.
