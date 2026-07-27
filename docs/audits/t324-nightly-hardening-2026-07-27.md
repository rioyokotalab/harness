# T-324 nightly hardening audit

Started 2026-07-27 22:13 JST. Material-change cutoff is 2026-07-28
04:13 JST; final deadline is 05:13 JST.

## Housekeeping

Local arg0 planning initially reported `live=5 eligible=2 young=0
unexpected=0`. The lock-aware apply quarantined and guarded-deleted one exact
three-entry/eight-byte target representing the two eligible completed
invocations. Protected anchors were unchanged. Final planning reports
`live=5 eligible=0 young=0 unexpected=0`.

## Repository matrix

| Repository | Git / preflight | Dependencies and tests | Hosting controls |
| --- | --- | --- | --- |
| Harness | isolated T-324 branch clean; hardening audit zero findings | all 75 focused suites, guarded-delete coverage, and phase-one integrations pass; only declared native MPI smoke skipped outside an allocation | zero Dependabot/secret alerts; read-only Actions; SHA-pinned workflow |
| Students | clean/current `main`; hardening audit zero findings | `uv lock --check` and full offline gate pass, 97 tests | zero Dependabot alerts; private secret fallback retained |
| Swallow | active AB task branch and T4 `main` clean/aligned after fetch; hardening audit zero findings | AB login-safe static, secret, portability, SW-030, and SW-031 gates pass | zero Dependabot alerts; private secret fallback retained |
| Website | clean/current `main`; hardening audit zero findings | npm audit zero findings; full security/supply-chain suite passes | zero Dependabot/secret alerts; read-only Actions; SHA-pinned workflow |

All four live rulesets preserve deletion/non-fast-forward protection, strict
required checks, linear history, and conversation resolution. Live approval
count is zero in all four; Students also has code-owner and last-push approval
disabled. This conflicts with frozen T-311 D-001 (one review everywhere and
stronger Students gates). Website already records the same zero-review drift.
Hosting administration is separately gated, so no ruleset write ran; the
exact drift is deferred for owner reconciliation.

## Fleet matrix

- Canonical fleet health passed all eight Linux logical nodes, including both
  ABQ routes, and all four Mac route pairs.
- Native Linux doctors passed with only the declared requirement-gated
  container warnings on Local and RI. All four native Mac doctors passed with
  zero failures/warnings.
- Every Linux weekly backup successor is present and active for 2026-08-02;
  every captured smoke successor remains verified absent. The exact RI
  accounting retry for old job `7242` again failed before lookup because
  Slurm DNS SRV discovery could not establish a configuration source.
  Successor `10386` was not queried or changed.
- Declared persistent/cache storage is ready on every Linux node. Local's
  shared `/home` filesystem reports 96% used, but the owner account consumes
  about 3 GiB, has about 2.2 TiB available there, and has about 154 TiB free
  in each declared storage class. This is external shared-capacity pressure,
  not a safe owner-cleanup target.
- FileVault, SIP, Gatekeeper, managed firewall/stealth, and signed-app policy
  pass on all Macs. Native update checks report no available software. The
  Home-only wildcard listener is signed Pharos Notify on vendor-documented
  TCP 28201; it is expected print-client functionality. No current-user-owned
  Linux TCP listener or failed user systemd unit was found.
- Both managed tunnel supervisors and the watchdog are loaded, running, and
  healthy on every Mac with `managed=1 external=0`. Aist, Home, and Riken have
  the expected one-window detached Codex resume session. Office also has one
  childless detached login-shell window created 2026-07-26 in that session.
  The managed Codex window is healthy; the owner shell is preserved and exact
  removal is deferred.
- Official release metadata reports Codex `0.145.0` and Claude Code
  `2.1.220` as current; every system runs those effective versions. Aist/Home
  Codex path duplicates collapse to one canonical target. Riken alone has a
  second distinct global npm Claude package at stale version `0.2.14`, behind
  the effective managed `2.1.220` launcher. Package removal is separately
  gated and is deferred with the exact package selected.
- All twelve agent-config outputs report 16 shared skills. The compact Harness
  current-state text incorrectly said 15 and was corrected to 16 without
  changing runtime configuration.
- Eleven remote project-agent doctors passed. Local's project-agent doctor is
  unknown because its explicit clean-checkout gate sees the preserved live
  supervisor-held `.nfs` inode. Two disposable-view exclude spellings failed
  closed; no live inode or safety check changed. Guarded deletion removed the
  exact 4,457-entry / 51,190,482-byte diagnostic clone and its manifest was
  exact-unlinked.
- Effective SSH policy matches the owner-selected forwarding, 30-second
  timeout, and persistent multiplexing contract. RI repeatedly rejects X11
  forwarding and lacks `xauth`; this is a site/package capability gap, not
  authorized package or sshd work, so it is deferred. Other currently
  multiplexed Linux sessions do not provide uniform DISPLAY evidence; no
  master was restarted merely for this audit.
- Native `codex doctor --json` passed all required local checks on Local and
  the four Macs. All seven managed Linux clients reported the same
  `installation`/`updates.status` failure because npm's mutable global package
  root differs from the current immutable Harness-owned release tree. AB and
  T4 have no package at the reported npm root, proving this is not stale
  package residue. The resilience supervisor consumed `installation` as a
  terminal post-failure gate, so a transient client exit could strand an
  otherwise healthy managed session. The correction tolerates only native
  doctor's exact Linux ownership-warning summary when its managed and running
  package roots are identical inside the versioned Harness agent tree and the
  root is a current-user-owned real directory. The field parser is bounded to
  the exact `installation` object, so missing data cannot be borrowed from a
  later check. All other doctor and platform failures retain their prior
  terminal behavior. Focused tests cover compact healthy checks, the valid
  Linux exception, cross-object data, mismatched roots, and Darwin fail-closed
  behavior.
- Current-user zombie counts are zero on all eight Linux logical nodes.
  System-wide failed-unit counts are Local 0, AB 250, AB2 17, RI 1, AL 4,
  RC 2, T4 0, and ABQ 0. AB/AB2 entries are historical session scopes. RI's
  `logrotate.service` failed at 2026-07-27 00:00 JST; AL reports failed
  binfmt mount/automount, GDRCopy, and PALS services; RC reports failed
  NetworkManager wait-online and another account's user manager while this
  account's user manager is running. These are shared-site system services
  requiring administrator authority. They were recorded without reset,
  restart, log-content inspection, or mutation.
- Current-user world-writable regular-file counts are zero beneath every
  present managed Harness/agent release root on all eight Linux nodes.
  Current-user broken-link counts are likewise zero beneath each present
  `.local/bin`, Harness release, and agent release root.
- Local alone has a root-owned reboot-required marker. It currently runs
  `6.8.0-134-generic`; installed `6.8.0-136-generic` and `linux-base` are named
  by the marker. The other seven Linux logical nodes have no such marker.
  Rebooting the control-plane host is an explicit coordination boundary and
  was deferred without process or service interruption.
- Native owner-queue readback on AL, RC, T4, and ABQ shows only the exact
  declared weekly backup successors `4275926`, `260847`, `8270230`, and
  `176525.qjcm`; none was changed. RI's `squeue` fails at the same DNS SRV
  configuration-source boundary as its accounting query, so its queue remains
  unknown and successor `10386` remains untouched. AB/AB2 do not expose their
  PBS client in the ordinary login environment; their already-verified
  Harness backup status remains the authoritative readback.
- Fresh `harness restic-primary check` snapshot enumeration passed on all
  eight primary repositories using each existing credential only by path.
  Native Restic structural checks then loaded indexes and checked pack
  references, snapshots, trees, and blobs on all eight without `--read-data`,
  snapshot creation, unlock, forget, or prune. Private output stayed in
  mode-0600 captures; all captures were exact-unlinked and all repository lock
  directories returned to zero entries.
- Independent replica roots remain available but unchanged and older than the
  July 26 primaries: Local/AB/RI/AL/RC/T4 latest generation
  `20260715T222741Z`, AB2 `20260716T023458Z`, and ABQ
  `20260722T092250Z`. T-196 requires a manual restore gate before a new
  immutable generation; no replica copy, promotion, or deletion is authorized
  or attempted.
- Epoch readback is within the one-second probe window on all eight Linux
  nodes and all four Macs. Every Linux node reports system time
  synchronization active; macOS exposes no matching unprivileged status field
  but has zero observed skew.
- Post-validation residue readback found zero task-owned phase-one,
  resilience, focused-runner, Restic-check, or guarded-delete temporary roots
  under Local `/tmp`. Primary Restic repository roots are current-user-owned
  real directories with effective mode 0700 (setgid 02700 on applicable
  project filesystems).
- A 30-cycle live monitor ran through 2026-07-28 00:01 JST. Every exact PR-head
  query remained successful and merge-clean; six canonical fleet sweeps passed
  all eight Linux logical nodes and both routes for every Mac. One GitHub
  status query was slow but completed successfully without retry or mutation.

## Repository housekeeping

Two old Harness worktrees were clean, unlocked, unused by any live cwd/open
file, and matched exact merged PR heads: `codex/t322-execute-rename` at PR
#360 and `t318-codex-thread-recovery` at PR #340. Two guarded transactions
removed only their exact 883/881-entry worktree trees and exact 10-entry Git
registration directories. Fresh PR-head and remote-ref readback then gated
deletion of only those two merged local and remote branches. T-324's worktree,
the primary checkout, and the live `.nfs` inode remain.

Fourteen additional Harness remote branches were deleted only after each
current remote head exactly matched its merged PR head (T-311, T-320, T-321,
T-322, and T-317 branches). Three T-303 evidence/blocker branches plus
T-314/T-316 branches without an exact merged-PR proof remain preserved.
Ten local T-317/T-321/T-322 counterparts remained after that remote cleanup.
Fresh worktree readback proved only `main` and active T-324 checked out, so
those local refs were removed using the already-recorded exact merged-PR
proof. Their deleted abbreviated commits remain in the command record.
Website's sole stale task branch exactly matched merged PR #36 and was deleted;
fresh readback leaves only `main`. Repository auto-delete-on-merge remains
disabled and is a hosting-policy choice, so it was not changed.

Website has one clean `main` worktree and no merged local branch residue.
Students changed concurrently from clean `main` to a project-owned task branch
during this audit and most recently reports
`task/t-013-skill-driven-sol` clean at `d9e9a4a`; no takeover or mutation ran.
Swallow's active AB project branch also advanced concurrently and is clean at
`edef7f9`, while its additional registered SW-013 worktree and T4 mirror
remain clean. Those
project-owned experiment refs are preserved for the Swallow agent rather than
treated as generic Harness residue. Fresh prune dry-runs report no stale
remote-tracking refs in any repository.

Remote Linux arg0 inventory found one eligible completed residue on AB, AB2,
RI, RC, T4, and ABQ and none on AL. Each owning node's lock-aware guarded
apply removed only its exact quarantine target (seven entries and about
8.8 KiB each). Final planning reports zero live, eligible, young, unexpected,
or leftover guarded-manifest directories on all seven nodes.

Local exact-unlinked ten stale current-user-owned, mode-0600, single-link T-295
guarded manifests after proving no open descriptor. The exact 225-entry /
602,089-byte pytest root created by tonight's validated Students run was
guarded-deleted with protected anchors unchanged. Ambiguous historical
browser, image, and Swallow research artifacts remain preserved.

## LIFO execution issues

1. Checkpoint `1734f1d` was pushed directly to `main` and accepted through an
   owner bypass despite required PR/check policy. The intended bytes are
   correct, but the route was wrong and non-retryable. Subsequent work moved
   to isolated branch `codex/t324-nightly`; no history rewrite will conceal
   the failure.
2. Seven backup status commands first ran on Local and refused host mismatch.
   Correct native-node retries passed.
3. The first capacity probe failed locally from nested SSH quoting. The
   corrected value-free home/declaration probes passed.
4. The first executable-cardinality probe used unsupported `command -v -a`
   and produced false zeros. The corrected `type -a -p` plus canonical-target
   check found the exact Riken duplicate above.
5. The first clean-clone full-suite launch named the not-yet-created clone as
   its working directory and failed before process creation. The retry from
   `/tmp` passed. Guarded deletion then removed only the exact 926-entry /
   22,765,943-byte validation clone with protected anchors unchanged; its
   manifest was exact-unlinked.
6. A validation command referenced nonexistent `tests/test-hardening.sh`
   after its preceding resilience and login suites passed. The corrected
   repository test name, `tests/test-hardening-audit.sh`, passed; the failed
   command made no change.
7. The first post-fix full suite inherited the live launcher
   `HARNESS_ROOT` and made tmux validation inspect the separate primary
   checkout, whose expected live `.nfs` inode failed its clean gate. The
   phase-one entry point now clears that process-only variable. A validating
   rerun then correctly inspected the task worktree, but its intentional
   uncommitted test-isolation patch caused the tmux and terminfo clean gates
   to refuse. Both failures were deterministic and safe; the subsequent clean
   committed head passed all 75 focused suites and phase-one integration.
8. A fresh commit-to-pull-request association query returned empty after the
   corresponding remote refs had already been deleted. It made no change and
   did not supersede the durable same-night proof that each exact remote head
   matched a merged pull request; local deletion used that prior proof plus a
   fresh worktree-ownership check.

Every failed probe was read-only and retry-safe unless explicitly marked
non-retryable. No credential, pane, transcript, deployment, message, package,
hosting setting, or unrelated repository state changed.

## Primary evidence

- OpenAI Codex release:
  <https://github.com/openai/codex/releases/tag/rust-v0.145.0>
- Anthropic Claude Code release:
  <https://github.com/anthropics/claude-code/releases/tag/v2.1.220>
- Pharos native port table:
  <https://doc.pharos.com/uniprint/Content/ports.htm>
