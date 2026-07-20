# Driver execution

## Steps and results

1. Revalidated target equality to baseline and both receipts, advanced in order
   through `ready-for-execution` to `executing`, then edited the live target.
2. Added `errno` and rewrote `load_seal` to open the leaf once with
   `O_RDONLY|O_CLOEXEC|O_NOFOLLOW|O_NONBLOCK`; it maps missing/symlink errors,
   uses `fstat` on that descriptor for regular/current-uid/single-link checks,
   reads to EOF from the same descriptor, explicitly decodes UTF-8, validates
   JSON as before, and returns parsed value plus SHA-256 of those exact bytes.
3. Changed `import_copilot` to consume `(seal, seal_sha256)` and removed its
   second `args.seal` path read. No schema, CLI, size cap, location rule, or
   receipt layout changed.
4. Added deterministic focused source assertions for `O_NOFOLLOW`, descriptor
   `fstat`/read/digest, tuple consumption, and absence of the former reopen. The
   existing happy-path digest and malformed/symlink/hard-link behavior remain
   exercised. Clarified exact-byte and before-open residuals in skill/protocol.
5. Python AST parse, shell syntax, focused cowork suite, and `git diff --check`
   passed on the live edits.

## Deviations

The first independent Claude invocation exited 0 but returned only
`Skill(codex-claude-cowork)`, with no required headings or evidence. It changed
only the staged candidate slot; protected/stage/seal hashes remained exact. One
narrow direct-task retry succeeded and was the only independent candidate
imported. No execution-phase deviation or out-of-scope edit occurred.
