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
| factual lookup | 73,734 | 1,360 | 98.1% | 2,906 | 1,114 | 61.6% |
| documentation edit | 73,545 | 1,619 | 97.7% | 2,717 | 1,373 | 49.4% |
| ordinary code fix | 74,455 | 1,619 | 97.8% | 3,627 | 1,373 | 62.1% |
| tmux health diagnosis | 73,545 | 1,650 | 97.7% | 2,717 | 1,404 | 48.3% |
| unsafe-tail recovery | 75,931 | 3,000 | 96.0% | 5,103 | 2,754 | 46.0% |
| fleet hardening | 76,238 | 4,220 | 94.4% | 5,410 | 3,974 | 26.5% |
| native HPC experiment | 77,550 | 3,486 | 95.5% | 6,722 | 3,240 | 51.8% |
| duration Cowork | 80,599 | 4,835 | 94.0% | 9,771 | 4,589 | 53.0% |

The median total reduction is 96.8%, above the frozen 85% threshold; every
scenario exceeds 93%, above the per-scenario 50% floor. Median non-ledger
reduction is 50.6%, above the 30% independent policy/skill threshold. The
always-read policy is 863 words, and the active board is 52 lines / 246 words,
and selected conditional policy routes are separately budgeted by
`tests/test-agent-policy-routing.sh`.

Active-task details are now one hop behind the board. At this checkpoint the
selected T-351 record is 614 words during execution, so board plus relevant
record is 860 words—25.4% below the prior 1,153-word board—while unrelated
backup successor IDs, outage contingency
details, and the blocked NFS fingerprint are not loaded. The ledger fixture
requires all four task records, their board routes, and their exact critical
facts before allowing this compaction.

`tests/test-context-routing-benchmark.sh` recalculates every current count,
checks that selected inputs are regular tracked files, enforces all frozen
thresholds, and fails if the active board or policy router regresses.

Phase routing reduced the largest selected routes as follows: Cowork
5,926→1,231 words (79.2%), HPC 2,668→1,397 (47.6%), PIE 1,088→615
(43.5%), remote communication 1,241→737 (40.6%), fleet hardening
1,431→864 (39.6%, including LIFO handling added to the largest interrupted
phase), and personal-Mac onboarding 1,527→953 (37.6%, including component
acceptance and orphan revalidation). Unsafe-tail recovery now selects 409 words
for diagnosis, 721 for safe rollback, or 1,148 for bridge replacement instead
of 455 for diagnosis or 1,221 for either transaction. The fleet scenario above
conservatively counts every phase and both host types, not just its largest
instantaneous route.

The 17 always-visible skill descriptions fell from 819 to 375 words (54.2%).
Each remains a precise trigger index; `tests/test-skill-catalog-budget.sh`
enforces a 400-word total plus skill-specific trigger markers. The root policy
therefore no longer duplicates a partial trigger table.
`tests/test-skill-context-budgets.sh` freezes selected routes, while
`tests/test-skill-context-gates.sh` proves that common authority rules and
phase-specific stop conditions remain reachable.
