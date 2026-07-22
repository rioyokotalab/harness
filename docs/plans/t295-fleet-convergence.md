# T-295 fleet convergence plan

## Control state

- Task: T-295
- Phase: complete
- Planning date: 2026-07-22
- Driver: Codex on `local`
- Interview method: ask one material question at a time, following the PIE
  skill's normal interview after the owner superseded the earlier bundle
  request.
- Mutation gate: satisfied by the owner's final explicit go; execution and
  acceptance completed on 2026-07-22.

## Scope

Deliver these outcomes as one ordered program:

1. Remove reverse-forward conflicts from multiple ordinary Mac-to-local SSH
   logins while retaining two independent launchd-owned tunnels per Mac.
2. Stop irrelevant X11 forwarding requests and preserve explicit opt-in X11.
3. Update/revalidate Codex on every Mac, stop all Codex processes, perform
   lock-aware arg0 cleanup, resume the most recent intended session, restart
   remote control if selected, and prove Codex stays running on all four Macs.
4. Document the supported workflow for changing the managed
   `~/.ssh/config.d/harness.conf` fragment.
5. Remove the exact `~/.sync_get.sh` file wherever it exists in the current
   managed 11-node fleet.
6. Repair AL terminal capability.
7. Repair and execute the explicit one-way local-to-t4 SSH configuration
   mirror.
8. Publish a cold-start-readable fleet alias table with verified OS facts.
9. Converge the selected Homebrew policy across the four Macs.
10. Onboard ABQ and add its supported route or routes to health monitoring.
11. Freeze a project-owned dual-runtime Python policy and synchronization
    method for heterogeneous LLM/HPC work.
12. Run a new matched Codex/Claude acceptance experiment and update README
    without rewriting the frozen T-181 evidence.
13. Create and validate an external-user onboarding skill that assumes neither
    this owner's hidden files nor any remote fleet.

## Non-goals

- Do not inspect, copy, or publish credentials, SSH keys, authentication state,
  session transcripts, private SSH payload bytes, or private configuration.
- Do not normalize schedulers, system Python, MPI, CUDA, compilers, or site
  modules.
- Do not remove Mac-specific Homebrew packages unless the owner selects strict
  convergence.
- Do not add ABQ scheduler recurrence during onboarding.
- Do not make `web` a deployment target unless the owner explicitly expands
  scope; it is currently a service alias.
- Do not rewrite historical benchmark reports or infer broad performance from
  the new bounded experiment.

## Confirmed evidence

### Connectivity and operating systems

Read-only probes on 2026-07-22 confirmed:

| Logical node | Observed login host | Observed OS | Architecture | State |
| --- | --- | --- | --- | --- |
| local | `login-01` | Ubuntu 24.04.3 LTS | x86_64 | ready |
| ab | `login2` | Red Hat Enterprise Linux 9.4 | x86_64 | ready |
| ab2 | `login4` | Red Hat Enterprise Linux 9.4 | x86_64 | ready |
| al | `daint-ln004` | SUSE Linux Enterprise Server 15 SP6 | aarch64 | ready |
| rc | `login1` | Rocky Linux 9.8 | x86_64 | ready |
| ri | `c000` | Ubuntu 24.04.4 LTS | aarch64 | ready |
| t4 | `login2` | Red Hat Enterprise Linux 9.4 | x86_64 | ready |
| aist | `aist` | macOS 26.5.2 | arm64 | ready |
| home | `home` | macOS 26.5.2 | arm64 | ready |
| office | `office` | macOS 26.5.2 | arm64 | ready |
| riken | `riken2` | macOS 26.5.2 | arm64 | ready |
| abq | `qes03` | Red Hat Enterprise Linux 9.4 | x86_64 | primary/emergency ready; secondary pending |
| web | `web-o3.noc.titech.ac.jp` | Rocky Linux 8 | x86_64 | service-only; documented |

The value-free connection monitor reported every Mac pair healthy. ABQ's first
direct inventory failed because local had no alias. After the owner approved
the route and established initial access-server trust, the existing nested
route through `ab` completed inventory on `qes03`; the Aist emergency route
also passed. The `ab2` node does not yet resolve `abq`, so its approved
secondary route requires the planned configuration change.

The owner supplied the official Science Tokyo NOC service specification for
`web`; its Rocky Linux 8/x86_64 fact is independently corroborated by an
official Tokyo Tech technical document:
<https://www.noc.cii.isct.ac.jp/srv/wwwsrv/> and
<https://www.titech.ac.jp/0/pdf/info-31935-3.pdf>.

### SSH and terminal

- Each Mac reports exactly one `RemoteForward` and
  `ClearAllForwardings no` for both `login` and `login2`.
- Each Mac launchd supervisor is loaded and running on both routes.
- Riken also reports one external `ssh ... login` process, demonstrating the
  overlapping ordinary-login surface.
- The public shared fragment globally sets `ForwardX11 yes` and
  `ForwardX11Trusted yes`.
- AL receives `TERM=tmux-256color`, has no matching terminfo entry, and fails
  `tput`; its `screen-256color` and `xterm-256color` entries are present. The
  complete harness doctor still passes with zero warnings.
- A forced-PTY Vim A/B test at a fixed 80x24 geometry reproduced the visible
  corruption with both `vim -Nu NONE` and the normal tracked Vim config when
  `TERM=tmux-256color`. Vim reported `E558`, fell back to builtin ANSI, cleared
  the screen, and emitted no alternate-screen restore. The same binaries and
  configs entered and restored the alternate screen correctly with
  `TERM=xterm-256color`; tty state was identical before and after both cases.
  Thus the apparent broken prompt is erased/mispositioned display state, not a
  damaged shell tty mode or Vim configuration.
- AL's `/usr/local/bin/bash` login-shell path is absent from `/etc/shells`, but
  resolves to the same `/usr/bin/bash` as `/bin/bash`; its interactive prompt
  is the plain Bash default. The tracked Vim and tmux configs exactly match
  local, so neither observation explains the TERM-dependent A/B result.
- AL has no user terminfo tree. Its ncurses 6.1 `tic -c -x` accepts local's
  canonical `tmux-256color` source without errors, demonstrating that a
  user-local compiled entry is compatible without a system change.
- `harness ssh-config-mirror --plan` stops locally with `SSH mirror local state
  has unsafe type` because `~/.local` is a managed symlink. Newer harness
  adapters already validate this declared layout safely.

### Codex, arg0, packages, and Python

- The official npm registry reports Codex 0.145.0, matching all four Macs and
  local. The current CLI documents `codex update`, `codex resume --last`, and
  `--all` to disable working-directory filtering.
- Each Mac has two exact-name Codex processes and three immediate arg0
  directories with three lock files; there are no unexpected root entries.
- All Mac public checkouts are clean `main` at `c182bf4`, four protected merges
  behind current main `c6d57f1`. Therefore the new Linux-only arg0 command is
  not yet present there and also needs a reviewed Darwin implementation.
- The managed ten-formula Homebrew plan reports no missing, outdated, retired,
  or unmanaged-dependent action. Common leaves are
  `bash-completion@2`, `gh`, `git`, `git-lfs`, `jq`, `ripgrep`, `shellcheck`,
  `tmux`, `tree`, and `uv`; Mac-specific leaves differ. Three Macs report uv
  0.11.29 while Riken reports 0.8.3, showing that a no-refresh plan does not
  prove version convergence.
- `.sync_get.sh` is absent on local and all six managed remote Linux nodes. It
  is a regular file on each Mac; no content was read.
- The selected Linux interface is Python 3.12. Five remote nodes retain managed
  CPython 3.12.12; local and RI retain host CPython 3.12.3. Macs have uv but no
  `python3.12`, and their default Python ranges from 3.13 to 3.14.

### Evaluation and external onboarding

- The repository's only acceptance evaluator is the frozen T-181 Codex-only
  experiment: seven task families, a 9-run-per-arm pilot, and a 35-run-per-arm
  full stage. Its results apply only to Codex 0.144.5 and must remain immutable.
- No current README command runs the same corpus with Claude.
- The new skill belongs under `shared/skills/` so installation exposes the same
  workflow to Codex and Claude. It must be initialized with the canonical
  skill-creator script, include no owner-specific defaults, and pass skill,
  discovery, and realistic forward tests.

## Proposed decisions and questions

Ask these decisions one at a time and checkpoint each answer before advancing.

### Decision register

- D1 — **accepted:** publish the supplied fleet usernames, hostnames, and
  verified OS facts in the public harness repository and link the table from
  project `AGENTS.md`. The existing 11 systems are the current managed scope,
  ABQ becomes node 12 after onboarding, and `web` remains service-only.
- D2 — **accepted with owner naming correction:** retain only `login` for
  ordinary interactive Mac-to-local access, remove the interactive `login2`
  alias, and move the primary and secondary supervised reverse forwards to
  launchd-only aliases named `tunnel` and `tunnel2` respectively.
- D3 — **accepted with explicit alias boundary:** set `ForwardX11 no` for
  `tunnel`, `tunnel2`, `aist`, `aist2`, `home`, `home2`, `office`, `office2`,
  `riken`, `riken2`, and `web`. Retain X11 forwarding on `login` and every
  other node.
- D4 — **accepted:** after the Mac Codex restart, select the globally most
  recent session with `codex resume --last --all`, not the most recent session
  filtered to `~/harness`.
- D5 — **accepted:** restart `codex remote-control` on all four Macs after the
  updater, process stop, and arg0 cleanup, preserving the existing device
  pairings.
- D6 — **accepted:** reject managed-baseline-only Homebrew
  convergence and require complete package-set equality across all four Macs.
  A read-only inventory found 107 unique installed formulae, 19 unique leaves,
  and one cask. Retain every formula already installed on all four Macs;
  promote `json-c`, `wget`, `bash-git-prompt`, and `mpfr` to all four; remove
  every other non-universal formula; remove Aist's `claude-code` cask; and
  install the dependency closure of the retained set. Retain universal
  `openssl@3` and remove legacy non-universal `openssl@1.1` from Aist and Home.
- D7 — **accepted:** route `abq` through `ab` and `abq2` through `ab2` for
  routine health/failover. Retain Aist as an emergency-only ABQ path that does
  not participate in routine health.
- D8 — **accepted authority:** the owner grants user-level authority for every
  operation their account can perform on ABQ. This does not authorize
  credential inspection, administrator actions, host-key bypass, or mutation
  before the final PIE go. The owner established initial access-server trust.
  Read-only preflight then proved primary `ab` and emergency Aist access,
  RHEL 9.4/x86-64, PBS/Git/bootstrap readiness, and outbound official HTTPS.
  The approved `ab2` secondary alias is not configured yet. `show_quota`
  initially reported a permission-writable group root with a 0 GiB limit. The
  required Restic password file was initially absent and is now satisfied by
  D12. Ordinary user-level ABQ actions need no later permission request.
- D9 — **accepted storage roots and verified allocation:** use
  `/groups/qgai50157/yokota` as ABQ's persistent root and
  `/groups/qgai50157/yokota/cache` as its cache root. After the owner added
  storage, `show_quota` verified a 1,024 GiB group-disk limit with 1 GiB used.
  Create and probe these paths transactionally only after the final PIE go.
- D10 — **accepted hidden-home policy:** declare `move-large=.local`,
  `move-fast=none`, `delete-after-backup=none`, and `owner-action=none` for
  ABQ. Preserve source data until backup and migration validation complete.
- D11 — **accepted backup topology:** place ABQ's primary Restic repository at
  `/groups/qgai50157/yokota/restic/home-control` and maintain its independent
  replica on local at
  `/mnt/nfs-03/safe/Users/rioyokota/restic-replicas/abq`.
- D12 — **credential prerequisite satisfied:** the owner provisioned ABQ's
  existing Restic password file. A value-free check verified it is a
  current-user-owned regular file with mode `0600`; no credential content was
  inspected.
- D13 — **accepted project-owned Python policy:** pin one tested `uv` version
  fleet-wide and provide versioned, non-default CPython 3.11 and 3.12 runtimes
  where practical. New projects default to 3.12; 3.11 is the compatibility
  runtime. Each subproject owns `requires-python`, `.python-version`,
  `pyproject.toml`, `uv.lock`, and its locally recreated virtual environment.
  Never copy virtual environments across hosts or architectures. GPU projects
  declare an accelerator backend, while ABI-coupled MPI/CUDA work loads the
  site's module or pinned container before uv creates the environment against
  that interpreter. Keep caches platform-local and record the resolved Python,
  uv, accelerator, compiler, MPI, and container versions with experiments.
- D14 — **accepted symmetric benchmark design:** preserve historical T-181 and
  add a new dated Codex-versus-Claude experiment over the existing seven task
  families. Record current CLI/default-model identities, match sandbox,
  reasoning, and run budgets, run a 9-run pilot per client, and proceed to the
  35-run full stage per client only when the pilot gates pass.
- D15 — **accepted external-user skill:** create `onboard-external-user` as a
  local-first Linux/macOS clone, install, preflight, and validation workflow.
  It detects and explains missing prerequisites and assumes no hidden files,
  credentials, private repository, remote nodes, storage, or backups. Remote
  node onboarding remains an explicit follow-on through
  `onboard-mirrored-node`.
- D16 — **accepted AL terminal fix:** compile the canonical
  `tmux-256color` entry into AL's user terminfo tree without changing site
  defaults. Validate discovery and capabilities with `infocmp` and `tput`,
  then verify clean Vim, tracked-config Vim, tty preservation, and alternate-
  screen restoration under a controlled PTY.
- D17 — **accepted documented web OS:** record service-only
  `web-o3.noc.titech.ac.jp` as Rocky Linux 8 on x86_64, sourced from the
  owner's cited official Science Tokyo NOC specification and corroborating
  official Tokyo Tech technical document. Do not make `web` a command or
  deployment target.

1. **Fleet scope and publication — answered/accepted.** Define the existing 11-node
   maintenance/Python/package scope as local, ab, ab2, al, rc, ri, t4, aist,
   home, office, and riken; ABQ becomes node 12 after onboarding; keep `web`
   service-only. Publish the supplied usernames and global hostnames plus
   verified OS data in the public repository and link it from project
   `AGENTS.md` for cold starts.
2. **SSH role split — answered/accepted with corrected names.** Use `login`
   only for ordinary interactive access, remove `login2`, and use `tunnel` and
   `tunnel2` exclusively for the primary and secondary launchd reverse routes.
   **X11 boundary — answered/accepted:** disable it only for D3's exact alias
   list, not for `login` or other nodes.
3. **Mac Codex restart — resume scope answered/accepted.** Run the supported updater even though
   0.145.0 is already current, stop all exact Codex processes, use a new
   Darwin lock-aware arg0 implementation to quarantine/delete only released
   entries, restart remote control, and start one named tmux TUI with
   `codex resume --last --all` so selection is global rather than restricted to
   `~/harness`, and restart remote control on all four Macs.
4. **Homebrew convergence — answered/accepted.**
   Refresh metadata and converge the complete selected formula/cask roots plus
   package-manager-derived dependencies across all four Macs using D6's exact
   retained/removal decision.
5. **ABQ routes — answered/accepted.** Add `abq` through `ProxyJump ab`, add `abq2`
   through `ProxyJump ab2` as a health/failover route, and reserve aist as an
   emergency third path rather than making health depend on a Mac reverse
   tunnel.
6. **ABQ storage, hidden-home policy, and backup topology — answered/accepted.**
   Use D9's roots, D10's hidden-home policy, and D11's two-location backup
   topology after the final go. D12 satisfies the owner-only Restic credential
   prerequisite. Missing packages remain limited to declared checksum-pinned
   user-space tools, never system packages.
7. **Python policy — answered/accepted.** Apply D13's project-owned,
   dual-runtime policy to the 11 current nodes and ABQ. Preserve site Python
   and the unversioned `python`/`python3` commands; standardize the tested uv
   version and project contract rather than forcing one exact Python patch onto
   every workload and platform.
8. **Codex/Claude benchmark interpretation — answered/accepted.** Implement
   D14's new dated, symmetric experiment and README result table without
   replacing the historical T-181 results.
9. **External-user skill — answered/accepted.** Implement D15's local-first,
   prerequisite-aware scope and keep remote-node onboarding as an explicit
   follow-on workflow.
10. **AL terminal — answered/accepted.** Apply D16's user-local terminfo fix
    and controlled validation.
11. **Web OS — answered/accepted.** Publish D17's documented service OS and
    retain `web` as service-only.

## Frozen plan audit

- All material scope, naming, publication, authority, topology, removal,
  runtime, experiment, and validation choices are captured in D1–D17.
- The implementation order respects code-before-rollout dependencies, the
  protected-main publication gate, clean-checkout fleet synchronization, and
  no-outage tunnel cutover.
- Credential, administrator, host-key, external-service, destructive-cleanup,
  and benchmark-cost boundaries remain explicit. No additional owner decision
  is required to begin; any genuinely new execution-time decision is deferred
  to the final blocker bundle as requested.
- Rollback and acceptance gates cover every mutable workstream. The plan is
  frozen and ready for the final PIE go.

## Frozen execution order after decisions and final go

1. Checkpoint answers, convert assumptions to decisions, audit dependencies,
   acceptance criteria, authority, and rollback, then mark `ready-for-go`.
2. Implement and test public control-plane changes on the task branch:
   `tunnel`/`tunnel2` supervision migration, scoped X11 opt-out, Darwin arg0
   housekeeping, local-to-t4 managed-symlink support, terminfo deployment,
   fleet table/AGENTS pointer, ABQ declarations/health route, cross-platform
   Python declaration, symmetric evaluator, and external-user skill.
3. Run focused tests, skill validation, synthetic failure tests, shell lint,
   `git diff --check`, and `tests/test-phase1.sh`. Fetch again, publish small
   protected PRs, wait for required CI, merge without force, and verify main.
4. Guardedly fast-forward clean managed Linux checkouts. Catch up all four Mac
   public/private checkouts through their native updater before invoking newly
   added commands.
5. Roll out `tunnel`/`tunnel2` in a no-outage sequence: add tunnel-only aliases,
   switch and validate supervisors one Mac/route at a time, then strip forwards
   from interactive aliases. Recheck dual-route health and multiple concurrent
   ordinary logins.
6. Deploy X11 and AL terminfo changes; prove warning-free connections on D3's
   selected aliases, unchanged X11 resolution on `login`/other nodes, and
   working `tput` under `tmux-256color`.
7. Repair, plan, apply, and verify the one-way local-to-t4 SSH mirror. Preserve
   its prior image and rollback transaction.
8. Validate owner/type for each exact `.sync_get.sh` and issue four separate
   exact non-recursive unlinks; re-inventory all 11 nodes. Never use a loop,
   wildcard, or recursive remover.
9. Refresh and reconcile the selected Homebrew scope one Mac at a time; retain
   dry-run evidence and recheck unmanaged dependents/extras.
10. Update/revalidate Codex, stop exact processes, classify and clean released
    arg0 state, restart the selected remote-control/TUI topology, and prove
    process/session health on all Macs.
11. Establish the selected Python policy with plan/apply/doctor on each node,
    then validate a small locked cross-platform environment without copying a
    venv.
12. Establish ABQ routing, rerun the single value-free onboarding inventory,
    stage declarations, validate, publish, bootstrap, and complete manual
    backup/restore acceptance as far as frozen decisions and available
    authentication allow. Add ABQ health only after its profile is coherent.
13. Run the pre-registered Codex/Claude pilot and conditional full experiment;
    retain private raw runs, publish only schema-validated aggregates, and add
    the scoped README table.
14. Initialize, implement, validate, and forward-test
    `onboard-external-user`; install discovery links through `install.sh` and
    prove a clean synthetic new-user path.
15. Run final full validation, protected publication, fleet convergence,
    compact TODO/audit evidence, and a fresh health report. Collect any
    execution-time decision or unavoidable authentication blockers only at the
    end, as the owner requested.

## Risks and rollback

- **Tunnel cutover:** retain old route until its replacement is running and
  inbound health passes; each supervisor and private SSH apply keeps an exact
  unchanged-only rollback.
- **X11:** the exact per-alias opt-out is reversible by the tracked fragment
  transaction and leaves `login` plus every unlisted node unchanged.
- **Codex:** updater is verified before process shutdown; session state is not
  deleted. Arg0 cleanup never removes a held or malformed entry. If restart
  fails, retain evidence and start the prior verified Codex command.
- **Homebrew:** no cleanup/autoremove/cask/service/tap action. Apply only the
  frozen managed scope; package-manager internal cleanup must satisfy the
  reviewed-installer exception.
- **SSH mirror:** preserve one exact t4 prior image and verify unchanged state
  before rollback.
- **ABQ:** failed discovery or ambiguous storage stops that substream without
  weakening the rest of the program. No scheduler job or recurrence is implied.
- **Python:** managed versioned trees and stable links leave system Python
  untouched; rollback verifies exact managed bytes.
- **Benchmarks:** pilot stop/go gate bounds spend; historical evidence is
  immutable; private raw logs remain outside Git and cleanup uses guarded
  deletion only after reports are accepted.

## Acceptance criteria

- Two launchd tunnel routes per Mac remain healthy, two simultaneous ordinary
  Mac-to-local logins do not request or conflict over reverse forwards, and
  recovery drills still pass.
- D3's exact aliases do not request X11, `login` and unlisted nodes retain the
  existing setting, and AL recognizes `tmux-256color` with successful `tput`
  in a real PTY.
- All four Macs report the selected current Codex version, zero removable arg0
  residue, expected live process topology, and a resumable most-recent session.
- The supported harness-fragment edit/deploy/rollback workflow is documented.
- `.sync_get.sh` is absent on every node in the frozen cleanup scope.
- t4 agrees with local's SSH config after a verified mirror transaction.
- The fleet table is complete or marks evidence-blocked fields explicitly and
  is linked from automatically loaded project guidance.
- Every Mac has D6's exact retained Homebrew formula set plus its dependency
  closure, no rejected formula or cask, and current metadata-supported
  versions; no tap or service state changes.
- ABQ has coherent tracked declarations, control-plane parity, approved
  storage, manual backup/restore evidence, and health coverage, or its exact
  unavoidable owner/authentication blocker is the sole deferred item.
- The pinned uv interface, available 3.11/3.12 runtimes where practical,
  project-owned selection, and a locked sample environment validate on all
  in-scope nodes without replacing site Python or copying environments across
  architectures.
- New Codex/Claude aggregates are schema-valid, matched, scoped, and published
  without changing T-181.
- `onboard-external-user` passes canonical validation, discovery tests, and a
  clean synthetic forward test without owner-specific assumptions.
- Focused suites, `git diff --check`, `tests/test-phase1.sh`, and protected CI
  pass; all changed managed checkouts end clean at published main.

## Checkpoint cadence

Checkpoint after decisions, after each protected control-plane merge, after
each live rollout class, after ABQ acceptance, after benchmark pilot/full, and
at final completion. Every checkpoint records exact commits, tests, live
transactions, retry safety, and the next executable action without private
values.

## Next action

None. T-295 is complete. Resume only an independently eligible task from
`TODO.md`; do not repeat live convergence or credential recovery.
