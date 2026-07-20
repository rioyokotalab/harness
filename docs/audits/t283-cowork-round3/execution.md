# Driver execution

## Steps and results

Codex re-read the ready state, charter, and frozen reconciliation; verified
branch `task/t-283-codex-claude-cowork` at baseline `eb36df2` with only this
declared exchange untracked; and advanced to `executing` before target edits.
It changed only the frozen skill, protocol, helper, focused test, round-3
evidence, and T-283 ledger surfaces.

1. `cowork-session stage` now creates a fresh external independent or reciprocal
   bundle with real/single-link mode-0600 inputs, deterministic path-free
   `stage.json` hashes, a real artifacts directory, and candidate evidence.
2. `import-copilot` validates exact stage shape, roles/phase, copied/manifest/
   current input equality, candidate identity, 64-KiB limit, UTF-8, ordered
   headings, and TODO completion. It writes a mode-0600 temp beside the live
   evidence, fsyncs, atomically replaces only `copilot-evidence.md`, and
   revalidates; post-validation failure restores the prior bytes.
3. The skill and protocol now make blinded independent and reciprocal staging
   the symmetric default, remove live `--add-dir SESSION_DIR` from both native
   templates, retain direct write only as a sealed exception, and state the
   real Codex OS-boundary versus Claude behavioral-policy difference.
4. The focused test exercises deterministic/blinded stage manifests, both
   modes, valid atomic import, stale and tampered inputs, linked/malformed/
   oversized/non-UTF-8 candidates, unexpected stage content, session-contained
   stage refusal, and unchanged live evidence on every refusal.

The canonical skill validator and expanded cowork focused test pass. The revised
helper accepts this live session in `executing` state.

## Deviations

The live round-3 independent and reciprocal candidates were imported manually
before the frozen implementation, because driver execution correctly began only
after the session had advanced from `discussing`; the new importer intentionally
refuses later phases and the state machine cannot move backward. Both manual
imports used the same frozen identity/size/UTF-8/headings/TODO/freshness gates,
changed only the co-pilot evidence, and left protected digests byte-identical.
The new importer was instead exercised end-to-end on synthetic discussing
sessions by the focused test, including its refusal battery. No safety boundary
was weakened to retrofit the completed live discussion.

The first two focused runs after editing failed before the protocol body: one
old wording assertion still expected “Neither may overwrite,” and another
expected an unwrapped staged-import phrase across a line break. Updating those
tests to assert the new content-ownership and `import-copilot` contracts was
retry-safe; the subsequent complete focused run passed.
