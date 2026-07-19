# Personal harness task board

This is the authoritative resume point for the portable Codex and Claude
harness. Git retains superseded chronology and command-level evidence. Keep
only active decisions, verified prerequisites, blockers, exact next actions,
and compact historical pointers here. Next free ID: T-272.

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
- Exactly one future native weekly primary job is present on each managed node.
  T-191's seven first runs passed scheduler, snapshot, successor, private-state,
  and warning-silence acceptance on 2026-07-19. No login-node cron, user timer,
  retention deletion, or automatic replica job exists.
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

T-268 and T-269 remain separate `executing` rollout tasks. The `office` pilot
has completed both ordered live applies. T-268 migrated the private companion
to SSH-only desired state, installed the public Bash pre/local/post ordering,
and linked the one public tmux configuration with a recoverable local
transaction. T-269 adopted the public Codex and Claude settings plus launcher;
its immediate doctor reported `status=ready failures=0`, with zero component
declarations and no package action. Neither apply reloaded an active shell,
tmux server, Codex session, or Claude session, and private transaction
identifiers remain local.

Exact next owner action on `office`: start fresh managed Bash and tmux sessions
and fresh Codex and Claude sessions, then confirm the frozen behavior. Any
unchanged-only rollback/reapply drill remains separately authorized. After
pilot observation, resume the explicit rollout order: independently revalidate
`local`, run separately authorized local tmux and agent-config plans/applies/
doctors/drills, then plan the six Linux remotes and obtain one reviewed
stop-on-first-failure authority bundle before sequential apply to `ab`, `ab2`,
`ri`, `al`, `rc`, and `t4`. The one-way `local`-to-`t4` SSH mirror remains a
separate explicit Linux command and authority gate. Only after Linux acceptance
should each remaining Mac be brought online and planned/applied independently;
never batch Macs or infer their state from `office`.

Before every rollout step, fetch and revalidate the current published target,
clean checkout, transport/authentication, private schema where applicable, and
absence of transfer-artifact collisions. No background/login-time mutation,
automatic publication, credential synchronization, plugin/MCP authorization,
package upgrade, active-session reload, or unrecorded rollback is allowed.
T-196 remains at 1/8 until the captured 2026-07-26 successors are eligible;
query only those recorded IDs after eligibility and do not replace or duplicate
a delayed job. T-210 is complete and must not be repeated.

## Active tasks

### T-271 — Comprehensive post-pilot update and cleanup

**Phase/status:** `complete`. Reconciled stale public ledger/control-plane
state after the completed `office` pilot, then perform only the owner-selected
bounded update and cleanup surfaces with independent safety and authority gates.

**Read-only inventory (2026-07-19):** public `main` is clean and current at
`0406a8b67a631d97df693d69ff4f70bdd37897cf`, with one worktree, no local or
remote task branch, no open PR, and no Git garbage. The top `TODO.md` resume
checkpoint is materially stale: it still describes the already-completed
T-268/T-269 pilot plans and applies as future unauthorized work, while the task
records correctly contain their successful apply outcomes and remaining fresh-
session/rollback/rollout gates. Homebrew reports 54 outdated formulae, no
outdated casks, and six cleanup candidates totaling about 189.2 MB. The known
disposable stage-14 temporary tree remains present. No file contents, private
transaction, credential, live config value, active session, remote checkout,
package, or scheduler state was changed or inspected.

**Recommended plan:** treat “everything” as bounded housekeeping, not implicit
rollout or software upgrade authority. First replace the stale top checkpoint
with the exact current T-268/T-269 state and next ordered actions; compact any
newly superseded duplicate ledger prose; validate and publish that documentation
through protected review. Recheck Git refs/worktrees/objects and perform only
non-destructive native maintenance if evidence warrants it. If the owner wants
the known disposable tree removed, invoke `guarded-bulk-delete` and require its
canonical-boundary, manifest, revalidation, and post-delete gates. Keep Homebrew
cleanup, 54 formula upgrades, Linux fleet synchronization/config rollout,
remaining-Mac rollout, rollback/reapply drills, and fresh-session mutation as
separate opt-in decisions. Never inspect private payloads or credentials.

**Execution/validation order:** (1) freeze scope decisions; (2) wait for an
explicit `go`; (3) checkpoint `executing`; (4) update only selected public
ledger/docs and validate pointers plus `git diff --check`; (5) run selected Git
maintenance with before/after object evidence; (6) use the guarded deletion
workflow for any selected disposable tree; (7) perform separately authorized
package or fleet work only if explicitly selected and planned; (8) independently
verify clean `main`, one worktree, branch/PR state, excluded surfaces unchanged,
and publish the durable handoff. Stop on dirt, ambiguous ownership/boundary,
private-output risk, authentication failure, package-scope drift, or any live
state inconsistent with the frozen plan.

**Decision H1:** selected repository ledger/Git housekeeping plus guarded
removal of the one known disposable temporary tree. Homebrew cleanup/upgrades,
Linux fleet synchronization/config rollout, remaining-Mac rollout,
rollback/reapply drills, and live-session changes are excluded. Git object
maintenance will run only if refreshed evidence shows garbage or material
reclaimable state; the current inventory does not. The deletion boundary is the
retained canonical `/private/tmp`, the sole target is the existing exact
`/private/tmp/harness-gh-stage14.DACMP6`, and the manifest will be a new exact
mode-0600 file directly under `/private/tmp`; the deterministic plan must confirm
those canonical identities before apply. The explicit owner `go` was received,
and the stale top resume checkpoint was replaced with the published pilot-apply
state and remaining ordered observation/rollout gates without changing either
task's separate record. `git diff --check` passes, and refreshed Git evidence
still warrants no object maintenance.

**Guarded-delete failure checkpoint:** the required plan stopped before
manifest creation with the exact value-free result `guarded-delete: required
command is unavailable: getent`. The sole target remains present and the exact
manifest path remains absent; no deletion or fallback remover ran. Retry is safe
only after a public macOS-capable guarded-delete correction passes focused and
protected validation. **Decision H2:** either separately authorize that narrow
public portability correction and then resume the same exact guarded plan
(recommended), or leave the known disposable tree present and publish only the
completed ledger/Git housekeeping.

**Decision H2 package-route checkpoint:** the owner selected installation of
`getent` rather than a guard correction. The exact bounded command disabled
Homebrew auto-update and install cleanup, but stopped before installation with
`Error: No formulae or casks found for "/^getent$/".` Homebrew exposes no such
formula on this pilot; `getent` remains absent, and no package, cleanup,
manifest, or target changed. H2 is unresolved again: authorize the narrow
public macOS guarded-delete correction, or retain the disposable tree.

**Decision H2 selected / portability discovery:** the owner selected the public
guard correction. Public-code and command-presence inspection then proved this
is not a one-command fallback: the implementation also hard-codes GNU
`realpath -e`, `stat -Lc`/`stat -c`, and `find -printf` in its plan/apply
revalidation path. macOS provides `dscacheutil`, `dscl`, BSD `realpath`, BSD
`stat`, BSD `find`, `shasum`, and an existing `sha256sum`, but no `getent` or
GNU-prefixed path/metadata/find commands. A correct change must add explicit
platform adapters for authoritative-home lookup, canonicalization, identity,
owner/mode/size, and tree entry/byte facts; preserve the manifest schema and all
protected-anchor/revalidation invariants; add synthetic Darwin-command-shape,
HOME-mismatch, alias/canonical drift, manifest integrity, and real native plan
coverage; then pass the focused suite and protected `portable-phase1`. It must
not install GNU packages or weaken Linux behavior.

**Decision H3:** this broader-but-bounded full macOS portability correction is
recommended because adapting only `getent` would immediately fail at the next
GNU-only gate. Alternatively, leave the disposable tree present and publish the
completed ledger-only cleanup. No public implementation or deletion may begin
until H3 is selected and a fresh explicit `go` follows the revised audit.

**H3 package-availability evidence:** the current official Homebrew index
offers bottled `coreutils` 9.11 and `findutils` 4.11.0 for macOS. `coreutils`
would supply GNU `realpath` and `stat` under prefixed command names and includes
GNU hashing utilities; `findutils` supplies prefixed GNU `find`. Neither formula
provides `getent`, and an exact Homebrew search returns no `getent` formula or
cask. Rust `uutils-coreutils`/`uutils-findutils` alternatives also exist with
their own prefixes but still do not resolve authoritative account-home lookup.
The pilot already has native `dscacheutil`/`dscl`, BSD path/metadata/find tools,
`shasum`, and a `sha256sum`. Installing GNU packages would therefore add two
new package dependencies yet still require a macOS home-database adapter. The
recommended H3 remains a self-contained platform-adapter correction with no new
package requirement.

**Decision H3 selected / revised final audit:** implement the complete native
macOS adapter correction with no new GNU package dependency. Preserve the
manifest schema, freshness/token/identity/count/byte revalidation, protected
lexical and canonical home anchors, Linux command behavior, and exact emitted
native actions. Add focused synthetic Linux/Darwin routes plus a real native
plan that must publish a mode-0600 manifest for only the frozen target; require
focused tests, ShellCheck, `git diff --check`, public privacy audit, and
protected `portable-phase1`. Publish and cleanly fast-forward `office` before
creating a fresh guarded plan; inspect its `PLAN`, sole `TARGET`, and exact
`NEXT`, then apply only that emitted command and verify both target and manifest
absent. Finally publish the updated ledger checkpoint and leave clean `main`.
No package, fleet, live-config/session, rollback/reapply, or broader cleanup is
authorized. All required decisions are frozen and internally consistent, and
the fresh owner `go` was received. Exact first action: implement and test the
platform adapters without contacting the deletion target.

**Mac guard implementation checkpoint:** the public manifest-backed CLI now
selects native adapters for authoritative-home lookup, canonical paths,
identity/owner/mode/size metadata, tree entry/byte facts, hashing, file
persistence, and filesystem-bounded deletion while leaving the GNU/Linux route
and manifest v2 schema unchanged. A real disposable macOS plan/apply cycle
under `/private/tmp` published a mode-0600 manifest, revalidated one target with
three entries, deleted only that target through BSD `find -x ... -delete`,
reported protected anchors unchanged, and left both synthetic target and exact
manifest absent. A Linux-CI fixture translates every Darwin command shape back
to GNU fixture tools and requires the same verified plan/apply result. Portable
syntax, warning-level ShellCheck, and `git diff --check` pass. The complete
focused suite on this Mac still reaches the separate pre-existing GNU-only
`guarded_delete_tree` test helper before its Linux assertions; protected Linux
CI remains authoritative for that existing route and the new synthetic Darwin
route. No selected live cleanup target, package, private value, fleet node, or
active session changed. Exact next action: publish the public correction and
ledger update through protected review, fast-forward clean `office`, then run
the frozen real guarded plan against only the known stage-14 tree.

**Protected publication and cleanup outcome:** protected PR #76 passed required
`portable-phase1` in 2m28s and squash-merged the native guard plus corrected
resume checkpoint as `2e278a6fde209fceebcc9ec5722124f0a47556ac`.
Clean `office` fast-forwarded to that exact `origin/main`. The fresh guarded
plan confirmed retained boundary `/private/tmp`, one exact target with 239
entries and 53,144,497 bytes, and a new mode-0600 manifest. Its exact emitted
apply revalidated the 13-second-old token, every identity/count/byte fact, and
all protected anchors; it deleted only
`/private/tmp/harness-gh-stage14.DACMP6` and reported
`VERIFIED protected_anchors=unchanged targets=absent`. The single exact
manifest was then unlinked and both target and manifest were independently
verified absent. No fallback remover, package, Homebrew cleanup/upgrade, Git
object rewrite, fleet/live config change, drill, or session reload ran. Final
validation now requires `git diff --check`, clean one-worktree/branch/PR state,
protected publication of this outcome, and exclusion-state review before T-271
can close.

### T-196 — Backup lifecycle phase 2

**Phase/status:** `policy resolved`, execution-gated on eight successful weekly
chains, two verified restores per node, and a current verified independent
generation. T-251 locked the 12-weekly/12-monthly/3-yearly exact-group policy,
monthly rotating quarter-data checks, quarterly full-data/full-restore checks,
monthly sampled restores, and monthly manual independent generations retaining
the latest two verified copies. No live retention, `forget`, `prune`, recurring
check/restore, or replica automation is authorized yet. The eventual actions
remain behind their later exact-command authority boundaries.

**Production checkpoint:** the 2026-07-19 first weekly run passed on all seven
nodes, so every chain is at 1/8. The captured 2026-07-26 successors are
`local` `91840`, `ab` `2048464.pbs1`, `ab2` `2048468.pbs1`, `ri` `7242`,
`rc` `212389`, `t4` `8194556`, and `al` `4238363`. They were identity-matched
and future-pending/waiting at the T-191 close. Treat delay as healthy and query
only the captured ID after eligibility. Full acceptance evidence is in
`docs/audits/restic-first-weekly-2026-07-19.md`.

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
opaque host deltas. S1–S10 first added the exact SSH payload exception;
D11–D14 later expanded it to the exact atomic SSH, private Bash-fragment, and
complete-tmux payload set. Other copied configuration, observed inventories,
live facts, transactions, credentials, and secrets remain prohibited. Public
and private repositories fast-forward independently, but their engine/schema
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

**Original decision audit:** D1–D10 are internally consistent for the completed
CLI/Bash-launcher stages and published SSH-only S1–S10 engine. The frozen order
is public schema/private contract, long-gap updater, Darwin portability and
observation, strict resolver,
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

PR #34 passed required `portable-phase1` and published the completed stage-14
checkpoint as `8ad536b`. A post-merge guarded cleanup plan for the temporary
verified GitHub CLI extraction stopped before manifest creation because the
guarded-delete implementation requires Linux `getent`, which is unavailable
on this Mac. No deletion fallback was used. The disposable tree remains at
`/private/tmp/harness-gh-stage14.DACMP6`; removing it later requires a
macOS-capable guarded-delete path, not raw recursive deletion.

The owner authorized stage 15's disposable long-gap acceptance drill and no
part of stage 16. Read-only reconstruction maps every frozen acceptance gate
to `tests/test-personal-macos-update.sh`: isolated synthetic public/private
bare origins and clones plus a private state root begin at the oldest released
schema-v1 engine/companion baseline; the primary route proves an initial direct
fast-forward, compatibility and initialization, a current no-op, exact state
rollback/reapply, then a second direct fast-forward with ordered v1 migration
and exact prior-state restoration while repositories stay current. A separate
injected private-fast-forward failure proves public-first partial-update retry
safety without state mutation. Incompatible schema and prohibited private
layout cases fail before checkout mutation or private-value disclosure. No
newer schema exists to migrate, and missed intermediate deployments are not
replayed. Exact execution action: publish this stage boundary, require the
protected Linux `portable-phase1` run containing that drill, inspect its result,
then checkpoint stage 15 complete only if the full gate passes. Do not access a
live private companion, mutate the pilot Mac, dispatch a separate workflow, or
begin sequential rollout.

PR #36 published the frozen drill boundary as `1d02796`. Protected Harness CI
run `29647147390`, job `88087186629`, passed `portable-phase1` in 1m39s; that
gate executed the full disposable long-gap update suite and all phase-one
regressions. The accepted evidence therefore covers both direct
fast-forwards, compatibility validation, initialization and ordered v1
migration, idempotent current behavior, public-first partial-update retry,
changed-state rollback refusal, exact state restoration without Git rewind,
incompatible-schema/layout refusal, privacy-negative output, and guarded
fixture cleanup. No live public/private checkout, pilot state, package, shell,
service, or other machine was changed by the drill. Stage 15 is complete.
Exact next action: plan stage 16 against one privately selected remaining Mac,
revalidate that Mac independently, and obtain separate authority for its
update/migration plan before any apply. Do not batch Macs or infer their state
from the pilot.

The owner introduced a new SSH-configuration synchronization requirement
before continuing rollout. All personal Macs are equal writers: `office` is
not canonical, a complete `~/.ssh/config` change made on any Mac must be
propagated to the others, and “mirror” means exact whole-file replacement
rather than a managed include. Separately, the `local` Linux node's complete
`~/.ssh/config` must mirror one-way to `t4`; `ab`, `ab2`, `ri`, `al`, and `rc`
must remain unchanged. Keys, agent state, `known_hosts`, and other `~/.ssh`
contents are out of scope. This conflicts with the current personal-Mac design
and private companion contract, both of which prohibit copied SSH
configuration, and with the existing `harness dotfiles` include-only adapter.
T-268 is therefore back in `interviewing` for this explicit scope expansion.
No SSH config has been read, copied, published, or changed. Next decision:
freeze multi-writer conflict handling and the private transport/source-of-truth
model before inspecting config contents or designing apply/rollback.

**SSH-sync decision S1:** selected fail-closed multi-writer Git semantics. Each
Mac may originate a complete config revision, but a push/pull that is not a
clean fast-forward stops and requires an explicit private merge. No timestamp,
machine priority, automatic conflict resolution, or last-writer-wins overwrite
may discard another Mac's revision. Exact prior revisions provide recovery.
Next decision: choose an isolated private repository or deliberately expand the
existing `harness-mac` companion contract to store the copied SSH config.

**SSH-sync decision S2:** selected deliberate expansion of the private
`harness-mac` companion rather than a second repository. Its strict tracked
layout may add one complete shared Mac SSH config, while public Git and public
logs retain only value-free validation results. The config remains separate
from runtime facts/transactions and must never contain private-key contents,
tokens, passwords, agent state, `known_hosts`, or other credential material.
Apply must validate a regular mode-0600 destination and SSH syntax, retain an
exact private rollback image, and atomically replace only `~/.ssh/config`.
Next decision: choose explicit owner-invoked synchronization or background
propagation timing.

**SSH-sync decision S3:** selected automatic background synchronization via a
per-user macOS `launchd` agent, explicitly superseding D6 only for this one SSH
config workflow. Package, repository-engine, migration, shell, and other apply
actions remain manual. The agent must validate syntax and identity before
publishing or replacing, use normal non-force Git operations, stop on
divergence or unrelated private-checkout dirt, and leave the last valid local
config untouched on authentication, network, validation, or merge failure.
It may never prompt, access key contents, or emit config values to logs.
Next decision: freeze event/interval scheduling for local edits and remote
updates.

**SSH-sync decision S4:** selected a `launchd` `WatchPaths` trigger on the Mac
SSH config plus a five-minute `StartInterval` remote poll. One owner-local lock
serializes triggers; content/revision comparison makes self-triggered atomic
replacement a no-op. A local validated change is committed and pushed when the
private checkout is clean and current; remote fast-forwards are validated and
atomically applied. Divergence remains a visible stopped state requiring an
explicit merge. Next decision: choose propagation timing for the independent
one-way `local` Linux to `t4` mirror.

**SSH-sync decision S5:** selected automatic propagation for the independent
one-way `local` Linux to `t4` mirror. `local` is the sole source and `t4` is
destination-only; no `t4` edit is copied back, and `ab`, `ab2`, `ri`, `al`, and
`rc` remain excluded. The job must use non-interactive `BatchMode=yes` through
the owner's existing agent, fail without prompting when authentication or
connectivity is unavailable, validate source and staged destination syntax,
retain a mode-0600 exact prior image on `t4`, and atomically replace only
`~/.ssh/config`. It may not enumerate or copy keys, agent state, `known_hosts`,
or other SSH files. Next decision: freeze the Linux timer cadence and trigger
model.

**SSH-sync decision S6:** selected a five-minute persistent per-user systemd
timer on `local`. Each activation validates the source, compares a cryptographic
content identity, and contacts `t4` only for a changed valid revision;
`Persistent=true` catches up after downtime. Activations serialize and use
bounded non-interactive SSH timeouts. Next action: perform value-minimized
read-only source/destination discovery, then settle rollback retention and
operator-visible failure reporting.

Read-only discovery on the current Mac found one regular parseable SSH config:
mode 0644, five `Host` blocks, zero `Match` and `Include` directives, zero
`IdentityFile` references, and two forwarding directives. No values or bytes
were emitted or copied. Managed Mac destinations will normalize the exact file
to mode 0600 on first authorized apply. This Mac has an explicit `t4` SSH route
but no explicit logical `local` route, so Linux-source discovery and timer
installation must occur in an owner-started session on `local` or through a
separately approved route; no endpoint will be guessed.

**SSH-sync decision S7:** selected one mode-0600 prior rollback image on `t4`.
It is replaced only after a newly staged source passes identity and SSH syntax
validation, immediately before atomic destination replacement. Mac rollback
uses complete private Git history rather than extra config archives. Next
decision: freeze value-free failure visibility and notification behavior.

**SSH-sync decision S8:** selected value-free local status files, bounded local
logs, and `harness doctor` reporting, with native `launchd`/systemd status as
the operator surface. No desktop notification, email, Slack, or other external
message is added. Public output reports only current/diverged/invalid/offline/
auth-failed classes and revision/hash agreement, never config values,
endpoints, usernames, private paths, or raw Git/SSH diagnostics. Next decision:
freeze unattended private-Git authentication boundaries for the Mac agent.

**SSH-sync decision S9:** selected reuse of each Mac's existing private-repo
authentication only, exercised with non-interactive Git/SSH behavior. Harness
will not install, copy, inspect, select, or reconfigure keys, tokens, helpers,
Keychain entries, agents, or remote URLs. An unavailable credential records
only `auth-failed` locally and leaves the live config and private checkout
unchanged. The Linux timer follows the same existing-agent/BatchMode boundary.
Next decision: freeze rollout order—validate the generic implementation and
private schema on `office` first, then require an independent owner-started
session for each other Mac and finally a separate `local` session for the
one-way `t4` timer.

The owner then revised the propagation model: SSH-config synchronization must
be part of the original explicit owner-started pull/catch-up workflow. This
supersedes S3–S6 scheduling only. No `launchd` agent, WatchPaths trigger,
background poll, systemd timer, or persistent unattended catch-up will be
created. S1 exact fail-closed multi-writer Git conflict handling, S2 storage in
the private `harness-mac` companion, S7 one prior `t4` rollback image, S8
value-free status/logging, and S9 no credential management remain selected.
For Macs, an owner-started catch-up must first reconcile/publish any valid
local config edit or stop on divergence, then fast-forward the private repo,
validate the selected complete config, and atomically apply it as mode 0600.
Next decision: clarify whether the one-way `local` to `t4` mirror belongs in
the same explicit user-run command family or remains a separate explicit
Linux command, since Mac-local pull cannot safely originate the Linux source.

**SSH-sync decision S10:** selected a separate explicit owner-run Linux command
executed on `local` for the one-way `t4` mirror. It is not part of a Mac command
or a broad fleet action, and it cannot target any other Linux host.

**Frozen SSH-sync execution plan:** T-268 is `executing`; the owner gave the
new explicit `go` for this frozen expansion on 2026-07-19. That go authorizes
the generic public engine/schema/tests and protected publication. Live private
payload seeding, Mac config mutation, and `local`-to-`t4` apply remain the
sequential later stages already separated below.

1. Extend the public private-companion schema contract to allow exactly one
   repository-root shared Mac SSH-config payload with strict regular-file,
   owner, tracked-layout, size, and no-symlink/hard-link gates. Keep its bytes
   private and update privacy-negative fixtures so public output never exposes
   directives, endpoints, usernames, paths, or hashes. Existing host manifests
   remain curated intent and runtime state remains prohibited.
2. Add a Mac SSH-sync adapter integrated into the explicit Mac catch-up route.
   It records a private last-applied revision/content identity. A valid local
   edit against the recorded base becomes the candidate private revision only
   after fetch proves the private checkout current and clean; it commits and
   pushes normally. A simultaneous remote advance plus local edit stops as
   diverged with both versions preserved for explicit private Git merge. A
   remote-only fast-forward is syntax-validated and atomically replaces only
   `~/.ssh/config` at mode 0600. First adoption requires the reviewed current
   config to seed the private payload; no Mac has permanent writer priority.
3. Store private mode-0600 Mac transaction/status evidence sufficient for
   exact rollback to the prior file while unchanged. Validate destination
   parent/type/owner, reject symlinks and hard links, preserve unrelated
   `~/.ssh` contents, and never inspect/copy keys, `known_hosts`, agents, or
   credentials. No automatic package, shell, Git-engine update, or background
   action is implied by config sync.
4. Add a separate Linux adapter callable only as an explicit command on the
   declared `local` profile with destination fixed to `t4`. It validates the
   regular source and SSH grammar locally, requires a current-user-owned agent
   socket and `BatchMode=yes`, stages bytes remotely as mode 0600, validates
   staged grammar on `t4`, preserves exactly one prior mode-0600 image, and
   atomically replaces only `t4:~/.ssh/config` when content differs. It must
   refuse execution on any other source or destination and never pull `t4`
   changes back.
5. Add synthetic tests for first seed, remote-only pull, local-only publish,
   equal no-op, concurrent divergence, invalid syntax, unsafe types/modes,
   injected fetch/push/atomic-replace failures, exact rollback, privacy leaks,
   fixed `local`/`t4` scope, and explicit exclusion of `ab`, `ab2`, `ri`, `al`,
   and `rc`. Run focused suites, `tests/test-phase1.sh`, ShellCheck, diff check,
   and protected `portable-phase1` before pilot mutation.
6. Roll out sequentially: first publish the generic engine/schema; then review
   and seed the current `office` payload privately, run plan/apply/doctor and
   deliberate rollback/reapply; then repeat from an owner-started local session
   on each other Mac. Finally resume from an owner-started `local` Linux session
   for read-only source/`t4` discovery, exact plan, separate apply authority,
   destination validation, deliberate rollback, and accepted reapply.

Stop conditions are config divergence, invalid grammar, unsafe identity/type,
dirty unrelated private state, non-fast-forward Git, unavailable authentication,
unexpected endpoint/scope, changed rollback target, or any output that could
expose private values. Recovery never force-pushes, guesses a winner, copies a
credential, rewrites another Linux node, or falls back to raw deletion.

**SSH-sync implementation checkpoint (2026-07-19):** the isolated
`agent/t268-ssh-sync-engine` worktree now contains the generic engine and no
live/private bytes. The v1 private contract accepts an optional root
`ssh_config` only as the backward-compatible pre-adoption transition; once
seeded, it is the sole shared payload. Strict owner/mode/type/size/link-count,
tracked-blob, credential-marker, `Include`, `Match exec`, canonicalization-off,
and OpenSSH grammar gates are implemented. `harness macos-ssh-sync` covers
explicit seed, equal no-op, local-only normal commit/push, remote-only
fast-forward/apply, same-content convergence, divergence stop, private status,
atomic mode-0600 replacement, exact unchanged rollback, prompt-free Git, and
retry after failed push. `harness ssh-config-mirror` is callable only with the
declared `local` identity and has no target option; it always uses `t4`,
BatchMode, a current-user-owned agent socket, remote mode-0600 staging and
grammar validation, one prior image, atomic replacement, and unchanged-only
rollback. Doctor surfaces report only class/agreement state.

Focused synthetic suites pass for the schema/profile, long-gap updater, Mac
reconciler, and fixed Linux mirror. Covered cases include first seed,
remote-only pull, local-only publish, equal no-op, concurrent divergence,
invalid grammar and external directives, unsafe modes/types/hard links,
fetch/push/offline/agent failures, injected atomic-replace failure, exact
rollback/reapply, privacy sentinels, fixed `local`/`t4`, and exclusion of every
other Linux node. No real SSH endpoint, private companion, Mac config, key,
agent identity, `known_hosts`, package, service, scheduler, or background job
was read or changed. Exact next action: commit the focused implementation,
run the clean-checkout full phase-one/ShellCheck/diff/public-privacy gates,
fetch and integrate current `origin/main`, then publish through the protected
task-PR workflow. Stop before any private seed or live apply.

The generic engine is committed as `172fd01` after a conflict-free rebase onto
published `main` `5b4091b`. A normal clean clone (not the linked implementation
worktree) passed `HARNESS_PORTABLE_CI=1 tests/test-phase1.sh`, including the
new suites, ShellCheck warning/error gate, repository independence, and all
portable regressions. `git diff --check` passed and a full current-history
public audit reported `value_exposed=false`. An initial non-portable full-suite
attempt reached the native MPI smoke and stopped only because this non-login
process has no `mpicc`; no test mutation escaped its guarded fixture and the
protected portable mode deliberately skips that undeclared toolchain. The
normal validation clone and its audit files were removed through guarded
cleanup and verified absent.

PR #40 passed protected Harness CI run `29660884552`, job `88123222816`, in
1m50s and squash-merged as published `main` `d5ebb33` on 2026-07-19 JST. A
guarded fleet plan then found all six remote managed checkouts clean at their
common older ancestor `a7ff2df`; the direct verified-bundle apply
fast-forwarded `ab`, `ab2`, `ri`, `al`, `rc`, and `t4` to `d5ebb33`, and every
transfer artifact was absent afterward. This distributed only the public
harness engine; it did not invoke either SSH-config command or mutate a live
config. The shared `local` checkout was preserved because another session owns
its active contributor branch; its `origin/main` is fetched at `d5ebb33`, but
no branch switch or worktree rewrite was attempted. The temporary fleet clone
was removed by guarded cleanup and verified absent.

Exact next T-268 action: in a new owner-started session on `office`, fetch
published `main`, read this ledger and `docs/ssh-config-sync.md`, confirm the
private companion is clean/current, and run only `harness macos-ssh-sync
--host LOGICAL_ID --seed --plan`. Keep its logical ID and all plan details
private. Obtain separate authority before `--seed --apply`; after apply,
deliberately exercise unchanged-only rollback and accepted reapply before
planning another Mac. Do not start the `local`-to-`t4` command from the login
node or combine it with the Mac stage.

**Shell/tmux sync PIE checkpoint (2026-07-19):** the owner paused that private
seed and requested synchronization of `.bashrc` and `tmux.conf` as well. Safe
repository discovery found two ownership constraints. First, the pilot's
`.bashrc` is already transactionally modified by `harness macos-bash` only to
append a thin public loader while preserving all other bytes, metadata, and
machine-local content. Second, the cross-platform policy already requires
portable tmux configuration to use a sourced fragment with local overrides,
and explicitly forbids replacing complete Linux/HPC `.bashrc` files because
site startup and owner-only state must remain local. No tracked tmux
configuration has yet been implemented. Discovery inspected only public
repository policy and code; it did not inspect a live `.bashrc`, `.tmux.conf`,
private companion, or configuration value.

The provisional execution plan, which is not authorized until the interview
closes and the owner gives a fresh `go`, is:

1. Freeze the target population (personal Macs only, or Macs plus managed
   Linux/HPC nodes) without weakening the existing site-local Bash contract.
2. Freeze representation per payload. Bash keeps its existing thin managed
   loader and synchronizes a private shared fragment without replacing
   `.bashrc`. Tmux synchronizes the complete `~/.tmux.conf` directly; it has no
   loader, second runtime config, or machine-local override file.
3. Freeze convergence granularity: recommended one atomic adopted-config set
   per private revision, with fail-closed three-way/equal-writer handling for
   each payload and no partial live apply. Preserve SSH's published behavior
   and schema-v1 backward compatibility.
4. Extend the strict private companion contract only for explicitly adopted
   payloads. Keep credentials, histories, runtime state, plugins, generated
   files, and observed inventories excluded; never print private bytes, paths,
   hashes, revisions, or diffs in public output or evidence.
5. Reconcile existing ownership transactionally. The managed `.bashrc` loader
   remains the sole writer to `.bashrc`; synchronized Bash bytes are copied to
   a private mode-0600 managed runtime fragment only after validation. The
   complete tmux payload replaces only `~/.tmux.conf` atomically after strict
   collision/metadata checks and preserves its prior image for exact unchanged-
   only rollback. Applying configuration does not automatically re-execute the
   current shell or reload a running tmux server.
6. Add non-executing Bash syntax validation and select a tmux validation route
   that cannot silently execute plugin, shell, network, or include behavior.
   Gate the shared tmux syntax against the oldest declared supported tmux floor
   as part of the already-recorded Core-tool compatibility task.
7. Add synthetic tests for absent/present adoption, local-only publish,
   remote-only catch-up from an old revision, equal no-op, multi-payload atomic
   apply, divergence, invalid syntax, unsafe file identity/metadata, injected
   Git and replacement failures, changed-target rollback refusal, privacy
   leaks, machine-local override preservation, and Linux regression safety.
8. Run focused suites, full portable phase-one validation, ShellCheck, diff and
   public-history privacy audits, then publish through protected CI. Only after
   publication may an owner-started pilot session run value-minimized seed
   plans. Each private apply, rollback/reapply drill, and subsequent Mac rollout
   retains a separate live authority gate.

Owner clarification selected D11 as the four personal Macs only. D12 was first
recorded as thin loaders for both payloads, then explicitly corrected: Bash
keeps the existing thin `.bashrc` loader and private shared fragment, while the
complete `~/.tmux.conf` is synchronized directly with no tmux loader or second
runtime configuration. Linux/HPC configuration is not part of this private
sync. The owner selected D13 as one atomic
adopted-config set per private revision: SSH, Bash, and tmux candidates all
validate before any live replacement, and any invalid or divergent payload
blocks the complete apply rather than leaving partial desired state. The owner
selected D14 so synchronized changes activate only in newly started managed
Bash shells and newly started tmux servers. Reloading a current shell or tmux
server is a separate explicit manual action and never part of catch-up apply.

**Amended decision audit:** D11–D14 are resolved and internally consistent with
D1–D10 and SSH S1–S10. The frozen design is four-Mac-only pull synchronization,
the existing thin `.bashrc` loader plus private Bash fragment, direct complete
`~/.tmux.conf` synchronization with no second runtime config, one atomic
SSH/Bash/tmux desired-state set per private revision, fail-closed validation/
application, exact unchanged-only rollback, and no automatic active-session
reload. A fresh `go` authorizes implementation, synthetic validation,
protected publication, and required clean managed-checkout synchronization of
generic public code. It does not authorize reading or publishing private
configuration, running the `office` seed, mutating a live Mac, reloading active
sessions, or applying a private payload; those remain later owner-started and
separately reviewed authority gates.

**Execution authorization (2026-07-19):** the owner gave the fresh `go` after
the corrected D12 audit. Generic public schema, reconciler, loaders, synthetic
tests, documentation, protected publication, and required clean-checkout
synchronization are authorized. Private companion access, live configuration
inspection or mutation, pilot seed/apply, and active-session reload remain
explicitly excluded.

**Generic bundle implementation checkpoint (2026-07-19):**
`harness macos-config-sync` now treats repository-root `ssh_config`, `bashrc`,
and `tmux.conf` as one engine-2 private bundle. Bash retains the published thin
`.bashrc` loader and reads only the synchronized owner-only fragment in a new
managed interactive shell; tmux has one complete live `~/.tmux.conf` and no
loader or second runtime file. The reconciler supports explicit seed/adopt,
same-content convergence, local publication, remote pull, failed-push retry,
mode normalization, divergence refusal, one three-file/state transaction, and
unchanged-only rollback. It never reloads an active shell or tmux server.

Validation rejects partial/unknown private trees, unsafe metadata, files over
1 MiB, private-key markers, credential-like assignments, invalid Bash, and
invalid tmux. Tmux uses documented `source-file -n` on an isolated disposable
server; synthetic `run-shell` sentinels prove parsing does not execute them.
Injected private replacement, private commit, and third-live-file replacement
failures unwind to clean exact preimages. The frozen engine-1 public baseline
regression passes. A Mac still on engine 1 after bundle publication must first
perform the documented public-only clean Git fast-forward, because the old
coupled updater validates its private target before public handoff; it can then
directly catch up the private checkout with engine 2 without replaying missed
releases.

Committed implementation through `5958af0` passes focused profile, long-gap
update, and bundle reconciliation suites. A normal clean validation clone
passes `HARNESS_PORTABLE_CI=1 tests/test-phase1.sh`, public repository audit,
repository independence, ShellCheck warning level, and `git diff --check`.
No private repository, configuration value, personal Mac, package, active
session, or live destination was read or changed during implementation.

**Generic bundle publication checkpoint (2026-07-19):** protected PR #42
passed required `portable-phase1` run `29663990517`, job `88131245362`, in
2m12s and squash-merged as published `main`
`8b63df2bdaf6ee8ff7db6f100faa78829da9aa8e`. The six remote managed Linux
checkouts were all clean at common ancestor `d5ebb33`; guarded verified-bundle
fleet apply fast-forwarded `ab`, `ab2`, `ri`, `al`, `rc`, and `t4` to the
published target. A complete post-apply plan reported six `KEEP`s and every
transfer artifact absent. The shared local checkout was preserved on another
contributor's clean branch; only its `origin/main` was fetched. No private
companion, personal Mac configuration, package, active session, or live Mac
destination was read or changed. Exact next action is the owner-started pilot
seed plan in the resume checkpoint above. Separately, after the owner renews
the declared AL certificate, rerun guarded fleet-sync plan/apply from
`8b63df2bdaf6ee8ff7db6f100faa78829da9aa8e` to current published `main` for
`al` only; first revalidate that its checkout is still clean and that no
transfer artifact exists.

**Pilot command simplification (published 2026-07-19):** the
owner requested the minimum runnable surface while already in the pilot
checkout. One new interactive command, `harness macos-pilot-plan --host
LOGICAL_ID`, performs the public clean fast-forward and target-engine handoff,
requires private Git clean/current without merging it, opens only `.bashrc` and
the private Bash fragment in isolated Vim for owner curation, validates the
three live candidates without executing them, and runs seed plan only. It has
no apply option. Synthetic coverage proves the fragment is curated, private
Git remains unchanged, and the final authority boundary is explicit. Protected
PR #45 passed required `portable-phase1` run `29665301562`, job `88134632579`,
in 2m4s and squash-merged as published `main`
`1606f2a5311dbf48bcbeb1d54a86e98a1d858a7f`. No private configuration or live
Mac was accessed during implementation or publication.

A plan-only pilot invocation completed owner-guided Bash curation, then stopped
at tmux validation with the bounded `unsafe type` class; no private Git commit,
push, or bundle apply occurred, and no configuration value was recorded
publicly. The generic helper did not yet handle an absent canonical path. It
now creates only an empty regular mode-0600 `~/.tmux.conf` when absent,
preserving default behavior and the one-file D12 contract; it continues to
refuse symlinks and other path types. Focused synthetic coverage exercises
this exact absent-to-empty preparation. Publish the correction before the
pilot fetches and safely reruns the helper.

The published absent-path correction was then exercised on the pilot and
created the intended empty regular mode-0600 canonical file, but the validator
reported `tmux configuration grammar is invalid`. Public-code diagnosis found
that the validator always invokes `source-file -n`; tmux releases differ on
the status of a commandless source file even though an empty startup config is
the deliberate default-behavior payload. The focused correction accepts an
empty file only after all existing identity, mode, size, and prohibited-content
checks, while retaining isolated parse-only validation for every nonempty
payload. Synthetic coverage makes its tmux wrapper reject empty `source-file`
input so this native semantic cannot regress. No live or private configuration
content was inspected. Portable shell syntax, warning-level ShellCheck, a
direct empty-file validator probe, and `git diff --check` pass locally. The
complete focused suite reaches its previously recorded Darwin fixture limit
(`stat -c` is unavailable), so protected Linux CI remains authoritative. Exact
Protected PR #48 passed its final required `portable-phase1` check in run
`29668050198`, job `88141960274`, in 2m14s and squash-merged as published
`main` `9043f38bf14a4b2de7d02206334c765a1c283f39`. The clean local checkout was
fast-forwarded to that merge. Exact next action: publish this final handoff,
synchronize only clean managed harness checkouts through guarded fleet-sync,
then safely rerun `macos-pilot-plan` from the clean pilot; seed apply and
session reload remain unauthorized.

The post-merge guarded fleet-sync plan was attempted from the pilot Mac for
`ab`, `ab2`, `ri`, `rc`, and `t4` from their recorded clean handoff
`ad41fa3fc1601d14bd5526a22bb0b70e7b755b62` to `39c0609`, but stopped on the
first read-only preflight because the private `ab` transport alias is not
available in this local context. No remote checkout or transfer artifact was
queried or changed, and all remote state is unknown rather than absent. Retry
from the managed controller, separately planning AL from its recorded clean
`8b63df2bdaf6ee8ff7db6f100faa78829da9aa8e` baseline after authentication is
available. This fleet blocker does not affect the clean local pilot rerun.

**Pilot bundle acceptance (2026-07-19):** after the empty-tmux portability fix
was published, the owner-started pilot helper completed Bash curation and
reported a valid three-payload seed plan. Under separate explicit authority,
seed apply committed and normal-pushed the private bundle and transactionally
converged all three live destinations. A separately authorized unchanged-only
rollback restored the exact prior live files and absent bundle state; explicit
adopt plan then reported the expected forward action, and accepted reapply
created a new recoverable transaction. Final normal reconciliation reported
`class=current agreement=yes action=none`, and the value-free Mac doctor passed
architecture, Homebrew, Command Line Tools, private profile, public checkout,
all managed links and Bash startup gates, all formula gates, and the three-file
configuration agreement with `failures=0 warnings=0`. Active shell and tmux
sessions were not reloaded. No private configuration value, identity, revision,
transaction identifier, repository detail, credential, or diagnostic entered
public Git. The pilot is accepted. Exact next T-268 action: choose one remaining
Mac privately, start an independent local session there, fetch the current
engine, and run plan-only discovery before requesting its separate apply
authority. Do not batch the remaining Macs.

Protected PR #51 passed required `portable-phase1` run `29668744829`, job
`88143825603`, in 2m8s and squash-merged the value-free pilot checkpoint as
published `main` `01971f1756ee140e32615cb658b932757b1ee90b`. Guarded fleet
preflight then found `ab`, `ab2`, `ri`, `rc`, and `t4` clean at `ca3ace7`, with
no transfer artifact. The first apply client's output ended after its first
preflight; an immediate read-only plan still saw all five old clean heads, so a
retry remained safe. The retried guarded command subsequently found all five
already at the target and performed only `KEEP` actions, showing the first
apply had completed after its client output ended. A final independent plan
reported five `KEEP`s at `01971f1`, zero dirt, and every transfer artifact
absent. `al` was not contacted and remains pending separate authentication
revalidation. The shared local checkout's contributor branch was not changed.

**Bash ordering correction PIE checkpoint (2026-07-19):** the owner clarified
that the intended Mac behavior was the same ordering contract used on managed
Linux startup files: a managed pre-hook, untouched machine-local content in the
middle, and a managed post-hook. The published Mac implementation instead
appends one loader and sources one synchronized private fragment only after all
local `.bashrc` content. This is a confirmed requirement mismatch, not a failed
pilot transaction; the accepted pilot remains internally converged and safe to
leave running, but rollout to another Mac is paused.

Read-only public-code discovery found that the Linux pre hook is the exact
`harness early managed` prefix sourcing tracked `shell/early-cache.sh`, and the
post hook is the exact `harness managed` suffix sourcing tracked
`shell/profile.sh`. Linux preserves the owner/site-local startup bytes between
them. `harness-bash` starts Homebrew Bash as a login shell, while the current
Mac installer instead appends the separate `personal-macos.bash` loader to both
`.bash_profile` and `.bashrc`; private engine 2 also stores one `bashrc`
payload.

The owner rejected provisional B1's two new private pre/post fragments: the
requirement is to reuse the existing public Linux hooks on the Macs, not create
another synchronized Bash representation. The recommended correction is a
Mac-specific transactional installer that places those same public hook blocks
around untouched Mac-local bytes in both `.bashrc` and Bash's selected login
startup file, using the strict private logical ID only in the live prefix. Any
Darwin incompatibility must be fixed in the shared public hook or a narrow
family adapter without changing Linux behavior. The existing private `bashrc`
payload and state then appear obsolete and require an explicit migration rather
than silent coexistence.

**Decision B2:** selected removal of private Bash payload synchronization.
Macs will use the same tracked `shell/early-cache.sh` pre hook and
`shell/profile.sh` post hook as the managed Linux nodes, with untouched
machine-local startup content between the exact managed blocks. The migration
must return any retained pilot-only fragment bytes to owner-reviewed local
content or deliberately classify them as already supplied by the public hooks;
it may not silently discard or publish them.

The owner simultaneously expanded tmux scope from the four Macs to all four
Macs plus `local`, `ab`, `ab2`, `ri`, `al`, `rc`, and `t4`. Public policy
already calls for portable non-secret tmux configuration but no tracked tmux
payload or Linux adapter exists; engine 2 currently stores the complete Mac
`~/.tmux.conf` only in the private companion and explicitly excludes Linux.
This invalidates D11–D13's population and atomic-bundle assumptions. Phase
remains `interviewing`, and rollout stays paused.

**Decision T1:** selected one complete, deliberately non-sensitive
cross-platform tmux configuration tracked in the public harness as the source
of truth for all eleven environments. It will use the oldest supported common
tmux grammar, contain no credentials or machine-private values, provide no
second config or local override, and advance through the existing protected
public-harness and per-machine catch-up workflows. The private Mac `tmux.conf`
payload becomes obsolete and must be removed through an explicit compatible
migration without losing the pilot's accepted prior image.

**Decision T2:** selected one live symlink on every managed environment:
`~/.tmux.conf` points to the complete tracked public canonical file under that
environment's `~/harness` checkout. There is exactly one configuration body,
no sourced loader, copied duplicate, or local override. Editing through the
live path changes the tracked file and normal Git review publishes it. Apply
must refuse ambiguous alternate paths and unsafe existing types, retain an
exact prior image/type for rollback, replace atomically, and never reload a
running tmux server. Open decision T3: select the owner-curated initial
canonical content after value-free path-type discovery; no live content may be
read or copied automatically. No code, private companion, tmux file, active
server, or node state has been changed.

Value-free read-only discovery then classified only the three candidate tmux
paths on `local`, `ab`, `ab2`, `ri`, `al`, `rc`, and `t4`. Every canonical
`~/.tmux.conf`, home-plain `~/tmux.conf`, and XDG
`~/.config/tmux/tmux.conf` path is absent. A second bounded probe confirmed all
six remote classifications after the first probe's newline formatting was
ambiguous; AL authentication was available for this read-only check. No tmux
bytes, hashes, commands, versions, private paths, or active-server state were
read, and no node changed. The accepted pilot Mac has an empty canonical file.
Each remaining Mac must still classify its own paths independently and stop for
owner curation if any existing config is nonempty before linking.

**Decision T3:** the owner supplied the exact public canonical payload. It sets
status-left length 80 and displays the bold persistent session name; `N` and
`P` switch to the next and previous sessions; `Space` opens
`choose-tree -Zw`. The supplied comments and commands contain no machine value,
credential, plugin, shell, network, include, or secondary-file behavior.
Current value-free version discovery found tmux 3.4 on `local` and `ri`, 3.2a
on `ab`, `ab2`, and `t4`, and managed 3.6b on `al` and `rc`. Parse-only
validation on disposable isolated servers passed the exact payload on all
seven Linux nodes, including the 3.2a floor; every candidate file, socket, and
temporary directory was exactly removed. No active server was contacted or
reloaded. T3 is selected subject to the same native parse gate on each Mac
before linking.

**Decision B3:** selected owner-guided side-by-side migration of the accepted
pilot's `.bashrc` and current private Bash fragment in isolated Vim. The owner
moves genuinely Mac-local settings into the local middle, removes only settings
already supplied by the shared public hooks, and leaves the private fragment
empty. Validation must preserve the managed boundaries, reject credentials and
invalid Bash, and prove the fragment empty before the private payload or state
is removed. The engine may not infer, print, or automatically insert private
bytes.

**Decision M1:** selected one recoverable pilot migration. After owner curation
and complete prevalidation, it converts `.bashrc` and Bash's selected login
startup file to the shared public pre/post hooks, replaces the canonical tmux
path with the public symlink, removes the obsolete private Bash/tmux payloads,
and converts local bundle state back to SSH-only agreement. Any live-file or
state failure restores every exact preimage. A normal-pushed private schema
advance is never force-rewound; a post-push local failure remains a bounded
forward retry. Deliberate unchanged-only rollback/reapply is required, and no
active shell or tmux server is reloaded.

**Decision R1:** selected generic implementation and protected publication
first, with no live/private mutation; then an owner-started pilot plan and
separately authorized apply/rollback/reapply; then a `local` Linux tmux
plan/apply/rollback/reapply drill; then one reviewed authority bundle applied
sequentially to the six remote Linux nodes with stop-on-first-failure; then one
independently planned remaining Mac at a time. No apply reloads an active shell
or tmux server.

**Corrective decision audit:** B2/B3, T1–T3, M1, and R1 supersede D11–D13 and
retain D14. They are consistent with D1–D10 and SSH S1–S10: Mac SSH remains the
only private synchronized configuration; Bash and tmux advance through public
harness catch-up; old Macs use a public-first migration bridge; the tmux file
is complete and singular; private bytes never enter public evidence; all live
replacements have exact unchanged-only rollback; and every later machine is
independently validated. Phase is `ready-for-go`. A fresh `go` authorizes the
generic implementation, synthetic validation, protected PR, and required
clean-checkout fleet synchronization only. It does not authorize private
companion access, owner curation, live hook/link mutation, rollback/reapply, or
active-session reload; those remain the explicit R1 gates.

**Execution authorization (2026-07-19):** the owner gave the fresh `go` after
the corrective decision audit. Generic public hooks, canonical tmux config and
link adapter, private-schema/state migration engine, old-Mac bridge, synthetic
tests, documentation, protected publication, and clean-checkout control-plane
synchronization are authorized. Private companion access, live Mac/Linux
configuration mutation, owner curation, and active-session reload remain
excluded. Exact first step: map the published engine-2 and Bash-v1 transaction
contracts, then implement synthetic-first migrations without contacting a live
config.

**Generic implementation checkpoint (2026-07-19):** the task branch now adds
the exact public `config/tmux/tmux.conf`, transactional cross-platform
`tmux-config`, public pre/local/post `macos-bash-hooks`, the owner-curated
forward-only `macos-config-migrate` bridge, migrated/legacy doctor coverage,
the revised pilot planner, documentation, and synthetic apply/rollback tests.
The migration fixture proved engine-2 to SSH-only publication, Bash local-byte
preservation, the one canonical tmux link, exact local rollback, and no private
Git rewind. Focused Mac/tmux/profile/update/privacy suites passed. ShellCheck
passed for every affected script with only the repository-standard dynamic
source/unreferenced-trap suppressions. `HARNESS_PORTABLE_CI=1
tests/test-phase1.sh` passed; the unspecialized invocation reached the native
MPI smoke and stopped because this session has no `mpicc`, so no native MPI
result is claimed. No private companion, live startup file, tmux path, active
session, or remote node was accessed or changed. Exact next action: fetch
`origin`, push the task branch, open the protected PR, wait for required CI,
merge without force, then run guarded clean-checkout fleet synchronization.

**Protected-CI retry checkpoint:** PR #53 opened at
`https://github.com/rioyokotalab/harness/pull/53`. Required run `29670914004`
passed ShellCheck, scheduling, onboarding, evaluation, public-history privacy,
and guarded-delete stages, then failed only because the new synthetic migration
fixture tried to rename a branch in GitHub's detached-HEAD checkout. Commit
`8fbd8f7` makes the fixture create `main` from detached HEAD while preserving
the named-branch path. The migration suite passed both locally and from an
isolated detached clone, and the complete portable phase-one suite passed again.
Retry safety: push the normal fast-forward commit and wait for the replacement
required check; no live or private state was involved.

Replacement run `29671048945` passed the detached-HEAD point and then exposed
the fixture's second ambient dependency: its synthetic private clone had no
local commit identity and had inherited the developer's global Git identity in
local runs. Commit `2c88749` gives only that synthetic repository an explicit
fixture identity. The focused migration test and the complete portable
phase-one suite both pass with `GIT_CONFIG_GLOBAL=/dev/null`, matching the
credential-free runner. Retry remains a normal fast-forward push with no live
or private-state effect.

**Generic publication outcome:** required run `29671188197` passed every stage,
and protected squash PR #53 merged as `4209ee84408a0abf4fccdbeafcac62ad050d4ad0`.
Guarded fleet synchronization advanced `ab`, `ab2`, `ri`, `rc`, and `t4` from
`63af57f`; AL was clean at older ancestor `8b63df2` and advanced directly from
that state. A final six-host plan reported `KEEP` at `4209ee8` for every host
and no transfer artifact. The shared checkout was not changed. No command ran
`macos-pilot-plan`, `macos-config-migrate`, `macos-bash-hooks`, or `tmux-config`
against a live environment, and no active shell/tmux server was reloaded.
The now-authorized exact next action is to run on the pilot Mac
`./bin/harness macos-pilot-plan --host office`; it may fetch/fast-forward the
public checkout and open the two owner files for curation, but it must stop at
the migration plan and must not apply.

**Pilot-plan authority (2026-07-19):** the owner explicitly authorized pilot
curation and migration plan on opaque logical host `office`. This authorizes
only the owner-started local command
`./bin/harness macos-pilot-plan --host office`: value-free public/private
preflight and fetch, a clean public fast-forward if available, isolated Vim
curation of `.bashrc` beside the private Bash fragment, the enforced empty
fragment gate, native parse validation, and `macos-config-migrate --plan`.
Owner edits made deliberately in that Vim session are within this plan-stage
authority. It does not authorize `macos-config-migrate --apply`, any private
commit/push, rollback/reapply, `tmux-config --apply`, Linux rollout, package
changes, or active shell/tmux reload. Exact next action: run the command locally
on `office`, preserve its complete value-free output, and stop after
`END macos_pilot_plan migration_apply=not-requested curation=owner-edited
next=separate-migration-apply-authority` for review.

**Pilot-plan failure handoff (2026-07-19):** the owner ran the authorized
command on `office`. It opened the two curation files, then stopped at the
enforced post-editor gate with this complete value-free result:

```text
PILOT_EDIT move every machine-local Bash setting from the private fragment into .bashrc
PILOT_EDIT remove only settings already supplied by the public pre/post hooks
PILOT_EDIT leave the private fragment empty; do not move credentials
2 files to edit
harness: pilot private Bash fragment is not empty after curation
```

The stop occurred before `macos-config-migrate --plan` and before any migration
apply, tmux link, private commit/push, or active-session reload. Owner edits
made in Vim may persist locally, so a retry must preserve both files and must
not assume their pre-attempt bytes. No private file content or credential was
inspected, printed, copied, or recorded. Retry is safe only at the existing
plan-stage boundary. Exact cold-start action: on `office`, start an agent from
`~/harness`; fetch `main`, read `AGENTS.md` and this T-268 ledger, and diagnose
the empty-fragment failure with value-free metadata and synthetic/public code
inspection. It may correct the planning workflow and rerun
`./bin/harness macos-pilot-plan --host office`, but it must stop at the
migration plan. It must not inspect private values or run
`macos-config-migrate --apply`.

**Tmux-validator publication and T-268 plan outcome (2026-07-19):** with the
owner's narrow package authorization, Homebrew installed `gh` 2.96.0 and its
automatic 30-day cleanup removed superseded formula versions, cached bottles,
and old logs; it reported 54 outdated formulae but upgraded none of them.
Authentication and other package intent were not changed. The now-available
native CLI opened protected PR #71; required `portable-phase1` passed in 2m14s,
and squash merge published the correction as
`1d64949b86f98011936e164d2748c99c8a7d1efb`. The clean pilot checkout
fast-forwarded to that exact `origin/main`. The authorized helper then reopened
the two curation files, confirmed value-free that the private Bash fragment was
empty, and closed without saving or changing either file. Its complete
post-editor result was:

```text
MACOS_CONFIG_MIGRATE class=current private_layout=legacy action=migrate apply=not-requested activation=none
END macos_config_migrate next=separate-apply-authority
END macos_pilot_plan migration_apply=not-requested curation=owner-edited next=separate-migration-apply-authority
```

**T-268 pilot migration apply outcome (2026-07-19):** under fresh owner
authority, the frozen migration apply completed from `class=current` and
`private_layout=legacy`, reported `agreement=yes action=applied`, retained a
private recoverable transaction, and advanced private history forward-only.
Activation is limited to new managed shells and tmux servers. No active shell
or tmux server was reloaded, and no rollback/reapply drill, package action, or
unrelated private/public change ran. The private transaction identifier remains
local and is deliberately omitted from public Git. Exact next owner action is
to observe newly started managed Bash and tmux sessions. Any deliberate
unchanged-only rollback/reapply drill remains a separate authority boundary.

### T-269 — Private cross-platform Codex and Claude configuration

**Phase/status:** `executing`. Mirror deliberately selected Codex and Claude
user configuration across four pull-based Macs and seven managed Linux
environments without copying authentication, credentials, sessions, histories,
memories, caches, databases, client-generated state, private endpoints, or raw
project paths. The public harness owns the reviewed portable settings bodies as
well as the generic link engine, transactions, synthetic tests, and privacy
gates. C1–C7 below freeze the exact safe configuration breadth and rollout.

**Confirmed cause boundary:** on `local`, Codex's mode-0600 user config selects
`never` plus `danger-full-access`, and Claude's mode-0600 settings select
`bypassPermissions`. The harness currently excludes these live files, so those
defaults never reached `office`. Pilot launch/profile/project/system precedence
still requires value-free local confirmation before claiming this is the only
cause. No live client setting changed.

**Plan/next action:** the complete architecture, risks, seven-decision register,
execution order, rollback, and acceptance gates are in
`docs/plans/agent-client-config-fleet.md`. C1 is frozen as zero Codex or Claude
action-approval prompts in ordinary sessions, implemented by global Linux
parity (`never` plus `danger-full-access` for Codex; `bypassPermissions` plus a
suppressed dangerous-mode startup warning for Claude). This does not suppress
authentication, macOS privacy/TCC, OS administrator, or provider-enforced
dialogs. C2 is frozen by the owner as one
tracked public canonical file per client under `harness`, with the live Codex
and Claude settings paths linked directly to those files. There is no private
companion, generated live copy, host overlay, or OS overlay for these settings.
C3 is frozen as the broad portable choice: include every reviewed
cross-platform and publicly safe preference, not only permission
posture, while excluding machine-specific trust, private paths/endpoints,
credential-bearing values, runtime state, and non-portable commands. C4 is
frozen as a tracked Bash launcher that injects the locally resolved current
root as transient Codex trust. No path is stored or published; every project
launched through the ordinary wrapper may load its project-local Codex config,
hooks, and exec policies. C5 is frozen as the broad prompt-free public
declarative choice. Reviewed Claude user-hook code and exact public
plugin/marketplace/MCP identifiers synchronize; credentials and authorization
remain local. Declarations that force interaction and non-managed Codex command
hooks are excluded. Current Claude documentation confirms `bypassPermissions`
retains hard-coded prompts for root/home recursive deletion and
policy/component-forced interaction; the
harness prohibits the former and C5 rejects the latter, but neither setting
can truthfully disable the client circuit breaker. C6 is frozen as review-first
Git: a live-link edit is a tracked worktree edit, dirty checkouts block catch-up,
and only validated protected Git review publishes it. No automatic commit,
push, adopt, or overwrite is allowed. C7 is frozen as the explicit-start
automated order: `office`, then `local` plus the six Linux remotes, then each
remaining Mac. One Mac-local catch-up command and one sequential Linux
controller handle fetch, validation, transactional link/declaration apply,
doctor, and authorized rollback/reapply drills. Offline-Mac startup,
configuration review/publication, authentication/OAuth, OS dialogs, and fresh
interactive-session observation remain manual; no background or login-time
mutation is allowed.

**Final decision audit:** C1–C7 are internally consistent. One public canonical
settings body per client and direct live links coexist with review-first Git:
an edit is preserved as checkout dirt and cannot be overwritten by catch-up.
Transient current-root Codex trust stores no project path, while C5 excludes
non-managed Codex hooks whose global trust bypass would be too broad.
Prompt-free ordinary sessions are compatible with C5 only because declarations
that force interaction are rejected; authentication, macOS privacy/TCC, OS
administrator, provider policy, and Claude's hard-coded destructive-operation
circuit breaker remain truthful external boundaries. C7 automates only
deterministic work inside an owner-started run and does not add background
mutation or automatic publication.

**Execution authorization:** all required design input is collected. The owner
gave the fresh explicit `go` on 2026-07-19, authorizing the generic public
settings bodies, validators, launcher,
transaction/link/declaration engines, Mac catch-up command, Linux controller,
synthetic validation, protected publication, and clean-checkout distribution
of that generic code. It does not authorize reading or adopting existing live
configuration values, changing a live client setting or link, installing,
enabling, or authorizing a plugin/MCP/connector, supplying authentication,
running a live apply/rollback/reapply drill, or reloading an active session.
Those remain the recorded sequential rollout gates. Exact first action: build
the minimal frozen canonical bodies and synthetic-first cross-platform engine
without reading either existing live settings file.

**Generic implementation checkpoint (2026-07-19):** the isolated task branch
now contains the singular public Codex and Claude settings bodies, an empty
strict component declaration, the transient current-root trust launcher, one
three-link transaction with exact regular/symlink preimages, unchanged-only
rollback, value-free inventory/plan/doctor output, direct offline catch-up, and
the sequential Linux controller. The initial bodies contain only the settings
already frozen in C1; no private model/UI value was inspected or inferred.
No hook, plugin, marketplace, or MCP identifier is declared because none has
yet received exact public review, and the empty manifest cannot install or
authorize one. Synthetic tests pass for absent apply, explicit regular/symlink
adoption, idempotence, transient project trust, changed-link and hard-link
refusal, injected partial-link restoration, automated rollback/reapply, direct
old-to-current fast-forward, controller ordering, and stop-on-first-failure.
Focused ShellCheck, Claude takeover, public-repository audit, and diff checks
pass. Commit `6f87600` records the implementation. From that clean task
checkout, `HARNESS_PORTABLE_CI=1 tests/test-phase1.sh` passed the complete
portable suite, including all existing macOS, Linux/HPC, safety, privacy,
ShellCheck, and new agent-config regressions. No live settings, link, client
session, authentication, component, or remote node was read or changed. Exact
next action: publish the clean task branch through a protected PR, require
`portable-phase1`, merge without force, and guarded-fast-forward only clean
managed checkouts. Stop before every live adoption or rollout gate.

**Generic publication outcome (2026-07-19):** protected PR #67 passed required
`portable-phase1` run `29677428042`, job `88167332036`, in 2m12s and
squash-merged as published `main`
`6a7e177d05742fbbde054a1af94e2c85810e3790`. Guarded fleet preflight found
`ab`, `ab2`, `ri`, `al`, `rc`, and `t4` clean at `af6f1bd`; verified-bundle
apply fast-forwarded all six to the published target, and the independent final
plan reported six `KEEP` results with every transfer artifact absent. Only
generic public code moved. No command invoked `agent-config`,
`agent-config-catch-up`, or `agent-config-fleet` against a live target; no live
settings, launcher, component, authentication, session, or private value
changed. Exact next action: start from the independently owner-controlled
`office` session, fetch current public `main`, and obtain plan-only authority
before running `./bin/harness agent-config-catch-up --adopt --plan`. That plan
may classify path types and fetch/fast-forward the clean checkout but must not
read settings bytes or apply links. Apply/rollback/reapply remains a later
separate gate.

**Coordinated Mac catch-up correction checkpoint (2026-07-19):** public-code
diagnosis confirmed that `agent-config-catch-up` fetched and fast-forwarded the
public harness directly, bypassing T-268's private-companion compatibility and
migration-state gates. The minimal correction keeps explicit pull-based
long-offline catch-up but, on Darwin, requires the opaque logical host, fetches
both clean fast-forward-only targets, and delegates checkout convergence to
`macos-update` before invoking the target agent-config engine. Linux behavior
is unchanged. The focused route-only synthetic test proves plan mode does not
advance the public checkout and delegates both targets; `sh -n`, warning-level
ShellCheck, and `git diff --check` pass. The full portable phase-one attempt on
the pilot Mac stopped in an existing GNU-utility-dependent startup fixture on
BSD `stat`/`realpath`, so protected Linux CI remains the authoritative full
gate. No private value or live configuration was read, inferred, or changed.
Exact next action: publish through protected CI, cleanly fast-forward `office`,
complete T-268's migration plan, then run only
`./bin/harness agent-config-catch-up --host office --adopt --plan`.

**Coordinated correction publication outcome (2026-07-19):** protected PR #69
passed required `portable-phase1` run `29681519104`, job `88178401414`, in
2m20s and squash-merged as published `main`
`339badc64d701e3ae241cd547ae69bbd582bfeed`. Guarded fleet synchronization
advanced `ab`, `ab2`, `ri`, `al`, `rc`, and `t4` from `b3a128a`; an independent
final plan returned six `KEEP` results at `339badc6` with every transfer
artifact absent. The shared checkout stayed on its unrelated clean branch.
Only generic public code moved: no command invoked either pilot plan or any
live agent-config, migration, tmux, private-companion, package,
authentication, rollback/reapply, or session action. Exact next action is on
`office`: cleanly catch up `main`, run `./bin/harness macos-pilot-plan --host
office` and stop after its migration plan, then run only
`./bin/harness agent-config-catch-up --host office --adopt --plan`. Neither
apply is authorized.

**Pilot adoption plan outcome (2026-07-19):** only after T-268 reached its
migration-plan boundary, the corrected Darwin route ran
`./bin/harness agent-config-catch-up --host office --adopt --plan` and exited
zero with this complete value-free result:

```text
NATIVE git fetch --no-tags origin main
NATIVE git fetch --no-tags origin main (private companion)
MAC_AGENT_CONFIG_ROUTE public=none private=none compatibility=required migration=required
MACOS_UPDATE mode=plan public=current private=current
COMPAT engine_schema=2 private_schema=1
MIGRATION state=initialize from=local-or-absent to=1
END macos_update changes=not-applied fetch=explicit-separate-step
AGENT_CONFIG_CATCH_UP mode=plan checkout=none target=current adopt=yes drill=no
AGENT_CONFIG_PATH client=codex state=regular action=adopt
AGENT_CONFIG_PATH client=claude state=regular action=adopt
AGENT_CONFIG_PATH client=launcher state=symlink action=adopt
AGENT_COMPONENTS declarations=0 action=none authorization=local
AGENT_CONFIG mode=plan adopt=yes blocked=0 changes=3 activation=new-sessions
END agent_config apply=not-requested
END agent_config_catch_up changes=not-applied
```

**T-269 pilot adoption apply outcome (2026-07-19):** after the successful
T-268 migration apply, the owner ran the frozen Darwin catch-up apply. The
coordinated `macos-update` route reported both checkouts current, compatible
engine/private schemas, a complete local migration-state initialization, and
`changes=applied package_actions=none`. Agent-config adopted the two regular
client settings paths and existing launcher symlink as one complete recoverable
transaction, then its immediate doctor reported all three paths current and
`status=ready failures=0`. Component declarations remained zero and local
authorization was untouched. Activation is limited to new sessions. No setting
value, credential, component authorization, package, active-session reload, or
rollback/reapply drill entered public evidence or changed outside the bounded
apply. Private transaction identifiers remain local and are deliberately
omitted from public Git. Exact next owner action is to start fresh Codex and
Claude sessions on `office` and confirm the frozen ordinary-session behavior;
any rollback/reapply drill or rollout beyond `office` requires its separately
recorded authority.

**Fresh-session verification checkpoint (2026-07-19):** the owner authorized
the non-mutating `office` verification. The previously dirty canonical Codex
body was deliberately restored to its published two-setting form. Fresh Bash
and an isolated fresh tmux server/session passed, but the value-free agent
doctor found only the launcher as a different symlink. The reviewed one-change
adoption plan was authorized; apply stopped before mutation with `agent
configuration changed before apply`. Public-code diagnosis confirmed a partial-
adoption defect: transaction preparation rejected paths already classified
`current`, and the link loop would have rewritten all three paths. The focused
correction records current paths as no-op preimages, revalidates every recorded
state immediately before linking, and changes/restores only drifted paths. Its
new partial-adopt/doctor/rollback/reapply regression passed before the existing
macOS focused suite reached its known GNU `stat -c` fixture failure; portable
syntax, warning-level ShellCheck, and diff checks pass. No live path changed
during the failed apply. Exact next action: publish the correction through
protected Linux CI, cleanly fast-forward `office`, rerun the already-authorized
one-change adoption and doctor, then observe fresh Codex and Claude sessions.
Stop before any drill or rollout beyond `office`.

**Protected fix and fresh-client outcome (2026-07-19):** PR #79 passed required
`portable-phase1` in 2m22s and squash-merged the partial-adoption correction as
`18aca73`. Clean `office` fast-forwarded to that target; the authorized one-
change launcher adoption and immediate doctor then passed with all three paths
current. Fresh Claude returned the fixed readiness response without an approval
dialog. Fresh Codex instead stopped at launcher resolution because the adopted
path had been the pilot's only native Codex command; the transaction's exact
unchanged-only rollback restored that prior symlink while leaving both current
settings links unchanged. The restored fresh Codex command completed without
an approval prompt but reported `approval: never` with `sandbox: read-only`,
not the frozen `danger-full-access`. No reapply drill or broader rollout ran.
Exact next action: revise C4 for a Mac whose sole native Codex entry occupies
the desired managed launcher path, and diagnose value-free configuration
precedence before another apply. Do not adopt the launcher again or claim pilot
acceptance until a protected correction preserves a separately callable native
binary and fresh Codex reports both frozen values.

**Revised C4 planning checkpoint (2026-07-19):** current official Codex
guidance confirms that the standalone installer's visible command defaults to
`~/.local/bin/codex`, while its package cache remains under `CODEX_HOME`; the
frozen managed launcher therefore collided with the supported native install
surface on this pilot. Official precedence places CLI flags above project,
profile, user, system, and built-in configuration, subject to managed
requirements. Value-free probes found no project/system config or local system
requirements, and an explicit `--sandbox danger-full-access` fresh run passed,
so full access is allowed; implicit fresh runs nevertheless reported changing
read-only/workspace-write modes and cannot satisfy C1. Phase returns to
`interviewing` for one revised C4 decision. Recommended D11 is to relocate the
visible native standalone command to a separate documented install directory,
then let the reviewed launcher own `~/.local/bin/codex` and pass the frozen
approval/sandbox settings explicitly alongside transient trust. This adds one
separately authorized official installer/package action but keeps `codex` as
the ordinary command and avoids a private cached-target dependency. Alternative
D11 is to leave native `codex` untouched and expose only a separately named
managed wrapper, weakening C4 because ordinary `codex` invocations can bypass
transient trust and frozen flags. No implementation or live action is
authorized until D11 is selected, the exact installer command/rollback is
planned, and a fresh `go` follows.

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
| T-191 | Seven scheduler-native first weekly snapshots, successor continuity, private-state consistency, and warning silence passed; evidence is in `docs/audits/restic-first-weekly-2026-07-19.md`. |
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
| T-270 | Post-pilot repository housekeeping compacted superseded T-268/T-269 handoffs while preserving final applies and active authority boundaries; protected PR #74 passed `portable-phase1` and merged as `4e3f4ed`. One clean worktree, no open PRs, and no merged task branches remained; Homebrew, private transactions, live settings/sessions, and rollout state were untouched. |
| T-271 | Corrected the stale post-pilot resume checkpoint, added manifest-compatible native macOS guarded-delete adapters with synthetic Darwin and protected Linux validation, and guardedly removed the sole known stage-14 temporary tree (239 entries, 53,144,497 bytes) with protected anchors unchanged; implementation PR #76 merged as `2e278a6`, outcome PR #77 as `0c1c3d2`. Packages, fleet/live configuration, drills, and sessions were unchanged. |
