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
`go` on 2026-07-18. Continue stage 10 from the exact next action in
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

**Execution checkpoint:** stages 1–9 are complete. The frozen D1–D10 record is
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

**Next:** implement stage 10 stable Homebrew Bash launcher and
collision-refusing thin Bash integration with native-shell recovery,
idempotence, and exact file rollback. Keep live Mac access gated on
privacy-negative validation. Go does not itself authorize
credentials/authentication changes, GitHub creation or publication, Homebrew
installation/upgrades, package cleanup, background automation, or destructive
actions.

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
