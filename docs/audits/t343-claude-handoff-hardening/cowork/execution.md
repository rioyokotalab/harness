# Driver execution

## Steps and results

Execution began at 2026-07-29T18:05:55+09:00 after the owner's explicit `go`.
Preflight reconstructed the frozen scope from committed files rather than chat:

- target and remote task head:
  `bd47587db69f029cce5a43ec8b8e48a19b94f472`;
- protected `main`: `333d67b2179906dbaea5c7ea7e763613851e52b8`;
- Cowork state: `ready-for-execution`, with independent and reciprocal
  receipts verified, then advanced once to `executing`;
- ruleset `19127355`: active, owner/admin bypass, strict
  `portable-phase1`, zero required approvals;
- official ABCI-Q System H status: service stopped, with maintenance extended
  through 2026-07-30 17:00 JST; ABQ remains excluded.

### Iteration 1 — task-bound packet identity

- Hypothesis: the current repository has no machine-readable handoff packet
  validator that rejects wrong root, baseline, task, expiry, and cross-task
  reuse.
- Before identity: clean task commit `bd47587`; new focused fixture
  `tests/test-claude-handoff.sh`, with no production command.
- Exact check: `tests/test-claude-handoff.sh`.
- Observed result: failed at the first positive assertion with
  `unknown harness command: claude-handoff`; guarded fixture cleanup succeeded.
- Decision: keep the failing fixture. Implement only the declared read-only
  dispatcher and strict packet validator, then rerun unchanged.

The strict packet validator and public schema then passed the unchanged exact
accept, wrong-root, wrong-baseline, missing-task, expired, cross-task, and
linked-input assertions.

### Iteration 2 — authority-class evidence and retry identity

- Hypothesis: packet validation alone cannot distinguish read-only evidence
  from execution claims or require a changed identity after a failed client
  row.
- Before identity: packet fixture passes; `verify-evidence` and `verify-retry`
  do not exist.
- Exact check: expanded unchanged `tests/test-claude-handoff.sh`.
- Observed result: failed at the first read-only evidence assertion because
  `verify-evidence` is not a recognized subcommand; guarded cleanup succeeded.
- Decision: keep the expanded fixture. Add strict evidence, driver
  reproduction, and retry-record validation without weakening packet checks.

The first post-implementation run passed packet, read-only, mismatch,
forbidden-execution, execution, and missing-reproduction assertions, then
failed because the newly authored broken-sandbox fixture was malformed JSON
before reaching the intended semantic gate. This is a test-fixture defect, not
a production-validator result. Replace only that fixture construction with a
deterministic JSON transformation and rerun the same suite.

After that correction the full fixture passed. A subsequent falsifying
experiment changed the copied staged `TODO.md` after `stage.json` was written;
`verify-evidence` still passed because it compared model-echoed digests to the
manifest without reopening staged bytes. Keep the new stale-stage assertion
and extend verification to current-user-owned, single-link staged files,
including fixed `handoff.json` and prompt paths.

The stale-stage assertion now passes. Before the real no-command model probe,
review found that exact byte counts are unavailable to Claude's Read/Grep/Glob
surface without granting execution and cannot be self-declared for the prompt
without a circular digest. The accepted read-only contract requires the exact
path/digest manifest, while the driver independently reopens staged bytes and
checks those digests. Remove only the redundant model-claimed byte count; retain
all byte identity and freshness enforcement on the driver side.

### Iteration 3 — real native read-only process

- Hypothesis: Claude 2.1.220/Fable/high can consume the sealed packet through
  Read/Grep/Glob in a read-only OS sandbox and emit evidence accepted by the
  new contract without target mutation.
- Before identity: native run `t343-native-readonly-r1`; packet validation
  passed; stage SHA-256
  `4c1dad0726ec0045087070ddca4526f16d6f1dede082f36dbedb0cb86bc5aed9`;
  prompt SHA-256
  `75bc3bc7633d8ec5fc8b940f816260c9ef41d9e5dc916e0e0dcaec61b1079a6a`;
  protected digest manifest sealed externally.
- Exact command surface: native `claude --print --permission-mode dontAsk
  --model fable --effort high --setting-sources project
  --no-session-persistence --tools Read,Grep,Glob --allowedTools Read Grep
  Glob --output-format json --json-schema ...`, inside a read-only `bwrap`
  filesystem.
- Observed result: exit 1 before model execution. Claude rejected the public
  Draft 2020-12 `$schema` URI in the structured-output schema; stdout remained
  zero bytes, protected digests and stage/prompt hashes remained unchanged,
  and no acknowledgement or target action occurred. Exact error SHA-256:
  `d8a1e758a0885d376f7a2457d829c53f27040ef929246fb4e28105670fb743de`.
- Decision: preserve r1 as a pre-model launch-validation failure. Add that
  exact retry outcome to the strict record vocabulary, create a changed
  structured-output schema without unsupported metadata, and use distinct run
  identity r2. Do not replay r1.

Native r2 reached Claude and returned `is_error=false` after 12 turns with
canonical Fable usage and a structured object. The protected manifest and
stage/prompt hashes remained unchanged. Initial driver verification refused
before accepting the evidence because the generic 64 KiB JSON cap was also
applied to staged source files; the required complete `TODO.md` copy is
399,049 bytes. This is a driver-validator limit defect, not a model failure.
Keep packet/evidence/prompt limits bounded, raise only staged source files to
1 MiB, and additionally require staged source names and bytes to match the
packet's live declared source files before revalidating the already returned
r2 evidence. Do not relaunch Claude.

After the narrow source-size correction, the unchanged returned evidence
passed with task `T-343`, run `t343-native-readonly-r2`, authority
`read-only`, six exact read-manifest entries, zero execution records, and zero
driver reproduction records. The validator independently matched every staged
source to the packet's live declared source file and matched the fixed prompt
and packet bytes. Raw native result SHA-256 is
`0f13e3a89e8ed21d3e36c224691b4582633eeb6fa18fb932a017fc791421cf8f`;
structured evidence SHA-256 is
`48d58b093a1e77eb99446a63ee54cf6caa10323cec59cccef0ae5239920dcc6c`.
Claude reported canonical `claude-fable-5` usage, an internal
`claude-haiku-4-5` auxiliary row, 12 turns, no permission denials, and
successful completion. Keep r2 and its tracked structured evidence; the
hypothesis passes without a second model invocation.

The first repository-local slice is retained. The new handoff focused suite,
Cowork, Claude takeover, agent config, client comparison, development
evaluation, fleet-hardening skill, and source-contract suites all pass in
parallel. `git diff --check` and the Python 3.6 syntax parse pass. The
metadata-free native structured schema is intentionally separate from the
canonical public schema, and its constraint remains enforced by the strict
driver validator.

## Deviations

None. The owner `go` matches the frozen plan. No live system, sibling
repository, user setting, hosting setting, credential, process, or deployment
mutation is authorized or attempted.
