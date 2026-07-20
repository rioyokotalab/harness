# Reconciliation

## Evidence accepted

- Both detached worktrees matched baseline `4c3602d`; both focused-suite runs
  passed, both native-role directions were exercised by Claude in scratch, and
  no repository edit occurred during discussion.
- The external-seal happy path, both role identities, phase-skip refusals,
  path-free stage/seal/receipt structures, receipt chaining, schema-1 receipt
  compatibility, schema-2 direct isolation, and native CLI mappings were all
  confirmed by matched execution or static trace.
- Claude reproduced the documented nested-stage weakening: when a caller
  violates the direct-child precondition, the stage parent is narrower than the
  real sandbox root. This is a real residual, not a defect in the declared
  direct-child workflow.
- Both agents confirmed that `verify-receipts` validates the stored seal digest
  and evidence chain but deliberately cannot find/reopen an external path-free
  seal. A manual retained-byte comparison detects later seal changes.
- Both agents confirmed that the helper rejects phase skips but cannot govern
  arbitrary repository editors. Round 6's out-of-order edit remains a process
  violation, not something a token file would mechanically prevent.

## Disagreements and uncertainty

The independent Claude pass initially called the protocol's co-pilot-root text a
promise of an unimplemented option and proposed either an optional
`--copilot-root` or wording change. The reciprocal pass reread and experimentally
traced the exact surface: the protocol says callers who cannot meet the
direct-child precondition should *extend* the helper, while argparse offers no
such current flag. We accept the reciprocal correction—this is future-design
guidance, not a false availability claim—and reject release-candidate churn.

Claude also proposed a `verify-receipts` output caveat, then withdrew it after
reciprocal review because the green output is accurately scoped to the receipt,
the limitation is already explicit in both skill and protocol, and new output
would add no enforcement. No material disagreement remains.

Named environment residual: this session used Claude as co-pilot. Claude's tool
permissions and staging reduce disclosed/writable scope but are not an OS
filesystem sandbox; a reachable same-UID external seal is therefore protected
by placement and behavior, unlike Codex workspace-write confinement. Both
pre/post seal hashes and protected manifests matched here. Do not generalize
that observed compliance into cryptographic authorship or OS confinement.

## Frozen plan

1. Make no live skill, helper, protocol, or test change. The release candidate
   passed the targeted audit and neither proposed addition improves enforcement
   enough to justify a late compatibility surface.
2. Advance through the phase machine in order. Before any execution record is
   written, re-read state/charter/this frozen plan, confirm the live target has
   no unrelated drift, validate both receipts, then advance to `executing`.
3. In `executing`, record the no-code disposition and the matched evidence. Do
   not reinterpret a no-code outcome as permission for opportunistic edits.
4. Advance to `validating`; run the focused cowork suite, source-contract,
   Claude takeover, public-repository audit, `git diff --check`, live session
   check/receipt verification, installed discovery-link identity, and the clean
   full Phase 1 suite after checkpoint.
5. Advance to `complete` only after every gate passes. Update `TODO.md`, commit
   the round-7 exchange, and use guarded deletion for the two worktrees, both
   stages/seals, and Claude's labeled scratch roots.

Disposition table:

| Proposal | Decision | Evidence |
| --- | --- | --- |
| Automatic retained-seal reopen | Reject | No durable path is stored; receipt already binds digest; both evidence files |
| Target-write phase token | Reject as false enforcement | Helper cannot govern arbitrary editors; driver probe and Claude probe 6 |
| Add `--copilot-root` now | Reject | Declared direct-child workflow passes; reciprocal probes 2, 3, and 5 |
| Reword co-pilot-root guidance | Reject | Text explicitly says to extend in the future; no false current option |
| Add receipt-output caveat | Reject | Limitation already documented; no assurance gain; reciprocal probe 4 |
| Preserve named Claude boundary | Accept | Claude independent critique and reciprocal confirmation |

## Acceptance gates

- Both independent and reciprocal receipts must remain valid and match the live
  co-pilot evidence.
- Protected and stage/seal pre/post digests must match; any mismatch stops.
- Only the tracked round-7 exchange and ledger may change; skill/runtime files
  remain byte-identical to `4c3602d`.
- All focused/repository tests in frozen step 4 pass, including a clean full
  Phase 1 run.
- Scratch cleanup uses guarded deletion with exact roots and unchanged protected
  anchors. Owner go is already present in the original request to execute after
  cowork planning, but only for this frozen no-code audit scope.
