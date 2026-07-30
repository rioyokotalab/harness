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
| factual lookup | 73,734 | 1,588 | 97.8% | 2,906 | 1,342 | 53.8% |
| documentation edit | 73,545 | 1,799 | 97.5% | 2,717 | 1,553 | 42.8% |
| ordinary code fix | 74,455 | 1,799 | 97.5% | 3,627 | 1,553 | 57.2% |
| tmux health diagnosis | 73,545 | 1,805 | 97.5% | 2,717 | 1,559 | 42.6% |
| unsafe-tail recovery | 75,931 | 3,281 | 95.7% | 5,103 | 3,035 | 40.5% |
| fleet hardening | 76,238 | 4,114 | 94.6% | 5,410 | 3,868 | 28.5% |
| native HPC experiment | 77,550 | 3,737 | 95.2% | 6,722 | 3,491 | 48.1% |
| duration Cowork | 80,599 | 4,993 | 93.8% | 9,771 | 4,747 | 51.4% |

The median total reduction is 96.5%, above the frozen 85% threshold; every
scenario exceeds 93%, above the per-scenario 50% floor. Median non-ledger
reduction is 45.5%, above the 30% independent policy/skill threshold. The
always-read policy is 1,082 words, and the active board is 52 lines / 246 words,
and selected conditional policy routes are separately budgeted by
`tests/test-agent-policy-routing.sh`.

Active-task details are now one hop behind the board. The selected T-351 record
is 328 words, so board plus relevant record is 574 words—50.2% below the prior
1,153-word board—while unrelated backup successor IDs, outage contingency
details, and the blocked NFS fingerprint are not loaded. The ledger fixture
requires all four task records, their board routes, and their exact critical
facts before allowing this compaction.

`tests/test-context-routing-benchmark.sh` recalculates every current count,
checks that selected inputs are regular tracked files, enforces all frozen
thresholds, and fails if the active board or policy router regresses.

Phase routing also reduced the largest selected PIE route from 1,088 to 652
words (40.1%) and the largest remote-communication route from 1,241 to 771
words (37.9%). The PIE entry selects exactly one of planning, interview, or
execution; remote communication selects exactly one of delivery, synchronous
request, or fallback. `tests/test-skill-context-budgets.sh` freezes these
budgets, while `tests/test-skill-context-gates.sh` proves that the common
authority rules and phase-specific stop conditions remain reachable.
