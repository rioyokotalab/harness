# Personal harness task board

This is the authoritative resume point for the portable Codex and Claude
harness. Git retains superseded chronology and command-level evidence. Keep
only active decisions, verified prerequisites, blockers, exact next actions,
and compact historical pointers here. Next free ID: T-264.

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
- All managed checkouts are kept clean and synchronized through guarded
  fleet-sync; `968796f` is the latest verified fleet checkpoint. Fresh
  interactive Bash shells load shell-local destructive-command safeguards;
  child and batch shells do not. Login and shell exit perform no automatic Git
  work.
- Harness and website `main` rulesets are active with their required CI check,
  linear history, conversation resolution, and force-push/deletion protection.
  The owner intentionally set required approvals to zero; PRs need no separate
  reviewer after the required check passes.
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

## Pause/resume checkpoint

The 2026-07-18 resume proved all six remote checkouts clean at `d80a036`, then
guarded-fast-forwarded and revalidated the complete fleet at `968796f`. T-210's
two remaining ABCI jobs passed and T-210 is complete. All seven T-191 jobs are
still captured with their exact owner/name and future eligibility. Resume T-191
after the first Sunday eligibility by querying only the seven IDs below; do not
infer absence from a failed query, and do not cancel, replace, or duplicate a
delayed job. T-196 remains blocked until T-191 reaches eight successful weekly
chains, two verified restores per node, and a current verified independent
generation.

## Active tasks

### T-191 — Scheduler-native weekly primary snapshots

**Status:** verification-pending. All seven bounded smokes passed and exactly
one production job per node was seeded for Sunday 2026-07-19. The last
read-only continuity audit on 2026-07-18 found every captured job present with
the expected owner/name and future eligibility. Local, RI, AL, and RC report
native Slurm `PENDING`/`BeginTime`; AB and AB2 report PBS `W`; T4's AGE record
is present. Every private mode-0600 chain state remains `active` with
`last_result=seeded` and `snapshot_id=none`. No job was submitted, replaced,
canceled, resized, or reprioritized.

| Host | Captured production ID | First eligibility |
|---|---:|---|
| `local` | `90939` | 00:30 JST |
| `ab` | `2044027.pbs1` | 01:00 JST |
| `ab2` | `2044028.pbs1` | 01:30 JST |
| `ri` | `6862` | 02:00 JST |
| `rc` | `210816` | 02:30 JST |
| `t4` | `8175651` | 03:00 JST |
| `al` | `4221054` | 01:00 Europe/Zurich |

**Frozen invariants:** each node independently maintains exactly one future
native-scheduler job. A delayed pending/held job is healthy and must never be
duplicated. When admitted, the job validates its identity, persists exactly one
strictly future successor, then takes one incremental snapshot tagged
`harness-hidden-home-weekly`; it never backfills missed weeks. Keep all
snapshots. No `forget`, `prune`, retention deletion, automatic replica,
login-node cron/timer, or scheduled full-data check is authorized. RI's
site-forced one-GB200 allocation is owner-accepted.

**Resume/acceptance:** after the first eligibility, fetch and prove a clean
fleet, then query only the seven IDs above with each site's declared native
scheduler route. A failed query is unknown state, not absence. After admission,
require scheduler and snapshot success, one owner/name-matched successor at the
next strictly future Sunday, consistent private state, and healthy interactive-
login silence. T-191 remains open until all seven first snapshots and
successors pass. Canonical commands and resource/timezone declarations are in
`profiles/restic-schedules.tsv`, `libexec/harness-restic-schedule`, and
`docs/home-backup.md`; full implementation and failure chronology is retained
at `d910a40:TODO.md`.

### T-196 — Backup lifecycle phase 2

**Phase/status:** `policy resolved`, execution-gated on eight successful weekly
chains, two verified restores per node, and a current verified independent
generation. T-251 locked the 12-weekly/12-monthly/3-yearly exact-group policy,
monthly rotating quarter-data checks, quarterly full-data/full-restore checks,
monthly sampled restores, and monthly manual independent generations retaining
the latest two verified copies. No live retention, `forget`, `prune`, recurring
check/restore, or replica automation is authorized yet. The eventual actions
remain behind their later exact-command authority boundaries.

**Outcome:** `docs/backup-lifecycle-phase2.md` records official Restic 0.19.1
semantics, recommended generous retention, separate forget/prune transactions,
deterministic data-check coverage, restore drills, manual-first independent
replicas, collision/lock rules, phased acceptance gates, rollback evidence, and
the resolved owner policy. No Restic, scheduler, replica, deletion, or
credential-path command ran. Keep-all remains effective until T-191 production
stabilizes and the owner separately approves the exact first `forget` and later
separate `prune` commands.

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
- Fresh interactive Bash shells wrap direct `rm`, `rsync`, `find`, `chmod`,
  `chown`, `qdel`, and `scancel` commands. Normal forms pass through unchanged;
  protected high-blast-radius forms fail before native execution. `command`,
  absolute executable paths, child shells, and batch scripts remain deliberate
  bypasses, so the manifest-backed guarded-delete workflow remains mandatory
  for agent-run recursive or bulk deletion.
- The current node uses the packaged systemd user SSH agent at the fixed
  current-user-owned socket declared in `docs/ssh-agent.md`. Recovery checks
  the process socket, current tmux session, then the declared fixed socket; it
  never reads tmux-global agent state or key contents.
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

Git history is the durable evidence store. Consult `303938f:TODO.md` for the
earlier recovery/storage history and `d910a40:TODO.md` for detailed T-193
through T-261 chronology when command-level evidence, transaction IDs,
aggregate counts, hashes, or failure chronology is required.

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
| T-193–T-195 | Public-repository audit, contributor CI/ruleset preparation, and seven-node drift audit completed or superseded; full detail is at `d910a40:TODO.md`. |
| T-197–T-209 | Evaluation decision and portable environment/HPC capability foundations completed; full detail is at `d910a40:TODO.md`. |
| T-210 | Cross-architecture numerical consistency passed on all seven routes. On 2026-07-18, exact PBS history confirmed AB `2045064.pbs1` and AB2 `2045063.pbs1` terminal `F`/`Exit_status=0`; both private mode-0600 results matched the frozen source contract and `-0x1.b6ap+2`, with zero capture residue. Full chronology is at `d910a40:TODO.md`. |
| T-211–T-246 | Checkpointing, debugger, MPI, scheduler, topology, intake, audit, and durable-handoff gates completed; full detail is at `d910a40:TODO.md`. |
| T-247 | Captured readiness work and cleanup were completed or superseded by T-249–T-252; full chronology is at `d910a40:TODO.md`. |
| T-248 | Obsolete `.bash_common` startup references and files removed transactionally. |
| T-249 | Seven-node startup normalization, bounded agent forwarding, and four exact guarded environment deletions completed; durable evidence begins at `ce2ccce`, `2e93750`, and `53402ec`. |
| T-250–T-252 | Seven-node directory cleanup, owner/site gate resolution, and readiness-queue reconciliation completed; full detail is at `d910a40:TODO.md`. |
| T-253 | Stable packaged SSH agent, tmux/Codex propagation, and authenticated GitHub SSH transport completed; see `docs/ssh-agent.md`. |
| T-254–T-256 | Rootless GitHub CLI installation and separate authenticated API/settings preflight completed. |
| T-257 | Automatic Git fetch-at-login and commit/push-at-exit hooks removed at `e52a3d0`. |
| T-258 | Harness and website CI-backed `main` rulesets activated and PR-tested; later owner policy sets required approvals to zero. |
| T-259 | Interactive recursion sentinels made shell-local so aliases load in every new tmux window at `887f2c9`. |
| T-260 | PBS lifecycle email disabled by default for agent-run AB/AB2 jobs at `9b28c19`. |
| T-261 | Interactive destructive-command safeguards implemented, CI-tested, and rolled out across all seven nodes at `accca9d`; completion checkpoint `d910a40`. |
| T-262 | Active ledger compacted from 3,364 lines to the three resumable tasks; safeguard and live zero-approval ruleset documentation/payloads aligned and the complete portable suite passed. |
| T-263 | Harness and website made operationally independent: website owns cleanup, CI, policy/audit evidence, and rootless lftp bootstrap; harness removed all website-specific ownership. Isolated clones and required CI passed; website PR #3 merged as `6f1ad83`, harness PR #7 as `f1b095c`. No deployment, live tool removal, account setting, fleet, or scheduler action ran. |
