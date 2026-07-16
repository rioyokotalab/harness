# Personal harness task board

This board is the authoritative current state for the portable Codex and Claude
harness. Git preserves superseded chronology and command-level evidence. Keep
live tasks, verified recovery facts, blockers, and next actions here; do not
rebuild a second incident transcript in a session or report file. Next free id:
T-191.

## Recovery priority — do before any other task

- **T-172 — Exhaustively re-audit Git history for additional recovery
  candidates (complete 2026-07-15):** traversed both complete local commit
  graphs, refs, reflogs, read-only unreachable-object reports, historical task
  paths, pre-/post-incident trees, and durable non-secret recovery evidence.
  The audit made no restoration, publication, package, owner-config, or fleet
  change.

  **Object and tree findings**

  - Harness `5f6382b` has 79 paths (63 regular, 15 executable, one symlink);
    current has 83 (65 regular, 17 executable, the same symlink). Every delta
    is explained by post-incident commits: the Node version fix, recovery
    ledgers, and guarded-delete implementation. `git fsck` found no unreachable
    commit or tree, only four blobs. Content-free similarity and exact safe
    markers map them to intermediate versions of `docs/recovery-session.md`
    (`d1a0d80`, 8 additions/5 deletions), guarded-delete script
    (`1ed2ca0`, 33/15), guarded-delete tests (`ac341fa`, 17/5), and the old
    `TODO.md` (`e15cce3`, 6/2). All are superseded post-incident work, not the
    lost pre-incident ShellCheck implementation.
  - Website `628b53a` and current each contain 275 paths with identical mode
    counts (257 regular, 18 executable; no symlink or submodule). The eight
    damaged paths are byte-, object-, and mode-identical to `628b53a`. Only six
    ledger files changed afterward. The 12 unreachable commits, 128 trees, and
    218 blobs all predate the incident: named trees cover 216 blobs and encode
    superseded July 12 evaluation variants or the July 14 ResearchMap
    autostash; the two anonymous blobs are explicitly identified by safe header
    fields as in-progress T-29 and T-30 `session.md` variants. None is a
    recovery candidate.
  - The ignored T-11 permission payload is absent from current ignored paths,
    reachable objects, and all unreachable tree names. Its applied outcome is
    recoverable from commits `b73c2c5`, `f92abf3`, `31b5b5b`, and `194fc04`,
    but the payload itself is confirmed missing from available local evidence.
    Surviving ignored T-170 reports and proposals are pre-incident evidence,
    deploy-excluded, and superseded by the current harness; preserve them.
  - No Git bundle remains under either checkout. The restored harness bundle's
    recorded SHA-256 and source revision remain in committed evidence, as do
    the clean-clone validations and remote rollout bundle hashes. Both current
    repositories pass read-only object checks.

  **Recovery candidate table**

  | Original path/state | Source and purpose | Current classification | Confidence / sensitivity | Dependencies | Validation and rollback |
  | --- | --- | --- | --- | --- | --- |
  | `~/harness/**` | bundle SHA-256 `cbb4a1…f59bb4`, commit `5f6382b`; portable non-secret harness | Already recovered; all later deltas are committed and explained | High; allowlisted repository only | None | `git fsck`, 79-path tree/mode baseline, post-incident commit reconciliation; revert only an individually reviewed commit |
  | Eight damaged website paths | website `628b53a`; public site/CV/build files | Already recovered exactly | High; tracked website data only | None | object/hash/mode equality against `628b53a`; rollback source is the same commit, so no action |
  | Agent discovery/control-plane links | harness history plus transaction `20260714T202625Z-3548153`; client discovery | Already recovered: current plan has 28 `KEEP` links and doctor has zero failures | High; live settings/auth contents excluded | Retain owner config and surviving Claude state | `harness apply --host local --plan`, doctor, fresh-client discovery; transaction rollback is available but must not be run merely to retest recovery |
  | T-11 permission proposal | no surviving payload object; commits through `194fc04` record intent/outcome | Payload confirmed missing, outcome superseded by T-179/current harness | High for absence; owner settings remain value-private | None | validate only recorded policy/discovery status; rollback current config only through a separate exact owner-config plan |
  | Harness four anonymous blobs | `d1a0d80`, `1ed2ca0`, `ac341fa`, `e15cce3` | Intentionally retired intermediate post-incident snapshots | High; no secret content printed | None | safe marker/similarity mapping above; do not restore, and let normal Git maintenance retire them |
  | Website unreachable graph and two anonymous session blobs | July 12 evaluation branches, July 14 autostash, T-29/T-30 checkpoints | Intentionally retired/superseded; accepted public changes are already in reachable history | High; repository paths only | None | commit dates, subjects, named-tree coverage, current-tree comparison; do not restore or publish |
  | Lost uncommitted ShellCheck transaction work | no bundle commit, tree, named blob, ignored artifact, or safe anonymous-object match | Confirmed unavailable in local evidence; reconstruct from reviewed intent as new work | High for local absence; no credentials involved | T-173 and T-174 | new implementation must freeze a source/checksum, pass isolated apply/tamper/rollback tests, then a full suite with safe cleanup; rollback the new commit if rejected |
  | Selected current-node user tools | committed checksum manifests; pre-incident versions in `5f6382b` ledger | Recovered: every selected tool is present; Node/npm are 24.16.0/11.13.0 | High; tool binaries only, never client state/config | None | exact transaction IDs and validation are recorded under T-171; rollback one transaction only if its owned path fails |
  | `.profile`, `.bash_profile`, `.bash_logout`, `~/sshservice-cli`, unknown former home paths | no authoritative local source | Unresolved/absent; do not fabricate | High for named absence, unknown completeness; potentially sensitive owner state | Owner-supplied authoritative source only | presence/mode checks only; no validation or rollback is possible without a source |
  | Owner `.bashrc`, SSH config, and agent socket | owner reconstruction and T-171 ledger | `.bashrc` intentional new file; SSH config intentionally final at 10 aliases; socket ephemeral | Owner-confirmed; contents/key material excluded | Owner maintains authentication and socket lifetime | status/parse and owner no-op evidence only; never replace from Git or copy key/session state |
  | Six remote harness checkouts | last committed fleet evidence through `963ad1f`; local `5f6382b` CUDA delta | Recovered and synchronized through the T-170 rollout | High; value-free remote facts only | None | exact clean revisions, native no-op inventory/plan/doctor, and per-host ShellCheck validation; rollback evidence remains under T-170 |

  **Executed post-audit order:** restored no Git object and preserved the
  pre-incident reports; removed raw recursive test cleanup (T-174), rebuilt and
  validated ShellCheck (T-173), reconciled every host read-only, recovered the
  selected current-node tools one transaction at a time, resolved lftp through
  T-175, and then completed the clean fleet rollout. Owner profiles,
  authentication, client state, and unknown home paths remained untouched.

## Active / recovery state

- **T-171 — Recover the current-node home after accidental deletion (complete
  2026-07-15):**

  **Incident and containment**

  - At approximately 2026-07-15 01:41 JST, an agent-issued temporary-`HOME`
    workflow let a command-scoped assignment expire before cleanup, launching
    `rm -rf /home/rioyokota`. This was an agent error, not a harness
    transaction. Cancellation initially left the child alive; PIDs `1786591`
    and `1786291` were terminated, and repeated process audits found no
    remaining matching deletion process.
  - `/home` is NFS. The only visible `.zfs/snapshot` entry was an empty
    `initial` snapshot dated 2025-10-20; the surviving `.sync_get.sh` was only a
    small caller-driven fetch helper. No usable local whole-home backup was
    found. Credentials and secret-bearing state were never inspected.

  **Verified recovery**

  - Restored `~/harness` from the previously verified bundle with SHA-256
    `cbb4a138f53323181c51174b9e68acfca57f3c2f14038dbd7f21829bedf59bb4`
    at pre-incident commit `5f6382b`. Later recovery and safety commits are in
    normal Git history; current local guardrails are commit `238f022`.
  - Restored the surviving `~/website` checkout at `628b53a` by replacing only
    the eight tracked paths damaged by the still-running deletion:
    `README.md`, `cv/build-cv.sh`, `cv/cv.cls`, `cv/cv.pdf`, `cv/cv.tex`,
    `package.json`, `publish.sh`, and `style.css`. Object/worktree checks passed.
  - Website T-179 reconstructed the layered non-secret agent configuration from
    T-11 and website T-170–T-173 history. The owner Codex config again provides
    `never`/`danger-full-access` and trusted home/website entries while
    preserving current model settings. Harness transaction
    `20260714T202625Z-3548153` recreated 17 command/guidance/rule/skill links
    and retained eight surviving Claude links; repeated plan/doctor and fresh
    Codex discovery checks passed.
  - The owner intentionally created the current `.bashrc`; do not treat it as a
    recovered copy of the deleted file. The reconstructed mode-0600 SSH config
    has 10 final aliases: `abci_login`, `ab`, `ab2`, `ri`, `alps_login`, `al`,
    `rc`, `t4`, `web`, and `github`. The owner confirmed `si` could not be
    recovered and intentionally removed it. All 10 declarations parse; no
    literal `TODO` remains. Owner-side strict no-op checks for `ab` and `ab2`
    passed from the renewed-agent shell.
  - Restored `.ssh/agent.sock` only as a machine-local symlink to the live
    renewed agent. It contains no key material, must never be committed, and
    must be refreshed after that agent or node exits.
  - Commit `68fb820` made Node/npm recovery planning fail closed on version
    mismatch. Commit `238f022` added the first autonomous bulk-deletion safety
    layer: global guidance, Codex `forbidden` rules for common raw recursive
    `rm`, the manifest-bound `harness guarded-delete` workflow, adversarial
    tests, and Codex/Claude/shared-agent discovery. T-174 and T-176 later routed
    test and internal transaction tree cleanup through the same revalidated
    workflow. Skill, policy, focused, full-suite, and fresh-client checks pass;
    T-173 restored ShellCheck 0.11.0 and T-177 made its warning gate durable.

  **Unresolved or intentionally not reconstructed**

  - The first audit found `.profile`, `.bash_profile`, `.bash_logout`, much of
    the former user-local tool/runtime state, `~/sshservice-cli`, and unknown
    top-level home paths missing. Later owner and harness reconstruction changed
    part of that inventory. T-172 resolved every Git-backed candidate; do not
    fabricate owner profiles or infer that an absent path should exist. The
    first website validation found no normal-PATH lftp and stopped without
    network or deployment; T-175 later restored it through a pinned local-only
    transaction and reran the deployment-policy tests successfully.
  - The uncommitted ShellCheck transaction bytes after `5f6382b` were confirmed
    absent by T-172. T-173 reconstructed new checksum-pinned work at `2222fc5`.
    Local transaction `20260714T223339Z-461104` passed apply, lint, doctor,
    idempotence, deliberate rollback, and absence checks; final transaction
    `20260714T223421Z-468645` reapplied ShellCheck 0.11.0 successfully.
  - T-175 transaction `20260714T230032Z-752754` restored local-only lftp.
    Transactions `20260714T231117Z-824985` (Git LFS),
    `20260714T231119Z-825786` (uv), `20260714T231121Z-827283` (Claude),
    `20260714T231126Z-829076` (rclone), `20260714T231330Z-845175`
    (Tectonic), and `20260714T231332Z-824975` (Node/npm) restored every
    remaining selected current-node tool. Exact version commands pass; the
    aggregate plan is entirely `KEEP`, and doctor has zero failures with only
    the intentional login-node Docker/Podman warnings. Git LFS hooks, rclone/
    agent state, credentials, and owner profiles were not read or changed.
  - Product-managed policy may override local Codex defaults on some surfaces;
    the verified fresh host CLI honored the recovered values. The surviving
    website pre-commit hook was left unchanged because agents do not edit
    `.git`; its old Claude-size branch is inert under the current tracked tree.

  **Completion boundary:** no authoritative source exists for the intentionally
  untouched former profiles, `~/sshservice-cli`, or unknown home paths; do not
  fabricate them. Current selected-tool and agent-control-plane recovery is
  complete. T-170 owns only the clean-revision fleet parity rollout.

- **T-170 — Mirror the working environment across configured clusters
  (complete 2026-07-15):**

  - In-scope environments are the current node plus `ab`, `ab2`, `ri`, `al`,
    `rc`, and `t4`. `abci_login` and `alps_login` are transport-only;
    `github` and SFTP-only `web` are services, not environments. `si` is no
    longer configured and is not a target. The retired `ai4s` target was
    replaced by `ri`.
  - The capability-driven design and safety boundaries live in
    `docs/environment-portability.md`. The harness provides value-free
    inventory/plan/doctor; transactional control-plane, shell, tool, runtime,
    Python, agent, source-build, and rollback paths; logical host profiles;
    checksum-pinned artifacts; exact state; and native HPC smoke/skill routes.
    It never distributes credentials or copies live client state.
  - Stable completed capabilities include managed Bash blocks, portable Git
    policy, uv/Python 3.12, Node 24/npm 11, Codex/Claude commands, rclone,
    Tectonic, Git LFS, Ninja, SQLite, Tree on `t4`, shared skills, container and
    debugger/profiler facts, deterministic C/C++20/MPI/CUDA/Python smoke gates,
    and exact rollback pilots. Git history retains transaction IDs, bundle
    hashes, per-host warning counts, native commands, and failure evidence.
  - Intentional site/project boundaries remain: lftp and some htop/tmux gaps,
    `rc` sanitizer-runtime limitations, project-owned PyTorch/CUDA images, and
    allocation-only multi-rank/GPU evidence. Do not install private dependency
    stacks merely to erase a warning.
  - Bundle SHA-256 `74cbfca8…8d21a` fast-forwarded all six clean checkouts from
    exact `5f6382b` to `2752ad0`; local and remote bundle copies and temporary
    fact/plan/doctor files were individually unlinked and verified absent. The
    ABCI profiles now discover all three PBS commands directly. ShellCheck
    transactions are `ab=20260714T231752Z-286846`,
    `ab2=20260714T231842Z-1765345`, `ri=20260714T231847Z-1138251`,
    `al=20260714T231914Z-89535`, `rc=20260714T231922Z-3392644`, and
    `t4=20260714T231932Z-719422`. Both architectures report 0.11.0; every
    ShellCheck plan is `KEEP`, every checkout is clean at the target, remote
    lftp selection is absent, and every doctor has zero failures. Remaining
    warnings are the recorded intentional htop/tmux/container gaps. No job,
    allocation, project environment, credential, client state, or external
    repository changed.

## Next task insertion point

- **T-189 — Create a ledger-backed plan–interview–execute skill (complete
  2026-07-16):** promoted the owner's repeatedly successful PIE working model
  into `shared/skills/plan-interview-execute`. It requires a thorough
  evidence-based on-disk plan, one-decision-at-a-time interview with every
  answer immediately checkpointed, an explicit owner `go`, and thorough
  stepwise execution reconstructed from the ledger rather than chat. Resume,
  drift, failure, authority, validation, completion, and handoff behavior are
  explicit. The standard skill initializer was not executable directly and
  failed with exit 126 before creating anything; invoking that same initializer
  with Python was safe and succeeded. The skill has no unnecessary resources,
  passes `quick_validate.py` and diff checks, and its exact shared directory is
  discoverable through Codex, Claude, and `.agents` links. T-190 is its first
  live forward use; no subagent was used or permitted. The first complete
  phase-1 run passed guarded-delete tests and then stopped because the loaded
  OpenMPI module's stale process-local table exposed no `mpicc`. Unloading and
  reloading the same declared `openmpi/5.0-cuda-12.8` module restored its
  native compiler path; the retry passed the full suite with only the already
  documented login-node CUDA-library warnings.

- **T-190 — Automate onboarding a newly configured SSH node (PIE phase:
  ready-for-go, 2026-07-16):** create a reusable personal skill that starts
  after the owner adds a node to SSH configuration, performs a value-redacted
  read-only inventory, resolves only material site-specific decisions through
  PIE, and, after `go`, transactionally reaches the established fleet baseline.

  **Outcome and scope:** accept one owner-supplied SSH alias and a validated
  logical host ID; add the node's capability/site declarations and test
  fixture; bootstrap a clean committed harness revision; install the portable
  tools and 28 managed control-plane links; integrate shell, Vim, tmux, Git,
  and shared SSH fragments while preserving owner prefixes/local overrides;
  classify top-level hidden state from names and aggregate metadata only;
  configure approved persistent/cache roots; and complete manual encrypted
  snapshot, all-pack check, restore verification, and an immutable independent
  generation before any reviewed clean-slate deletion or scheduling proposal.
  The skill must work for a new site as well as another host at a known site.

  **Non-goals and authority:** never read `~/.ssh` or credential contents,
  copy/generate private keys or backup passwords, automate login UI, install as
  root, modify site runtimes/drivers/schedulers, clone projects/data, run jobs,
  delete unreviewed paths, weaken guardrails, publish/push, enable scheduling,
  or alter unrelated owner settings. Resolve the supplied alias through normal
  native SSH behavior without parsing its configuration. External actions stay
  separately gated even after PIE `go`.

  **Confirmed baseline:** a host currently requires a strict
  `profiles/hosts/HOST.conf`, rows in `profiles/home-layout.tsv` and
  `profiles/restic-repositories.tsv`, host shell blocks and an environment
  adapter, a sanitized inventory fixture, remote-Codex allowlisting, and test
  expectations that currently enumerate seven logical hosts. `harness
  inventory/plan/apply/doctor/rollback`, checksum-pinned tool transactions,
  dotfile transactions, guarded deletion, Restic routing, replica
  fingerprint/promotion, Git-bundle transport, interactive exit/Ctrl-D policy,
  and client skill discovery already exist and should be composed rather than
  reimplemented. Current source is intentionally dirty only for T-189/T-190
  and the cross-repository ledger checkpoint; execution must start from a clean
  committed baseline.

  **Frozen implementation plan after interview:**

  1. Scaffold `shared/skills/onboard-mirrored-node` with the standard skill
     initializer, concise procedural instructions, deterministic scripts only
     where repeated parsing/scaffolding would otherwise be error-prone, and
     matching UI metadata.
  2. Define a strict invocation contract for the supplied alias and logical
     ID. Reject empty, option-like, malformed, reserved local, proxy/transport,
     service, and already-managed IDs; never enumerate SSH configuration.
  3. Add a read-only preflight that uses recognizable native SSH commands,
     verifies reachability and POSIX-shell/Git/Python bootstrap floors, records
     lexical/canonical home identity, OS/architecture, scheduler/module/uenv/
     container/tool capabilities, quota/mount facts, and top-level hidden-path
     names plus aggregate sizes without reading contents or environment values.
     Keep potentially private raw output in an unread mode-0600 temporary log
     and retain only an allowlisted sanitized inventory.
  4. Make the skill run PIE for each node. Reuse known policy automatically;
     ask one question at a time only for root selection, unknown hidden-path
     treatment, replica placement, unsupported tool choices, and any new
     authority. Checkpoint each answer before continuing.
  5. Generate a complete proposed host change set in a disposable worktree or
     narrowly scoped staging area: capability profile, sanitized fixture,
     home/backup rows, shell/environment adapters, dynamic fleet membership,
     documentation pointer, and tests. Refuse duplicate rows or unmanaged
     collisions.
  6. Refactor hard-coded fleet allowlists/expected-host tests to derive safe
     managed IDs from strict profile declarations where doing so preserves
     exclusions; keep transport and service aliases impossible to target.
  7. Run syntax, lint, schema, fixture, plan, adversarial alias, secret-output,
     transaction, guarded-delete, and complete phase-1 tests locally. Inspect
     the exact diff and commit only the intended harness files; do not push.
  8. Revalidate host reachability and source identity. Bootstrap with a
     credential-free Git bundle over the existing SSH route when origin fetch
     is unavailable; never rsync a dirty tree or copy authentication state.
  9. Run remote inventory and plan first. Apply only managed user-space paths
     transactionally, validate each stage, and use the recorded rollback route
     on failure before advancing.
  10. Create and validate the chosen persistent/cache roots, then migrate only
      explicitly classified high-growth state. Preserve independent copies
      before activation and use guarded-delete manifests for every tree
      removal; retain node-local histories separately.
  11. Validate all 28 links, managed markers, owner-prefix preservation,
      canonical Vim parity, shell syntax, real interactive/non-interactive PTY
      behavior, exit/Ctrl-D policy, Restic resolution, doctor, idempotence,
      clean checkout, and absence of transient artifacts.
  12. Pause for the owner-only creation/retention of a unique mode-0600 Restic
      password when needed. Agents may validate only path/type/mode and pass it
      by path; they never inspect, hash, print, copy, or generate it.
  13. Run the reviewed hidden-home snapshot, `check --read-data`, verified
      restore to suitable scratch, guarded cleanup, independent encrypted
      generation at a different site, fingerprint comparison, and a fresh
      generation check/restore. Record aggregate metadata only.
  14. Re-run fleet parity without serializing independent nodes unnecessarily,
      update the durable node/site references and ledgers, remove exact
      temporary bundle/helper/log paths, and commit the final local evidence.
      Leave backup scheduling proposal-only until repeated manual restores are
      stable.

  **Safety, recovery, and acceptance:** fail closed on host ambiguity, dirty
  source, profile/schema conflict, lexical/canonical home drift, quota
  uncertainty, symlink or filesystem-boundary surprises, unsupported artifact,
  missing backup credential, live repository lock, source drift, or any
  validation mismatch. Preserve raw failures privately and state whether retry
  is safe. Acceptance requires clean committed source, exact declared profile
  and sanitized fixture, full local tests, successful remote plan/apply/doctor
  and rollback evidence, interactive/non-interactive shell proofs, exact
  managed-link and configuration parity with documented host-local exceptions,
  stable relocated-state activation, and independently restored encrypted
  backup. An interruption resumes from the first unverified ledger step.

  **Decision register:** D1 is resolved by the owner: invoke the skill
  explicitly as `onboard HOST` after the owner adds that alias to SSH
  configuration. The skill must neither read nor enumerate SSH configuration;
  the supplied alias is the complete discovery boundary. This freezes plan
  steps 2–3 around strict alias validation and normal native SSH resolution.
  D2 is resolved by the owner: retain one owner-only Restic password
  checkpoint. The owner creates a unique mode-0600 password file and retains
  the value in the external password manager; the workflow may validate only
  path, regular-file type, non-symlink status, ownership, and mode, and pass
  that path to Restic without inspecting, hashing, printing, copying, or
  generating the credential. After this checkpoint, execution resumes
  automatically at plan step 13. D3 is resolved by the owner: first-run
  onboarding must reach full parity, including portable control-plane setup,
  suitable storage roots, explicitly approved hidden-state migration, and
  independently restored encrypted backup. Scheduling and any unreviewed
  deletion remain excluded rather than being implied by full parity.
  All later root, path, and replica decisions are per-node questions asked only
  after sanitized inventory exists.

  **Interview audit:** D1–D3 are complete and mutually consistent. The frozen
  plan preserves the explicit-alias boundary, the owner-only credential step,
  and full first-run parity without granting publication, scheduling,
  unreviewed deletion, root installation, credential inspection, or scheduler
  authority.

  **Next action:** wait for an explicit owner `go`. After `go`, reconstruct this
  frozen plan from disk, set the phase to `executing`, and begin step 1; do not
  scaffold or execute the onboarding skill before that gate.

- **T-182 — Relocate, back up, and normalize the seven-node home control plane
  (in progress 2026-07-15):** migrate approved high-growth cache/tool state to
  the owner-selected large/fast roots; retain small node-local histories at
  their default paths; reconstruct portable Bash, Vim, SSH-fragment, tool, and
  28-link parity; add verified Restic recovery; and remove only the explicitly
  reviewed clean-slate paths. Credential-bearing paths remain uninspected and
  require the agreed owner-run backup/move/removal commands. `ab2` storage
  migration is externally blocked until its requested 10 TB group quota is
  active, but other nodes proceed independently.

  **Safety and acceptance:** repair the RC lexical/canonical account-home guard
  before any bulk cleanup; use immutable guarded-delete manifests for every
  directory-tree deletion; preserve node-local histories and authentication;
  require restore tests, fresh interactive and non-interactive SSH validation,
  control-plane idempotence, and fleet doctor evidence. Login synchronization
  is interactive-only and fast-forward-only. Explicit `exit` prompts to publish
  only dirty harness work; Ctrl-D is disabled in top-level interactive remote
  shells. No automatic logout push, credential copy, scheduler job, deployment,
  or unreviewed external write is authorized.

  **Working files:** `TODO.md`,
  `shared/skills/guarded-bulk-delete/scripts/guarded-delete`,
  `tests/test-guarded-delete.sh`, shell/config manifests and transactions under
  `libexec/`, `profiles/`, `shell/`, `tools/`, `tests/`, and
  `shared/skills/operate-native-hpc/references/sites.md`.

  **Current checkpoint:** repository clean at `00c07aa` before this ledger edit;
  all six remotes connected during planning. Current node owns canonical
  `.vimrc` SHA-256 `2226d098…b2f3`. RC account home is lexical
  `/home/users/rio.yokota` and resolves to `/hs/work0/home/users/rio.yokota`;
  the current guard rejects this valid site layout. First executable action is
  to add adversarial lexical/canonical-home tests, repair the guard, and run the
  complete guarded-delete suite before touching remote state.

  **2026-07-15 guard checkpoint:** guarded-delete schema v2 now records and
  revalidates both the lexical NSS home and canonical resolved home, protects
  both spellings, and keeps the internal cleanup helper's `$HOME` lexical.
  Dedicated tests cover successful aliased-home plan/apply, broad lexical-home
  rejection, canonical identity drift, target drift, and prior protected-root
  cases. `tests/test-guarded-delete.sh` and the complete
  `tests/test-phase1.sh` pass; the only emitted diagnostics are the already
  recorded login-node Open MPI CUDA-library warnings. No remote state has been
  changed. Next action: commit this independently verified safety repair, then
  validate its read-only plan behavior on RC before implementing migration
  transactions.

  **RC validation:** local commit `2ebf80d` was streamed to RC without
  installation and planned both known `/tmp/harness-shell.*` residue trees.
  The mode-600 schema-v2 manifest recorded lexical
  `/home/users/rio.yokota`, canonical `/hs/work0/home/users/rio.yokota`, and
  exact target facts (three entries, 344 bytes each); no target was deleted.
  The exact temporary manifest was unlinked and verified absent. The guard
  repair therefore resolves the observed RC failure without weakening protected
  roots. Next action: implement the portable storage/shell configuration and
  its plan/apply/rollback tests before fleet distribution.

  **Portable configuration checkpoint:** all seven profiles now declare the
  owner-selected persistent and cache roots, with the still-blocked `ab2`
  quota recorded separately from the other six executable migrations. The
  silent profile layer exports application cache roots without creating paths;
  top-level interactive SSH sessions alone perform a bounded fast-forward
  login fetch, prompt on explicit `exit` to publish staged harness changes, and
  disable Ctrl-D exit. Fresh `.profile`/`.bashrc` creation and rollback are now
  transactional. The current `.vimrc` is preserved byte-for-byte as the
  canonical managed source, and a separate non-secret SSH fragment contains
  only `Host github` and `Host *`; node-local SSH configuration is retained and
  receives one managed include. Exact replacement, changed-state refusal, and
  rollback are covered by the full phase-1 suite. The native-HPC reference now
  links each target to official documentation; no public RIKYU user guide was
  found on 2026-07-15, so the official system announcement and site-local help
  are recorded without substituting Fugaku commands. Local read-only plans are
  unblocked. Next action: commit this layer, then add checksum-pinned Restic and
  the approved tmux/htop installation routes before distributing the revision.

  **Portable tool checkpoint:** Restic 0.19.1 now has exact x86-64 and AArch64
  single-binary transactions pinned to the SHA-256 digests published with the
  official release. tmux 3.6b and htop 3.5.1 use their official release source
  assets and publisher digests; tmux statically links the official libevent
  2.1.12-stable distribution whose independently reproduced SHA-256 is pinned
  because that older release asset predates GitHub's digest metadata. Archive
  root, entry-count, path, and type gates reject undeclared content before
  extraction. A real isolated build verified htop 3.5.1, tmux 3.6b, static
  libevent linkage, managed idempotence, rollback, and guarded removal of both
  build trees; the full phase-1 suite also passes Restic bzip2 apply/rollback,
  both architectures' plans, and both source plans. The two isolated validation
  roots (1,170 and 422 entries) were removed through one schema-v2 manifest and
  verified absent. No live home or remote node changed. Next action: commit,
  distribute the revision, and run read-only fleet plans before applying tools
  or configuration.

  **Restic probe correction:** the first local apply verified the official
  archive digest and extracted one regular binary, then correctly rejected it
  before installation because the generic health probe invoked `--version`
  instead of Restic's `version` subcommand. Staging was guard-deleted and no
  binary or link remained. Commit `e75f719` added an argument-sensitive
  regression fixture and the native `version` subcommand; all seven live
  installations now report Restic 0.19.1.

  **Fleet execution checkpoint:** commits through `4f34299` are clean on all
  seven checkouts. Restic 0.19.1 is installed everywhere; tmux 3.6b is installed
  on `al` and `rc`; htop 3.5.1 is installed on `ab`, `ab2`, and `t4`. Every
  checkout has 28 `KEEP` control-plane links, managed shell loaders, the exact
  canonical Vim configuration, and the shared SSH include. Real PTY sessions
  on all six remotes proved the host roots, interactive-only exit wrapper, and
  Ctrl-D guard; non-interactive sessions retained builtin `exit` and loaded no
  remote-session policy. The explicit `harness_remote_codex HOST` path uses one
  allowlisted PTY connection and per-invocation agent forwarding. No harness
  commit was pushed.

  `.local` now resolves to the selected persistent root on `local`, `ab`, `ri`,
  `al`, `rc`, and `t4`; `ab2` deliberately remains a default-home directory
  until its 10 TB quota is active. The current-node migration retained two
  independently materialized, checksum-identical 5,821-entry copies before
  activation; its 686,904,121-byte original was then removed through a narrowed
  schema-v2 guard. Approved fast-state moves are complete for `.nsightsystems`,
  `.nv`, `.triton`, and `.starpu` on `ab`, and `.allinea`, `.apptainer`, `.cupy`,
  `.lhotse`, `.nv`, and `.triton` on `t4`; each has a persistent pre-migration
  copy. Node-backup links and mode-0700 (or inherited setgid-2700) Restic parents
  exist on every node. All known incident/rollout bundles and harness temporary
  directories were exact-unlinked or guard-deleted, and a full `/tmp/harness*`
  audit was empty afterward.

  **Encrypted-backup gate:** `profiles/restic-repositories.tsv` and
  `docs/home-backup.md` define unique per-node primary repositories, an
  independent encrypted generation at a second site, owner-held mode-0600
  password files, a manual all-hidden-path snapshot, `check --read-data`, and
  `restore --verify`. Scheduling is explicitly deferred until manual restore
  evidence is stable. The owner created unique mode-0600 password files on all
  seven nodes without exposing them. Empty repositories are initialized and
  structurally present on `local`, `ab`, `ri`, `al`, `rc`, and `t4`; AB2
  initialization is deferred with all other AB2 work until its quota increase.
  Agents have not read credentials or inspected repository/restored content. The
  owner-run snapshot plus `check --read-data` transaction completed on all six
  initialized nodes (`local`, `ab`, `ri`, `al`, `rc`, and `t4`), and each now
  has a structurally visible manual hidden-home snapshot. AB2 has no repository
  or helper and remains deferred with its other work. Restore verification is
  complete on `ab`, `ri`, `al`, `rc`, and `t4`: each helper ran `restore --verify`,
  the wrapper validated a nonempty restored tree using only aggregate metadata,
  and the helper plus unread mode-0600 log were exact-unlinked after success.
  Their restored trees were each removed by a separate immutable
  guarded-delete manifest; apply revalidated every target, preserved protected
  anchors, verified absence, and the exact manifests were then unlinked. Each
  empty restore-test parent was subsequently removed by one exact non-recursive
  `rmdir` and verified absent. RI
  initially failed before creating a target because its non-interactive SSH
  `PATH` omitted the healthy managed Restic binary; a reviewed
  `~/.local/bin/restic` fallback fixed the helper, and the retry then succeeded
  without reading either private log. After the owner renewed the existing
  CSCS-signed `id_ed25519` certificate, AL restored 11,065 entries on Capstor;
  its helper and unread private log were exact-unlinked after success. Its
  first guarded cleanup apply failed closed before deletion because separate
  SSH connections landed on login nodes with different lexical-home
  identities. A fresh plan/apply pair in one persistent `daint-ln003` session
  then revalidated and removed only the restore tree; its manifest and empty
  parent were exact-unlinked/non-recursively removed and verified absent. The
  current node then restored 70,959 entries and 3,077,206,016 allocated bytes
  to mode-0700 local `/tmp` scratch in seconds. Its helper and both unread
  private logs were exact-unlinked after success; a fresh guarded manifest
  removed the scratch tree, preserved protected anchors, and its manifest and
  empty parent are absent. Therefore every
  approved clean-slate deletion and owner-sensitive
  `.mozilla`/`.muttrc`/agent-state action remains closed only pending the
  independent encrypted generations.
  The final parity, doctor, real-shell, origin, and all-backend temp audits pass.
  Bundle SHA-256 `b1dd3f0e…41d` then fast-forwarded the clean `ab`, `ri`, `rc`,
  and `t4` checkouts from exact `6db9296` to `0c44c5f`. Each node verified the
  bundle, clean target revision, wrapper syntax, and Restic 0.19.1 execution
  through the new route; every remote and local bundle was exact-unlinked and
  verified absent. Later bundle SHA-256 `fd7647f3…0200` fast-forwarded AL's
  clean checkout from exact `6db9296` to `27a1a91`; Restic 0.19.1 and the AL
  replica plan route passed, and both bundle copies were exact-unlinked. AB2
  remains wholly deferred and unchanged. Fleet bundle SHA-256
  `0d5866be…6af5` subsequently fast-forwarded the five active clean remotes
  from their `0c44c5f`/`27a1a91` checkpoints to `0f200ac`. Every node verified
  the bundle and clean target, Restic 0.19.1, and its host-specific replica
  plan; all remote and local bundle copies are absent.
  Generation `20260715T222741Z` is independently validated for `local`: its
  encrypted repository was copied and promoted at T4, then passed a fresh
  all-pack read and verified restore without using `/mnt/nfs-03`. The `ab`
  generation has been fingerprint-validated and promoted locally, but its
  independent Restic validation remains pending because it requires the AB
  password at the replica site. On 2026-07-16 the owner reopened NFS work and
  requested background execution with five-minute reporting. No prior
  Restic/replica task was running. RI source preflight found no Restic writer
  or lock and recorded 286 entries, 325,277,900 bytes, and SHA-256
  `62099e9e5b20393fda4ac02bae6c0decd02a93f508ca4672ab766207dec271cc`;
  its generation staging/final paths were absent. A first `nohup` launch was
  killed by the command supervisor before creating either path; it produced no
  status, retained an empty unread mode-0600 log and reviewed helper, and both
  exact files were then unlinked, making retry safe. Persistent background
  session `1422` then completed the reviewed apply: RI generation
  `20260715T222741Z` was promoted with the exact source fingerprint above.
  The serialized AL, RC, and T4 applies then passed the same writer/lock,
  collision, source-before/after, staging, and promoted-final gates:
  AL is 289 entries, 361,725,145 bytes, SHA-256
  `ee644eb6d134f7657b4e65345ea8e0694ea523fe82c6e304abbd7bebfd601c07`;
  RC is 298 entries, 525,388,529 bytes, SHA-256
  `4025fbc83ce39b9915b58aba6451567459c7f1c06e82f39f06ae1a1da0d412b2`;
  and T4 is 497 entries, 4,092,281,307 bytes, SHA-256
  `1da892c7bb066b84317cf67cebc82ef68223b212bf2861c25b934225f877038c`.
  A final shallow audit found final generations for `ab`, `ri`, `al`, `rc`,
  and `t4`, no corresponding staging path, and no Restic or rsync process.

  Independent Restic validation remains closed on credential transport. A
  loopback-only reverse SSH preflight from AB reached this node but failed
  `publickey` authentication because the forwarded agent is not authorized by
  this node's SSH server. No repository or credential was accessed or changed.
  Do not copy password bytes, weaken SSH authentication, or expose a writable
  unauthenticated repository to bypass this. Next action: use an owner-supplied
  approved password-file path at the replica site or implement and test a
  strictly read-only, user-private transport before running `check --read-data`
  and verified restores for `ab`, `ri`, `al`, `rc`, and `t4`. Only after all
  generations validate may sensitive cleanup reopen.

  **Independent-generation safety checkpoint:** foreground work during the
  read-only local restore added a credential-free `harness replica plan/apply`
  transaction without touching any live repository or remote. It derives only
  the seven-row declared routes, keeps AB2 rejected, copies with native
  `rsync -aH` and no deletion option, fingerprints encrypted repository bytes
  before and after copying, rejects locks, symlinks, nested filesystems, path
  collisions, source drift, and staging mismatches, and promotes only by an
  exact staging rename. Synthetic tests cover both copy directions plus every
  rejection above; failed staging fixtures are retained for evidence and then
  removed by the suite's guarded cleanup. ShellCheck and the complete phase-1
  suite pass. Restore evidence is now complete and the implementation is
  distributed to all five active remotes, so live execution is open for the
  six initialized repositories. AB2 remains rejected.

  **Current-node NFS diagnosis:** the first local `restore --verify` was
  intentionally interrupted with exit 130 after more than eight hours of
  measurable progress, not because Restic hung. It had read approximately the
  full 1.04 GB/329-entry encrypted repository and written about 3.07 GB, while
  the private mode-0600 log continued changing. The partial materialization was
  70,939 entries and 2,866,582,512 bytes. The process and the subsequent exact
  guarded deletion repeatedly entered kernel `D` state in
  `rpc_wait_bit_killable` on `/mnt/nfs-03/safe`, an NFSv4.2 hard mount from
  `192.168.33.30:/tank/safe`. Mount statistics show effectively zero network
  retransmissions and no RPC backlog, but metadata round trips average roughly
  85 ms for REMOVE, 75 ms for CREATE, 117 ms for SETATTR, 43 ms for OPEN, and
  220 ms for SYMLINK, with rare session operations taking seconds. A live
  sample achieved only 7.6 removes/second. The root cause is therefore
  small-file metadata amplification on the `/tank` NFS service, not capacity,
  client CPU, Restic integrity, credentials, or packet loss. Keep packed Restic
  repositories and immutable replica generations on large storage, but use
  node-local mode-0700 scratch for restore materialization and reconsider live
  metadata-heavy trees on this service. The first long-running guarded apply
  later exited without a retained terminal result after partially reducing the
  target to 4,125 entries and 135,734,272 allocated bytes. Because the target
  remained, it was not treated as success: the expired manifest was
  exact-unlinked, a fresh manifest rebound the reduced tree, and apply then
  verified protected anchors unchanged and target absent. The manifest and
  empty NFS restore parent are absent. The subsequent `/tmp` restore and
  cleanup completed as recorded above.

## Owner-review queue

- **T-169 — Research advanced agent harness practices (research complete
  2026-07-15; adoption remains owner-review gated):** froze the comparison at
  the recovered, fully tested harness baseline. No researched mechanism was
  implemented and no third-party text, code, or configuration was copied.
  Official product documentation is used only as evidence about the intended
  Codex/Claude environments; papers and evaluation reports are used only for
  their stated mechanisms and limitations, so their software licenses do not
  enter the current tree.

  **Primary-source inventory and disposition**

  | Mechanism and source | Current harness comparison | Disposition | Risk / cost |
  | --- | --- | --- | --- |
  | Outcome, constraints, verification, persistent goals, layered `AGENTS.md`, and focused skills ([OpenAI best practices](https://learn.chatgpt.com/guides/best-practices.md), [long-running work](https://learn.chatgpt.com/docs/long-running-work.md), [custom instructions](https://learn.chatgpt.com/docs/customization/agents-md.md)) | Global/project guidance, the durable task board, scoped skills, definition-of-done gates, and restart checkpoints already implement the durable parts | **Covered**; keep ledgers authoritative and instructions concise | More always-loaded prose consumes context and can reduce adherence; promote only stable rules |
  | Generated local memory ([OpenAI memories](https://learn.chatgpt.com/docs/customization/memories.md), [Claude memory](https://code.claude.com/docs/en/memory)) | The checked-in ledger already provides reviewable provenance and survives compaction; both products distinguish required instructions from generated recall | **Reject as an authoritative state layer**; optional product memory may remain owner-controlled | Generated state can be stale, delayed, context-heavy, or inappropriate after external-context work |
  | Interleaved reasoning, tool action, and observation ([ReAct paper](https://arxiv.org/abs/2210.03629)) | Small plan/tool/validation steps and evidence-backed replanning already follow this loop | **Covered**; retain observable evidence, not hidden reasoning transcripts | Extra narration without new evidence adds latency and context |
  | Feedback retained across retries ([Reflexion paper](https://arxiv.org/abs/2303.11366)) | Raw failures and ledger checkpoints are retained, but there is no measured rule for converting a failed attempt into a bounded retry capsule | **Experiment**, only after T-181 establishes a baseline | Self-generated reflection can reinforce a wrong diagnosis; bound retries and require external test evidence |
  | Agent-oriented command/file interfaces ([SWE-agent paper](https://arxiv.org/abs/2405.15793)) | Native commands, `rg`, `apply_patch`, task-specific harness verbs, exact manifests, and deterministic tests already supply a narrow, inspectable interface | **Covered/adapt**; add a wrapper only when repeated measured failures identify a specific interface gap | New wrappers increase maintenance and can obscure the native action |
  | Isolated subagents and parallel work ([OpenAI subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents.md), [Claude subagents](https://code.claude.com/docs/en/sub-agents)) | `bounded-agent-delegation` already requires permission, independent scope, concise return evidence, and parent validation | **Covered**; reject default recursive teams or overlapping writes | Each worker adds tokens, startup latency, coordination risk, and possible context pollution |
  | Lifecycle hooks and command policy ([OpenAI hooks](https://learn.chatgpt.com/docs/customization/hooks.md), [Claude hooks](https://code.claude.com/docs/en/hooks)) | Deletion safety is enforced inside the workflow with manifests/revalidation and supplemented by command policy; it does not depend on model adherence | **Reject hooks as the primary safety boundary**; consider read-only telemetry only if T-181 shows an observability gap | Product/config-specific, potentially experimental, and a hook failure must not weaken deletion protection |
  | Long-task time horizons and acceptance quality ([METR time horizons](https://metr.org/time-horizons/), [maintainer-review study](https://metr.org/notes/2026-03-10-many-swe-bench-passing-prs-would-not-be-merged-into-main/)) | Harness tests prove explicit invariants but do not constitute a representative agent benchmark or maintainer acceptance test | **Adapt** through T-181; do not claim general autonomy from one suite or one successful recovery | Domain/task mix and grader choice materially change conclusions; repeated agent runs have real token/runtime cost |

  **Gap analysis:** safety, durable state, rollback, portability, verification,
  and bounded delegation are already strong and recently validated. The only
  evidence-backed gap is comparative evaluation: there is no frozen task corpus
  that can show whether a proposed planning, reflection, delegation, memory, or
  observability change improves accepted outcomes without increasing unsafe
  diffs, context, runtime, or recovery failures. T-181 is therefore the sole
  proposed implementation prerequisite. Auto-memory, deeper agent teams,
  always-on reflection, and hook-based deletion enforcement remain rejected
  unless measurements overturn their current cost/risk case.

Do not modify harness behavior from T-169 findings until the owner reviews the
evidence and explicitly selects an experiment. T-181 is a proposal, not an
authorized implementation task.

## Archived detail

The former 1,600-line chronological board, recovery checkpoints, exact remote
commands, transaction identifiers, and superseded observations remain in Git
through commit `238f022` and earlier. Use them as evidence during T-172, not as
live instructions.

## Issues appended during the T-172 sweep

- **T-173 — Reconstruct the lost ShellCheck transaction (complete
  2026-07-15):** implemented it as new work because no pre-incident object
  survived. Froze the supported version, primary artifact provenance,
  architecture coverage, and checksums; added isolated plan/apply/tamper/
  idempotence/rollback tests without inferring or claiming recovery of the
  lost bytes.

  **2026-07-15 reconstruction checkpoint:** the official project release and
  GitHub release metadata identify v0.11.0 as the current stable release and
  publish Linux x86-64 and AArch64 tarball digests. The tag's license is GPLv3.
  Reconstruct this as a checksum-pinned `tar.gz` transaction using only the
  exact `shellcheck-v0.11.0/shellcheck` member. Its multi-line `--version`
  output requires an exact `version: 0.11.0` health check; matching only the
  invariant banner would not prove the installed version. Both official
  archives independently reproduced their published digests and contained
  exactly one declared member; the verified x86-64 binary reported version
  0.11.0 and GPLv3. Exact/old host behavior, inventory/doctor integration,
  both architecture plans, isolated apply, idempotence, tamper refusal,
  rollback, guarded cleanup, syntax/diff checks, and the full phase-1 suite
  pass. The later T-171 local transaction pilot also passed; that successful
  reconstruction is not evidence that the lost implementation bytes were
  recovered.
- **T-174 — Remove raw recursive cleanup from harness tests (complete
  2026-07-15):**
  `tests/test-phase1.sh` and the native Slurm smoke owned temporary trees with
  raw recursive cleanup, while the guarded-delete regression suite silently
  tolerated cleanup failure. Replace those implicit exceptions with a shared,
  deterministic bounded cleanup path and adversarially prove it cannot expand
  to the account home before running the full suite again.
  Added one shared cleanup helper that accepts four explicit absolute paths,
  delegates every tree removal to a fresh guarded-delete manifest/token, removes
  its two fixed state files individually, propagates cleanup failure, and
  preserves signal exit status. The phase-1 suite, guarded-delete suite, and
  native Slurm smoke now use it. Home-target and raw-command adversarial tests,
  POSIX/Bash syntax, two dedicated runs, two full phase-1 runs, diff checks, and
  post-run searches for leftover roots/state all pass. The only recursive-rm
  strings left under `tests/` are inert exec-policy denial fixtures.
- **T-175 — Restore or deliberately retire lftp through a reproducible path
  (complete 2026-07-15):** the website deployment-policy test requires lftp,
  but no portable upstream binary exists. Official project evidence says 4.9.3
  is the latest source release; replacing lftp with rclone would require
  re-expressing owner SSH routing and could attempt remote shell commands on the
  SFTP-only target. Ubuntu Noble repository metadata instead provides the
  local-compatible `4.9.2-2ubuntu1.1` package with SHA-256 `60140f…0b72`.
  Independent download/hash, exact package layout, version, GPLv3+, and linked
  runtime-library checks pass. Commit `292c6b4` added a local-only exact-binary
  package transaction and retired lftp from every remote host scope. Both
  package plans, remote rejection, isolated apply/idempotence/tamper refusal/
  rollback, ShellCheck/syntax/diff gates, and the full phase-1 suite pass. Live
  transaction `20260714T230032Z-752754` installed the pinned binary; website
  commit `362847d` then passed its real file-backend mirror, deletion guard,
  publish/preview regressions, and complete offline security suite. No live
  server, credential, push, or deployment operation ran.
- **T-176 — Eliminate internal raw recursive deletion from harness
  transactions (complete 2026-07-15):** the T-174 whole-repository scan found direct recursive
  removal in rollback plus shell, tool, runtime, agent, Python, and source-build
  staging cleanup. Added a shared internal primitive that canonicalizes three
  explicit absolute boundaries, protects both the current and authoritative
  account homes, creates mode-700 unique state, delegates deletion to the same
  immutable short-lived manifest/token workflow, revalidates identity/counts/
  bytes immediately before removal, verifies anchors afterward, removes its
  manifest exactly on success, and preserves it on failure. Every production
  caller now propagates cleanup failure and preserves signal status; rollback
  retains its all-path preflight and reverse record order. Fake-HOME success and
  home-root refusal, manifest drift/race refusal, changed-tree rollback refusal,
  minimal-PATH command floors, recursive-command absence, syntax, dedicated
  guard tests, and repeated full phase-1 suites pass. Command-level exec policy
  is no longer the sole protection for deletion launched inside harness code.
- **T-177 — Resolve findings from the restored ShellCheck (complete
  2026-07-15):** the local recovery pilot found one real source-manifest
  checksum-loop defect plus warning-level portability/style findings. Replaced
  the ineffective one-item loop with exact checksum validation, made previously
  discarded manifest identity fields enforce their schemas, made rollback and
  remediation conditionals explicit, quoted literal hyphenated values, and
  used the portable explicit empty-`CDPATH` form. The phase-1 suite now lints
  every tracked shell entry point at warning/error severity when ShellCheck is
  available. Warning/error lint, POSIX syntax, diff checks, guarded-delete
  regressions, and the full phase-1 suite pass. Remaining exploratory messages
  are info-only dynamic sibling sourcing, deliberately single-quoted generated
  fixture bodies, manifest pipeline analysis, or trap-invoked helpers; they are
  neither globally suppressed nor actionable failures.
- **T-178 — Normalize hyphenated tool fact keys (complete 2026-07-15):** the
  reconciled plans reported `git-lfs` as unknown even when inventory and doctor
  agreed it was present because `harness-plan` did not map command punctuation
  to the fact-key schema. It now uses the shared mapper; present and unusable
  Git LFS fixture regressions and the full suite pass.
- **T-179 — Reconcile ABCI scheduler discovery (complete 2026-07-15):** both
  `ab` and `ab2` reported PBS commands absent in the direct non-interactive
  inventory. Read-only native comparisons proved that `bash -lc` resolves
  `qsub`, `qstat`, and `qdel` in `/opt/pbs/bin` and `nodestatus` in
  `/home/apps/pbs_wrapper/bin` on both hosts. The host profiles now declare
  those value-free command directories. Inventory appends only existing,
  non-symlink, validated absolute profile directories after inherited/user
  paths; it does not source startup files. An isolated fake-site-path test,
  shell lint/syntax, and the full suite pass. The T-170 rollout then verified
  direct discovery on both ABCI hosts; no scheduler job or allocation was
  created.
- **T-180 — Make aggregate plans enforce pinned Node/npm versions (complete
  2026-07-15):** current inventory correctly reported Node 18.19.1 and npm
  9.2.0, but `harness plan` emitted `KEEP` from command presence alone. The
  aggregate plan now reads the architecture-specific required versions from
  `tools/runtimes.tsv` and emits an explicit observed/required mismatch action.
  Exact and old Node/npm fixture regressions, live local planning, shell lint/
  syntax, and the full suite pass.

## Issue appended during T-169 research

- **T-181 — Build an acceptance-grade agent harness evaluation corpus
  (proposed; blocked on owner review):** before adopting any advanced agent
  mechanism, freeze representative tasks for small fixes, ambiguous requests,
  dirty-tree preservation, incident recovery/resume, destructive-operation
  refusal, primary-source research, and bounded delegation. Run baseline and
  one candidate at a time in disposable worktrees with fake homes, no
  credentials, no live remote writes, and guarded cleanup. Pre-register
  correctness and owner-style acceptance checks plus unintended-diff count,
  recovery success, wall time, tool calls, context/token use, and failure mode;
  repeat enough runs to expose nondeterminism. Require zero safety regressions
  and no correctness loss before considering cost/latency gains. Candidate A
  is one deterministic failure capsule plus at most one evidence-triggered
  retry; candidate B is a read-only bounded subagent on independently scoped
  exploration; candidate C is read-only lifecycle telemetry. Do not combine
  candidates until each beats the unchanged baseline, and do not use product
  memory, recursive teams, or hooks as safety enforcement.

## Issue appended during T-182 fleet validation

- **T-183 — Make private-origin login synchronization credential-safe
  (complete 2026-07-15):** real PTY logins proved that all six remote shell
  policies were active, but also exposed local bundle paths left as Git origins.
  Replacing only those local-path origins with the canonical private GitHub
  origin then showed the expected authentication failures on nodes without a
  forwarded agent. Commit `2c2dff0` makes an SSH private origin a silent no-op
  without an agent socket, suppresses raw authentication diagnostics, preserves
  fast-forward-only fetch with a pre-existing socket, and adds an agentless
  regression. Every bundle-local origin was replaced only after validating the
  canonical URL as an allowlisted credential-free GitHub form. The fix was
  distributed cleanly; repeated real PTY and non-interactive checks passed on
  all six remotes. Commit `4f34299` added the explicit one-connection launcher.
  No key, agent identity, push, or SSH owner setting was read or changed.

## Issue appended during the T-182 Restic initialization

- **T-184 — Reject truncated guarded-delete manifests at plan time
  (complete 2026-07-15):** AB2 exhausted its persistent-storage quota while
  Restic initialized, leaving a partial repository. The cleanup plan correctly
  inventoried 262 entries and 1,081,344 bytes, but the quota-exhausted
  destination retained an empty manifest while the command printed the token
  of the intended content. Apply rejected the mismatch before deletion, so the
  target remained intact. Commit `f31aeb5` builds manifest content on
  independent temporary storage and verifies exact target-filesystem copy and
  published-link size plus SHA-256. A truncating copy that falsely exits zero
  cannot publish a manifest; focused guard tests and the complete phase-1 suite
  pass. After fleet distribution, a fresh manifest on AB2's separate default
  home recorded the same 262 entries and 1,081,344 bytes; apply revalidated and
  removed only the partial repository, then its exact manifest was unlinked.
  The failed repository and temporary script are absent. All other AB2
  migration and backup work remains deferred until the quota increase is active.

## Issue appended during the T-182 remote restore gate

- **T-185 — Make non-interactive Restic resolution use the managed binary
  (complete 2026-07-16):** RI's first restore helper stopped before target
  creation because direct non-interactive SSH omitted `~/.local/bin` from
  `PATH`, although the checksum-pinned Restic 0.19.1 binary was healthy at
  `~/.local/bin/restic`. A reviewed helper fallback selected `command -v
  restic` first and then the exact executable managed path; syntax, ShellCheck,
  host detection, and helper hashes passed, and the retry completed verified
  restore plus guarded cleanup without inspecting private logs. The new
  `harness restic` route now gives a normal absolute `PATH` command precedence,
  falls back to the executable managed path, and fails if neither exists. The
  manual initialization, snapshot, check, restore, and snapshot-list commands
  all use this route. Synthetic fallback/precedence tests, live minimal-`PATH`
  Restic 0.19.1 execution, POSIX syntax, warning/error ShellCheck, diff checks,
  and the full phase-1 suite pass. The first full-suite attempt exposed a stale
  process-local OpenMPI module table; the native unload/load refresh restored
  its declared `mpicc` path, after which the suite passed with only the already
  documented login-node CUDA-library warnings.

- **T-186 — Replace retired CSCS SSHService authentication for AL
  (complete 2026-07-16):** AL failed at the Ela jump host with
  `Permission denied (publickey)` before any remote command runs. Read-only
  resolution confirms `alps_login` targets `ela.cscs.ch`, `al` targets
  `daint.alps.cscs.ch` through `ProxyJump alps_login`, both aliases already
  inherit the default `id_ed25519` identity, and the current agent socket is
  live with at least one identity.
  CSCS officially retired the old SSHService and its CLI in Q2 2026; do not
  reconstruct the lost `sshservice-cli`. The supported replacement is a local
  key signed for one day by `cscs-key` through CSCS MFA/device authorization.

  The owner renewed the existing certificate directly with `cscs-key sign
  --headless -f ~/.ssh/id_ed25519`; no new private key, SSH configuration, or
  repair installation was needed. A read-only connection now proves `ssh al`
  authentication succeeds. The owner added local alias `al` for that renewal
  command at line 5 of the current node's `.bashrc`, before the exact harness
  managed suffix. `harness shell` preserves this owner prefix, and the tracked
  harness contains no matching alias, so login synchronization cannot mirror
  it to another node. A fresh interactive shell resolves the alias. The unused
  mode-0700 `~/fix_al.sh` was hash-revalidated, exact-unlinked, and verified
  absent; it never ran, and no private diagnostic log exists. The staged AL
  restore then completed as recorded under T-182.

- **T-187 — Keep guarded deletion on one load-balanced AL login node
  (complete 2026-07-16):** an AL restore-cleanup plan and apply used separate
  SSH connections. Load balancing moved apply to a login node that reported a
  different identity for lexical home `/users/ryokota`; schema-v2 validation
  rejected it before deletion and retained both target and manifest. After the
  failed manifest was verified and exact-unlinked, one persistent SSH session
  on `daint-ln003` emitted a fresh plan for the unchanged 11,065-entry target
  and applied its exact token. Protected anchors were unchanged; target,
  manifest, and empty parent are absent. The AL native-site reference now
  requires persistent-connection plan/apply rather than weakening the
  account-home identity guard.

## Task appended during the T-182 independent-generation gate

- **T-188 — Validate the NFS-independent off-site generation (complete
  2026-07-16):** generation `20260715T222741Z` for `local` is immutable at
  T4 under `/gs/bs/jh250019/yokota/restic-replicas/local`. A fresh T4-side
  inventory reproduced the promoted fingerprint exactly: 328 entries,
  1,040,723,827 bytes, SHA-256
  `d1dc612c6f96da112f957a370fe4f46ac3333074668093e365b4f0a82ff1d6a1`;
  its lock directory is empty. With caching disabled, Restic accessed that
  generation over SFTP, found the tagged local snapshot, passed
  `check --read-data`, and passed `restore --verify` into node-local `/tmp`.
  The nonempty restored tree had 70,959 entries and 3,077,206,016 aggregate
  bytes. The reviewed credential-passing helper and unread mode-0600 log were
  exact-unlinked after success. A fresh guarded manifest then revalidated and
  removed only the 70,959-entry restore tree (2,895,957,642 planned bytes),
  preserved protected anchors, and verified the target absent; the exact
  manifest and empty parent are also absent. This validation did not access
  `/mnt/nfs-03`.
