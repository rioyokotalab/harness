# Co-pilot (Codex) invocation log (round 4)

Provenance for the two native Codex calls. Full stdout is bounded and retained
in the co-pilot sandbox under each stage's `artifacts/`
(`codex-independent-stdout.txt` ~197 KiB, `codex-reciprocal-stdout.txt`
~363 KiB); only summaries are kept here to stay public-safe and bounded.

## Independent pass

- Blinding: independent stage (`state.json`, `charter.md`, `plan.md` only);
  driver evidence withheld. Stage inside the Codex sandbox, live session path
  not disclosed.
- Staged input SHA-256: charter `168d6f5f…`, plan `375da1d0…`,
  state `d86dd35f…` (this round staged raw state under the pre-fix helper — the
  disclosure artifact under study).
- First call (documented mapping): `codex --ask-for-approval never exec
  --ephemeral --sandbox workspace-write --cd /tmp/harness-t283-round4-codex
  --output-last-message <stage>/candidate-copilot-evidence.md -` on stdin.
  Timed out at 10 min at high reasoning effort; candidate file unchanged
  (retry-safe), live session untouched, no import performed.
- Narrower retry (identical sandbox/approval; reasoning effort lowered to
  medium for speed only): `codex -c model_reasoning_effort="medium"
  --ask-for-approval never exec --ephemeral --sandbox workspace-write --cd
  /tmp/harness-t283-round4-codex --output-last-message
  <stage>/candidate-copilot-evidence.md -`. Exit 0.
- Import: `cowork-session import-copilot` accepted the candidate,
  sha256 `83d6f30f…`; protected digests unchanged pre/post window
  (`pre-independent.digests` == `post-independent.digests`).

## Reciprocal pass

- Reveal: reciprocal stage adds both evidence files
  (driver `6f876e97…`, co-pilot `83d6f30f…`).
- Call (medium effort, identical confinement) resolved as above against the
  reciprocal stage. Exit 0.
- Import: `cowork-session import-copilot` accepted the revised candidate,
  sha256 `0a0e901f…` (the current live `copilot-evidence.md`); protected
  digests unchanged pre/post window
  (`pre-reciprocal.digests` == `post-reciprocal.digests`).

## Integrity note

Both retained candidate files later lost their trailing newline and are
otherwise byte-identical to the bytes imported from them: independent is 12404
instead of 12405 bytes, and reciprocal is 15657 instead of 15658. This did not
touch live or protected bytes. The exact independent import (`83d6f30f…`, with
the newline) is preserved as the reciprocal stage's `copilot-evidence.md` and
pinned in that stage's input manifest. The exact reciprocal import
(`0a0e901f…`, with the newline) is the current live evidence and its hash was
recorded at import, but the v4 stage manifest does not pin candidate bytes.
Every import validated candidate bytes before replacement, and protected-entry
digests compared clean around both windows. This post-import drift exposes the
next protocol question: whether import should write a driver-held receipt that
binds candidate hash, import result, and source-stage input hashes independently
of the still-writable stage (hashes detect change; they do not prevent it).
