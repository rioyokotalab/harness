# T-304 project-scoped Codex and Claude configuration

## Status

- Phase: ready for execution
- Owner outcome: Codex and Claude must be launched from `~/harness` on all
  managed Linux and Mac systems; machine-global behavior must not define the
  working environment.
- Target fleet: Local, AB, AB2, RI, AL, RC, T4, ABQ, Aist, Home, Office, and
  Riken.
- Next action: wait for the owner's explicit `go`, then execute the frozen
  plan without further interruption unless an unavoidable boundary is reached.
- Authority: read-only discovery and ledger updates only until every decision
  is frozen and the owner gives an explicit `go`.

## Execution checkpoints

- 2026-07-24 baseline: `tests/test-agent-config.sh`,
  `tests/test-agent-config-fleet.sh`, `tests/test-onboard-external-user.sh`,
  and `tests/test-claude-takeover.sh` all passed before implementation.
  Confirmed boundary: the current installer owns global instruction/rule/skill
  links, while `agent-config` owns global Codex/Claude settings and the
  launcher. The migration must retain the launcher but replace both global
  configuration surfaces.
- 2026-07-24 implementation checkpoint: repository-native root policy,
  Codex/Claude project permission files, 13 exact skill links per client,
  minimal sentinels, schema-2 transactional legacy cleanup, and revised
  external-user onboarding are implemented. Focused agent-config,
  agent-config-fleet, Claude-takeover, and external-onboarding tests pass.
  The first phase-one run found expected stale assertions in
  `test-repository-independence`, `test-personal-macos-plan-doctor`, and
  `test-personal-macos-control`. Tmux and terminfo failed only because their
  clean-checkout gates observed this uncommitted checkpoint; rerun them from
  the committed tree before classifying them as regressions.
- 2026-07-24 validation checkpoint: the committed clean-tree rerun passed the
  complete `tests/test-phase1.sh` suite. The Mac plan/control assertions and
  final generic control-plane assertions now validate sentinels and the
  absence of global skill links. Documentation is updated for the schema-2
  project-scoped contract. Next: protected CI, then Local/Linux/Mac pilots.
- 2026-07-24 protected publication: PR #285 passed `portable-phase1` and was
  squash-merged as `19235ce`. The first read-only Local pilot plan found no
  path collision, but pre-apply review caught that schema 2 had omitted the
  existing declaration-aware `~/.local` symlink exception needed by managed
  storage layouts. No live mutation occurred. A follow-up restores only that
  strict host/profile/ownership/containment check and adds a linked-home
  regression test before pilots resume.

## Source evidence

Official Codex documentation establishes:

- Global guidance is `~/.codex/AGENTS.md`; project guidance is discovered from
  `AGENTS.md` between the Git root and working directory.
  <https://learn.chatgpt.com/docs/agent-configuration/agents-md>
- Trusted project settings load from `.codex/config.toml`.
  <https://learn.chatgpt.com/docs/config-file/config-advanced#project-config-files>
- repository skills load from `$REPO_ROOT/.agents/skills`, and symlinked skill
  directories are supported.
  <https://learn.chatgpt.com/docs/build-skills>

Official Claude Code documentation establishes:

- user and project settings are separate; project settings belong in
  `.claude/settings.json`, while `~/.claude.json` combines preferences, OAuth,
  MCP, project state, and caches.
  <https://code.claude.com/docs/en/configuration>
- project instructions load from root `CLAUDE.md` or
  `.claude/CLAUDE.md`; root `CLAUDE.md` may import `AGENTS.md`.
  <https://code.claude.com/docs/en/memory>
- project skills load from `.claude/skills/<name>/SKILL.md`, and skill
  directories support live discovery and symlinks.
  <https://code.claude.com/docs/en/slash-commands>

## Confirmed current state

- The repository has:
  - the 198-line shared policy in `.codex/AGENTS.md`;
  - project-only additions in root `AGENTS.md`;
  - root `CLAUDE.md` containing `@AGENTS.md`;
  - `.claude/CLAUDE.md` linked to the shared policy;
  - project Codex rules in `.codex/rules/default.rules`;
  - public settings bodies in `config/agent-clients/codex.toml` and
    `config/agent-clients/claude.json`;
  - 13 canonical skills under `shared/skills/`;
  - no project `.codex/config.toml`, `.claude/settings.json`,
    `.agents/skills`, `.codex/skills`, or `.claude/skills`.
- Every system currently has:
  - an exact harness guidance link at `~/.codex/AGENTS.md` and
    `~/.claude/CLAUDE.md`;
  - a managed regular `~/.codex/config.toml`;
  - a managed link at `~/.claude/settings.json`;
  - a global Codex rules link;
  - exact links for all 13 skills in `~/.codex/skills`,
    `~/.agents/skills`, and `~/.claude/skills`;
  - current managed launcher configuration.
- Local, AB, and all four Macs have one unrelated entry in
  `~/.codex/skills`: the vendor-owned `.system` directory. Other unrelated
  entries were not found.
- `~/.claude.json` is a regular file on Local, T4, Office, and Riken and absent
  elsewhere. Its content was not read. Official documentation says this path
  can contain OAuth and other mixed state.
- Existing Mac Codex tmux sessions run from `~/harness`. Target migration must
  not stop them or the remote-control/app-server processes.

## Proposed end state

### Repository scope

1. Make root `AGENTS.md` self-contained by combining the stable shared policy
   and harness project rules. Keep root `CLAUDE.md` as the one-line import
   `@AGENTS.md`; remove the redundant project `.claude/CLAUDE.md`.
2. Add `.codex/config.toml` with the current reviewed Codex policy and
   `.claude/settings.json` with the current reviewed Claude policy.
3. Retain `.codex/rules/default.rules` only as a project rule.
4. Add exact tracked symlinks for each canonical skill:
   - `.agents/skills/<name>` -> `../../shared/skills/<name>` for Codex;
   - `.claude/skills/<name>` -> `../../shared/skills/<name>` for Claude.
5. Keep `shared/skills/` as the single skill source and update tests,
   documentation, installer behavior, config doctor, and fleet reconciliation
   to reject drift.
6. Update `onboard-external-user` and its focused tests so a clean Linux or
   macOS onboarding validates the tracked project settings and project skill
   discovery, installs only the two minimal global sentinels, and never
   installs user-global behavioral settings or harness skill links.

### User scope

1. Replace `~/.codex/AGENTS.md` with a minimal sentinel for accidental launches
   outside `~/harness`.
2. Replace `~/.claude/CLAUDE.md` with an equivalent Claude sentinel.
3. Remove only the exact harness-managed global paths:
   - `~/.codex/config.toml`;
   - `~/.codex/rules/default.rules`;
   - the 13 exact harness skill links from `~/.codex/skills`;
   - the 13 exact harness skill links from `~/.agents/skills`;
   - `~/.claude/settings.json`;
   - the 13 exact harness skill links from `~/.claude/skills`.
4. Preserve unrelated entries and parent directories when non-empty. Remove an
   empty harness-created parent only with exact identity and empty-directory
   checks.
5. Preserve client binaries, `harness`, `harness-codex`, shell startup,
   authentication, sessions, memories, caches, databases, remote control,
   auto-memory, and all unrelated files.

## Execution sequence

1. Add failing source-contract and focused tests for repository discovery,
   sentinels, exact managed removal, unrelated-state preservation, collision
   refusal, rollback, idempotence, and cold-start client evidence.
2. Build the repository-scoped instruction, settings, rules, and skill
   surfaces; update docs, installer contracts, and the
   `onboard-external-user` workflow.
3. Replace the current global `agent-config` transaction with a schema-versioned
   plan/apply/doctor/rollback migration that:
   - identifies only exact current managed preimages;
   - records mode-0600 rollback evidence without credential access;
   - atomically installs sentinels;
   - exact-unlinks only declared harness links/settings;
   - refuses changed, ambiguous, hard-linked, unrelated, or concurrent state;
   - never terminates a running client.
4. Validate shell syntax, ShellCheck, focused suites, source contracts,
   `git diff --check`, and the full phase-one suite.
5. Publish through a protected task branch and wait for required CI.
6. Pilot Local:
   - capture value-free preimage identity;
   - apply;
   - verify project settings/rules/skills from `~/harness`;
   - verify the home-directory sentinel;
   - prove credentials, client state, unrelated `.system`, binaries, and
     running services are unchanged;
   - execute an exact rollback/reapply drill.
7. Pilot one remote Linux node and one Mac with the same acceptance gates.
   Preserve all live Mac processes.
8. Merge the protected change, guarded-sync every clean checkout, then migrate
   the remaining systems one at a time with per-host rollback available.
9. Gracefully restart only selected interactive TUI sessions after fleet
   acceptance; never kill remote-control/app-server processes.
10. Run final cold-start probes from `~/harness` and `$HOME`, verify all 13
    project skills for both clients, exact project settings, no global harness
    config beyond sentinels, clean/current repositories, zero transfer/helper
    residue, and fresh fleet health.

## Safety, rollback, and interruption

- No credentials or mixed private state may be read, copied, hashed, or
  modified.
- Do not remove a path merely because its name resembles a harness path.
  Require exact symlink targets or the existing strict managed grammar.
- Bulk or recursive deletion is prohibited. Exact symlinks are unlinked only
  through the reviewed transaction; empty directory removal requires an exact
  empty-directory check. Any directory tree removal uses `guarded-delete`.
- Repository rollback is a normal protected revert. Per-host rollback restores
  exact preimage bytes, modes, and link targets only while every postimage is
  unchanged.
- Running clients retain their already-loaded configuration until restarted.
  The migration never signals them.
- Stop on collision, unrelated entry, credential/state ambiguity, dirty or
  divergent checkout, failed protected CI, or a new material decision.
- Checkpoint after each test baseline, implementation commit, protected
  publication, pilot, host migration, and final validation.

## Acceptance criteria

- Codex launched in `~/harness` loads root policy, project config/rules, and all
  13 skills without depending on harness-managed global configuration.
- Claude launched in `~/harness` loads root policy, project settings, and all
  13 skills without depending on harness-managed global configuration.
- Accidental `$HOME` launches receive the frozen sentinel behavior selected in
  D2 and do not silently work under stale harness policy.
- No harness-managed global config remains except the two sentinels.
- Authentication, sessions, memories, caches, databases, binaries, unrelated
  skills, `.system`, remote control, tunnels, and repository user work are
  unchanged.
- Plan/apply/doctor/rollback are idempotent and fail closed on every tested
  collision or concurrent change.
- Focused and full tests, protected CI, local/Linux/Mac pilots, all 12 final
  doctors, checkout convergence, and fleet health pass.
- External-user onboarding documents and validates the same project-scoped
  Codex/Claude permission settings without assuming owner fleet state.

## Decision register

### D1 — Mixed authentication/state boundary

- Recommended: interpret “global config” as harness-managed behavioral and
  discovery files only. Preserve `~/.claude.json` wholesale, plus all Codex and
  Claude auth, session, memory, cache, database, trust/runtime state, and
  binaries.
- Alternative: include `~/.claude.json` or other mixed state. Rejected by the
  proposed safety boundary because it cannot be separated without inspecting
  or destroying authentication and private runtime state.
- Owner decision: delete global config and credential files only when doing so
  does not affect Codex launched from `~/harness`. Authentication and runtime
  state are still consumed by that project-scoped client; deleting them would
  sign out future launches, break resume/history, and can disrupt Mac remote
  control. The owner's condition therefore selects the recommended
  preservation boundary.
- Status: selected — preserve credentials and mixed runtime state; remove only
  replaceable harness-managed behavior and discovery configuration.

### D2 — Accidental launch behavior

- Recommended: keep a minimal global instruction sentinel for each client that
  tells the agent it is outside `~/harness`, refuses task work, and prints the
  exact restart command. This is portable even after an accidental client
  reinstall.
- Alternative A: informational warning but continue working outside harness.
- Alternative B: add a shell launcher guard that exits before the client
  starts, in addition to the sentinel.
- Owner decision: use the minimal client instruction sentinels. When Codex or
  Claude starts outside `~/harness`, it must immediately direct the owner to
  restart from `~/harness` and refuse task work. Keep the client process open;
  do not add a shell launcher guard.
- Status: selected — refuse task work outside `~/harness`.

### D3 — Existing interactive sessions

- Recommended: never interrupt them during migration; after validation,
  gracefully restart only the four Mac tmux TUIs one at a time in
  `~/harness`, preserving remote control.
- Alternative: leave every existing session on its already-loaded context
  until the owner restarts it manually.
- Owner decision: after project-scoped discovery and settings pass validation,
  gracefully restart the four Mac Codex tmux sessions one at a time from
  `~/harness` and resume each latest session. Preserve remote-control
  continuity and at least one working route throughout.
- Status: selected — sequential validated restart and resume.

### D4 — Project permission posture

- Recommended: preserve the current reviewed project behavior:
  Codex `approval_policy="never"` plus `sandbox_mode="danger-full-access"`, and
  Claude `bypassPermissions` plus its warning suppression, now in tracked
  project settings.
- Alternative: return either client to its default permission prompts.
- Owner decision: preserve the current reviewed non-interactive permission
  posture in tracked project settings. Update the Linux/external-user
  onboarding skill so new harness checkouts receive and validate these same
  project-scoped settings.
- Status: selected — preserve current permissions at project scope.
