# Personal harness task board

This is the authoritative resume point for the portable Codex and Claude
harness. Git retains superseded chronology and command-level evidence. Keep
only active decisions, verified prerequisites, blockers, exact next actions,
and compact historical pointers here. Next free ID: T-215.

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

**Phase/status:** `complete`; executed after T-193's local scanner was frozen.
Use only the declared aliases `local`, `ab`, `ab2`, `ri`, `al`, `rc`, and `t4`.
Collect a bounded allowlisted inventory of logical identity, harness revision
and cleanliness, profile/control-plane discovery, storage-link targets,
managed tool versions, native scheduler availability, T-191's captured exact
job state, and existing HPC smoke sources. Never dump environments, enumerate
SSH configuration, read credentials, submit/cancel jobs, install packages, or
touch NFS data trees. Separate login-node capability from compute readiness and
record site-specific drift rather than normalizing it away.

**Outcome:** committed collector `tools/fleet-readiness-audit.py` made one
bounded login-shell connection per remote concurrently and one local probe.
`docs/audits/fleet-readiness-2026-07-16.json` has all seven nodes, zero probe
failures, zero discarded stdout, clean checkouts, doctor failures zero, exact
T-191 chains present, disabled smokes absent, four control links correct, and
all ten smoke blobs identical. Remotes are clean at ancestor `a2823d3`, 36
commits behind local `26690a8`. Site login baselines differ as expected and do
not establish compute readiness. Recreated default-home directories are listed
without content inspection in `docs/fleet-readiness-audit.md` and assigned to
T-199. No node or scheduler was mutated.

### T-196 — Backup lifecycle phase 2

**Phase/status:** `design complete`, execution-gated on all seven T-191 first
snapshots and successors passing. The PIE decision register and
recommended defaults for retention, `forget`/`prune`, scheduled full-data
checks, restore drills, and independent replica recurrence. No deletion,
retention command, new scheduler job, or replica automation is authorized by
this planning task. The eventual plan must preserve rollback evidence, bound
repository locks and maintenance time, and introduce each destructive or
recurring mechanism only after a manual dry run and restore gate.

**Outcome:** `docs/backup-lifecycle-phase2.md` records official Restic 0.19.1
semantics, recommended generous retention, separate forget/prune transactions,
deterministic data-check coverage, restore drills, manual-first independent
replicas, collision/lock rules, phased acceptance gates, rollback evidence, and
five owner choices. No Restic, scheduler, replica, deletion, or credential-path
command ran. Keep-all remains the effective policy until T-191 production
stabilizes and the owner separately approves exact destructive commands.

### T-197 — Evaluation follow-up decision

**Phase/status:** `complete`; evidence-only, with no new model invocation or
candidate adoption. Reconcile T-181's pilot/full reports and review limitation,
quantify correctness, retry, latency, and token tradeoffs, and record an
adopt/adapt/experiment/reject decision. Default recommendation: do not adopt
failure-capsule candidate A because it showed no substantive correctness gain,
used comparable retries, and increased aggregate cost; require a materially
different mechanism and pre-registered hypothesis before another 70-run study.

**Outcome:** `docs/evaluation-follow-up.md` records `reject` for candidate A
and retains the baseline. Pilot was 9/9 versus 9/9; the full canonical result
remains 35/35 baseline versus 34/35 candidate with one retry per arm and no
safety failures. Targeted review classified the one difference as an oracle
false negative, so substantive correctness tied while candidate full-stage
duration/input/output rose 13.328%/3.135%/3.292%. The review's arm-bearing path
leak limits subjective blinding. No model, grader, report, or guidance changed.

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

### T-198 — Safe remote harness fast-forward

**Phase/status:** `complete`. All six remotes were clean at ancestor
`a2823d3`, 36 commits behind the local/public branch. Before any rollout,
classify every intervening path and prove that the T-191 scheduled entrypoint,
repository declarations, and private-state schema remain compatible with the
already queued jobs. If compatible, use the established credential-free
bundle/fast-forward route, one exact revision on every remote, with pre/post
cleanliness, identity, syntax, doctor, and read-only T-191 status gates. Do not
resubmit, cancel, or alter any scheduled job. Halt only the affected node on
drift; exact-unlink each reviewed transfer artifact after success.

**Compatibility checkpoint:** a path-level diff from `a2823d3` through the
current clean main branch proves identical Git object IDs for `bin/harness`,
`libexec/harness-common`, `libexec/harness-restic`,
`libexec/harness-restic-primary`, `libexec/harness-restic-schedule`, and both
Restic repository/schedule maps. The queued jobs therefore execute byte-identical
dispatch, state schema, successor, and snapshot code after fast-forward. The
only runtime-adjacent diffs are interactive-shell profile-derived host discovery
and removal of a redundant hard-coded host case in the separately manual
replica helper; neither is in the scheduled call graph. T-195 independently
proved each remote clean at the expected ancestor with the captured production
job present. Next: publish this checkpoint, create one prerequisite-bound Git
bundle, and require exact preflight/fast-forward/postflight in each connection.

**Outcome:** mode-0600 bundle SHA-256
`91a6ec436e3f238be1b1dae4b0c65bb07715457da3f9a153f07f8840614fdb57`
fast-forwarded all six remotes to `a916b10`. Five direct transactions passed
every postflight. RI also fast-forwarded and removed its bundle, then hit only
the documented non-login Slurm query boundary; a login-shell read-only
postflight passed. The independent canonical report
`docs/audits/fleet-readiness-post-rollout-a916b10.json` proves all seven exact,
clean, doctor failures zero, captured production jobs unchanged/present,
disabled smokes absent, control links correct, and smoke blobs identical. All
seven local/remote transfer artifacts are absent. No scheduler write occurred.

### T-199 — Recreated hidden-state classification

**Phase/status:** `partially complete`; metadata audit and all already approved
deletions are complete, while AB Mozilla relocation is owner-gated. The exact
scope was local `.cache`/`.nv`; AB `.cache`/`.mozilla`; AB2 `.cache`; RI
`.cache`/`.apptainer`; AL `.mozilla`; and T4 `.cache`. Record link/type,
ownership/mode, same-filesystem fact, bounded apparent size, application owner,
and whether XDG or application configuration can redirect future writes.
Reconcile the already approved per-node delete/move policy before action.
Never inspect file contents. Any multi-tree deletion must use guarded-delete;
any move must be transactional with application-specific rollback and must not
cross the active Restic/scheduler path unexpectedly.

**Outcome:** `docs/hidden-state-cleanup.md` records metadata without file names
or contents. Guarded staging/plan/exact-NEXT apply/postflight removed local
`.cache`/`.nv`, AB/AB2/T4 `.cache`, RI `.cache`/`.apptainer`, and AL `.mozilla`;
AB and T4 released roughly 23.4 GiB apparent legacy cache. Manifests, plan
files, and staging boundaries are absent, and the post-cleanup fleet audit kept
all T-191 jobs present. RI fresh-login startup recreated an empty `.cache`
before the managed cache block; a second guarded cleanup left it absent and
assigned durable prevention to T-201. AB `.mozilla` is only 12 KiB but crosses
filesystems and can contain authentication state, so it was neither copied nor
inspected; T-202 owns an application-native migration choice.

### T-200 — Scheduler-native LLM/HPC capability matrix

**Phase/status:** `capability baseline complete`; framework selection moved to
T-206. Convert identical tracked smoke sources
and site declarations into a reproducible login-versus-compute matrix. First
record exact native commands and environment/container routes; then, only under
existing allocation authority, run matched single-rank CPU/compiler/Python and
single-device CUDA/framework correctness before any distributed test. Freeze
inputs and collect architecture, driver/runtime/framework, MPI/backend, device,
and numerical evidence. Do not infer compute absence from login PATH, install
packages, clone models/datasets, pull images, or scale until the smaller gate
passes.

**CPU-gate checkpoint:** `tests/smoke/jobs/cpu-readiness.sh` is a
scheduler-neutral five-minute job that fails on architecture drift, selects
only the validated process-local GCC/uenv routes, builds and runs C/C++/Fortran
with CMake/Ninja, runs a direct C++20 and standard-library Python gate, and
executes sanitizers except for RC's declared base-runtime gap. It publishes one
new mode-0600 result and guarded-cleans node-local build state. Scheduler
actions remain explicit outside the generic script. Planned native requests
reuse only T-191-approved accounts/resources at default priority: local
`ybatch`/`thrp_1`; AB/AB2 PBS `rt_HC select=1`; RI Slurm `rkp00015/gpu` with
explicit `--gres=none` but accepted site-injected GB200; AL Slurm
`g177-1/normal`; RC Slurm `cloud-users/r340`; and T4 AGE
`jh250019 cpu_4=1`. Validate, commit, distribute, recheck no exact-name/result
collision, print each full native submit command, then monitor only captured
IDs. No GPU/framework claim follows from this CPU gate.

**CPU-gate submission checkpoint (2026-07-16):** the repeated pre-submit gate
found every fixed result absent and zero exact-name collisions. Seven native
five-minute/default-priority jobs were then accepted: current Ybatch `91133`;
AB PBS `2044959.pbs1`; AB2 PBS `2044958.pbs1`; RI Slurm `6978`; AL Slurm
`4223373`; RC Slurm `211005`; and T4 AGE `8179531`. Monitor only these captured
IDs, preserve the T-191 production jobs, and publish a capability claim only
from each private result plus scheduler accounting.

**CPU-gate v1 evidence:** local `91133`, AB2 `2044958.pbs1`, AL `4223373`,
and RC `211005` completed with status zero and passed C/C++/Fortran CTest,
C++20, Python, and the applicable sanitizer gate. RI `6978` reached every pass
marker but the site login shell's EXIT context failed afterward, so scheduler
accounting correctly records failure and no clean claim is made. T4 `8179531`
passed through Python but exposed a reproducible mixed-toolchain defect: its
GCC module supplies `gcc`/`g++`/`gfortran` while leaving `cc` at the base GCC
11 linker, which cannot link UBSan. AB `2044959.pbs1` remains queued for the
requested 32 CPU resource. Raw failed results remain private and untouched.

**CPU-gate v2 correction:** the job now resolves and exports a coherent
compiler triplet after AB/AB2/T4 module setup, re-executes the test body in
non-login Bash after site environment setup, and accepts a restricted run tag
so retries cannot overwrite prior evidence. Focused tests, invalid-tag tests,
shell parsing, and the full native phase-1 suite pass (the latter after the
required unload/reload of `openmpi/5.0-cuda-12.8`; expected login-node
`libcuda` component warnings remain non-fatal). Commit and distribute v2, then
repeat collision checks and retry only RI/T4 plus any later v1 failure.

**CPU-gate v2 submission checkpoint:** exact commit `8cded82` was transported
to all six remotes with a verified 3,099-byte bundle after direct GitHub fetch
proved unavailable there. A shared-`/tmp` name collision between AB accounts
caused no checkout mutation; the corrected transport used unique private
per-account state paths, and every local/remote bundle is absent after clean
fast-forwards. Fresh v2 collision checks passed before accepting: local Ybatch
`91158`; AB2 PBS `2044969.pbs1`; RI Slurm `6979`; AL Slurm `4223564`; RC Slurm
`211007`; and T4 AGE `8179553`. AB v2 is deliberately deferred while its v1
job remains live. Monitor only these IDs and the previously captured AB v1 ID.

**CPU-gate v2 continuation:** local, RI, AL, RC, and T4 v2 completed with
scheduler success, terminal status zero, coherent compiler identity, 3/3
CTest, C++20, Python, and applicable sanitizer evidence. T4 now proves the
explicit GCC 14 triplet; RI proves the non-login publication correction. AB v1
also completed status zero, clearing its duplicate-work constraint. A fresh AB
v2 preflight then passed and PBS accepted `2044973.pbs1`. AB2 v2
`2044969.pbs1` remains queued. These are the only two outstanding CPU-v2 IDs.

**CPU-gate outcome:** both remaining PBS jobs completed with scheduler exit
zero and terminal result zero. The matched seven-node report is
`docs/hpc-readiness.md` with machine-readable evidence in
`docs/audits/hpc-cpu-readiness-2026-07-16.json`. All nodes passed coherent
C/C++/Fortran builds, 3/3 CTest including OpenMP, direct C++20, and Python;
six sanitizer gates passed and RC retains its explicit runtime-gap skip. This
closes only the CPU/compiler/Python prerequisite. Next freeze a minimal
single-device accelerator/framework gate per declared site route; make no MPI,
distributed, numerical-equivalence, or performance claim beforehand.

**Accelerator-gate freeze:** queue and account discovery identifies the
smallest declared route at each site: local Ybatch `a4500_1`; AB/AB2 PBS
`rt_HG select=1` (exactly 16 CPU/one GPU by queue default and maximum); RI
Slurm `rkp00015/gpu --gres=gpu:1`; AL Slurm `g177-1/normal` with native
`--uenv=prgenv-gnu/25.11:v1 --view=default`; RC Slurm
`cloud-users/qc-gh200 --gres=gpu:1` (one GH200 per node and all-account
permission); and T4 AGE `jh250019 gpu_h=1` (one H100 MIG slice). Default
priority and a five-minute limit are mandatory. The tracked v1 job selects one
logical device, proves driver metadata everywhere, and compiles/runs the
one-device CUDA kernel on the five reviewed toolkit routes. RI and RC record an
explicit compile skip rather than infer a toolkit. Every node records the
framework skip because no reviewed PyTorch environment or image exists.
Commit, distribute, collision-check, print exact native commands, then monitor
only captured IDs without touching T-191.

**Accelerator v1 submission checkpoint:** exact commit `2e48072` reached six
clean remotes through a verified 4,811-byte bundle, with all bundle files then
absent. Result/name collision checks passed before native acceptance of local
Ybatch `91206`; AB PBS `2045030.pbs1`; AB2 PBS `2045029.pbs1`; AL Slurm
`4224038`; RC Slurm `211017`; and T4 AGE `8179763`. RI rejected the request
before creating a job because site policy requires job-level `--gpus=1`, not
per-node `--gres=gpu:1`. Exact-name reconciliation found no RI job or result.
ABCI IDs were recovered by exact `qselect` after the asynchronous controller
calls outlived the initial terminal yield; never resubmit those names.

**Accelerator v1 evidence and v2 correction:** AL and T4 completed with
scheduler/result zero, driver metadata, one-device CUDA kernel success, and the
declared framework skip. AB2 also completed the same gate with PBS exit zero;
AB remains queued. Local proved the A4500 driver but failed before compilation
because the inherited module table claimed CUDA loaded while its PATH lacked
`nvcc`. RC proved the allocated GH200 compute node is `aarch64`, contradicting
the x86 login-node assumption, and failed that intentional architecture gate.
Preserve both private v1 failures. V2 explicitly unloads/reloads local CUDA and
declares RC compute as Arm; after AB's immutable v1 job finishes, distribute
the correction and retry only local, RC, and the previously unsubmitted RI
with run tag v2 and RI's required `--gpus=1` spelling.

**V2 retry checkpoint:** AB v1 completed with PBS exit/result zero before exact
commit `1e6f930` was distributed, so no queued job observed moving source.
RI's corrected request passed native `--test-only` without creating a job;
fresh collision checks then preceded Slurm acceptance of RI `7009` and RC
`211018`. Both use run tag v2 and distinct names. The local retry wrapper is
being versioned with name `t200glocal2` and run tag v2 before its own fresh
collision check and Ybatch submission. Monitor only the captured IDs.

**Accelerator outcome:** RI `7009`, RC `211018`, and local `91211` completed
with scheduler/result zero. The final seven-node matrix is
`docs/audits/hpc-accelerator-readiness-2026-07-17.json` and the human report is
`docs/hpc-readiness.md`: seven driver/runtime passes, five one-device CUDA
compile/kernel passes, and two explicit no-toolkit skips. Every node records
the intentional framework skip. T-200's safe base-environment capability
matrix is complete; it makes no framework, MPI, distributed, numerical, or
performance claim. T-206 owns the owner-gated framework selection, and T-207
owns the next smaller scheduler-native MPI gate.

### T-201 — Early-login cache redirection

**Phase/status:** `complete`; RI's shell-independent recurrence moved to T-203. Determine, without
tracing values or reading unrelated startup content, whether the managed cache
exports can be installed before any user application startup on all seven
nodes. Design the smallest silent POSIX block and prove non-interactive,
interactive, batch, nested, and direct-SSH behavior. It must not make cache
targets part of T-191 backup sources, change scheduler state, create directories
on healthy login, or overwrite owner startup content. Roll out only after fake
home tests and per-node plans pass.

**Implementation checkpoint:** `harness cache-bootstrap` now plans and
transactionally prepends an exact silent cache-only block to `.bashrc` and
Bash's existing selected login file. It stores only the public prefix, disables
editor swap/backup/user configuration, revalidates exact suffix/type/owner/mode
before mutation, and supports exact-prefix rollback that preserves later owner
edits. `docs/early-cache-bootstrap.md` records the contract. Fake-home tests
prove first-command ordering, idempotence, silence, no `~/.cache` creation, no
copy of a synthetic secret, refusal before mutation when a prefix changes, and
successful rollback with later changes. Portable and native full suites pass.
Commit and distribute the exact revision, obtain clean seven-node plans, then
apply and test fresh login, direct SSH, interactive/nested Bash, and scheduler
inheritance before guarded cleanup of any RI recurrence.

**Live-plan checkpoint:** exact revision `070479c` is clean on all seven
checkouts after checksum-verified private bundle transport and complete
transport cleanup. Seven native `cache-bootstrap --plan` runs reported
`contents=not-read`, no block, and exactly two prepends: `.bashrc` plus
`.profile` on local/RI, or `.bashrc` plus `.bash_profile` on AB/AB2/AL/RC/T4.
Apply only this exact revision, capture all transaction IDs, then require an
idempotent two-KEEP postplan before opening fresh test sessions.

**Live-apply checkpoint:** repeated exact-revision plans passed at `2f72425`.
All seven transactional applies completed: local
`20260716T140611Z-3466811`; AB `20260716T140613Z-3409425`; AB2
`20260716T140612Z-1704569`; RI `20260716T140609Z-602570`; AL
`20260716T140620Z-250841`; RC `20260716T140615Z-1162732`; and T4
`20260716T140619Z-2984771`. These are the exact rollback IDs. Require two KEEP
postplans, correct first-line/type/mode metadata, declared cache variables in
fresh login/direct/non-interactive/interactive/nested sessions, no startup
output regression, and no default-home cache recurrence before closing T-201.

**Live shell postflight:** every node reports two idempotent KEEP actions, exact
first-line prefixes, and unchanged file modes. Fresh login, direct SSH,
inherited non-interactive, interactive, and nested Bash assertions all see the
declared host/cache/XDG values. RI's interactive warning text is the intended
T-191 schedule warning, not a cache-bootstrap output. Guarded cleanup removed
the pre-fix 4 KiB AB/AB2 remnants and their SFTP-only postflights remain absent.
RI's 4 KiB/two-entry remnant was twice guarded-cleaned with manifests and
boundaries fully removed, but an SFTP subsystem-only connection found the
directory recreated without running shell startup. T-203 owns that distinct
site/PAM-or-concurrent-process diagnosis; do not churn it with repeated deletes
or weaken `HOME`. Close T-201 only after one native batch inherits the declared
variables on each node. `tests/smoke/jobs/cache-startup-readiness.sh` is the
small, scheduler-neutral gate: it removes all inherited managed cache values,
enters login Bash, re-enters non-login Bash to avoid RI's known EXIT defect,
then validates the independent declared host/cache/XDG paths and publishes a
mode-0600 result. Focused and portable full suites pass. Commit, distribute,
collision-check, and run this five-minute/default-priority gate before closing.

**Batch-gate submission checkpoint:** exact commit `96de5d2` is clean on all
seven nodes; all collision checks found absent results and zero exact-name
jobs. Native schedulers accepted local Ybatch `91169`; AB PBS `2045001.pbs1`;
AB2 PBS `2045000.pbs1`; RI Slurm `6997`; AL Slurm `4223834`; RC Slurm
`211014`; and T4 AGE `8179679`. Monitor only these IDs and publish no batch
inheritance claim until scheduler accounting and terminal private results agree.

**Batch-gate outcome:** all seven terminal private results report PASS/status
zero and all native scheduler records report exit zero. The matched evidence is
`docs/audits/cache-startup-readiness-2026-07-16.json`. Each job first removed
the submit shell's managed values, entered login Bash, and independently
reconstructed the declared host/cache/XDG/application-cache paths. T-201 is
complete: ordering, shell modes, rollback, and batch inheritance are proven.
The persistent RI directory is explicitly not attributed to Bash and remains
isolated in T-203.

### T-202 — AB Mozilla application-native relocation

**Phase/status:** `owner-gated`; not a quota emergency. AB's retained
`.mozilla` is 12 KiB, Firefox is not running, the intended fast target is
absent, and source/target parents are on different filesystems. Never inspect
or agent-copy this potentially credential-bearing profile. Present an
application-native new-profile/re-authentication route, selective non-secret
owner migration, launch test, rollback, and final symlink plan as a future PIE
interview.

### T-203 — RI shell-independent default-cache recurrence

**Phase/status:** `planned` from T-201. RI recreates a 4 KiB/two-entry
`~/.cache` after an exact guarded cleanup even when the next connection uses
the SFTP subsystem and no Bash startup file. Preserve the tiny directory while
diagnosing; repeated deletion is not progress. Use value-free timing/type/count
evidence and official site/PAM documentation or owner/site support. Do not
trace startup values, list child names, inspect contents, weaken `HOME`, or
guess an application. If a responsible component is proven, prefer its native
cache configuration and re-run the SFTP-versus-shell experiment.

**Value-free diagnosis:** the preserved recurrence is currently a real
mode-0700 cache directory containing one mode-0644 zero-byte regular file;
directory and child birth/change times are identical
(`2026-07-16T14:12:51Z`), and no process holds the directory open. RI uses the
stock `/usr/lib/openssh/sftp-server`, has no user or system SSH rc file, and its
SSH PAM stack lists only standard access, environment, key, limits, loginuid,
mail, MOTD, nologin, and SELinux modules. This excludes a visible SSH rc
wrapper, internal-sftp customization, shell startup, persistent writer, or
multi-file application cache, but it does not identify the creator. Further
attribution needs site-admin audit evidence or a site explanation; do not
enumerate the marker name, install tracing, repeat deletion, or infer an
application from a zero-byte file.

### T-204 — Remove obsolete AB2 pyenv startup calls

**Phase/status:** `complete`. AB2 emitted exactly three
`pyenv: command not found` diagnostics on each login because `.pyenv` was
owner-approved for deletion while startup invocations remain. Identify only
the exact pyenv-related lines and structural context needed for a reviewed
patch; never print unrelated startup content. Add a transactional, byte-exact
remediation with rollback and fake-home tests, preserve all other owner lines,
then prove direct/login/interactive silence without reinstalling pyenv.

**Implementation checkpoint:** the live value-limited review found one exact
six-line block in AB2 `.bash_profile` (heading, `PYENV_ROOT`/`PATH`, and three
`eval` calls) and no pyenv line in `.bashrc`. `harness remediate --host ab2`
now verifies that entire public block and transactionally replaces it with six
same-length inert comments, preserving every unrelated byte and offset. The
existing patch rollback validates exact size/offset/payload. Fake-home tests
prove plan/apply/idempotence, no synthetic-secret copy, surrounding-line
preservation, changed-patch refusal, and exact rollback; portable and native
full suites pass. Commit and distribute, then require a clean live plan before
applying and capturing the AB2 transaction ID.

**Live outcome:** exact revision `000045f` produced one unambiguous 162-byte
live plan, and transaction `20260716T142824Z-1970447` completed. This is the
exact rollback ID. Require an idempotent KEEP plan, unchanged file mode/size,
zero pyenv literal matches in the reviewed file, and warning-free direct,
login, and interactive sessions before closing T-204.

**Postflight:** the live plan is now an idempotent KEEP; `.bash_profile` remains
mode 0640 and byte-identical in size, both startup files contain zero pyenv
literal matches, fresh direct/login paths contain no `.pyenv` component, and
direct/login/interactive checks pass without a pyenv diagnostic. T-204 is
complete; transaction `20260716T142824Z-1970447` remains the rollback point.

### T-205 — Fail-closed scheduler-chain visibility

**Phase/status:** `complete`; prompted by a false-negative RI audit. A direct
non-login `restic-schedule status` reported captured Sunday job `6862` absent,
while native login-environment `sacct`, `scontrol`, and `squeue` independently
proved the exact job healthy, owner-matched, `PENDING` for its declared
2026-07-19 02:00 JST eligibility, and unchanged. The direct shell lacked only
RI's public `SLURM_CONF_SERVER=sctl1:6817,sctl2:6817`; no scheduler state was
changed and no replacement job was submitted.

Declare that public endpoint in RI's host profile for direct harness calls and
change exact Slurm status queries to an owner-scoped scheduler listing that
must succeed before absence is inferred. A scheduler connectivity failure must
fail closed, produce no “missing job” warning, and never reach adoption or
submission as if discovery were empty. Add a deterministic failure regression,
run the full portable suite, distribute the exact commit, then prove both
direct and login status see the original `6862` and that all seven original
T-191 jobs remain singleton and unchanged before closing T-205.

**Outcome:** targeted scheduling tests, the native full phase-1 suite, warning
level ShellCheck, diff checks, and the value-free public audit passed. Exact
commit `d3d0eff` was fast-forwarded into six clean remote worktrees through a
5,105-byte verified public bundle, and every local/remote bundle is absent.
Fresh direct status sees all seven original T-191 IDs; RI direct and login
status both see unchanged job `6862` `PENDING`. The test suite also proves that
a Slurm discovery failure emits no false missing warning, submits no job, and
creates no chain state. T-205 is complete without any scheduler write.

### T-206 — Reviewed LLM framework environment

**Phase/status:** `planned`, intentionally gated after T-200 accelerator
evidence. No managed node exposes PyTorch in its declared base login or AL uenv
route. Select a reproducible project-scoped environment or immutable image for
the tracked tiny-language-model forward/backward test; do not install into a
base home, pull an unpinned image, or silently choose divergent versions per
node. First reconcile architecture, CUDA/driver compatibility, package source,
lockfile or digest, cache placement, license, and rollback. This task may
prepare a value-free option matrix autonomously, but package installation,
image pull, or live environment selection remains owner-gated.

### T-207 — Scheduler-native MPI correctness gate

**Phase/status:** `planned` after T-200. Discover and freeze each site's
declared MPI/compiler route, then run the tracked bounded MPI source with two
ranks on one allocated node before any multi-node or GPU-aware claim. Require
rank uniqueness, expected world size, launcher identity, compiler/library
provenance, scheduler/result zero, private collision-resistant evidence, and
guarded scratch cleanup. Reuse T-191-approved CPU accounts/resources, default
priority, and five-minute limits. Do not infer ABI compatibility from login
PATH, cross node boundaries, run a benchmark, or use an unreviewed container.

**Route freeze:** the five reviewed base routes are local Open MPI 5.0.8 with
native `mpirun -n 2`; AB/AB2 HPC-X 2.26/Open MPI 5.0.10rc1 with `mpirun -n
2`; AL `prgenv-gnu/25.11:v1` Cray MPICH 8.1.32 with native `srun --ntasks=2`;
and T4 HPC-X 2.21/Open MPI 4.1.7rc1 with `mpirun -n 2`. The tracked job
unloads/reloads the exact module where applicable, compiles one source, asserts
the allocated architecture, and publishes one mode-0600 result. Local uses
Ybatch `thrp_1`; AB/AB2 use their approved `rt_HC select=1`; AL uses
`g177-1/normal` plus native uenv integration; and T4 uses `cpu_4=1`. RI and RC
remain explicit no-route skips: neither exposes an architecture-compatible MPI
wrapper on its selected Arm compute base. Do not allocate them for this gate or
carry RC's x86 login-only MPICH binary onto GH200.

**Submission checkpoint:** exact commit `e034477` was installed into six clean
remote worktrees by a verified 3,277-byte public bundle; every bundle is
absent. Fresh result/name collision checks passed before native acceptance of
local Ybatch `91213`; AB PBS `2045044.pbs1`; AB2 PBS `2045043.pbs1`; AL Slurm
`4224197`; and T4 AGE `8179808`. Local, AL, and T4 already report two unique
ranks, scheduler/result zero, and guarded cleanup. The two ABCI jobs remain
validly queued; monitor only these captured IDs and do not submit replacements.

**ABCI v1 failure and v2 correction:** both PBS jobs eventually reached
terminal `Exit_status=1` without creating their private result, while the
identical source already passed local, AL, and T4. The only pre-result code was
the HPC-X module unload/reload plus non-login re-exec, so no MPI transport claim
or diagnostic can be inferred. Preserve both failed records. V2 installs the
private capture/trap first, performs the same exact process-local module setup
inside that capture, and continues without re-exec. After tests and exact
distribution, retry only AB/AB2 with run tag v2 and distinct names; a second
failure must still publish its bounded diagnostic instead of disappearing.

### T-208 — Immutable training-environment transport matrix

**Phase/status:** `design complete`; execution remains under T-206's owner
gate. Native value-free discovery and official documentation are reconciled in
`docs/immutable-environment-matrix.md`. The fleet has four viable mechanisms:
allocation-only Docker/Podman wrappers on local; SingularityCE 4.4.1 on
AB/AB2; Apptainer 1.4.5 plus Slurm OCI flags on RI; native uenv 10.0.1 plus
Slurm integration on AL; SingularityCE 4.5.0 plus Slurm OCI flags on RC; and
Apptainer 1.4.0 on T4. No image, registry, daemon, or credential was accessed.

Use one reviewed dependency definition/lock with two immutable architecture
artifacts and recorded digests, not one binary image: x86_64 for local,
AB/AB2, and T4; aarch64 for RI, AL, and RC. Prefer AL's site-native uenv and
Singularity/Apptainer SIF elsewhere unless a tested site-native OCI bundle is
materially better. Store large images/bundles under each persistent root,
caches under the declared fast cache root, and only non-secret definitions,
locks, provenance, and digests in harness. Before T-206 chooses anything,
validate licensing, CUDA/driver compatibility, compute-node runtime, GPU
selection, bind paths, home isolation, cache placement, and exact rollback.

### T-209 — Declared training-storage readiness gate

**Phase/status:** `complete`; read-only fleet discovery passed. Every declared
persistent and cache root is a real owner-writable directory outside canonical
home. Current uses NFS; the other roots use Lustre. Each reported filesystem
has more than 750 GiB free and more than 977,000 free inodes at discovery time,
but shared-filesystem `df` values are not a user-quota promise.

`harness storage-readiness --host HOST` now revalidates the unique public
layout row, exact canonical root identity, owner, writability, outside-home
boundary, filesystem type, and current free blocks/inodes without mutation.
`--write-probe` adds one mode-0600 4 KiB write+fsync in each exact root and
unlinks only that already-validated file, with a trap that refuses cleanup if
type, owner, dirname, or basename identity changes. Fake-root tests prove the
read-only path, two successful exact cleanups, inside-HOME rejection, symlink
rejection, and zero residue. After full-suite validation, commit/distribute,
run fresh read-only plans, then execute one bounded live probe per root and
verify no probe name remains. This is correctness only, not an I/O benchmark or
quota/capacity reservation.

**RC fail-closed correction:** the first live plan stopped before writing
because `/lvs0/rccs-asfm/rio.yokota` canonically resolves to the same
device/inode at `/lvs0/dne0/rccs-asfm/rio.yokota`; cache has the analogous
alias, while neither root is HOME. The host profile now declares those two
exact canonical identities. The gate still rejects undeclared intermediate
aliases and symlink endpoints, and binds cleanup to the captured root
device/inode. Tests prove undeclared-alias rejection, exact declared-alias
acceptance, write/fsync, and zero residue. Recommit/distribute this correction,
then repeat every read-only plan before any live probe.

**Outcome:** exact commit `e5e89ce` reached all six clean remotes and every
transport bundle is absent. Seven repeated plans passed. Fourteen live probes
then each wrote and fsynced exactly 4 KiB with mode 0600, revalidated the root
identity, exact-unlinked the probe, and reported cleanup absent. Independent
postflight searches for the restricted probe prefix found no residue in any
declared root. T-209 is complete; shared `df` values remain point-in-time
health evidence, not quota or future-capacity guarantees.

### T-210 — Cross-architecture numerical consistency gate

**Phase/status:** `executing` after T-200. The new tracked C++20 source uses
4,096 deterministic dyadic products whose frozen integer numerator is `-14036`
and exact binary64 result is `-0x1.b6ap+2`. It asserts IEEE-754 binary64,
round-to-nearest, forward/reverse bit identity, signed zero, the next value
after 1.0, quiet NaN, and two byte-identical outputs. Compile flags are
`-O2 -fno-fast-math -ffp-contract=off -frounding-math -Wall -Wextra -Werror`;
this is a strict reproducibility baseline, not permission to generalize to
fast-math, BLAS, GPU, mixed precision, or project numerics.

The scheduler-neutral job reuses the proven CPU compiler routes, validates the
allocated architecture, publishes one private fixed result, and guarded-cleans
scratch. Planned native requests are the T-200 five-minute/default-priority CPU
routes on all seven nodes. First run syntax/static tests, direct local compile
and repeat evidence, the full suite, public audit, commit/distribution, and
fresh result/name collision checks. The still-captured ABCI T-207 MPI jobs are
distinct work; do not cancel, resize, or duplicate them.

**Submission checkpoint:** exact commit `0d46b99` was installed into six clean
remote worktrees through a verified 5,110-byte public bundle, with every bundle
then absent. Fresh result/name collision checks passed before native acceptance
of local Ybatch `91220`; AB PBS `2045064.pbs1`; AB2 PBS `2045063.pbs1`; RI
Slurm `7013`; AL Slurm `4224277`; RC Slurm `211060`; and T4 AGE `8179846`.
RI, AL, RC, and T4 already report scheduler/result zero and the identical frozen
hex result twice. Local and both ABCI jobs remain validly pending; monitor only
these captured IDs and never infer failure or resubmit from queue delay.

### T-211 — Atomic checkpoint publication gate

**Phase/status:** `complete` after T-209. Extend the storage gate with a
mutually exclusive `--checkpoint-probe` that operates only in the declared
persistent root. It creates one unique mode-0600 staging file, writes and
fsyncs exactly 1 MiB of deterministic bytes, verifies the frozen SHA-256,
publishes without overwrite through a same-filesystem hard link, proves both
names are the same inode/link count, exact-unlinks staging, re-verifies the
published size/hash, syncs it, revalidates root identity, and exact-unlinks the
published name. Trap cleanup handles the two explicit validated names without
a deletion loop, glob deletion, or recursive action.

Fake-root tests prove publication, hash, cleanup, zero residue, mutual
exclusion from the 4 KiB write probe, and declared canonical-alias behavior.
This establishes bounded atomic checkpoint publication mechanics only; it is
not a checkpoint-format, directory-fsync, recovery, quota, throughput, or
distributed-coordination claim. Run the full suite/public audit, commit and
distribute, repeat read-only plans, then execute one live persistent-root probe
per node and independently verify the restricted prefix is absent.

**Outcome:** exact commit `f1dafda` reached all six clean remotes and every
bundle is absent. Seven repeated plans passed. Each persistent root then
published and verified the exact 1 MiB checkpoint probe and reported both
names absent. An independent restricted-prefix postflight found zero residue
on all seven nodes. T-211 is complete within its narrow atomic-hardlink scope.

### T-212 — Direct development-debugger gate

**Phase/status:** `executing`; no scheduler allocation is required. The tracked
tiny C program has a non-inlined `checkpoint(35)` that returns 42. The bounded
login-node gate compiles it with `-g3 -O0 -fno-omit-frame-pointer`, runs GDB in
batch/no-init mode, and privately requires the exact function breakpoint,
argument value 35, continuation, and normal exit. Only compiler/GDB version and
a stable pass/fail category reach stdout; raw debugger output stays inside a
mode-0700 temporary tree removed through guarded cleanup.

Local direct execution and static/safety tests pass. Run the full suite/public
audit, commit and distribute, then execute once on all seven login nodes. This
establishes only direct local-process GDB usability; it does not claim remote
debugging, scheduler attach, MPI/GPU debugging, core-file policy, optimized
debug info, or profiler capability.

**V1 result and V2 classification:** local, RI, AL, and RC passed. AB, AB2,
and T4 returned nonzero from GDB before the stable breakpoint checks; the raw
logs were correctly guarded-cleaned and no cause is inferred. V2 maps only an
allowlist of raw signatures to `ptrace-policy`, `process-limit`, or
`temporary-storage`, otherwise reports `gdb-exit-uncategorized`; it never emits
the matched line. Commit/distribute and rerun only the three failures. Treat a
confirmed login ptrace policy as a boundary and test compute-node debugging in
a separate bounded task rather than attempting a bypass.

**Outcome:** V2 identifies AB and AB2 as `ptrace-policy` and T4 as
`process-limit`, without emitting matched raw lines. Local, RI, AL, and RC are
direct-development passes; the other three are explicit login-node gaps, not
installation failures. T-212 is complete within its direct-login scope and
hands bounded compute validation to T-213.

### T-213 — Compute-node debugger gate for restricted logins

**Phase/status:** `executing` after T-212. Run the same guarded GDB breakpoint,
argument, continuation, and normal-exit test inside one five-minute/default-
priority CPU allocation on AB, AB2, and T4 only. A scheduler-neutral wrapper
requires the native allocation identity, captures only safe direct-gate output,
and publishes one mode-0600 fixed result even on failure. Use approved
`rt_HC select=1` groups for ABCI and `cpu_4=1` for T4. Do not change ptrace,
process limits, core policy, packages, or login behavior. Commit/distribute,
collision-check, submit once, and monitor only captured IDs.

**Submission checkpoint:** exact commit `5fadfbd` reached all six clean remotes
through a verified 2,332-byte public bundle; every bundle is absent. Fresh
result/name collision checks passed before PBS accepted AB `2045079.pbs1` and
AB2 `2045078.pbs1`, and AGE accepted T4 `8180554`. T4 already completed with
scheduler/result zero and the full inner breakpoint/argument gate. The two
ABCI jobs are validly queued; monitor only those IDs without replacement.

### T-214 — Offline project virtual-environment gate

**Phase/status:** `executing`; no allocation or package installation is
required. The tracked direct gate selects only the already-present `python3`,
requires managed `uv`, sets `UV_OFFLINE=1` and
`UV_PYTHON_DOWNLOADS=never`, and creates an unseeded project-independent venv
plus uv cache inside one mode-0700 temporary tree. It never activates the venv,
contacts an index, resolves dependencies, or writes project/home state. The
venv Python must run isolated with user site disabled and pass the tracked
standard-library smoke before guarded cleanup.

Run local execution, static/safety tests, the full suite and public audit;
commit/distribute; then execute once on all seven login nodes. This proves only
offline environment creation from the visible interpreter. It does not select
framework packages, validate a lock, seed pip, claim wheel availability, or
authorize any T-206 install/download.

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
