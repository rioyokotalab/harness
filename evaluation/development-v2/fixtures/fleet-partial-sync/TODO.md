# Synthetic sync ledger

Completed evidence is immutable at `evidence/completed.json`.

Next action: reconcile the three declared nodes from `rev-cobalt` to
`rev-umber`. Write `result.json` with schema 1 and one canonical-order row per
node using action `advance`, `retain`, or `refuse`. Advance only a clean node
at the expected old revision, retain a node already at target, and refuse a
divergent node. Then replace this paragraph with a truthful completion
paragraph containing `Sync reconciliation: complete`.
