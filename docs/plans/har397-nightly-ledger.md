# Har-397 direct and nightly ledger migration

## Target structure

```text
TODO.md                       ordinary Har-* active board
docs/tasks/config.json        next Har ID and record bounds
docs/tasks/index.tsv          ordinary task dispositions and history lookup
docs/tasks/Har-NNN.md         ordinary execution records

NIGHTLY.md                    sole Harness nightly procedure and active board
docs/nightly/config.json      next Nit ID and record bounds
docs/nightly/index.tsv        nightly dispositions
docs/nightly/tasks/Nit-NNN.md nightly execution records
tools/harness-ledgers.py      shared schema and namespace validator
```

## Migration rules

- `Har-*` and `Nit-*` never cross ledgers.
- “Put this in the nightly ledger” allocates the next `Nit-*`; it never creates
  a `Har-*` task.
- Nightly records contain no private sibling payload. Private implementation
  details stay in the owning repository's ordinary ledger.
- Historical Harness producer packets and receipts move under `docs/history/`
  and are never part of cold-start routing.
- Harness retains portfolio coordination guidance and the reusable onboarding
  scaffold solely for sibling or future project repositories.
