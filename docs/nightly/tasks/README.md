# Nightly task records

Each `Nit-NNN.md` file is the complete durable execution record for one
owner-requested Harness nightly task. Its metadata keys are `task`, `status`,
and `updated`, followed by `---`. Valid states are `ready`, `active`, `gated`,
`blocked`, `complete`, and `canceled`.

Nonterminal tasks appear in both `NIGHTLY.md` and `docs/nightly/index.tsv`.
Terminal tasks remain only in the index and their record. Never store private
sibling-repository values in this public ledger.
