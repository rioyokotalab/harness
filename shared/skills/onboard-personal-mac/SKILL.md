---
name: onboard-personal-mac
description: Plan, execute, validate, roll back, or resume onboarding of exactly one personal Mac; Codex runs native commands and pauses only at unavoidable owner gates.
---

# Onboard one personal Mac

Operate exactly one owner-named Mac. Treat repository Git, the compact
`TODO.md` queue, and its selected task record as durable truth; never infer
state from another Mac. Codex runs every native command; the owner supplies only
decisions and unavoidable physical or authentication interaction.

## Route only the current phase and components

Reconstruct the phase, then read every selected reference completely before
its action; do not preload later phases or unrelated components.

| Current action | Read completely |
| --- | --- |
| reconstruct, discover, plan, or await `go` | [planning.md](references/planning.md) |
| mutate after `go` | [execution-common.md](references/execution-common.md), plus each matching component below |
| restore or create the private companion | [private-companion.md](references/private-companion.md) |
| bootstrap prerequisites or manage Homebrew packages | [bootstrap-packages.md](references/bootstrap-packages.md) |
| install or verify public control-plane links | [public-control.md](references/public-control.md) |
| adopt or converge Bash startup | [bash-startup.md](references/bash-startup.md) |
| configure or validate tmux | [tmux.md](references/tmux.md) |
| establish or migrate private SSH agreement | [ssh-private.md](references/ssh-private.md) |
| adopt or validate Codex or Claude configuration | [agent-config.md](references/agent-config.md) |
| accept, roll back/reapply, checkpoint, or publish | execution common plus [acceptance.md](references/acceptance.md) and the component under test |
| test or retire `.bash_common` after acceptance | execution common plus acceptance and [orphan-cleanup.md](references/orphan-cleanup.md) |

Component routes augment `execution-common.md`; they never replace it. Read
each component spanned by one action.
The orphan route cumulatively includes the entry, execution common, acceptance,
and orphan references; add a component only when revalidating it. On a phase or
component change, read only the newly selected reference. References never
select one another.

## Preserve the authority boundary

Do not mutate the target until `planning.md` records one host, a complete plan,
no open material decision, `ready-for-go`, and the owner's explicit `go`.
Apply recorded owner defaults without asking again. Pause only for a new
material choice, unsafe or divergent adapter state, unavoidable interaction,
missing authority, or drift.

Stop rather than guess an unknown phase, host, route, transaction, or state. A
failed query is unknown, not absence. On interruption, preserve the last
verified state and resume from the ledger.
