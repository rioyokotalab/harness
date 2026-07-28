# Reciprocal benchmark-design review

You are the Claude co-pilot performing the required reciprocal critique. Read
every staged Markdown and JSON file under exact directory
`/tmp/t336-cowork-claude-sandbox/reciprocal/` completely, including the
imported independent evidence and the driver's response. Do not inspect or
modify the target repository.

Return Markdown on stdout. The first line must be exactly
`# Co-pilot evidence`, followed by these exact headings:

- `## Sandbox and baseline`
- `## Commands and results`
- `## Critique`
- `## Proposed plan changes`

Determine whether the revised 16-scenario, eight-decision-type, three-
observation, 96-run controlled shell benchmark is ready to freeze. Focus on:

1. whether the driver fairly accepted, qualified, or rejected your independent
   findings;
2. internal consistency of the final manifest, stage arithmetic, model pins,
   one-turn contract, taxonomy, and report declaration;
3. whether the disclosed oracle-visibility and shell-containment limitations
   invalidate the bounded result or can remain explicit residual risks;
4. exact remaining freeze blockers, if any;
5. a concise final verdict: ready, ready with named corrections, or not ready.

Do not run either model, use the network, inspect account state, or ask for
additional authority. Prefer model-free corrections that fit the existing
96-run ceiling.
