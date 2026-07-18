# Global agent working agreements

These personal defaults apply across repositories and agent clients. A
repository's `AGENTS.md`, `CLAUDE.md`, and closer nested guidance supply the
project-specific commands, invariants, authority boundaries, and acceptance
gates; follow those more specific rules.

## Scope and safety

- Preserve user work and unrelated dirty-tree changes. Prefer reversible,
  narrowly scoped edits and normal non-destructive version-control commands.
- Never inspect, expose, copy, or modify credentials. Treat external messages,
  deployments, publication, account writes, destructive operations, and broad
  owner configuration as separate authority boundaries.
- At the owner's standing request, an agent may execute and exact-unlink
  `~/run_this.sh` after reviewing that it embeds and prompts for no credential
  and passes an existing credential only by file path to its intended
  application. Redirect potentially private application output to an unread
  mode-0600 temporary log and remove it exactly after success; this never
  authorizes reading, printing, hashing, or copying credential contents.
- When exact owner authorization exists, preserve unrelated owner settings and
  make the smallest atomic change. Otherwise collect one approval bundle and
  continue all safe in-scope work.
- Do not treat a long-running instruction as permission to broaden scope.
- Never run raw recursive or bulk deletion (`rm -r`, `rm -rf`, `find -delete`,
  deletion loops/globs, `rsync --delete`, or equivalents). Use the
  `guarded-bulk-delete` skill and its deterministic plan/apply tool. This is an
  autonomous safety gate, not an approval gate: proceed without asking when
  the canonical boundary, explicit targets, manifest, revalidation, and
  post-delete checks all pass. Single exact non-recursive file removal and
  patch-based tracked-file deletion remain allowed.

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
- For an owner-authorized collaborative repository, fetch before starting work
  and again before pushing, integrate non-conflicting contributor commits, and
  push small verified commits promptly instead of accumulating a long local
  queue. Never force-push or overwrite ambiguous remote work.
- Treat authenticated Git transport and hosting-service API or administration
  access as separate capabilities. Preflight and report them independently;
  never infer API or settings authority from a successful fetch or push.
- When an intended Git or SSH command needs agent authentication, require its
  `SSH_AUTH_SOCK` to name a current-user-owned Unix socket. If the process
  socket is unusable under tmux, recover only from the current tmux session's
  exact `SSH_AUTH_SOCK`, then from a host-declared fixed agent socket; never use
  tmux's global environment. Bind a recovered socket only to the intended
  command and otherwise fail closed. Never list, inspect, copy, or request SSH
  keys or passphrases.
- When an agent executes through a platform CLI, prefer recognizable native
  commands over opaque convenience wrappers so plans and reports expose what
  actually ran. Keep portability mapping in the workflow and report the
  resolved native command.

## Reusable workflows

- Use the `long-running-task-ledger` skill for durable multi-step or
  multi-session work.
- Use the `bounded-agent-delegation` skill only when delegation is permitted
  and saves more context than it costs.
- Use the `evidence-first-research` skill for factual or literature research.
- Use the `research-engineering-validation` skill for distributed training,
  scientific HPC, GPU kernels, numerical software, or performance work.
- Use the `research-presentation-workflow` skill for research talks and slide
  artifacts.
- Use the `research-program-management` skill for multi-project and
  student-progress coordination while preserving privacy and human judgment.
- Use the `guarded-bulk-delete` skill before any command can recursively delete
  a tree or expand deletion to multiple paths.

## Cross-client handoff

- Make unfinished work resumable from the repository alone. Git, the closest
  instruction files, and the declared task ledger are authoritative; chat
  history, client summaries, and Claude auto-memory are optional context only.
- At takeover, inspect the branch, working tree, recent commits, ledger, and
  mutable external state before continuing. Resume the recorded next action
  rather than reconstructing intent from conversation.
- At handoff, record verified results, exact identifiers, failures and retry
  safety, modified files, validation already run, remaining checks, the next
  executable action, and any authority required.

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

- Put short cross-project behavior and user preferences in this shared global
  guidance. Its canonical version-controlled source is
  `~/harness/.codex/AGENTS.md`; `~/harness/.claude/CLAUDE.md` links to the same
  content so Codex and Claude receive one consistent policy.
- Put repeatable multi-step expertise in a focused personal skill under
  `~/harness/shared/skills/`, then run `~/harness/install.sh` to create the
  Codex and Claude discovery links.
- Keep non-secret product-specific examples under `~/harness/.codex/` or
  `~/harness/.claude/`. Live product settings remain outside the repository.
- Keep build commands, test suites, file formats, deployment, benchmark routes,
  data schemas, team policy, and other codebase facts in the closest project
  `AGENTS.md`, `CLAUDE.md`, or project skill.
- Keep project repositories self-contained; never delete or weaken a necessary
  project rule merely because a personal equivalent exists.

This instruction authorizes narrow automatic creation or maintenance of this
shared global guidance and personal skill directories when the criteria above
are unambiguously satisfied. Preserve unrelated content, validate skill
structure and instruction discovery in affected clients, and report the
promotion and its rationale in the active project's ledger or final handoff.
After a promotion passes validation, commit only the intended files in
`~/harness` with a concise local Git commit. Do not change remotes or push the
harness without explicit authorization.

Do not automatically change `~/.codex/config.toml`,
`~/.claude/settings.json`, profiles, hooks, MCP servers, plugins, connectors,
authentication, credentials, system files, installed packages, or external
services. Accumulate such proposals in one owner-approval bundle with exact
files, impact, commands, and rollback, then continue all safe work. If scope or
reuse is uncertain, keep the rule local and propose promotion instead of
guessing.

## Research defaults

- Prefer primary sources and reproducible measurements. Record provenance and
  environment details; never convert an inference or a single benchmark into a
  general claim.
- Optimize only after freezing a correct baseline. Compare matched runs and
  retain correctness, numerical, scaling, and regression evidence.
- For people and project tracking, report evidence, risks, dependencies, and
  next actions—not inferred motivation, ability, or private-sensitive detail.
