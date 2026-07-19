# T-269 plan — private cross-platform Codex and Claude configuration

**Phase:** interviewing

## Desired outcome

Give all four personal Macs and all seven managed Linux environments one
reviewed, pull-compatible Codex/Claude configuration system. Routine agent
behavior, permission posture, hooks, profiles, plugin declarations, and other
deliberately selected user configuration should converge after a long offline
period without placing personal configuration or machine identity in the public
harness. Authentication, credentials, sessions, transcripts, histories,
memories, caches, and other runtime state must remain local.

The system must explain effective behavior from configuration precedence,
refuse ambiguous drift, support exact local rollback, and never interpret
"mirror all configuration" as permission to copy a client state directory.

## Confirmed facts

### Current harness ownership

- The public harness currently links global Codex/Claude guidance, Codex rules,
  shared skills, and the `harness` command on Linux and macOS.
- It deliberately excludes live `~/.codex/config.toml`,
  `~/.claude/settings.json`, authentication, client state, plugins, hooks,
  sessions, histories, memories, caches, and databases.
- T-268 established a pull-only private Git companion for curated personal-Mac
  desired state and a public-engine/private-policy compatibility contract. Its
  current schema intentionally does not copy local configuration.
- Macs may be offline for long periods and must converge by clean direct
  fast-forward plus schema migration, not by replaying every intermediate
  rollout. Linux remains controller-synchronized only through guarded clean
  checkout fast-forwards.

### Value-free local baseline

- The current Linux node has a regular mode-0600 Codex user config with
  `approval_policy=never` and `sandbox_mode=danger-full-access`. It contains one
  model selection, one reasoning-effort selection, and 93 path-specific trusted
  project records. No Codex MCP, hook, agent, custom permission, provider, or
  telemetry table is present.
- Its regular mode-0600 Claude user settings use
  `permissions.defaultMode=bypassPermissions`. The settings contain eleven
  command-hook event groups and additional user-interface/model preferences;
  no Claude settings-level environment values or enabled-plugin declarations
  are present.
- Codex 0.144.6 and Claude Code 2.1.207 are installed on the current node. No
  system Codex config/requirements or Claude managed-settings file is present,
  and neither client home is redirected by an environment variable.
- Credential and high-churn state files exist locally but were not read. Beyond
  the whitelisted behavioral keys and aggregate counts above, no configuration
  values, hook commands, project paths, endpoints, environment values,
  credential values, or authentication material were emitted.
- The pilot Mac has repeated Codex approval prompts. Its effective settings and
  launch flags have not yet been inventoried, so the missing Linux-equivalent
  user config is the leading explanation, not yet a proven exclusive cause.

### Product configuration semantics

- Codex loads CLI overrides, trusted project config, a selected user profile,
  user `~/.codex/config.toml`, system config, then built-ins in descending
  precedence. Project config is ignored until the project is trusted. Approval
  policy controls prompting independently from the filesystem/network sandbox.
  Sources: [Codex configuration basics](https://learn.chatgpt.com/docs/config-file/config-basic),
  [sandbox and approvals](https://learn.chatgpt.com/docs/agent-approvals-security).
- Claude user settings live at `~/.claude/settings.json`; project and local
  settings are separate, while `~/.claude.json` combines OAuth, MCP, trust, and
  cache/state that must not be mirrored as a file. User settings can contain
  permissions and hooks. Sources: [Claude settings](https://code.claude.com/docs/en/configuration),
  [permissions](https://code.claude.com/docs/en/permissions),
  [hooks](https://code.claude.com/docs/en/hooks), and
  [permission modes](https://code.claude.com/docs/en/permission-modes).

## Scope

- Add a generic public engine for value-free inventory, strict schema
  validation, plan, transactional apply, doctor, unchanged-only rollback, and
  direct old-schema catch-up.
- Extend the private companion contract to carry curated portable client
  intent, common and OS-class variants, opaque logical host selections, and an
  explicit desired plugin/marketplace/MCP inventory if selected in interview.
- Cover user-level Codex config/profile files and Claude settings plus selected
  user-level config directories only through an explicit allowlist.
- Diagnose effective permission behavior from the user config, project layer,
  profile/launch overrides, system/managed policy presence, and declared client
  version without printing private values.
- Preserve all existing public guidance, rules, skills, public/private update,
  privacy, transaction, rollback, and sequential rollout invariants.

## Non-goals and prohibited payloads

- Never version or mirror Codex `auth.json`, history, sessions, logs, SQLite,
  caches, package cache, installation IDs, or connector authorization.
- Never version or mirror Claude `.credentials.json`, `~/.claude.json`, project
  transcripts, auto-memory contents, caches, backups, install IDs, OAuth, or
  user/local MCP credentials.
- Never copy raw project trust maps, absolute paths, observed local settings,
  environment values, private endpoints, hook output, or credential-helper
  results into the public repository or public evidence.
- Do not manage macOS TCC, Accessibility, Screen Recording, Keychain, system
  preferences, MDM profiles, or system-managed client policy.
- Do not reload a running Codex/Claude session. Acceptance is in fresh sessions.
- Do not install, remove, enable, or authorize a plugin, MCP server, connector,
  marketplace, or credential until its separately frozen decision and native
  transaction are authorized.

## Recommended architecture

1. Keep generic schemas, validators, transactions, synthetic fixtures, and
   privacy-negative tests public. Keep curated personal desired configuration
   in the existing private Git companion.
2. Extend the companion from Mac-only host declarations to a client-config
   policy consumed by both Mac and Linux adapters. Use common policy plus
   `darwin`/`linux` variants and opaque host selectors only where behavior truly
   differs.
3. Treat live client files as generated transactional products, not Git
   worktrees. A strict allowlist composes a complete mode-0600 Codex TOML and
   Claude JSON from private desired intent. Unknown keys, inline credential
   values, unsafe commands, unresolved paths, and schema drift stop before
   mutation.
4. Keep path-specific trust as logical project declarations resolved locally.
   Never transplant the current 93 absolute Linux paths to a Mac. A trust
   declaration must name a reviewed local project root class and validate that
   the corresponding checkout exists before generating a client entry.
5. Store portable hook implementation in a reviewed repository surface and
   generate settings that reference stable harness/private-companion paths.
   Commands with machine paths require an explicit OS/host variant. Hooks may
   never embed secret values or emit environment/config dumps.
6. Store desired plugin, marketplace, and MCP declarations separately from
   installed caches and authorization. Resolve them through native client CLIs,
   exact identifiers, and per-client plan/apply gates. Authentication remains a
   local owner action.
7. Every apply records exact preimages locally, writes atomically, validates
   native parsing, and activates only in a fresh session. Rollback is allowed
   only while the managed outputs remain unchanged.
8. Macs pull both repositories and apply locally. Linux adopts on `local`
   first, then advances the six clean remote nodes sequentially with stop on
   first failure. No login/session hook performs network or config mutation.

## Execution sequence after `go`

1. Freeze all interview decisions and mark the plan `ready-for-go`.
2. Add public versioned schemas and synthetic public/private fixtures covering
   every selected client-config category and prohibited payload.
3. Implement value-free inventory of config path kind/mode, selected behavior
   keys, section counts, override sources, client versions, and declared drift.
4. Implement strict private composition for Codex TOML and Claude JSON,
   including portable/common, OS-class, and host overlays.
5. Implement trust-path resolution from logical declarations without recording
   observed paths in public output.
6. Implement hook/profile/plugin/marketplace/MCP adapters only for categories
   selected during interview; separate declaration, installation, enablement,
   and authorization.
7. Add transaction, preimage, atomic replacement, native parse, idempotence,
   doctor, rollback, and old-schema direct-migration tests.
8. Run focused privacy/config tests, ShellCheck, public-repository audit, and
   the complete portable phase-one suite; publish through protected CI.
9. On `office`, run value-free discovery and an owner-reviewed adoption plan.
   Apply, validate a fresh client session, rollback unchanged outputs, verify
   the prior image, then reapply only under separate pilot authority.
10. On `local`, adopt/plan/apply/rollback/reapply with the same gates and prove
    that the selected behavior matches `office` while OS-specific entries do
    not leak across platforms.
11. Roll out one clean Linux remote at a time, then one remaining pull-based Mac
    at a time. Each node independently validates effective config and stops on
    any unexpected prompt, policy, path, or plugin state.

## Risks and recovery

- Global full-access/bypass defaults materially expand blast radius. Permission
  posture is therefore a separate owner decision rather than an inferred copy
  of the current Linux node.
- Copying complete live files can import credentials, private endpoints,
  machine paths, obsolete keys, or project trust. The recommended allowlisted
  composition rejects exact-file mirroring.
- Client versions may accept different keys. The plan pins a supported version
  floor, validates with each native client, and migrates schema before apply.
- Client UI/CLI edits can drift from the private source. Doctor reports drift
  without overwriting it; an explicit owner-reviewed `adopt` transaction is the
  only path back to the canonical desired source.
- A hook or plugin can execute code on every prompt/tool event. Each executable
  source and native install/enable action must be reviewed, versioned, and
  independently disableable through rollback.
- A private-repository fast-forward may succeed while public update fails (or
  vice versa). Compatibility is resolved after both updates and before any
  config plan; partial repository advancement is harmless and retryable.

## Validation and acceptance

- Public history, logs, plans, CI, and doctors contain no host names, absolute
  private paths, local config values, endpoints, credentials, hook commands, or
  raw live-file bytes.
- Every chosen category has positive, malformed, secret-like, unknown-key,
  unsafe-path, unsafe-command, wrong-mode, symlink, collision, drift, and
  old-schema tests.
- Existing Linux and T-268 Mac behavior remains unchanged until an explicit
  client-config apply. Unselected files and directories remain byte-for-byte
  untouched.
- A long-offline synthetic Mac and Linux node advance directly from schema 1 to
  current, produce the same portable effective config, retain required OS
  differences, and converge to a second-run no-op.
- Pilot and local apply/rollback/reapply preserve exact preimages and activate
  only in fresh sessions. Effective permission behavior matches the frozen
  decision without unplanned prompts or silent privilege expansion.
- Plugin/MCP/connector authorization and all credential files remain local and
  unchanged. Installed package caches are never Git payloads.
- The final doctor reports agreement across four Macs and seven Linux nodes,
  while each pull-based Mac remains independently usable when offline.

## Decision register

### C1 — Default permission posture (open; ask first)

- **A — Two-tier autonomy (recommended):** ordinary sessions use a zero-routine-
  prompt but bounded mode; an explicit owner launcher selects full
  access/bypass only for authorized machine/fleet work. This reduces ambient
  blast radius while keeping an intentional unattended route.
- **B — Exact Linux parity everywhere:** Codex globally uses
  `danger-full-access` plus `never`, and Claude globally uses
  `bypassPermissions`. This most directly removes prompts but makes every new
  session maximally privileged.
- **C — Interactive default:** retain workspace/on-request and Claude default
  permissions, accepting routine prompts.

### C2 — Canonical storage (open)

- **A — Existing private companion (recommended):** generic engine public;
  curated client intent private; both repositories remain independently
  testable and fast-forwarded.
- **B — Public portable subset plus private overlay:** easier Linux distribution
  but deliberately exposes some personal preference/configuration publicly.
- **C — Separate second private repository:** stronger conceptual separation at
  the cost of a third checkout and compatibility axis on every node.

### C3 — Managed configuration breadth (open)

- **A — Allowlisted broad configuration (recommended):** manage every reviewed
  portable key/category while excluding runtime/credential state and composing
  OS/host variants.
- **B — Exact whole-file mirroring:** simplest mental model but unsafe for trust,
  paths, credentials, and client-generated state.
- **C — Permission keys only:** solves the immediate prompt mismatch but does
  not meet the stated broader mirroring goal.

### C4 — Project trust (open)

- **A — Logical project declarations (recommended):** private desired state
  names reviewed project classes; each node resolves its own path and generates
  trust only for existing expected checkouts.
- **B — Do not synchronize trust:** every node retains independent prompts and
  trust state.
- **C — Mirror raw trust maps:** rejected by the recommended design because
  absolute Linux paths do not port to Macs and trust must not be inferred.

### C5 — Hooks, plugins, marketplaces, and MCP (open)

- **A — Declarative desired state (recommended):** sync reviewed declarations
  and repository-owned hook code; native plan/apply installs or enables exact
  components; credentials and authorization remain local.
- **B — Hooks only:** sync current automation but leave plugins/MCP independent.
- **C — Exclude all four:** synchronize scalar client preferences only.

### C6 — Editing and drift model (open)

- **A — Private source with explicit adopt (recommended):** normal UI/CLI edits
  become detected drift; an owner-reviewed adopt transaction updates private
  desired state, and normal apply never overwrites unexplained drift.
- **B — Live file is source:** automatically publish local changes, which risks
  secrets, partial edits, and unintended cross-node rollout.
- **C — Per-node unmanaged overlay:** preserves ad hoc edits but prevents exact
  cross-node agreement and complicates precedence.

### C7 — Rollout order (open)

- **A — `office`, `local`, six Linux remotes, remaining Macs (recommended):**
  prove both OS families and rollback before broad rollout; stop on first
  failure and never reload active sessions.
- **B — Linux first:** quicker seven-node parity but leaves the original Mac
  problem untested until late.
- **C — all Macs first:** validates the pull-based family but defers the known
  Linux canonical baseline.

## Exact next action

Ask C1 only. After each answer, checkpoint the decision and ask the next open
item. Do not change any live client setting during the interview. After C7,
audit for contradictions, set `ready-for-go`, and wait for a fresh explicit
`go`.
