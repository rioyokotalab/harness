# Personal harness task board

This is the authoritative resume point for the portable Codex and Claude
harness. Keep only active decisions, blockers, exact next actions, and compact
completion pointers here. Full pre-housekeeping chronology is available at
published commit 90451d49ac96; detailed T-288 execution through Home Git
catch-up is preserved at 378df00159d59e8abee645f2bdaebd20cf467cc2. Final
T-288 through T-292 execution is in
`docs/audits/macos-ssh-finalization-2026-07-21.md`.

Next free ID: T-296.

## Current state

- Protected public `main` includes PR #185's functional closeout and PR #186's
  durable audit, the schema-3 per-Mac SSH engine, and failover isolation.
  Superseded T-288/T-291/T-292 branches are absent locally and remotely.
- Managed Linux nodes are local, ab, ab2, ri, al, rc, and t4.
  abci_login and alps_login are transports, not targets; retired si is out of
  scope.
- T-288 through T-292 are functionally complete. Local, all six remote Linux
  nodes, and all four Macs have the canonical terminal SSH include and shared
  fragment. All four private Mac profiles use schema 3 with exactly four
  per-host SSH payloads and no legacy payload. Final execution preserved every
  Mac's distinct non-shared SSH bytes.
- The final Mac acceptance proved clean/current public and private Git, current
  updater/startup/SSH plans, managed non-login/login shells, both doctors, and
  zero formula-policy residue. Home's recurring known Codex-installer tail and
  duplicate link were remediated through the established exact transaction;
  no package or unknown state changed.
- Guarded fleet synchronization advanced all six clean Linux mirrors, and the
  schema-3 updater advanced all four clean Mac public checkouts without a live
  SSH transaction. Private Mac checkouts remained clean/current.
- All four Macs run two independent current-user `launchd` supervisors using
  dedicated restricted identities. The tmux session
  `harness-connection-monitor` probes every pair at 300-second cadence,
  classifies healthy/degraded/unrecoverable state, and uses only a healthy
  sibling to kick one failed service. Simultaneous route loss recovers locally
  through `launchd` without controller or owner intervention for tested
  process/network failures; power, sleep, and external-provider loss remain
  outside that guarantee.
- Exactly one future native weekly primary backup job exists on each managed
  Linux node. First runs passed on 2026-07-19; keep-all remains effective.
- Global safety and collaboration invariants in `.codex/AGENTS.md` remain
  authoritative. Never inspect credentials or use raw recursive/bulk deletion.
- Whenever owner input/approval is requested or a task is completed, report a
  fresh health snapshot for all managed Linux nodes and all four Mac route
  pairs. At the owner's standing request, omit `abci_login` and `alps_login`
  from routine health reports unless a task specifically targets a transport.

## Next resume checkpoint

1. Select another independently eligible T-273 workstream only after fresh
   reconstruction of its gate and authority.
2. On or after 2026-07-26, query only T-196 recorded successor job IDs.

## Active tasks

### T-295 — Fleet convergence, ABQ onboarding, and external-user bootstrap

**Phase/status:** executing. The owner requested one upfront PIE plan for
thirteen coupled workstreams, then selected PIE's normal one-question-at-a-time
interview. Read-only discovery, decisions D1–D17, the frozen execution order,
rollback, and acceptance gates are recorded in
`docs/plans/t295-fleet-convergence.md`. No agent target mutation has started;
the owner supplied the final explicit PIE go on 2026-07-22.

Confirmed planning facts:

- All seven currently managed Linux nodes and all four Mac primaries respond;
  all eight Mac reverse routes are healthy. ABQ is reachable as a RHEL 9.4
  x86-64 interactive node through the existing nested `ab` route and through
  Aist for emergency access; its planned `ab2` secondary route is not yet
  configured. `web` rejected the available noninteractive authentication.
- Every Mac's interactive `login` and `login2` alias requests one fixed remote
  forward in addition to the launchd-owned connection. Dedicated tunnel-only
  aliases are required to eliminate bind conflicts without weakening
  fail-fast supervision.
- Global `ForwardX11 yes` explains irrelevant X11 rejection warnings. A
  controlled AL Vim test reproduced its broken-prompt symptom only when the
  missing `tmux-256color` entry forced Vim to ANSI fallback without alternate-
  screen restoration; clean and tracked Vim configs behaved identically,
  `xterm-256color` restored correctly, and tty modes remained intact. AL's
  ncurses accepts the canonical entry in check-only mode for user-local
  installation. The accepted fix installs it only in the user terminfo tree
  and validates capabilities, tty preservation, clean/configured Vim, and
  alternate-screen restoration.
- All four Macs run Codex 0.145.0, the current published npm version observed
  on 2026-07-22, with two Codex processes and three live arg0 locks each.
  Their clean `main` checkouts are at `c182bf4`, behind current public main.
- The existing managed Homebrew baseline is satisfied everywhere, and the
  owner has now selected a strict cross-Mac package set from the complete
  union inventory. `.sync_get.sh` is absent on the seven Linux nodes and is a
  regular file on each Mac.
- Linux already provides a Python 3.12 interface everywhere; five remotes use
  managed 3.12.12, while local and RI retain host 3.12.3. Macs expose Python
  3.13 or 3.14 and do not expose `python3.12`. The accepted replacement policy
  pins one tested uv version, supplies non-default 3.11 and 3.12 runtimes where
  practical, defaults new projects to 3.12, and lets each project select its
  interpreter, accelerator/site toolchain, lockfile, and local virtual
  environment.
- The existing local-to-t4 SSH mirror plan fails before contacting t4 because
  it rejects the harness-managed `~/.local` symlink. This is a code defect, not
  evidence of t4 divergence.
- The README defines a Codex-only frozen acceptance evaluator, not a current
  paired Codex/Claude benchmark. A new matched experiment must preserve the
  historical T-181 results rather than overwrite them. The accepted design
  uses current CLI/default-model identities and matched budgets, with a
  9-run-per-client pilot gating a 35-run-per-client full stage.
- ABQ's group disk now has a verified 1,024 GiB quota. Its accepted persistent
  and cache roots are `/groups/qgai50157/yokota` and
  `/groups/qgai50157/yokota/cache`; they remain uncreated until the final go.
  Its accepted hidden-home policy moves large `.local` data only, moves no
  latency-sensitive path, deletes no source after backup, and requires no
  owner-only migration step.
- ABQ's accepted backup topology uses
  `/groups/qgai50157/yokota/restic/home-control` as the primary Restic
  repository and local's
  `/mnt/nfs-03/safe/Users/rioyokota/restic-replicas/abq` as its independent
  replica. The owner provisioned the Restic password on ABQ; a value-free
  check verified a current-user-owned regular file with mode `0600`.
- The accepted `onboard-external-user` skill is local-first for Linux and
  macOS, detects missing prerequisites, assumes no private state or remote
  infrastructure, and delegates any later remote-node work explicitly to
  `onboard-mirrored-node`.
- The official service specification identifies service-only
  `web-o3.noc.titech.ac.jp` as Rocky Linux 8 on x86_64; an official Tokyo Tech
  technical document independently corroborates the same fact.

**Next action:** validate and publish each implementation slice, synchronize
clean checkouts, and execute the frozen rollout; defer only genuinely new
decision or approval blockers to the final bundle.

Execution checkpoint 2026-07-22:

- Protected PR #212 passed `portable-phase1` and squash-merged the frozen plan
  as `bf322ad`; the planning branch was removed.
- On `task/t-295-ssh-doc-contract`, the first implementation slice adds the
  cold-start fleet table and AGENTS pointer, documents the supported managed
  fragment workflow, moves fail-fast/nonmultiplexed behavior from
  `login`/`login2` to `tunnel`/`tunnel2`, and applies D3's exact X11 boundary.
- `tests/test-fleet-inventory.sh` and `tests/test-ssh-config-layout.sh` pass.
  The first Phase 1 run passed every other focused suite but
  `test-tmux-config.sh` correctly refused the dirty checkout. After commit
  `ecc945d`, the full `tests/test-phase1.sh` rerun passed from a clean tree.
- Protected PR #213 passed `portable-phase1` and squash-merged the fleet SSH
  and inventory contract as `db8a5b7`; guarded fleet sync advanced all six
  clean remote Linux checkouts to that exact revision.
- The next slice on `task/t-295-mirror-symlink` repairs the one-way mirror's
  declared `.local` symlink handling and makes the installed canonical SSH
  fragment part of plan/apply/rollback validation without transporting it.
  Focused syntax, fragment-drift, atomicity, privacy, rollback, and symlink
  tests pass. Next: commit from the verified tree, run clean Phase 1, publish,
  synchronize, install the fragment layout on local and t4, then execute the
  separately authorized mirror plan/apply.
- Protected PR #214 passed `portable-phase1` and squash-merged that repair as
  `71cc888`; guarded fleet sync advanced all six clean Linux mirrors to the
  exact merge. Local and t4 canonical layout transactions
  `20260722T051216Z-401698` and `20260722T051229Z-2297395` completed, the
  separately authorized local-to-t4 mirror applied with rollback available,
  and its follow-up plan reports `agreement=yes action=none`.
- Each Mac's exact current-user-owned, single-link regular `~/.sync_get.sh`
  was independently revalidated and exact-unlinked. A subsequent inventory
  reports the path absent on local, all six remote Linux nodes, and all four
  Macs. No wildcard, looped deletion, or recursive deletion was used.
- Current slice: implement and validate AL's user-local canonical
  `tmux-256color` deployment, then publish and roll it out with controlled PTY
  acceptance.
- Protected PR #215 passed `portable-phase1` and squash-merged the AL adapter
  as `a1b4973`; guarded fleet sync advanced all six clean Linux mirrors. AL's
  live plan reported the expected missing entry, but apply stopped before any
  entry or transaction because the first implementation rejected AL's
  profile-declared `.local` symlink. The follow-up slice adds the same strict
  declaration/owner/containment validation used by established adapters plus
  declared and undeclared symlink tests; retry is safe after publication.
- Protected PR #216 passed `portable-phase1` and squash-merged the symlink
  repair as `0172cd5`; guarded fleet sync advanced all remote Linux mirrors.
  AL apply then installed the canonical entry in transaction
  `20260722T053338Z-243285`, guarded-deleted its compiler stage, and passed
  `infocmp` plus `tput`. Follow-up plan exposed one ncurses-version-only
  normalized spelling difference (`\:` versus `:`), with no capability
  difference. The current slice canonicalizes that escape equivalence and adds
  a regression before completing real-PTY acceptance; rollback remains intact.
- Protected PR #217 passed `portable-phase1` and squash-merged the ncurses
  normalization as `7b3f034`; guarded fleet sync advanced all remote Linux
  mirrors. AL now reports `state=current action=none`, with `infocmp`, 256
  colors, clean/configured Vim alternate-screen entry and restoration, and tty
  preservation all passing in a real PTY. All four Macs then cleanly advanced
  public Git to `7b3f034` and retained private Git at `a93fa1f`; their update
  transactions are `20260722T054112Z-50342`, `20260722T054128Z-59824`,
  `20260722T054158Z-63319`, and `20260722T054221Z-7321` for Aist, Home, Office,
  and Riken respectively. Canonical SSH-fragment transactions
  `20260722T054235Z-53170`, `20260722T054243Z-62667`,
  `20260722T054253Z-66128`, and `20260722T054302Z-10115` applied D3; every
  selected alias resolves `ForwardX11 no` and `login` plus an unlisted node
  resolve `yes` on every Mac.
- Current slice: extend lock-aware Codex arg0 housekeeping to macOS's native
  metadata, Perl advisory locks, and four-helper layout before the frozen
  update/stop/cleanup/resume sequence.
- Protected PR #218 passed `portable-phase1` and squash-merged Darwin arg0
  support as `59856f9`; guarded fleet sync advanced all Linux mirrors and all
  four Macs advanced clean public checkouts to that revision. The official
  Codex 0.145.0 installer was byte-frozen and reviewed before use. Each Mac now
  runs the resumed most-recent Codex session and remote-control app server;
  post-grace arg0 housekeeping remains in final acceptance. Aist's
  `claude-code` cask was removed, and Riken's installer-added startup tail and
  duplicate Codex symlink were removed without affecting its canonical
  launcher.
- Homebrew metadata was refreshed independently on all four Macs. The complete
  allowed selection plus dependency closure is identical at 51 formulae, and
  the observed non-universal union is frozen as the public retirement set.
  The current slice updates the bounded adapter so dependents inside that
  reviewed retirement set can be removed together while external dependents
  still block; focused regression coverage passes. Next: publish, synchronize,
  run all four live plans, and converge one Mac at a time.
- Protected PR #219 passed after its inventory privacy/count fixture was made
  policy-derived and squash-merged as `54e64f0`; all Linux mirrors are at that
  revision. Mac update plans then correctly failed before mutation because
  older updater code treats schema-2 `formula-policy-v2.conf` as a frozen
  compatibility surface. The active corrective slice restores v2 byte-for-byte,
  moves the expanded exact set to schema-3 `formula-policy-v3.conf`, and adds a
  frozen v2 regression. All affected focused Mac suites pass; next publish this
  compatibility repair and retry the four Mac plans.
- Protected PR #220 passed and squash-merged the v2/v3 compatibility repair as
  `81dcf50`; all Linux mirrors and all four clean Mac checkouts now hold that
  exact revision. Mac update transactions are
  `20260722T062642Z-61901`, `20260722T062646Z-70665`,
  `20260722T062655Z-74291`, and Riken's completed current-state migration.
  Aist's first live Homebrew plan then exposed old installed-linkage ordering:
  selected upgrades must precede retirement. The active slice implements that
  post-upgrade fail-closed checkpoint and replaces per-formula version probes
  with one bounded scoped query; focused migration-order coverage passes.
- Protected PR #221 passed and squash-merged the migration-order repair as
  `551bbb8`; all Linux mirrors and all four Macs are synchronized to it. Aist,
  Home, and Riken plans now pass and explicitly schedule `node` migration before
  retirement. Office exposed Homebrew canonicalizing `icu4c@76` to
  `icu4c@78` only when both are passed as query arguments. The active slice
  replaces that ambiguous query with one formula-only installed inventory and
  blocks every name outside the exact policy; no casks or package changes are
  involved in discovery.
- Protected PR #222 passed and squash-merged exact installed-formula discovery
  as `417c471`; every checkout is synchronized. All four retry plans passed.
  Apply then safely stopped after selected-package migration on Aist and Home
  because Homebrew reports managed users for legacy aliases, and on Office
  because upgrading the retirement-bound graphics stack introduced
  `libdatrie` and `libthai`. Riken retired the newest reviewed kegs but retained
  older versions, as non-forced uninstall documents. No unreviewed removal
  occurred. The active slice declares the two alias mappings, uses scoped
  cleanup for the shared `icu4c` Cellar, exact forced uninstall for independently
  dependency-checked retirements, and adds the two newly observed packages to
  the retirement set.
- Protected PR #223 passed and squash-merged those legacy-keg rules as
  `cb410dd`; Linux mirrors advanced, but all Mac updater preflights refused the
  target before mutation because deployed schema 3 is now itself a frozen
  compatibility surface. The active repair restores v3 exactly, introduces
  schema-4 `formula-policy-v4.conf`, routes current adapters to v4, and pins the
  v3 Git object ID in long-gap update coverage.
- Protected PR #224 passed and squash-merged the v4 compatibility repair as
  `a3f46ba`; Linux and Mac checkouts are synchronized. Office and Riken v4
  plans pass. Aist and Home stop before mutation because Homebrew's cleanup
  dry-run reports the declared legacy Cellar path while the adapter expected
  the declared current command target. The active fix validates both mapping
  sides explicitly: legacy source path in evidence and current target in the
  scoped cleanup command.
- Protected PR #225 passed and squash-merged that mapping fix as `f314c69`; all
  checkouts are synchronized and all four plans pass. Exact retirements then
  completed, leaving no retired or outside-policy formulae. The final checkpoint
  correctly caught Homebrew removing selected `mpdecimal` (plus `mpfr` on
  Riken) and leaving Office's `mpdecimal` outdated. The active slice adds a new
  exact dry-run and scoped install/upgrade repair after retirement, followed by
  the full final acceptance inventory.
- Protected PR #226 passed and squash-merged post-retirement repair as
  `ccc1764`; all checkouts are synchronized. Repair transactions completed on
  Aist (`20260722T074653Z-4698`), Home (`20260722T074601Z-73734`), Office
  (`20260722T074610Z-20940`), and Riken (`20260722T074607Z-31431`). All four now
  have the identical 51-name set (SHA-256
  `dbd8547528d603da7e79f3c8a6942283c3933b0fa942d224b8fdcff91aeeff23`)
  and zero casks. Version hashes still differ only because historical kegs
  remain. The active slice detects multi-version managed formulae, requires a
  formula-scoped cleanup dry-run, cleans only those reviewed Cellars, and then
  repeats exact acceptance.

### T-273 — Resolve intentionally deferred maintenance

**Phase/status:** executing. Workstreams 1, 2, 3, and 9 are complete. Each
remaining item keeps its independent gate.

1. **Failed transaction evidence — complete/retain.** Small paired recovery
   preimages lack a cleanup contract.
2. **Linux agent replacement — capability complete.** PR #143 published
   1ed9712bc8c3fd4896df2654b2a3379412e5984b; no live replacement or old-tree
   cleanup is authorized.
3. **Fourth Mac — complete.** T-268/T-269/T-286 acceptance passed.
4. **Backup successors — time-gated.** On or after 2026-07-26, query only the
   seven T-196 IDs; never duplicate a delayed job.
5. **Vendor arg0 directories — complete/live-managed.** T-294 installed the
   version-scoped NFS wrapper and added lock-aware guarded routine housekeeping.
6. **Container capability — requirement-gated.** Install nothing merely for
   warning parity.
7. **One-way local-to-t4 SSH mirror — separate authority.** Execute only after
   explicit authorization for that external mutation.
8. **Package maintenance — freshness/selection-gated.** No blanket upgrade,
   cleanup, autoremove, cask, service, tap, or unmanaged-dependent mutation.
9. **Orphaned .bash_common — complete.** Absent on all four Macs; do not
   recreate it.

Closed non-goals remain plugins/connectors/accounts, administrator settings,
automatic publication, background login mutation, active-session reload, and
guessing lost unknown configuration.

### T-196 — Backup lifecycle phase 2

**Phase/status:** policy-resolved; execution remains gated on eight successful
weekly chains, two verified restores per node, and a current independent
generation. Progress is 1/8 everywhere.

| Node | Recorded 2026-07-26 successor |
| --- | --- |
| local | 91840 |
| ab | 2048464.pbs1 |
| ab2 | 2048468.pbs1 |
| ri | 7242 |
| rc | 212389 |
| t4 | 8194556 |
| al | 4238363 |

On or after eligibility, identity-match and query only these IDs. Record
terminal success, snapshot succession, warning silence, and chain count. Delay
is healthy; do not replace a pending job. Keep-all remains effective. No
forget, prune, recurring check/restore, or replica automation is authorized.
Evidence remains in docs/backup-lifecycle-phase2.md, docs/home-backup.md, and
docs/audits/restic-first-weekly-2026-07-19.md.

## Completed anchors

- T-294 diagnosed the Codex 0.145.0 NFS arg0 lock/delete failure, removed 3,158
  stale directories without stopping Codex, and published shared housekeeping
  in PR #208. PR #209 at `f7cdacd` added guarded lock-aware cleanup and a
  transactional version-scoped launcher, restored ordinary harness push
  authority while retaining the remote-change prohibition, and passed all 61
  focused suites plus protected CI. Live install, exact binary-hash rollback,
  and reapply passed; two short calls and a deliberate nonzero exit were
  warning-free, remote-control help was ready, all three original held-lock
  identities survived, and acceptance ended with three live, one young empty,
  and zero unexpected. After its grace elapsed, guarded-delete manifest
  `/home/rioyokota/.codex/tmp/.harness-delete.pHVd67/manifest` removed that
  final empty directory and was exact-unlinked, leaving only the three live
  entries. Current rollback is
  `harness codex-arg0-wrapper --rollback`; an official Codex upgrade supersedes
  the version-scoped wrapper and requires fresh diagnosis before reinstallation.

- T-293 published and rolled out independent managed Mac reverse-route
  supervision, state-aware monitoring, bounded single/dual-failure recovery,
  exact rollback, and final fleet convergence in PRs #191 through #206, ending
  at `97162ef3c554a80a29c63a4b83d39d292ad4fb14`. Full value-minimized evidence
  is in `docs/audits/t293-connection-self-healing-2026-07-22.md`.
- T-292 isolated `login`/`login2` from multiplexing and enabled forward-bind
  fail-fast behavior in protected PRs #182 through #184, ending at 936a54f.
- T-291 converged the canonical SSH fragment on all eleven managed systems,
  published four distinct per-Mac payloads, finalized private schema 3, and
  preserved all live non-shared SSH bytes. Detailed execution and transaction
  identifiers are in `docs/audits/macos-ssh-finalization-2026-07-21.md`.
- T-290 diagnosed Aist route oscillation followed by the keepalive window. Its
  unpublished raw local checkpoint was compacted value-free and the sole
  preservation ref exact-deleted; no process/network details were published.
- T-288 completed post-onboarding Git, startup, doctor, and exact-residue
  housekeeping on all four Macs. The generic fix shipped in PR #170 and the
  final evidence is in `docs/audits/macos-ssh-finalization-2026-07-21.md`.
- T-289 published sourced harness-evolution artifacts in PR #168 at f2ffdd99685d;
  protected CI and clean phase-one passed.
- T-287 converged the fourth Mac startup files and published PR #166 at
  90451d49ac96.
- T-286 independently onboarded the fourth Mac and superseded T-285.
- T-284 published accelerated/instrumented cowork in PR #163 at 54454b3.
- T-283 published symmetric Codex-Claude cowork in PR #161 at 535a492.
- T-282 compacted the ledger and removed proven-obsolete refs in PR #159.
- T-281 completed three-Mac convergence; T-280 onboarded Home; T-279 repaired
  its prior Bash drift.
- T-274 published unified Bash startup and Mac onboarding; T-268/T-269
  completed the private Mac fleet.
- T-191 accepted first native weekly backup runs on all seven nodes.
- T-181 acceptance finished at 69/70 with zero safety failures.
- T-210 is complete and must not be repeated.

Consult Git history at or before 378df00159d59e8abee645f2bdaebd20cf467cc2
for superseded plans, exact transaction chronology, prior PR/run identifiers,
and detailed T-288 evidence.
