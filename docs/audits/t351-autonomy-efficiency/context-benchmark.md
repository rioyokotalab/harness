# T-351 mandatory-context benchmark

The baseline is immutable Harness commit
`f2ce89ac3ea393cb5a7b882bed1b79fe773974fb`. Baseline counts were reproduced
with `git show COMMIT:PATH | wc -w`; current counts are the sum of the exact
resources selected in `context-scenarios.tsv`. “Non-ledger” excludes only
`TODO.md`, so policy and skill savings cannot be hidden by board compaction.

The scenario routes deliberately include every phase-specific resource needed
to complete the named task. For example, duration Cowork includes planning,
exchange, native-client, execution, and recovery references; native HPC uses
the common rules and one exact current-node site reference; and fleet hardening
retains its required PIE, ledger, research, and audit resources. A
documentation edit conservatively includes the Git/external module needed for
its eventual protected publication.

| Scenario | Before total | After total | Total reduction | Before non-ledger | After non-ledger | Non-ledger reduction |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| factual lookup | 73,734 | 1,385 | 98.1% | 2,906 | 1,139 | 60.8% |
| documentation edit | 73,545 | 1,409 | 98.0% | 2,717 | 1,163 | 57.1% |
| ordinary code fix | 74,455 | 1,409 | 98.1% | 3,627 | 1,163 | 67.9% |
| tmux health diagnosis | 73,545 | 1,357 | 98.1% | 2,717 | 1,111 | 59.1% |
| unsafe-tail recovery | 75,931 | 2,707 | 96.4% | 5,103 | 2,461 | 51.7% |
| fleet hardening | 76,238 | 4,074 | 94.6% | 5,410 | 3,828 | 29.2% |
| native HPC experiment | 77,550 | 2,996 | 96.1% | 6,722 | 2,750 | 59.0% |
| duration Cowork | 80,599 | 4,625 | 94.2% | 9,771 | 4,379 | 55.1% |

The median total reduction is 97.2%, above the frozen 85% threshold; every
scenario exceeds 94%, above the per-scenario 50% floor. Median non-ledger
reduction is 58.0%, above the 30% independent policy/skill threshold. The
always-read policy is 888 words, and the active board is 52 lines / 246 words,
and selected conditional policy routes are separately budgeted by
`tests/test-agent-policy-routing.sh`.

Active-task details are now one hop behind the board. At this checkpoint the
selected T-351 record is 408 words during execution, so board plus relevant
record is 654 words—43.3% below the prior 1,153-word board—while unrelated
backup successor IDs, outage contingency
details, and the blocked NFS fingerprint are not loaded. The ledger fixture
requires all four task records, their board routes, and their exact critical
facts before allowing this compaction.

`tests/test-context-routing-benchmark.sh` recalculates every current count,
checks that selected inputs are regular tracked files, enforces all frozen
thresholds, and fails if the active board or policy router regresses.

Phase routing reduced the largest selected routes as follows: Cowork
5,926→1,231 words (79.2%), HPC 2,668→1,117 (58.1%), PIE 1,088→615
(43.5%), remote communication 1,241→737 (40.6%), fleet hardening
1,431→864 (39.6%, including LIFO handling added to the largest interrupted
phase), and personal-Mac onboarding 1,527→953 (37.6%, including component
acceptance and orphan revalidation). Unsafe-tail recovery now selects 409 words
for diagnosis, 721 for safe rollback, or 1,148 for bridge replacement instead
of 455 for diagnosis or 1,221 for either transaction. The fleet scenario above
conservatively counts every phase and both host types, not just its largest
instantaneous route.

Within the already site-routed HPC workflow, a second routing layer reduced
the former 1,397-word largest route to 1,117 words (20.0%). The mandatory
entry still loads `common.md`, exactly one site, and exactly one current
planning, execution, or validation phase.

Three additional onboarding/recovery workflows now route by phase:
external-user onboarding selects at most 391 instead of 664 words (41.1%),
mirrored-node onboarding 630 instead of 1,157 (45.5%), and reboot recovery 408
instead of 599 (31.9%). Their mandatory entries retain authority, credential,
collision, cleanup, and unknown-state stops before references load.

Conditional policy is now split by exact Git, external-operation,
managed-Codex, and fleet actions. The corresponding root-plus-module routes
are 1,163, 1,162, 1,111, and 1,219 words. An ordinary Git action no longer
loads installer/global-configuration policy, and tmux recovery no longer loads
fleet maintenance and rollout policy.

The 17 always-visible skill descriptions fell from 819 to 375 words (54.2%).
Each remains a precise trigger index; `tests/test-skill-catalog-budget.sh`
enforces a 400-word total plus skill-specific trigger markers. The root policy
therefore no longer duplicates a partial trigger table.
`tests/test-skill-context-budgets.sh` freezes selected routes, while
`tests/test-skill-context-gates.sh` proves that common authority rules and
phase-specific stop conditions remain reachable.
