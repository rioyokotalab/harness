# T-317 fleet housekeeping and resilience audit

## Scope and authority

T-317 runs from 2026-07-27 08:30 JST to 20:30 JST, with material work ending
at 18:30. It covers:

- Linux: Local, ab, ab2, abq through both routes, ri, al, rc, and t4;
- macOS: aist, home, office, and riken through both routes;
- repositories: Harness, Students, Website, and Swallow.

The owner authorized ordinary non-administrator package/dependency maintenance
and normal task Git/PR/merge operations. The frozen boundary excludes active
job mutation, backup creation/deletion/retention changes, hosting
administration, credentials, active Students/Swallow disruption, and remote
branch deletion. Every recursive tree removal used the guarded-delete
transaction.

## Remote-aware Codex resilience

Harness added `codex-resilient --remote-session ID`. Its first launch and
every classified retry execute the same exact command:

```text
resume --remote unix:// ID
```

The supervisor retries non-usage, non-operator exits only after the native
Codex doctor confirms auth, config, installation, and state paths. Provider
and WebSocket reachability may recover during bounded backoff. The state file
is mode 0600 and value-free; it stores neither prompt nor transcript.

| Root | Supervisor | Owner PID | Selector | Live view |
| --- | --- | ---: | --- | --- |
| Harness | `harness-canary` | 4063793 | `remote-explicit` | supervised `harness` |
| Students | `students` | 4073421 | `remote-explicit` | detached guard plus protected direct view |
| Swallow | `swallow` | 4077898 | `remote-explicit` | detached guard plus protected direct view |

Focused tests prove exact remote retry, doctor gating, backoff
15/30/60/120/240/300 seconds plus bounded jitter, reset after healthy runtime,
operator-signal refusal, and prompt replay disabled. Fresh native doctor
readback reports all checks `ok`. The original Students and Swallow views
remain direct because replacing them would disrupt active agents; the detached
guards preserve an exact supervised connection without signaling either
project.

The three long-lived supervisors hold the old NFS-unlinked script inode open,
so `libexec/.nfs0000000002a8b30d0001f88e` must remain until they exit
naturally. It is live kernel residue, not a cleanup candidate.

## Fleet readback

### Linux

| Node | Routes | Arg0 after cleanup | uv | rclone | Primary Restic | Snapshots | Future backup job | Storage note |
| --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| Local | pass | `live=7 eligible=0 unexpected=0` | 0.11.32 | 1.74.4 | metadata pass | 3 | `94950` | shared `/home` 96%, owner data volume 1% |
| ab | pass | all zero | 0.11.32 | 1.74.4 | metadata pass | 3 | `2064918.pbs1` | `/groups` 51%, 4% inodes |
| ab2 | pass | all zero | 0.11.32 | 1.74.4 | metadata pass | 3 | `2064919.pbs1` | `/home` 11%, 11% inodes |
| abq | both pass | all zero | 0.11.32 | 1.74.4 | metadata pass | 2 | `176525.qjcm` | `/home` 8%, 1% inodes |
| ri | pass | all zero | 0.11.32 | 1.74.4 | metadata pass | 3 | `10386` | `/home` 1%, 1% inodes; scheduler query unknown |
| al | managed pass | all zero | 0.11.32 | 1.74.4 | metadata pass | 3 | `4275926` | `/users` 5%; one 50 GiB project quota 51% |
| rc | pass | all zero | 0.11.32 | 1.74.4 | metadata pass | 3 | `260847` | work filesystem 28%, 10% inodes |
| t4 | pass | all zero | 0.11.32 | 1.74.4 | metadata pass | 3 | `8270230` | `/home` 5%, 1% inodes |

Every metadata-integrity check acquired/released the native Restic lock,
loaded indexes, checked all pack references, and verified snapshots, trees,
and blobs in 1–25 seconds. No data-pack sampling or backup mutation ran. All
lock directories, task captures, and Restic processes are absent afterward.

RI scheduler state remains unknown because Slurm DNS SRV lookup fails.
Scheduler state on the other seven nodes contains only the exact future weekly
backup jobs above. No job was submitted, cancelled, requeued, reprioritized,
or otherwise changed.

Local runs Ubuntu 24.04 kernel `6.8.0-134`; installed `6.8.0-136` requires a
reboot. Metadata reports 92 upgrades including 32 security updates. The
administrator transaction and reboot are deferred to avoid active-agent
disruption. The apt daily/unattended timers are healthy and no dpkg lock is
held.

### macOS

| Host | Routes | Arg0 | Homebrew plan | Updates | Security posture | Backup |
| --- | --- | --- | --- | --- | --- | --- |
| aist | both pass | `live=3`, no residue | zero changes | none | FileVault/SIP/Gatekeeper on; firewall/stealth off | no Time Machine destination |
| home | both pass | `live=3`, no residue | zero changes | none | FileVault/SIP/Gatekeeper on; firewall/stealth off | no Time Machine destination |
| office | both pass | `live=3`, no residue | zero changes | none | FileVault/SIP/Gatekeeper on; firewall/stealth off | no Time Machine destination |
| riken | both pass | `live=3`, no residue | zero changes | none | FileVault/SIP/Gatekeeper on; firewall/stealth off | no Time Machine destination |

All four Macs converge on libnghttp3 1.18.0, SQLite 3.53.4, and uv 0.11.32.
Homebrew cleanup reclaimed approximately 68.4/129.0/198.9/189 MB and repeat
dry runs are empty. A one-snapshot installed-formula inventory fixed
Homebrew alias drift and reduced Office plan time from 77.97 to 16.37 seconds
(4.76x faster).

There are no Homebrew services, outdated formulae/casks, Apple updates, X11
TCP-range listeners, or active Time Machine operations. Wildcard listeners
are signed Apple continuity/device services and Dropbox. The existing
mode-0700 firewall helpers remain staged with checksum
`f83690717bc2826af203336196d8ce73b26adc33939762bb325ed66de684d33b`;
they require owner-local administrator authentication.

## Backup recovery gaps

Every primary repository passes structural metadata integrity. Independent
replicas are older:

| Source | Primary snapshots/latest | Replica generation | Replica snapshots/latest |
| --- | --- | --- | --- |
| Local | 3 / July 26 | `20260715T222741Z` | 1 / July 15 |
| ab | 3 / July 26 | `20260715T222741Z` | 1 / July 15 |
| ab2 | 3 / July 26 | `20260716T023458Z` | 1 / July 16 |
| abq | 2 / July 26 | `20260722T092250Z` | 1 / July 22 |
| ri | 3 / July 26 | `20260715T222741Z` | 1 / July 15 |
| al | 3 / July 26 | `20260715T222741Z` | 1 / July 15 |
| rc | 3 / July 26 | `20260715T222741Z` | 1 / July 15 |
| t4 | 3 / July 26 | `20260715T222741Z` | 1 / July 15 |

The primaries total about 40 GiB. T-196 expressly requires manual
checks/restores before a current immutable generation and forbids automatic
replica creation, so T-317 did not copy them.

All four Macs report no Time Machine destination and no local Time Machine
snapshot. This is not evidence that no other backup exists, but Harness
declares none. Storage selection and Mac backup configuration require an owner
decision.

## Repository and hosting matrix

| Repository | Worktree | Integrity | Dependencies | Hosting |
| --- | --- | --- | --- | --- |
| Harness | task branch plus live `.nfs…` | strict fsck pass | managed utilities current; deferred source-built tools | protected strict `portable-phase1` |
| Students | protected active `main` | fsck pass; 51 MiB loose plus 54-byte temp objects | lock present; PR #39 behind current main | strict two-check protection; production Slack deployment failed |
| Website | clean current `main` | fsck pass; zero garbage | Playwright 1.62.0; checkout v7.0.1 | PR #36 merged, no deployment |
| Swallow | protected active AB branch; clean T4 mirror | both fsck pass | no package lock; local SIF hash pinned | strict `Offline checks`; no task mutation |

All four repositories have:

- active main rulesets that reject deletion/non-fast-forward updates, require
  linear history, resolved conversations, and strict current checks;
- zero required approving reviews and one bypass actor;
- read-only, non-approving default workflow permissions;
- full-SHA Action pins and non-persisted checkout credentials;
- Dependabot and automated security updates enabled with zero open alerts;
- zero Actions caches, artifacts, and open issues.

Harness and Website have secret scanning and push protection with zero alerts.
The private Students and Swallow repositories lack that entitlement. Code
scanning is unavailable on all four. Students/Website restrict Actions and
enforce SHA pinning at the host; Harness/Swallow currently allow all Actions
without host-enforced SHA pinning.

Students scheduled run `30165098550`, deployment `5602726317`, failed at the
combined collection/post step with Slack API error `not_in_channel`. Current
Students `main` has no workflow or implementation change that resolves it.
Do not dispatch, alter the environment, inspect secrets, or invite the bot
outside a project-local owner-authorized Slack correction.

Swallow verifies the staged `nemo-26.06.sif` as
`b625ee8ea6bf89830935eb179055389c195173b624652541e8d85ff49d9287ee`,
but bootstrap begins from mutable registry tag `nvcr.io/nvidia/nemo:26.06`
without an immediate digest assertion. Defer digest-qualified pull and
post-pull verification to SW-031.

## Published changes

| Repository | PR | Merge | Result |
| --- | ---: | --- | --- |
| Harness | #334 | `0ad118b` | remote-aware resilience; uv/rclone declarations |
| Harness | #335 | `e61c16b` | fleet housekeeping checkpoint |
| Harness | #336 | `99617e1` | alias-safe, faster Mac package plan |
| Website | #35 | `141a79e` | Playwright 1.62.0 |
| Website | #36 | `9e1cd10` | checkout v7.0.1; linked-worktree hook doctor |

Every Harness merge passed `portable-phase1`, synchronized all eleven clean
remote checkouts, and sent exactly one post-sync context refresh to each
validated Mac Codex pane. Every Website merge passed `Offline checks`; no
Website deployment ran.

## Guarded deletion and cleanup

- Six Linux and four Mac arg0 candidates were quarantined, revalidated, and
  guarded-deleted; all final inventories have zero eligible/unexpected.
- Homebrew internal cleanup used only the reviewed package-manager exception.
- Website T-209 and T-210 isolated worktrees were removed after clean,
  tree-equality, merge, and open-handle gates. T-210 deleted exactly 403
  entries / 61,097,424 bytes below `/tmp`.
- Test/sync clones and their manifests were exact-verified and removed.
- No active process, repository worktree, backup, scheduler state, credential,
  cache with unresolved ownership, or protected project artifact was deleted.

## Deferred actions

1. Owner-local authentication: apply and verify the four exact Mac firewall
   helpers, then exact-unlink each helper.
2. Owner storage choice: select/configure Mac backup destinations.
3. T-196 gates: complete weekly stability/restores and create current manual
   encrypted replica generations; do not automate yet.
4. Hosting-policy decision: reconcile zero required reviews and bypass actors,
   plus host-enforced Action restrictions for Harness/Swallow.
5. Students-local Slack administration: resolve production
   `not_in_channel`; do not rerun until membership is corrected.
6. SW-031: digest-qualify NeMo bootstrap and continue evidence-only
   reasoning/tool-use throughput planning.
7. Administrator maintenance window: apply Local security updates and reboot
   only after active agents and jobs are safely quiesced.
8. Active-agent maintenance: resolve value-free agent-config collisions and
   pack Students loose objects only after those agents finish.

## Final validation checklist

At the 18:30 cutoff, repeat:

- supervisor status, tmux metadata, native Codex doctor, and Local arg0 plan;
- canonical fleet health and Mac tunnel/session doctors;
- exact native scheduler future-job readback;
- primary Restic access and absence of locks/processes (do not repeat
  full-data work);
- Git branch/worktree/upstream status, PR/check state, and live rulesets;
- task-temp/helper/residue inventory and `git diff --check`;
- full clean Harness `tests/test-phase1.sh`.

Stop all material work at 18:30 and use the remaining two hours for this
readback, final audit correction, protected publication, fleet sync if needed,
and durable handoff.
