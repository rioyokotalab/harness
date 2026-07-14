# Personal harness task board

This board is the authoritative current state for the portable Codex and Claude
harness. Git preserves superseded chronology and command-level evidence. Keep
live tasks, verified recovery facts, blockers, and next actions here; do not
rebuild a second incident transcript in a session or report file. Next free id:
T-182.

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

No active task. Insert the next user-defined task here as T-182; it takes
execution priority over the owner-review-gated T-181 proposal below. Replace
this paragraph with the task's outcome, constraints, verification, working
files, and first executable action when the task is supplied.

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
