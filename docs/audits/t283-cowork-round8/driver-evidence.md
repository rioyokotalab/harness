# Driver evidence

## Sandbox and baseline

Codex inspected detached worktree `/tmp/harness-t283-round8-codex` at exact,
clean baseline `0620d3eb92f942c72e8972dbe67566db36244c00`. No target file was
edited.

## Commands and results

- Static trace found three path operations during import: `lstat()` inside
  `require_owned_kind`, `Path.read_text()` inside `load_seal`, then a separate
  `session_path(args.seal).read_bytes()` at receipt construction.
- The JSON value that controls role/mode/phase/destination/stage validation comes
  from the second operation. `receipt.seal_sha256` comes from the third. A leaf
  path can therefore be atomically replaced after validation but before the
  digest reopen, making those two observations refer to different inodes/bytes.
- The already-read valid seal still controls the import decision, so this trace
  does not alone bypass an unreachable external seal. It does falsify the exact
  claim that the receipt binds the seal bytes structurally validated by this
  invocation.
- `require_owned_kind` protects only its own earlier `lstat`; replacement between
  `lstat` and `read_text` can likewise make JSON parsing observe a different
  file. Regular-file/uid/link checks and content read are not descriptor-bound.
- Existing focused tests cover symlink, hard-link, malformed, altered, wrong
  stage, and ordinary receipt-digest behavior, but no structural assertion
  prevents a future second seal-path read.

## Critique

This is a narrow provenance/correctness issue, not a new confinement model. The
smallest robust shape is one `os.open` with `O_RDONLY|O_CLOEXEC|O_NOFOLLOW`, one
`os.fstat` for regular/current-uid/single-link properties, one read from that
same file description, JSON decode/validation from those bytes, and a returned
SHA-256 over those same bytes. Parent-path reachability and same-UID replacement
before `open` remain documented residuals; after `open`, leaf replacement cannot
change the validated bytes or digest.

Do not add seal-size limits, schema changes, CLI arguments, or stronger
authorship/confinement language in this round. A deterministic regression should
assert that `import_copilot` receives both parsed seal and digest from
`load_seal`, and that no `args.seal` path reopen remains in import, while all
behavioral edge tests continue to pass.

## Proposed plan changes

1. Ask Claude to independently confirm or refute the distinct-inode trace and
   the portability/diagnostic implications of descriptor-bound reading.
2. If confirmed reciprocally, implement one exact-byte reader localized to
   seals, return `(value, digest)`, add structural source assertions plus focused
   behavior coverage, and clarify only the byte-identity claim in docs.
3. Reject any broader promise that this stops a co-pilot which can reach the
   seal before it is opened.
