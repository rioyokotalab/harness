# T-351 mandatory-context benchmark

The baseline is immutable Harness commit
`f2ce89ac3ea393cb5a7b882bed1b79fe773974fb`. Baseline counts were reproduced
with `git show COMMIT:PATH | wc -w`; current counts are the sum of the exact
resources selected in `context-scenarios.tsv`. “Non-ledger” excludes only
`TODO.md`; the selected task record remains in the non-ledger count, so policy
and skill savings cannot be hidden by board compaction or task routing.

The scenario routes deliberately include every phase-specific resource needed
to complete the named task. For example, duration Cowork includes planning,
exchange, native-client, execution, and recovery references; native HPC uses
the common rules and one exact current-node site reference; and fleet hardening
retains its required PIE, ledger, research, and audit resources. A
documentation edit conservatively includes the Git/external module needed for
its eventual protected publication.

| Scenario | Before total | After total | Total reduction | Before non-ledger | After non-ledger | Non-ledger reduction |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| factual lookup | 73,734 | 1,806 | 97.5% | 2,906 | 1,483 | 48.9% |
| documentation edit | 73,545 | 2,118 | 97.1% | 2,717 | 1,795 | 33.9% |
| ordinary code fix | 74,455 | 1,844 | 97.5% | 3,627 | 1,521 | 58.0% |
| tmux health diagnosis | 73,545 | 1,805 | 97.5% | 2,717 | 1,482 | 45.4% |
| unsafe-tail recovery | 75,931 | 3,164 | 95.8% | 5,103 | 2,841 | 44.3% |
| fleet hardening | 76,238 | 4,509 | 94.0% | 5,410 | 4,186 | 22.6% |
| native HPC experiment | 77,550 | 3,431 | 95.5% | 6,722 | 3,108 | 53.7% |
| duration Cowork | 80,599 | 4,978 | 93.8% | 9,771 | 4,655 | 52.3% |

The median total reduction is 96.4%, above the frozen 85% threshold; every
scenario exceeds 93%, above the per-scenario 50% floor. Median non-ledger
reduction is 47.1%, above the 30% independent policy/skill threshold. The
always-read policy is 806 words, and the active board is 68 lines / 323 words,
and selected conditional policy routes are separately budgeted by
`tests/test-agent-policy-routing.sh`.

The frozen benchmark deliberately retains the completed T-351 record as its
representative task payload. That record is 426 words and the active board is
68 lines / 323 words, so board plus representative payload is 749 words—35.0%
below the prior 1,153-word board. A current cold start reads the
board and only a selected active record; it does not load completed T-351 or
unrelated backup successor IDs, outage contingency details, and the blocked
NFS fingerprint. The ledger fixture requires all compact task records,
their active/completed routing, and their exact critical facts before allowing
this compaction.

`tests/test-context-routing-benchmark.sh` recalculates every current count,
checks that selected inputs are regular tracked files, enforces all frozen
thresholds, and fails if the active board or policy router regresses.

Phase routing reduced the largest selected routes as follows: Cowork
5,926→1,011 words (82.9%), HPC 2,668→1,117 (58.1%), PIE 1,088→615
(43.5%), remote communication 1,241→795 (35.9%), fleet hardening
1,431→864 (39.6%, including LIFO handling added to the largest interrupted
phase), and personal-Mac onboarding 1,527→953 (37.6%, including component
acceptance and orphan revalidation). Unsafe-tail recovery now selects 409 words
for diagnosis, 699 for safe rollback, or 1,157 for bridge replacement instead
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
are 1,095, 1,080, 1,056, and 1,137 words. An ordinary Git action no longer
loads installer/global-configuration policy, and tmux recovery no longer loads
fleet maintenance and rollout policy.

The 18 always-visible skill descriptions fell from 819 to 400 words (51.1%).
Each remains a precise trigger index; `tests/test-skill-catalog-budget.sh`
enforces a 400-word total plus skill-specific trigger markers. The root policy
therefore no longer duplicates a partial trigger table.
`tests/test-skill-context-budgets.sh` freezes selected routes, while
`tests/test-skill-context-gates.sh` proves that common authority rules and
phase-specific stop conditions remain reachable.

Cowork's mandatory entry now contains only its cross-phase authority,
isolation, import, sole-writer, ambiguity, and routing gates. Initialization,
evidence, execution, recovery, and duration mechanics stay in their selected
references; removing duplicated flow prose and compacting those gates reduced
the initial route from 1,231 to 1,011 words.

Evidence reasoning and sealed exchange now route independently. Review or
reconciliation selects 881 words, while stage/status/import selects 1,136
instead of the former 1,327-word combined route. A native evidence pass selects
both references and remains complete at 1,795 words; the split removes no
transaction or evidence requirement.
