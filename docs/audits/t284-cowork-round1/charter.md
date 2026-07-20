# Charter

## Task

Refine the published Codex-Claude cowork workflow along four measurable axes:
lower driver/co-pilot turnaround, clearer and smaller file-mediated exchanges,
observable co-pilot state while a native client window is open, and shorter
local/CI validation latency. Test proposals against the published baseline
before any target implementation.

## Boundaries

Codex is the driver and Claude Code is the co-pilot. Only Codex may later edit
the target checkout. During discussion both clients may perform read-only
inspection and mutate only their separate disposable sandboxes. Preserve
blinded independent evidence, sealed staged import, receipt integrity,
driver-only target mutation, and recognizable native client invocations. Do
not access credentials or private values; change settings, packages, services,
remotes, or external systems; publish; or weaken sandbox, seal, receipt,
authority, validation, or cleanup controls. Exchange artifacts must remain
bounded and public-safe.

## Baseline and sandboxes

Immutable Git baseline:
`f7d5bf0d403bdc07079bb4c5e420a2aa9fbb4a02`. The target is the task checkout
`/home/rioyokota/harness` on branch `task/t-284-cowork-speed`. Independent
no-hardlink clones will be created at `/tmp/harness-t284-r1-codex` and
`/tmp/harness-t284-r1-claude`, each checked at the named baseline. Each stage
will be a direct child of the Claude sandbox. External seals and protected
digest manifests will be under `/tmp/harness-t284-r1-driver`, outside the
session and both co-pilot-writable trees. Baseline measurements on the target
were 10.12 seconds for the focused cowork suite and 88.18 seconds for a clean
four-worker phase-one gate.

## Acceptance

Both independent passes must execute bounded experiments, report commands,
elapsed time, observed output, and exact proposed changes, then challenge the
strongest conflicting result reciprocally. Reconciliation must select changes
that reduce measured wall time or manual polling/context steps while retaining
all published safety invariants. Any implementation must pass the canonical
skill validator, focused cowork suite, Claude takeover, source contract,
public-repository audit, `git diff --check`, and a clean full phase-one gate.
The final session must preserve both receipts and validate complete.
