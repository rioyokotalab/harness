# Initial plan

## Confirmed facts and assumptions

- Confirmed: `load_seal` currently calls `require_owned_kind(path, "file")`, then
  `path.read_text()`, while `import_copilot` later calls
  `session_path(args.seal).read_bytes()` for the receipt digest.
- Confirmed: round 7 accepted current behavior but explicitly left
  descriptor-bound reads as future evidence-requiring work.
- Hypothesis: a path replacement between these operations can make the receipt
  digest describe bytes other than the seal JSON that passed validation.
- Assumption to challenge: an `os.open`/`fstat`/single-read implementation can
  close this byte-identity gap without claiming same-UID path protection or
  cross-file atomicity.

## Steps

1. Both agents independently trace the exact seal lifecycle and devise a bounded
   way to falsify the single-byte-identity claim; inspect relevant tests.
2. Exchange blinded evidence with sealed independent and reciprocal stages.
3. Reconcile whether the issue is real, its security/correctness scope, and an
   exact API: ideally `load_seal` returns parsed JSON plus SHA-256 from one byte
   read on one validated file description.
4. If accepted, advance through `ready-for-execution` and `executing` before
   editing; implement only the reader/digest change and focused tests that prove
   there is no second seal-path read. Preserve documented confinement residuals.
5. Validate focused, syntax, source-contract, takeover, public audit, session
   receipts, clean full Phase 1, discovery identity, and guarded cleanup.

## Evidence questions

- Which exact operations can observe different path identities today?
- Can the receipt bind unvalidated seal bytes even though the already-validated
  seal still protects the import decision?
- What properties must be checked on the opened descriptor: regular file,
  current uid, one link, non-symlink via `O_NOFOLLOW`, and bounded bytes?
- Does the proposed fix alter schema, CLI, path-free data, compatibility, or
  claims about Claude confinement?
- What deterministic structural regression prevents a later path reopen?

## Risks and recovery

Do not overstate impact: this is receipt byte identity, not a demonstrated bypass
of an unreachable driver-held seal. Stop with documentation only if one read
cannot be implemented portably or tested. Preserve all scratch until receipt
verification and reconciliation; use guarded cleanup. Any client failure or
digest mismatch stops import. Git provides rollback; no target edit before the
`executing` phase.
