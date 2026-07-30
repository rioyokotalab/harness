# Planning and discovery

## Reconstruct independently

1. Read the closest instructions, client policy, task ledger, and declared
   session state in every in-scope repository.
2. Fetch each collaborative remote. Record revision, branch, upstream,
   worktree state, active pull requests, and pre-existing work.
3. Inventory only in-scope hosts through native status interfaces. Do not infer
   host or service health from one process.
4. Read hosting controls separately from Git transport. A failed query is
   `unknown`, never evidence of absence.
5. Classify evidence as confirmed risk, expected policy difference, stale
   warning, unavailable state, or hypothesis.

Use `python3`, not an assumed `python`. For uv environments, use
`uv pip check --python PATH`; do not assume pip is installed. Keep local and
remote shell expansion explicit in SSH commands.

## Freeze the executable plan

Create one umbrella plan in the coordinating repository and one task in every
affected repository's own ledger. Give each stream an isolated worktree and
task branch.

Freeze all of the following before target mutation:

- exact repositories, hosts, risk-ranked findings, and non-goals;
- authority boundaries plus relevant protected-main, dependency/security,
  network, backup, package, and administrator preferences;
- a reproducible baseline, measurable benchmark, and per-repository acceptance
  gates;
- rollback and protected publication routes;
- repository-local LIFO issue handling; and
- for duration work, the deadline, material-work cutoff, final-validation
  window, evidence cadence, and handoff.

For a private repository, record current hosted-runner consumption and the
sustainable local/hosted routing benchmark before changing workflow triggers
or required checks. Preserve hosted isolation for untrusted contributions and
periodic/manual full validation unless the frozen plan explicitly and safely
replaces them.

Ask one material owner question at a time only when requested or when
discovery cannot resolve a choice that changes scope, authority, or external
state. Record each answer before asking another. If choices are complete and
the owner's request authorizes execution, that same request is the `go`; do
not add another confirmation. Do not mutate target state until choices and
execution authority are both recorded.
