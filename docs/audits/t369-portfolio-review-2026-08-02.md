# T-369 portfolio review — 2026-08-01/02

## Decision standard

This review optimizes expected owner/research value per unit of authorization,
maintenance, context, compute, and failure risk. It does not optimize deletion
count or preserve work merely because effort has already been spent. Local
facts are classified separately from web guidance; no fetched instruction was
executed.

## Authoritative source matrix

| Domain | Primary source | Decision |
| --- | --- | --- |
| Git worktrees | Git, [git-worktree](https://git-scm.com/docs/git-worktree.html) | Adopt isolated worktrees and explicit removal of stale administration; add Harness lifecycle enforcement rather than relying on eventual prune. |
| Branch safety | GitHub, [protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches) | Preserve protected `main`, linear history, blocked force updates, and accepted zero approvals; archive exact local tips before cleanup. |
| Portfolio flow | GitHub, [Projects best practices](https://docs.github.com/en/issues/planning-and-tracking-with-projects/learning-about-projects/best-practices-for-projects) and [Kanban Guide 2025](https://kanbanguides.org/the-kanban-guide/2025.5/pdf/kanban-guide.v2025.5.en.pdf) | Adopt one source of truth, smaller work items, explicit status/priority, and limited work in progress. Completed tasks and dormant implementation proposals do not belong in active queues. |
| Student-facing AI | NIST, [AI RMF](https://airc.nist.gov/airmf-resources/airmf/) and [AI RMF Core](https://airc.nist.gov/airmf-resources/airmf/5-sec-core/); Slack, [least-privilege scopes](https://slack.dev/least-privilege-a-slack-approach-to-scopes/) | Require a use-case-specific pilot profile with explicit human oversight, knowledge limits, risk tolerance, participant feedback, and measured benefits/costs. Every Slack scope must map to a current feature; reject speculative scopes and model action authority. AI RMF 1.0 is currently being revised, so use the final 1.0 baseline and monitor rather than adopting an unfinished revision. |
| Actions sustainability | GitHub, [billing and usage](https://docs.github.com/en/billing/concepts/product-billing/github-actions), [GitHub-hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners), [self-hosted runners](https://docs.github.com/en/actions/concepts/runners/self-hosted-runners), and [secure use](https://docs.github.com/en/actions/reference/security/secure-use) | Keep owner-authored protected local validation and retain hosted isolation for untrusted or mixed-contributor work plus bounded periodic/manual gates. Do not register these persistent, credentialed project machines as general self-hosted runners: GitHub warns they lack clean-VM guarantees and can be persistently compromised. Do not add scheduled hosted work merely for bookkeeping. |
| Research software | FAIR4RS, [RDA recommendation](https://doi.org/10.15497/RDA00068) and [primary paper](https://www.nature.com/articles/s41597-022-01710-x) | Adopt versioned, identifiable, documented, reusable artifacts and explicit software/environment provenance. |
| Artifact evidence | ACM, [Artifact Review and Badging](https://www.acm.org/publications/policies/artifact-review-and-badging-current) | Adapt the functional-artifact criteria—documented, consistent, complete, exercisable, validated—to SW-034 before spending more compute. |
| ML benchmarking | MLCommons, [benchmark principles](https://mlcommons.org/benchmarks/) and [inference rules](https://github.com/mlcommons/inference_policies/blob/master/inference_rules.adoc) | Preserve fixed inputs/seeds, full hardware/software disclosure, matched systems, replicability, and claim limits; reject unmatched score transfer. |
| Web accessibility | W3C WAI, [evaluation overview](https://www.w3.org/WAI/test-evaluate/), [ongoing monitoring](https://www.w3.org/WAI/eval/considerations), and [sustainability](https://www.w3.org/WAI/planning-and-managing/sustain/) | Keep automated gates but add bounded human, keyboard, and assistive-technology sampling at material changes and quarterly checkpoints. |
| Sensitive automation | NIST, [Privacy Framework 1.0](https://www.nist.gov/document/nist-privacy-frameworkv10pdf) and [Privacy Framework home](https://www.nist.gov/privacy-framework) | Keep source content in authoritative services, minimize collection/retention, and design the full creation-to-disposition lifecycle. Version 1.0 remains the final baseline; 1.1 is still an initial public draft, so monitor rather than silently adopting draft text. |
| OAuth capability | Google, [OAuth best practices](https://developers.google.com/identity/protocols/oauth2/resources/best-practices), [granular permissions](https://developers.google.com/identity/protocols/oauth2/resources/granular-permissions), and [desktop-app flow](https://developers.google.com/identity/protocols/oauth2/native-app) | Request the smallest scope in context and handle partial denial. Because installed apps do not support incremental authorization, request the complete staged set when adding a feature, then persist only the granted subset, disable denied capabilities, store tokens outside Git, and make revocation/recovery explicit. |

## Local repository judgments

### Harness — adapt, with two cancellations

The control plane is broadly on the right track: repository-native ledgers,
conditional policy routing, guarded transactions, local owner validation, and
protected publication all match the evidence. Its main cost is lifecycle
complexity. T-363 correctly diagnosed shared-checkout collisions and abandoned
worktrees, but the observability lease is unnecessary until measured. It is
superseded by T-370's plain per-task worktrees and mandatory teardown. T-354 is
canceled because relocating healthy canonical roots is cosmetic while the
saved-root, encrypted-state, phone, and rollback cutover is material. Backup,
outage recovery, and trusted NFS diagnosis remain real event gates.

### Students — adapt toward one pilot decision

The privacy and identity architecture is strong: affirmative consent,
encrypted post-consent state, immutable Slack IDs, no model action tools,
student-owned accounts, and credential-free tests. The queue was not: it
listed completed infrastructure as active and split one future pilot across
four blocked rows. Those rows become one T-052 decision packet. T-050 is
canceled because a synthetic credential-rotation agent benchmark is outside
the advising mission and does not reduce a current student risk. Nine merged
controller worktrees and branches were safely retired; the divergent live
Claude branch and open Dependabot PR #560 are preserved.

### Swallow — preserve the valuable result, stop the program

The project is scientifically disciplined where it separates sites,
correctness, profiling, and performance and records exact native scheduler
evidence. It had severe lifecycle residue: 123 Swallow-named `/tmp` roots and
multiple completed cowork branches. SW-031 is canceled rather than waiting
indefinitely for capacity; a new hypothesis must use a new bounded task. The
25-commit SW-034 branch is high-value unpublished evidence and is preserved.
SW-040 prioritizes independent functional-artifact review and protected
publication before any more compute. Exact reproduction remains unresolved;
the 100-question diagnostic is not promoted to a leaderboard claim.

### Website — maintain, do not redesign

The static bilingual site is on the right track: stable URLs, mirrored EN/JP,
positive deployment allowlisting, locked browser checks, supply-chain pins,
and no unnecessary build system. It has no product backlog requiring a
redesign. The next valuable task is change-triggered and quarterly human
accessibility/source sampling, not more hosted CI. The board's old one-review
drift was stale; zero approvals is the owner's accepted live policy. One stale
56.8 MB public staging tree was guarded-deleted. Remote branch
`origin/t211-overnight-health-audit` remains report-only under Harness policy.

### Personal — expand only through capability lifecycle

Personal's metadata-only architecture, absent Actions, source-system retention,
and exact external-write gates are appropriate for sensitive work. Its README
lagged the accepted Calendar work and is corrected without source values. P-005
adds a value-free capability inventory plus offline revocation, partial-scope,
and recovery tests before any new connector. Research-budget and assistant
access remain explicit source/identity gates, not speculative implementation.
The freshness pass exposed one real integration gap: the pure partial-scope
classifier did not yet control the installed-app consent write. P-006 closes
that gap by atomically replacing old token metadata with the exact granted
subset and rejecting unrequested scopes before persistence; no live consent or
credential access was used.

## Cleanup snapshot

- Harness: five stale T-366/test roots removed; live connection-monitor and
  held Codex arg0 layouts preserved. The arg0 inventory was 90 roots: 29 held
  expected layouts, one fresh idle expected layout, 60 fresh empty roots, zero
  unexpected layouts, and zero candidates older than the grace threshold.
- Students: 66 generated cache roots, nine worktrees, nine administration
  records, and nine merged local branches removed; verified mode-0600 bundle
  retained nine exact tips.
- Swallow: 121 stale scratch/worktree roots and 14 stale administration records
  removed; six merged/superseded local branches removed. Verified mode-0600
  Git and untracked-evidence archives preserve unique state. Draft PR #134 was
  closed as superseded and its local worktree/branch retired separately.
- Website: one stale public staging root removed; no local historical branch or
  extra worktree existed. Before final generated-residue cleanup, 92 MB of
  ignored benchmark artifacts and 43 old handoff/rollback files were preserved
  in verified mode-0600 archive
  `website-t369-ignored-evidence-20260801.tar.gz` (74,447,211 bytes, SHA-256
  `f05aeb45e22a3bda84fd8f53bf6b7d88a894e494de594b0fea529080c5569a82`);
  guarded deletion then removed those sources, dependency installs, bytecode,
  and the checkout-only Playwright symlink without touching its external
  cache target.
- Personal: eleven exact merged-PR local branches removed after a verified
  mode-0600 bundle; no historical worktree or project-named scratch root
  existed.

Final validation residue was independently classified. Guarded manifests
removed generated caches from the isolated Students, Swallow, and Website
worktrees and a 117,021,029-byte pytest scratch tree after owner, process, and
open-file checks. Live primary Students environments remain preserved because
active processes use them.

Remote branch deletion is deliberately excluded: current Harness policy makes
remote branches report-only. Active, unpublished, open-PR, sensitive, and
event-gated state is preserved even when deletion would reduce counts.

The first report-only remote inventory contained 4 Harness branches, 4
Students branches, 98 Swallow branches, and only `main` in Website and
Personal. After the protected T-369/T-370/T-372 publications, Harness has 7:
`main` plus six exact merged-PR task branches. Students still has one open
branch, Dependabot PR #560; the other repositories have no open PR. Swallow
therefore retains 97 non-`main` remote branches as visible cleanup debt, but
policy intentionally provides no remote delete path. More importantly, its
live local SW034 tip is `ec809eaf...` while the same-named remote ref is only
`81ecc2ba...`; GitHub is not a complete backup of that active result. All six
Harness task branches remain report-only. These counts are not interpreted as
a reason to bypass the protected cleanup contract.

## First publication checkpoint

- Students PR #562 merged exact head `e34d8b640a8ea1d7c724972edeb386c0cd1f40e4`
  as protected squash `f6c5f0938d7c8b91b841ba2cf8f24b5efe343588`.
- Swallow PR #142 merged exact head `aa1bcd289dac4c35efdb0f0e3c69e427cbc19a5a`
  as protected squash `042ab01f0eb51a57cacaab3109dcb0cc06725b14`.
- Personal PR #17 merged exact head `878d61dd77da0147f2d966f25e42b8c4c583b539`
  as protected squash `42ff730aa6f0cc4bdd107ae8b1c23eef8cc1f6ce`;
  canonical-root validation passed before publication and again after its
  final documentation amendment.

Each merged task worktree was clean, inactive, nested-repository-free, and the
exact head of its merged pull request. Guarded manifests removed the three
worktree directories and Git administration records; expected-old ref
transactions removed their local branches. Students and Swallow primary
checkouts remain on their active unpublished branches, while Personal primary
is clean and fast-forwarded to protected `main`. Hosted owner-authored checks
were skipped where repository sustainability policy prescribes local
self-attestation; no required approval setting changed.

## Second publication checkpoint

- Harness PR #551 merged exact head
  `3bce54f26a909f5d9c9b4d53159553d0e9f607c6` as
  `85d59a1d99ea8f19b1489b23651dc87d2fe578f9`. T-370 now enforces clean,
  current-main task creation and exact merged-head guarded teardown across an
  explicitly selected repository. Clean local phase one and the protected
  portable phase-one check passed.
- Personal PR #18 merged exact head
  `5fb25767d4701c09b311fa794451d9c22e388e80` as
  `67b7053bf50de0455022da74347ff88410e8eab9`. Its canonical validator passed
  22 synthetic tests and recorded a value-free lifecycle inventory.
- Personal PR #19 merged exact head
  `e245ea77d09294097bb593282b991b9348881c49` as
  `aec19c622ffb158d2d18ebb5475d06e3667d8784`. Its canonical validator passed
  24 synthetic tests and proved exact-subset partial consent plus no-persist
  rejection of an unrequested scope.
- Harness PR #553 merged exact head
  `65a677b7ec1b94d31e0e5b69918827f81eba2ce6` as
  `4996e198366992a79568237368f925388f3f1306`. T-372 converts interrupted
  directory/admin checkpoints into an explicit later-invocation recovery,
  binds recovery to the original plan digest and exact archive item, and
  leaves unstarted bulk candidates for a fresh plan. Local and protected R3
  phase one passed; its real completed closeout produced an idempotent recovery
  no-op.

The new T-370 lifecycle opened both Personal tasks from independently verified
clean `main`, then archived and guarded-retired each exact merged worktree and
local branch. `git bundle verify` passed for the P-005, P-006, and T-370
archives. Personal is again a single clean `main`
worktree. T-371 records, but does not execute, the corresponding migration for
the live legacy Students and Swallow primary task branches.

Website's still-local worker candidate is `e0a8aa1`. Its complete offline suite
passed again after T-213 was anchored to W3C WCAG-EM 2.0 and WAI sustaining
guidance. Worker policy still forbids push or `tools/state/session.md`; the
clean worktree remains the exact handoff for a Website driver. Because that
commit is intentionally absent from GitHub, transaction
`website-t369-worker-handoff-20260802` also preserves its exact full history in
a current-user mode-0600 bundle (80,842,296 bytes, SHA-256
`229b0bb9a5ad6c660667982154be0083c3a4c858d4b900d2d3f9b1e433f8ff1e`);
the native archive audit passed with one live exact ref.

GitHub was also not a complete backup for either live legacy managed branch.
Without reading project payloads or changing a checkout, two additional
mode-0600 native bundles now preserve their exact tips: Students
`2f8771894...` in `students-t369-active-handoff-20260802` (3,279,773 bytes,
SHA-256 `1d3968e6aef5f9f5de66dbcf39d85e8c9679b0e17d0bbff235bdb869e396d88d`)
and Swallow `ec809eaf...` in `swallow-t369-active-handoff-20260802`
(1,716,887 bytes, SHA-256
`98d8a54df4baa7ff73a3708d16b05a3e78b6898647185078559afc9a577636a5`).
Both native audits passed with one exact live ref. The bundles do not include
ignored environments or Swallow's untracked local Claude setting; those remain
preserved in place and were not inspected or copied.

A fresh live readback of all five protected-main rulesets found enforcement
active, required approvals exactly zero, and one owner/admin bypass in each:
Harness `19127355`, Students `19716717`, Swallow `19734040`, Website
`19127356`, and Personal `20104679`. No hardening or cleanup action changed a
ruleset, and no stale document was allowed to restore the former one-review
policy.

Live workflow readback identified one remaining autonomy cost. Harness is
public, but 47 owner-authored pull-request jobs ran during 2026-08-01/02 even
though their exact trees were already validated locally. Public minutes do not
consume the private allowance, but the queue and required-check wait still
slow every owner task. Harness now applies the proven Students/Swallow
owner/owner job skip while retaining hosted isolation for non-owner or
mixed-sender events and unconditional weekly/manual full gates. Website is
public and PR-only. Private Students and Swallow retain one unconditional
weekly/manual backstop and have no push trigger; Students' separate trusted-base
boundary job runs only for non-owner pull requests. Personal has no workflow.
GitHub's system-managed Dependabot entries remain visible, but no project added
a nightly or bookkeeping schedule, a persistent self-hosted runner, or a
duplicate post-merge run. Organization billing totals remain unknown because
the available read-only GitHub identity lacks `admin:org`; no scope expansion
was requested or needed for the repository-local correction.

The post-change sample contains 48 owner PR workflow events: the 47 earlier
allocated jobs plus PR #555's zero-runtime skipped proof. Their aggregate event
wall time is 4,652 seconds, with a 131-second median and 142-second p90. This is
not billable private usage, but it quantifies the normal protected-merge wait
removed from owner tasks while leaving non-owner isolation unchanged.

## Recovery and retained-branch drills

The three unpublished handoff bundles were restored into independent bare
repositories rather than merely verified structurally. Each restored tip
matched its recorded source exactly: Students `2f8771894...`, Swallow
`ec809eaf...`, and Website `e0a8aa1a...`. `git fsck --full --no-dangling`
passed in all three restores. The 86,594,716-byte drill boundary was then
removed through an immutable guarded transaction; the post-delete identity
check found no recovery residue and all protected anchors were unchanged.

A fresh mirror classified every retained remote branch without deleting one.
Harness has one branch already ancestral to `main` and five squash-merged task
tips that appear divergent by graph ancestry. Students has three divergent
refs, including the open Dependabot update and two T-035 histories. Swallow has
23 refs ancestral to `main` and 74 graph-divergent refs; Website and Personal
have none outside `main`. The largest unique Swallow histories are
SW-033 (179 commits), SW-030 (138), SW-038 (42), SW-031 host generation (31),
and the remote SW-034 continuation (24). These counts explain why blind
ancestry-based deletion would be unsafe after protected squash merges and why
remote refs remain report-only. The independently bundled live SW-034 tip is
still newer than its same-named remote ref.

The same two-day Actions sample contained eight failed Harness PR runs. All
were owner-authored intermediate heads, not failures on the protected merge
trees. Four included a stale exact-number context benchmark, two included an
in-progress task-ledger contract, and the remaining focused failures were
subsequently corrected managed-session/startup changes. The context benchmark
was the repeated avoidable repair cost: its threshold checks remain mandatory,
but a new deterministic `--check`/`--write` helper now prints the exact stale
diff and refreshes only generated values. This replaces a large assertion
payload and manual arithmetic without weakening scenario, resource, board, or
reduction gates.

Live repository-isolation checks found seven distinct worktree paths across
the five repositories, with no duplicate, parent/child, or cross-owner path
collision. Every Git common directory and object database is repository-local;
all five report no object alternates, no lock file, and an empty worktree-prune
dry run. Harness has only canonical `main` plus the active T-369 worktree;
Website has canonical `main` plus its preserved worker handoff; the other
three have one primary worktree each. Tmux metadata, read without pane or
transcript content, keeps Harness/Personal work rooted in Harness and Students
work rooted in Students for both clients. The legacy Students and Swallow
primary branches are intentionally ahead of and behind protected `main`; their
exact tips are bundled, and T-371 remains the sole idle-boundary migration
path. This is preserved isolation debt, not evidence that either live checkout
should be switched in place.

One live closeout exposed a parallelism defect before mutation: the broad
worktree planner correctly classified the merged old continuation, but also
classified the newly opened, still-clean next continuation because both tips
were ancestors of protected `main`. The plan was not applied. After the new
task tree received its first ledger commit, a fresh plan retired only the old
tree. The durable fix adds `--path EXACT_TASK_TREE` to worktree planning,
records that canonical selection in the immutable receipt, reapplies it during
mutable-state verification, and marks every other otherwise eligible tree
`not-selected`. A focused fixture proves one selected clean tree is archived
and removed while a second parallel clean tree survives. Broad housekeeping
discovery remains available when no path is supplied.

Students' sole open PR, Dependabot #560, is behind current `main` and failed
for one understood safety reason: all 695 other tests and 34 subtests passed,
but changing the Codex package manifests invalidated the exact digest embedded
in the staged non-activating installer. The guard worked as designed. T-371
now records the post-migration repair: update package bytes and installer
digest together from fresh `main`, pass locally, then replace or supersede the
stale PR without spending another hosted run on a known mismatch.

A metadata-only `/tmp` rescan caught 20 owner-created files that the
directory-oriented routine did not select: completed Mac formula-policy and
Harness checksum/manifests plus SW-021, SW-031, and SW-032 job, result, patch,
prompt, and board snapshots. No file was open, every file was a current-user
single-link regular file, and the associated tasks were complete, canceled, or
superseded. Their exact bytes remain in mode-0600
`t369-residual-files-20260802.tar.gz` (194,981 bytes, SHA-256
`79038742efaeb1d664d924a8806e7acf2da6e078d8a1489955492f1cb22a2e78`);
gzip and 21-entry archive traversal checks passed. One guarded manifest then
removed only the explicit staging directory (21 entries / 773,385 bytes),
with protected anchors unchanged. The remaining project-named `/tmp` roots are
the live connection monitor, this T-369 worktree, Website's clean worker
handoff, and three `ishida`-owned research directories; all remain untouched.
`git fsck --full --no-dangling` passed independently in all five repositories,
all five worktree databases report zero stale administration entries, and all
17 native archive receipts pass a fresh audit against their owning repository.
`git count-objects` found one 23,449-byte Students `tmp_obj` from an interrupted
Git object write; it was a current-user, single-link, 17-hour-old regular file
with no open descriptor and was not a valid object. Exact non-recursive unlink
removed only that file, after which Students `git fsck` passed and object-store
garbage returned to zero. The 224 loose objects already represented in packs
remain for ordinary Git maintenance at T-371's idle boundary rather than
contending with the live managed session for negligible storage benefit.

The project-name sweep was not sufficient: a complete current-user top-level
`/tmp` inventory found 613 entries. The metadata-only classification is frozen
in `docs/audits/t369-tmp-inventory.tsv` with exact type, owner, mode, link,
device, inode, size, and mtime identities. It retained 14 managed runtime or
active-handoff roots and selected 599 unchanged, unopened candidates: 352
completed Swallow/Harness research and test artifacts, 141 old zero-byte tool
locks, and 106 stale browser/profile, dead-socket, or opaque temporary entries.
The 352
potentially useful artifacts were moved without reading into a private archive
`t369-expanded-tmp-artifacts-20260802.tar.gz` (45,312,876 bytes, SHA-256
`1961d548f5040ef267da4063a496178dfc667c0cdc650143ba5c7364d58c42ae`);
gzip validation passed. Browser/profile and opaque bytes were intentionally not
copied because extending their lifetime had no recovery value and could retain
sensitive state. One immutable guarded transaction then removed the two exact
staging roots: 5,963 recursive entries and 501,328,891 bytes, with protected
anchors unchanged. A listener-only socket readback then distinguished three
live SSH-agent directories from two July 22 directories whose socket paths had
no listener or open descriptor; a second guarded transaction removed only the
two dead directories. Post-audit found exactly 14 current-user top-level
entries, all declared runtime/handoff state, plus the same three out-of-scope
`ishida`-owned research directories.

A final boundary sweep covered `/var/tmp` and `/dev/shm`. The only
current-user `/var/tmp` entry was T-303's completed 24-hour NFS observation:
16 entries / 166,906,198 bytes, unopened but still referenced by its audit.
Without reading payloads, its exact directory was preserved as private
mode-0600 `t303-nfs-monitor-20260724.tar.gz` (11,722,016 bytes, SHA-256
`b5b23debd22cd2be50fcf16b46950f87e9f275abaa6187fa6d6eea60ca532302`),
gzip-validated, guarded-retired, and given a durable archive pointer in the
T-303 audit. Five July OpenMPI shared-memory segments in `/dev/shm` were
current-user, single-link, unopened, and had no matching MPI process; one
guarded transaction removed the exact five files and released 83,886,080
bytes without archiving ephemeral process memory.

An open-unlinked-file audit exposed a separate Harness lifecycle defect that a
directory inventory cannot see: 18 orphaned synthetic `codex-resilient` test
launchers, parented by PID 1 and running for 8–25 hours from already-deleted
fixture roots. Their command identity was the exact fake
`session-watcher-exit` client, not a managed Codex session. Each exact PID was
revalidated and terminated with `SIGTERM`; all 18 and their transient sleep
children exited, leaving zero deleted-fixture descriptors. The product cause
was a background shell-function wrapper around the remote client: watcher
failure could signal the wrapper rather than the actual client. The
remote-explicit branch now `exec`s the launcher so the recorded PID is the
client, and the focused test records that PID and fails if it survives. Two
consecutive focused suites passed with zero residual fixture processes. The
first dirty-tree R3 run passed the changed lifecycle suite and every other
executable gate except two suites whose explicit contract requires a clean
committed checkout; their clean-tree rerun is required before publication.
