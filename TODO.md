# Personal harness task board

This is the authoritative resume point for the portable Codex and Claude
harness. Keep only active decisions, blockers, exact next actions, and compact
completion pointers here. Full pre-housekeeping chronology remains available at
published commit `d797d8658ea249f40f1acef1e84fcbbd83b0d6ff`.

Next free ID: T-284.

## Current state

- The public harness is on protected `main`. Fetch before work and before push;
  preserve contributor commits and never force-push.
- Managed Linux environments are `local`, `ab`, `ab2`, `ri`, `al`, `rc`, and
  `t4`. `abci_login` and `alps_login` are transports; retired `si` is not a
  target.
- Three currently reachable personal Macs have completed public/private Git,
  Homebrew, Bash, tmux, SSH, and agent convergence. Their repositories are
  clean/equal, Mac and agent doctors are ready, and each has one native SSH
  agent. One owner-operated Mac remains availability-gated and must be handled
  independently.
- Exactly one future native weekly primary backup job exists on each managed
  Linux node. The first run passed on all seven nodes on 2026-07-19. No login-
  node cron, user timer, retention deletion, or automatic replica job exists.
- All seven Restic primaries and independent encrypted generations have passed
  full-data checks and verified restores. Keep-all remains effective.
- Harness and website `main` rulesets require their protected CI check, linear
  history, resolved conversations, and force-push/deletion protection. Required
  approvals intentionally remain zero.
- Global safety and collaboration invariants in `.codex/AGENTS.md` remain
  authoritative. Never inspect credentials or use raw recursive/bulk deletion.

## Next resume checkpoint

1. When the remaining Mac is online, resume T-268/T-269 through the one-host
   onboarding workflow. Do not infer its state from another Mac or batch it.
2. On or after 2026-07-26, query only T-196's seven recorded successor job IDs.
3. Choose another independently eligible T-273 workstream only after fresh
   reconstruction of its gate and authority.

## Active tasks

### T-283 — Create and self-refine symmetric Codex–Claude cowork skill

**Phase/status:** `executing`; owner requested on 2026-07-20 that Codex drive a
six-hour, file-mediated collaboration with Claude to create
`codex-claude-cowork`, then use the new skill to refine itself. The original
request explicitly authorizes proceeding through planning, evidence discussion,
and driver execution; no unresolved owner decision remains.

**Execution checkpoint:** the plan/interview audit found zero unresolved
material choices. The owner's original instruction is the explicit go for the
frozen scope. First executable step: create the task branch and initialize the
shared skill skeleton without changing live client settings.

The canonical initializer's direct invocation failed with exit 126 because its
installed file is not executable (`Permission denied`); it created no skill
directory and changed no target state. Retrying the same reviewed Python source
through `python3` is safe.

Initialization through `python3` succeeded. The first focused test exposed and
then corrected two test-only defects: an over-specific wording assertion and an
incorrect guarded-cleanup call. Its leaked empty temporary directory and the
compiler-created skill `__pycache__` were each removed through verified guarded
deletion; the source trees and protected anchors were unchanged. The canonical
quick validator, cowork focused test, Claude takeover test, source-contract
test, public-repository audit, and `git diff --check` now pass. Working files are
the new shared skill directory, `tests/test-codex-claude-cowork-skill.sh`,
`tests/focused-suites.tsv`, and this ledger. Next action: install the new
discovery links, then begin the Codex-driver/Claude-co-pilot sandbox round.

Round 1 used commit `35ed1db` as a matched baseline in two no-hardlink detached
sandboxes; its complete exchange evidence is under
`docs/audits/t283-cowork-round1/`. Codex and Claude independently reproduced
acceptance of extra and symlinked protocol entries. Claude found the distinct
reverse-mapping defect: Codex 0.144.6 rejects `--ask-for-approval` after `exec`.
Both agents reproduced the corrected global-before-subcommand form and, after
reciprocal tests, agreed on a closed top-level set with a real `artifacts/`
directory. A failed ready transition additionally proved that the v1 TODO regex
false-positives on ordinary wrapped evidence; Claude repaired its owned file and
both sides froze an exact-standalone matcher. Driver execution implemented only
those changes. Canonical skill, focused cowork, Claude takeover, source,
public-audit, and diff checks pass. The first full phase-1 run passed 52/53 and
failed only the tmux suite's intentional clean-committed-checkout prerequisite;
retry is safe after checkpointing this reviewed round. No settings, credentials,
packages, remotes, or external systems changed.

Checkpoint commit `9325af8` made the validation checkout clean; the subsequent
full `tests/test-phase1.sh` retry passed every focused suite and the umbrella
gate (native MPI correctly skipped outside a declared MPI environment). Round 1
is ready to close. Next action: advance its session to complete, checkpoint the
result, then run the required reverse-role round with Claude driving Codex.

**Outcome and scope:** add one shared personal skill discoverable by both Codex
and Claude. Its role contract must be client-neutral: the active client is the
driver and the other client is the co-pilot. Both must reconstruct repository
state, exchange bounded public-safe artifacts through a declared session
directory, independently exercise the proposed plan in disposable sandboxes,
criticize evidence rather than personalities, reconcile disagreements into a
frozen plan, and permit only the driver to execute that plan against the target.
Include deterministic protocol checks, focused tests, product-neutral core
instructions, and only the small client-specific invocation mapping needed for
Codex-driving-Claude and Claude-driving-Codex.

**Confirmed inventory:** `main` was clean/equal to `origin/main` at
`d44a99e3ac671beae4bc8b99a6b5bc874151dd38` after a fresh authenticated fetch.
Claude Code 2.1.207 and Codex CLI 0.144.6 are installed. `install.sh` already
links every `shared/skills/*` directory into Codex, Agent Skills, and Claude
discovery locations. The repository has no existing cowork protocol. The
canonical skill initializer and validator are available under the installed
`skill-creator` skill.

**Plan and ordering:** (1) freeze the role/state/file protocol and sandbox
boundaries; (2) initialize the skill with `SKILL.md`, OpenAI UI metadata, a
single protocol reference, and the smallest deterministic session validator;
(3) add a focused shell test for structure, state transitions, role symmetry,
owned-file boundaries, and both native client invocation mappings; (4) run
skill validation and focused tests; (5) install the discovery links; (6) use
Codex as driver with Claude as co-pilot on a synthetic sandbox refinement;
(7) reverse roles so Claude drives and invokes Codex on another synthetic
sandbox refinement; (8) reconcile evidence, revise the skill, repeat bounded
adversarial rounds during the requested work window, and independently rerun
all acceptance checks; (9) checkpoint evidence and the exact next action here,
commit only intended files, but do not push without explicit authorization.

**Safety, recovery, and non-goals:** co-pilots may write only inside disposable
sandboxes and the declared exchange directory; they may not mutate the target,
Git refs, credentials, settings, services, packages, remote systems, or external
messages. Follow the closest repository authority and deletion policy; retain a
failed sandbox until it can be removed safely. Preserve unrelated work. A
client timeout or denial is retry-safe after inspecting its exchange files.
This task does not alter live client configuration, authentication, plugins,
connectors, MCP servers, or remotes and does not publish the harness.

**Acceptance:** the skill passes the canonical quick validator, its focused
test, `tests/test-claude-takeover.sh`, `tests/test-source-contract.sh`,
`tests/test-public-repo-audit.sh`, `git diff --check`, and
`tests/test-phase1.sh`; isolated installation exposes one identical skill to
all three discovery roots; both driver directions produce schema-valid file
artifacts and sandbox evidence; the final diff and ledger contain no private
data; and a clean reviewer can reconstruct the last verified step and next
action from Git plus this entry.

### T-282 — Compact the ledger and remove proven-obsolete repository residue

**Phase/status:** `complete`; the owner authorized repository housekeeping on
2026-07-20. The compact ledger, exact ref cleanup, protected publication, and
post-merge one-branch verification are complete. Scope was the public harness
repository and the now-eligible
T-273 `.bash_common` check on the three reachable Macs. It excludes backup
payloads, retained transaction evidence, credentials, caches outside the
repository, live configuration beyond the exact check, package/scheduler
changes, and speculative deletion.

**Verified preflight:** A value-free retry found `~/.bash_common` absent—not a
symlink or other object—on Aist, Home, and Office. The first Home probe was
read-only and failed only because it assumed the already-absent path was a
regular file; no state changed. T-273 workstream 9 is therefore closed for all
reachable Macs without quarantine or deletion. The remaining Mac retains its
post-onboarding gate.

The repository has one worktree and a clean `main`. There are no untracked
files. Ignored `node-backups/` is retained backup data and is excluded. The two
`.tmp` paths found under `evaluation/seeds/destructive-safety/` are tracked test
fixtures and are excluded. No repository file is eligible for deletion.

Branch preflight found nine non-current local branches and 56 remote branches
whose exact head names are tied to merged pull requests. One additional local
and remote T-281 checkpoint branch is an ancestor of merged PR #157. Open PR
#126 is a stale T-276 planning-only snapshot superseded by the completed T-276
state on `main`; its branch has no unique active work. Removal is limited to
those proven-obsolete refs plus the eventual T-282 task branch after merge.

**Execution/acceptance:** replace the 4,135-line chronology with this compact
active ledger while retaining the published history pointer; validate the
result against repository instructions and active gates; close superseded PR
#126; delete only the exact reviewed obsolete local/remote refs; run focused
ledger/source/privacy checks and `git diff --check`; publish through protected
CI; then verify one worktree, only `main`, no stale remote task branches, clean
Git, and unchanged excluded files/data. Any open, unmatched, or ambiguous ref
must be retained.

**Execution checkpoint:** the ledger is now 196 lines and retains every active
gate, all seven successor job IDs, the remaining-Mac boundary, and the full
history pointer. Diff, source-contract, public-repository, and repository-
independence checks pass. PR #126 was revalidated as open, planning-only, and
limited to stale `TODO.md`; it was closed and its remote branch removed. A
concurrent cleanup removed 39 already-reviewed remote refs before the planned
push, so the exact-count safety check stopped without issuing that push. Fresh
reconstruction then found 18 remaining merged-PR refs plus the T-281 checkpoint
proven ancestral to merged PR #157; those 19 refs were deleted explicitly.
Nine local refs tied to merged PRs and the same verified checkpoint ref were
also deleted. Current local refs are `main` plus active T-282; remote refs are
`main` plus active T-282; there are no open PRs except the forthcoming T-282
publication. No repository file, ignored backup, tracked fixture, transaction
evidence, Mac configuration, package, process, or scheduler state was removed
or changed by housekeeping. Focused validation passed before publication.

PR #159 passed protected `portable-phase1` and merged as `5a060e9`. Its task
branch was deleted. Post-merge verification found one worktree, exactly local
`main` and remote `origin/main`, zero open PRs, and a clean/equal checkout.
T-282 is complete; the excluded backup data, tracked fixtures, transaction
evidence, and external machine state remain unchanged.

### T-273 — Resolve intentionally deferred maintenance

**Phase/status:** `executing`; workstreams 1, 2, and accessible-host portion of
9 are complete. Every remaining workstream retains its own availability, time,
process, requirement, freshness, or explicit-authority gate.

1. **Failed transaction evidence — complete/retain.** Value-free audits found
   two failed groups on `local` and one on RC. Their small size, age, and paired
   manifests do not prove redundancy. No public operation-specific cleanup
   contract proves their recovery preimages unnecessary, so fail-closed
   retention remains final. Both hosts were clean/ready at acceptance.
2. **Checksum-pinned Linux agent replacement — complete capability.** PR #143
   published `1ed9712bc8c3fd4896df2654b2a3379412e5984d`. Synthetic replacement,
   interruption recovery to the immediate predecessor, exact rollback,
   guarded proposed-tree removal, downgrade refusal, and idempotence pass. The
   repository version pin remains unchanged; no live replacement or old-tree
   cleanup is authorized.
3. **Remaining Mac — availability-gated.** Onboard the one remaining Mac under
   T-268/T-269, one host at a time. Revalidate identity, transport, native agent
   ownership, public/private cleanliness and compatibility, and value-free
   plans before any apply.
4. **Backup successors — time-gated.** On or after 2026-07-26, query only the
   seven T-196 successor IDs. Do not replace or duplicate a delayed job.
5. **Vendor arg0 temporary directories — process-gated.** Re-inventory `local`
   only after every Codex process exits. Do not inspect payloads. Any eligible
   multi-directory cleanup must use `harness guarded-delete`; otherwise retain.
6. **Container capability — requirement-gated.** Resolve absent Docker/Podman
   on `local` and Singularity/Apptainer capability on RI only against a concrete
   project need. Do not install a generic stack for warning parity.
7. **One-way `local`→`t4` SSH mirror — separate authority.** Revalidate the
   frozen plan and execute only after explicit owner authorization for that
   exact external mutation.
8. **Package maintenance — freshness/selection-gated.** Recheck inventory and
   select only harness- or active-project-required packages. No blanket
   upgrade, cleanup, cask, service, tap, autoremove, or unmanaged-dependent
   mutation is implied.
9. **Orphaned `.bash_common` — accessible hosts complete.** Office completed
   quarantine/retest/restoration/exact-unlink previously. Aist completed its
   content-blind exact unlink during T-281. Fresh 2026-07-20 classification now
   confirms Aist, Home, and Office all absent. Repeat the ordered check only on
   the remaining Mac after its independent onboarding acceptance.

**Closed non-goals:** plugin/MCP/connector authorization, accounts,
administrator settings, automatic publication, background/login mutation, and
active-session reload have no identified requested outcome. Unknown profiles
and the retired `sshservice-cli` lost in the 2026-07-15 incident remain
non-reconstructable and must not be guessed back into existence.

### T-196 — Backup lifecycle phase 2

**Phase/status:** `policy-resolved`, execution-gated on eight successful weekly
chains, two verified restores per node, and a current verified independent
generation. Current progress is 1/8 on every node.

The captured 2026-07-26 successors are:

| Node | Recorded job ID |
| --- | --- |
| `local` | `91840` |
| `ab` | `2048464.pbs1` |
| `ab2` | `2048468.pbs1` |
| `ri` | `7242` |
| `rc` | `212389` |
| `t4` | `8194556` |
| `al` | `4238363` |

On or after eligibility, identity-match and query only these IDs. Record
terminal success, snapshot succession, warning silence, and chain count. Treat
delay as healthy; do not replace or duplicate a pending job. Keep-all remains
effective. No `forget`, `prune`, recurring check/restore, or replica automation
is authorized. Policy and evidence remain in
`docs/backup-lifecycle-phase2.md`, `docs/home-backup.md`, and
`docs/audits/restic-first-weekly-2026-07-19.md`.

### T-268/T-269 — Finish the private personal-Mac fleet

**Phase/status:** `availability-gated`; three reachable Macs are accepted and
one owner-operated Mac remains. Generic public engines and private-companion
schemas are published. The remaining host must use the current
`onboard-personal-mac` workflow from an owner-started local session, with
pull-based long-gap catch-up and no dependency on another repository.

For the remaining Mac, fetch current public/private `main`, perform value-free
identity/architecture/Homebrew/Command-Line-Tools/Git/native-agent discovery,
plan only applicable stages, wait at any password/TCC/reboot/physical boundary,
and exercise transactional apply/rollback/reapply plus fresh-session and doctor
acceptance. Private values and host identity remain outside this public ledger.
Do not batch it with an accepted Mac, infer state, synchronize credentials,
change Terminal/Keychain/zsh, reload an active session, or install unselected
packages.

T-269's accepted scope is one canonical public copy of Codex/Claude policy and
configuration with local symlinks, prompt-free ordinary sessions, official
native client ownership, and SSH-only private agreement. Plugin, connector,
MCP, authentication, and account authorization remain separate.

### T-275 — One-command Codex bootstrap for the remaining Mac

**Phase/status:** `published`; available only as a bounded stage inside the
remaining Mac's onboarding. It can install missing declared prerequisites and
official native Codex ownership after exact plan/review. It is not permission
for packages, authentication, plugins, connectors, background services, or
another host.

## Completed anchors

- T-282 compacted the active ledger and removed verified-obsolete refs: PR #159,
  published `5a060e9`.
- T-281 three-Mac environment convergence: PR #158, published `d797d86`.
- T-280 independently onboarded Home; T-279 repaired its Bash drift.
- T-274 unified Bash startup and published the Mac onboarding skill.
- T-272/T-271/T-270 completed accessible-fleet maintenance and cleanup.
- T-191 accepted the first native weekly backup runs on all seven nodes.
- T-181 acceptance evaluation completed at 69/70 with zero safety failures.
- T-210 is complete and must not be repeated.

Consult Git history at or before `d797d86` for superseded plans, transaction
chronology, exact prior PR/run identifiers, and completed task narratives.
