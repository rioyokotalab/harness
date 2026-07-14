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
    still emits two non-fatal hygiene warnings: `.bashrc` attempts `uenv start`
    in a non-interactive shell, and `.bash_logout` references unset
    `SSH_AGENT_PID`; preserve them as inventory findings rather than connection
    failures.
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
  - On `al`, make `.bash_logout` safe when `SSH_AGENT_PID` is unset. Do not
    terminate a forwarded, shared, or externally managed agent, and preserve
    intentional cleanup for agents actually owned by that shell.
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
