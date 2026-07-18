# T-268 plan — private personal macOS fleet

**Phase:** executing

**Updated:** 2026-07-18 17:49 JST

**Owner:** repository driver

**Target:** four owner-operated personal Macs; identities are intentionally
not recorded here

## Desired outcome

Extend the harness principles to four personal Macs without treating them as
Linux HPC login nodes. The result should give each Mac a reproducible,
inspectable, rollback-aware development and agent environment while keeping
machine identity, local configuration, installed-app inventory, credentials,
and private desired state out of the public harness repository.

The public repository may contain only generic macOS adapters, strict schemas,
deliberately selected non-sensitive baseline policy, synthetic fixtures,
tests, and operating documentation. Live facts and private host declarations
must remain outside the checkout and must never enter CI artifacts or task
ledgers.

## Scope

- model macOS as a separate personal-device family, not as four more HPC fleet
  hosts;
- add value-minimized macOS inventory, plan, doctor, transaction, and rollback
  behavior where the interview authorizes it;
- use the installed Homebrew control plane for selected user tools rather than
  Linux release artifacts;
- preserve macOS-native zsh, SSH agent/Keychain, privacy controls, application
  permissions, login/background-item visibility, and system updates;
- install the same public Codex/Claude guidance and shared skills only through
  collision-refusing repository-owned links;
- validate on one deliberately selected pilot Mac before sequential rollout;
- retain private per-machine state locally or in an explicitly chosen private
  store, never in this public repository.

## Non-goals unless the interview explicitly adds them

- MDM, Apple Business Manager, configuration profiles, FileVault recovery-key
  escrow, Apple Account/iCloud management, or OS update enforcement;
- copying complete dotfiles, `~/Library`, application preferences, browser
  state, histories, caches, SSH configuration, keys, Keychain contents, or
  installed-app inventories;
- public host profiles containing Mac names, serial numbers, hardware UUIDs,
  usernames, network addresses, location, personal app lists, or local paths;
- `brew bundle dump`, `brew bundle cleanup`, unmanaged-formula or cask removal,
  dependency pruning, or service start/restart;
- background agents, login items, launch daemons, cron, or unattended changes;
- inbound SSH/Remote Login enablement, firewall changes, port forwarding,
  tunnels, or agent-forwarding changes;
- Time Machine, personal-data backup, Restic scheduling, or restore automation;
- HPC schedulers, modules, GPU stack, containers, or project repository/data
  synchronization on the Macs;
- replacing Apple system tools or forcing Linux command semantics into the
  default interactive environment.

## Confirmed facts

### Existing harness

- The current managed family is Linux/Bash/HPC-oriented. Inventory observes
  `/etc/os-release` and Bash startup paths; profiles declare schedulers,
  modules, containers, Linux storage roots, and Linux command paths.
- Tool, runtime, Python, and agent installers select Linux artifacts and depend
  on GNU-style `stat -c`, `sha256sum`, and `readlink -f` in material paths.
- Fleet sync assumes the controller can initiate BatchMode SSH to a reachable
  target and that both ends support the current POSIX/GNU command contract.
- The local cluster login node uses a packaged systemd user SSH agent; this is
  explicitly Linux-specific and must not be transplanted to macOS.
- The public repository already defines the right privacy principle: generated
  state belongs under user-local state, optional owner configuration belongs
  outside tracked policy, and secrets/live client state are never synchronized.

### macOS and Homebrew evidence

- Apple documents zsh as the default Terminal shell, so Bash startup blocks are
  not the correct Mac integration surface.
- Homebrew's supported default prefix is `/opt/homebrew` on Apple Silicon and
  `/usr/local` on Intel Macs; code must discover the active installation rather
  than hard-code either path.
- `brew bundle check` can compare a selected Brewfile with installed state.
  `brew bundle install` upgrades by default; `--no-upgrade` suppresses that
  ambient upgrade behavior but is not a version lock.
- `brew bundle dump` snapshots installed formulae, casks, taps, and other
  package types. `brew bundle cleanup --force` removes supported items absent
  from the Brewfile. Neither operation is suitable for default inventory or
  convergence on personal machines.
- Apple exposes login items and background activity to the user and uses
  `launchd`/Service Management for per-user agents. Any future background
  automation must therefore be a distinct opt-in phase, not shell bootstrap.
- macOS privacy controls restrict access to Desktop, Documents, Downloads,
  network volumes, application data, automation, and full disk contents.
  Harness operation should not request Full Disk Access or Automation merely
  to inventory a development environment.
- Apple's OpenSSH integration supports scoped `UseKeychain` and
  `AddKeysToAgent`. The harness should preserve the owner's native choices and
  never create a replacement agent or inspect loaded identities.

Primary sources:

- <https://docs.brew.sh/Installation>
- <https://docs.brew.sh/Brew-Bundle-and-Brewfile>
- <https://docs.brew.sh/Manpage>
- <https://docs.brew.sh/FAQ>
- <https://docs.brew.sh/Versions>
- <https://support.apple.com/guide/terminal/trml113/mac>
- <https://support.apple.com/guide/security/secddd1d86a6/web>
- <https://support.apple.com/guide/deployment/depdca572563/web>
- <https://developer.apple.com/documentation/servicemanagement>
- <https://developer.apple.com/library/archive/technotes/tn2449/_index.html>

## Implementation-time facts to discover safely

- Homebrew presence, active prefix, Mac architecture, and Command Line Tools
  availability remain unknown per machine. Local value-minimized observation
  discovers them only after the synthetic privacy gates pass. Missing
  Homebrew is reported as a stop condition; installing Homebrew is not implied
  by this plan and requires separate package authority.

## Owner decisions

- **D1 — Pull-based operation and long-gap convergence.** The Macs are not
  always online and some are used only occasionally. Every Mac must therefore
  pull and apply locally; the cluster login node will not push changes to it.
  The owner also requires the Mac to be able to "fastforward from very old
  states." The design interprets this as direct convergence from any released
  Mac baseline to the current published baseline through a clean Git
  fast-forward plus planned, schema-versioned local-state migrations. It must
  not require the Mac to have been online for, or to replay, each intermediate
  rollout.
- **D2 — Private Git companion.** The authoritative personal-Mac desired state
  will live in a separate private Git repository. It contains curated baseline
  selections, schemas, and opaque per-Mac deltas only. It never contains copied
  dotfiles, captured local configuration, observed package/app inventories,
  live facts, transaction records, credential material, or secret values. The
  public harness remains the generic engine and must be fully testable without
  access to the private repository. Private repository creation, remote
  configuration, and publication remain separate external authority
  boundaries during execution.
- **D3 — CLI-only initial scope.** The first implementation and pilot manage
  selected command-line development/agent capabilities plus collision-refusing
  Codex/Claude guidance and skill links. GUI applications, Homebrew casks, Mac
  App Store state, application preferences, editor-extension inventories,
  Homebrew services, login/background items, and macOS settings are excluded.
  Adding any of those later requires a separate evidence-backed phase and
  explicit owner decision.
- **D4 — Automatic managed-formula catch-up upgrades.** After both public and
  private repositories fast-forward and their schemas/migrations validate, a
  catch-up run automatically upgrades the explicitly managed CLI formula
  allowlist as well as installing missing entries. It does not upgrade or
  remove unmanaged formulae and does not touch casks, services, taps, App Store
  apps, or editor extensions. The upgrade stage must be printed separately,
  capture pre/post formula versions and dependency changes in private local
  state, and fail closed before shell/link work on any unexpected scope or
  prompt. Homebrew lacks transactional rollback, so recovery is a separately
  reviewed version/reinstall plan rather than automatic uninstall/downgrade.
- **D5 preference — Bash.** The owner prefers Bash, so the Mac interactive
  policy will use a managed current Homebrew Bash rather than make zsh the
  working shell. The owner selected activation through a stable harness
  launcher while retaining macOS's native account login shell; neither
  `/etc/shells`/`chsh` nor Apple's old `/bin/bash` is the managed route.
- **D5 activation — stable launcher with native recovery shell.** The selected
  route manages current Homebrew Bash and enters it through a stable
  harness-owned launcher that discovers the active Homebrew prefix. The macOS
  account login shell remains unchanged and usable if Homebrew or the harness
  fails. The harness may add only a thin transaction-backed Bash loader; it
  does not edit Terminal preferences, `/etc/shells`, `chsh`, or zsh files.
- **D6 — Manual catch-up only.** Repository fast-forward, schema migration,
  Homebrew install/upgrade, link apply, and doctor run only through an explicit
  owner-started plan/apply command. Login, wake, managed Bash entry, agent
  startup, and shell exit perform no network or mutation. No `launchd`, login
  item, cron, or other background job is installed in the first system.
- **D7 access route — local pilot session.** The owner will start a
  Codex/Claude session locally on the selected pilot Mac. The pilot is not
  accessed from the cluster, no inbound SSH or Remote Login is required, and
  no SSH configuration is enumerated. Live facts and detailed plan/transaction
  evidence stay on the Mac. Public evidence uses only an opaque logical ID and
  value-free aggregate outcomes.
- **D7 pilot — current client Mac.** The first pilot is the Mac the owner is
  currently using to connect to this login node. Its hostname, model, serial,
  network details, username, and private paths are not recorded in the public
  repository. A stable opaque logical ID will be assigned only in private
  desired state when execution is authorized.
- **D8 — Existing backup plus reconstruction.** The private Git companion is
  the recovery source for curated desired intent. Private local facts and
  transaction/rollback records remain outside Git and rely on the owner's
  existing Mac backup coverage where available; otherwise they are rebuilt by
  a fresh value-minimized observation and plan. The harness will not add an
  encrypted sync service, backup job, or new backup repository in this phase.
- **D9 — Small public CLI baseline.** The common managed Homebrew allowlist is
  `bash`, `git`, `git-lfs`, `tmux`, `ripgrep`, `jq`, `tree`, and `shellcheck`.
  Language runtimes, agent installers, backup/transfer tools, and
  build/document tools are separate private opt-in capability groups per Mac.
  Automatic catch-up upgrades apply only to the common baseline plus the
  explicit private groups selected for that Mac; they never infer selections
  from installed state.
- **D10 — Private GitHub companion.** The desired-state companion will be one
  owner-controlled private GitHub repository. Each Mac keeps an independent
  clean expected-branch clone and catches up by fast-forward only; runtime
  state is never pushed. Creating the repository, choosing its final name,
  configuring authentication/remotes, and publishing commits are separately
  checked external authority boundaries during execution.

## Recommended architecture

### 1. Separate target family

Introduce a `personal-macos` platform adapter with its own facts, policy, and
validation. Do not add personal Macs to `profiles/hosts/` or the current
`fleet-sync` default. Existing Linux/HPC behavior remains byte-for-byte stable
unless a portable primitive is deliberately extracted with regression tests.

### 2. Public engine, private desired state

Keep generic code and a small, deliberate CLI capability baseline in Git.
Resolve private host declarations only from a strict user-local path such as
`~/.config/harness/private/hosts/LOGICAL_ID.conf`, with a mode and ownership
gate. Live fact/state files remain under `~/.local/state/harness/` with mode
0700/0600 boundaries. Public tests use synthetic `mac-test-*` fixtures.

The private declaration may select baseline groups and add local packages, but
plan output and durable public evidence record only categories/counts and
pass/fail state unless the owner explicitly requests a local detailed view.
No tool ever generates a private manifest from installed state.

After D1 established long-gap convergence, the recommended storage behind that
local path changed from four independent files to a separate private Git
companion. It would version only curated desired state and opaque host deltas,
so an occasionally used Mac can fast-forward public engine and private policy
before one migration/apply plan. It must exclude copied dotfiles, observed
package/app inventories, live facts, transaction logs, credentials, and secret
values. The public engine remains usable and testable without the companion;
creating a private remote is a separate external-service authority boundary.
This recommendation is selected by D2.

### 3. Mac-local mutation

Prefer a pull/local-apply model: each Mac obtains a reviewed public harness
revision, loads its private declaration locally, runs plan, and applies changes
in its own logged-in user context. This fits sleeping/NATed personal machines,
keeps macOS authorization prompts visible to the owner, and avoids enabling
inbound management. An optional controller may later receive value-minimized
health, but it is never an apply route.

### 4. Long-gap update and migration contract

Use the public read-only Git origin as the distribution channel. An update
must refuse a dirty checkout, detached or unexpected branch, local-only
commits, non-ancestor target, or ambiguous remote. It fetches the explicit
published target and uses `git merge --ff-only`; it never rebases, resets,
force-updates, autostashes, or applies owner changes. A Mac that missed many
releases advances directly to the current target commit.

Private declarations and local transaction state carry explicit schema
versions. The current harness must plan a direct ordered migration from every
previously released Mac schema starting with v1, apply each migration
idempotently with local rollback state, and validate the final schema before
any Homebrew or shell action. Synthetic fixtures for every released schema are
retained permanently. Catch-up never interprets absence as permission to
remove packages and never bundles package upgrades into a state migration.

The public and private repositories fast-forward independently from clean,
expected branches. The public engine declares the supported private-schema
range; the private repository declares its schema and minimum engine contract.
Both target commits and their compatibility must be resolved before any
machine-state plan is accepted. A fetch, ancestry, or compatibility failure
may leave one checkout harmlessly newer, but it performs no Homebrew, link,
shell, or state migration. The next run resumes by fast-forwarding the lagging
checkout and recomputing the complete plan.

### 5. Homebrew as an adapter, not the source of truth

Discovery uses the active `brew` executable and `brew --prefix`. The harness
checks only explicitly desired formulae. Catch-up uses exact formula-only
native install and upgrade commands derived from the selected public/private
allowlist, rather than Bundle's broader multi-type convergence surface. The
upgrade is an explicit plan section after repository/schema migration, not an
implicit Git-update side effect. It never dumps installed state, cleans up,
upgrades unmanaged formulae, starts services, or manages casks/MAS/VS Code
extensions unless separately authorized.

Because Homebrew lacks a lockfile and upgrades may change dependencies, package
apply records the managed formula set plus pre/post versions and dependency
deltas locally. Configuration/link rollback can be automatic; formula
downgrade, uninstall, or removal of newly installed dependencies is a
separately reviewed destructive action, not an automatic failure trap.

### 6. Preserve native macOS boundaries

- preserve the native account login shell as a recovery path unless D5
  explicitly selects `chsh`;
- manage current Homebrew Bash as a selected CLI formula and discover its path
  through `brew --prefix` rather than hard-coding Apple Silicon or Intel
  prefixes;
- if the recommended activation is selected, provide a stable harness launcher
  that enters Homebrew Bash and can be chosen manually as an Apple Terminal
  profile command; the harness does not edit Terminal preferences;
- add only unchanged-marker-guarded thin Bash loaders after collision and
  precedence planning, with local backups and exact rollback; inspect zsh
  startup paths only enough to prove the harness did not modify them;
- leave Keychain, `ssh-agent`, `UseKeychain`, `AddKeysToAgent`, SSH host
  stanzas, FileVault, TCC permissions, login items, and system updates to the
  owner/macOS;
- require no Full Disk Access, Accessibility, Automation, or administrator
  rights for normal inventory/doctor;
- prohibit background automation in the first rollout.
- keep the managed Bash launcher network-free and mutation-free; it may report
  locally known stale status but must not query a remote or start catch-up.

## Execution sequence after explicit go

1. **Freeze decisions and identity boundary.** Record the chosen topology,
   privacy store, scope, package policy, shell policy, automation policy, and
   exact pilot access method without private values in Git.
2. **Define the private companion contract.** Add only a public schema/example
   and strict resolver. Freeze the private repository's curated-intent scope,
   opaque host-ID model, local checkout path, private schema, minimum-engine
   field, prohibited content, and privacy-negative tests. Creating its remote
   remains separately authorized.
3. **Build the long-gap updater and compatibility contract.** Define public and
   private read-only origins, clean-checkout/ancestor gates, explicit target
   commits, `git merge --ff-only` behavior, supported schema ranges, migration
   planner, idempotence, and rollback. Resolve both targets and compatibility
   before planning machine state. Retain a synthetic fixture for every released
   schema starting at v1.
4. **Build portability primitives.** Add OS/architecture detection for Darwin,
   portable file metadata/hash helpers where needed, and regression coverage
   proving existing Linux behavior is unchanged.
5. **Add the macOS observation contract.** Emit only OS family, architecture,
   shell class, Homebrew presence/prefix class, Command Line Tools presence,
   selected-capability states, checkout/link kinds, and private-profile
   availability. Do not enumerate apps, packages, networks, files, or secrets.
6. **Add strict private-profile resolution.** Refuse symlinks, wrong owner/mode,
   unsafe IDs, duplicate keys, unknown keys, absolute public evidence paths,
   and any value that would be echoed into public logs. Provide a value-free
   example schema, not a real host profile.
7. **Add macOS plan and doctor.** Separate required failures from optional
   gaps; remain read-only while printing the exact native Homebrew commands
   that the selected automatic managed-allowlist catch-up apply would use.
8. **Add Mac control-plane transactions.** Reuse collision-before-mutation for
   guidance/skill links. Store local-only transaction records and prove
   idempotence plus exact rollback in synthetic tests.
9. **Add bounded Homebrew catch-up.** Revalidate the selected managed formula
   set and current prefix; capture managed pre-state; print missing and outdated
   managed formulae as a distinct plan stage; then install/upgrade that
   allowlist and capture post-state/dependency deltas locally. Do not dump or
   converge the whole machine. Stop on unmanaged-formula, cask, service, sudo,
   license, tap, or other unexpected scope.
10. **Add Bash integration.** Implement the selected Bash activation route,
    discover Homebrew Bash without hard-coded prefixes, plan
    `.bash_profile`/`.bashrc` precedence, preserve existing bytes/mode/ACL
    expectations, append only the reviewed loader, and prove native-shell
    recovery, non-interactive silence, fresh interactive behavior,
    idempotence, and rollback. Do not edit Terminal preferences.
11. **Synthetic validation.** Run focused macOS adapter tests, independence and
   privacy-negative tests, the complete `tests/test-phase1.sh`, ShellCheck, and
   `git diff --check`; add a synthetic macOS CI job if it materially tests
   native tools without private state.
12. **Pilot observation.** On one owner-selected Mac, capture a value-minimized
    mode-0600 fact file locally, review plan output, and confirm zero private
    config or identifiers entered Git or logs.
13. **Pilot control-plane apply/rollback.** Apply only discovery links first,
    run doctor in a fresh Codex and Claude session, deliberately roll back,
    verify the prior state, then reapply if accepted.
14. **Pilot tool/shell stages.** Execute only the separately authorized
    Homebrew and managed-Bash stages; stop at every unexpected macOS prompt or
    scope expansion.
15. **Long-gap acceptance drill.** In disposable synthetic public/private
    checkouts and a state root, start from the oldest released engine and
    private schema. Prove two direct fast-forwards, compatibility validation,
    ordered migration, idempotent current plan, partial-update retry safety,
    and exact state rollback without replaying intermediate deployments.
16. **Sequential rollout.** Repeat update, migration plan, apply, doctor,
    restart, and rollback readiness on the remaining Macs one at a time,
    including one deliberately stale pilot state. Never infer one Mac's facts
    from another.
17. **Closeout.** Retain public synthetic evidence and value-free aggregate
    results only. Keep live facts, private profiles, transaction details, and
    machine identities in the chosen private/local store. Document exact
    maintenance and recovery routes.

## Safety gates and failure handling

- No Mac connection or local probe occurs during planning. Pilot observation
  starts only after explicit go, public synthetic privacy tests, and a local
  owner-started agent session on the selected current client Mac.
- No update runs automatically at login or wake. A locally initiated update
  must prove a clean expected checkout, explicit published target, and strict
  ancestry before a fast-forward; any local divergence fails closed.
- Managed Bash entry, agent-client startup, and shell exit remain fast and
  silent with respect to Git, Homebrew, migrations, and doctor. Only an
  explicit catch-up command enters the update/apply pipeline.
- Public and private targets must both be clean fast-forwards and declare a
  compatible engine/private-schema pair before any machine mutation. Partial
  repository update is retry-safe and never authorizes partial apply.
- Every released private-state schema remains a supported migration input.
  Missing intermediate execution history is normal and never triggers
  replay of historical package actions or package cleanup. D4's current
  managed-allowlist upgrade runs once against current state after migration.
- Inventory must pass privacy-negative tests before a live run.
- Plan is always read-only; apply requires a clean committed harness revision,
  strict target identity, and a revalidated unchanged plan.
- Every file mutation refuses unmanaged collisions and records a local
  restorable transaction without copying the full private configuration into
  Git or public logs.
- Homebrew catch-up upgrades only the current managed formula allowlist. It
  never uses `sudo`, cleanup, autoremove, service management, casks, or
  whole-machine upgrade/convergence.
- A TCC prompt, administrator prompt, license prompt, cask request, or
  unexpected package upgrade is a stop condition, not permission to proceed.
- Package recovery is plan-only until the owner approves exact
  downgrade/reinstall/uninstall targets; file/link rollback remains immediate
  and bounded.
- No recursive/bulk deletion is permitted until the guarded-delete
  implementation has a separately tested Darwin backend.
- On interruption, resume from T-268's recorded phase and next decision or
  first unverified execution step; never repeat a successful mutation blindly.

## Validation and acceptance

- Existing seven-node Linux fixtures, plans, doctors, installers, fleet sync,
  shell behavior, and complete phase-1 suite remain green.
- Synthetic Darwin arm64 and, if needed, x86_64 fixtures cover positive,
  missing-tool, collision, malformed-private-profile, symlink, wrong-mode,
  privacy-leak, Homebrew-prefix, managed-upgrade, unmanaged-preservation, and
  unexpected-dependency cases.
- The current Mac updater fast-forwards directly from the oldest released Mac
  public/private baseline and migrates every historical schema fixture to
  current state. A second run is a no-op; incompatible pairs, partial fetches,
  divergence, dirty state, and non-ancestor targets are rejected without
  machine mutation.
- Public tracked files and Git diff contain no actual Mac identifier, local
  path, app inventory, private package list, credential reference value, or
  captured live fact payload.
- A clean Mac pilot can inventory and plan with no administrator/TCC prompt and
  no network except explicit Git/Homebrew metadata operations.
- Control-plane apply is idempotent; doctor passes in fresh Codex and Claude
  sessions; exact rollback restores the prior state.
- Homebrew catch-up names its intended formulae locally, upgrades only that
  allowlist, preserves unmanaged formulae, performs no cleanup/service/cask
  action, and records or stops on unexpected dependency changes.
- The selected Bash activation retains an independently usable native recovery
  shell, enters the current Homebrew Bash through a stable path, is silent in
  non-interactive contexts, preserves existing local configuration, and rolls
  back exactly while unchanged.
- Before sequential rollout, a cross-platform Core-tool compatibility matrix
  exercises the oldest supported Linux floors and current macOS/Homebrew
  versions. It covers feature and output compatibility plus Git safety
  defaults, tmux/Vim configuration, jq language behavior, rsync protocol and
  argument handling, curl TLS/protocol support, and SQLite forward
  compatibility. User-space CLIs must not replace site shared libraries or
  alter `LD_LIBRARY_PATH`; actual AI/HPC workflows must pass before a broader
  managed baseline is accepted.
- Each Mac is accepted independently. Aggregate completion reports only counts
  and capability classes in public evidence.

## Decision register

| ID | Decision | Recommended default | Alternatives / consequence | Status |
| --- | --- | --- | --- | --- |
| D1 | Control topology and stale catch-up | Mac-local pull/apply; direct clean fast-forward plus schema migrations from any released Mac baseline | Central mutation is excluded; missed rollouts must not require replay or package backfill | selected — Macs are intermittently online and some are rarely used |
| D2 | Private desired-state storage | Separate private Git companion containing curated intent only, resolved through a strict local path | Four local-only manifests reduce remote exposure but weaken consistency, recovery, and long-gap convergence; public host state violates privacy | selected — private Git companion |
| D3 | Phase-1 managed scope | CLI development tools plus agent discovery links only | Adding GUI casks, App Store apps, preferences, services, or OS settings increases privacy and rollback risk | selected — CLI-only |
| D4 | Homebrew convergence | Automatically install/upgrade only the explicit managed allowlist during manual catch-up; no dump, cleanup, removal, or unmanaged upgrade | `--no-upgrade` reduces catch-up changes but leaves managed tools stale; full convergence or ambient whole-machine upgrades violate scope | selected — automatic managed-allowlist catch-up upgrades |
| D5 | Interactive shell | Current Homebrew Bash through a stable harness launcher; retain native account shell and thin managed Bash loader | `chsh` makes Homebrew a login dependency and touches system shell policy; `/bin/bash` avoids Homebrew but is old | selected — recommended launcher/native recovery route |
| D6 | Background automation | Manual invocation only for the first rollout | `launchd` pull/doctor adds unattended network/change behavior and user-visible background state | selected — explicit manual catch-up only |
| D7 | Pilot and discovery boundary | Owner starts a local session on one low-risk Mac and supplies a non-sensitive logical ID | Exact existing alias or owner-captured value-free facts are possible; SSH-config enumeration and automatic discovery are prohibited | selected — local session on the current client Mac; identity remains private |
| D8 | Private-state recovery | Use the owner's existing private backup after defining exact non-secret state; do not add backup automation now | New encrypted sync or backup automation is a separate project and authority boundary; putting live facts/transactions in Git increases exposure and churn | selected — private Git recovers intent; existing backup plus reconstruction covers local runtime state |
| D9 | Shared CLI baseline | Keep a small public bootstrap/development baseline and select additional capability groups privately per Mac | Mirroring the entire Linux list adds unnecessary tools; making the whole baseline private weakens public testing and reproducibility | selected — eight-formula public baseline; extra capability groups are private opt-ins |
| D10 | Private companion hosting | Use one private GitHub repository with clean fast-forward-only clones on each Mac | Another private Git host is viable but needs its own transport and recovery contract; local-only storage cannot synchronize four intermittent Macs | selected — owner-controlled private GitHub repository |

## Next action

Stages 2–3 are complete and retry-safe in the public repository. The strict
resolver now validates the entire clean private Git tree. `harness
macos-update` enforces explicit fetched targets and clean expected-branch
fast-forwards, validates both target contracts, hands off to the target public
engine before private/state mutation, and transactionally initializes or
migrates schema-v1 local state. Synthetic drills pass for direct old-to-current
catch-up, idempotence, changed-state rollback refusal, exact state rollback and
reapply, incompatible schema/layout refusal, and partial-public-update retry.
Stages 4–6 are also complete: shared helpers select GNU or BSD metadata safely,
the Darwin-only inventory emits only the frozen value-minimized fact set, and
the strict resolver covers all private tracked manifests. Synthetic arm64 and
x86_64 routes, Linux refusal, present/absent/unusable Homebrew, missing Command
Line Tools, invalid private state, scoped public-formula queries, and privacy
leak assertions pass. Stage 7 is complete: plan and doctor strictly validate
mode-0600 facts, revalidate live selected scope, reject fact/link/outdated
drift, keep doctor output value-free, and render exact official formula-only
Homebrew metadata/dry-run/apply commands without executing them.
Stages 8–9 are complete. Mac control-plane discovery links are collision-refusing,
idempotent, mode-restricted, transaction-backed, partial-failure safe, and
exactly reversible while unchanged. Synthetic tests cover pre-existing links
and directory modes, regular and symlink collisions, symlinked state and
parent paths, injected partial failure, changed-link refusal, unexpected
content refusal, exact rollback, and second-run no-op. Bounded Homebrew catch-up
uses the public baseline plus explicit private formulae, refuses taps and
unmanaged installed dependents, validates exact formula-only dry-runs, repeats
all gates before apply, and retains local pre/post/dependency/failure evidence
without promising package rollback. Stage 10 is complete: the stable launcher
resolves the physical Homebrew Bash cellar without hard-coded architecture
prefixes, and transactional thin-loader integration preserves native-shell
recovery, existing startup bytes/inodes/modes/ACLs, interactive idempotence,
and non-interactive silence. Stage 11 is complete: every focused macOS suite,
privacy/public-repository audit, repository-independence audit, Claude takeover
test, ShellCheck gate, complete portable phase-1 suite, and diff check pass.
A native macOS CI job was not added because it would depend on mutable hosted
Homebrew state or install packages during CI without materially strengthening
the fully synthetic adapter tests. Stage 12 now requires the owner to start a
local Codex or Claude session in the public harness checkout on the selected
pilot Mac. That session must re-read Git and `TODO.md`, obtain separate authority
before creating/configuring the private GitHub companion, assign the opaque ID
only privately, and capture value-minimized mode-0600 facts locally. Do not
connect to or infer the Mac from this login node, and do not mutate Homebrew or
shell state during observation.
