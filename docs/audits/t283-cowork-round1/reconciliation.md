# Reconciliation

## Evidence accepted

Both agents independently observed that the v1 validator accepts unexpected
top-level files and symlinked protocol files. Claude additionally proved that
the documented reverse mapping is misordered: `codex exec
--ask-for-approval never --help` exits 2. Both agents then reproduced the safer
form `codex --ask-for-approval never exec --help` with exit 0, preserving an
explicit non-prompting policy. Matched reciprocal probes also showed that a
closed top-level set with a real `artifacts/` directory accepts the intended log
case while rejecting the observed provenance and symlink failures.

## Disagreements and uncertainty

Claude initially preferred documenting rather than closing the extra-file gap;
its reciprocal matched trace withdrew that preference in favor of enforcement.
The driver preferred narrowing the TODO claim rather than expanding the regex;
Claude accepted this because only untouched standalone template markers are an
intended mechanical gate. Claude flagged a possible atomic-state temp file as a
false positive. Reconciliation treats a leftover or concurrently visible temp
file as evidence of an interrupted/concurrent state update and intentionally
rejects it; normal `os.replace` completes before the next single-process check.
No blocking disagreement remains. Filesystem authorship and confinement below
`artifacts/` remain explicitly non-mechanical review obligations.

## Frozen plan

Codex remains the only target-writing role. The owner's original instruction is
the go for these exact changes:

1. Make `cowork-session` preserve the lexical session path long enough to reject
   a symlinked root, and require current-user ownership plus real directory/file
   identity for the root, `artifacts/`, `state.json`, and all protocol Markdown.
2. Initialize a mode-0700 `artifacts/` directory. At every check/advance, require
   the exact known top-level set and reject every extra or missing entry,
   including interrupted atomic temp residue. Do not inspect or claim mechanical
   confinement of artifact contents.
3. Correct the Claude-driver mapping to place the global approval option before
   the subcommand: `codex --ask-for-approval never exec ...`.
4. Restrict `has_todo` to standalone initialized TODO marker lines
   (`^\s*TODO\s*$`), accurately narrow the reference claim to that behavior,
   state that authorship and nested artifact confinement remain review gates,
   and document the real-directory artifact contract. This became required when
   the first ready transition safely rejected Claude's legitimate wrapped prose
   line beginning `TODO marker`; Claude must repair its owned file before retry.
5. Extend the focused test with unexpected-file, symlinked state/protocol/root/
   artifacts, exact-set, both-role, and gated installed-client parse probes.
6. Add the required real `artifacts/` directory to this self-hosting session,
   run the revised validator, and record every target edit and check.

Rejected changes: deleting the explicit approval policy, silently relying on
Codex exec defaults, merely softening the unsupported-file claim, or broadening
the TODO regex to reject legitimate evidence discussions.

## Acceptance gates

The revised adversarial focused test and canonical quick validator must pass.
Both documented mapping commands must pass help-only parsing when their clients
are installed, while the old misplaced Codex form must fail. This round's
exchange directory must pass the revised state validator after adding only the
declared `artifacts/` directory. Claude takeover, source contract,
public-repository audit, `git diff --check`, and full `tests/test-phase1.sh` must
pass. Final diff review must show no credential/private content, settings,
remotes, package state, or non-driver target mutation.
