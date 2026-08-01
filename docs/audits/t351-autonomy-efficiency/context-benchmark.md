# T-351 mandatory-context benchmark

The baseline is immutable Harness commit
`f2ce89ac3ea393cb5a7b882bed1b79fe773974fb`. Baseline counts were reproduced
with `git show COMMIT:PATH | wc -w`; current counts are the sum of the exact
resources selected in `context-scenarios.tsv`. “Non-ledger” excludes only
`TODO.md`; the selected task record remains in the non-ledger count, so policy
and skill savings cannot be hidden by board compaction or task routing.

The scenario routes deliberately include every phase-specific resource needed
to complete the named task. Duration work selects its policy and durable
ledger without requiring another client; native HPC uses the common rules and
one exact current-node site reference; and fleet hardening retains its
required PIE, ledger, research, and audit resources. A documentation edit
conservatively includes the Git/external module needed for its eventual
protected publication.

| Scenario | Before total | After total | Total reduction | Before non-ledger | After non-ledger | Non-ledger reduction |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| factual lookup | 73,734 | 1,871 | 97.4% | 2,906 | 1,483 | 48.9% |
| documentation edit | 73,545 | 2,183 | 97.0% | 2,717 | 1,795 | 33.9% |
| ordinary code fix | 74,455 | 1,909 | 97.4% | 3,627 | 1,521 | 58.0% |
| tmux health diagnosis | 73,545 | 1,870 | 97.4% | 2,717 | 1,482 | 45.4% |
| unsafe-tail recovery | 75,931 | 3,229 | 95.7% | 5,103 | 2,841 | 44.3% |
| fleet hardening | 76,238 | 4,729 | 93.7% | 5,410 | 4,341 | 19.7% |
| native HPC experiment | 77,550 | 3,495 | 95.4% | 6,722 | 3,107 | 53.7% |
| duration ledger | 80,599 | 2,190 | 97.2% | 9,771 | 1,802 | 81.5% |

The median total reduction is 97.1%, above the frozen 85% threshold; every
scenario remains far above the per-scenario 50% floor. Median non-ledger
reduction is 47.1%, above the 30% independent policy/skill threshold. The
always-read policy is 806 words, and the active board is 69 lines / 358 words,
and selected conditional policy routes are separately budgeted by
`tests/test-agent-policy-routing.sh`.

The frozen benchmark deliberately retains the completed T-351 record as its
representative task payload. That record is 426 words and the active board is
77 lines / 388 words, so board plus representative payload is 814 words—29.4%
below the prior 1,153-word board. A current cold start reads the
board and only a selected active record; it does not load completed T-351 or
unrelated backup successor IDs, outage contingency details, and the blocked
NFS fingerprint. The ledger fixture requires all compact task records,
their active/completed routing, and their exact critical facts before allowing
this compaction.

`tests/test-context-routing-benchmark.sh` recalculates every current count,
checks that selected inputs are regular tracked files, enforces all frozen
thresholds, and fails if the active board or policy router regresses. When a
deliberate routed-context edit changes generated values,
`tools/refresh-context-benchmark.py --write` updates them deterministically;
`--check` prints the exact stale diff instead of a Python assertion payload.

Phase routing reduced the largest selected routes as follows: HPC
2,668→1,116 words (58.1%), PIE 1,088→615 (43.5%), remote communication
1,241→795 (35.9%), fleet hardening 1,431→877 (38.7%, including LIFO handling
and explicit interrupted-closeout recovery in the largest selected phase),
and personal-Mac onboarding 1,527→953 (37.6%, including component
acceptance and orphan revalidation). Unsafe-tail recovery now selects 409 words
for diagnosis, 699 for safe rollback, or 1,157 for bridge replacement instead
of 455 for diagnosis or 1,221 for either transaction. The fleet scenario above
conservatively counts every phase and both host types, not just its largest
instantaneous route.

Within the already site-routed HPC workflow, a second routing layer reduced
the former 1,397-word largest route to 1,116 words (20.0%). The mandatory
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

The 17 always-visible skill descriptions fell from 819 to 375 words (54.2%).
Each remains a precise trigger index; `tests/test-skill-catalog-budget.sh`
enforces a 400-word ceiling plus skill-specific trigger markers. The root policy
therefore no longer duplicates a partial trigger table.
`tests/test-skill-context-budgets.sh` freezes selected routes, while
`tests/test-skill-context-gates.sh` proves that common authority rules and
phase-specific stop conditions remain reachable.
