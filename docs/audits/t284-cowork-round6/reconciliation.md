# Reconciliation

## Evidence accepted

Both agents confirm NaN passes both ordered-comparison guards. Timeout NaN
propagates through the deadline and sleeps at the finite poll interval forever;
poll NaN reaches `time.sleep(nan)` and raises an unhandled `ValueError`. Positive
and negative infinities are already rejected by existing bounds, but one finite
predicate gives the complete numeric contract. Claude's first candidate falsely
reported the helper absent; exact-path revalidation disproved it, so that stage
was rejected without import. The narrowed retry and reciprocal evidence are the
accepted receipt chain.

## Disagreements and uncertainty

No remaining disagreement. Claude corrected its initial vague suggestion of a
possible busy loop after tracing `remaining` and `min`; Codex's claim was always
the narrower finite-interval infinite wait. Bare `-inf` argparse spelling is
irrelevant because infinities are already outside the documented range.

## Frozen plan

Codex alone imports `math`, adds `math.isfinite` to both existing argument guards
before the first snapshot, and adds two externally bounded CLI tests asserting
concise exit 2 for `nan` timeout and poll values with no traceback. No loop,
status, exit-code, or valid-input behavior changes.

## Acceptance gates

Focused cowork and phase one pass; direct invalid-argument probes return 2 with
the existing messages and no JSON/traceback; Python AST and diff checks pass;
receipts remain valid; the session reaches complete; temporary trees are
guarded-deleted. Owner go is inherited only for this exact frozen refinement.
