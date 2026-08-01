# Charter

## Task

Design, implement, publish, and bridge-first activate T-366: one Local tmux
session named `harness` with a mixed-client `cowork` window and separate
Personal/Students Codex and Claude windows, including exact resume, monitor,
remote-control, messaging, and `att` behavior.

## Boundaries

Codex is the sole target writer and runtime driver; Claude is the native
co-pilot. Planning and evidence are read-only against the live topology. Never
read panes or transcripts, inspect credentials, disturb unrelated work, or
retry an ambiguous client launch, message submission, or tmux promotion.
The destroyed pane/PID identities are historical evidence only. Reconstruct
accepted processes from exact durable session identities and do not recreate
Swallow. Non-goals include T-363 workspace
lifecycle, T-354 repository relocation, fleet hardening, and unrelated cleanup.

Owner authority covers the exact repository, Local tmux, alias, monitor,
recovery, and phone-control changes needed for this topology. Unavoidable
phone visibility confirmation remains an owner acceptance gate.

## Baseline and sandboxes

Immutable baseline is Git commit
`3d96125514281ef071ba7ce0303185b6e3e8660e`. The target is branch
`codex/t366-cowork-personal-layout` at
`/tmp/harness-t366-cowork-personal-layout`. The live exchange is this directory.
Disposable driver and Claude sandboxes are detached worktrees at
`/tmp/harness-t366-driver-sandbox` and `/tmp/harness-t366-claude-sandbox`, both
constructed from the immutable baseline. Stages are direct children of the
Claude sandbox; seals and driver prompts live in a current-user mode-0700
directory outside the target, exchange, and both sandboxes.

## Acceptance

Every benchmark case passes on matched baseline evidence, focused tests and
phase one pass, protected `main` publication succeeds, and reconstruction
creates exact accepted pane/process identities. Both Personal clients have
distinct exact resume identities and supported phone control before final
acceptance. Final metadata, monitor/helper, message routing, alias, attachment,
resume, remote-control, fleet-health, and rollback checks are value-minimized.
