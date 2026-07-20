# Initial plan

## Confirmed facts and assumptions

Confirmed by reading the helper at baseline `9fed369`: `stage_session` copies
each name in `STAGE_INPUTS[mode]`, which begins with `state.json`, verbatim into
the stage and records its SHA-256 in `stage.json`. `predecessor_record` writes
`predecessor.path = str(pred_root)` (an absolute path) into `state.json`, so a
predecessor session's own path is embedded in the successor state that staging
then copies. `import_copilot` re-reads the live `state.json` and requires the
staged copy to be byte-identical, so any transform applied to the staged
`state.json` must also be applied to the comparison, or freshness binding
breaks. Confirmed: `predecessor_record` calls `load_state` (layout + phase +
role checks) but never `validate_files(pred_root, pred_state["phase"])`, so a
predecessor's phase-required Markdown is not checked at snapshot time.

Assumption to test: a bounded, deterministic redaction/projection of the staged
`state.json` (or a decision to stage a path-free projection) can remove absolute
paths the co-pilot does not need while keeping freshness binding meaningful; and
adding a phase-content check inside `predecessor_record` closes the provenance
gap without breaking legitimate takeover. These are confidentiality and
integrity refinements, not a claim that a same-user co-pilot is an adversarial
OS boundary.

## Steps

1. Independently reproduce Hypothesis 1: init a synthetic successor session with
   a predecessor in the sandbox, stage it, and show the staged `state.json` and
   `stage.json` contain an absolute predecessor path. Show a no-predecessor
   session stages without such a path, isolating the disclosure to the
   predecessor block.
2. Independently reproduce Hypothesis 2: build a synthetic predecessor whose
   `state.json` says `complete` but whose `charter.md` still holds a template
   `TODO`, then `init --predecessor` against it and show it is accepted and the
   inconsistent phase is snapshotted. Compare against `check`/`advance`, which do
   validate phase content, to show the asymmetry.
3. Inspect adjacent atomicity/disclosure issues only if evidence points to them
   (e.g. whether `stage.json` input hashes would still bind a redacted
   `state.json`, whether redaction must be reflected in the live comparison).
4. Design the minimal deterministic fix for each: for disclosure, a
   path-free projection of the copied `state.json` bound by its own hash so
   `import-copilot` stays consistent; for provenance, a `validate_files` check in
   `predecessor_record`. Confirm neither breaks existing tests conceptually.
5. Stage an independent bundle inside the Codex sandbox, invoke real Codex to
   reproduce/falsify both hypotheses and criticize the strongest fix claim,
   import the validated candidate. Then stage a reciprocal bundle exposing both
   evidence files and invoke Codex again to challenge the strongest claim.
6. Reconcile on reproduced evidence. Freeze only narrow changes improving
   confidentiality, integrity, atomicity, provenance, or symmetry; preserve
   disagreements and rejected proposals. Add adversarial tests. Execute as
   driver against the live target; do not commit.

## Evidence questions

- Does a staged `state.json` from a `--predecessor` session actually contain an
  absolute predecessor path, and is that path unnecessary for co-pilot work?
- Would a path-free projection of the staged state still support freshness
  binding at import (i.e. can the projection be hashed and compared
  deterministically), or does it break the live-vs-staged equality check?
- Does `init --predecessor` accept a phase/content-inconsistent predecessor, and
  is a `validate_files` check the minimal fix that does not break valid takeover?
- Do the fixes preserve blinding, the reciprocal full-file round trip, the
  refusal battery, hard-link/takeover/state/mapping tests, and atomicity?
- Which limits are mechanical and which remain same-user behavioral policy?

## Risks and recovery

Changing what staging copies could silently break the import freshness check;
mitigate by binding the projection to its own hash and by testing a full
round-trip import after the change. A phase-content check in `predecessor_record`
could reject a legitimate predecessor whose files were correct; mitigate by
testing takeover against a genuinely valid predecessor. A model call changes only
its sandbox and is retry-safe after inspection. A failed live import must leave
the session byte-identical. All sandboxes and stages remain for guarded cleanup;
the live target is edited only by the driver after the plan is frozen.
