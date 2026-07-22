# Personal harness task board

This is the authoritative resume point for the portable Codex and Claude
harness. Keep only active decisions, blockers, exact next actions, and compact
completion pointers here. Full pre-housekeeping chronology is available at
published commit 90451d49ac96; detailed T-288 execution through Home Git
catch-up is preserved at 378df00159d59e8abee645f2bdaebd20cf467cc2. Final
T-288 through T-292 execution is in
`docs/audits/macos-ssh-finalization-2026-07-21.md`.

Next free ID: T-295.

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

1. Publish T-294's locally validated wrapper through protected main, then
   install and run the recorded live validation without stopping existing
   Codex processes.
2. Select another independently eligible T-273 workstream only after fresh
   reconstruction of its gate and authority.
3. On or after 2026-07-26, query only T-196 recorded successor job IDs.

## Active tasks

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
5. **Vendor arg0 directories — diagnosed; durable fix separated as T-294.**
   The old process-wide gate was overly broad: held per-directory locks protect
   live sessions, while unlocked residue can be isolated and guarded-deleted.
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

### T-294 — Eliminate Codex arg0 cleanup failures on local NFS home

**Phase/status:** executing. The owner authorized a version-scoped local
launcher wrapper on 2026-07-22. Implementation and focused validation are
complete locally; publication, live installation, and acceptance remain.

- Local Codex CLI 0.145.0 stores its arg0 helper directories on the NFSv3
  account home. The mounted filesystem reports `local_lock=none`.
- Lock-aware inventory found 3,157 empty no-lock remnants, one unlocked stale
  helper directory, and three held-lock live directories. The live directories
  were preserved with unchanged identities and working helper paths.
- The stale set was atomically quarantined, then removed through guarded-delete
  manifest `/home/rioyokota/.codex/tmp/arg0-cleanup-20260722.manifest`:
  one target containing 3,158 child directories and 3,164 total entries. The
  manifest was exact-unlinked after its verified result was recorded here.
- Two controlled `codex --version` probes reproduced the lifecycle exactly.
  The first exited without warning but left one unlocked nonempty helper
  directory. The second emitted `Directory not empty (os error 39)`, converted
  the first residue to an empty no-lock directory, and left a new unlocked
  nonempty helper directory. Both probe residues were quarantined and removed
  through `/home/rioyokota/.codex/tmp/arg0-probe-cleanup-20260722.manifest`;
  that manifest was also exact-unlinked after verification.
- This matches the upstream janitor's lock lifetime: it keeps the acquired
  `.lock` file open while recursively deleting its directory. On this NFS
  filesystem the open file prevents the final directory removal. This is a
  confirmed local mechanism, not merely an accumulation symptom.
- Shared Codex/Claude guidance now makes this inventory part of every routine
  housekeeping request: held locks are live, eligible directories must pass
  owner/type/age/layout checks, candidates move to same-filesystem quarantine
  while locked, and only the quarantine goes through guarded-delete. This
  procedural rule does not modify the official launcher.
- Shared-instruction discovery passed its focused Claude takeover test, and the
  clean-checkout `tests/test-phase1.sh` gate passed every focused suite plus the
  guarded-delete regression suite on 2026-07-22.
- The smallest deterministic workaround that preserves current processes is a
  version-scoped launcher wrapper: retain the exact official binary, move only
  unlocked prior-session directories to a private quarantine while holding
  their locks, invoke the official binary, then guarded-delete the quarantine.
  The owner explicitly authorized installing and testing this mutation. An
  official upgrade may replace it safely but requires revalidation if the
  upstream defect remains.
- Working files are `libexec/harness-codex-arg0-housekeeping`,
  `libexec/harness-codex-arg0-wrapper`,
  `libexec/codex-arg0-launcher-wrapper`, and
  `tests/test-codex-arg0-wrapper.sh`, with dispatch, focused-suite, shared
  instruction, and client-documentation updates.
- The focused suite proves held-lock preservation, old empty and unlocked
  expected-layout cleanup, observed-exit cleanup without a grace delay,
  unexpected-layout retention, guarded quarantine deletion, official output
  and exit-status preservation, exact binary rollback, and automatic recovery
  at each injected installation failure point. The live plan resolves only the
  current official 0.145.0 Linux standalone release and reports no process
  action.
- Local commit `0a2ff82` contains the implementation. Its clean-checkout
  `tests/test-phase1.sh` run passed all 61 focused suites, including the new
  wrapper suite, followed by the guarded-delete regression suite. Native MPI
  remained the expected environment-gated skip. The owner subsequently
  authorized this branch push and removed the global harness-specific
  explicit-push requirement; the prohibition on changing remotes remains.
- Post-test routine housekeeping preserved three held-lock live directories,
  removed two eligible empty directories through guarded-delete manifest
  `/home/rioyokota/.codex/tmp/.harness-delete.xvoLBZ/manifest`, retained seven
  younger-than-grace empty directories, and found zero unexpected entries. The
  helper exact-unlinked the manifest and its empty private state directory
  after protected anchors and target absence verified.

**Next exact action:** push the local branch and complete protected review. After
merge, apply from clean current main, verify two warning-free short invocations,
a nonzero-exit fixture result, remote-control status, held-lock identities,
residue counts, doctor, and exact rollback plan.

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
