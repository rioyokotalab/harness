# Codex and Claude project configuration

The harness owns one reviewed project-settings body for each client:

- `.codex/config.toml`, mirrored by `config/agent-clients/codex.toml`;
- `.claude/settings.json`, mirrored by
  `config/agent-clients/claude.json`.

Codex and Claude load those files only when started from `~/harness`. Root
`AGENTS.md` is the always-read shared policy router; root `CLAUDE.md` imports
it. Exact conditional modules remain project-local under `docs/agent-policy/`.
Every canonical skill has one tracked link under `.agents/skills/` and one
under `.claude/skills/`. No harness behavioral setting, rule, or skill link is
required from the user's home-directory client configuration.

Authentication, credentials, sessions, histories, memories, caches, databases,
private endpoints, and machine-specific runtime state remain outside this
contract and are never inspected or migrated.

## Task-bound Claude handoff

`harness claude-handoff` validates a bounded, expiring packet before a fresh
Claude process is asked to recover durable work. Packet schema 1 binds the task
and run IDs, canonical repository root, exact Git baseline, phase, Fable/high
primary client profile, authority class, allowed paths, source files, checks,
next action, issue time, and expiry. The packet's `model` field records the
primary intent; the project profile and reviewed native invocation add Opus at
high effort as the sole ordered availability fallback. Validation requires
separate expected values from the driver and rejects unknown fields, unsafe
paths, wrong or noncanonical roots, current Git-head drift, wrong
task/run/baseline, future or expired packets, and linked or foreign-owned
packet files:

```bash
./bin/harness claude-handoff validate \
  --packet STAGE/handoff.json \
  --expect-task Har-NNN --expect-run-id RUN_ID \
  --expect-root REPOSITORY --expect-baseline FULL_COMMIT \
  --now YYYY-MM-DDTHH:MM:SSZ
```

The evidence gate is authority-specific. A `read-only` packet has no allowed
write path, and its evidence must contain the exact sealed prompt/input receipt
plus a complete path/digest read manifest and zero execution records. An
`execution` packet must declare relative allowed paths, include a successful
`git rev-parse HEAD` baseline record, and supply command, exit, and output
digests. The baseline output digest is SHA-256 over the exact UTF-8 bytes
`BASELINE_COMMIT\n` from the packet. Codex must independently reproduce one
exact execution record in a separate current-user-owned JSON receipt; model
prose cannot satisfy that requirement.

`verify-evidence` reopens every staged source, the fixed staged
`handoff.json`, and `artifacts/copilot-prompt.md`; it caps each copied source at
1 MiB, checks current-user ownership and single-link regular-file identity,
matches copied bytes to the packet's live declared source files, and then
matches the model's receipt and recovered fields. The packet, evidence, prompt,
and driver receipt retain the narrower 64 KiB input cap. The stage contains
exactly packet source files plus `handoff.json`; extra or missing inputs fail
closed.

```bash
./bin/harness claude-handoff verify-evidence \
  --packet STAGE/handoff.json --stage STAGE/stage.json \
  --evidence STAGE/evidence.json \
  --expect-task Har-NNN --expect-run-id RUN_ID \
  --expect-root REPOSITORY --expect-baseline FULL_COMMIT \
  --now YYYY-MM-DDTHH:MM:SSZ
```

For native structured output, use
`docs/schemas/claude-handoff-structured-output.schema.json`; the canonical
public evidence schema retains its Draft 2020-12 metadata, which Claude Code
2.1.220's native `--json-schema` parser does not accept. A read-only launch uses
explicit `--model fable --effort high --fallback-model opus`, project-only
settings, a nonpersistent print session, `dontAsk`, and only Read/Grep/Glob.
Tool flags are authority reduction, not OS confinement; use an
environment-native read-only filesystem sandbox and seal protected driver
digests around the client window.

Failed rows are never replayed. `verify-retry` requires a distinct next run,
changed input, unchanged protected state, no prior import, no replay, an exact
error digest, and one of the narrow observed outcomes:
`transport-failure`, `launch-validation-failure`, or `candidate-invalid`.
Other or ambiguous outcomes require a separate recovery decision.

These packets are task evidence, not credentials or standing authority. They
do not change the ordinary interactive Claude profile, authorize target
execution, prove model authorship, or replace the task's benchmark, evidence,
owner `go`, and target-write boundaries.

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
dangerous-mode warning. Managed interactive Claude processes also carry the
same explicit `--permission-mode bypassPermissions` pair so project-local
`dontAsk` settings cannot silently disable consumer tools. Claude starts with
Fable/high and has Opus/high as its
sole ordered native fallback for an overloaded, unavailable, or otherwise
eligible server-failed turn. Authentication, billing, rate-limit,
request-size, transport, and shared session or weekly usage-limit failures do
not trigger that fallback and must not be converted into prompt replay. These
choices do not suppress authentication, macOS privacy, administrator,
provider-policy, or Claude's hard-coded root/home recursive-deletion
circuit-breaker prompts.

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
The managed live launcher is `~/.local/bin/harness-codex`. Managed interactive
Bash shells leave `codex` unaliased, so native subcommands such as
`codex --version` resolve normally; resilient resume is explicit through
`harness codex-resilient --run --name harness --last`. Non-interactive and
batch shells also retain native resolution. The
wrapper uses an absolute native path, preventing recursion or silent fallback,
and preserves all arguments and subcommands. Client-persisted project trust
stays only in the private live regular file and never dirties public Git.

## Bounded Personal process

`harness personal-agent` is a non-managed bridge from Harness to the exact
private repository at
`/mnt/nfs-03/safe/Users/rioyokota/projects/personal` on Linux or
`$HOME/projects/personal` on macOS. It never adds a Codex
target, tmux pane, phone thread, app-server root, monitor role, saved root, or
recovery identity. The user launch sentinels admit that one exact path while
labeling it non-managed.

`--run` requires an identified Codex or Claude driver, a bounded task ID, the
`local` domain, and a prompt on standard input. A current-user runtime lock
serializes both clients. The launcher validates the exact real mode-0700
repository and its owned single-link policy/configuration files, scrubs
Harness control variables, streams output without a log, and retains only one
mode-0600 value-free runtime receipt. It never retries a failed or ambiguous
run.

Codex uses `exec --ephemeral --ignore-user-config --strict-config`, Sol/high,
the reviewed granular policy, danger-full-access, disabled history, memory,
feedback, suggestions, and web search. Claude uses non-persistent print mode,
project-only settings, a strict empty MCP configuration, Fable/high with the
sole Opus fallback, `dontAsk`, a narrow local tool list, and disabled
auto-memory, telemetry, feedback, error reporting, and nonessential traffic.
These controls do not establish provider-side retention.

Email, calendar, and research-budget domains fail closed. They remain blocked
until a later protected change provides a Personal-only connector runtime and
the Personal readiness ledger records its independent isolation and
provider-privacy evidence. Installed user-level plugins are not treated as a
project isolation boundary.

## Transient-service supervisor

`harness codex-resilient` is the portable foreground owner for a Codex TUI
inside tmux. It always delegates to `bin/harness-codex`, so the existing
project trust, approval, sandbox, Darwin path, and version-scoped arg0
contracts remain authoritative.

The supervisor supports `--new`, `--last`, and `--session ID`, plus
`--remote-session ID` for an exact app-server-backed thread. An explicit
saved-session identifier is concurrency-safe only after its persisted CWD
matches the current closed target; that check runs before every launch.
The latest-session selector is repository-scoped. Global `--last-all` is
rejected under supervision and remains available only through the intentional
direct launcher. A fresh first launch recovers with repository-scoped
`resume --last`; every other recovery retains its selected resume scope. A
remote selector always retains `resume --remote unix:// ID`. No recovery
command contains a prompt.

One saved ID may still diverge when a standalone TUI and the app server load it
into independent in-memory contexts. Matching IDs therefore do not prove
synchronization. Managed cross-surface use requires the TUI to be an exact
remote peer of the app server. If that bridge cannot be proven, the selected
standalone client remains the sole writer and every other surface uses a
distinct thread with Git and the durable ledger as the handoff.

An exact remote selector starts one target-bound
`harness codex-thread-recovery --watch` child. A one-shot readiness transaction
must succeed before the TUI launches, and the supervisor stops and reaps the
watcher at exit. If a ready watcher unexpectedly exits while the same TUI
remains live, the supervisor reaps that exact child, repeats the existing
safe-tail preflight, and may replace only the watcher without relaunching the
TUI. Replacement is bounded to three consecutive attempts and its budget
resets only after five minutes of watcher stability. Failed preflight,
readiness, or budget exhaustion still terminates the TUI and fails closed.
The helper speaks the local app-server Unix-WebSocket protocol directly and
keeps only a mode-0600, value-free receipt. It can roll back one to eight
trailing turns only when the exact thread is `systemError` and every candidate
turn is complete, has user input, has no assistant response, and contains no
tool, command, file, web, external, or unknown event. It applies existing
rollback markers before counting and revalidates thread identity plus rollout
identity under the shared agent-message lock. Unsafe or changing state and
ambiguous rollback acknowledgement fail closed. Rollback does not undo local
or external effects, so removed prompts are never replayed. Other selector
classes do not start this watcher.

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
