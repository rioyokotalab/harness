# Driver execution

## Steps and results

Codex re-read the ready state, charter, and frozen reconciliation; verified the
target branch at baseline commit `35ed1db` with only this declared exchange
directory untracked; and advanced the session to `executing` before target
edits. It then changed only the frozen surfaces:

1. `cowork-session` now checks lexical root identity, current-user ownership,
   real file/directory types, an exact top-level set, and a real `artifacts/`
   directory; initialization creates that directory; TODO matching is exact to
   standalone placeholder lines.
2. `protocol.md` now describes those mechanical and non-mechanical limits and
   orders the Codex global approval flag before `exec`.
3. The focused test now probes both roles, exact phase order, the prose TODO
   false-positive regression, unexpected files, symlinked protocol/state/root/
   artifact paths, and both installed native help mappings.
4. This session gained the required real `artifacts/` directory with one bounded
   public-safe client-status record.

The canonical skill validator passed. The revised focused test passed, and the
revised validator accepted this live session in `executing` state.

## Deviations

The first focused-test invocation after rewriting the test exited 126
(`Permission denied`) because patch-based replacement reset its executable bit.
It executed no test body and changed no state. Restoring the already-reviewed
file to mode 0755 was retry-safe; the immediate rerun passed. No frozen behavior,
authority boundary, or target scope changed.
