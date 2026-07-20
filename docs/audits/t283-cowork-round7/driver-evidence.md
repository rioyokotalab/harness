# Driver evidence

## Sandbox and baseline

Codex used detached worktree `/tmp/harness-t283-round7-codex` at exact baseline
`4c3602d586fb5d7225f516aa15677a2b6fa1384b`. `git status --short` was empty.
No live target file was edited during this independent pass.

## Commands and results

From that worktree:

- `git rev-parse HEAD` returned the exact charter baseline; clean status had no
  output.
- `python3 -m py_compile .../cowork-session` and `bash -n
  tests/test-codex-claude-cowork-skill.sh` both exited 0.
- `tests/test-codex-claude-cowork-skill.sh` exited 0 with `Codex-Claude cowork
  skill tests passed`. This concretely exercises the sealed happy path, missing
  seal, seal inside session/co-pilot tree, pre-existing seal, modified and
  malformed seals, wrong-stage seal, candidate import, schema-2 receipt binding,
  replay refusal, legacy schema-1 receipt reading, phase skips, both driver
  identities, direct mode, predecessor validation, and staged state projection.
- A first static query used a pattern beginning `--seal` without `rg --` and was
  rejected as an option; it changed no files. The corrected `rg -n -- ...` trace
  found the seal commands in both skill/protocol, the native phase sequence,
  receipt binding and compatibility checks, and the explicit statement that
  `verify-receipts` does not reopen external seal bytes.
- Static trace of `load_seal` and `import_copilot` confirms seal structure and
  stage-manifest equality are checked before candidate bytes replace live
  evidence. Static trace of `advance` confirms skipped phases are refused, but
  the helper has no authority over arbitrary editor writes outside its own
  commands.

## Critique

The release candidate has strong focused coverage, and the operator-visible
happy path now names both `stage --seal` and `import-copilot --seal`. A new
`verify-receipts --seal-path` surface would bind durable validation to an
ephemeral local path that is deliberately omitted from path-free receipts and
may not survive takeover or cleanup. The current separate retained-byte
comparison is therefore an explicit recovery/audit operation, not silently part
of receipt-chain validity.

Likewise, no generic session helper can prevent a driver from editing arbitrary
repository files before `executing` unless all editors are routed through a new
OS-enforced wrapper. The existing helper correctly rejects phase skips; round 6
demonstrates that an out-of-band write must remain an auditable process failure.
Adding a token file would create ceremony without controlling the editor.

One remaining usability question requires the other client: whether Claude can
follow the sealed staging instructions without seeing the live exchange, and
whether it independently considers retained-seal CLI expansion worthwhile.

## Proposed plan changes

1. Keep the implementation unchanged unless Claude reproduces a correctness or
   actionable usability failure.
2. In reconciliation, explicitly reject integrated retained-seal verification
   if it requires receipt paths or makes historical receipt validation depend on
   cleaned scratch; retain the documented manual digest comparison.
3. Keep phase ordering as a required audited invariant; do not claim the helper
   can confine arbitrary target writes. Consider a wrapper only in a future task
   with an actual OS-enforcement design and acceptance test.
4. Add no code solely to make the final audit appear productive. A validated
   no-code execution is a legitimate outcome.
