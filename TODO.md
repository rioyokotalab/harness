# Personal harness task board

This is the authoritative resume point for the portable Codex and Claude
harness. Git retains superseded chronology and command-level evidence. Keep
only active decisions, verified prerequisites, blockers, exact next actions,
and compact historical pointers here. Next free ID: T-198.

## Current state

- Repository: local `main` is clean. The owner authorized frequent ordinary
  pushes for the now-public harness and website repositories; fetch before
  work and push, preserve contributor commits, and never force-push.
- Managed environments: `local`, `ab`, `ab2`, `ri`, `al`, `rc`, and `t4`.
  `abci_login` and `alps_login` are transports; `github` and `web` are
  services. Retired `si` is not a target.
- All seven hidden-home Restic primaries and all seven independent encrypted
  generations have passed full-data checks and verified restores. Exact
  snapshot, fingerprint, aggregate restore, transaction, and cleanup evidence
  is retained in Git through `303938f` and in `docs/home-backup.md`.
- T-181's acceptance evaluation is complete. The clean pilot passed 18/18;
  the full deterministic aggregate is 69/70 with zero safety failures and one
  reviewed semantic-oracle false negative. Candidate adoption remains separate
  and was not performed. Reports are under `evaluation/results/`; frozen
  evidence is commit `ee96853`, evaluator hardening is `d26c5a3`, and the
  private run root and cleanup manifest are absent.
- Exactly one native weekly primary job is seeded on each managed node. No
  login-node cron, user timer, retention deletion, or automatic replica job
  exists. T-191 remains verification-pending until all seven first runs pass.
- Global invariants remain authoritative in `.codex/AGENTS.md`: never inspect
  credentials; never use raw recursive/bulk deletion; preserve unrelated owner
  state; print native scheduler actions; validate proportional to risk; do not
  push without explicit authority.

## Recovery priority

- **T-172 — Exhaustively re-audit Git history (complete 2026-07-15):** audited
  both repositories' reachable graphs, refs, reflogs, read-only unreachable
  objects, historical task paths, and pre-/post-incident trees. No additional
  recoverable pre-incident home content or lost ShellCheck implementation was
  found. The website's eight damaged paths were already identical to commit
  `628b53a`; harness recovery and every later delta were reconciled. Four
  harness blobs and the website unreachable graph are superseded intermediate
  work, not recovery candidates. The ignored T-11 payload and former owner
  profiles remain unavailable; do not fabricate them. Git preserves the full
  candidate table and audit evidence in the pre-compaction TODO history.

## Active tasks

### T-191 — Scheduler-native weekly primary snapshots

**Status:** verification-pending after the explicit owner `proceed`. All seven
final smokes passed, and exactly one production job per node is present for
Sunday 2026-07-19. Idempotent reseeding kept every captured ID and created no
duplicate. Monitor each first snapshot and its strictly future successor; valid
queue delay is healthy. RI's forced one-GB200 allocation is owner-accepted.

**Verified prerequisite:** every primary and independent generation has a
successful full-data check and verified restore. Recurrence covers primary
snapshots only; independent replica generations remain manual.

**Frozen global decisions (D1-D10, D27-D28):** run weekly and independently on
each node through its native batch scheduler. Do not use login-node cron,
`systemd` timers, central SSH, AL `scrontab`, sleeping processes, or automatic
logout work. Maintain exactly one future scheduler job per node. When admitted,
the job validates its identity, submits/adopts and records exactly one
successor, then runs one incremental snapshot. Valid pending/held state is
healthy even after eligibility; queue delay is not a failure and must never
create a duplicate. A job delayed past one or more Sundays runs one snapshot,
does not backfill, and selects the earliest designated Sunday strictly after
its actual start. Keep all snapshots initially: no `forget`, `prune`, retention
deletion, automatic replica, or scheduled full-data check. Record private local
status and warn only on a later interactive login; healthy and non-interactive
sessions remain silent.

**Frozen resource and eligibility matrix (D11-D26):** times are scheduler-local
eligibility points, not promised starts.

| Host | Native request | Sunday eligibility |
|---|---|---|
| `local` | `ybatch`; default account; `thrp_1`; 30 min; default priority; evidence-only fallback `epyc-7502_1` | 00:30 JST |
| `ab` | PBS `-P gag51395`; `rt_HC`; `select=1`; 30 min; default Spot priority | 01:00 JST |
| `ab2` | PBS `-P gah51624`; `rt_HC`; `select=1`; 30 min; default Spot priority | 01:30 JST |
| `ri` | Slurm `-A rkp00015`, default `gpu`; one CPU and explicit `--gres=none`, but site policy still injects one GB200/400 GiB; 30 min | 02:00 JST |
| `rc` | Slurm `-A cloud-users -p r340`; one node/task/CPU; no GPU; 30 min | 02:30 JST |
| `t4` | AGE `-g jh250019 -l cpu_4=1 -l h_rt=00:30:00`; omit `-p` | 03:00 JST |
| `al` | Slurm `-A g177-1 -p normal`; one node/task/CPU; no GPU; 30 min | 01:00 Europe/Zurich local time |

Live read-only discovery on 2026-07-16 established the account/resource facts.
Notable tradeoffs: AL `normal` is whole-node exclusive but was explicitly
chosen; RC `r340` is shared x86-64 and matches the managed Restic binary; T4
`cpu_4` is its smallest documented CPU-only type and uses default priority;
`local` `thrp_1` requests no GPU despite GPU-bearing physical nodes. Every
claim is still acceptance-gated by its site's live smoke.

**Implementation plan:**

1. Add strict `profiles/restic-schedules.tsv` declarations for the exact seven
   rows above. Validate unique known hosts, safe fields, timezone, scheduler,
   account/group, resource, walltime, and priority schemas.
2. Add `harness restic-primary`: reuse the reviewed hidden-home algorithm from
   `docs/home-backup.md`; validate the repository row and password-file
   type/owner/mode without reading it; privately enumerate every top-level
   hidden path plus only approved relocated targets; run the managed Restic
   command with the password by pathname; exact-unlink the one manifest.
   Weekly tag: `harness-hidden-home-weekly`.
3. Add `harness restic-schedule` with read-only `plan`, `status`, and `warning`,
   plus explicit `smoke`, `seed`, allocated `run`, and exact-ID `disable`.
   Store mode-0600 atomic state below mode-0700
   `~/.local/state/harness/restic-chain/`; retain bounded, value-limited
   diagnostics and never log hidden-home contents or credential values.
4. Generate native jobs: Slurm `sbatch --begin` on RI/RC/AL; embedded
   `#SBATCH --begin` with `ybatch` on `local`; PBS `qsub -a` on AB/AB2; AGE
   `qsub -a` on T4. Print the resolved `NATIVE` command before every write.
5. Close the submit/record crash window with deterministic chain/host/
   eligibility job names. Query before submission and after ambiguous output:
   adopt exactly one matching owner/name/time job, submit only when none exists,
   and stop/warn on duplicates. Validate the running ID/name before any work;
   successor persistence precedes the snapshot.
6. Add a bounded call in `shell/interactive.sh`. It is silent when healthy or
   unseeded, performs no scheduler write/network/authentication/prompt, and may
   query only the captured local scheduler ID. Preserve silence in
   non-interactive, batch, nested, and ordinary SSH-command sessions.
7. Add fake-scheduler and source-manifest tests covering hostile output, ID
   parsing, modes/owners/symlinks, successor ordering, concurrency, ambiguous
   acceptance, queue delays, no-backfill, JST and Europe/Zurich DST boundaries,
   warning clearing, bounded history, exact disable, and absence of destructive,
   retention, replica, or secret-reading paths. Run syntax, warning-level
   ShellCheck, focused suites, `git diff --check`, guarded-delete tests, and
   `tests/test-phase1.sh`.
8. Commit only reviewed harness files locally; do not push. Revalidate every
   checkout is clean and logically identified, distribute the exact revision
   using the established credential-free Git-bundle/fast-forward route, and
   rerun plan/profile/PTY/non-interactive/status gates on all seven nodes.
9. Run bounded native smokes concurrently where policies permit. Each real
   allocation validates architecture, paths, password metadata only, managed
   Restic read-only access, time calculation, and one distant deferred test
   successor; it performs no snapshot. Cancel only that exact successor and
   prove it absent. A compute-side resubmission failure returns to the D9
   fallback interview; do not improvise a login trigger.
10. After all seven smokes and cancellation proofs pass, seed exactly one real
    future job per node, prove no duplicate exists, and monitor each first
    admitted snapshot plus strictly future successor. Queue delay is allowed.
    Keep T-191 verification-pending until all seven pass, with progress updates
    at least every five minutes during active monitoring.

**Stop and rollback:** dirty checkout, credential-path anomaly, unknown
resource, architecture mismatch, duplicate/ambiguous job, inaccessible
repository, failed smoke, or unexpected scheduler semantics halts only that
node without weakening checks. Before seeding there is no scheduler rollback.
After seeding, `disable` revalidates, prints, cancels, and verifies absence of
only the captured future ID, then retains private evidence. It never searches
broadly or deletes state.

**Execution checkpoint:** owner authority is limited to this frozen T-191 plan.
Current working set starts with `TODO.md`, `profiles/restic-schedules.tsv`,
`bin/harness`, new `libexec/harness-restic-primary` and
`libexec/harness-restic-schedule`, `shell/interactive.sh`, focused tests, and
the backup documentation. Next action is local implementation and validation;
do not submit a scheduler job before that checkpoint passes.

**Initial execution audit (2026-07-16):** exact-name process checks report zero
Restic processes on every node. Native scheduler listings filtered only to the
reserved `hr-*` namespace report no matching job on `local`, RI, AL, RC, AB,
AB2, or T4. X11-forwarding warnings on RI/RC were transport noise; every probe
otherwise completed. It is safe to implement locally; re-run this audit before
the first smoke because this checkpoint does not reserve scheduler state.

**Local implementation checkpoint:** the strict seven-row schedule, shared
primary helper, scheduler controller, interactive warning, documentation, and
focused fake-scheduler suite are implemented in the declared working set.
Syntax, warning-level ShellCheck for new scripts, `git diff --check`, the
focused suite, and guarded-delete suite pass. The first complete phase-1 run
reached the pre-existing environment gate and stopped exactly at
`tests/test-phase1.sh: 365: mpicc: not found`: the process-local module table
again claims OpenMPI is loaded without exporting its compiler. No scheduler
write occurred. A retry is safe only after unloading and reloading the same
declared `openmpi/5.0-cuda-12.8` module in the retry shell.

The reviewed retry and the later strengthened state-machine rerun both pass
the complete phase-1 suite with only the documented login-node CUDA-library
warnings. The focused suite now proves smoke-gated seeding,
`verified-disabled` successor cancellation, status tracking of the future
smoke successor, exact singleton/idempotent seed and disable across fake
`ybatch`/Slurm/PBS/AGE, hostile output refusal, successor-first weekly order,
JST/Europe-Zurich boundary behavior, private warning state, manifest coverage,
and relocated-target rejection. Read-only `plan`/`next` succeeds for all seven
declarations after fixing portable planning so it does not require a remote
site's scheduler directories locally. Next action: inspect and commit only the
declared implementation files locally; do not push.

**Rollout and pre-smoke checkpoint:** local implementation commit
`852b84bb753bf590a55353f96de71fba3b7b77d5` is clean and unpushed. A
43,655-byte credential-free bundle with SHA-256
`f4ca151b7007316d361aae5ad009759b62fda109d4361e0a37b8d848581c9c72`
fast-forwarded clean AB, RI, AL, RC, and T4 checkouts from `df72e17` and AB2
from `303938f` to that exact commit. Every remote bundle and the local bundle
are exact-unlinked and absent. All seven nodes then passed exact-revision and
clean-worktree checks, new-script syntax, schedule `plan`/`next`, absent chain
and smoke state, doctor, and managed Restic read-only repository access. Real
PTY-backed interactive shells remained warning-silent while healthy/unseeded,
and non-interactive shells remained silent on every node. AB2's first shared
validation connection outlived the result window but left no Restic process;
its bounded solo retry passed the full gate. No scheduler write has yet run.
Next action: commit this evidence locally, re-audit the reserved job namespace,
then submit the seven bounded smokes with the printed native commands.

**First live-smoke checkpoint:** the reserved namespace/process re-audit was
clean. AB parent `2043932.pbs1`, AB2 `2043931.pbs1`, AL `4220993`, RC
`210790`, and T4 `8175288` were accepted with their exact printed native
requests. AL and RC completed read-only Restic checks, created exactly one
Sunday successor (`4220994` and `210791`), and exact `scancel` plus absence
verification left both smoke states `verified-disabled`. AB/AB2 remain valid
queued parents and were not duplicated. Local failed before state adoption:
`ybatch` injected `thrp_1` directives after `set -eu`, so Slurm ignored the
partition and accepted no job. RI direct SSH lacked the site Slurm DNS/config
environment; native `scontrol ping` and `sbatch --version` pass under both
`bash -lc` and `bash -lic`, so retry must use the login environment and let the
smoke prove compute-side resubmission. T4 ran on `cpu_4=1` (four slots, no GPU)
for 0.93 seconds and exited 2 before advancing state; only `smoke-submitted`
exists, with no lock or diagnostic. This exposed missing private diagnostics.
Current corrective work moves local `#YBATCH`/`#SBATCH` directives before the
first executable line, adds ordering regression, overwrites one mode-0600
controller diagnostic per job, and safely reconciles an absent submitted smoke
as failed before retry. No snapshot has run and no uncaptured job was created.

**T4 retry checkpoint:** corrective commit `613a0f2` allowed a safe retry as
AGE job `8175315`. Its managed read-only Restic check passed, but compute-side
successor submission stopped before adoption because `qsub` was absent from
the batch job's `PATH`; the private mode-0600 diagnostic contains only the
resolved native command and the `command not found` error. Login-side
validation identified the executable directory as
`/apps/t4/rhel9/uge/latest/bin/lx-amd64`, a mode-0755 directory owned by
`geadmin` and canonically linked to the installed 2023.1.1 AGE tree. Commit
`4c678d5` declared that path, passed focused, guarded-delete, and complete
phase-1 gates, and was bundle-fast-forwarded to all six clean remotes. Retry
parent `8175392` then passed on `all.q/r2n6`, four CPU slots, exit 0 in 3.498
seconds; exact `qdel 8175400` verified its Sunday successor disabled.

**Seven-node smoke checkpoint:** every accepted parent below completed the
managed read-only Restic check and created exactly one future Sunday successor;
each successor was canceled by captured exact ID and its private state is now
`verified-disabled`. No smoke took a snapshot.

| Host | Accepted parent | Exact disabled successor |
|---|---:|---:|
| `local` | `90931` | `90932` |
| `ab` | `2043932.pbs1` | `2043966.pbs1` |
| `ab2` | `2043931.pbs1` | `2043964.pbs1` |
| `ri` | `6857` | `6858` |
| `al` | `4221037` | `4221038` |
| `rc` | `210808` | `210810` |
| `t4` | `8175392` | `8175400` |

Local parent `90931` completed in 12 seconds on `threadripper-3960x` with six
CPUs and 15,600 MiB; AL parent `4220993` completed in nine seconds with the
accepted whole-node allocation; RC parent `210790` completed in three seconds
with two billed CPUs; and T4 accounting is recorded above. All bundle copies
were exact-unlinked and every checkout is clean at `4c678d5`. RI reached its
scheduler only under the login environment and requires an explicit project
account. The owner selected `rkp00015`. The first RI parent `6850` passed and
exact `scancel 6852` verified its successor absent, but accounting showed the
default `gpu` partition injected one GB200 and 400 GiB. RI exposes no CPU
partition. Commit `aa9e08e` made `--gres=none` explicit after native
non-submitting tests passed and left no test jobs; final RI parent `6857` still
received the same injected GPU allocation, passed in two seconds, and exact
`scancel 6858` verified its successor absent. Final-form AL parent `4221037`
and RC parent `210808` also passed, with exact successors `4221038` and
`210810` disabled. This proves the site override cannot be avoided through the
reviewed native request. The owner accepted the forced RI GPU allocation; all
required production choices were resolved before the exact seven-node pre-seed
audit and production submissions below.

**Production seed checkpoint (2026-07-16):** the exact pre-seed audit found all
checkouts clean at `324360b`, every chain absent, and every smoke state
`verified-disabled` with its successor absent. Native seeding then accepted the
following singleton jobs; an immediate second seed on every node returned
`status=kept` for the same ID.

| Host | Captured production ID | First eligibility |
|---|---:|---|
| `local` | `90939` | 2026-07-19 00:30 JST |
| `ab` | `2044027.pbs1` | 2026-07-19 01:00 JST |
| `ab2` | `2044028.pbs1` | 2026-07-19 01:30 JST |
| `ri` | `6862` | 2026-07-19 02:00 JST |
| `rc` | `210816` | 2026-07-19 02:30 JST |
| `t4` | `8175651` | 2026-07-19 03:00 JST |
| `al` | `4221054` | 2026-07-19 01:00 Europe/Zurich |

Every controller status reports `active`, exact identity present, and the
expected scheduler pending/held state. Next action: monitor only these captured
IDs; after each admission verify successful snapshot evidence, exactly one
successor at the next strictly future Sunday, private state consistency, and
healthy interactive-login silence. Do not duplicate or cancel jobs merely for
queue delay.

### T-193 — Reproducible public-repository safety audit

**Phase/status:** `complete` under the owner's 2026-07-16 eight-hour go.
Extend website T-185's manual review with one credential-value-free scanner
that audits the current tree and reachable history of both public repositories.
Report only rule IDs, paths, commits, sizes, counts, and metadata fingerprints;
never print matching values. Cover suspicious filenames, private-key headers,
common token/credential assignments, credential-context entropy, oversized
blobs, operational paths, and ignored/untracked boundaries. Do not rewrite
history, change visibility, inspect authentication stores, or mutate website
files while its unrelated fresh ledger closeout remains dirty. Acceptance is a
versioned scanner with hostile fixtures, bounded reports for both repositories,
and independent confirmation that no matched repository value is copied into
stdout, stderr, or a report.

**Outcome:** `tools/public-repo-audit.py` scans all
reachable blobs with one Git batch reader and one raw-history pass, publishes
only bounded per-rule samples with complete counts, and refuses to overwrite
reports. Its guarded hostile
fixture proves a fake token present only in deleted history triggers path,
token-shape, and assignment rules while the value remains absent from stdout,
stderr, and JSON. Provisional full scans completed without a private-key,
high-entropy-credential, or suspicious-path finding. Harness's sole token-shape
item is its synthetic historical fixture. Website's sole assignment candidate
is a historical, HEAD-absent jQuery 1.2.3 vendor expression. Canonical reports
and interpretation are in `docs/audits/` and
`docs/public-repository-safety.md`; the website report preserves its four-entry
concurrent dirty-count fact without reading or mutating those files. Focused
hostile tests, evaluation regression tests, and the complete phase-1 suite
passed before publication; the expected login-node OpenMPI CUDA-library
warnings were explicitly ignored by OpenMPI.

### T-194 — Contributor-safe CI and merge-control proposal

**Phase/status:** `partially complete`; harness CI is implemented and verified,
website CI is deferred behind its fresh unrelated driver state, and external
GitHub settings remain proposal-only. Use only pinned official actions and
least-privilege read permissions. Harness CI must run deterministic syntax,
ShellCheck, focused evaluator tests, and portable phase-1 gates without
credentials, remote nodes, scheduler writes, model calls, or a false claim
about generic-runner MPI readiness. Website CI must run its existing
credential-free checks and locked browser tests, but no deploy/live check.
Preserve the website's current unrelated dirty ledger and defer its workflow
edit until clean. Record exact recommended branch protections, required checks,
rollback, and remaining owner-side settings without changing GitHub
configuration automatically.

**Outcome/checkpoint:** Harness workflow `.github/workflows/ci.yml` uses
read-only permissions, checkout v6.0.2 pinned to full commit
`de0fac2e4500dabe0009e67214ff5f5447ce83dd`, no persisted credential, complete
history, and fixed `ubuntu-24.04`. Hosted run `29499772796` passed ShellCheck,
all five focused suites, and the portable phase-1 gate. The generic runner
explicitly skips only native MPI and Codex-client policy semantics; the default
managed-node suite still requires both and passed locally. Exact branch-rule,
rollback, and deferred website instructions are in
`docs/ci-and-merge-controls.md`. Do not take over the website files until its
current driver checkpoint becomes clean or stale.

### T-195 — Seven-node configuration-drift audit

**Phase/status:** `planning`; execute after T-193's local scanner is frozen.
Use only the declared aliases `local`, `ab`, `ab2`, `ri`, `al`, `rc`, and `t4`.
Collect a bounded allowlisted inventory of logical identity, harness revision
and cleanliness, profile/control-plane discovery, storage-link targets,
managed tool versions, native scheduler availability, T-191's captured exact
job state, and existing HPC smoke sources. Never dump environments, enumerate
SSH configuration, read credentials, submit/cancel jobs, install packages, or
touch NFS data trees. Separate login-node capability from compute readiness and
record site-specific drift rather than normalizing it away.

### T-196 — Backup lifecycle phase 2

**Phase/status:** `planning`, execution-gated on all seven T-191 first snapshots
and successors passing. During this window, produce a PIE decision register and
recommended defaults for retention, `forget`/`prune`, scheduled full-data
checks, restore drills, and independent replica recurrence. No deletion,
retention command, new scheduler job, or replica automation is authorized by
this planning task. The eventual plan must preserve rollback evidence, bound
repository locks and maintenance time, and introduce each destructive or
recurring mechanism only after a manual dry run and restore gate.

### T-197 — Evaluation follow-up decision

**Phase/status:** `executing`; evidence-only, with no new model invocation or
candidate adoption. Reconcile T-181's pilot/full reports and review limitation,
quantify correctness, retry, latency, and token tradeoffs, and record an
adopt/adapt/experiment/reject decision. Default recommendation: do not adopt
failure-capsule candidate A because it showed no substantive correctness gain,
used comparable retries, and increased aggregate cost; require a materially
different mechanism and pre-registered hypothesis before another 70-run study.

### Eight-hour LLM/HPC readiness workstream

After T-193–T-197 reach their safe terminal states, continue assigning new
task IDs and executing bounded work that improves all-node readiness for LLM
training and scientific HPC coding. Prefer, in order: a reproducible capability
matrix; credential-free environment manifests; portable CPU/C++/Fortran/MPI/
CUDA/Python build gates; architecture-aware container/uenv plans; scheduler-
native single-device then distributed LLM smokes; checkpoint/data-path and
profiling plans; and matched performance baselines. Use existing tracked smoke
sources before adding code. No project/model/dataset clone, package install,
image pull, allocation/billing spend, global configuration, or destructive
cleanup is implied; prepare and validate read-only or model-free surfaces while
ledgering any owner-only action bundle. Checkpoint and push small verified
harness changes frequently while preserving concurrent contributor work.

## Stable operational facts

- The 2026-07-15 accident was an agent-issued raw recursive deletion of
  `/home/rioyokota` after a temporary `HOME` assignment expired. Processes were
  terminated; no usable whole-home filesystem snapshot existed. Harness and
  website recovery are complete. Unknown former profiles and `sshservice-cli`
  remain intentionally unreconstructed.
- The guarded-delete schema protects lexical and canonical account homes,
  binds immutable manifests to exact identities/counts/bytes, revalidates
  immediately before apply, and verifies anchors afterward. RC and load-balanced
  AL require the documented canonical-home/persistent-session handling; never
  weaken the guard.
- `/mnt/nfs-03` is a hard NFSv4.2 mount whose metadata latency makes large
  small-file restore/cleanup trees extremely slow even when throughput and
  capacity are healthy. Keep packed repositories/generations on large storage
  and materialize restore tests on node-local mode-0700 scratch.
- AL authentication uses the owner's existing `id_ed25519` certificate renewed
  by `cscs-key sign --headless -f ~/.ssh/id_ed25519`. The local `al` convenience
  alias is intentionally owner-only in the current node's `.bashrc` and must
  not be mirrored.
- AB2's 10 TB group quota is active. Its `.local` migration, approved cleanup,
  primary, independent generation, full-data checks, restores, and guarded
  cleanup completed under T-192. `.bash_history` remains node-local.
- `profiles/home-layout.tsv`, `profiles/restic-repositories.tsv`, host profiles,
  `docs/environment-portability.md`, `docs/home-backup.md`, and
  `shared/skills/operate-native-hpc/references/sites.md` are the canonical
  current declarations; do not copy obsolete ledger prose back into them.

## Completed-task index

Git history is the durable evidence store. Consult the pre-compaction version
of this file at `303938f:TODO.md` and the named commits when command-level detail,
transaction IDs, aggregate counts, hashes, or failure chronology is required.

| Task | Completed outcome / durable pointer |
|---|---|
| T-169 | Advanced-harness research and proposal inventory completed. |
| T-170 | Seven-node portable environment parity completed; capability design is in `docs/environment-portability.md`. |
| T-171 | Current-home incident contained and recoverable tracked/tool state restored; safety commits include `68fb820` and `238f022`. |
| T-172 | Exhaustive Git recovery re-audit found no additional candidate. |
| T-173 | ShellCheck 0.11.0 reconstructed as checksum-pinned new work at `2222fc5`. |
| T-174 | Test cleanup routed through guarded deletion. |
| T-175 | Local-only pinned lftp restored at `292c6b4`; website validation at `362847d`. |
| T-176 | Internal transaction tree cleanup routed through guarded deletion. |
| T-177 | Restored ShellCheck findings fixed and warning-level lint made durable. |
| T-178 | Hyphenated tool fact-key normalization completed. |
| T-179 | ABCI PBS command discovery reconciled without startup-file sourcing. |
| T-180 | Aggregate plans now enforce pinned Node/npm versions. |
| T-181 | Seven-family acceptance evaluation completed: clean pilot 18/18; full deterministic 69/70 with zero safety failures, 13 reviewed pairs, one recorded semantic-oracle false negative, and no candidate adoption. Evidence is in `evaluation/results/`, commit `ee96853`; post-experiment hardening is `d26c5a3`. |
| T-182 | Seven-node storage, shell/control-plane, Restic, and independent-generation workflow completed; exact evidence spans commits through `303938f`. |
| T-183 | Credential-safe private-origin login sync and explicit remote Codex launcher completed at `2c2dff0` and `4f34299`. |
| T-184 | Truncated guarded-delete manifest publication rejected at `f31aeb5`. |
| T-185 | Non-interactive managed Restic resolution completed. |
| T-186 | AL authentication migrated to owner-renewed `cscs-key`; obsolete helper removed. |
| T-187 | AL guarded plan/apply constrained to one persistent login session. |
| T-188 | NFS-independent local replica at T4 passed full check/restore (`56c15a7`). |
| T-189 | Ledger-backed PIE skill created and validated at `dfaea9e`. |
| T-190 | Automated guarded mirrored-node onboarding skill completed, installed, tested, and published at `b5bb171`. No live node was onboarded. |
| T-192 | AB2 quota deferral, primary, replica, restore, migration, and cleanup completed at `1c2050a` and `303938f`. |
