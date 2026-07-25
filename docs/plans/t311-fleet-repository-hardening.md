# T-311 fleet and repository hardening

## Outcome

Reduce confirmed security and reliability risk across the managed Linux and
macOS fleet and the independent `harness`, `students`, `swallow`, and `website`
repositories. Preserve each repository's own policy, task board, branch,
tests, publication route, and runtime authority. Add a reusable harness skill
and value-free commands only after their behavior is validated by this run.

The execution window ends at 2026-07-26 05:00 JST. Stop starting material work
at 04:30, enter final validation and cleanup by 04:45, and leave every
unfinished item restartable in its owning repository by 05:00.

## Scope and non-goals

In scope:

- owner-controlled user files, managed harness configuration, repository code,
  CI, task ledgers, dependency locks, and repository-scoped GitHub settings;
- value-free audits of all eight logical Linux nodes and all four managed Macs;
- existing owner-sandbox Sensei-gent units while every student-facing unit
  remains disabled;
- T4's private Swallow checkout after its pre-existing SW-017 work is clean;
- narrowly staged administrator changes only when the interview explicitly
  authorizes them and their validation and rollback are complete.

Not in scope without a separate frozen decision:

- credentials or credential contents, organization-wide GitHub settings,
  student contact, production Slack messages, model or dataset publication,
  paper or compute submission, blanket package upgrades, destructive cleanup,
  site-managed HPC operating-system changes, disk repartitioning/encryption,
  or interruption of an existing Codex/Claude session.

Repository work is independent. A repository receives its own task ID, branch
or isolated worktree, TODO entry, tests, commits, pull request, and handoff.
No project imports another project's scripts, policy, artifacts, or mutable
state. Harness may provide reusable orchestration, but is never a project
runtime dependency.

## Confirmed baseline

### Fleet

- All eight logical Linux nodes and all four primary Mac routes were reachable
  during discovery. Every managed harness checkout was clean at
  `e9c3e060fc8f4b4496331b1235ca23dcb21d79b0`.
- Linux homes and SSH directories are mode 0700; the canonical SSH fragment is
  a regular mode-0600 file everywhere. Harness doctor has zero failures on
  every Linux node, but emits the now-expected project-scoped
  `codex_rules=not-installed` warning everywhere.
- Local's shared `/home` export is 95% used with about 2.4 TiB free; the NFSv4
  project volume holding `students` and `website` is 1% used. This is a shared
  capacity risk, not evidence that the owner's projects consume the 41 TiB.
- Seven scheduled Restic successor jobs remain active. ABQ's primary repository
  check passes, but `restic-schedule status --host abq` fails because
  `profiles/restic-schedules.tsv` has no ABQ row; the command misleadingly
  calls both zero and duplicate rows “not unique.”
- Codex 0.145.0 matches the current published release on all nodes. Linux
  Claude is pinned at 2.1.207 while the current published release is 2.1.220;
  Office has 2.1.214, Aist/Home intentionally have no Claude command, and
  Riken's existing `/opt/homebrew/bin/claude` exits 1 even for `--version`.
- The four Mac Homebrew formula inventories are byte-for-byte equivalent
  (51 formulae). All Mac tunnel identities authenticate unattended and both
  launchd-managed routes report `running=yes managed=1 external=0`.
- FileVault, Gatekeeper, SIP, and automatic update scheduling are enabled on
  every Mac. The application firewall is disabled on every Mac. Current-user
  wildcard listeners include built-in sharing processes, Dropbox LAN sync,
  and an X server on Office TCP port 6000. X.Org recommends disabling TCP
  listening when it is not required.
- Home, Office, and Riken retain the same two unused 2018 RealPresence data
  files as mode 0666 in mode-0755 homes. No process has either open and no
  matching application remains. Removal or permission change is deferred to
  the interview and the guarded deletion boundary.
- No Mac reports a configured Time Machine destination. A sync client or local
  APFS state must not be represented as an independent backup.

### Harness

- Local `main` is clean/current. T-310 functionality is merged, while closeout
  PR #311 remains open with no check run after three GitHub Actions startup
  failures. Its isolated closeout branch has one unpushed evidence commit and
  explicitly forbids another push-only retry.
- The public repository has a strict ruleset and SHA-pinned least-privilege CI,
  but its GitHub defaults still grant workflow write permission and permission
  to approve pull requests. Repository secret scanning, push protection, and
  Dependabot security updates report disabled.
- Direct `github.com` SSH URLs do not match the canonical `Host github`
  exclusion, so they inherit agent and trusted-X11 forwarding. The students
  fetch reproduced an unnecessary X11 forwarding warning. The owner-selected
  default for future Linux nodes remains `ForwardAgent yes`.
- The first portable inventory probe expanded locally because it passed a
  double-quoted command string to SSH. Literal stdin delivery fixed it. The
  reusable audit must test expansion locality rather than trusting quoting.

### Students

- The private repository is clean on
  `task/t-002-report-japan-timezone`; PR #36 is open and its required Offline
  check was queued during discovery. Hardening must begin from reconciled
  protected `main`, not mix with T-002.
- Its ruleset requires one approval, code-owner review, last-push approval,
  thread resolution, and two strict checks; one admin bypass preserves owner
  completion. Default Actions permission is read and Actions cannot approve
  pull requests.
- Secret scanning, push protection, and Dependabot security updates report
  disabled. The three workflows pin actions and avoid persisted credentials.
  The `pull_request_target` boundary workflow checks out the trusted base, but
  still interpolates event fields directly into a shell command instead of
  passing them through environment variables.
- An OSV batch query on the locked production dependencies found
  `cryptography==46.0.7` affected by GHSA-537c-gmf6-5ccf. The upstream advisory
  fixes project wheels in 48.0.1. This application uses cryptography for the
  interaction ledger, so update and backward-compatibility evidence are P0.
- All five current private directories are mode 0700 and contain no weak-mode
  file; none is tracked. The world-writable `.venv/.lock` is enclosed by the
  owner's mode-0700 home and is not treated as an exposed file.
- Student-facing services remain disabled/inactive. The owner sandbox, report
  socket, and retention timer are active as intended. Systemd rates the
  services MEDIUM; capability, namespace, syscall-architecture, filesystem,
  temporary-directory, and process-view restrictions can be tightened.
- Local has no TPM device and its root ext4 filesystem is not encrypted. The
  machine-bound systemd credential protects the NFS ciphertext from the NFS
  store, but does not protect against a Local-root or offline-root-disk
  adversary. Do not overstate its at-rest guarantee.

### Swallow

- At the owner's readiness signal, T4's private repository is clean on `main`
  at `76de582`, equal to `origin/main`; its earlier SW-017 working state is now
  safely committed and no longer blocks an isolated hardening worktree.
- Project runtime, authentication,
  and private-evidence directories are mode 2700 and no private/runtime path is
  tracked. T4 project storage is 1% used.
- The GitHub repository has no ruleset, default Actions write permission,
  Actions pull-request approval enabled, no secret scanning/push protection,
  and no Dependabot security updates. Organization inheritance exposes
  66 write collaborators plus the owner admin. This is the highest confirmed
  repository-control risk.
- The project-local GitHub CLI authentication became unavailable from T4
  during discovery; Local's authorized GitHub capability could still read the
  repository settings. No credential was inspected. Revalidate task-scoped
  Git transport before creating the independent Swallow hardening worktree.
- Tracked code is remote-backed, but ignored models, checkpoints, raw
  profiles, logs, and runtime state have no declared independent backup.

### Website

- The public repository is clean/current with no active task. It already has
  a one-review/admin-bypass strict ruleset, read-only Actions defaults,
  SHA-pinned least-privilege PR-only CI, secret scanning, push protection,
  Dependabot security updates, and monthly grouped version updates.
- `npm audit` reports zero vulnerabilities across the four locked dependency
  records. No hardening change is justified unless a focused check finds a
  regression; the repository still receives its own audit task and handoff.

## Execution sequence

1. Freeze the decisions below, audit them for contradiction, set every new
   repository task to `ready-for-go`, and wait for explicit `go`.
2. Reconstruct all four repositories and mutable GitHub/service/fleet state.
   Do not touch an occupied or ambiguous checkout. Finish or defer pre-existing
   tasks through their own ledgers.
3. Create isolated task worktrees and add tasks to each repository's own
   TODO/session ledger. Put confirmed blockers above ordinary work.
4. Fix the P0 students cryptography advisory first on a branch based on the
   merged T-002 revision. Prove lock integrity, old-ledger decryptability,
   write/read/retention/report behavior, full offline tests, and live-unit
   compatibility before any owner-sandbox restart.
5. Establish Swallow's minimum protected-main and credential-free CI baseline
   after SW-017 becomes clean. Preserve the login/compute boundary: run its
   tests only in the approved AGE allocation. Never execute fetched private
   context repositories.
6. Apply the selected repository-scoped GitHub baseline transactionally.
   Capture exact preimages, change one repository at a time, read back settings,
   and roll back only the changed field if validation fails.
7. Implement harness fixes in small test-first increments: ABQ schedule
   classification/coverage, GitHub-host SSH exclusions, false-positive doctor
   warnings, a value-free hardening audit command, and the reusable
   `harden-fleet-repositories` skill. Keep accepted site/container gaps out of
   failure status.
8. Apply selected Mac user-level and administrator hardening one Mac at a
   time. Preserve both routes, validate remote control and the standard Codex
   tmux session, and roll back that Mac before moving on after any failure.
9. Run the website audit independently. Add no code merely for symmetry.
10. Fetch before every publication, commit small verified increments, use each
    repository's protected workflow, and never force-push. After merged harness
    changes, guarded-sync only clean managed checkouts and perform the required
    one-shot Mac context refresh.
11. By 04:30 stop starting material changes. Run focused/full regression,
    settings-readback, fleet-health, residue, branch, worktree, and ledger
    checks. At 05:00 record exact commits/PRs/settings, remaining blockers,
    retry safety, and next commands in the owning repositories.

## Issue and interruption contract

Pre-existing owner or agent work is never stashed. Each hardening stream uses
an isolated worktree. On the slightest new ambiguity or failed gate:

1. stop that repository's execution without hiding the failure;
2. preserve exact safe evidence and classify whether retry is safe;
3. commit a coherent validated partial increment when possible;
4. otherwise stash only this task's explicitly named WIP paths, never another
   worktree or broad untracked scope;
5. place the issue at the top of that repository's active TODO section with
   the stash identifier or commit, unchanged state, and next action;
6. continue only independent work in another repository.

No raw recursive deletion is permitted. Any multi-path or tree removal uses
the guarded-delete workflow and verifies protected anchors afterward.

## Validation and acceptance

- Every repository's own tests and protected CI pass for its changes.
- No pre-existing work is stashed, overwritten, or mixed into another task.
- The students advisory is either upgraded with compatibility evidence or is
  the first explicit blocker in its TODO; no student is contacted.
- Swallow `main` cannot be changed by an ordinary writer without the selected
  protected workflow, and its login/compute boundary remains enforced.
- GitHub permissions and rulesets read back exactly as frozen.
- Mac hardening preserves FileVault/SIP/Gatekeeper/update state, two managed
  tunnels, both inbound routes, remote control, and the existing Codex session.
- ABQ backup state is classified accurately and any selected schedule is
  identity-checked without replacing a pending job.
- The new hardening command and skill emit only value-free facts, distinguish
  accepted exceptions from failures, handle local/remote quoting safely, and
  validate for both Codex and Claude discovery.
- All checkouts, helpers, temporary logs, worktrees, stashes, and transaction
  artifacts are accounted for at handoff.

## Decision register

| ID | Decision | Recommended default | Status |
| --- | --- | --- | --- |
| D-001 | Protected-main model across four repositories | One review for non-admin writers, strict checks, linear history, owner/admin bypass | confirmed: option 1 |
| D-002 | Dependency and GitHub security automation | Read-only Actions defaults, Dependabot alerts/security PRs, monthly grouped updates, secret protection where available; never auto-merge | confirmed: option 1 |
| D-003 | Mac network posture | Firewall plus stealth, preserve signed/built-in access initially, disable Office X11 TCP, validate one Mac at a time | confirmed: option 1 |
| D-004 | Backup expansion | Add ABQ weekly scheduling now; plan Mac and Swallow backups separately rather than sweeping large/private state | open |
| D-005 | Agent/package refresh | Fix broken Riken Claude and update managed Linux Claude to 2.1.220; preserve intentional Aist/Home absence and running sessions | open |
| D-006 | Administrator boundary during unattended execution | Apply only already non-interactive narrow authority; stage exact helpers for password/TCC/root work at the top of the owning TODO | open |

D-001 consequence: standardize the protected-main floor across all four
repositories. Require one approving review from non-admin writers, strict
required checks, linear history, and resolved review conversations; preserve
an owner/admin bypass so owner-authorized work can complete unattended.
Retain `students`' stronger code-owner-review and last-push-approval gates.
Add the Swallow ruleset only after its credential-free required CI check exists
and passes, so protection never names an absent or unproven check.

D-002 consequence: make repository-default Actions permissions read-only and
disallow Actions from approving pull requests. Enable dependency graphs,
Dependabot alerts and security-update pull requests, plus monthly grouped
version-update pull requests for declared package ecosystems and GitHub
Actions. Enable native secret scanning and push protection where the hosting
plan supports them; where a private repository lacks that entitlement, use a
credential-free, pinned, reviewed CI check instead. Never auto-merge dependency
updates, and repair the currently confirmed Students cryptography advisory in
its own repository task.

D-003 consequence: enable the macOS application firewall and stealth mode on
each managed Mac while preserving signed and built-in application access.
Disable Office's exposed X11 TCP listener and retain local Unix-socket X11
behavior where available. Apply and validate one Mac at a time, proving both
reverse routes, managed tunnel ownership, remote control, and required local
services before advancing. These administrator changes remain subject to
D-006; an unavailable authorization must become a precise staged handoff
rather than an unsafe workaround.

## Evidence

- GitHub Actions permission guidance:
  https://docs.github.com/en/rest/actions/permissions
- GitHub Dependabot security update guidance:
  https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/configure-security-updates
- GitHub secret scanning availability:
  https://docs.github.com/en/code-security/how-tos/secure-your-secrets/detect-secret-leaks/enable-secret-scanning
- Apple firewall security:
  https://support.apple.com/guide/security/firewall-security-in-macos-seca0e83763f/web
- X.Org TCP-listener mitigation:
  https://www.x.org/Development/Security/Advisory-2014-12-09/
- Cryptography advisory:
  https://github.com/pyca/cryptography/security/advisories/GHSA-537c-gmf6-5ccf

## Next action

Ask D-004 only. After every answer, checkpoint the exact selection and ask the
next open decision. Do not execute hardening until all decisions are frozen
and the owner gives explicit `go`.
