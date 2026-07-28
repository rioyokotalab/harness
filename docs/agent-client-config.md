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

The reviewed Codex body uses an explicit granular approval policy with only
`mcp_elicitations = true`; sandbox, command-rule, request-permission, and
skill-script approval categories are false and therefore fail closed. It
retains `sandbox_mode = "danger-full-access"`. Newly started trusted-project
sessions default to `gpt-5.6-sol` with
`model_reasoning_effort = "high"`; existing sessions retain the policy, model,
and effort already loaded for that chat. The startup update check is disabled
because Linux Codex releases are pinned and upgraded transactionally by the
harness; accepting the native update offer would install into Node's global
prefix without moving the managed command link. Claude uses
`permissions.defaultMode = "bypassPermissions"` and suppresses the one-time
dangerous-mode warning. These choices do not suppress authentication, macOS
privacy, administrator, provider-policy, or Claude's hard-coded root/home
recursive-deletion circuit-breaker prompts.

## Project trust launcher

`bin/harness-codex` calls the installer-owned native command and passes the
same exact MCP-only granular approval policy as a native command-line config
override plus the explicit `danger-full-access` sandbox flag. Those values
take precedence over ordinary configuration layers and keep managed launches
aligned with the reviewed project body. Linux uses `~/.local/bin/codex`.
Darwin accepts Homebrew's fixed bin only when it resolves inside the current
user's official standalone Codex package; the older local-bin path remains
only as a compatible fallback.
The managed Darwin route also exports that fixed Homebrew bin as
`CODEX_INSTALL_DIR` and places it first on `PATH` before native execution.
An installer-based update launched by Codex therefore inherits the reviewed
destination and does not add its default local-bin block to a shell profile.
The managed live launcher is `~/.local/bin/harness-codex`. Fresh managed
interactive Bash shells define `co` as the resilient shorthand and leave
`codex` unaliased, so native subcommands such as `codex --version` resolve
normally. Non-interactive and batch shells also retain native resolution. The
wrapper uses an absolute native path, preventing recursion or silent fallback,
and preserves all arguments and subcommands. Client-persisted project trust
stays only in the private live regular file and never dirties public Git.

## Transient-service supervisor

`harness codex-resilient` is the portable foreground owner for a Codex TUI
inside tmux. It always delegates to `bin/harness-codex`, so the existing
project trust, approval, sandbox, Darwin path, and version-scoped arg0
contracts remain authoritative.

The supervisor supports `--new`, `--last`, `--last-all`, and
`--session ID`, plus `--remote-session ID` for an exact app-server-backed
thread. An explicit saved-session identifier is the concurrency-safe choice.
The two latest-session selectors rely on the fleet's established single active
Codex session per checkout or global scope. A fresh first launch recovers with
repository-scoped `resume --last`; every other recovery retains its selected
resume scope. A remote selector always retains `resume --remote unix:// ID`.
No recovery command contains a prompt.

An exact remote selector starts one
`harness codex-thread-recovery --watch` child. A one-shot readiness transaction
must succeed before the TUI launches, and the supervisor stops and reaps the
watcher at exit. The helper speaks the local app-server Unix-WebSocket
protocol directly and keeps only a mode-0600, value-free receipt. It can roll
back one to eight trailing turns only when the exact thread is `systemError`
and every candidate turn is complete, has user input, has no assistant
response, and contains no tool, command, file, web, external, or unknown
event. It applies existing rollback markers before counting and revalidates
thread identity plus rollout identity under the shared agent-message lock.
Unsafe or changing state and ambiguous rollback acknowledgement fail closed.
Rollback does not undo local or external effects, so removed prompts are never
replayed. Other selector classes do not start this watcher.

After a nonzero process exit, the supervisor writes Codex doctor's redacted
JSON to one mode-0600 runtime temporary file, reads only the status of
`auth.credentials`, `config.load`, `installation`, and `state.paths`, then
exact-unlinks the file. Any non-`ok` result or a doctor failure stops. Healthy
local prerequisites classify the exit as transient and use delays of 15, 30,
60, 120, 240, then at most 300 seconds plus zero-to-five seconds of jitter.
Fifteen minutes of process lifetime resets the delay. Exit 0 and operator
signals are terminal, as is the CLI's usage-error exit. `--run` requires all
three standard streams to be attached to an interactive terminal, preventing
a detached non-TTY launch failure from becoming a retry loop.

Per-name state and an exclusive process lock live beneath the current user's
runtime directory. State is value-free and records only mode, selector class,
owner PID, retry count, delay, and reason; it never captures the terminal,
prompt, transcript, error message, diagnostic body, credential, or explicit
session identifier. `--status` cross-checks a running/backoff receipt with its
live owner and reports stale ownership rather than claiming readiness.

The managed Mac reboot workflow starts its next newly created
`harness-codex-resume` pane through this supervisor. It retains every existing
healthy legacy or supervised pane unchanged. Rollback is simply to stop the
foreground supervisor and start `bin/harness-codex` directly; no persistent
service or owner configuration is installed. Publishing or synchronizing a
new supervisor revision does not signal a running TUI; adoption requires a
separate deliberate restart.

On Linux, do not run `codex update`. Upgrade the two reviewed release records
in `tools/agents.tsv`, publish them through protected `main`, synchronize the
managed checkouts, and use the transactional agent command on each logical
host:

```bash
./bin/harness agent --host HOST --name codex --plan
./bin/harness agent --host HOST --name codex --apply
```

The command downloads only the declared official HTTPS artifacts, verifies
their SHA-256 digests and package identities, atomically advances
`~/.local/bin/codex`, retains the predecessor for unchanged-only rollback, and
refuses an ordinary downgrade.

## Lock-aware arg0 housekeeping and the Linux NFS wrapper

On Linux and macOS, `codex-arg0-housekeeping` classifies immediate helper
directories without stopping Codex. Held locks are live. Linux uses native
`flock`; macOS uses Perl's nonblocking POSIX `flock` and its four-helper Darwin
layout. Old empty directories and platform-expected directories with
acquirable locks move atomically to a same-filesystem private quarantine, and
only that quarantine is removed through guarded-delete. A mode-0600 baseline
lets a launcher identify residue from an invocation whose exit it directly
observed without weakening protection for concurrent sessions.

The separately authorized version-scoped wrapper preserves arguments and exit
status and accepts only the exact official standalone release layout or the
exact harness-managed npm layout for the current Linux architecture. A
standalone install retains the launcher as `codex.real` beside its original
path. A managed install leaves the package tree byte-identical and points the
stable link to a separate version-and-architecture-scoped wrapper whose
`codex.real` symlink names the original managed launcher. It runs bounded
housekeeping before and after that preserved launcher. Apply and rollback do
not signal or reload existing Codex processes. The managed-agent plan verifies
both the wrapper and the unchanged package-tree digest and reports the current
version as managed. Roll back a managed wrapper before a managed Codex version
upgrade, then re-diagnose the new release before another wrapper installation.
An official standalone upgrade changes its stable release link and supersedes
the old version's wrapper.

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
sentinels at `~/.codex/AGENTS.md` and `~/.claude/CLAUDE.md`, preserves
Codex's optional product-owned user configuration, and removes only recognized
legacy harness configuration:

- the exact managed Claude settings and Codex rule links; and
- exact harness skill links from the three former user discovery directories.

`~/.codex/config.toml` may be absent or a mode-0600, current-user-owned,
single-link regular file. The transaction reports only that value-free state
and never reads, copies, hashes, removes, restores, or writes the file.
Symlinks, hard links, broader modes, wrong ownership, and non-regular paths
fail closed.

Unrelated entries—including Codex's vendor-owned `.system` directory—remain.
Different symlinks, unsafe parents, dirty checkouts, and concurrent managed
changes fail closed. `--adopt` remains accepted for controller compatibility
but never authorizes an unrelated preimage.

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
