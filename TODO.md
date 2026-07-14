# Personal harness task board

This board owns planned and active work for the portable Codex and Claude
harness. Repository-specific tasks remain in their own project ledgers.

## Active

- **T-170 — Mirror the working environment across configured clusters:**
  1. Enumerate only concrete host aliases from the current node's SSH config
     and probe them non-interactively through the user's unlocked SSH agent.
     Use strict host-key checking, short timeouts, and a no-op remote command;
     do not copy keys, credentials, or other authentication material.
  2. Record which aliases pass, which fail at name resolution, routing,
     host-key verification, authentication, or remote command execution, and
     identify intentional non-cluster aliases separately.
  3. For reachable clusters, inventory only the portable environment surfaces
     the user approves (harness checkout, shell/tool configuration, package
     manifests, client discovery links, and version facts). Never copy secrets,
     live client state, caches, sessions, histories, or machine-specific paths.
  4. Define a declarative source of truth, per-cluster differences, dry-run
     synchronization, rollback, and validation before changing any remote.
  5. Apply changes only after the user reviews the inventory and synchronization
     plan; verify each cluster independently and preserve intentional local
     differences.

  Updated connectivity checkpoint (2026-07-14, current node, 11 aliases):

  - Clean non-interactive remote-command success: `ab`, `ab2`, `ai4s`, `rc`,
    `si`, `t4` (6).
  - `si` remains a known reachable SSH endpoint but is explicitly excluded
    from environment unification, profiles, deployment, and fleet validation.
  - `abci_login` is an acceptable proxy-only endpoint: its own session closes,
    but both downstream aliases `ab` and `ab2` pass through it.
  - `al` has the documented CSCS structure: its target is under
    `*.alps.cscs.ch`, it uses `ProxyJump alps_login`, an identity file, and
    `IdentitiesOnly yes`; `alps_login` resolves to Ela. After the user renewed
    the CSCS-signed identity, a strict non-interactive `ssh al true` passed in
    nine seconds. Source: <https://docs.cscs.ch/access/ssh/>. The remote startup
    still emits a non-fatal hygiene warning because `.bashrc` attempts `uenv
    start` in a non-interactive shell. An earlier logout emitted an unset
    `SSH_AGENT_PID` warning, but the captured inventory and a later targeted
    audit both found `.bash_logout` absent; preserve the earlier observation
    without inferring a current user-file defect.
  - Current-node convenience is installed: `.bashrc` defines `cscs-renew` to
    run the supported signer and reload only `~/.ssh/cscs-key` into the shared
    agent for one day. `Host al` uses `ControlMaster auto`, a hashed control
    socket under `~/.ssh/`, and `ControlPersist 8h`. Bash/config validation
    passed; a fresh no-op took about seven seconds and a multiplexed repeat took
    about 0.7 seconds with a live master connection.
  - `github` is reachable/authenticated and correctly behaves as a restricted
    non-cluster Git service. It is excluded from environment unification.
  - `web` is confirmed to be an intentional SFTP-only service; rejecting shell
    commands is correct and it is excluded from environment mirroring.
  - The only environment-unification targets are the current node plus `ab`,
    `ab2`, `ai4s`, `al`, `rc`, and `t4`. `abci_login` and `alps_login` remain
    transport-only proxy nodes and receive no harness deployment.

  Owner authorization checkpoint (2026-07-14):

  - The user explicitly authorizes the rollout to modify any remote file their
    account is permitted to edit on `ab`, `ab2`, `ai4s`, `al`, `rc`, and `t4`
    when the change is necessary for T-170. This includes `.bashrc`,
    `.bash_profile`, `.bash_logout`, the harness checkout and discovery links,
    and other evidence-backed user configuration required by the approved
    environment design.
  - File writability does not broaden the task: excluded aliases, unrelated
    projects or personal data, credentials and authentication material,
    external services, and destructive or unrelated cleanup remain out of
    scope. Shared or system-wide files with wider impact must be called out in
    the exact host plan rather than treated as routine user configuration.
  - Preserve each site's existing startup behavior and modify only a bounded,
    marked harness block. Before the first mutation, record file type,
    permissions, and a restorable backup without printing file contents or
    environment values. Repeated apply must update the block idempotently.
  - For `.bash_profile`, first determine structurally whether it exists and
    which login file Bash currently selects. If creating `.bash_profile` would
    supersede an existing `.bash_login` or `.profile`, show the preserved source
    chain in that host's plan before creation.
  - This broad file-level authorization satisfies the owner-configuration
    boundary for in-scope changes, but the exact value-redacted diff, backup
    location, validation commands, and rollback command must still be presented
    per host before rollout.

  Required shell-startup remediation before synchronization:

  - On `al`, make `.bashrc` invoke `uenv start` only in an appropriate
    interactive shell; preserve intended interactive behavior and use the
    supported non-interactive `uenv run` path where needed.
  - On `al`, do not create or patch `.bash_logout` unless the earlier unset
    `SSH_AGENT_PID` warning is reproduced and its current source is identified.
    Never terminate a forwarded, shared, or externally managed agent.
  - Audit non-interactive startup and logout on every reachable cluster for
    analogous stderr, unset-variable, agent-lifecycle, or exit-status defects;
    fix each evidence-backed issue and independently recheck both `ssh HOST
    true` and a normal interactive login.
  - The current node's `.bashrc` contains plaintext API credentials discovered
    during the scoped helper edit. Never mirror or commit them. Rotate the
    affected credentials, move them to an approved secret store or protected
    runtime injection mechanism, and verify that new shells receive only the
    intended environment without exposing values.

  Environment inventory checkpoint (2026-07-14):

  - The in-scope fleet cannot safely share a machine image or a package-manager
    state. It spans Ubuntu, RHEL/Rocky, and SLES; `x86_64` and `aarch64`; and
    Slurm, PBS, a local `yrun` wrapper, and hosts with no scheduler client on
    the login path.
  - Site software also differs intentionally: Environment Modules or `ml`,
    CSCS uenv, Singularity CE, Apptainer, Docker/Podman, different system
    Python/compiler/CMake versions, and different GPU/driver exposure.
  - All six in-scope cluster shells have Git, Bash, and Python 3. None has
    `uv`, Node, Nix, Home Manager, or mise in the probed login environment.
    POSIX shell and Git remain the mandatory bootstrap floor; richer tools are
    optional capabilities, not installer dependencies.
  - Only the current node has a harness checkout and the Codex/Claude discovery
    links. No remote files were changed during inventory.

  User preference decisions:

  - Unify every portable, non-sensitive shell-convenience category: prompt,
    aliases, functions, history policy, navigation helpers, and editor/pager
    defaults. The harness becomes their source of truth; host profiles retain
    only evidence-backed site differences. Inventory and reconcile the exact
    behavior without reading or migrating credential values.
  - Make the harness the source of truth for portable, non-secret Git, Vim, and
    tmux configuration. Use thin live includes/source hooks and preserve
    host-local Git identity, signing, credentials, machine paths, and mandatory
    site overrides outside the repository. Do not infer plugin installation or
    network downloads from this configuration decision.
  - Do not create normalized scheduler wrapper commands. Build an agentic
    workflow that uses each site's native scheduler commands, shows the exact
    resolved command before execution, and reports that command and its result.
    Host profiles may inform command selection, but must not conceal Slurm,
    PBS, or `yrun`/`ybatch` behavior from the user.
  - Do not clone, update, or mirror project repositories or datasets as part of
    fleet unification. The user will clone projects manually when needed. The
    harness may recognize and support an already-present project, but must not
    create its checkout or synchronize its working data implicitly.

  Local tool candidate checkpoint (2026-07-14):

  - Configured local defaults are Vim as `EDITOR` and `cat` as `PAGER`; tracked
    candidates exist for Git and Vim configuration. File presence was checked
    without reading configuration contents.
  - Deliberate user-space tools observed on the current node are `uv` 0.9.18,
    Node 24.16/npm 11.13, Codex CLI 0.144.4, Claude Code 2.1.207, ripgrep
    15.1, rclone 1.74.3, Tectonic 0.16.9, and lftp 4.9.3. Their executable
    names and versions are safe candidate inputs; credentials, client state,
    and tool-specific configuration are not.
  - Useful system-provided interfaces include Git, Vim/Neovim/Emacs, tmux,
    tree, jq, rsync, curl/wget, htop, SQLite, Make, CMake, Ninja, GCC/GDB, Go,
    Docker/Podman, CUDA commands, and Environment Modules. Treat compilers,
    CUDA, containers, numerical libraries, and build stacks as site/project
    capabilities rather than pinned personal binaries.
  - Common shell enhancements not currently installed include `fd`, `fzf`,
    `zoxide`, `bat`, `eza`, `direnv`, `yq`, GitHub CLI, `delta`, `lazygit`,
    `shellcheck`, and `shfmt`. Adding them would be an intentional improvement,
    not mirroring existing behavior.
  - The user selected bundles C + P + A + D for the initial rollout:
    - core shell interfaces: Git, Vim, tmux, ripgrep, jq, tree, rsync,
      curl/wget, htop, and SQLite;
    - Python: `uv` plus managed Python 3.12;
    - agents/Node: Node 24/npm, Codex CLI, and Claude Code;
    - documents/transfer: rclone, lftp, and Tectonic.
  - Do not add the currently absent modern shell/Git enhancements or extra
    editor configuration in the initial rollout. For each selected tool, the
    manifest must distinguish a host-provided command with a tested feature
    floor from a checksum-pinned user-space artifact. Never synchronize rclone
    or agent credentials and live state.

  Phase-1 implementation checkpoint (2026-07-14):

  - Implemented dependency-free `harness inventory`, `harness plan`, and
    `harness doctor` commands under `bin/` and `libexec/`. Inventory emits only
    allowlisted value-free facts and supports text and JSON. Plan and doctor
    accept live facts or an explicit captured fact file.
  - Added strict logical profiles for `local`, `ab`, `ab2`, `ai4s`, `al`,
    `rc`, and `t4`, plus the reviewed C + P + A + D tool policy. Excluded SSH
    aliases have no profile and are rejected.
  - Added value-free fixtures for all seven environments and
    `tests/test-phase1.sh`. The suite checks shell syntax, fact allowlisting,
    JSON parsing, every fixture/profile pair, a read-only plan terminator,
    expected remote checkout/tool actions, unknown-host rejection, and a
    required architecture-mismatch failure.
  - Extended the fail-closed installer to expose `bin/harness` as
    `~/.local/bin/harness`. An isolated-home install test passed, the live local
    link resolves to the tracked command, and the live local doctor reports
    zero failures and zero warnings. No remote file has been changed.
  - Next executable action: feed `harness inventory --host HOST` to `sh` over
    each of the six existing SSH connections without creating remote files.
    Replace partial fixtures with the resulting value-free facts and generate
    exact host plans for review.

  Read-only remote plan checkpoint (2026-07-14):

  - Streamed the self-contained inventory script over stdin to `sh` on all six
    targets. Every command exited successfully and created no remote file.
    Replaced the partial fixtures with the complete allowlisted fact streams.
  - All six profiles pass doctor with zero required failures. Warning totals
    reflect only the absent harness/discovery links and selected tools: `ab`
    13, `ab2` 13, `ai4s` 16, `al` 15, `rc` 14, and `t4` 15.
  - Planned tool additions are:
    - `ab`, `ab2`: ripgrep, htop, `uv`, Node/npm, Codex, Claude, lftp,
      Tectonic; retain existing rclone;
    - `ai4s`: ripgrep, tree, htop, SQLite, `uv`, Node/npm, Codex, Claude,
      rclone, lftp, Tectonic;
    - `al`: tmux, ripgrep, SQLite, `uv`, Node/npm, Codex, Claude, rclone,
      lftp, Tectonic;
    - `rc`: tmux, ripgrep, `uv`, Node/npm, Codex, Claude, rclone, lftp,
      Tectonic;
    - `t4`: ripgrep, tree, htop, `uv`, Node/npm, Codex, Claude, rclone,
      lftp, Tectonic.
  - Every target also plans a clean committed harness checkout and the three
    Codex/Claude discovery links. Startup-file plans remain structural and do
    not read contents. `al` still emits the known non-interactive `uenv start`
    error before inventory output; remediate it before installing the common
    shell hook.
  - Exact plans are reproducible with `harness plan --host HOST --facts
    tests/fixtures/HOST.facts`. Await review before implementing apply/rollback
    or changing any remote file.

  Transaction implementation checkpoint (2026-07-14):

  - The user approved the reviewed delta. Implemented `harness apply --host
    HOST --plan|--apply` and `harness rollback TRANSACTION_ID` for the managed
    control-plane links. Apply requires a clean committed checkout, passing
    doctor, and collision-free preflight before mutation.
  - Transactions record only created links, host, and harness revision in
    mode-600 manifests under `~/.local/state/harness/transactions/`. Apply
    automatically removes partial links after failure. Rollback removes only a
    link that still matches its recorded source and refuses changed paths.
  - The isolated test performs real plan/apply/rollback operations from a clean
    temporary Git repository. It also replaces a managed link deliberately and
    verifies rollback preserves the foreign target and fails safely before a
    successful retry.
  - Next executable action: commit this transaction implementation, transfer
    the committed harness revision to `ab2` with a native Git bundle over SSH,
    show the native remote plan, apply, validate, deliberately roll back once,
    and reapply. This pilot changes control-plane links only; it does not yet
    edit shell startup files or install selected tools.

  `ab2` control-plane pilot checkpoint (2026-07-14):

  - Committed transaction support as `07351a4`. Created and verified a native
    Git bundle containing `main`, then streamed it over SSH. The first clone
    attempt omitted `-b main`; bundles do not advertise a remote `HEAD`, so Git
    created an empty checkout and reported `remote HEAD refers to nonexistent
    ref`. The revision check stopped the pilot before apply.
  - Verified the failed `~/harness` contained only `.git` and had zero dirty
    entries, removed only that agent-created artifact, and retried safely with
    `git clone -b main`. The resulting checkout is clean at `07351a4`. Future
    bundle deployment must always name the branch explicitly.
  - The exact control-plane plan contained 22 creates and no replacements or
    blocks: the harness command, three guidance/rule links, and six shared
    skills exposed in each of the Codex, Claude, and shared agent directories.
  - Applied transaction `20260714T114257Z-4146521`, validated a mode-600
    manifest, 22 links, zero doctor failures, and silent `ssh ab2 true`, then
    deliberately rolled it back. Rollback removed exactly the recorded links
    in reverse order and preserved the audit manifest.
  - Reapplied as transaction `20260714T114331Z-4149212`. Final validation shows
    zero planned creates, 22 keeps, clean Git state, transaction status
    `complete`, silent non-interactive SSH, and doctor `failures=0 warnings=9`;
    the nine warnings are the selected tools not yet installed.
  - No shell startup file, credential, project, dataset, or selected tool was
    changed. Next action is either to roll out this validated control plane to
    the other five hosts or begin the separately transactional `ab2` shell/tool
    pilot after recording artifact checksums and startup-file backups.

  Fleet control-plane checkpoint (2026-07-14):

  - Rolled the control plane to `ab`, `al`, `rc`, and `t4`, and fast-forwarded
    `ab2`, so all five are clean at `95075c4` with 22 keeps, zero planned
    creates, and zero doctor failures. Transactions: `ab`
    `20260714T114658Z-4160962`, `al` `20260714T115013Z-26535`, `rc`
    `20260714T115019Z-1532458`, and `t4` `20260714T115026Z-2153095`; `ab2`
    retains its validated transaction and was fast-forwarded in place.
  - The first fleet command cloned `ab` successfully but stopped before apply
    because the local shell expanded `$HOME` in the SSH command. Verified the
    checkout was clean and no control link existed, then retried with remote
    expansion quoted correctly. `ab` subsequently passed all gates.
  - `ai4s` timed out once during SSH banner exchange, then accepted a no-op,
    but later state probes became silent before returning any evidence. Leave
    its control-plane state unknown and pending; do not retry mutation until a
    fresh read-only state audit returns reliably.
  - `al` passed the control-plane gates but emitted the known `uenv start`
    non-interactive error for every SSH command. Its final doctor is
    `failures=0 warnings=11`; remediate `.bashrc` before further rollout there.
    Final warnings on the other converged hosts are selected-tool gaps: `ab`
    9, `ab2` 9, `rc` 10, and `t4` 11.
  - No rollout in this checkpoint edited startup files or installed tools.
    Next safe actions are a fresh read-only `ai4s` audit and the backed-up shell
    pilot on `ab2`; handle `al` startup remediation as its own transaction.

  `ai4s` retry checkpoint (2026-07-14):

  - A later read-only no-op succeeded once, but three subsequent structural
    state probes returned no remote output, including one with a 45-second
    connect timeout and SSH keepalives. No reliable evidence establishes
    whether `~/harness` exists, so no mutation was attempted.
  - Treat `ai4s` control-plane rollout as connectivity-blocked until a fresh
    read-only audit reports checkout and link state. Continue independent work
    on the other hosts without inferring success or absence.
  - Next executable action: implement and isolate-test a shell managed-block
    transaction for `ab2`. Do not copy whole startup files into backups because
    their unknown contents may include credentials; rollback must remove only
    the exact appended harness block when surrounding file state still matches.
  - Shell pilot work started: added tracked `shell/profile.sh`,
    `shell/interactive.sh`, and exact `.bashrc`/`.bash_profile` block payloads.
    They set the selected local defaults, prepend `~/.local/bin` idempotently,
    and guard interactive history initialization. These files are not yet
    deployed; next implement suffix-verified append/rollback and isolated tests.
  - Implemented `harness shell --host HOST --plan|--apply`. It requires regular
    `.bashrc` and `.bash_profile` files, blocks pre-existing non-suffix markers,
    and appends only the public tracked payload. Transaction state contains no
    pre-existing file bytes or hashes.
  - Extended rollback with an all-path preflight. An adversarial test added a
    later edit after shell apply and exposed an initial partial-rollback flaw;
    rollback now validates every recorded link/file before any removal or
    truncation. The test proves the later edit is preserved, the first rollback
    fails without partial mutation, and a clean retry restores both fake startup
    files byte-for-byte without copying their fake secret into transaction state.
  - Next executable action: commit, fast-forward `ab2`, show its shell dry run,
    apply the two managed suffixes, validate non-interactive and interactive
    startup, deliberately roll back, then reapply if all checks pass.

  `ab2` shell pilot checkpoint (2026-07-14):

  - Committed suffix-verified shell transactions as `42e9a11` and
    fast-forwarded the clean `ab2` checkout to that revision with a native Git
    bundle. The reviewed dry run planned one 144-byte append to each of
    `.bashrc` and `.bash_profile` and no blocked path.
  - Applied transaction `20260714T120012Z-2710544`. The files retained their
    original owners and modes (`17783:0644` and `17783:0640`) and grew from
    592/424 bytes to 736/568 bytes. A repeated plan returned two `KEEP`
    results, and `ssh ab2 true` remained silent.
  - Deliberately rolled that transaction back. Rollback restored the exact
    original byte lengths and modes, removed both public managed markers, left
    non-interactive SSH silent, and made the next plan return the same two
    appends. No pre-existing startup-file bytes were copied to transaction
    state or displayed.
  - Reapplied cleanly as transaction `20260714T120159Z-1639880`. Its manifest,
    status, and two public payload records are mode 600; the status is
    `complete`. Both startup files have exactly one managed suffix, the dry
    run is idempotent, and a real `ssh -tt` login reports `EDITOR=vim`,
    `PAGER=cat`, `HISTCONTROL=ignoreboth:erasedups`, and the interactive guard
    loaded once.
  - An earlier non-TTY `bash -ic` check emitted pre-existing job-control/stty
    warnings, while the real TTY login completed normally. Two post-apply
    validation probes also initially used stale marker/state filename
    assumptions; they caused no mutation, and corrected probes used the
    tracked marker plus the actual `.manifest.status` path.
  - Next safe action: fast-forward `ab`, `rc`, and `t4` to `42e9a11`, show each
    shell plan, and apply/validate one host at a time. Keep `al` out of this
    rollout until its `uenv` startup defect is remediated and the earlier
    logout warning is rechecked, and keep `ai4s` blocked pending reliable
    read-only connectivity.

  Eligible-fleet shell rollout checkpoint (2026-07-14):

  - Fast-forwarded the clean `ab`, `rc`, and `t4` checkouts from `95075c4` to
    `f124e36` with a checksum-verified native Git bundle. Each pre-apply plan
    contained only the two reviewed 144-byte appends. Their checkouts remain
    clean and their host doctors had zero failures before mutation.
  - Applied and validated shell transactions `ab`
    `20260714T120521Z-27821`, `rc` `20260714T120542Z-1676365`, and `t4`
    `20260714T120606Z-3929502`. Every original owner and mode was preserved,
    every file grew by exactly 144 bytes, every startup file has exactly one
    managed suffix, and every transaction manifest/status is mode 600 and
    complete.
  - Repeated plans return two `KEEP` results on all three hosts. Native
    `ssh -x HOST true` is silent, and real `ssh -x -tt` login shells on all
    three report the common Vim/cat/history settings with the interactive
    guard loaded once.
  - The first `ab` transfer staged the bundle under `/tmp`. `scp` succeeded,
    but a new SSH connection reached a different login node and could not see
    that node-local path; Git stopped before changing the checkout. Retrying
    through a checksum-verified shared-home staging file succeeded, and that
    file was removed after the fast-forward. Future load-balanced cluster
    transfers must not assume `/tmp` is shared between connections.
  - `al` remains intentionally excluded from shell apply until its
    non-interactive `uenv start` defect is fixed and the earlier, currently
    unreproduced logout warning is rechecked.
    `ai4s` remains connectivity-blocked, and the current node remains blocked
    on rotation/removal of plaintext credentials from `.bashrc`; neither was
    mutated in this checkpoint.
  - Next executable action: design a suffix-verified, content-minimizing
    transaction for the reviewed `al` uenv startup defect, dry-run it, and
    validate non-interactive and real interactive behavior before applying the
    common shell suffix there.

  `al` remediation implementation checkpoint (2026-07-14):

  - Current official CSCS guidance explicitly says not to use `uenv start` in
    `.bashrc`: it creates an interactive child shell. Automated commands should
    use `uenv run`, and Slurm jobs should use the native uenv integration.
    Source: <https://docs.cscs.ch/software/uenv/using/>.
  - A targeted remote audit printed only exact public matches. It found one
    offending line, `uenv start prgenv-gnu/25.11:v1 --view=default`, in the
    mode-600 `.bashrc`. It confirmed `.bash_logout` is absent, consistent with
    the captured fixture, so no logout file is currently eligible for editing.
  - Implemented `harness remediate --host al --plan|--apply`. It recognizes
    only that reviewed line, replaces it in place with an equal-length public
    comment, and stores only the original/applied 45-byte patches in mode-600
    transaction state. It neither copies nor hashes surrounding bytes.
  - Extended all-path rollback to validate patch payloads, file length, and the
    exact patched range before restoration. Isolated tests prove apply,
    idempotent planning, changed-patch refusal, exact rollback, unreviewed-host
    refusal, and that a fake credential elsewhere in `.bashrc` never enters
    state.
  - Added host-specific Alps shell payloads and an interactive-only `prgenv`
    function. It reports and calls the exact native `uenv start
    prgenv-gnu/25.11:v1 --view=default`; non-interactive shells do not define
    it. The full phase-1 suite and shell syntax checks pass.
  - Next executable action: commit this implementation, fast-forward the clean
    `al` checkout with a checksum-verified bundle, show both remediation and
    shell dry runs, then apply/validate/rollback/reapply the remediation before
    applying the common shell suffix.

  `al` deployment checkpoint (2026-07-14):

  - Committed the remediation as `5b51f58`, verified the complete Git bundle
    locally and remotely with SHA-256
    `c466841457f2e5da94c8af12cb93576a6c05577b6dcb90d707645ca7a7c65673`,
    and fast-forwarded the clean `al` checkout from `95075c4`. The shared-home
    staging artifact was removed after transfer.
  - The remote dry runs found no pre-existing `prgenv` function, exactly one
    reviewed 45-byte uenv patch, and two unblocked 195-byte host-specific shell
    suffixes. Before mutation, `.bashrc` was owner 31254, mode 600, 172 bytes;
    `.bash_profile` was owner 31254, mode 644, 552 bytes.
  - Applied remediation transaction `20260714T121512Z-270890`. It preserved
    `.bashrc` size/owner/mode, made the next plan `KEEP`, silenced `ssh al
    true`, and produced a clean real-TTY login. Deliberate rollback restored
    the exact original line and reproduced the known 526-byte uenv warning;
    the next plan again proposed the one exact patch.
  - Reapplied as remediation transaction `20260714T121553Z-290205`, then
    applied shell transaction `20260714T121604Z-2866`. Final `.bashrc` and
    `.bash_profile` sizes are 367 and 747 bytes, exactly 195 bytes larger, with
    original owners/modes and one managed marker each. Both manifests/status
    records are mode 600 and complete.
  - Final plans are all `KEEP`, doctor reports `failures=0 warnings=11`, and
    non-interactive SSH is silent. A real login TTY reports `EDITOR=vim`,
    `PAGER=cat`, `HISTCONTROL=ignoreboth:erasedups`, the guard loaded once, and
    `prgenv` as a function. The earlier `SSH_AGENT_PID` logout warning did not
    recur, so no absent `.bash_logout` file was created.
  - The common shell layer is now converged on `ab`, `ab2`, `al`, `rc`, and
    `t4`. Remaining shell targets are the connectivity-blocked `ai4s` and the
    current node, whose plaintext `.bashrc` credentials must be rotated and
    removed before a managed shell transaction is considered.

  Adopt the capability-driven design in
  [`docs/environment-portability.md`](docs/environment-portability.md):

  1. First implement read-only `inventory`, `plan`, and `doctor` commands plus
     logical host profiles. Keep detection separate from policy and redact
     values by construction.
  2. Extend installation transactionally: explicit `--host`, dry-run by
     default, checksum-pinned portable artifacts, backups/state records,
     idempotent apply, and rollback. Never invoke root/system package managers
     or overwrite an unmanaged path.
  3. Add the full portable common Bash experience selected above. Install it
     through bounded managed blocks in remote startup files while preserving
     site initialization; apply only after every affected startup file passes
     non-interactive and interactive validation in the host plan.
  4. Add portable user tools only on supported targets. Use `uv` as an optional
     managed Python/tool layer after the shell-and-Git bootstrap. Keep drivers,
     MPI, CUDA, compilers, schedulers, modules, and uenv in site adapters. Keep
     project dependencies in project lockfiles or containers.
  5. Deploy one clean committed harness revision at a time, preferably through
     a Git bundle until an explicit push is authorized. Use the existing SSH
     agent; never distribute keys. Verify and, if necessary, roll back each
     host independently before advancing.
  6. Only after the current credential exposure is remediated, define a
     value-free secret-name contract and host-local injection adapter. Doctor
     may report a secret as present or missing but must never read or print its
     value.

  Next step: implement phase 1 locally, validate it against captured fixtures
  for the current node and six in-scope cluster environments, and present the
  exact per-host plan before any remote mutation.

## Planned

- **T-169 — Research advanced agent harness practices:**
  1. Freeze the present harness behavior and define evaluation criteria:
     correctness, autonomy, context efficiency, recovery, security,
     observability, portability, and measurable cost/runtime impact.
  2. In bounded research sessions, collect advanced public `CLAUDE.md` and
     `AGENTS.md` examples, including any authentic Karpathy material, from
     original repositories or authors. Record provenance, license, intended
     environment, and exact mechanisms instead of copying unattributed text.
  3. Review primary literature and authoritative technical reports on agentic
     planning, tool use, memory, delegation, verification, reflection,
     long-horizon execution, and multi-agent coordination. Confirm titles,
     authors, venue/year, and stable URLs, DOIs, or arXiv identifiers.
  4. Map each mechanism against the current harness's ledger, delegation,
     validation, safety, and portability behavior. Classify it as already
     covered, adopt, adapt, experiment, or reject, with benefits, failure
     modes, context/runtime cost, and evidence strength.
  5. Produce a cited source inventory, harness gap analysis, prioritized
     implementation proposals, and isolated benchmark designs.
  6. Independently verify material claims, separate evidence from inference,
     avoid license-incompatible copying, and turn approved proposals into
     bounded follow-up tasks with rollback and acceptance tests.

Do not modify the harness from research findings until the user reviews the
research plan and proposed changes.
