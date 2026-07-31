# Private SSH-only agreement

For an existing agreement, run
`macos-ssh-sync --host HOST --plan|--apply`. On first agreement, when a fetched
private payload exists and differs from the live file, use the settled
`--adopt-remote` route. Preserve the live preimage and require exact
rollback/reapply. Use `--seed` only when the private payload is absent.

This default never resolves a later two-sided divergence; stop for one new
material decision. Select `macos-config-migrate` only when the current ledger
and private profile explicitly require the legacy-schema route.

Keep the agreement SSH-only. Never expose private payload bytes or revisions,
substitute a public profile, inspect keys, weaken agent-socket ownership, or
silently fall back to an unauthenticated transport.
