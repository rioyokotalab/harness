# Validation

## Checks

The canonical skill validator passes. The expanded cowork focused suite passes
in about eight seconds and covers schema-1 compatibility, schema-2 staged/direct
mode, receipt phase/order/chain/content, stage and destination binding, receipt
and candidate drift, replay, path absence, digest coverage, non-crash rollback,
retry, aliases, and crash residue in addition to every round-1–4 case. Python
source compiles in-memory without cache output and the shell test parses.

`tests/test-claude-takeover.sh`, `tests/test-source-contract.sh`,
`tests/test-public-repo-audit.sh`, and `git diff --check` pass. The current
legacy round-5 session validates at `validating` under the new dual-schema
helper. A clean-commit full `tests/test-phase1.sh` remains after the reviewed
checkpoint because its tmux path intentionally requires a clean checkout.

## Outcome

All driver-scoped gates pass. The implementation changes only the cowork skill,
its focused test, the task ledger, and this round's public-safe evidence. It does
not change settings, credentials, packages, remotes, services, external
messages, or unrelated repository content. No sandbox has been deleted yet.

## Residual risks

Import receipts and external digests detect byte relationships; they do not
prove model authorship, prevent same-user writes, or restore data. The normal
exception path rolls back evidence and cleans exact temporary state, but the
evidence/receipt pair is not crash-atomic. Destination-before binding makes the
crash-shaped retry fail closed; recovery still needs the driver-held preimage.
The stage-manifest hash is printed, recorded in receipts, and required by prose
to be externally sealed, but `import-copilot` does not yet require a separate
driver-held seal file. Claude without an OS wrapper remains behaviorally rather
than mechanically confined. Schema-2 is intentionally fail-closed and future
state/receipt fields require coordinated validator/test updates.
