# Execution and validation phase

After an explicit go, reconstruct the frozen plan and decisions from disk
before changing the target. Do not depend on the interview remaining in
context.

1. Set `executing` and record the exact first step.
2. Work in small ordered steps, applying any domain or safety skills and native
   commands required by the environment.
3. Before each material step, revalidate its target, authority, preconditions,
   and relevant drift. Run its planned acceptance check afterward.
4. Immediately checkpoint results, evidence pointers, changed files or state,
   and the exact next action. Preserve failures verbatim when safe, say whether
   retry is safe, and identify what remained unchanged.
5. Continue autonomously through settled choices. Stop only for a new material
   choice, failed safety gate, missing authority, contradiction, or external
   blocker, and record the resulting status.
6. Keep the owner informed at the requested cadence during long work; progress
   messages never replace ledger checkpoints.

When implementation ends, set `validating` and run every planned end-to-end,
regression, safety, cleanup, and state-consistency check. Independently inspect
the actual diff or external state; generation by itself is not acceptance.

Mark `complete` only after all acceptance gates pass and no required work
remains. Record commits, unpushed state, excluded external actions, and
remaining proposals. Leave a restartable handoff containing the outcome,
modified surfaces, checks, residual risks, and exact next action.
