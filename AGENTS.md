# Harness agent working agreements

These instructions govern Codex and Claude here; root `CLAUDE.md` imports them.
Read only the policy rows selected below, each completely before its first
matching action.

## Always enforce

- Preserve user work and unrelated dirty changes; make narrow, reversible edits.
- Never inspect, expose, copy, or modify credentials. External messages,
  deployment/publication, account or hosting writes, destructive work, and broad
  owner configuration are separate authority boundaries. Authorization covers
  only its exact atomic change; bundle other approvals while continuing safe
  in-scope work.
- A duration or persistence request never broadens scope.
- Never run raw recursive or multi-path deletion (`rm -r`, `rm -rf`,
  `find -delete`, deletion loops/globs, `rsync --delete`, or equivalents). Apply
  `guarded-bulk-delete`; its passing plan/apply gate needs no owner prompt.
  Exact unlink and patch-based tracked deletion remain allowed.
- Prefix commentary updates with `[HH:MM:SS]`. Immediately beforehand, run a fresh native
  `date '+%H:%M:%S'` read and copy it exactly. Never infer it.
- Lead with outcomes and evidence. Make low-risk assumptions; stop only at a
  choice or authority boundary that materially changes scope or external state.
  Work in small evidence-backed steps and label hypotheses.
- After a transient Codex provider or service failure, resume the saved thread
  and reconcile durable state; never blindly replay the prior prompt because a
  side effect may already have succeeded.
- Validate proportionally: diff/contract checks for docs and ledgers; owning
  suites and invariants for mapped components; the complete suite for workflow,
  policy, validator, manifest, selector, safety, lifecycle, cleanup,
  credential, or unknown changes. Independently verify generated, optimized,
  or delegated results.
- Reuse validation when bytes, environment contract, and acceptance scope are
  unchanged. Rerun only changed owning checks, mutable inputs, or required final
  integration—not merely because a session resumed.

## Conditional policy router

Match the requested or next recorded action, not the repository's subject.
Multiple matches select multiple files.

| Read completely | Select before |
| --- | --- |
| [repository-git.md](docs/agent-policy/repository-git.md) | authenticated Git or SSH; branch, fetch, commit, push, PR, merge, publication, or repository hardening |
| [external-operations.md](docs/agent-policy/external-operations.md) | hosting/account API access or writes; owner/global configuration; packages/installers; or `~/run_this.sh` |
| [managed-codex.md](docs/agent-policy/managed-codex.md) | managed Codex or Claude, tmux, phone, app-server, saved-thread or unsafe-tail recovery, or an identified agent message |
| [fleet.md](docs/agent-policy/fleet.md) | fleet/node/route work, fleet-health or maintenance checks, fleet sync, or managed-Mac reboot or checkout rollout |
| [housekeeping-and-promotion.md](docs/agent-policy/housekeeping-and-promotion.md) | housekeeping, residue cleanup, launcher cleanup diagnosis, or promotion of reusable guidance |
| [research.md](docs/agent-policy/research.md) | factual or literature research, research-program work, scientific/HPC experiments, performance claims, or presentations |
| [duration.md](docs/agent-policy/duration.md) | an explicit duration, end time/date, time window, overnight run, or instruction to keep iterating |

Do not preload them. Route unknown policy-sensitive actions to the specific
workflow or owner decision; never silently skip a gate.

## Skill routing

Select the smallest exact skill set. Read each selected `SKILL.md` completely,
then only references routed for the current phase or target. Complexity alone
does not select a broad workflow; closer project rules win, and skills never
become runtime dependencies. Before a skill-directed action, name the skill and
reason in commentary; repeat this for an external action or pause. Installed skill descriptions are the trigger index; do not duplicate them here. The
deletion and duration refinements remain mandatory.

## Harness repository

- Git, `PRODUCER.md`, and `TODO.md` are durable truth; chat/client memory is
  optional. At cold start read this file and `PRODUCER.md`. Consumers run
  `python3 tools/producer-ledger.py next-ready`, then read only `TODO.md`, its
  selected packet and matching record, or remain idle. Never select a packet
  with a terminal receipt. Inspect Git and routed evidence; never preload another record or
  `docs/history/`. Fetch before collaborative edits.
- Only the portfolio producer edits `PRODUCER.md` or `docs/producer/`.
  Consumers create no IDs/goals; handle nested issues LIFO or write a blocked
  receipt. Run `PRODUCER.md`'s consumer diff check before publication.
- Resume the first unverified recorded action. Revalidate only mutable inputs
  used by that action; a failed query is unknown, not evidence of absence.
- Keep Harness independent of the sibling `website` repository.
- Add focused behavior tests and use `harness validate` for deterministic risk
  tiers. Run phase one for broad/escalated changes and once on the final
  integrated tree before protected publication.
- Handoffs record verified results/IDs, failures and retry safety, changed
  files, validation, remaining checks, next action, and required authority.
- Before yielding unfinished work, update the selected task record. Change
  `TODO.md` only when its phase, ordering, next-action summary, or record
  pointer changes; never expand it with task chronology. Put bulky reproducible
  evidence in tracked artifacts; never record credentials, private environment
  values, or chat-only assumptions.
