# Harness agent working agreements

These govern both clients; `CLAUDE.md` imports them. Read each selected policy
completely before its first matching action.

## Always enforce

- Preserve user work and unrelated dirty changes; make narrow, reversible edits.
- Never inspect, expose, copy, or modify credentials. Messages, publication,
  hosting/account writes, destructive work, and broad owner configuration are
  separate authority boundaries. Authorization covers only its exact change.
- A duration or persistence request never broadens scope.
- Never run raw recursive or multi-path deletion (`rm -r`, `rm -rf`,
  `find -delete`, deletion loops/globs, `rsync --delete`, or equivalents). Apply
  `guarded-bulk-delete`; its passing plan/apply gate needs no owner prompt.
  Exact unlink and patch-based tracked deletion remain allowed.
- Prefix commentary updates with the current local time in `[HH:MM:SS]`.
  Immediately beforehand, run a fresh native `date '+%H:%M:%S'` read and copy
  it exactly. Never infer a timestamp.
- Lead with outcomes and evidence. Make low-risk assumptions; stop only at a
  material choice or authority boundary. Label hypotheses.
- After a transient Codex provider or service failure, resume the saved thread
  and reconcile durable state; never blindly replay the prior prompt because a
  side effect may already have succeeded.
- Validate in order: one affected-group discovery, one owning suite per repair,
  then one complete final suite before publication. High-risk and unknown
  changes remain final-required. Independently verify generated or delegated
  results.
- Reuse validation when bytes, environment contract, and acceptance scope are
  unchanged. Rerun only changed owning checks, mutable inputs, or required final
  integration—not merely because a session resumed.

## Conditional policy router

Match the next action, not the repository's subject. Multiple matches combine.

| Read completely | Select before |
| --- | --- |
| [repository-git.md](docs/agent-policy/repository-git.md) | authenticated Git or SSH; branch, fetch, commit, push, PR, merge, publication, or repository hardening |
| [external-operations.md](docs/agent-policy/external-operations.md) | hosting/account API access or writes; owner/global configuration; packages/installers; or `~/run_this.sh` |
| [managed-codex.md](docs/agent-policy/managed-codex.md) | managed Codex or Claude, tmux, phone, app-server, saved-thread or unsafe-tail recovery, or an identified agent message |
| [fleet.md](docs/agent-policy/fleet.md) | fleet/node/route work, fleet-health or maintenance checks, fleet sync, or managed-Mac reboot or checkout rollout |
| [housekeeping-and-promotion.md](docs/agent-policy/housekeeping-and-promotion.md) | housekeeping, residue cleanup, launcher cleanup diagnosis, or promotion of reusable guidance |
| [research.md](docs/agent-policy/research.md) | factual or literature research, research-program work, scientific/HPC experiments, performance claims, or presentations |
| [duration.md](docs/agent-policy/duration.md) | an explicit duration, end time/date, time window, overnight run, or instruction to keep iterating |
| [portfolio-coordination.md](docs/agent-policy/portfolio-coordination.md) | coordinating a sibling repository's producer/consumer ledger, packet, receipt, or consumer message |

Do not preload them. Route unknown policy-sensitive actions to the specific
workflow or owner decision; never silently skip a gate.

## Skill routing

Select the smallest exact skill set, read its `SKILL.md`, then routed references.
Closer rules win; skills grant no authority. Name a skill before acting and
again for an external action or pause.
Installed skill descriptions are the trigger index. The deletion and duration
refinements remain mandatory.

## Harness repository

- Git and `TODO.md` are the ordinary durable truth; chat and client memory are
  optional. At cold start read this file and `TODO.md`, run
  `python3 tools/harness-ledgers.py next-task`, then read only the selected
  `docs/tasks/Har-NNN.md` record and its routed evidence. Inspect Git; never preload
  another active record or `docs/history/`. Fetch before collaborative
  edits.
- Harness executes its own work directly; it has no Harness-local producer,
  consumer, packet, assignment, receipt, or checkpoint-confirmation lifecycle.
  `NIGHTLY.md` is a separate `Nit-*` queue used only when the owner starts a
  nightly run or explicitly asks to add work to the nightly ledger. In that
  case run `python3 tools/harness-ledgers.py next-nightly`; never allocate a
  `Har-*` item for the nightly request.
- Harness may coordinate sibling repositories that retain repository-local
  producer/consumer ledgers. Their ledgers and private details remain in those
  repositories and follow the routed portfolio policy; they never become
  Harness task records.
- Resume the first unverified recorded action. Revalidate only mutable inputs
  used by that action; a failed query is unknown, not evidence of absence.
- Keep Harness independent of the sibling `website` repository.
- Add focused behavior tests and use `harness validate`; follow the
  discovery/repair/final order above before protected publication.
- Handoffs record verified results/IDs, retry safety, files, validation, next
  action, and required authority.
- Before yielding unfinished work, update the selected task record. Change
  `TODO.md` only when its phase, ordering, next-action summary, or record
  pointer changes; never expand it with task chronology. Put bulky reproducible
  evidence in tracked artifacts; never record credentials, private environment
  values, or chat-only assumptions.
