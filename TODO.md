# Personal harness task board

This board is the authoritative current state for the portable Codex and Claude
harness. Git preserves superseded chronology and command-level evidence. Keep
live tasks, verified recovery facts, blockers, and next actions here; do not
rebuild a second incident transcript in a session or report file. Next free id:
T-177.

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
  | Selected current-node user tools | committed checksum manifests; pre-incident versions in `5f6382b` ledger | Missing: normal-PATH ripgrep, uv, Claude, rclone, lftp, Tectonic, Git LFS; system Node/npm are 18.19.1/9.2.0 instead of 24.16.0/11.13.0 | High; tool binaries only, never client state/config | T-174 first; lftp needs T-175 | run exact plan, apply one transaction, verify version/doctor/idempotence, deliberate rollback pilot, then reapply; no bulk restore |
  | `.profile`, `.bash_profile`, `.bash_logout`, `~/sshservice-cli`, unknown former home paths | no authoritative local source | Unresolved/absent; do not fabricate | High for named absence, unknown completeness; potentially sensitive owner state | Owner-supplied authoritative source only | presence/mode checks only; no validation or rollback is possible without a source |
  | Owner `.bashrc`, SSH config, and agent socket | owner reconstruction and T-171 ledger | `.bashrc` intentional new file; SSH config intentionally final at 10 aliases; socket ephemeral | Owner-confirmed; contents/key material excluded | Owner maintains authentication and socket lifetime | status/parse and owner no-op evidence only; never replace from Git or copy key/session state |
  | Six remote harness checkouts | last committed fleet evidence through `963ad1f`; local `5f6382b` CUDA delta | Current state unresolved after incident | Medium; value-free remote facts only | T-170 read-only reconciliation | native no-op, revision/status/inventory/plan/doctor per host; any later change uses one reviewed transaction and its recorded rollback |

  **Reviewed post-audit execution order:** restore no Git object; preserve the
  pre-incident reports; first remove raw recursive cleanup from the harness
  tests (T-174), then reconstruct and validate the lost ShellCheck transaction
  (T-173). Reconcile the local and six remote hosts read-only under T-170 before
  any mutation. Recover the checksum-pinned current-node tools one transaction
  at a time with an apply/validate/rollback/reapply pilot; T-175 must resolve
  lftp's missing supported artifact separately. Leave owner profiles,
  authentication, client state, and unknown home paths untouched. T-169 starts
  only after the resulting environment baseline is frozen.

## Active / recovery state

- **T-171 — Recover the current-node home after accidental deletion
  (T-172 audit complete; execute the reviewed plan above):**

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
    mismatch. Commit `238f022` added autonomous bulk-deletion safety: global
    guidance, Codex `forbidden` rules for common raw recursive `rm`, the
    manifest-bound `harness guarded-delete` workflow, adversarial tests, and
    Codex/Claude/shared-agent discovery. Skill, policy, focused, full-suite, and
    fresh Codex checks passed; ShellCheck itself is currently unavailable.

  **Unresolved or intentionally not reconstructed**

  - The first audit found `.profile`, `.bash_profile`, `.bash_logout`, much of
    the former user-local tool/runtime state, `~/sshservice-cli`, and unknown
    top-level home paths missing. Later owner and harness reconstruction changed
    part of that inventory. Treat all such claims as dated evidence until T-172
    compares Git and current state; do not fabricate owner profiles or infer
    that an absent path should exist. A 2026-07-15 website validation confirmed
    normal-PATH `lftp` is still unavailable; its isolated deployment-policy
    test stopped at that prerequisite without network or deployment.
  - The uncommitted ShellCheck transaction work after `5f6382b` was not in the
    restored bundle. T-172 must search read-only Git/object evidence before it
    is classified as permanently lost or reconstructed from intent.
  - Product-managed policy may override local Codex defaults on some surfaces;
    the verified fresh host CLI honored the recovered values. The surviving
    website pre-commit hook was left unchanged because agents do not edit
    `.git`; its old Claude-size branch is inert under the current tracked tree.

  **Next action:** execute T-172. Do not perform broad home reconstruction,
  owner config/profile edits, package installation, credential recovery, or
  fleet mutation during that audit.

- **T-170 — Mirror the working environment across configured clusters
  (ready for read-only reconciliation after T-172):**

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
  - Before the incident, all six remote checkouts had been independently
    synchronized through the MPI-route closure at `963ad1f`, with clean Git,
    zero doctor failures, idempotent plans, and mode-0600 transaction state.
    Local `5f6382b` then recorded validated native CUDA compiler routes; do not
    claim that revision reached every remote until T-172 and a later read-only
    fleet reconciliation prove it.
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
  - The accidental deletion invalidated current-node and fleet-parity
    assumptions. Do not resume remote mutation from the old chronological
    notes. After T-172, recapture value-free local and remote inventories,
    establish exact revisions, make a reviewed diff/rollback plan, then advance
    one host at a time only under a new user request.

## Planned

- **T-169 — Research advanced agent harness practices (blocked by T-170
  reconciliation):**
  1. Freeze the recovered harness behavior and evaluation criteria:
     correctness, autonomy, context efficiency, recovery, security,
     observability, portability, and measurable cost/runtime impact.
  2. Collect primary-source advanced `CLAUDE.md`/`AGENTS.md` examples and
     research on planning, memory, delegation, verification, reflection,
     long-horizon execution, and multi-agent coordination. Record provenance,
     license, intended environment, and exact mechanisms.
  3. Compare each mechanism with the current ledger, safety, validation, and
     portability behavior; classify it as covered, adopt, adapt, experiment, or
     reject with evidence, risks, and context/runtime cost.
  4. Produce a cited inventory, gap analysis, prioritized proposals, and
     isolated benchmark designs. Independently verify material claims and avoid
     license-incompatible copying.

Do not modify the harness from T-169 research findings until the owner reviews
the evidence and proposed changes.

## Archived detail

The former 1,600-line chronological board, recovery checkpoints, exact remote
commands, transaction identifiers, and superseded observations remain in Git
through commit `238f022` and earlier. Use them as evidence during T-172, not as
live instructions.

## Issues appended during the T-172 sweep

- **T-173 — Reconstruct the lost ShellCheck transaction:** implement it as new
  reviewed work because no pre-incident object survived. Freeze the supported
  version, primary artifact provenance, architecture coverage, and checksums;
  add isolated plan/apply/tamper/idempotence/rollback tests; do not infer or
  claim recovery of the lost bytes.
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
- **T-175 — Restore or deliberately retire lftp through a reproducible path:**
  the local profile selects lftp 4.9.3 and the website deployment-policy test
  requires it, but `harness tool --name lftp --plan` fails closed because no
  supported checksum-pinned artifact exists. Add a verified user-space source
  transaction or record an intentional dependency replacement; do not install
  an unpinned package merely to clear the warning.
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
