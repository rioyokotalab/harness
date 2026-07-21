# Driver execution

## Steps and results

The frozen plan required no production code or runbook change. I corrected the
driver-evidence timing paragraph with common-clock start offsets and explicit
native-exit-before-import ordering. In the existing stale-candidate waiter test,
I replaced fixed PID `2147483647` with a real `sleep 0.5` child, passed that PID
to `wait-copilot`, and reaped it afterward. Existing assertions still require
exit 2, `not-importable`, observed process loss, false full preconditions, and
no authorization. This exercises a live reachable-to-not-reachable transition
without adding a parallel duplicate case.

`bash tests/test-codex-claude-cowork-skill.sh` passed in 16.62 seconds. The
executing session and reciprocal receipt validate, and `git diff --check`
passes.

## Deviations

None. The edit exactly follows the frozen reconciliation. The focused suite is
about 0.9 seconds slower than the prior synthetic process-loss version, the
expected cost of waiting for a real transition.
