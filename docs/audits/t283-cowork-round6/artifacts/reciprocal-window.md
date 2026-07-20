# Reciprocal Codex window — bounded record

- Same resolved command shape as the independent window, against
  `/tmp/harness-t283-round6-codex/stage-reciprocal` (mode reciprocal, both
  evidence files included).
- External pre-window stage seal
  `stage_sha256=f5b31282440d73fd13ea79b4a86b1250e3a6df76f94b7d0215355db622cc0f36`
  (`/tmp/harness-t283-round6-seals/reciprocal.stage_sha256`); post-window
  `stage.json` matched exactly.
- Protected pre-window seal
  `/tmp/harness-t283-round6-seals/protected-pre-reciprocal.digests` (now including
  `receipts/independent.json`) matched the post-window `digests` exactly: no
  driver-owned live write during the window.
- Single invocation, exit 0. Candidate 19511 bytes, required headings present and
  in order, zero standalone TODO lines. (The candidate quotes `git status`
  output containing a literal `## HEAD (no branch)` line inside a fenced block;
  this is an extra heading, not one of the required headings, so it does not
  affect the ordered required-heading validation.)
- `import-copilot` → `receipts/reciprocal.json`, candidate
  `sha256=423c365fd49344871b508b402e35601af1ac2eb67eb5a7d78c22dadd751b7747`.
- Chain verified: `reciprocal.destination_before` ==
  `independent.candidate` == `e6a8ba15…`. Both receipts are schema 1 (pre-change
  helper) — the live backward-compatibility fixture.

## Reciprocal findings that shaped the freeze

1. Withdrew the extra `stage_schema_version` seal field: a run with the seven-key
   seal still rejected a manifest tamper, because `stage.json` carries its own
   schema and the manifest hash commits it transitively.
2. Demonstrated with a **nested stage** that refusing only descendants of
   `stage_root.parent` accepts a seal elsewhere inside the co-pilot tree. The
   smallest fix is to require and document that `STAGE_DIR` is a direct child of
   the co-pilot sandbox (so `stage_root.parent` is the real sandbox root); a full
   mechanical fix would need an explicit `--copilot-root`.
3. Fault-injected a seal-publication failure: the stage exists, the seal does
   not, and import fails closed — confirming stage+seal is fail-closed but not
   cross-file atomic.
4. Changed an external seal after import and showed `verify-receipts` still
   passes: it validates the stored commitment and chain, not retained seal bytes.
5. Confirmed a schema-2 session holding a pre-change **schema-1 receipt** must
   stay readable: the receipt bump requires a dual-version reader.
