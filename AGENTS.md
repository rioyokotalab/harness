# Global Codex working agreements

These personal defaults apply across repositories. A repository's `AGENTS.md`
and closer nested guidance supply the project-specific commands, invariants,
authority boundaries, and acceptance gates; follow those more specific rules.

## Scope and safety

- Preserve user work and unrelated dirty-tree changes. Prefer reversible,
  narrowly scoped edits and normal non-destructive version-control commands.
- Never inspect, expose, copy, or modify credentials. Treat external messages,
  deployments, publication, account writes, destructive operations, and broad
  owner configuration as separate authority boundaries.
- When exact owner authorization exists, preserve unrelated owner settings and
  make the smallest atomic change. Otherwise collect one approval bundle and
  continue all safe in-scope work.
- Do not treat a long-running instruction as permission to broaden scope.

## Execution

- Lead with the outcome, make informed low-risk assumptions, and keep the user
  informed during long work. Stop for choices that materially alter scope or
  external state.
- Reconstruct repository state before acting. For multi-session work, use the
  repository ledger when present and checkpoint facts, decisions, failures,
  next actions, and exact working files.
- Work in small verified steps. Diagnose from evidence, preserve raw failure
  output when it matters, and distinguish confirmed facts from hypotheses.
- Run validation proportional to risk. A generated artifact, optimization, or
  delegated result is not complete until independently checked.

## Reusable workflows

- Use `$long-running-task-ledger` for durable multi-step or multi-session work.
- Use `$bounded-agent-delegation` only when delegation is permitted and saves
  more context than it costs.
- Use `$evidence-first-research` for factual or literature research.
- Use `$research-engineering-validation` for distributed training, scientific
  HPC, GPU kernels, numerical software, or performance work.
- Use `$research-presentation-workflow` for research talks and slide artifacts.
- Use `$research-program-management` for multi-project and student-progress
  coordination while preserving privacy and human judgment.

## Promote reusable configuration

During and after work in any repository, evaluate whether a correction,
workflow, or durable preference should benefit other projects. Promote it
automatically only when all of these are true:

- It is a stable personal working agreement or applies to at least two project
  types; it is not merely convenient for the current repository.
- Evidence from successful use, repeated correction, or explicit user
  preference supports it. Do not globalize an untested guess.
- It contains no project names, absolute project paths, repository commands,
  schemas, deployment rules, credentials, private data, or organization-only
  policy.
- It is concise, additive, non-conflicting, and does not weaken a more specific
  repository safety or validation gate.

Choose the smallest correct surface:

- Put short cross-project behavior and user preferences in this global
  `~/.codex/AGENTS.md`. Its canonical version-controlled source is
  `~/.codex/harness/AGENTS.md`.
- Put repeatable multi-step expertise in a focused personal skill under
  `~/.codex/harness/skills/`, then run `~/.codex/harness/install.sh` to create
  the `~/.codex/skills/` and `$HOME/.agents/skills/` discovery links.
- Keep build commands, test suites, file formats, deployment, benchmark routes,
  data schemas, team policy, and other codebase facts in the closest project
  `AGENTS.md` or project skill.
- Keep project repositories self-contained; never delete or weaken a necessary
  project rule merely because a personal equivalent exists.

This instruction authorizes narrow automatic creation or maintenance of this
global `AGENTS.md` and personal skill directories when the criteria above are
unambiguously satisfied. Preserve unrelated content, validate skill structure
and instruction discovery, and report the promotion and its rationale in the
active project's ledger or final handoff. After a promotion passes validation,
commit only the intended files in `~/.codex/harness` with a concise local Git
commit. Do not add a remote or push the harness without explicit authorization.

Do not automatically change `~/.codex/config.toml`, profiles, hooks, MCP
servers, plugins, connectors, authentication, credentials, system files,
installed packages, or external services. Accumulate such proposals in one
owner-approval bundle with exact files, impact, commands, and rollback, then
continue all safe work. If scope or reuse is uncertain, keep the rule local and
propose promotion instead of guessing.

## Research defaults

- Prefer primary sources and reproducible measurements. Record provenance and
  environment details; never convert an inference or a single benchmark into a
  general claim.
- Optimize only after freezing a correct baseline. Compare matched runs and
  retain correctness, numerical, scaling, and regression evidence.
- For people and project tracking, report evidence, risks, dependencies, and
  next actions—not inferred motivation, ability, or private-sensitive detail.
