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

  - Clean non-interactive remote-command success: `ab`, `ab2`, `ri`, `rc`,
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
    `ab2`, `ri`, `al`, `rc`, and `t4`. `abci_login` and `alps_login` remain
    transport-only proxy nodes and receive no harness deployment.

  `ai4s` to `ri` replacement checkpoint (2026-07-14):

  - The user replaced the retired `ai4s` machine with SSH alias `ri`. `ai4s`
    is no longer an environment target and must not retain a deployable logical
    host profile. Historical `ai4s` evidence below remains as an audit record.
  - `ri` resolves to `login.rikyu.r-ccs.riken.jp` with account `rku0075`.
    Strict batch SSH reached the server but failed authentication with
    `Permission denied (publickey,hostbased)` before any remote command ran.
  - The local agent is healthy and `rc` still authenticates. SSH offered all
    four currently loaded identities to `ri`; the server accepted none. This
    rules out an unloaded/passphrase-locked agent and indicates that the new
    account needs a matching public key registered or the configured username
    corrected.
  - No `ri` file was read or changed. Remove the retired `ai4s` profile and
    fixture now, but do not guess a `ri` profile until a value-free inventory
    can run successfully. After owner-side access is fixed, the next native
    gate is `ssh -x -o BatchMode=yes -o StrictHostKeyChecking=yes ri true`.
  - The user corrected the account-side access. The exact strict gate now exits
    zero with no output. A self-contained inventory streamed to remote `sh`
    also completed without creating files: `ri` is Ubuntu 24.04 on AArch64,
    with Bash, Git, Python 3, Slurm, tmux, jq, tree, htop, and NVIDIA GPU
    exposure. It lacks the harness, ripgrep, SQLite, uv, Node/npm, both agent
    CLIs, rclone, lftp, and Tectonic.
  - Startup structure is `.bashrc` regular, `.bash_profile`/`.bash_login`
    absent, `.profile` regular, and `.bash_logout` regular. Add an explicit
    Ubuntu/AArch64/Slurm `ri` profile and captured fixture. Extend the shell
    transaction to append its login hook to the first existing Bash login file
    instead of creating a higher-precedence `.bash_profile` that would bypass
    `.profile`.

  `ri` convergence checkpoint (2026-07-14):

  - Added the Ubuntu 24.04/AArch64/Slurm profile and value-free fixture, removed
    the retired `ai4s` deployable profile/fixture, and taught shell transactions
    to select Bash's first existing login file. The full phase-1 suite includes
    isolated `.profile` apply/rollback coverage and passes.
  - Cloned a clean control plane at `b55629f` from a Git bundle whose local and
    remote SHA-256 was
    `21bb8c2be1e0ec392549bfb3833e479d559e25c5275c169ba0debd1040d59bd4`.
    Applied transaction `20260714T125539Z-1057040`; its repeated plan reports
    22 keeps and no unexpected path.
  - Applied shell transaction `20260714T125651Z-1058033`, deliberately rolled
    it back to the exact original `.bashrc`/`.profile` lengths and modes, then
    reapplied as `20260714T125728Z-1058618`. Both files have one managed suffix,
    retained owner/mode 100074:0644, and `.bash_profile` remains absent. A real
    login loads the common environment once without warnings.
  - Installed pinned AArch64 ripgrep 15.1.0 and uv 0.9.18 as transactions
    `20260714T125747Z-1059239` and `20260714T125748Z-1059238`. Both exact plans
    are now idempotent `managed-artifact` keeps; all transaction manifests and
    statuses are mode 600 and complete. No uv-managed Python directory was
    created.
  - Post-apply validation exposed two non-interactive PATH assumptions. Fixed
    managed-link discovery in `db1d177` and user-bin inventory in `eeb1e94`,
    each with a regression test that omits `~/.local/bin` from inherited PATH.
    Checksummed bundles fast-forwarded `ri` cleanly to each fix; their SHA-256
    values were `8cbef64c9565530d1d6ceaeb1610858ddd86754e34615ace8fc8d65ae0529fe3`
    and `2c3644b451dedd073add65d9cff41f4bb39b3ce16dbd7273d342249b9e5cb2e8`.
  - Final validation at `eeb1e94` reports clean Git state, idempotent control,
    shell, ripgrep, and uv plans, `failures=0 warnings=8`, silent strict SSH,
    and a real login running both pinned tools. The remaining warnings are the
    not-yet-implemented selected tool classes; the current node remains the
    only shell target blocked by plaintext credential rotation.

  Owner authorization checkpoint (2026-07-14):

  - The user explicitly authorizes the rollout to modify any remote file their
    account is permitted to edit on `ab`, `ab2`, `ri`, `al`, `rc`, and `t4`
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
  - After the five other cluster shells converged, a fresh sentinel/state audit
    with a 15-second connect timeout and SSH keepalives failed during banner
    exchange at `134.160.189.24:22`. No remote command started and no state was
    changed. This independently confirms that `ai4s` remains connectivity-
    blocked rather than merely missing a harness checkout.
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
  - The common shell layer is now converged on `ab`, `ab2`, `ri`, `al`, `rc`,
    and `t4`. The current node remains blocked because its plaintext `.bashrc`
    credentials must be rotated and removed before a managed shell transaction
    is considered.

  Portable-tool transaction checkpoint (2026-07-14):

  - Began with ripgrep 15.1.0 because every reachable target that lacks it has
    a first-party Linux release asset for its architecture. Recorded the
    official x86-64 musl and AArch64 GNU asset URLs and their publisher-provided
    SHA-256 values in `tools/artifacts.tsv`. Source:
    <https://github.com/BurntSushi/ripgrep/releases/tag/15.1.0>.
  - Implemented explicit `harness tool --host HOST --name ripgrep
    --plan|--apply`. Dry-run reports the native HTTPS fetch, checksum, exact
    archive member, versioned destination, and stable link. Apply requires a
    clean committed harness and passing doctor, verifies SHA-256 before
    extraction, extracts only the declared member, validates the version, and
    activates it through `~/.local/bin/rg`.
  - Extended all-path rollback for managed artifacts. It verifies the expected
    directory shape and installed binary hash before any mutation; a changed
    binary blocks removal of both artifact and link. Isolated tests exercise
    the exact plan, unsupported-artifact refusal, changed-binary refusal, and
    successful link/directory rollback without network access.
  - Independently downloaded both declared archives over TLS into temporary
    storage. Both SHA-256 checks passed, each archive contained exactly one
    declared `rg` member, the x86-64 binary reported `ripgrep 15.1.0`, and
    `file` identified the binaries as x86-64 static PIE and AArch64 GNU/Linux
    ELF respectively. The temporary verification directory was removed.
  - The first committed end-to-end isolated apply failed closed after download
    and extraction because the version validator expected the whole first line
    to equal `ripgrep 15.1.0`, while the binary appends a parenthesized revision.
    Automatic cleanup removed the staged artifact and temporary-home cleanup
    removed all test state. Restrict validation to the exact version prefix
    followed only by end-of-line or a space-delimited build suffix, then rerun
    the complete apply/rollback path before any remote pilot.
  - The corrected committed apply then passed end to end in a disposable home:
    it created a mode-755 binary and mode-600 complete transaction, reported
    the pinned release, produced an idempotent plan, and rollback removed both
    activation link and versioned directory. The disposable home was deleted.
    Refine the repeated plan to label the structurally matching stable link as
    `managed-artifact` rather than the less precise `host-provided`.
  - No remote tool has been installed yet. Next executable action: independently
    commit the implementation, transfer it to `ab2`, and perform the same
    plan/apply/rollback/reapply pilot used for the control plane and shell
    layer.

  `ab2` ripgrep pilot checkpoint (2026-07-14):

  - Fast-forwarded the clean `ab2` harness from `42e9a11` to `822d9c4` using a
    complete shared-home Git bundle with matching local/remote SHA-256
    `2ed0c79efac1f9a2cb67035af6731832d87573f01990a37aed915cd768a15a36`.
    The staging bundle was removed after transfer.
  - Preflight confirmed `rg` and both managed paths absent, with native
    `curl`, `sha256sum`, and `tar` available. The remote plan exactly matched
    the reviewed x86-64 URL, publisher checksum, versioned directory, and
    stable link.
  - Applied transaction `20260714T122652Z-97806`. The installed binary was mode
    755, reported `ripgrep 15.1.0 (rev af60c2de9d)`, and linked from
    `~/.local/bin/rg`. The mode-600 transaction was complete, download staging
    count was zero, the repeated plan reported `managed-artifact`, doctor
    warnings fell from nine to eight, and SSH remained silent.
  - Deliberate rollback removed both the stable link and exact versioned
    directory. The plan returned to `INSTALL`, doctor warnings returned to
    nine, and neither path remained. Reapplied cleanly as transaction
    `20260714T122725Z-961686`.
  - Final validation again reports the pinned version, a mode-600 complete
    transaction, an idempotent managed-artifact plan, `failures=0 warnings=8`,
    clean harness Git state, and silent non-interactive SSH.
  - Next safe action: fast-forward `ab`, `al`, `rc`, and `t4` to the committed
    tool revision, show their architecture-specific plans, and apply ripgrep
    one host at a time. Keep `ai4s` connectivity-blocked.

  Reachable-fleet ripgrep checkpoint (2026-07-14):

  - Audited `ab`, `al`, `rc`, and `t4`: each checkout was clean and `rg` plus
    both managed paths were absent. Fast-forwarded all four through a complete
    shared-home bundle whose local and remote SHA-256 was
    `1b4dff75d85416125175dbf9a1707f394a7418a4c7b3eef19a89d701200b6b34`.
  - All four architecture-specific plans were unblocked. Applied ripgrep
    transactions `ab` `20260714T122908Z-2059611`, `al`
    `20260714T122926Z-253490`, `rc` `20260714T122942Z-1915736`, and `t4`
    `20260714T123000Z-476119`. The AArch64 GNU binary executed successfully on
    `al`; the other three used the x86-64 static PIE asset.
  - Every transaction manifest/status is mode 600 and complete. All five
    reachable clusters (`ab`, `ab2`, `al`, `rc`, `t4`) report ripgrep 15.1.0,
    an idempotent `managed-artifact` plan, clean harness Git state, zero doctor
    failures, and silent non-interactive SSH.
  - Final warning counts are `ab` 8, `ab2` 8, `al` 10, `rc` 9, and `t4` 10.
    Each fell by exactly one from its pre-ripgrep baseline. `ai4s` received no
    checkout or tool mutation because its SSH banner remains unreachable.
  - Next executable action: commit this fleet evidence, fast-forward all five
    reachable checkouts to that one revision, then add the next independently
    sourced/checksum-verified artifact class to the same transaction engine.

  uv artifact checkpoint (2026-07-14):

  - Selected the observed local uv 0.9.18 as the next mirrored interface.
    Official uv documentation supports direct GitHub release binaries, and
    managed Python is explicitly a separate download surface. Sources:
    <https://docs.astral.sh/uv/getting-started/installation/> and
    <https://docs.astral.sh/uv/guides/install-python/>.
  - Recorded the publisher-provided x86-64 and AArch64 GNU/Linux asset URLs and
    SHA-256 values in the existing artifact manifest. Independently downloaded
    both archives over TLS: both checksums passed, each had exactly one declared
    `uv` member, the x86-64 binary reported `uv 0.9.18`, and `file` identified
    the expected x86-64 and AArch64 ELF interpreters. Temporary files were
    removed.
  - Added fixture coverage proving that the `al` profile selects the AArch64
    URL, checksum, and install target. This transaction installs only `uv`; it
    does not run the upstream installer, modify profiles, install `uvx`, or
    download a Python runtime.
  - A committed end-to-end transaction passed in a disposable home: uv 0.9.18
    downloaded, verified, installed, and reported `managed-artifact`; no uv
    Python directory appeared. Rollback removed the stable link and versioned
    directory, and the disposable home was deleted.
  - Next executable action: commit the isolated evidence, fast-forward `ab2`,
    then run a uv plan/apply/rollback/reapply pilot before any fleet rollout.

  `ab2` uv pilot checkpoint (2026-07-14):

  - Fast-forwarded `ab2` to `e0e5a54` with a complete bundle whose matching
    local/remote SHA-256 was
    `59e3c563b16d6853258f429a18478cf2cdddd458fd70b3740add0c09bf0dcf01`.
    Preflight found uv and its managed paths absent, with no uv Python directory,
    and selected the exact reviewed x86-64 asset/checksum.
  - Applied transaction `20260714T123353Z-1079736`. uv reported 0.9.18, the
    repeated plan reported `managed-artifact`, transaction files were mode 600
    and complete, doctor warnings fell from eight to seven, and no Python
    runtime was downloaded.
  - Deliberate rollback removed both the uv link and versioned directory,
    restored the `INSTALL` plan and eight-warning baseline, and left the absent
    Python directory unchanged. Reapplied as transaction
    `20260714T123414Z-1085400`.
  - Final validation reports uv 0.9.18, an idempotent managed-artifact plan,
    `failures=0 warnings=7`, mode-600 complete state, no uv-managed Python, and
    silent SSH.
  - Next safe action: fast-forward `ab`, `al`, `rc`, and `t4`, show their uv
    plans, and apply one host at a time; keep Python installation separate and
    keep `ai4s` blocked.

  Reachable-fleet uv checkpoint (2026-07-14):

  - Fast-forwarded `ab`, `al`, `rc`, and `t4` to the uv pilot revision through
    a complete bundle with SHA-256
    `6ff8a91db712d7b8167d8ea580f66a1ffc198d7a610adedec635b66f694b8c94`.
    All four plans were unblocked and selected the expected architecture.
  - Applied uv transactions `ab` `20260714T123533Z-2871307`, `al`
    `20260714T123535Z-74225`, `rc` `20260714T123537Z-1964222`, and `t4`
    `20260714T123540Z-639983`. Every manifest/status pair is mode 600 and
    complete; the AArch64 binary executes successfully on `al`.
  - All five reachable clusters report uv 0.9.18, an idempotent
    `managed-artifact` plan, zero doctor failures, and silent SSH. Warning
    counts are now `ab` 7, `ab2` 7, `al` 9, `rc` 8, and `t4` 9.
  - `t4` had a pre-existing `~/.local/share/uv/python` directory before uv was
    installed; it remains present and was not inspected or modified. The other
    four still have no uv Python directory, confirming that the artifact
    transaction did not implicitly download Python.
  - Next executable action: checkpoint and synchronize this evidence, then
    design managed Python 3.12 as its own pinned, rollback-aware transaction or
    add another self-contained selected tool artifact. `ai4s` remains blocked.

  rclone artifact implementation checkpoint (2026-07-14):

  - Selected the observed local rclone 1.74.3 as the next self-contained layer.
    The official release directory publishes Linux AMD64 and ARM64 ZIP archives
    and a release-wide `SHA256SUMS` file:
    <https://downloads.rclone.org/v1.74.3/>. All six cluster targets have native
    `unzip`; `ab` and `ab2` already provide rclone, so only `ri`, `al`, `rc`,
    and `t4` need a managed artifact.
  - Independently downloaded both official archives over TLS. Their SHA-256
    values matched the publisher file, each archive contained the same six-file
    layout, and exact-member extraction produced one static executable. The
    AMD64 binary reported rclone 1.74.3; `file` identified the second binary as
    AArch64. Temporary verification files were removed.
  - Extended the existing transaction engine to accept only `tar.gz` or `zip`,
    reject wildcard member paths, report the exact native extraction command,
    and use `unzip -p` to materialize only the declared ZIP member. The same
    checksum, version, single-file directory, mode-600 state, managed-link, and
    all-path rollback gates remain in force.
  - Added both architecture records and plan assertions. An offline fixture
    exercises ZIP apply, idempotent discovery outside inherited PATH, and exact
    rollback without network. A disposable-home transaction against the real
    AMD64 release then installed a mode-755 rclone 1.74.3 binary, produced
    mode-600 complete state, returned an idempotent managed plan, and rolled
    back both paths exactly. The full phase-1 suite passes.
  - Next executable action: commit this implementation, checksum-transfer it to
    `ri`, show the exact ARM64 plan, and perform apply/rollback/reapply as the
    architecture pilot. If all gates pass, roll out one host at a time to `al`,
    `rc`, and `t4`; retain the host-provided rclone on `ab` and `ab2`.

  `ri` rclone pilot checkpoint (2026-07-14):

  - Committed the implementation as `701517f` and fast-forwarded the clean `ri`
    checkout through a bundle whose local and remote SHA-256 was
    `a6b4dd1318a6e4b3a89ed68d00cac7280e30ddc547d23d1e6d51ebf0e95f661a`.
    Preflight found native `unzip`, no rclone command, and both managed paths
    absent; the exact ARM64 plan matched the reviewed URL, checksum, and member.
  - Applied transaction `20260714T131350Z-1063085`. The AArch64 binary executed
    and reported rclone 1.74.3, the repeated plan reported `managed-artifact`,
    doctor warnings fell from eight to seven, transaction files were mode 600
    and complete, no staging remained, and strict SSH stayed silent.
  - Deliberate rollback removed only the stable link and exact versioned
    directory, restored the eight-warning baseline and original `INSTALL` plan,
    then reapply completed as `20260714T131418Z-1064064`. Final validation again
    passes the version, idempotence, private-state, clean-Git, silent-SSH, and
    real-login gates with the common shell guard loaded once.
  - Next executable action: commit this pilot evidence, fast-forward clean
    `al`, `rc`, and `t4` checkouts with one checksum-verified bundle, show each
    architecture-specific plan, then apply and validate one host at a time.

  Reachable-fleet rclone checkpoint (2026-07-14):

  - Fast-forwarded clean `al`, `rc`, and `t4` checkouts to the pilot-evidence
    revision with one complete bundle whose local and remote SHA-256 was
    `f2309f8ab259adb538449bf744b0391c178bd2b91b13bacd9b262c782aab3c9d`.
    All exact plans matched their architecture and preflight found no collision.
  - Applied rclone transactions `al` `20260714T131606Z-290742`, `rc`
    `20260714T131625Z-2295042`, and `t4` `20260714T131651Z-1849980`. Each binary
    reports rclone 1.74.3, each repeated plan reports `managed-artifact`, and
    every manifest/status pair is mode 600 and complete.
  - Fast-forwarded clean `ab`, `ab2`, and `ri` checkouts without changing their
    tool state. Final fleet validation at `d6d9376` reports host-provided rclone
    1.72.1 on `ab`/`ab2`, managed 1.74.3 on `ri`/`al`/`rc`/`t4`, zero doctor
    failures, clean Git state, idempotent plans, and silent strict SSH on all
    six targets. Warning counts are `ab` 7, `ab2` 7, `ri` 7, `al` 8, `rc` 7,
    and `t4` 8.
  - Next executable action: checkpoint and synchronize this evidence, then
    design Node 24.16.0/npm 11.13.0 as a separately pinned multi-file runtime
    transaction. Do not force the single-binary artifact engine to manage the
    Node distribution tree or install either agent CLI before Node/npm rollback
    and PATH behavior are independently validated.

  Node/npm artifact verification checkpoint (2026-07-14):

  - Selected the observed local Node 24.16.0/npm 11.13.0 pair. The official
    release archive publishes signed SHA-256 sums and Linux x64/ARM64 tarballs:
    <https://nodejs.org/download/release/v24.16.0/>. The recorded tar.gz hashes
    are `2faf6a387e9b62b888e21c54f01249fb27537ffecf1842f29f4c919d0a59a0ff`
    for x64 and
    `589f5b6dd4fcfee4dfda73013903c966abaa8abd93dbc9d436544e472b4f0e74`
    for ARM64.
  - Independently downloaded both archives over TLS and matched those hashes.
    Each contains exactly one 5,729-entry distribution root and the expected
    `bin/node`, `bin/npm`, `bin/npx`, and `bin/corepack` entries. The x64 tree
    reports Node 24.16.0 and npm 11.13.0; `file` identifies the second Node
    executable as AArch64 using `/lib/ld-linux-aarch64.so.1`. Temporary files
    were removed.
  - Treat Node as a multi-file runtime, not a single-binary artifact. The
    transaction must own one versioned distribution tree, create four explicit
    stable links, validate both Node and npm versions with the staged `bin` at
    the front of PATH, store a compact whole-tree integrity record, and refuse
    rollback if any tree entry or activation link changed. Apply, rollback, and
    cleanup must remain all-path atomic.
  - Next executable action: implement `harness runtime --host HOST --name node
    --plan|--apply` with an isolated offline archive fixture. Prove changed-tree
    rollback refusal and exact clean rollback before any real or remote apply;
    then run a disposable-home transaction against the official x64 archive.

  Node/npm runtime implementation checkpoint (2026-07-14):

  - Implemented a dedicated `harness runtime --host HOST --name node
    --plan|--apply` transaction and strict two-architecture runtime manifest.
    It owns only `~/.local/opt/node/24.16.0/linux-ARCH` and four stable links;
    an existing host Node/npm pair is retained, while partial or colliding
    states block instead of being overwritten.
  - Apply requires a clean harness and passing doctor, verifies the publisher
    SHA-256, rejects archive entries outside the one declared root, validates
    exactly three internal symlinks remain inside the staged tree, and checks
    Node 24.16.0 plus npm 11.13.0 before activation. It records a compact tar
    digest of the complete 5,729-entry tree and mode-600 transaction state.
  - Extended all-path rollback for managed runtime trees. It validates all four
    activation links and recomputes the complete tree digest before any
    mutation. The offline fixture deliberately changed one runtime file;
    rollback failed without removing any link or tree, then metadata-exact
    restoration allowed complete removal. The full phase-1 suite passes.
  - A disposable-home transaction downloaded the official x64 archive, created
    a mode-755 Node binary and mode-600 complete state, reported both pinned
    versions, returned an idempotent `managed-runtime` plan, and rolled back all
    four links and the complete tree. The disposable home was removed.
  - Next executable action: commit this implementation, fast-forward `ri`, show
    the exact ARM64 plan, and perform apply/rollback/reapply as the architecture
    pilot. Do not install Codex or Claude until Node/npm is validated across the
    fleet and their own package integrity/state boundaries are designed.

  `ri` Node/npm pilot checkpoint (2026-07-14):

  - Committed the runtime implementation as `922a138` and fast-forwarded the
    clean `ri` checkout through a bundle whose local and remote SHA-256 was
    `1813d3cabd7f17bf5f83b1f0b81da149bb98b0530f28673491ce14febc0fa7fb`.
    Preflight found Node/npm and all five managed paths absent; the ARM64 plan
    matched the reviewed URL, checksum, tree, and four links.
  - Applied transaction `20260714T134013Z-1067663`. Node reported 24.16.0, npm
    11.13.0, the repeated plan reported `managed-runtime`, transaction state
    was mode 600 and complete, doctor warnings fell from seven to five, and the
    checkout remained clean.
  - Deliberate whole-tree rollback validated the digest, removed all four links
    and the exact distribution tree, restored the seven-warning baseline and
    original install plan, then reapply completed as
    `20260714T134052Z-1070696`. The final state again passes version,
    idempotence, state-permission, and clean-Git gates.
  - Next executable action: commit this pilot evidence, fast-forward the other
    five cluster checkouts, retain any complete host-provided Node/npm pair, and
    apply one host at a time only where both commands and all managed paths are
    absent.
  - Fleet rollout applied successfully on `ab` (`20260714T134246Z-3141332`),
    `ab2` (`20260714T134301Z-3039291`), and `al`
    (`20260714T134317Z-258033`), then stopped safely during `rc` staging. The
    checksum and extraction passed, but the containment check compared the
    logical home path with `readlink -f`'s physical filesystem path and falsely
    reported `runtime link escapes staged tree: npm`. Automatic cleanup left no
    Node command, runtime tree, activation link, or staging directory on `rc`;
    `t4` was not attempted.
  - Fixed containment to compare the resolved link against the canonical staged
    root. The offline runtime test now places HOME behind a symlink and passes
    apply, changed-tree refusal, and rollback, reproducing the filesystem shape
    that exposed the defect. Next commit and fast-forward this narrow fix, then
    retry `rc` before advancing to `t4`.

  Reachable-fleet Node/npm checkpoint (2026-07-14):

  - Committed the canonical-path fix as `e8cd1db`, verified bundle SHA-256
    `68d76ed622f5bb978208b9a2d9a03147ad638aa71dde7f4a1621f50305dd6c40`,
    and retried `rc` successfully before advancing to `t4`. Final transactions
    are `ab` `20260714T134246Z-3141332`, `ab2`
    `20260714T134301Z-3039291`, `ri` `20260714T134052Z-1070696`, `al`
    `20260714T134317Z-258033`, `rc` `20260714T134608Z-2570586`, and `t4`
    `20260714T134633Z-2638939`.
  - All six clusters report Node 24.16.0 and npm 11.13.0, an idempotent
    `managed-runtime` plan, mode-600 complete transaction state, clean harness
    Git state, zero doctor failures, and silent strict SSH. Warning counts are
    now `ab` 5, `ab2` 5, `ri` 5, `al` 6, `rc` 5, and `t4` 6. The current node
    already provides the same Node/npm versions and was not shadowed.
  - Next executable action: checkpoint and synchronize this evidence, then add
    managed Python 3.12 as an explicit uv operation with per-host preflight.
    Preserve `t4`'s pre-existing uv Python state and do not infer its contents;
    design adoption/refusal behavior before any Python mutation there.

  Managed Python implementation checkpoint (2026-07-14):

  - uv 0.9.18's exact CLI and official documentation support a custom
    `--install-dir`, `--no-bin`, and disabled configuration discovery. A
    disposable layout probe selected CPython 3.12.12, produced one
    architecture-specific installation, and passed SSL, SQLite, architecture,
    and base-prefix checks. The harness therefore owns a separate
    `~/.local/opt/python/3.12/linux-ARCH` tree and only a `python3.12` link; it
    neither shadows `python`/`python3` nor touches uv's default directory.
  - Implemented `harness python --host HOST --minor 3.12 --plan|--apply` with
    exact uv-version gating, staged no-cache installation, patch/architecture
    and standard-library validation, mode-600 transaction state, managed-link
    discovery, and all-path rollback. An offline symlinked-HOME fixture proves
    changed-tree refusal and exact cleanup.
  - The first official-archive disposable apply installed and ran Python
    3.12.12 correctly, but rollback failed closed after the validation imports
    generated normal `__pycache__` files inside the standard library. The
    disposable home was removed. Refine integrity to cover every non-cache tree
    entry while excluding only derived `__pycache__`, `.pyc`, and `.pyo`; add a
    generated-cache rollback test and repeat the official trial before commit.
  - Normalized Python integrity records now sort paths and normalize archive
    metadata while excluding only generated bytecode-cache paths. The offline
    test proves a source/executable edit still blocks without partial mutation
    and that an added `__pycache__/module.pyc` permits exact rollback. The
    repeated official trial imported SSL and SQLite, retained an idempotent
    managed plan, then removed the link and complete tree successfully.
  - Next executable action: commit the managed-Python implementation, pilot
    apply/rollback/reapply on ARM64 `ri`, and validate exact patch,
    architecture, SSL, SQLite, prefix, state permissions, silent SSH, and no
    writes beneath uv's default Python directory.
  - The first live ARM64 pilot installed correctly on `al` as transaction
    `20260714T135818Z-57995`, but rollback again failed closed after final-path
    execution changed exactly one non-cache file:
    `_sysconfigdata__linux_aarch64-linux-gnu.py`. A disposable second uv install
    and recursive content comparison found no other difference; `.gitignore`
    and `.lock` also matched. This is relocation state created because the
    integrity digest was recorded while the interpreter still lived under its
    staging prefix.
  - Move activation before the final validation and digest, while retaining
    cleanup ownership if any post-move gate fails. Extend the offline fixture
    to rewrite a relocation-state file from its executable path, proving the
    final digest is recorded only after activation. Then repair only the
    agent-created pilot manifest hash from the independently observed current
    tree, exercise rollback, and reapply with the corrected transaction.
  - Corrected the activation order and committed it as `91948f9`. On `al`, the
    repaired first-pilot manifest then rolled back exactly; corrected
    transaction `20260714T140211Z-131352` survived final-path execution and
    SSL/SQLite imports, rolled back exactly, and final transaction
    `20260714T140353Z-164269` restored CPython 3.12.12 on AArch64. The uv
    default Python directory remained absent throughout.
  - Fleet presence-only preflight found host-provided Python 3.12.3 on `ri`,
    so it must remain unshadowed. `ab`, `ab2`, `rc`, and `t4` have no
    `python3.12` command or managed Python path. The uv default Python path is
    absent on the first three and pre-existing on `t4`; do not enumerate or
    modify it. Synchronize the corrected transaction code, apply one host at a
    time, and prove `t4`'s default-path type is unchanged before and after.
  - Synchronized clean revision `4509be7` to all six clusters from complete
    bundle SHA-256
    `0c033e42ccfc98530cd88f24398b0422558b4967c8ca95243633ccdc41c4f26d`.
    Installed CPython 3.12.12 serially as transactions `ab`
    `20260714T140609Z-3238657`, `ab2` `20260714T140630Z-2607267`, `rc`
    `20260714T140650Z-2757791`, and `t4` `20260714T140714Z-3209289`; `al`
    retains final transaction `20260714T140353Z-164269`. `ri` and the current
    node retain their host-provided Python 3.12.3.
  - Final seven-environment closure passed exact version/architecture,
    SSL/SQLite, base-prefix, idempotent source selection, clean Git, and doctor
    gates. All six strict `ssh -x` no-op gates were silent. The uv default path
    stayed absent on `ab`, `ab2`, `al`, and `rc`, and stayed a pre-existing
    uninspected directory on `t4`. Next inventory the LLM/HPC development
    surfaces—compiler/build/debugger, accelerator driver/toolkit, MPI,
    scheduler, modules/uenv, and containers—before selecting any portable
    additions or site-native smoke tests.
  - Login-node LLM/HPC inventory found GCC/G++/Fortran, Make, CMake,
    pkg-config, and GDB on all seven environments. Native CPU compiler tests
    are therefore safe to standardize, but MPI, CUDA, scheduler, and container
    tests must remain site-aware. `ab`, `ab2`, `t4`, and the current node expose
    default MPI; `ri`, `al`, and `rc` require a compute image, uenv, or module.
    `al` publicly lists GNU/OpenMPI and PyTorch uenv images, confirming that a
    generic user MPI or global PyTorch install would conflict with site policy.
  - `ab` and `ab2` have an unusable `/usr/local/bin/ninja` Python shim that
    exits with `ModuleNotFoundError: ninja`; `al`, `rc`, and `t4` have no Ninja.
    The current node and `ri` have working Ninja 1.11.1. Add official Ninja
    1.13.2 x86-64 and AArch64 ZIP artifacts using GitHub-published SHA-256
    digests, retain healthy host commands, and shadow only absent or failing
    commands through `~/.local/bin`. Managed version or health mismatches must
    block rather than be silently replaced.
  - Added value-free compiler/build/debugger/MPI/accelerator discovery and
    Ninja health state, plus deterministic C, C++/OpenMP, Fortran, MPI, CUDA,
    and standard-library Python smoke sources. The complete offline phase-1
    suite passes; direct native CPU builds and Python execution pass locally.
    Pilot Ninja apply/rollback/reapply on `ab` before the remaining missing or
    broken hosts.
  - The `ab` pilot installed transaction `20260714T141649Z-3281200`, validated
    Ninja 1.13.2, rolled back to the original failing site shim exactly, and
    reapplied final transaction `20260714T141651Z-3281873`. A same-process
    final check initially reused Bash's cached `/usr/local/bin/ninja`; a fresh
    strict session resolved the managed binary and all state/permission gates
    passed. Report native caller command `hash -r` after link creation and add
    regression coverage before continuing the fleet rollout.
  - Synchronized the cache-refresh revision `ec3d81b`, then installed final
    Ninja 1.13.2 transactions `ab2` `20260714T141842Z-2698713`, `al`
    `20260714T141853Z-173294`, `rc` `20260714T141904Z-2862193`, and `t4`
    `20260714T141918Z-3572846`. Each passed exact version, architecture where
    relevant, mode-600 state, idempotent managed plan, and clean Git checks.
    The current node and `ri` deliberately retain healthy host Ninja 1.11.1.
  - Added an out-of-tree CMake project for the deterministic CPU sources. Local
    native `cmake -G Ninja`, build, and CTest passed C, C++/OpenMP, and Fortran;
    synchronize this test definition and run the same commands on every login
    environment before proceeding to site-native MPI/GPU allocations.
  - Outstanding site evidence: the current node's `nvidia-smi` wrapper targets
    a missing `/usr/bin/nvidia-smi`; `ri` exposes four GB200 GPUs but its Slurm
    client cannot currently resolve a controller; `t4` exposes CUDA/MPI tools
    on the login node but no active NVIDIA driver there. Determine the intended
    native compute-node route for each before interpreting login-node GPU or
    scheduler results as workload readiness.
  - The identical out-of-tree CMake/Ninja/CTest sequence now passes C,
    C++/OpenMP, and Fortran on all seven environments; standard-library Python
    also passes everywhere. Compiler observations are GCC 11.5 on `ab`, `ab2`,
    `rc`, and `t4`; 13.3 on the current node and `ri`; and 7.5 on `al`. These
    are validated site baselines, not interchangeable ABI requirements.
  - A true login-context scheduler probe corrected the earlier non-login
    inventory: `ab` and `ab2` expose PBS Pro 2022.1.6 plus `nodestatus`; `t4`
    exposes AGE `qsub`/`qstat`/`qrsh`; `ri`, `al`, and `rc` have reachable Slurm
    controllers. Update the `ab`/`ab2` profiles from `none-observed` to PBS Pro
    and the `t4` profile from generic PBS to AGE. Preserve context-dependent
    absence in the original fixtures rather than pretending the commands are
    available before site login initialization.
  - Do not submit ABCI or TSUBAME compute smoke jobs until the owner selects the
    billing group: both sites require an explicit group and resource request,
    and even a one-minute validation can consume project points. Continue with
    non-chargeable readiness checks and site-native Slurm tests where the
    account has an unambiguous default allocation.
  - `ri` default Slurm allocation passed a one-minute GB200 driver/Python smoke:
    GB200, driver 580.159.03, compute capability 10.0. Neither `nvcc` nor MPI is
    present on the compute base image; login context supplies Apptainer 1.4.5
    and Slurm OCI flags, so LLM/CUDA/MPI dependencies belong in a project image.
  - `rc` is heterogeneous across login and compute architectures. One-minute
    native probes found an AArch64 GH200 480 GB node with driver 610.43.02 and
    an AArch64 FX700 node, but neither base image exposes CUDA or MPI wrappers.
    Do not execute the login node's x86-64 managed Python on those partitions;
    add partition-specific module/container selection when a project chooses
    its target architecture.
  - Current-node job `90624` passed A4500 driver/CUDA runtime and Python, but
    `srun --ntasks=2` started two Open MPI rank-1 singletons because no PMIx
    server was reachable. Tighten `mpi.c` to require exactly two ranks and use
    native `mpirun -n 2` inside this single-node allocation. The `ybatch`
    wrapper also places extra arguments after its generated script, so `--wait`
    and CLI output options are not scheduler options; declare a job-ID-scoped
    output in the tracked script, monitor the parsed job ID, and clean exactly
    that output after validation.
  - Current-node retry job `90625` passed the tightened end-to-end gates on an
    RTX A4500: driver 595.58.03, compute capability 8.6, CUDA kernel, exactly
    two MPI ranks via `mpirun`, and Python. Its known output and the wrapper's
    accidental literal directory were removed. Use `.harness-smoke/%j.out`
    going forward because `ybatch` misclassifies a bare output filename as a
    directory; remove the job-scoped file and empty directory after validation.
  - Begin the portable agent-command layer without touching authentication or
    settings. Claude Code 2.1.207 publishes single native x86-64 and AArch64 npm
    artifacts; downloaded bytes match npm's published SHA-512 integrity values,
    recorded SHA-256 values are
    `862d403aa07a49548215fb8b1255cb5a66fd31601e33e13bc8e6925526d242c0`
    and `02c381be3269489119287dc0b5f4b99b870d886f058918994b51e06b701dd1be`,
    and disposable x86 execution reports 2.1.207. Add them as exact-member
    tool transactions, pilot rollback/reapply on AArch64, then roll out.
  - Claude rollout final transactions are `al` `20260714T143426Z-239659`, `ab`
    `20260714T143445Z-1914635`, `ab2` `20260714T143459Z-2829245`, `ri`
    `20260714T143512Z-1085564`, `rc` `20260714T143544Z-3003718`, and `t4`
    `20260714T143550Z-4014179`. Exact direct execution, managed plans, and
    mode-600 completed state pass on all six, and local retains its healthy
    host-provided 2.1.207. Interactive-login closure exposed one real ordering
    defect on `t4`: a project path supplied Claude 2.1.128 before the managed
    2.1.207 path. Refined the silent portable profile to remove duplicate
    `~/.local/bin` entries and prepend exactly one; an offline regression keeps
    the order of every other PATH entry. Synchronize and prove normal login
    shells resolve managed Claude and Codex on all six before closing this
    agent layer. No authentication or live agent state was read or copied.
  - Codex CLI 0.144.4 is not a single-binary npm artifact: it has a small
    launcher and one architecture resource package containing the native
    binary, code-mode host, ripgrep, sandbox helper, and shell resource. npm's
    published SHA-512 values match downloaded root/x86-64/AArch64 bytes; their
    recorded SHA-256 values are
    `613aadb30be4b6a6daa45cbd086f5d4a84636bcd8c036510c106464bd087f193`,
    `9a4a45314e80b53c4761b80067e3a68c2302f9a9026059b5f54f22dec8f34323`,
    and `38461c769ce95e734a4200bb5e7aac8bbe8a8052603d648eae4afaa26ac066a7`.
  - Added `harness agent --host HOST --name codex --plan|--apply` with two
    checksum gates, safe regular-file-only extraction into an exact owned
    `node_modules` layout, Node 24.16.0 gating, launcher validation, normalized
    whole-tree integrity, mode-600 state, and all-path rollback. Offline tests
    prove idempotence, caller cache reporting, changed-tree refusal without
    partial mutation, and exact cleanup. A real official-archive disposable
    x86-64 transaction (`20260714T144309Z-446045`) also passed checksum,
    execution, managed-state, mode-600, and exact rollback checks while
    preserving its pre-existing Node link. The `ri` AArch64 pilot passed
    rollback/reapply (`20260714T144528Z-1087203` rolled back; final
    `20260714T144536Z-1089642`). Serial final transactions are `al`
    `20260714T144559Z-190488`, `ab` `20260714T144610Z-3392759`, `ab2`
    `20260714T144622Z-3394138`, `rc` `20260714T144632Z-3101084`, and `t4`
    `20260714T144646Z-412525`. Fleet closure passed exact 0.144.4 execution,
    interactive-login discovery, managed planning, mode-600 completed state,
    clean revision `8e145dc`, and doctor with zero failures; local retains its
    healthy host-provided 0.144.4. No Codex authentication, settings, sessions,
    caches, or logs were read or copied.
  - Tectonic 0.16.9 publishes one-file static musl artifacts for both fleet
    architectures. GitHub's per-asset digests and independent downloads agree:
    x86-64 is
    `60b13a0826ae7ad9ce34b4a2df06bff2cfcfa6dda8a915477c0cbb84e1a4a902`
    and AArch64 is
    `f9aa39017dbd51f111fdb93dda222178cbe51c8193508fc567b523cc74fff9c1`.
    The checksum gate rejected an initial x86 URL/digest pairing that used the
    neighboring GNU asset's digest; temporary files were removed and the exact
    musl pair then passed checksum, member, version, and ELF-architecture
    checks. Root-member tar extraction now materializes only the declared
    member and has offline apply/rollback coverage. Real disposable x86-64
    transaction `20260714T145706Z-604010` passed checksum, exact version,
    managed planning, mode-600 state, a fresh isolated-cache TeX-to-PDF compile,
    and exact rollback while preserving a pre-existing sentinel. Pilot
    rollback/reapply on AArch64 passed (`ri` first
    `20260714T145921Z-1097328`, final `20260714T145922Z-1097899`). Serial final
    transactions are `al` `20260714T150033Z-129107`, `ab`
    `20260714T150106Z-2024317`, `ab2` `20260714T150155Z-4078071`, `rc`
    `20260714T150244Z-3272728`, and `t4` `20260714T150336Z-848604`. Every host
    passed a fresh isolated-cache TeX-to-PDF compile, exact version, normal-login
    discovery, managed planning, mode-600 completed state, clean Git, and zero
    doctor failures. The AArch64 pilot emitted a non-fatal missing-default
    Fontconfig warning but downloaded its declared font and produced a valid
    PDF; no temporary cache or smoke output was retained.
  - Git LFS 3.7.1 is a strong LLM-project follow-up: the official security-fix
    release has publisher-digested x86-64 and AArch64 binaries. Independent
    downloads match the publisher values
    `1c0b6ee5200ca708c5cebebb18fdeb0e1c98f1af5c1a9cba205a4c0ab5a5ec08`
    and `73a9c90eeb4312133a63c3eaee0c38c019ea7bfa0953d174809d25b18588dd8d`;
    exact-member extraction reports static binaries for both architectures.
    Presence-only fleet preflight found 3.7.1 on `rc`, older 3.4.1 on `ri`, and
    absence elsewhere. Add a security feature floor that retains 3.7.1 or
    newer and visibly shadows older commands. Offline tests cover absent,
    insecure-old, exact-current, future-newer, and both architecture plans.
    Real disposable x86-64 transaction `20260714T151032Z-718054` passed exact
    extraction/version, Git subcommand dispatch, local pointer generation,
    managed planning, mode-600 state, and exact rollback; `.gitconfig` remained
    absent and a pre-existing sentinel survived. Keep binary installation
    separate from hook/filter activation: never run `git lfs install`
    implicitly, and use explicit project-local activation only when that
    repository is in scope. AArch64 `ri` pilot transaction
    `20260714T151201Z-1100634` rolled back to the unchanged site 3.4.1 binary;
    final `20260714T151202Z-1101328` restored managed 3.7.1. Other final
    transactions are local `20260714T151224Z-733331`, `al`
    `20260714T151248Z-204303`, `ab` `20260714T151251Z-31276`, `ab2`
    `20260714T151255Z-3531290`, and `t4` `20260714T151300Z-1087921`; `rc`
    retains host-provided 3.7.1. All seven pass normal-login Git dispatch,
    pointer generation where installed, idempotent source selection, clean Git,
    and zero doctor failures. Git-config metadata stayed unchanged across every
    apply, and neither global nor project-local activation was run.
  - Source-build prerequisite inventory found no safe uniform dependency floor
    for lftp, tmux, or htop: `ri` and `al` lack different pkg-config development
    libraries. Do not create a second bundled package manager merely to erase
    those warnings. SQLite is a narrow exception because its publisher supports
    the self-contained amalgamation and every environment already passed a C
    compiler baseline.
  - SQLite 3.53.3's official amalgamation matched publisher SHA3-256
    `d45c688a8cb23f68611a894a756a12d7eb6ab6e9e2468ca70adbeab3808b5ab9`;
    its independently recorded SHA-256 is
    `646421e12aac110282ef8cc68f1a62d4bb15fc7b8f09da0b53e29ee690500431`.
    Exact four-file extraction plus the displayed native C build produced a
    3.53.3 CLI passing in-memory JSON, FTS5, and RTree tests. Add a dedicated
    source-build transaction with offline compile, tamper-refusal, and rollback
    coverage. Real official-source disposable transaction
    `20260714T152202Z-838785` built with system SQLite hidden, passed exact
    version and all three feature gates, returned a managed plan with mode-600
    state, and rolled back exactly while preserving a sentinel. Two preceding
    disposable runners completed the build/rollback but omitted `tee` and then
    `cat` from their artificial PATH; both temporary homes were removed and the
    complete repeated trial passed. The first `ri` post-build runner then used
    incorrectly nested JSON quoting and stopped after successful transaction
    `20260714T152355Z-1103259`; read-only diagnosis proved the build healthy.
    A quote-free equivalent feature probe validated it, rollback removed it
    exactly, and final AArch64 transaction `20260714T152459Z-1103991` passed.
    `al` final transaction is `20260714T152545Z-200303`. Both owned trees retain
    only `sqlite3`; the other five environments retain feature-complete site
    commands. Fleet closure passes JSON, FTS5, RTree, clean Git, idempotent
    source selection, and zero doctor failures everywhere.
  - Direct compile/link probes confirmed that lftp cannot share a safe source
    build floor: `ri` lacks OpenSSL headers/libraries, while `ab`, `ab2`, `rc`,
    and `t4` lack Expat and Readline link support; `al` is the only remote with
    all four probed dependencies. Keep lftp as an explicit site-native gap. Do
    not ship a no-TLS client or vendor a private dependency stack merely to
    remove one doctor warning.
  - Added the reusable `operate-native-hpc` personal skill. It requires visible
    native scheduler/environment/container commands, explicit account/group
    decisions, compute-node evidence, exact job-ID monitoring and cleanup,
    rank/world-size validation, bounded LLM forward/backward gates, and matched
    performance evidence. Its site reference records the validated ybatch,
    PBS Pro, Slurm/uenv, heterogeneous-architecture, and AGE constraints without
    account values. The skill contains no scheduler wrapper or executable
    automation. `quick_validate.py`, placeholder inspection, and the complete
    phase-1 suite pass; `install.sh` created the three local discovery links.
    Commit `9a59b34` added it. The `ri` rollback pilot
    `20260714T153221Z-1107889` and final transaction
    `20260714T153221Z-1108545` passed; final transactions on `ab`, `ab2`, `al`,
    `rc`, and `t4` are `20260714T153243Z-3605318`,
    `20260714T153246Z-2215045`, `20260714T153247Z-156743`,
    `20260714T153249Z-3543456`, and `20260714T153251Z-1615711`. Each created
    exactly the three intended links and immediately returned an idempotent
    plan. A first independent audit runner was read-only but incorrectly
    expanded its local home while constructing the remote command; discard its
    result. The corrected literal-script audit passed on `ab`, `ab2`, `ri`, and
    `al`, then exposed a real `rc` portability defect: its home has equivalent
    `/home/users/...` and `/hs/work0/home/users/...` mount paths, and invocation
    through the managed command used `readlink -f` to falsely block every
    correct lexical link. Commit `47897e0` now preserves a symlink's lexical
    target before canonical fallback, and a disposable aliased-checkout
    apply/managed-plan/rollback regression passes in the full transactional
    suite. The first `ab` update attempt ran `git bundle verify` outside its
    checkout and stopped before fetch; its cleanup trap removed the staged file.
    A corrected retry fast-forwarded all six clean checkouts from the complete
    bundle with matching SHA-256
    `60e54e96ede3026e243622c946cc45c3265ae2eac919ffc2fa5e923b1d428243`.
    The repeated fresh seven-environment closure invoked the managed harness,
    resolved all three skill links exactly, found zero creates, blocks, or
    doctor failures, confirmed clean revision `47897e0`, mode-600 complete
    transaction state on every remote, and no staged bundle. The reusable
    native-HPC workflow is deployed and validated.
  - LLM/HPC environment-entry audit confirmed that all seven environments have
    `uv`, Python 3.12, C/C++/Fortran, CMake, and Ninja. Disposable, isolated
    `uv venv` runs with `UV_PYTHON_DOWNLOADS=never`, an isolated cache, and the
    standard-library smoke passed on every target and removed their temporary
    trees; current and `ri` retain healthy site Python 3.12.3 while the other
    five use managed 3.12.12. Login MPI/CUDA wrappers are present on current,
    `ab`, `ab2`, and `t4`; `ri`, `al`, and `rc` correctly require their
    site/project environment for those layers. No framework was installed
    globally.
  - A fresh `ri` login and live value-free inventory now expose Singularity
    compatibility plus Apptainer 1.4.5, so replace its stale `container=none`
    profile and fixture. Generalize safe container inventory from presence to
    native `--version` health, with explicit `unusable` planning evidence.
    This revealed that the current node's root-owned Docker/Podman wrapper
    forces `/run/user_slurm/UID` and exits 1 on the login node even though the
    login runtime directory is valid. Do not bypass its site storage policy.
    Native `ybatch tests/smoke/jobs/local.slurm` job `90627` proved both wrapper
    entry points report Podman 5.2.4 inside the allocation, then passed an A4500
    CUDA kernel, two-rank MPI reduction, and Python smoke in four seconds with
    exit `0:0`. Only its job-scoped output and empty directory were removed; no
    image was selected, pulled, or run. Add this allocation-context rule to the
    native-HPC skill, keep current login facts `unusable`, and validate the
    revised profile/inventory behavior fleet-wide. Commit `dc43fca` implements
    those changes and passed shell syntax, the complete phase-1 suite, and skill
    validation. All six clean checkouts were fast-forwarded from the complete
    bundle with SHA-256
    `f9983c6cee57bae590d043658f0a1d511f70b233475ea3bd23729ff9aa5a0aae`.
    Fresh login inventories match every container profile with zero warnings on
    the six clusters: `ab`/`ab2` have Singularity and Podman, `ri` has
    Singularity/Apptainer, `al` has Docker/Podman, `rc` has Singularity/Podman,
    and `t4` has Singularity/Apptainer. Current alone reports the two intended
    compute-only warnings. Every doctor has zero failures and every checkout is
    clean at `dc43fca`.
  - None of the seven common Python 3.12 environments contains PyTorch; retain
    that intentional project/site boundary. Add `tests/smoke/llm_torch.py` as a
    bounded gate for an already-selected environment: it checks tensor/device
    agreement, finite forward loss, finite nonzero backward gradients, a real
    optimizer update, and, under native `torchrun`, process-group world size and
    unique ranks without creating a checkpoint. Static compile, dependency-free
    help, and a clear absent-PyTorch refusal are part of the phase-1 suite.
    For independent numerical validation, the official
    [PyTorch 2.12.1 CPU command](https://docs.pytorch.org/get-started/previous-versions/)
    installed `torch==2.12.1+cpu` only into a disposable local uv environment.
    Native single-process and two-process CPU runs both passed with loss
    `2.806825`, gradient L1 `8.485694`, and parameter delta
    `4.726678e-03`; the two-process run verified world size 2. The minimal wheel
    emitted an optional-NumPy warning but the Torch-only numerical gates passed.
    The temporary venv and its 183 MB cache were removed. Do not install a
    global framework merely to run GPU validation; run the CUDA form later from
    the first reviewed project image or lockfile environment. Commit `1ffc9f1`
    adds the source and tests. All six clean remotes were fast-forwarded from
    the complete bundle with SHA-256
    `189648da0ae91aaf08865b846c3fdc354d4ea247457ae105dc6e38527ce858a9`;
    each remote's Python 3.12 independently compiled the script, exercised its
    dependency-free help path, retained a clean checkout, and removed the
    staged bundle.

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
