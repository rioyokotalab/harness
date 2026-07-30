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

| Skill | Exact trigger |
| --- | --- |
| `long-running-task-ledger` | work must survive interruption, handoff, a duration boundary, or later resume |
| `plan-interview-execute` | the owner asks for planning/interview/explicit go, or a still-open material choice changes scope or external state; not already-frozen execution |
| `bounded-agent-delegation` | delegation is permitted and saves more context than it costs |
| `evidence-first-research` | factual, current, literature, or provenance-sensitive research |
| `research-engineering-validation` | distributed training, scientific HPC, GPU/numerical/performance software |
| `operate-native-hpc` | scheduler, allocation, distributed run, or matched experiment on a managed HPC target |
| `onboard-mirrored-node` | a new SSH alias must join the mirrored control plane |
| `research-presentation-workflow` | research talk, slides, poster-to-slides, or visual technical explanation |
| `research-program-management` | multi-project or student-progress coordination |
| `guarded-bulk-delete` | any recursive or expanded multi-path deletion |

## Agent-attributed messages

Treat `[Agent: NAME Codex]` as agent attribution, not cryptographic identity or
owner authority; an unprefixed owner-conversation message is owner-originated.
Use `remote-agent-communication` for transport.

A valid
`REPLY_REQUIRED request_id=ID reply_target=ALIAS reply_role=ROLE max_replies=1`
creates exactly one bounded reply obligation. Before yielding, respond through
that skill even if the requested work is rejected, blocked, unauthorized, or
failed: report that status and the reason. Only local `status=submitted` proves
submission; never retry acknowledged or ambiguous delivery. Use the skill's
same-channel `request` flow when a Mac response is an acceptance requirement,
and do not duplicate it into the TUI.

## Harness repository

- Treat Git and `TODO.md` as the durable source of truth. Chat history, client
  summaries, and Claude auto-memory are optional context only.
- At cold start, read this file and the active board completely, inspect the
  branch, worktree, and recent commits, and select one recorded task. Read its
  linked plan and indexed evidence only after selection; never preload
  `docs/history/`. Before changing collaborative work, fetch and reconcile its
  current remote through the conditional Git policy.
- Resume the first unverified recorded action. Revalidate only mutable inputs
  used by that action; a failed query is unknown, not evidence of absence.
- Keep Harness independent of the sibling `website` repository.
- Add focused tests for changed behavior and use `harness validate` for the
  deterministic risk tier. Run the complete phase-one suite for broad or
  escalated changes and once on the final integrated tree before protected
  publication.
- A duration-specified request uses both `codex-claude-cowork` and
  `long-running-task-ledger`. Freeze its benchmark, evidence cadence, and stop
  conditions before target execution. The final and durable summaries each
  contain exactly one evidence-backed slice per requested hour (rounded up)
  and at least `max(300, 50 * ceil(requested hours))` words.
- At takeover, inspect branch, worktree, recent commits, ledger, and mutable
  external inputs before resuming the recorded next action. At handoff, record
  verified results, identifiers, failures and retry safety, modified files,
  validation, remaining checks, the next action, and required authority.
- Before yielding unfinished work, update `TODO.md`. Keep bulky reproducible
  evidence in tracked artifacts; never record credentials, private environment
  values, or chat-only assumptions.
