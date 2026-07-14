# Personal harness task board

This board is the authoritative current state for the portable Codex and Claude
harness. Git preserves superseded chronology and command-level evidence. Keep
live tasks, verified recovery facts, blockers, and next actions here; do not
rebuild a second incident transcript in a session or report file. Next free id:
T-173.

## Recovery priority — do before any other task

- **T-172 — Exhaustively re-audit Git history for additional recovery
  candidates:**
  1. Traverse the complete `harness` and `website` commit graphs, all local
     refs, reflogs, and read-only unreachable-object reports. Start from the
     last verified pre-incident revisions (`harness` `5f6382b`; `website`
     `628b53a`) and reconcile every post-incident restoration commit.
  2. Compare pre-incident tracked file inventories, modes, symlinks, subtrees,
     and task state against the current checkouts. Include historical locations
     renamed during website T-170–T-178 and harness T-170; do not assume the
     current path existed at the older revision.
  3. Audit durable non-secret recovery evidence: Git bundles and their recorded
     hashes, transaction manifests, checksum allowlists, clean-clone tests,
     deployment exclusions, task metrics, and driver logs. Check whether the
     lost uncommitted ShellCheck transaction work survives in dangling Git
     objects or another explicitly safe repository artifact; do not claim that
     committed history contains uncommitted work without object evidence.
  4. Produce a candidate table with original path, source commit/object,
     pre-incident purpose, current state, confidence, sensitivity boundary,
     dependencies, and exact validation/rollback. Separate confirmed loss,
     already recovered state, intentional retirement, and unresolved evidence.
  5. Never inspect or restore credentials, private keys, tokens, shell/client
     histories, authentication stores, live client sessions, or secret values.
     Report only that owner-controlled state is present, absent, or unresolved.
  6. Restore nothing during the audit. Present one reviewed recovery plan first;
     any later restoration must be narrow, reversible, independently validated,
     and recorded here. This audit blocks T-170 fleet mutation and T-169.

## Active / recovery state

- **T-171 — Recover the current-node home after accidental deletion
  (awaiting T-172 audit):**

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
  (paused behind T-172):**

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

- **T-169 — Research advanced agent harness practices (blocked by T-172 and
  T-170 reconciliation):**
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
