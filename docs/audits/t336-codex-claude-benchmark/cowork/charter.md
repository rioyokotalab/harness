# Charter

## Task

Design a reproducible, synthetic benchmark that tests whether current Claude
Code can safely and effectively perform the representative development and
operations-engineering tasks recorded in Harness history, then run the same
suite with current Codex and compare deterministic outcomes. Preserve the
frozen T-181/T-295 evaluation and publish T-336 as a separate versioned suite.

## Boundaries

- Driver: Codex. Co-pilot: Claude.
- The target is the isolated T-336 worktree only. T-335 and live fleet,
  tmux, process, scheduler, connector, hosting, and credential state are out
  of scope.
- No historical prompt is replayed. Fixtures are synthetic, credential-free,
  and contain no private fleet values.
- Co-pilot work is evidence and critique only. Claude never writes the target.
- Model runs may write only their synthetic workspaces. Their shell tools have
  no network and cannot mutate the Harness checkout.
- Raw events and workspaces remain private under `/tmp`; only closed-schema,
  value-free aggregate evidence may enter Git.

## Baseline and sandboxes

- Source baseline:
  `fcadc7ae68182036f1aa128fe3b7bea977cddc4f`.
- Task worktree: `/tmp/harness-t336-agent-benchmark`, branch
  `codex/t336-agent-benchmark`.
- Native clients observed before planning: `codex-cli 0.145.0` and
  `Claude Code 2.1.220`.
- Benchmark clients receive byte-identical initialized Git fixtures, matched
  prompts, fresh non-persistent sessions, high effort, alternating order,
  bounded time/output, and no delegation.
- Codex shell execution uses workspace-write with tool-network disabled.
  Claude receives Bash only through an audited bubblewrap wrapper with a
  read-only host, writable fixture/tmp binds, and an unshared network.
- Driver and co-pilot design evidence use separate staged sandboxes and sealed
  exchange inputs under the current staged cowork protocol.

## Acceptance

- A versioned manifest maps every decision type to representative historical
  T-IDs and states exact prompts, allowed/protected paths, deterministic
  acceptance, and safety gates.
- Model-free validation proves fixture/oracle hashes, closed schemas, client
  command construction, containment, alternating order, stage ceilings, report
  reproducibility, and refusal of unsafe/malformed evidence.
- An all-scenario pilot preserves containment/integrity before two confirmation
  repeats may start, yielding three total observations per scenario.
- Results report per-client and per-decision-type pass counts, paired outcomes,
  safety failures, duration, exact versions/settings, observed models, and
  limitations without claiming general product superiority.
- README and TODO accurately reflect the current 17-skill, 12-node control
  plane and point to the new reproducible benchmark and dated result.
- Focused tests, `tests/test-phase1.sh`, protected CI, protected merge, safe
  fleet synchronization, and required Mac context refreshes pass.
