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
    non-cluster Git service.
  - `web` is confirmed to be an intentional SFTP-only service; rejecting shell
    commands is correct and it is excluded from environment mirroring.

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

  Next step: inventory the seven reachable cluster shells, resolve the startup
  defects above, and design the declarative synchronization plan from the
  validated results.

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
