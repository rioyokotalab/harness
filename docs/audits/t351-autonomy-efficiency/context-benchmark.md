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
| factual lookup | 73,734 | 2,329 | 96.8% | 2,906 | 1,342 | 53.8% |
| documentation edit | 73,545 | 2,540 | 96.5% | 2,717 | 1,553 | 42.8% |
| ordinary code fix | 74,455 | 2,540 | 96.6% | 3,627 | 1,553 | 57.2% |
| tmux health diagnosis | 73,545 | 2,546 | 96.5% | 2,717 | 1,559 | 42.6% |
| unsafe-tail recovery | 75,931 | 4,022 | 94.7% | 5,103 | 3,035 | 40.5% |
| fleet hardening | 76,238 | 5,888 | 92.3% | 5,410 | 4,901 | 9.4% |
| native HPC experiment | 77,550 | 4,478 | 94.2% | 6,722 | 3,491 | 48.1% |
| duration Cowork | 80,599 | 5,734 | 92.9% | 9,771 | 4,747 | 51.4% |

The median total reduction is 95.6%, above the frozen 85% threshold; every
scenario exceeds 92%, above the per-scenario 50% floor. Median non-ledger
reduction is 45.5%, above the 30% independent policy/skill threshold. The
always-read policy is 1,082 words, the active board is 157 lines / 987 words,
and selected conditional policy routes are separately budgeted by
`tests/test-agent-policy-routing.sh`.

`tests/test-context-routing-benchmark.sh` recalculates every current count,
checks that selected inputs are regular tracked files, enforces all frozen
thresholds, and fails if the active board or policy router regresses.
