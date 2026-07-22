# T-295 fleet convergence plan

## Control state

- Task: T-295
- Phase: interviewing
- Planning date: 2026-07-22
- Driver: Codex on `local`
- Interview method: ask one material question at a time, following the PIE
  skill's normal interview after the owner superseded the earlier bundle
  request.
- Mutation gate: no target-system changes until decisions are checkpointed,
  the plan is audited and frozen, and the owner gives the final explicit go.

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
11. Freeze a cross-platform Python 3.12 policy and synchronization method.
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
| abq | unresolved | unresolved | unresolved | direct alias unresolved |
| web | unresolved | unresolved | unresolved | authentication rejected |

The value-free connection monitor reported every Mac pair healthy. ABQ's
onboarding preflight accepted the token `abq`, but its single permitted direct
inventory attempt failed because local cannot resolve that alias. This is
unknown remote state, not evidence that ABQ is absent.

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

1. **Fleet scope and publication — answered/accepted.** Define the existing 11-node
   maintenance/Python/package scope as local, ab, ab2, al, rc, ri, t4, aist,
   home, office, and riken; ABQ becomes node 12 after onboarding; keep `web`
   service-only. Publish the supplied usernames and global hostnames plus
   verified OS data in the public repository and link it from project
   `AGENTS.md` for cold starts. Confirm or change this scope/publication choice.
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
4. **Homebrew convergence — strict equality selected; removal set pending.**
   Refresh metadata and converge the complete selected formula/cask roots plus
   package-manager-derived dependencies across all four Macs. Do not infer
   removal permission from absence on another Mac; use the owner's forthcoming
   retained/removal decision.
5. **ABQ routes.** Recommended: add `abq` through `ProxyJump ab`, add `abq2`
   through `ProxyJump ab2` as a health/failover route, and reserve aist as an
   emergency third path rather than making health depend on a Mac reverse
   tunnel. Confirm this route design or provide another priority.
6. **ABQ storage and backup declarations.** Provide exact absolute persistent
   and cache roots if known. Recommended hidden-home policy is
   `move-large=.local`, `move-fast=none`, `delete-after-backup=none`, and
   `owner-action=none`; primary Restic lives below the selected persistent root
   and the independent replica uses local's existing safe storage. If roots
   are not known, authorize read-only candidate discovery and allow only an
   unambiguous site-backed choice; otherwise storage/backup acceptance will be
   deferred to the final decision list. Missing packages remain limited to
   declared checksum-pinned user-space tools, never system packages.
7. **Python policy.** Recommended: manage exact CPython 3.12.12 on all 11
   current nodes without replacing `python` or `python3`; expose only
   `python3.12`; synchronize project dependency declarations and `uv.lock`,
   then recreate rather than copy virtual environments per OS/architecture.
   Apply the same declaration to ABQ after onboarding. Confirm this exact-patch
   policy or select minor-only compatibility that retains local/RI 3.12.3.
8. **Codex/Claude benchmark interpretation.** Recommended: create a new
   symmetric experiment using the existing seven synthetic task families,
   current Codex and Claude CLIs/default models, matched sandbox/reasoning/run
   budgets, a 9-run-per-client pilot, and—only if the pilot gates pass—a
   35-run-per-client full stage. Publish a new scoped result table in README
   while retaining T-181. Confirm this interpretation or identify the other
   README benchmark you meant.
9. **External-user skill.** Recommended name and scope:
   `onboard-external-user`, for a local-first clone/install/preflight on Linux
   or macOS with missing-prerequisite detection, no assumed hidden files,
   credentials, private companion, remote nodes, storage, or backups; adding a
   remote node remains an explicit follow-on via `onboard-mirrored-node`.
   Confirm or expand the intended trigger examples/scope.
10. **Unresolved observations.** AL's measured defect is specifically missing
    `tmux-256color`; the proposed fix installs the exact public terminfo entry
    in the user tree without changing the site default. Confirm that matches
    the terminal problem, or describe any additional symptom now. For `web`,
    either provide an already-authorized route for an OS probe or accept an
    explicit `unknown (SFTP authentication unavailable)` OS cell.

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
- The selected Homebrew package/version policy passes on every Mac without
  changing preserved extras.
- ABQ has coherent tracked declarations, control-plane parity, approved
  storage, manual backup/restore evidence, and health coverage, or its exact
  unavoidable owner/authentication blocker is the sole deferred item.
- The selected Python interface and a locked sample environment validate on
  all in-scope nodes without copying environments across architectures.
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

Receive answers to questions 1–10, update this file's decision register, audit
for unanswered material choices, mark the plan `ready-for-go`, summarize it,
and request the final explicit execution go.
