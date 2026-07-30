# Harness agent working agreements

These instructions apply to Codex and Claude started from this repository.
Root `CLAUDE.md` imports this file. The files under `docs/agent-policy/` are
conditional parts of this policy: read only the rows selected below, but read
every selected file completely before its first matching action.

## Always enforce

- Preserve user work and unrelated dirty-tree changes. Prefer reversible,
  narrowly scoped edits and non-destructive version-control commands.
- Never inspect, expose, copy, or modify credentials. External messages,
  deployments, publication, account or hosting writes, destructive operations,
  and broad owner configuration are separate authority boundaries. Exact owner
  authorization permits only the smallest atomic change; otherwise collect one
  approval bundle and continue all safe in-scope work.
- Ordinary Git operations inside the active task are standing-authorized,
  including fetch, branch, commit, rebase, push, task pull-request, and merge.
  They do not authorize hosting administration, workflow dispatch,
  deployments, messages, cleanup, or credential access. Never force-push or
  overwrite ambiguous remote work.
- A duration or persistence request never broadens scope.
- Never run raw recursive or multi-path deletion (`rm -r`, `rm -rf`,
  `find -delete`, deletion loops or globs, `rsync --delete`, or equivalents).
  Apply `guarded-bulk-delete`; its passing plan/apply gate is autonomous and
  needs no extra owner prompt. Exact non-recursive unlink and patch-based
  tracked-file deletion remain allowed.
- Prefix every commentary progress update with the current local time in
  `[HH:MM:SS]` format. Immediately before writing it, run a fresh native
  `date '+%H:%M:%S'` read and copy that exact value. Never infer a timestamp
  from a prior message or elapsed time.
- Lead with outcomes, make informed low-risk assumptions, and stop only for a
  choice or authority boundary that materially changes scope or external
  state. Work in small evidence-backed steps and distinguish facts from
  hypotheses.
- After a transient Codex provider or service failure, resume the saved thread
  and reconcile durable state; never blindly replay the prior prompt because
  side effects may already have succeeded.
- Validate in proportion to impact. Documentation and ledger changes get diff
  and contract checks; a mapped component gets its owning suite and invariants;
  workflow, policy, validator, manifest, selector, safety, lifecycle, cleanup,
  credential, and unknown changes get the complete suite. Independently inspect
  generated, optimized, or delegated results.

## Conditional policy router

Match the requested or next recorded action, not the general subject of the
repository. Multiple matching rows select multiple files.

| Read completely | Select before |
| --- | --- |
| [repository-and-external.md](docs/agent-policy/repository-and-external.md) | authenticated Git or SSH; commit, push, PR, merge, publication; hosting/API/account/config writes; packages/installers; repository hardening |
| [managed-runtime-and-fleet.md](docs/agent-policy/managed-runtime-and-fleet.md) | managed Codex, tmux, phone, app-server, recovery, reboot, fleet, route failure, fleet sync, or an `[Agent: NAME Codex]` message |
| [housekeeping-and-promotion.md](docs/agent-policy/housekeeping-and-promotion.md) | housekeeping, residue cleanup, launcher cleanup diagnosis, or promotion of reusable guidance |
| [research.md](docs/agent-policy/research.md) | factual or literature research, research-program work, scientific/HPC experiments, performance claims, or presentations |
| [duration.md](docs/agent-policy/duration.md) | an explicit duration, deadline, time window, overnight run, or instruction to keep iterating |

Do not preload these files for unrelated work. The routing contract is tested;
an unknown policy-sensitive action fails toward the more specific workflow or
an owner decision, never toward silently skipping a gate.

## Skill routing

At task start, compare the exact request with installed skills and select the
smallest set that covers it. Read each selected `SKILL.md` completely and only
the references its router selects for the current phase or target. Do not stack
a broad workflow merely because work is consequential or multi-step. Closer
project rules remain authoritative, and skills never become project runtime
dependencies.

Before a skill-directed action, name the skill and why it applies in
user-facing commentary. Name it again if it causes an external action or pause.

Installed skill descriptions are the trigger index; do not duplicate or broaden
them here. The always-read deletion rule and the Harness duration rule below
remain mandatory project refinements.

## Harness repository

- Treat Git and `TODO.md` as the durable source of truth. Chat history, client
  summaries, and Claude auto-memory are optional context only.
- At cold start, read this file and the active board completely, inspect the
  branch, worktree, and recent commits, and select one recorded task. Read that
  task's board-linked record, then only the plan and evidence it routes;
  never preload another active record or `docs/history/`. Before changing
  collaborative work, fetch and reconcile its current remote through the
  conditional Git policy.
- Resume the first unverified recorded action. Revalidate only mutable inputs
  used by that action; a failed query is unknown, not evidence of absence.
- Keep Harness independent of the sibling `website` repository.
- Add focused tests for changed behavior and use `harness validate` for the
  deterministic risk tier. Run the complete phase-one suite for broad or
  escalated changes and once on the final integrated tree before protected
  publication.
- At takeover, inspect branch, worktree, recent commits, ledger, and mutable
  external inputs before resuming the recorded next action. At handoff, record
  verified results, identifiers, failures and retry safety, modified files,
  validation, remaining checks, the next action, and required authority.
- Before yielding unfinished work, update the selected task record. Change
  `TODO.md` only when its phase, ordering, next-action summary, or record
  pointer changes; never expand it with task chronology. Keep bulky
  reproducible evidence in tracked artifacts and never record credentials,
  private environment values, or chat-only assumptions.
