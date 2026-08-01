# Harness agent working agreements

These instructions apply to Codex and Claude launched here; root `CLAUDE.md`
imports them. Files under `docs/agent-policy/` are conditional: read only the
rows selected below, each completely before its first matching action.

## Always enforce

- Preserve user work and unrelated dirty changes. Prefer reversible, narrow,
  non-destructive edits.
- Never inspect, expose, copy, or modify credentials. External messages,
  deployments, publication, account or hosting writes, destructive operations,
  and broad owner configuration are separate authority boundaries. Exact owner
  authorization covers only its smallest atomic change; otherwise bundle
  required approvals and continue safe in-scope work.
- A duration or persistence request never broadens scope.
- Never run raw recursive or multi-path deletion (`rm -r`, `rm -rf`,
  `find -delete`, deletion loops or globs, `rsync --delete`, or equivalents).
  Apply `guarded-bulk-delete`; a passing plan/apply gate needs no owner prompt.
  Exact non-recursive unlink and patch-based tracked deletion remain allowed.
- Prefix every commentary progress update with the current local time in
  `[HH:MM:SS]`. Immediately beforehand, run a fresh native
  `date '+%H:%M:%S'` read and copy it exactly. Never infer a timestamp.
- Lead with outcomes, make low-risk assumptions, and stop only at a choice or
  authority boundary that materially changes scope or external state. Work in
  small evidence-backed steps; distinguish facts from hypotheses.
- After a transient Codex provider or service failure, resume the saved thread
  and reconcile durable state; never blindly replay the prior prompt because
  side effects may already have succeeded.
- Validate proportionally. Documentation and ledger changes get diff and
  contract checks; a mapped component gets its owning suite and invariants;
  workflow, policy, validator, manifest, selector, safety, lifecycle, cleanup,
  credential, and unknown changes get the complete suite. Independently check
  generated, optimized, or delegated results.
- Reuse recorded validation when target bytes, environment contract, and
  acceptance scope are unchanged. Rerun only changed owning checks, mutable
  inputs, or required final integration—not merely because a session resumed.

## Conditional policy router

Match the requested or next recorded action, not the repository's general
subject. Multiple matches select multiple files.

| Read completely | Select before |
| --- | --- |
| [repository-git.md](docs/agent-policy/repository-git.md) | authenticated Git or SSH; branch, fetch, commit, push, PR, merge, publication, or repository hardening |
| [external-operations.md](docs/agent-policy/external-operations.md) | hosting/account API access or writes; owner/global configuration; packages/installers; or `~/run_this.sh` |
| [managed-codex.md](docs/agent-policy/managed-codex.md) | managed Codex or Claude, tmux, phone, app-server, saved-thread or unsafe-tail recovery, or an identified agent message |
| [fleet.md](docs/agent-policy/fleet.md) | fleet/node/route work, fleet-health or maintenance checks, fleet sync, or managed-Mac reboot or checkout rollout |
| [housekeeping-and-promotion.md](docs/agent-policy/housekeeping-and-promotion.md) | housekeeping, residue cleanup, launcher cleanup diagnosis, or promotion of reusable guidance |
| [research.md](docs/agent-policy/research.md) | factual or literature research, research-program work, scientific/HPC experiments, performance claims, or presentations |
| [duration.md](docs/agent-policy/duration.md) | an explicit duration, end time/date, time window, overnight run, or instruction to keep iterating |

Do not preload them. Unknown policy-sensitive actions fail toward the specific
workflow or an owner decision, never toward silently skipping a gate.

## Skill routing

At task start, select the smallest installed skill set covering the exact
request. Read each selected `SKILL.md` completely, then only references its
router selects for the current phase or target. Consequential or multi-step
work alone does not select a broad workflow. Closer project rules remain
authoritative; skills never become project runtime dependencies.

Before a skill-directed action, name the skill and reason in commentary. Name
it again if it causes an external action or pause.

Installed skill descriptions are the trigger index; do not duplicate or broaden
them here. The always-read deletion rule and the Harness duration rule below
remain mandatory project refinements.

## Harness repository

- Treat Git and `TODO.md` as the durable source of truth. Chat history, client
  summaries, and Claude auto-memory are optional context only.
- At cold start, read this file and the active board completely, inspect the
  branch, worktree, and recent commits, and select one task. Read the selected
  task's board-linked record, then only routed plan and evidence; never preload
  another active record or `docs/history/`. Before changing collaborative work,
  fetch and reconcile its remote through the conditional Git policy.
- Resume the first unverified recorded action. Revalidate only mutable inputs
  used by that action; a failed query is unknown, not evidence of absence.
- Keep Harness independent of the sibling `website` repository.
- Add focused tests for changed behavior and use `harness validate` for its
  deterministic risk tier. Run phase one for broad or escalated changes and
  once on the final integrated tree before protected publication.
- At handoff, record verified results, identifiers, failures and retry safety,
  modified files, validation, remaining checks, next action, and required
  authority.
- Before yielding unfinished work, update the selected task record. Change
  `TODO.md` only when its phase, ordering, next-action summary, or record
  pointer changes; never expand it with task chronology. Keep bulky
  reproducible evidence in tracked artifacts and never record credentials,
  private environment values, or chat-only assumptions.
