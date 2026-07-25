---
name: fleet-repository-hardening
description: Audit and harden multiple repositories and their Linux/macOS execution fleet through independent ledgers, isolated worktrees, a frozen owner interview, repository-local LIFO issue stacks, small protected changes, live-settings readback, and deadline-based handoff. Use for nightly or multi-hour security, reliability, dependency, CI, backup, SSH, agent-tooling, or repository-governance reviews spanning two or more repositories or nodes.
---

# Fleet and Repository Hardening

Apply this workflow when hardening must improve several independently owned
repositories or hosts without turning them into one coupled change. Preserve
each repository's instructions, task board, validation, branch, and publication
route.

## Compose the required workflows

Read and apply these installed skills when their trigger is present:

- `plan-interview-execute` for the initial audit, owner decisions, frozen plan,
  and explicit execution gate;
- `long-running-task-ledger` for every multi-session or deadline-bound stream;
- `evidence-first-research` for current advisories, platform entitlements,
  vendor guidance, and security claims;
- `operate-native-hpc` before scheduler or allocation work; and
- `guarded-bulk-delete` before any recursive or multi-path deletion.

Never make a sibling repository depend at runtime on this skill or the harness.
Skills govern the working method; each project remains operationally
self-contained.

## Reconstruct before planning

1. Read the closest `AGENTS.md`, `CLAUDE.md`, task ledger, and declared session
   state in every repository.
2. Fetch each collaborative remote. Record branch, revision, upstream,
   worktree state, active pull requests, and pre-existing work.
3. Inventory the in-scope hosts read-only: reachability, OS, storage pressure,
   backup status, agent versions, security controls, and managed-service state.
   Use a native status interface rather than inferring health from one process.
4. Read live repository controls separately from Git transport: Actions token
   defaults, rulesets, required checks, dependency alerts, update automation,
   secret protection entitlement, environments, and open alerts.
5. Distinguish confirmed risks, expected policy differences, stale warnings,
   and hypotheses. Do not turn absence or a failed query into a finding.

Use `python3`, not an assumed unversioned `python`. For uv environments use
`uv pip check --python PATH`; do not assume the environment contains pip.
Keep local-versus-remote shell expansion explicit in SSH commands.

## Establish independent ownership

Create one umbrella plan in the coordinating repository and one task in every
affected repository's own TODO. Use an isolated worktree and task branch for
each stream. Never stash pre-existing owner or agent work.

The umbrella plan must freeze:

- exact repositories and hosts;
- risk-ranked findings and non-goals;
- repository and system authority boundaries;
- protected-main, dependency/security, network, backup, package, and
  administrator preferences when relevant;
- per-repository acceptance gates;
- rollback and publication routes;
- the issue-stack protocol; and
- the deadline, material-work cutoff, final-validation window, and handoff.

Ask one material owner question at a time when requested. Record each answer
before asking the next. Do not mutate target state until all decisions are
frozen and the owner gives explicit `go`.

## Process issues as repository-local LIFO stacks

On the slightest new ambiguity or failed gate:

1. Pause only the interrupted change and preserve safe evidence.
2. Classify retry safety and whether a coherent validated partial commit exists.
3. If not, stash only explicitly named task-owned paths. Never use a broad
   stash and never include pre-existing work.
4. Push the issue to the top of that repository's active TODO with the exact
   failure, stash or commit identifier, unchanged external state, and next
   command.
5. Treat the new issue as that repository's next task. Resolve it immediately
   when safe, record the resolution, remove only superseded task-owned stash
   state after validation, and pop back to the interrupted task.
6. If the newest item needs owner input, administrator authority, or another
   unavailable external condition, mark it deferred in place and continue the
   next highest safe item in that same repository. Do not skip an item whose
   correctness depends on the gate.
7. Keep every other repository progressing independently.

A gate is not a terminal stop. It becomes the newest work item. If it needs
owner input or unavailable administrator authority, leave its exact helper or
decision at the top, continue safe independent work below it in the same
repository, and continue every other repository. Never interpret one blocked
item as a reason to idle its whole repository.

## Execute in small protected increments

Prioritize credential exposure, vulnerable runtime dependencies, privileged
workflow injection, absent required CI, and uncontrolled default branches
before efficiency or package freshness.

- Add a focused regression before or with each behavior change.
- Keep Actions permissions read-only by default and never let workflows approve
  pull requests unless explicitly required.
- Move untrusted event values through environment variables rather than
  interpolating them into shell source.
- Pin third-party Actions by immutable commit.
- Enable native dependency and secret protection only where the hosting plan
  supports it. For unavailable private-repository secret protection, use a
  credential-free, pinned, reviewed local/CI fallback; do not claim equivalence
  to provider-wide scanning.
- Never auto-merge dependency updates.
- Require a passing, exact CI context before adding it to branch protection.
- Preserve stronger repository-specific review rules.
- Apply host changes transactionally and validate one host or route at a time.
- Use only existing narrow non-interactive administrator authority. Stage an
  exact reviewed helper with impact, rollback, and validation for password,
  root, reboot, TCC, or physical gates.

Fetch immediately before publication. Push with an explicit refspec:

```bash
git push origin HEAD:refs/heads/TASK_BRANCH
```

Do not use plain `git push`; a global `push.default=matching` can publish other
local branches. Never force-push.

## Validate and close

For each repository:

1. Run focused tests, the declared full suite, dependency/lock checks, secret
   checks, and `git diff --check`.
2. Push a small commit series and open the repository-owned pull request.
3. Require exact current-head checks; read back live rules/settings after any
   hosting change.
4. Merge only through the selected protected workflow and verify alerts or
   settings that should change after merge.
5. Record commits, pull requests, immutable rule identifiers, checks, external
   state, residue, and remaining stack items in that repository's ledger.

For the fleet, independently recheck logical nodes, redundant routes, managed
service ownership, backups, and changed configuration. Do not report an
unverified route pair as healthy.

Stop starting material changes at the frozen cutoff. Use the remaining window
for full regression, live-settings readback, fleet health, residue, clean-tree,
branch/worktree, and ledger checks. At the deadline, leave the next executable
action and authority requirement in every unfinished repository.

Read [references/audit-checklist.md](references/audit-checklist.md) for the
minimum discovery and final-readback matrix.
