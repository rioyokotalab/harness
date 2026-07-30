# Backup and acceptance

Follow `docs/home-backup.md` for primary initialization, manual snapshot,
repository check, representative restore, independent encrypted generation,
credential-safe validation, and independent restore. Exit success alone is
not proof; preserve evidence without secrets.

Before completion require:

- a clean remote checkout at the recorded revision and two unchanged
  `harness doctor` passes;
- correct login and non-interactive SSH, with no prompt or unsolicited output;
- converged Vim and only approved SSH fragments;
- planned storage, retained-copy recovery, and quota behavior;
- primary snapshot/check/restore and independent-generation restore proof;
- exact verified absence of temporary bundles, plans, and staging artifacts;
  and
- ledger records for commits, pushed state, evidence, exclusions, residual
  risks, and the next separately authorized action.

On failure, preserve the last known-good copy, record the exact failed gate
and retry safety, and stop for a new material decision or authority. Never
infer acceptance from a partial or ambiguous result.
