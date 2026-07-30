# Repository and hosting audit

Record each applicable row as `pass`, `finding`, `expected`, `unavailable`, or
`unknown`; classify a failed query as `unknown`.

- Read repository instructions and the task ledger completely.
- Record revision, upstream, worktrees, active pull requests, dirty ownership,
  and focused/full validation commands.
- Check runtime and development locks plus current advisories.
- Inspect workflow triggers, private hosted-runner allocation, token
  permissions, immutable Actions, and untrusted event-to-shell flow.
- Check tracked credential, private, and runtime paths; secret-protection
  entitlement; and any credential-free fallback.
- Read default Actions permissions, workflow approval capability, dependency
  graph, alerts, security updates, and update policy.
- Read branch rules: deletion, non-fast-forward, accepted review count,
  stronger reviewers, conversation resolution, linear history, exact strict
  checks, and bypass actors.
- Check environments, deployments, external messages, and credential
  boundaries.
- Distinguish tracked-source backup from ignored runtime artifacts.
