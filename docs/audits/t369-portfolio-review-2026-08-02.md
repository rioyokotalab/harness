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
| Actions sustainability | GitHub, [billing and usage](https://docs.github.com/en/actions/concepts/billing-and-usage), [GitHub-hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners), and [self-hosted runners](https://docs.github.com/en/actions/concepts/runners/self-hosted-runners) | Keep owner-only protected local validation and retain hosted isolation for untrusted/mixed work plus periodic/manual gates. Do not add scheduled hosted work merely for task bookkeeping. |
| Research software | FAIR4RS, [RDA recommendation](https://doi.org/10.15497/RDA00068) and [primary paper](https://www.nature.com/articles/s41597-022-01710-x) | Adopt versioned, identifiable, documented, reusable artifacts and explicit software/environment provenance. |
| Artifact evidence | ACM, [Artifact Review and Badging](https://www.acm.org/publications/policies/artifact-review-and-badging-current) | Adapt the functional-artifact criteria—documented, consistent, complete, exercisable, validated—to SW-034 before spending more compute. |
| ML benchmarking | MLCommons, [benchmark principles](https://mlcommons.org/benchmarks/) and [inference rules](https://github.com/mlcommons/inference_policies/blob/master/inference_rules.adoc) | Preserve fixed inputs/seeds, full hardware/software disclosure, matched systems, replicability, and claim limits; reject unmatched score transfer. |
| Web accessibility | W3C WAI, [evaluation overview](https://www.w3.org/WAI/test-evaluate/), [ongoing monitoring](https://www.w3.org/WAI/eval/considerations), and [sustainability](https://www.w3.org/WAI/planning-and-managing/sustain/) | Keep automated gates but add bounded human, keyboard, and assistive-technology sampling at material changes and quarterly checkpoints. |
| Sensitive automation | NIST, [Privacy Framework 1.0](https://www.nist.gov/document/nist-privacy-frameworkv10pdf) | Keep source content in authoritative services, minimize collection/retention, and design the full creation-to-disposition lifecycle. |
| OAuth capability | Google, [OAuth best practices](https://developers.google.com/identity/protocols/oauth2/resources/best-practices) and [granular permissions](https://developers.google.com/identity/protocols/oauth2/resources/granular-permissions) | Request the smallest scope in context, handle partial denial, store tokens securely outside Git, and make revocation/recovery explicit. |

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
