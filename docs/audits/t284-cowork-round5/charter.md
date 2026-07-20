# Charter

## Task

Audit and correct `wait-copilot` deadline precedence. A snapshot that completes
after its explicit monotonic deadline must not return ready merely because its
bytes are fresh; timeout must win once the observation budget is exhausted.

## Boundaries

Codex drives; Claude is a blinded staged co-pilot. Experiments use deterministic
monotonic/status fakes in matched disposable clones. Only Codex may mutate the
task branch after reciprocal evidence, frozen reconciliation, and the owner's
standing go. No settings, credentials, packages, remotes, services, external
messages, or cleanup during the evidence window.

## Baseline and sandboxes

Both no-hardlink clones use commit
`f3114a881ea0adb05c82c48d0018b549f72a6d5a` under
`/tmp/harness-t284-r5.X6y0SH/{codex,claude}`. Claude stages are direct children
of its clone; prompts/seals/raw output stay under the driver-only sibling.
Predecessor round 4 is recorded complete.

## Acceptance

Reproduce the edge with a deterministic fake whose ready snapshot consumes 1.1
seconds of a 1.0-second budget. Agree exact precedence for initial, normal,
process-loss final, and timeout snapshots. Freeze the smallest production/test
change; focused cowork, receipts, diff, fresh-clone, and final phase-one gates
must pass. No broader wait API or CI topology change.
