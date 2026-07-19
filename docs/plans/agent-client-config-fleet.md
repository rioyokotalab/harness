# T-269 plan — private cross-platform Codex and Claude configuration

**Phase:** interviewing

## Desired outcome

Give all four personal Macs and all seven managed Linux environments one
reviewed, pull-compatible Codex/Claude configuration system. Routine agent
behavior, permission posture, and other deliberately selected portable user
configuration should converge after a long offline period from one public
canonical settings body per client in `harness`. Authentication, credentials,
sessions, transcripts, histories, memories, caches, machine identity, private
paths/endpoints, and other runtime state must remain local.

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

- Add one reviewed public canonical Codex TOML body and one reviewed public
  canonical Claude JSON body, plus value-free inventory, strict validation,
  transactional symlink apply, doctor, unchanged-only rollback, and direct
  old-state catch-up.
- Link `~/.codex/config.toml` and `~/.claude/settings.json` directly to their
  respective tracked canonical files. Do not generate, copy, or privately
  overlay either live settings file.
- Cover additional user-level configuration only when a later frozen decision
  gives it an equally singular, public, portable representation.
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
  results into the canonical public files or public evidence.
- Do not manage macOS TCC, Accessibility, Screen Recording, Keychain, system
  preferences, MDM profiles, or system-managed client policy.
- Do not reload a running Codex/Claude session. Acceptance is in fresh sessions.
- Do not install, remove, enable, or authorize a plugin, MCP server, connector,
  marketplace, or credential until its separately frozen decision and native
  transaction are authorized.

## Recommended architecture

1. Keep each reviewed, portable settings body beside the generic validators,
   transactions, synthetic fixtures, and privacy-negative tests in the public
   harness. The private companion is not a source or overlay for client
   settings.
2. Treat the tracked files as the only managed settings bodies. There are no
   generated copies, common/OS/host composition layers, or per-node managed
   overlays. A change made through a live symlink changes the local Git
   worktree and must pass normal review before publication.
3. Validate the complete tracked Codex TOML and Claude JSON before linking.
   Unknown or unsupported keys, credential-like values, private paths or
   endpoints, unsafe commands, and non-portable behavior stop before mutation
   or publication.
4. Do not place the current 93 absolute Linux trust records in the canonical
   Codex file. Project-specific trust/configuration needs a later portable
   decision that does not create a second user-settings body.
5. Store portable hook implementation in a reviewed repository surface only if
   selected. Hook references must be identical and portable on every target;
   machine-path or host-specific commands cannot enter the canonical settings.
6. Keep desired plugin, marketplace, and MCP declarations separate from
   installed caches and authorization. If selected, resolve them through native
   client CLIs and exact public identifiers; authentication remains local.
7. Every link apply records exact prior path type/content locally, validates
   the target and parents, replaces atomically, and activates only in a fresh
   session. Rollback is allowed only while the linked output remains unchanged.
8. Macs pull the public harness and apply locally. Linux adopts on `local`
   first, then advances the six clean remote nodes sequentially with stop on
   first failure. No login/session hook performs network or config mutation.

## Execution sequence after `go`

1. Freeze all interview decisions and mark the plan `ready-for-go`.
2. Add the two public canonical settings files plus synthetic fixtures covering
   every selected client-config category and prohibited payload.
3. Implement value-free inventory of config path kind/mode, selected behavior
   keys, section counts, override sources, client versions, and declared drift.
4. Implement strict complete-file validation and direct collision-refusing
   links for Codex TOML and Claude JSON; do not create rendered copies.
5. Implement the frozen project-trust decision without adding raw paths or a
   second managed user-settings body.
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
- Because the tracked files are public and linked live, an accidental edit can
  expose credentials, private endpoints, machine paths, obsolete keys, hook
  commands, or project trust in Git. Pre-commit/public-history privacy gates
  and strict complete-file validation must reject such content; clean-checkout
  catch-up stops on any unpublished local edit.
- Client versions may accept different keys. The plan pins a supported version
  floor, validates with each native client, and migrates schema before apply.
- A client or owner edit through a live symlink dirties the harness checkout.
  Doctor reports that state, and fleet catch-up refuses to overwrite it; normal
  Git review is the only publication path.
- A hook or plugin can execute code on every prompt/tool event. Each executable
  source and native install/enable action must be reviewed, versioned, and
  independently disableable through rollback.
- A long-offline node fast-forwards the one public source directly to current
  before link validation. There is no second repository compatibility axis.

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
- A long-offline synthetic Mac and Linux node advance directly from an old
  public state to current, link the same portable settings bodies, and converge
  to a second-run no-op.
- Pilot and local apply/rollback/reapply preserve exact preimages and activate
  only in fresh sessions. Effective permission behavior matches the frozen
  decision without unplanned prompts or silent privilege expansion.
- Plugin/MCP/connector authorization and all credential files remain local and
  unchanged. Installed package caches are never Git payloads.
- The final doctor reports agreement across four Macs and seven Linux nodes,
  while each pull-based Mac remains independently usable when offline.

## Decision register

### C1 — Default permission posture (selected)

- **Selected — Zero client action-approval prompts:** the owner's exact
  requirement is, "I don't want to be asked for approval by anyone." Within
  T-269, ordinary and newly started Codex and Claude sessions must therefore
  produce no agent action-approval prompts. Codex globally uses `never` plus
  `danger-full-access`; Claude globally uses `bypassPermissions` and suppresses
  its dangerous-mode startup warning. This supersedes the earlier two-tier
  recommendation.
- This decision does not suppress authentication, macOS privacy/TCC, OS
  administrator, workspace/provider policy, or other non-agent system dialogs.
  No target configuration changed during the interview checkpoint.

### C2 — Canonical storage (selected)

- **Selected — One public canonical file per client with direct live links:**
  the owner requires "only one copy in the harness and a symbolic link to it
  for local files." `harness` therefore contains one tracked Codex TOML body
  and one tracked Claude JSON body, while `~/.codex/config.toml` and
  `~/.claude/settings.json` are direct symbolic links to them on every target.
- There is no private companion, generated live copy, OS/host overlay, or
  machine-local managed overlay for these two files. Their selected contents
  must be identical across the fleet and safe to publish. Credentials,
  authentication, private paths/endpoints, runtime state, and machine-specific
  values remain local outside these linked settings files. No live link or
  settings file changed during this interview checkpoint.

### C3 — Public canonical content breadth (open; ask next)

- **A — Broad portable settings (recommended):** the linked whole files contain
  every reviewed key that is identical on macOS and Linux and safe to publish,
  including the frozen permission posture and portable UI/model preferences.
  Machine-specific trust, private paths/endpoints, credential-bearing values,
  runtime state, and non-portable commands are excluded entirely.
- **B — Permission posture only:** the linked files contain only the settings
  needed to eliminate client action-approval prompts; all other preferences
  remain outside managed user settings.
- **C — Attempt the current complete Linux files:** rejected by the design
  because they contain raw project paths and other values that are not portable
  or suitable for a public repository.

### C4 — Project trust (open)

- **A — Exclude path-specific trust (recommended):** one identical public user
  file cannot safely carry machine-specific absolute roots. Codex project trust
  remains outside this user-settings mirror, and Claude's separate local trust
  state remains untouched.
- **B — Require identical public checkout paths:** only reviewed common paths
  could enter the canonical file, but this constrains every Mac/Linux layout
  and deliberately publishes those paths.
- **C — Mirror the current raw trust map:** rejected because absolute Linux
  paths do not port to Macs and local trust must not be inferred.

### C5 — Hooks, plugins, marketplaces, and MCP (open)

- **A — Public declarative desired state (recommended):** sync reviewed public
  declarations and repository-owned hook code; native plan/apply installs or
  enables exact components; credentials and authorization remain local.
- **B — Hooks only:** sync current automation but leave plugins/MCP independent.
- **C — Exclude all four:** synchronize scalar client preferences only.

### C6 — Editing and drift model (constrained by C2; publication still open)

- C2 fixes the live path as a symlink to the Git-tracked canonical file, so an
  edit through the live path is a local harness worktree edit. Automatic commit
  or publication is not implied. C6 will freeze the review/publish and dirty-
  checkout recovery behavior; a second live or managed overlay is excluded.

### C7 — Rollout order (open)

- **A — `office`, `local`, six Linux remotes, remaining Macs (recommended):**
  prove both OS families and rollback before broad rollout; stop on first
  failure and never reload active sessions.
- **B — Linux first:** quicker seven-node parity but leaves the original Mac
  problem untested until late.
- **C — all Macs first:** validates the pull-based family but defers the known
  Linux canonical baseline.

## Exact next action

Ask C3 only. After each answer, checkpoint the decision and ask the next open
item. Do not change any live client setting during the interview. After C7,
audit for contradictions, set `ready-for-go`, and wait for a fresh explicit
`go`.
