You are the Claude driver for a full `codex-claude-cowork` self-refinement
session. The owner explicitly requested that the skill work with either client
as driver and authorized continued self-refinement. Work autonomously through
planning, evidence discussion, frozen execution, and validation.

Read the complete skill and protocol from your detached driver sandbox at
`/tmp/harness-t283-round2-claude/shared/skills/codex-claude-cowork/`. Both your
driver sandbox and the Codex co-pilot sandbox
`/tmp/harness-t283-round2-codex` are immutable-baseline no-hardlink clones at
`7df5f7d2bb8b199c51fd87f00d43467c12b8073e`. The live target is
`/home/rioyokota/harness` on branch `task/t-283-codex-claude-cowork`. The
initialized exchange directory is
`/home/rioyokota/harness/docs/audits/t283-cowork-round2`, with state naming you
as driver and Codex as co-pilot.

Follow every skill phase and file-ownership rule. First reconstruct the clean
target and v2 baseline, then fill the driver-owned `charter.md` and `plan.md`
with a bounded adversarial audit of remaining symmetry, safety, takeover, and
native-invocation defects. Advance to `discussing`. Run your independent tests
only in your driver sandbox and write `driver-evidence.md` before exposing it to
Codex.

Then construct a public-safe prompt under `artifacts/` and invoke the actual
Codex CLI as co-pilot using the corrected native shape:

`codex --ask-for-approval never exec --ephemeral --sandbox workspace-write --cd /tmp/harness-t283-round2-codex --add-dir /home/rioyokota/harness/docs/audits/t283-cowork-round2 --output-last-message /home/rioyokota/harness/docs/audits/t283-cowork-round2/artifacts/codex-last.md -`

Give Codex only the charter, plan, baseline, its sandbox, and its owned
`copilot-evidence.md`; explicitly blind it from your evidence until its
independent pass finishes. Do not give Codex the live target. After both passes,
perform reciprocal critique: you append to your evidence, and invoke Codex a
second time to append to its evidence. Reconcile observed results, preserve any
disagreement, and advance to `ready-for-execution` only with a precise frozen
plan and no blocking gap.

The original owner instruction is the go for that frozen self-refinement scope.
After ready, revalidate the live target. Advance to `executing`, then you alone
may edit the live skill, protocol, deterministic helper, focused test, round-2
exchange files, and compact T-283 ledger entry. Do not modify settings,
authentication, credentials, packages, remotes, other tasks, or external
systems. Do not push. Do not use raw recursive or bulk deletion; retain all four
round sandboxes for later guarded cleanup. Preserve unrelated work and stop if
the target has unexpected drift.

Run canonical skill validation, focused cowork, Claude takeover, source,
public-audit, diff, and full phase-1 checks. If the full suite requires a clean
commit, you may make a small commit containing only reviewed T-283 files, rerun
from the clean commit, then record the result and make a final evidence-only
commit. Do not weaken a safety gate to pass. Advance the session to `complete`
only after every required check passes. End your terminal response with the
session phase, commits (if any), exact files changed, validation, and residual
risks; the exchange files and Git remain authoritative.
