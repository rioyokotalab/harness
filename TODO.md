# Personal harness task board

This is the authoritative resume point for the portable Codex and Claude
harness. Git retains superseded chronology and command-level evidence. Keep
only active decisions, verified prerequisites, blockers, exact next actions,
and compact historical pointers here. Next free ID: T-269.

## Current state

- Repository: published `main` and all managed fleet checkouts are clean and
  synchronized. The owner authorized frequent ordinary pushes for the
  now-public harness and website repositories; fetch before work and push,
  preserve contributor commits, and never force-push.
- Managed environments: `local`, `ab`, `ab2`, `ri`, `al`, `rc`, and `t4`.
  `abci_login` and `alps_login` are transports; `github` and `web` are
  services. Retired `si` is not a target.
- All seven hidden-home Restic primaries and all seven independent encrypted
  generations have passed full-data checks and verified restores. Exact
  snapshot, fingerprint, aggregate restore, transaction, and cleanup evidence
  is retained in Git through `303938f` and in `docs/home-backup.md`.
- T-181's acceptance evaluation is complete. The clean pilot passed 18/18;
  the full deterministic aggregate is 69/70 with zero safety failures and one
  reviewed semantic-oracle false negative. Candidate adoption remains separate
  and was not performed. Reports are under `evaluation/results/`; frozen
  evidence is commit `ee96853`, evaluator hardening is `d26c5a3`, and the
  private run root and cleanup manifest are absent.
- Exactly one native weekly primary job is seeded on each managed node. No
  login-node cron, user timer, retention deletion, or automatic replica job
  exists. T-191 remains verification-pending until all seven first runs pass.
- All managed checkouts are kept clean and synchronized through guarded
  fleet-sync; current published `main` is the fleet resume point. Fresh
  interactive Bash shells load shell-local destructive-command safeguards;
  child and batch shells do not. Login and shell exit perform no automatic Git
  work.
- Harness and website `main` rulesets are active with their required CI check,
  linear history, conversation resolution, and force-push/deletion protection.
  The owner intentionally set required approvals to zero; PRs need no separate
  reviewer after the required check passes.
- Global invariants remain authoritative in `.codex/AGENTS.md`: never inspect
  credentials; never use raw recursive/bulk deletion; preserve unrelated owner
  state; print native scheduler actions; validate proportional to risk; do not
  push without explicit authority.
- Cross-client takeover is repository-backed: root `AGENTS.md` and `CLAUDE.md`
  share the project protocol, `.claude/CLAUDE.md` shares the global policy, and
  isolated installer/control-plane tests cover Claude guidance plus every
  shared-skill discovery link. A live 2026-07-18 preflight passed on all seven
  environments with Claude Code 2.1.207, canonical guidance, 10/10 shared
  skills, 34/34 managed links, and zero planned changes. Chat and client
  auto-memory are non-authoritative.

## Next resume checkpoint

Resume T-268 in `executing`; D1–D10 are frozen and the owner gave explicit
`go` on 2026-07-18. Continue stage 12 from the exact next action in
`docs/plans/personal-macos-fleet.md`. Independently resume T-191 after the first
Sunday eligibility. Fetch and prove a clean fleet, then query only the seven
captured IDs below through their declared native scheduler routes. Do not infer
absence from a failed query, and do not cancel, replace, or duplicate a delayed
job. T-196 remains blocked until T-191 reaches eight successful weekly chains,
two verified restores per node, and a current verified independent generation.
T-210 is complete and must not be repeated.

## Active tasks

### T-191 — Scheduler-native weekly primary snapshots

**Status:** verification-pending. All seven bounded smokes passed and exactly
one production job per node was seeded for Sunday 2026-07-19. The last
read-only continuity audit on 2026-07-18 found every captured job present with
the expected owner/name and future eligibility. Local, RI, AL, and RC report
native Slurm `PENDING`/`BeginTime`; AB and AB2 report PBS `W`; T4's AGE record
is present. Every private mode-0600 chain state remains `active` with
`last_result=seeded` and `snapshot_id=none`. No job was submitted, replaced,
canceled, resized, or reprioritized.

| Host | Captured production ID | First eligibility |
|---|---:|---|
| `local` | `90939` | 00:30 JST |
| `ab` | `2044027.pbs1` | 01:00 JST |
| `ab2` | `2044028.pbs1` | 01:30 JST |
| `ri` | `6862` | 02:00 JST |
| `rc` | `210816` | 02:30 JST |
| `t4` | `8175651` | 03:00 JST |
| `al` | `4221054` | 01:00 Europe/Zurich |

**Frozen invariants:** each node independently maintains exactly one future
native-scheduler job. A delayed pending/held job is healthy and must never be
duplicated. When admitted, the job validates its identity, persists exactly one
strictly future successor, then takes one incremental snapshot tagged
`harness-hidden-home-weekly`; it never backfills missed weeks. Keep all
snapshots. No `forget`, `prune`, retention deletion, automatic replica,
login-node cron/timer, or scheduled full-data check is authorized. RI's
site-forced one-GB200 allocation is owner-accepted.

**Resume/acceptance:** after the first eligibility, fetch and prove a clean
fleet, then query only the seven IDs above with each site's declared native
scheduler route. A failed query is unknown state, not absence. After admission,
require scheduler and snapshot success, one owner/name-matched successor at the
next strictly future Sunday, consistent private state, and healthy interactive-
login silence. T-191 remains open until all seven first snapshots and
successors pass. Canonical commands and resource/timezone declarations are in
`profiles/restic-schedules.tsv`, `libexec/harness-restic-schedule`, and
`docs/home-backup.md`; full implementation and failure chronology is retained
at `d910a40:TODO.md`.

### T-196 — Backup lifecycle phase 2

**Phase/status:** `policy resolved`, execution-gated on eight successful weekly
chains, two verified restores per node, and a current verified independent
generation. T-251 locked the 12-weekly/12-monthly/3-yearly exact-group policy,
monthly rotating quarter-data checks, quarterly full-data/full-restore checks,
monthly sampled restores, and monthly manual independent generations retaining
the latest two verified copies. No live retention, `forget`, `prune`, recurring
check/restore, or replica automation is authorized yet. The eventual actions
remain behind their later exact-command authority boundaries.

**Outcome:** `docs/backup-lifecycle-phase2.md` records official Restic 0.19.1
semantics, recommended generous retention, separate forget/prune transactions,
deterministic data-check coverage, restore drills, manual-first independent
replicas, collision/lock rules, phased acceptance gates, rollback evidence, and
the resolved owner policy. No Restic, scheduler, replica, deletion, or
credential-path command ran. Keep-all remains effective until T-191 production
stabilizes and the owner separately approves the exact first `forget` and later
separate `prune` commands.

### T-268 — Private personal macOS fleet

**Phase/status:** `executing`. Design a separate personal-macOS target
family that reuses harness safety and control-plane principles without adding
four private machines to the public Linux/HPC profiles. Generic code, schemas,
synthetic fixtures, tests, and any deliberately selected non-sensitive CLI
baseline may be public; machine identity, local configuration, installed-app
inventory, private desired state, live facts, credentials, and transaction
detail must remain local or in an explicitly chosen private store.

**Verified discovery:** the current harness materially assumes Linux, Bash,
GNU file/hash tools, Linux artifacts, systemd-style local SSH-agent handling,
and controller-initiated SSH. Homebrew and Apple documentation support a
separate adapter: discover the active Homebrew prefix, avoid Bundle's default
upgrade behavior, never use dump/cleanup as inventory or convergence, preserve
native zsh/Keychain/TCC/login-item behavior, and require no background service
or broad privacy permission in the initial rollout. No Mac was identified,
connected, inventoried, or changed; no package, shell, SSH, privacy, login-item,
backup, repository, or external-service action ran.

**Plan:** `docs/plans/personal-macos-fleet.md` contains scope/non-goals,
confirmed facts and assumptions, primary sources, the recommended public-engine
plus private-state architecture, 17 execution stages, safety/rollback gates,
acceptance criteria, and decisions D1–D10. The selected design is Mac-local
pull/apply, a strict private overlay, managed-allowlist Homebrew catch-up
upgrades, a current Homebrew Bash launcher with the native shell preserved,
manual operation before any `launchd` work, and one low-risk local pilot before
sequential rollout.

**Decision D1:** selected pull-based local operation because Macs are
intermittently online and some are rarely used. The login node will not push
or apply. Each Mac must directly fast-forward a clean expected checkout from
any released Mac baseline to the current published target, then run
schema-versioned, idempotent local-state migrations without replaying missed
rollouts or backfilling historical package actions. D4's current managed-tool
upgrade stage is separate from these migrations.

**Decision D2:** selected a separate private Git companion as the authoritative
desired-state layer. It will version curated baseline selections, schema, and
opaque host deltas only; copied dotfiles/configuration, observed inventories,
live facts, transactions, credentials, and secrets are prohibited. Public and
private repositories fast-forward independently, but their engine/schema
compatibility must pass before any machine mutation. Partial repository update
is retry-safe and never permits partial apply. Creating/configuring/publishing
the private remote remains a separate execution authority boundary.

**Decision D3:** selected CLI-only initial scope. The pilot manages selected
command-line development/agent capabilities and Codex/Claude discovery links.
GUI applications/casks, App Store state, preferences, editor extensions,
Homebrew services, login/background items, and macOS settings are excluded and
require a separate later phase.

**Decision D4:** selected automatic catch-up upgrades for the explicitly
managed CLI formula allowlist after public/private fast-forward and schema
migration validate. The upgrade is a separately printed stage with private
pre/post version and dependency evidence. Unmanaged formulae, casks, services,
taps, App Store apps, editor extensions, dump, cleanup, and removal remain
untouched. Because Homebrew upgrade is not transactionally reversible, any
downgrade/reinstall/uninstall recovery requires a later exact reviewed plan.

**Decision D5:** selected managed current Homebrew Bash through a stable harness
launcher while retaining the unchanged native macOS account shell as an
independent recovery path. The launcher discovers the Homebrew prefix; only a
thin collision-refusing Bash loader may be added. Terminal preferences,
`/etc/shells`, `chsh`, and zsh files remain untouched.

**Decision D6:** selected explicit manual catch-up only. Login, wake, managed
Bash entry, agent startup, and shell exit perform no fetch, migration,
Homebrew action, apply, or doctor. No `launchd`, login item, cron, or background
job is added; long-gap updates run only when the owner deliberately starts and
can observe plan/apply.

**Decision D7:** selected a Codex/Claude session started locally on the pilot
Mac, specifically the current client Mac the owner is using to connect to this
login node. No inbound SSH, Remote Login change, SSH-config enumeration, or
live configuration transfer to the cluster is required. Hostname, model,
serial, network details, username, and private paths remain private; an opaque
logical ID is assigned only in the private desired-state repository during
authorized execution. Public records contain only value-free aggregate
outcomes.

**Decision D8:** selected the private Git companion as the recovery source for
curated desired intent, with private local facts and transaction/rollback
records covered by the owner's existing Mac backup where available and
otherwise rebuilt through fresh value-minimized observation and planning. No
new encrypted sync service, backup job, backup repository, or versioning of
live facts/transactions is in scope.

**Decision D9:** selected the small public Homebrew baseline `bash`, `git`,
`git-lfs`, `tmux`, `ripgrep`, `jq`, `tree`, and `shellcheck`. Language runtimes,
agent installers, backup/transfer tools, and build/document tools are private
opt-in capability groups per Mac. Automatic catch-up upgrades only the public
baseline and explicitly selected private groups; installed state never implies
desired state.

**Decision D10:** selected one owner-controlled private GitHub repository as
the desired-state companion, with an independent clean expected-branch clone
on each Mac and fast-forward-only catch-up. Runtime state is never pushed.
Repository creation/name, authentication/remotes, and publication remain
separate external authority checks during execution.

**Final decision audit:** D1–D10 are internally consistent and no material
design input remains. The frozen order is public schema/private contract,
long-gap updater, Darwin portability and observation, strict resolver,
plan/doctor/transactions, bounded Homebrew and Bash support, synthetic and
Linux regression validation, local pilot observation and staged rollback, a
long-gap drill, then one-at-a-time rollout. Privacy-negative tests precede any
Mac observation; control-plane rollback precedes package/shell stages; every
live package or external-service action retains its separate authority gate.

**Execution checkpoint:** stages 1–11 are complete. The frozen D1–D10 record is
unchanged. Stage 2 added `harness macos-profile`, the public
`profiles/personal-macos/base.conf`, strict companion v1 schema/example,
synthetic v1 fixture, and `tests/test-personal-macos-profile.sh`. The resolver
now also proves the checkout is clean and validates every tracked host while
rejecting any unapproved tracked path. Stage 3 added `harness macos-update`,
shared portable manifest/checksum helpers, `docs/personal-macos.md`, and a
synthetic long-gap suite. It requires full fetched `origin/main` commits,
clean tracked `main` branches, one origin, ancestry, compatible target trees,
and a valid current companion before apply. Public fast-forward hands off to
the target engine before private/state mutation. Local schema-v1 state is
mode-0600 and transaction-backed; rollback never rewinds repositories.

Synthetic direct catch-up, second-run no-op, absent/present-state rollback,
changed-state refusal, rollback/reapply, incompatible schema, prohibited target
layout, injected private-fast-forward failure, and partial-update retry all
pass. Focused profile/update suites, ShellCheck (with existing dynamic-source
exclusions), repository independence, Claude takeover, public-repository
audit, and `git diff --check` passed on 2026-07-18. No private repository, Mac,
live fact, authentication, GitHub service, package, shell, or external state
was accessed or changed.

Stages 4–6 add `harness macos-inventory` without changing the Linux inventory.
Shared helpers select GNU or BSD `stat` and SHA-256 routes. The Darwin-only,
read-only inventory emits architecture and native-shell classes, Homebrew
presence/prefix class, Command Line Tools status, strict private-profile and
checkout state, fixed link kinds, and only the eight public-formula states. It
suppresses actual prefixes, versions, paths, private selections, detailed
profile failures, and all broader inventory. Synthetic arm64/x86_64, Linux
refusal, BSD metadata, present/absent/unusable Homebrew, missing Command Line
Tools, invalid profile, exact scoped Brew query, and privacy-leak tests pass,
along with all earlier focused/audit checks on 2026-07-18.

Stage 7 adds `harness macos-plan` and `harness macos-doctor`. Facts are strict,
mode-0600, private, and identity-bound. Plan revalidates actual fixed-link
targets and scoped formula presence, refuses captured/live or unmanaged
outdated drift, and only reads Homebrew with automatic update/analytics
disabled. It renders a separately authorized `brew update`, then exact
formula-only install/upgrade dry-runs and no-prompt applies with automatic
cleanup disabled; it executes none of them. Doctor reports private selections
only as counts. Official Homebrew manpage/FAQ/versions evidence and the reason
not to disable dependent linkage checks are recorded in
`docs/personal-macos.md`. Malformed/leaking facts, wrong links, formula drift,
unmanaged outdated output, missing readiness, ready state, and implicit
mode-0600 fact capture/cleanup pass, along with every earlier focused/audit
check on 2026-07-18.

Stage 8 adds `harness macos-control`. It validates canonical owner-controlled
paths, a clean committed public `main`, and the strict private profile before
creating any discovery link. It refuses regular-path, different-symlink,
symlink-parent, ambiguous-root, foreign-owner, and unsafe transaction-state
collisions. Apply creates only missing private parents and links, preserves
existing correct links and existing personal directory modes, records exact
mode-0600 transactions, and unwinds injected partial failures. Rollback
validates the whole manifest and all recorded state before mutation, refuses
changed links or unexpected content, and removes only unchanged links plus
empty directories created by that transaction. Plan/apply idempotence,
pre-existing-link preservation, changed-link and unexpected-content refusal,
symlinked state refusal, partial-failure cleanup, and exact rollback pass with
all earlier focused macOS suites on 2026-07-18. No live Mac or external state
was accessed or changed.

Stage 9 adds `harness macos-homebrew`. The exact formula allowlist is the
public baseline plus explicit private `extra_formulae`; capability labels are
never guessed into packages, and tapped names/dependencies are refused. The
adapter validates the active prefix, reads only selected versions and their
dependency/dependent closure, conservatively blocks any installed unmanaged
dependent, and runs exact formula-only dry-runs with update, cleanup,
analytics, prompts, and environment hints disabled. Apply repeats all gates,
never refreshes metadata implicitly, never invokes whole-machine inventory,
Bundle, casks, services, taps, cleanup, or removal, and retains mode-0600 local
pre/post/dependency/delta/log/status evidence. Because package changes are not
reversible, failed transactions explicitly retain evidence and require later
review rather than automatic uninstall or downgrade. Synthetic missing and
outdated convergence, scoped-command audit, dependency evidence, no-op,
unmanaged-dependent refusal, prohibited dry-run refusal, tapped-selection
refusal, and injected apply failure pass on 2026-07-18. Official Homebrew
manpage, FAQ, Versions, and Installation guidance were revalidated on the same
date. No live Homebrew or Mac state was read or changed.

Stage 10 adds the network-free `harness-bash` launcher and transactional
`harness macos-bash`. The launcher resolves a regular active Homebrew command,
its reported prefix, the installed Bash formula, and the physical Bash cellar;
it preserves the native account shell and performs only local prefix/version
reads. Integration collision-checks launcher/loader links plus `.bash_profile`
and `.bashrc`, rejects symlinks, hard links, foreign owners, unsafe parents,
and partial/duplicate markers, and appends one identical guarded loader block
in place. Existing startup bytes, inode, mode, and ACL are preserved; new files
are mode 0600. The loader is silent/inactive non-interactively and only marks
the managed interactive shell plus de-duplicates `~/.local/bin` to the front of
`PATH`. Exact rollback validates full post-images before unlink/truncation and
refuses later owner changes. Synthetic launcher routing, prefix/cellar refusal,
fresh interactive behavior, non-interactive silence, no-op, exact rollback,
changed-file, marker, symlink, hard-link, and injected partial-failure tests
pass on 2026-07-18. Doctor now requires the loader link and both exact startup
blocks. No Terminal preference, `/etc/shells`, `chsh`, zsh, Keychain, login
item, background job, live Mac, or external state was accessed or changed.

Stage 11 full synthetic validation passed on 2026-07-18: all seven focused
personal-macOS suites, public-repository/privacy audit, repository independence,
Claude takeover, the complete `tests/test-phase1.sh` including its ShellCheck
warning gate, and `git diff --check`. Native macOS CI was not added: a hosted
runner would either rely on mutable preinstalled Homebrew state or install
packages during CI, while the synthetic tests already assert BSD metadata call
shapes, prefix classes, exact native commands, transaction behavior, and
privacy boundaries. This decision adds no external CI cost or mutable package
action and can be revisited after pilot evidence identifies a native-only gap.

The public engine was published through protected PR #17 after required
`portable-phase1` passed, merging as
`a0b74a4a6936c591684325226c872f1ba02f327e`. Guarded fleet-sync then
fast-forwarded the six clean remote managed checkouts from
`3fa041271520162779567ba297ac7b7403ec2718` to that merge; `local` was already
at the target. A post-apply plan verified `local`, `ab`, `ab2`, `ri`, `al`,
`rc`, and `t4` clean at the target with every transfer artifact absent. This
publication and fleet synchronization touched no personal Mac or private
companion state.

**Next/authority boundary:** stage 12 must begin in an owner-started local
Codex or Claude session inside the selected pilot Mac's public harness checkout,
not from this cluster login node. Reconstruct this ledger there, then request
one exact approval bundle before creating/configuring the private GitHub
companion or changing authentication/remotes. Assign the opaque logical ID and
private formula intent only in that private/local context. After the strict
profile is valid, run value-minimized inventory to a mode-0600 local fact file
and review the read-only plan; do not apply links, Homebrew, or Bash in stage
12. Go does not itself authorize credentials/authentication changes, GitHub
creation or publication, Homebrew installation/upgrades, package cleanup,
background automation, or destructive actions.

On 2026-07-18 the owner-started Darwin pilot session completed the authorized
private-companion bootstrap and stage-12 observation without recording its
repository, logical ID, paths, or manifests publicly. The clean strict private
profile has zero optional capability groups and formulae; the value-minimized
fact file is owner-only mode 0600. The first read-only plan exposed a native
Homebrew semantic gap: named `brew outdated` correctly emitted two scoped
outdated public-baseline formulae and exited 1, which both public adapters
misclassified as query failure. The focused correction accepts exit 1 only
with nonempty output that still passes the existing strict managed-scope
validation; synthetic fakes now reproduce that native status. Portable syntax
and diff checks pass, and the corrected live plan reports four absent managed
links, six missing public formulae, two outdated public formulae, zero blocks,
and no applied package or network action. Native focused suites cannot complete
on this Mac because their cleanup fixture deliberately depends on the Linux
guarded-delete toolchain, and `shellcheck` is not installed; protected CI is
the remaining authoritative regression gate. Exact next action: publish this
adapter/test/ledger correction through a protected task PR, require
`portable-phase1`, then fast-forward the clean pilot checkout and repeat the
mode-0600 inventory/read-only plan before declaring stage 12 complete. Stage
13 link apply/rollback remains separately authorized and has not begun.

The separately authorized GitHub-CLI bootstrap dry-run then exposed a second
native Homebrew gap before any package mutation: current Homebrew rejects the
rendered `--no-ask` option. The safe portable contract is now to remove that
unsupported flag and invoke formula-only dry-run/apply through
`env -u HOMEBREW_ASK` with `NONINTERACTIVE=1`, automatic update/cleanup and
analytics disabled, and all existing dependency/scope gates intact. The same
dry-run also proved the pilot's Homebrew prefix and cache/log paths are not
writable by the current account. No suggested broad `sudo chown` or `chmod`
ran, and `gh` was not installed through Homebrew. A checksum-verified temporary
official GitHub CLI created and merged PR #19; required `portable-phase1`
passed and published `main` is `504f7a8`. Exact next action: validate and
publish the no-prompt portability correction through the protected workflow,
then repeat the clean stage-12 inventory/read-only plan. Do not change
Homebrew ownership or apply its rendered package commands.

Stage 12 completed on 2026-07-18 after PR #20 passed required
`portable-phase1` and published the no-prompt correction as `42399aa`. The
pilot checkout and strict private companion are clean; a fresh owner-only
mode-0600 fact capture and published-engine read-only plan passed with four
absent managed links, six missing public formulae, two outdated public
formulae, zero blocks, and `package_changes=not-applied network=none`. No
private value, repository identifier, logical ID, path, or manifest entered
public Git, and no discovery link, package, Homebrew ownership, shell startup,
background, or system state changed. The separately authorized GitHub CLI
device authentication was used only for protected PRs #19 and #20; its
checksum-verified temporary binary is safe to exact-unlink after this
checkpoint publishes. Exact next action: request separate stage-13 authority,
then run discovery-link plan/apply, fresh Codex and Claude doctor checks,
deliberate exact rollback, prior-state verification, and accepted reapply.
Stage 14 Homebrew/Bash remains unauthorized, and the non-writable Homebrew
prefix is a known blocker that must not be repaired with broad ownership or
mode changes without a separate exact plan and authority.

Stage 13 completed on 2026-07-18 under the owner's separate `proceed` authority.
The collision plan reported 34 absent discovery links and zero blocks. The
first apply created exactly those links with a private mode-0600 complete
transaction; its second plan was a 34/34 no-op. Fresh non-persistent read-only
Codex 0.144.5 and Claude Code 2.1.214 sessions each loaded canonical guidance
and discovered 10/10 shared skills. Fresh post-apply facts and doctor passed
architecture, Homebrew presence, Command Line Tools, private profile, public
checkout, all Codex/Claude guidance/rule links, and zero private formulae. Its
five not-ready results were exactly the excluded stage-14 Bash
launcher/loader/startup blocks and six missing public formulae. No attempt was
made to repair them. Deliberate rollback marked the first private transaction
rolled back and restored the exact prior 34-link-create plan with no residue.
The accepted reapply created a new private complete transaction; final plan is
again a 34/34 no-op, and two new non-persistent read-only client sessions again
passed canonical guidance plus 10/10 skills. Public Git contains no private
path, logical ID, repository, transaction ID, manifest, or fact payload.
Exact next action: request a separately reviewed stage-14 plan and authority.
Resolve the non-writable Homebrew prefix without broad recursive ownership or
mode changes before any formula action, then gate Homebrew and managed-Bash
mutations independently. No package, Bash startup, login-shell, Terminal,
Keychain, background, system, or Homebrew ownership change is authorized yet.

After stage 13 published as `9417286`, guarded fleet-sync preflight verified
the six remote managed Linux checkouts clean at `1395048`, with no transfer
artifact collisions. Apply fast-forwarded `ab`, `ab2`, `ri`, `al`, `rc`, and
`t4` to `9417286`; the local checkout was already at that target. A complete
post-apply plan exited zero with all six remote hosts retained clean at the
target and every transfer artifact absent. This synchronization changed no
personal Mac, private companion, package, shell, scheduler, or backup state.

Before sequential Mac rollout, add a cross-platform Core-tool compatibility
gate. Exercise the oldest observed Linux floors and current macOS/Homebrew
versions for Git, Git LFS, Vim, tmux, ripgrep, jq, tree, rsync, curl, wget,
htop, and SQLite. Check feature, output, configuration, protocol, and shared-
data behavior rather than assuming version-number equality. Give focused
coverage to Git safety defaults, tmux/Vim configuration floors, jq 1.8
language changes, rsync argument/protocol negotiation, curl TLS/protocol
removals, and SQLite forward compatibility. Keep upgraded CLIs isolated in
user space; never replace site shared libraries or alter `LD_LIBRARY_PATH`.
The current evidence found no mainstream AI/HPC requirement for an older Core
CLI, but this negative finding must be validated against the actual workflows
before accepting a wider managed baseline.

Stage 14 entered read-only planning on 2026-07-18. A fresh fetch proved clean
published `main` at `a7ff2df`. The managed-Bash plan passes with zero blocks
and four reversible changes: two fixed links plus marker-guarded appends to
`.bash_profile` and `.bashrc`, preserving their existing bytes, modes, ACLs,
and the native account shell. The bounded Homebrew plan correctly stops before
dry-run because installed unmanaged formulae depend on the managed dependency
closure. A separately reproduced exact scoped dry-run shows six selected
formula installs, two selected upgrades, shared dependency upgrades, and one
unmanaged dependent upgrade. No package or dependency changed. The earlier
non-writable-prefix conclusion was a restricted-sandbox false positive: under
the current owner-local execution context, all fixed Homebrew prefix,
Cellar/bin/lock, cache, and log roots checked are current-user-owned and
writable. No ownership or mode repair is needed or authorized. Exact decision
now required: either execute the reversible managed-Bash apply/rollback/reapply
while deferring Homebrew, or first redesign and publish dependency-delta gates
that can review the unmanaged dependent change before any formula apply. Never
bypass the current refusal or broaden private desired intent from installed
state.

The owner selected the recommended Bash-only route. After the planning
checkpoint passed protected PR #25 and published as `75dca87`, the clean
published-engine plan again reported four changes and zero blocks. Initial
apply created the launcher/loader links and exact guarded startup blocks with a
private complete transaction; the next plan was a four-part no-op. A clean
interactive launcher probe set the managed marker, loaded exactly once, and
placed `~/.local/bin` first. A clean non-interactive launcher probe retained
the launcher marker by design while the thin startup loader stayed unset and
silent. The native account shell remained unchanged. Deliberate exact rollback
marked the first private transaction rolled back and restored the original
four-change plan. Accepted reapply created a new private complete transaction;
final plan is a four-part no-op. Fresh mode-0600 facts and doctor now pass every
architecture, checkout, profile, discovery-link, Bash-link, and Bash-startup
gate; the sole not-ready result is the six deliberately deferred public
formulae. No package, dependency, Homebrew metadata, ownership/mode, native
login-shell, Terminal, Keychain, zsh, background, or system state changed.
Stage 14 remains open only for Homebrew. Exact next action: redesign the public
adapter to plan and validate actual dependency/dependent deltas instead of
bypassing its conservative unmanaged-dependent refusal, add focused synthetic
coverage, pass protected CI, then present the exact bounded package plan for
separate authority.

The owner then authorized tackling the Homebrew engine issue, not a live
package apply. The focused redesign checks installed dependents only for the
explicitly selected roots. Packages that merely share dependency libraries
remain unmanaged, while Homebrew's normal installed-dependent linkage checks
remain enabled. A direct or recursive dependent outside selected intent is
shown only in the private local plan, produces a value-free block reason, and
stops before transaction creation or apply. The dependency closure remains
captured and compared before/after apply. Synthetic coverage now requires a
selected-root dependent to block, proves a shared-dependency user is not
queried or absorbed into intent, and retains prohibited dry-run, failure
evidence, no-op, tap, and exact-scope gates. Portable shell syntax and diff
checks pass locally; protected CI is the authoritative focused/Linux gate.
Exact next action: publish the adapter/docs/test correction, require
`portable-phase1`, fast-forward the pilot, and run the native read-only plan.
The expected remaining selected-root dependent must be explicitly selected or
deferred by the owner before any separately authorized formula apply.

PR #27 passed required `portable-phase1` and published the dependency-scope
redesign as `ca28a73`. The clean native read-only plan now completes its exact
dry-runs and reports six selected installs, two selected upgrades, 12 shared
dependencies preserved, and exactly one direct selected-root dependent; it
then exits blocked before transaction or mutation. The dependent's name and
selection remain private. Exact decision now required: explicitly add that
formula to private desired intent because the owner wants it maintained, or
leave intent unchanged and defer Homebrew convergence. Installed state alone
must not decide.

The owner explicitly selected the one direct dependent for management. Its
name remains private. The strict companion now has one extra formula, is clean
on `main`, validates against schema v1 with zero capability groups, and is
pushed to its private origin. No package or dependency changed. Exact next
action after this value-free checkpoint publishes: run the clean native
Homebrew plan again, review its exact selected/dependency/dry-run scope, and
request separate authority before the irreversible apply.

PR #28 passed required `portable-phase1` and published the value-free private
intent checkpoint as `88b8808`. The clean native Homebrew plan now exits zero:
six selected installs, three selected upgrades, 12 shared dependencies
preserved, zero unmanaged selected-root dependents, and both exact dry-runs
validated. Automatic metadata update, cleanup, analytics, prompts, services,
casks, taps, removal, and whole-machine inventory remain disabled. No package,
dependency, or transaction changed. Exact authority now required: approve one
irreversible `harness macos-homebrew --apply` using this frozen scope. Apply
will repeat every checkout/profile/prefix/dependency/dependent/dry-run gate,
retain mode-0600 pre/post/delta/log evidence, and stop on any drift; package
rollback remains manual-review-only.

The owner authorized that one bounded apply after the checkpoint. PR #29
passed required `portable-phase1` and published the authority record as
`f1a0ce4`. The first combined invocation returned after plan without reaching a
transaction and changed nothing; the unchanged plan and absent transaction
made one standalone retry safe. That retry created a private mode-0600 failed
transaction, installed exactly one selected formula, then Homebrew raised an
internal bottle-metadata exception while beginning the first dependency. Its
own diagnostic requires `brew update` before retry. The current read-only plan
is retry-safe but changed to five remaining selected installs and three
selected upgrades; zero unmanaged selected-root dependents remain. No Git LFS
configuration command, retry, metadata refresh, cleanup, removal, ownership,
service, cask, tap, or automatic rollback ran. Exact authority now required:
approve the separately displayed Homebrew metadata refresh. After refresh,
rerun the full bounded plan and request confirmation if its selected,
dependency, or dependent scope differs; otherwise retry only the remaining
plan while retaining the failed evidence.

The owner authorized exactly `env HOMEBREW_NO_ANALYTICS=1 brew update`. After
PR #30 passed required `portable-phase1` and published the partial-failure
checkpoint as `b8a87bb`, that command updated the core and cask metadata and
changed no formula. It emitted a non-fatal missing remote-main-ref diagnostic
but completed its tap update and outdated report. The post-refresh bounded
plan exits zero with five remaining selected installs, three selected
upgrades, the same 12 shared dependencies, zero unmanaged selected-root
dependents, and validated exact dry-runs. This differs from the pre-failure
plan only by the one selected formula already installed and evidenced in the
failed transaction. Exact authority now required for one retry of this
remaining irreversible apply. The failed transaction must be retained; no
cleanup, rollback, Git LFS configuration, or whole-machine upgrade is implied.

The owner authorized one remaining-plan retry after PR #31 passed required
`portable-phase1` and published the refresh checkpoint as `0c18495`. The clean
plan matched exactly. The retry created a second private mode-0600 failed
transaction and reproduced the same Homebrew internal bottle-tab exception on
the first shared dependency; it changed no additional selected formula. The
current bounded plan remains five installs, three upgrades, 12 shared
dependencies, and zero unmanaged selected-root dependents. Read-only diagnosis
found the Homebrew engine itself on a clean legacy tracked branch at version
5.0.7, 3,380 commits behind the current remote 6.x head. The earlier `brew
update` refreshed taps but failed to advance the engine because its expected
remote ref was then unavailable. A direct fetch now proves the current engine
is a strict ancestor of both remote default refs and the worktree is clean.
Exact authority now required for a Homebrew-repository `git merge --ff-only`
to the already fetched tracked remote head, followed by version and bounded
read-only-plan validation. Do not use reset, rebase, update-reset, reinstall,
cache deletion, package retry, or transaction cleanup.

The owner authorized exactly that fast-forward-only engine repair after PR
#32 passed required `portable-phase1` and published the diagnosis checkpoint as
`dfd68f3`. `git -C /opt/homebrew merge --ff-only origin/master` advanced the
clean engine from `d61f229fd2` to `2cd4aea237`; local `master` now exactly
matches `origin/master`, and `brew --version` reports 6.0.11-96-g2cd4aea. The
subsequent bounded read-only plan exits zero without the bottle-tab exception
and retains the same remaining scope: five selected installs, three selected
upgrades, 12 shared dependencies preserved, zero unmanaged selected-root
dependents, and validated exact dry-runs. No formula, dependency, transaction,
cache, ownership, service, cask, tap, or cleanup state changed during this
repair and validation. Exact authority is now required for one package-apply
retry against this unchanged remaining plan; the two failed transactions must
remain retained and package rollback remains manual-review-only.

The owner authorized that one bounded retry. A fresh fetched-main preflight
and native plan matched the frozen scope exactly. Transaction
`20260718T133449Z-27726` completed with five selected installs and three
selected upgrades; the adapter retained its 12-dependency closure and reported
no unmanaged selected-root dependents. The immediate convergence plan exits
zero with zero installs, zero upgrades, and zero unmanaged dependents. The
macOS-specific doctor passes all required architecture, Homebrew, Command Line
Tools, private-profile, checkout, discovery-link, Bash-link/startup, and public
and private formula gates with zero failures or warnings. An attempted generic
`harness doctor --host office` was a non-mutating wrong-family CLI invocation
and rejected the private logical profile; `harness macos-doctor --host office`
is the applicable route and passed. The two earlier failed transactions remain
retained, no cleanup or automatic rollback ran, and package rollback remains
manual-review-only. Stage 14 is complete. Exact next action: separately review
and authorize stage 15's disposable long-gap acceptance drill; do not begin
sequential rollout.

Checkpoint validation: `git diff --check` passes. Direct native execution of
`tests/test-personal-macos-homebrew.sh` stops in its Linux-oriented fake BSD
`stat` shim because that shim delegates to unsupported macOS `/usr/bin/stat
-c`; cleanup then reports unsupported `realpath -e`. This occurred in the
synthetic temporary fixture after live convergence and changed no managed
state. The required protected Linux `portable-phase1` run remains
authoritative and must pass before merge.

## Stable operational facts

- The 2026-07-15 accident was an agent-issued raw recursive deletion of
  `/home/rioyokota` after a temporary `HOME` assignment expired. Processes were
  terminated; no usable whole-home filesystem snapshot existed. Harness and
  website recovery are complete. Unknown former profiles and `sshservice-cli`
  remain intentionally unreconstructed.
- The guarded-delete schema protects lexical and canonical account homes,
  binds immutable manifests to exact identities/counts/bytes, revalidates
  immediately before apply, and verifies anchors afterward. RC and load-balanced
  AL require the documented canonical-home/persistent-session handling; never
  weaken the guard.
- Fresh interactive Bash shells wrap direct `rm`, `rsync`, `find`, `chmod`,
  `chown`, `qdel`, and `scancel` commands. Normal forms pass through unchanged;
  protected high-blast-radius forms fail before native execution. `command`,
  absolute executable paths, child shells, and batch scripts remain deliberate
  bypasses, so the manifest-backed guarded-delete workflow remains mandatory
  for agent-run recursive or bulk deletion.
- The current node uses the packaged systemd user SSH agent at the fixed
  current-user-owned socket declared in `docs/ssh-agent.md`. Recovery checks
  the process socket, current tmux session, then the declared fixed socket; it
  never reads tmux-global agent state or key contents.
- `/mnt/nfs-03` is a hard NFSv4.2 mount whose metadata latency makes large
  small-file restore/cleanup trees extremely slow even when throughput and
  capacity are healthy. Keep packed repositories/generations on large storage
  and materialize restore tests on node-local mode-0700 scratch.
- AL authentication uses the owner's existing `id_ed25519` certificate renewed
  by `cscs-key sign --headless -f ~/.ssh/id_ed25519`. The local `al` convenience
  alias is intentionally owner-only in the current node's `.bashrc` and must
  not be mirrored.
- AB2's 10 TB group quota is active. Its `.local` migration, approved cleanup,
  primary, independent generation, full-data checks, restores, and guarded
  cleanup completed under T-192. `.bash_history` remains node-local.
- `profiles/home-layout.tsv`, `profiles/restic-repositories.tsv`, host profiles,
  `docs/environment-portability.md`, `docs/home-backup.md`, and
  `shared/skills/operate-native-hpc/references/sites.md` are the canonical
  current declarations; do not copy obsolete ledger prose back into them.

## Completed-task index

Git history is the durable evidence store. Consult `303938f:TODO.md` for the
earlier recovery/storage history and `d910a40:TODO.md` for detailed T-193
through T-261 chronology when command-level evidence, transaction IDs,
aggregate counts, hashes, or failure chronology is required.

| Task | Completed outcome / durable pointer |
|---|---|
| T-169 | Advanced-harness research and proposal inventory completed. |
| T-170 | Seven-node portable environment parity completed; capability design is in `docs/environment-portability.md`. |
| T-171 | Current-home incident contained and recoverable tracked/tool state restored; safety commits include `68fb820` and `238f022`. |
| T-172 | Exhaustive Git recovery re-audit found no additional candidate. |
| T-173 | ShellCheck 0.11.0 reconstructed as checksum-pinned new work at `2222fc5`. |
| T-174 | Test cleanup routed through guarded deletion. |
| T-175 | Local-only pinned lftp restored at `292c6b4`; website validation at `362847d`. |
| T-176 | Internal transaction tree cleanup routed through guarded deletion. |
| T-177 | Restored ShellCheck findings fixed and warning-level lint made durable. |
| T-178 | Hyphenated tool fact-key normalization completed. |
| T-179 | ABCI PBS command discovery reconciled without startup-file sourcing. |
| T-180 | Aggregate plans now enforce pinned Node/npm versions. |
| T-181 | Seven-family acceptance evaluation completed: clean pilot 18/18; full deterministic 69/70 with zero safety failures, 13 reviewed pairs, one recorded semantic-oracle false negative, and no candidate adoption. Evidence is in `evaluation/results/`, commit `ee96853`; post-experiment hardening is `d26c5a3`. |
| T-182 | Seven-node storage, shell/control-plane, Restic, and independent-generation workflow completed; exact evidence spans commits through `303938f`. |
| T-183 | Credential-safe private-origin login sync and explicit remote Codex launcher completed at `2c2dff0` and `4f34299`. |
| T-184 | Truncated guarded-delete manifest publication rejected at `f31aeb5`. |
| T-185 | Non-interactive managed Restic resolution completed. |
| T-186 | AL authentication migrated to owner-renewed `cscs-key`; obsolete helper removed. |
| T-187 | AL guarded plan/apply constrained to one persistent login session. |
| T-188 | NFS-independent local replica at T4 passed full check/restore (`56c15a7`). |
| T-189 | Ledger-backed PIE skill created and validated at `dfaea9e`. |
| T-190 | Automated guarded mirrored-node onboarding skill completed, installed, tested, and published at `b5bb171`. No live node was onboarded. |
| T-192 | AB2 quota deferral, primary, replica, restore, migration, and cleanup completed at `1c2050a` and `303938f`. |
| T-193–T-195 | Public-repository audit, contributor CI/ruleset preparation, and seven-node drift audit completed or superseded; full detail is at `d910a40:TODO.md`. |
| T-197–T-209 | Evaluation decision and portable environment/HPC capability foundations completed; full detail is at `d910a40:TODO.md`. |
| T-210 | Cross-architecture numerical consistency passed on all seven routes. On 2026-07-18, exact PBS history confirmed AB `2045064.pbs1` and AB2 `2045063.pbs1` terminal `F`/`Exit_status=0`; both private mode-0600 results matched the frozen source contract and `-0x1.b6ap+2`, with zero capture residue. Full chronology is at `d910a40:TODO.md`. |
| T-211–T-246 | Checkpointing, debugger, MPI, scheduler, topology, intake, audit, and durable-handoff gates completed; full detail is at `d910a40:TODO.md`. |
| T-247 | Captured readiness work and cleanup were completed or superseded by T-249–T-252; full chronology is at `d910a40:TODO.md`. |
| T-248 | Obsolete `.bash_common` startup references and files removed transactionally. |
| T-249 | Seven-node startup normalization, bounded agent forwarding, and four exact guarded environment deletions completed; durable evidence begins at `ce2ccce`, `2e93750`, and `53402ec`. |
| T-250–T-252 | Seven-node directory cleanup, owner/site gate resolution, and readiness-queue reconciliation completed; full detail is at `d910a40:TODO.md`. |
| T-253 | Stable packaged SSH agent, tmux/Codex propagation, and authenticated GitHub SSH transport completed; see `docs/ssh-agent.md`. |
| T-254–T-256 | Rootless GitHub CLI installation and separate authenticated API/settings preflight completed. |
| T-257 | Automatic Git fetch-at-login and commit/push-at-exit hooks removed at `e52a3d0`. |
| T-258 | Harness and website CI-backed `main` rulesets activated and PR-tested; later owner policy sets required approvals to zero. |
| T-259 | Interactive recursion sentinels made shell-local so aliases load in every new tmux window at `887f2c9`. |
| T-260 | PBS lifecycle email disabled by default for agent-run AB/AB2 jobs at `9b28c19`. |
| T-261 | Interactive destructive-command safeguards implemented, CI-tested, and rolled out across all seven nodes at `accca9d`; completion checkpoint `d910a40`. |
| T-262 | Active ledger compacted from 3,364 lines to the three resumable tasks; safeguard and live zero-approval ruleset documentation/payloads aligned and the complete portable suite passed. |
| T-263 | Harness and website made operationally independent: website owns cleanup, CI, policy/audit evidence, and rootless lftp bootstrap; harness removed all website-specific ownership. Isolated clones and required CI passed; website PR #3 merged as `6f1ad83`, harness PR #7 as `f1b095c`. No deployment, live tool removal, account setting, fleet, or scheduler action ran. |
| T-264 | Reconciled the compact active ledger and public README with the deployed seven-node control plane, backup recurrence gate, SSH-agent/session behavior, protected collaboration workflow, and harness/website independence. |
| T-265 | Made Codex-to-Claude takeover repository-complete: added root project instructions and Claude import, explicit cross-client handoff policy, collision-before-mutation installer preflight, and focused plus transactional tests for Claude guidance/settings/skills. Live seven-environment preflight passed Claude 2.1.207, canonical guidance, 10/10 shared skills, and 34/34 managed links with no planned changes. |
| T-266 | Corrected local MPI discovery: fresh interactive shells preserve an existing toolchain or load the reviewed Open MPI 5.0.8 module, tracked local batch jobs select the same module explicitly, and focused regression coverage protects both boundaries. |
| T-267 | Ran three independent Claude Code cold-takeover tasks with bounded tools: ledger reconstruction and the MPI audit passed, Claude added a correct cross-host MPI isolation regression, exact permissions denied one extra history query and two spelling-variant test attempts, and primary review plus the complete portable suite passed. Durable evaluation: `docs/audits/claude-live-takeover-2026-07-18.md`. |
