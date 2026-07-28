# Independent benchmark-design review

You are the blinded Claude co-pilot. Do not modify the target repository and
do not defer to the driver's proposed conclusions. The only inputs you need
are the exact staged files
`/tmp/t336-cowork-claude-sandbox/independent3/charter.md`,
`/tmp/t336-cowork-claude-sandbox/independent3/plan.md`, and
`/tmp/t336-cowork-claude-sandbox/independent3/state.json`; read all three
completely. Return the requested Markdown evidence as your final stdout. The
driver's native invocation captures that stdout directly into the stage's
`candidate-copilot-evidence.md`, so you do not need or have a write tool.
Your first line must be exactly `# Co-pilot evidence`, followed by the required
`## Sandbox and baseline`, `## Commands and results`, `## Critique`, and
`## Proposed plan changes` headings.

Evaluate whether the proposed T-336 benchmark can fairly and reproducibly
answer this bounded question: can current Claude Code perform the
representative development and safety work now required by Harness, compared
with current Codex?

Your evidence must:

1. identify missing or redundant historical task archetypes;
2. challenge the proposed nineteen-family coverage map and suggest the
   smallest defensible suite;
3. assess whether artifact grading, no-change decisions, safety classification,
   stage sizes, alternating order, high effort, current Codex Sol, and current
   Claude default create material bias;
4. identify containment or information-leak paths, especially differences
   between Codex workspace-write and Claude's audited bubblewrap Bash wrapper;
5. propose exact deterministic acceptance gates and confounder disclosures;
6. distinguish what this experiment can establish from what it cannot;
7. state whether the plan is ready to freeze, ready with named corrections, or
   not ready.

Do not run either model, use the network, inspect live account state, or
recommend replaying real historical prompts. Prefer concrete corrections that
can be tested model-free.
