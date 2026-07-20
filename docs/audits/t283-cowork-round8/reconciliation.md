# Reconciliation

## Evidence accepted

Both agents independently traced three separate seal leaf lookups: metadata
`lstat`, JSON `read_text`, and receipt-digest `read_bytes`. Claude reproduced an
atomic replacement in disposable scratch where the parsed/accepted seal hash
differed from `receipt.seal_sha256`; a one-descriptor prototype retained the
pre-swap inode for both parsing and digest. This is a real receipt byte-identity
defect, not an import bypass: the original parsed seal still controls all import
checks. Linux/macOS expose the required flags and descriptor metadata.

## Disagreements and uncertainty

No material disagreement remains. Claude initially proposed a 64 KiB seal cap,
then withdrew it reciprocally because it does not establish byte identity and
would change accepted behavior. Codex did not initially include `O_NONBLOCK`;
Claude showed it is needed when the regular-file check moves after `open`, so a
FIFO/device leaf cannot block before `fstat` rejects it. We accept that narrow
flag. We reject a runtime race hook: structural source assertions plus existing
edge behavior and happy-path digest equality prove the second read is absent.

## Frozen plan

1. Advance in order to `executing`; only Codex edits the live target.
2. In `load_seal`, open the leaf once with
   `O_RDONLY|O_CLOEXEC|O_NOFOLLOW|O_NONBLOCK`, map missing and symlink open
   errors to existing diagnostics, use `fstat` on that descriptor for regular
   type/current uid/single-link checks, read it to EOF without a new cap,
   explicitly decode UTF-8, parse/validate JSON, and return `(value, digest)`.
3. In `import_copilot`, consume both return values and remove the later
   `args.seal` path reopen. Do not change schema, CLI, location checks, or
   external-confinement claims.
4. Add deterministic focused source assertions for one descriptor/no reopen and
   preserve the existing happy-path digest and malformed/symlink/hard-link tests.
   Clarify in skill/protocol that receipt digest binds the exact seal bytes
   validated by that import; retain before-open same-UID and parent-path limits.
5. Run focused, syntax, takeover, source-contract, public audit, live receipt
   compatibility, diff checks, then checkpoint and clean full Phase 1. Complete
   and guarded-clean exact scratch only after acceptance.

## Acceptance gates

- `load_seal` has one leaf `os.open`, one descriptor read, and returns its digest;
  import has no second seal path read.
- Existing error and compatibility behavior passes, including the live round-8
  receipts written by the pre-change helper.
- No schema/CLI/size/confinement expansion.
- All focused/repository gates and clean full Phase 1 pass.
- Original owner instruction is the go for this frozen narrow scope; any broader
  choice stops. Scratch cleanup uses guarded manifests.
