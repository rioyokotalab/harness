# Codex and Claude user configuration

The harness owns exactly one public user-settings body for each client:

- `config/agent-clients/codex.toml`
- `config/agent-clients/claude.json`

Claude's live path is a direct link. Codex's live path is an owner-only regular
file containing each key from the public body exactly once. Its optional local
body may add one opaque `model` string and one opaque
`model_reasoning_effort` string; all four top-level keys must precede
client-written trusted-project tables.
Their values remain private and are never inventoried or copied into Git.
Authentication,
credentials, sessions, histories, memories, caches, databases, private
endpoints, and machine-specific trust remain outside this contract.

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
The managed live launcher is `~/.local/bin/harness-codex`. Fresh managed
interactive Bash shells define a shell-local `codex` function that calls it;
non-interactive and batch shells retain native resolution. The wrapper uses an
absolute native path, preventing recursion or silent fallback, and preserves
all arguments and subcommands. Client-persisted project trust stays only in the
private live regular file and never dirties public Git.

## Declarative components

`config/agent-clients/components.tsv` is the single public declaration surface
for reviewed hooks, plugins, marketplaces, and MCP servers. It currently has no
component entries because no exact identifier or hook command has yet passed a
separate public review. Authentication and installed caches can never be
payloads. Adding the first component requires a protected change that also adds
its exact native reconciliation adapter and rejects interactive, credential,
private-endpoint, and machine-command declarations.

## Local transaction

Read-only commands are value-free:

```bash
./bin/harness agent-config --inventory
./bin/harness agent-config --plan
./bin/harness agent-config --doctor
```

An existing strict regular Codex file containing only the optional local model
keys and client-written trusted-project tables is preservation state and blocks
the normal plan. After separately reviewing its ownership and choosing
`--adopt`, apply adds the canonical policy keys while retaining that validated
local body. Other regular files and different symlinks remain replacement
state. Apply records a mode-0600 local manifest and exact regular-file or
symlink preimages before rendering Codex and linking Claude plus the managed
launcher:

```bash
./bin/harness agent-config --adopt --plan
./bin/harness agent-config --adopt --apply
```

Parent directories must normally be owner-controlled real directories. The
sole symlink exception is `~/.local`: it is accepted only when the selected
logical host has `.local` in `profiles/home-layout.tsv`, the canonical target
is strictly below that row's persistent root, and the resolved directory is
owned by the current user. An undeclared host, an escaping target, or any other
symlink parent is rejected.

The apply output contains a transaction identifier. Rollback first proves all
three managed paths and every transaction-created directory are unchanged, then
restores exact prior bytes, modes, and symlink targets. `--drill` automates one
apply, unchanged-only rollback, accepted reapply, and doctor sequence. Changes
activate only in fresh Codex and Claude sessions.

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

No command automatically commits, pushes a configuration edit, reloads an
active client, installs a component, or supplies authentication. Editing a live
settings link dirties the harness checkout; catch-up stops until normal Git
review publishes or deliberately discards that edit.
