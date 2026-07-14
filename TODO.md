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

  Connectivity checkpoint (2026-07-14, current node, 35 concrete aliases):

  - Clean non-interactive no-op success: `ab`, `ab2`, `ai4s`, `login-01`,
    `rc`, `si`, `t4` (7).
  - Transport/authentication reached but no-op did not return success:
    `abci_login` (remote closed the session after reaching session setup) and
    `web` (remote command exit 1 without an SSH transport error). `github` is
    reachable/authenticated but is a non-cluster restricted Git service and
    rejects the `true` command.
  - TCP connection refused: `a100`, `a4500-02`, `a4500-03`, `a4500-04`,
    `a6000`, `ad-01`, `am-02`, `am-03`, `am4`, `dgx-b200`, `epyc-7502` (11).
  - No route: `a4500-01`, `am-01` (2). DNS failure: `md`, `rtx6000-ada` (2).
  - Timed out: `al` (banner), `aws` (connect), `su` (bounded probe) (3).
  - Strict host-key verification blocked unknown keys: `login-02`, `maas-01`
    (2); do not accept them until their fingerprints are verified out of band.
  - The unlocked agent key was rejected: `alps_login`, `ip`, `po`, `st`, `wi`
    (5). Resolve whether these require another already-owned key, renewed
    account access, VPN/routing, or site-specific interactive authentication;
    never place passphrases or private keys in the harness.

  Next step: resolve or explicitly retire the failed aliases, then inventory
  portable environment state only on the seven cleanly reachable clusters and
  any session-stage aliases confirmed safe for remote commands.

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
