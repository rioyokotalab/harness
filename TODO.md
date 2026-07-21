# Personal harness task board

This is the authoritative resume point for the portable Codex and Claude
harness. Keep only active decisions, blockers, exact next actions, and compact
completion pointers here. Full pre-housekeeping chronology remains available at
published commit `90451d49ac96`; T-288 planning and execution checkpoints are
commits `d57041d` and `9ddd2bf`.

Next free ID: T-290.

## Current state

- The public harness is on protected `main`. Fetch before work and before
  push; preserve contributor commits and never force-push.
- Managed Linux environments are `local`, `ab`, `ab2`, `ri`, `al`,
  `rc`, and `t4`. `abci_login` and `alps_login` are transports; retired
  `si` is not a target.
- All four personal Macs independently passed public/private Git, Homebrew,
  Bash, tmux, SSH, and agent onboarding acceptance. T-288 is reconciling later
  harness revisions and exact harness-owned residue without package changes.
- Exactly one future native weekly primary backup job exists on each managed
  Linux node. The first run passed on all seven nodes on 2026-07-19. No login-
  node cron, user timer, retention deletion, or automatic replica job exists.
- All seven Restic primaries and independent encrypted generations have passed
  full-data checks and verified restores. Keep-all remains effective.
- Harness and website `main` rulesets require their protected CI check,
  linear history, resolved conversations, and force-push/deletion protection.
  Required approvals intentionally remain zero.
- Global safety and collaboration invariants in `.codex/AGENTS.md` remain
  authoritative. Never inspect credentials or use raw recursive/bulk deletion.

## Next resume checkpoint

1. Resume T-288 at its exact next action until controller/Aist/Office
   housekeeping is published and accepted; checkpoint unavailable Macs.
2. On or after 2026-07-26, query only T-196's seven recorded successor job IDs.
3. Choose another independently eligible T-273 workstream only after fresh
   reconstruction of its gate and authority.

## Active tasks

### T-288 — Complete post-onboarding Mac and repository housekeeping

**Phase/status:** `executing`. The owner requested thorough housekeeping
after all four personal Macs completed onboarding, accepted a harness-only
scope, explicitly deferred all Homebrew/package work to a later task, restored
Aist access, reported Home unavailable, and instructed execution. Each live Mac
operation remains sequential and independently gated.

**Repository and host reconstruction:** authenticated fetch found protected
`main` at `90451d49ac96`; the first task branch began from a clean/equal,
single-worktree checkout with zero open PRs or untracked files. The sole ignored
top-level path is intentionally retained `node-backups/`. Initial post-go
probes reached Aist and Office; later probes reach only Office. Home, `riken`,
and Aist are currently unavailable and must receive exact resumable checkpoints
unless they return before closeout. All observed Macs
have clean public/private `main`, ready Mac and agent doctors, strict private
state metadata, and absent `.bash_common`, `run_this.sh`, startup backups,
and quarantine residue. Aist and Office are behind both remote mains. Planning-
time `riken` was behind public main and equal to private main.

**Retained state and exact anomalies:** transaction statuses on Aist, Office,
and planning-time `riken` are small, strict rollback/failure evidence without
a retirement contract and remain retained. Backups, active processes/sessions,
credentials, package/cache state, unknown residue, and private payloads are
excluded. Aist has two local T-280 public refs that raw ancestry does not prove
merged into its stale main; retain until current-main fetch plus patch/task-
provenance review. Aist and Office each had four unopened
`harness-macos-formula-policy.*` files. Controller discovery found 189 current-
user regular files of only that class, none open, aged about 0.1–15 hours.

**Defect, fix, and evidence:** the ordinary updater trap included the formula-
policy temporary, but the public-fast-forward re-exec path exact-unlinked the
other six target-validation temporaries, disabled the trap, and omitted this
one. `libexec/harness-macos-update` now exact-unlinks it before re-exec.
`tests/test-personal-macos-update.sh` confines updater children to a private
temporary root and asserts no target-validation leaf survives exercised plan,
apply/re-exec, failure, retry, or rollback routes. `sh -n`,
`git diff --check`, the updater/private-profile/public-audit/source-contract
focused gates, and the focused test pass. The first full phase-one run passed
every suite except `test-tmux-config.sh`, whose intentional clean-committed-
checkout guard rejected this uncommitted task tree. Its diagnostic explicitly
reports that gate; no behavioral test failed. Commit these intended files and
rerun the full suite from the required clean checkout was the recorded recovery
path. Commit `7bb2c56` is that checkpoint, and the clean rerun passed every
phase-one suite.

The first regression attempt used a process-wide `TMPDIR`, which placed the
guarded test-cleanup tool's own working files inside its deletion target.
Entry-count revalidation correctly refused cleanup; no live Mac or production
state changed. The override is now updater-child-only. The exact synthetic
target `/tmp/harness-macos-update-test.rfAtYv` was retained for fresh guarded
cleanup with controller residue. Retry was safe after exact identity and
boundary revalidation, and the acceptance below records its removal.

**Controller cleanup acceptance:** final re-inventory found 192 exact current-
user, regular, single-link formula-policy leaves and no open handle, plus the
one unchanged owner synthetic test tree. They were content-blind moved into a
new mode-0700 retained boundary with per-file pre/post-move identity checks.
Guarded-delete manifest revalidation accepted exactly one target containing
2,828 entries and 6,652,804 bytes, deleted it at age six seconds, and verified
all protected anchors unchanged. The two exact mode-0600 manifest/list files
were then exact-unlinked and the empty retained boundary removed. Final checks
find the original synthetic target, staging boundary, and every top-level
formula-policy leaf absent; no other `/tmp` class was selected.

**Publication and Linux synchronization:** PR #167 passed required
`portable-phase1`, rebased and merged at
`5c6e4c9c2f9a789463e97473f357d2a11ee5b083`, and GitHub removed its task ref;
the immediate post-merge controller was clean/equal on `main` with only
local/remote `main` before this closeout checkpoint branch. The
default fleet plan safely stopped because five reachable clean Linux checkouts
were at published `535a49218d766ce917ee28bc4b9d89fa0f650434`, not the assumed
immediate predecessor. Exact reconstruction found `ab`, `ab2`, `ri`, `rc`, and
`t4` clean at that shared ancestor; `al` was unavailable. A host-bounded guarded
plan/apply then advanced those five to the merge revision, verified remote and
local refs equal, and removed every transfer artifact. Controller `local` was
already clean at the merge revision. Protected main later advanced through the
independent T-289 presentation work to
`21fde49259193a0ba2df2259e192b5a8c36bc75d`. After the owner authenticated
`al`, fresh reconstruction found its `main` clean at the same `535a492`
ancestor. An `al`-only guarded plan/apply advanced both refs directly to
`21fde49`, verified equality, and removed the transfer artifact. No other `al`
task is currently eligible; its doctor passes with zero failures or warnings,
and its T-196 successor remains time-gated until 2026-07-26.

The first closeout branch was later proven fully superseded by v2: zero unique
patches, both patches preserved, and zero open PRs. Its exact local and remote
refs were deleted after a fresh fetch; the active durable checkpoint is only
`task/t-288-housekeeping-closeout-v2`.

**Office acceptance:** a validated forwarded current-user agent socket fetched
both clean `main` checkouts. The native updater plan selected public/private
fast-forward, apply completed, and the post-plan reports both current with
current migration state. Mac and agent doctors are ready with zero failures or
warnings; public/private Git is clean/equal at its freshly fetched targets.
The four planning-time formula-policy leaves were already absent before the
cleanup snapshot, so no payload was staged. The initially created empty target
was retained when the first plan used non-canonical macOS `/tmp`; replanning
under canonical `/private/tmp` guarded-deleted exactly that empty target,
verified protected anchors unchanged, and exact-removed its list/manifest and
boundary. Final Office residue count is zero.

The owner authorized `office2` as a failover transport to the same Mac. SSH
configuration resolves `office` and `office2` through distinct transports.
After the owner confirmed the alternate host key interactively, a dual-route
comparison proved identical host, user, repository, and current-user-owned
forwarded-agent markers. `office2` is accepted as failover. After any later
route switch, still revalidate the exact durable step rather than assuming an
interrupted command completed.

**Aist acceptance:** the owner confirmed `aist2` interactively and authorized
it as failover. Primary `aist` remained unavailable, but the alternate matched
the recorded Aist profile, clean public/private `main` checkouts, one private
branch, the two distinctive T-280 public refs, and a current-user-owned
forwarded agent. The public remote URL spelling differed only by SSH alias and
was correctly rejected as a host-identity criterion. Through `aist2`, both
checkouts fetched and fast-forwarded to their current remote targets; the public
target was protected main `21fde49`. Post-plan reports both current with current
migration state, Mac and agent doctors are ready with zero failures/warnings,
and both checkouts are clean/equal.

The two stale T-280 refs each had zero unique patches, exactly one
patch-equivalent commit on current main, no remote ref, and a merged exact PR
(#151 and #152). Both exact local refs were deleted; only `main` remains. Final
formula-policy inventory is zero, so no guarded deletion was needed. A paired
keepalive probe after acceptance found both `aist` and `aist2` unavailable, but
all update, doctor, Git, ref, and residue checks completed before the drop and
no Aist mutation remains pending. At reconnection, revalidate rather than
repeating the completed update.

**Riken acceptance:** restored primary access exposed a valid forwarded agent,
clean public/private `main`, and safe ancestry. Native update fast-forwarded
public Git to `21fde49` while private Git was already current. Post-plan is
current/current, both doctors are ready with zero failures/warnings, and Git is
clean/equal. `riken` and `riken2` are proven to reach the same host, user, and
repository with valid forwarded agents. Final checks find only local `main`,
zero formula-policy residue, and absent `.bash_common` and `run_this.sh`.

**Connectivity policy and remaining host:** during active work, probe both
declared transports for Aist, Office, and riken with SSH server-alive settings;
on a drop, use the surviving route only after reconstructing the last durable
step. Do not install a background keepalive service or infer completion across
a disconnect. The latest paired probe found both Office routes and both riken
routes ready, while both Aist routes had dropped after acceptance. Home remains
unavailable and is the sole Mac catch-up checkpoint.

**Frozen execution order:**

1. Reprobe Home; when reachable, independently run its clean-main fetch,
   ancestry, native update plan/apply/post-plan, doctors, and exact residue
   gates. Otherwise retain the checkpoint without alternate routing.
2. Publish this closeout checkpoint through protected CI only after reconciling
   fresh contributor main, then remove only proven-superseded T-288 refs.

**Safety and recovery:** do not inspect credential or private payload bytes,
transaction preimages, backups, or temporary contents. Do not remove
`node-backups/`, transactions, generated rollback state, active sessions,
package data, fixtures, or unknown `/tmp` entries. No raw recursive or multi-
path deletion. A failed staging move or guarded revalidation retains the bounded
target for reconstruction. Divergence, unsafe metadata, open handles,
authentication failure, prompts, or an unreachable Mac stop only that host.
No active shell reload, account/system setting, package, or backup mutation is
implicit.

**Published implementation files:** `libexec/harness-macos-update` and
`tests/test-personal-macos-update.sh`. Current checkpoint file: `TODO.md`.

**Next executable action:** reprobe Home when its declared route is restored;
it is the only remaining Mac catch-up. Until then, keep this branch as the
durable checkpoint and do not perform the deferred Homebrew/package task.

### T-273 — Resolve intentionally deferred maintenance

**Phase/status:** `executing`. Workstreams 1, 2, 3, and 9 are complete. Every
remaining workstream retains its own time, process, requirement, freshness, or
explicit-authority gate.

1. **Failed transaction evidence — complete/retain.** Value-free audits found
   two failed groups on `local` and one on RC. No operation-specific cleanup
   contract proves their recovery preimages unnecessary.
2. **Checksum-pinned Linux agent replacement — complete capability.** PR #143
   published `1ed9712bc8c3fd4896df2654b2a3379412e5984d`. The repository
   version pin remains unchanged; no live replacement or old-tree cleanup is
   authorized.
3. **Remaining Mac — complete.** The fourth Mac completed independent
   T-268/T-269/T-286 onboarding, rollback/reapply, fresh-session acceptance,
   doctors, and its ordered orphan check.
4. **Backup successors — time-gated.** On or after 2026-07-26, query only the
   seven T-196 successor IDs. Do not replace or duplicate a delayed job.
5. **Vendor arg0 temporary directories — process-gated.** Re-inventory
   `local` only after every Codex process exits. Do not inspect payloads. Any
   eligible multi-directory cleanup must use `harness guarded-delete`.
6. **Container capability — requirement-gated.** Resolve absent Docker/Podman
   on `local` and Singularity/Apptainer on RI only against a concrete project
   need. Do not install a generic stack for warning parity.
7. **One-way `local`→`t4` SSH mirror — separate authority.** Revalidate the
   frozen plan and execute only after explicit owner authorization for that
   exact external mutation.
8. **Package maintenance — freshness/selection-gated.** Recheck inventory and
   select only harness- or active-project-required packages. No blanket
   upgrade, cleanup, cask, service, tap, autoremove, or unmanaged-dependent
   mutation is implied.
9. **Orphaned `.bash_common` — complete.** Office and Aist completed prior
   exact unlink workflows; Home was confirmed absent; T-287 removed the fourth
   Mac's formerly active copy after converging its startup files. Fresh T-288
   discovery confirms absence on every observed Mac. All four are therefore
   complete; do not recreate the file.

**Closed non-goals:** plugin/MCP/connector authorization, accounts,
administrator settings, automatic publication, background/login mutation, and
active-session reload have no requested outcome. Unknown profiles and the
retired `sshservice-cli` lost in the 2026-07-15 incident remain
non-reconstructable and must not be guessed back into existence.

### T-196 — Backup lifecycle phase 2

**Phase/status:** `policy-resolved`, execution-gated on eight successful
weekly chains, two verified restores per node, and a current verified
independent generation. Current progress is 1/8 on every node.

| Node | Recorded 2026-07-26 successor job ID |
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
effective. No `forget`, `prune`, recurring check/restore, or replica
automation is authorized. Policy and evidence remain in
`docs/backup-lifecycle-phase2.md`, `docs/home-backup.md`, and
`docs/audits/restic-first-weekly-2026-07-19.md`.

## Completed anchors

- T-289 published the sourced harness-evolution artifacts in PR #168 at
  `f2ffdd99685d`: the Japanese final deck contains only the former summary
  slide, with one embedded notes part, native editable visuals, reproducible
  evidence/source maps, and inspected render. Both presentation verifiers,
  protected portable CI, and the 57-suite clean phase-one gate passed; native
  MPI was the declared environment-specific skip. No production harness code
  changed, and Microsoft PowerPoint fidelity remains a human distribution check.
- T-287 converged the fourth Mac startup files, removed its obsolete
  `.bash_common`, and published PR #166 at `90451d49ac96`.
- T-286 independently onboarded the fourth Mac and superseded T-285.
- T-284 accelerated and instrumented the cowork workflow; PR #163 published
  `54454b3`, all acceptance and 57-case checks passed, all branches/worktrees
  were cleaned, and external-task regression risk remained bounded but not
  empirically eliminated.
- T-283 published the symmetric Codex–Claude cowork skill: PR #161 merged at
  `535a492`; all clean managed Linux checkouts were synchronized.
- T-282 compacted the ledger and removed verified-obsolete refs: PR #159,
  published `5a060e9`.
- T-281 completed three-Mac environment convergence: PR #158, `d797d86`.
- T-280 independently onboarded Home; T-279 repaired its Bash drift.
- T-275 published bounded one-command Codex bootstrap for remaining-Mac
  onboarding; it conveys no package/account/plugin/connector authority.
- T-274 unified Bash startup and published the Mac onboarding skill.
- T-268/T-269 completed the private personal-Mac fleet.
- T-272/T-271/T-270 completed accessible-fleet maintenance and cleanup.
- T-191 accepted the first native weekly backup runs on all seven nodes.
- T-181 acceptance evaluation completed at 69/70 with zero safety failures.
- T-210 is complete and must not be repeated.

Consult Git history at or before `90451d49ac96` for superseded plans,
transaction chronology, exact prior PR/run identifiers, and completed task
narratives.
