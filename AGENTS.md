# Global agent working agreements

These working agreements and the harness-specific rules at the end of this
file apply to Codex and Claude when they are started from this repository.

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
- The owner grants standing authorization for ordinary Git operations within
  the active task scope, including fetch/pull, branch creation, commits,
  merges, rebases, pushes, and task pull-request creation or merge. Continue to
  apply all preflight, preservation, collaboration, and no-force-push rules;
  this does not authorize hosting settings or administration, workflow
  dispatch, deployments, external messages, destructive cleanup, or credential
  access.
- Do not treat a long-running instruction as permission to broaden scope.
- Never issue agent-directed raw recursive or bulk deletion (`rm -r`, `rm -rf`,
  `find -delete`, deletion loops/globs, `rsync --delete`, or equivalents), or
  hide it in a script under agent control. Use the `guarded-bulk-delete` skill
  and its deterministic plan/apply tool. This is an autonomous safety gate, not
  an approval gate: proceed without asking when its boundary, manifest,
  revalidation, and post-delete checks pass. Single exact non-recursive file
  removal and patch-based tracked-file deletion remain allowed.
- A reviewed vendor installer or trusted package manager may perform its own
  internal recursive cleanup only through the exception defined by the
  `guarded-bulk-delete` skill: obtain exact bytes from an official HTTPS source
  instead of piping remote code to a shell; review syntax, destructive
  primitives, and target derivation; use explicit non-interactive destinations;
  confine deletion to declared package-owned release/cache/staging/temp roots;
  exclude account-home roots, repositories, workspaces, credentials, backups,
  and unrelated user data; execute the exact reviewed artifact; and verify
  installed state and residue afterward. Ambiguity falls back to guarded
  deletion. Owner approval alone never creates an exception.

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

## Routine housekeeping

- When the owner requests routine housekeeping, include a read-only inventory
  of `$CODEX_HOME/tmp/arg0` when present. A held `.lock` is live; never remove
  the whole root or require every Codex process to exit.
- Candidates must be current-user-owned real directories past a grace period
  or from an observed completed invocation, and either empty without a lock or
  expected-layout with an acquirable lock. Quarantine while locked, then
  guarded-delete.
- Report live, eligible, removed, and unexpected counts. If fresh invocations
  recreate residue, separate housekeeping from any vendor-launcher fix, which
  always requires explicit authority.

## Reusable workflows

At every task start, actively compare the request and repository guidance
against the installed shared skills and workflows. Read every matching skill
completely and apply each applicable one by default, including its planning,
ledger, validation, and handoff gates; do not invoke irrelevant workflows.
Closer project rules stay authoritative, and project repositories remain
operationally self-contained: skills guide the agent's working method and
never become project runtime dependencies.

- Whenever applying a skill, explicitly name that skill in user-facing
  commentary before its first skill-directed action and state why it applies.
  Name each applicable skill separately; if a skill later causes an external
  action or pause, identify it again at that point.

- Use the `long-running-task-ledger` skill for durable multi-step or
  multi-session work.
- Use the `plan-interview-execute` skill for consequential, ambiguous, or
  multi-session work that needs owner decisions frozen before execution.
- Use the `bounded-agent-delegation` skill only when delegation is permitted
  and saves more context than it costs.
- Use the `evidence-first-research` skill for factual or literature research.
- Use the `research-engineering-validation` skill for distributed training,
  scientific HPC, GPU kernels, numerical software, or performance work.
- Use the `operate-native-hpc` skill for scheduler, allocation, distributed
  run, and matched performance work on the managed HPC targets.
- Use the `onboard-mirrored-node` skill when the owner adds a new SSH alias
  and asks to mirror the existing control plane.
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

- Put short cross-project behavior and user preferences in this repository's
  root `AGENTS.md`, where root `CLAUDE.md` imports it so Codex and Claude
  receive one consistent policy while working in `~/harness`.
- Put repeatable multi-step expertise in a focused personal skill under
  `~/harness/shared/skills/`, then create the corresponding project discovery
  links in `.agents/skills/` and `.claude/skills/`.
- Keep non-secret product-specific examples under `~/harness/.codex/` or
  `~/harness/.claude/`. Live product settings remain outside the repository.
- Keep build commands, test suites, file formats, deployment, benchmark routes,
  data schemas, team policy, and other codebase facts in the closest project
  `AGENTS.md`, `CLAUDE.md`, or project skill.
- Keep project repositories self-contained; never delete or weaken a necessary
  project rule merely because a personal equivalent exists.

This instruction authorizes narrow automatic creation or maintenance of this
project guidance and project skill directories when the criteria above
are unambiguously satisfied. Preserve unrelated content, validate skill
structure and instruction discovery in affected clients, and report the
promotion and its rationale in the active project's ledger or final handoff.
After a promotion passes validation, commit only the intended files in
`~/harness` with a concise local Git commit. Do not change remotes.

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

# Harness repository instructions

## Start and resume

- Treat Git and `TODO.md` as the durable source of truth. Do not rely on a
  previous Codex or Claude conversation, client auto-memory, or an uncommitted
  recollection of external state.
- Before changing anything, read the applicable instructions and `TODO.md`,
  inspect the current branch and working tree, fetch the collaborative remote,
  and reconstruct the exact next action and blockers.
- Resume only the recorded task. Revalidate scheduler, hosting-service, and
  other mutable external state before acting; a failed query is unknown state,
  not evidence of absence.
- Use `docs/fleet-inventory.md` as the cold-start reference for logical aliases,
  SSH entries, usernames, hostnames, and operating systems.
- In compact fleet-health reports, count `abq` as a Linux node and mark it
  ready only when both `abq` and `abq2` routes pass. Count only aist, home,
  office, and riken in the Mac-route total.

## Change and validation

- Keep this repository independent of the sibling `website` repository. Do not
  import its scripts, CI, policy files, artifacts, or working-tree state.
- Add focused tests for changed behavior and run `tests/test-phase1.sh` before
  merge. Documentation-only work must at least pass `git diff --check` and the
  relevant focused test; protected CI remains authoritative.
- Publish through the protected `main` workflow without force-push. After a
  merged control-plane change, use guarded `harness fleet-sync` plan/apply to
  synchronize only clean managed checkouts.
- After a successful fleet sync advances a managed Mac checkout, queue exactly
  one context-refresh instruction in its running `harness-codex-resume`
  session. Require one detached live session with one Codex pane rooted at
  `$HOME/harness`; never inspect pane contents, interrupt work, or respawn the
  process. The instruction must tell Codex to read `AGENTS.md` and `TODO.md`
  completely, inspect the branch, worktree, and recent commits, and reconcile
  its next action with the durable task ledger before continuing. If the
  session is absent, attached, or ambiguous, do not inject input: report the
  refresh as deferred and retry at the next safe opportunity.
- On a managed personal Mac, treat `~/harness` as the live tunnel-control
  checkout: keep it on clean `main` and perform feature work in a separate Git
  worktree. The watchdog tolerates unrelated branch/worktree state, but any
  difference in its runtime-critical scripts or public Mac profile inputs must
  continue to fail closed.

## Handoff

- Before yielding unfinished work, update `TODO.md` with verified results,
  exact identifiers, failures and retry safety, modified files, completed and
  remaining checks, the next executable action, and any authority boundary.
- Keep bulky reproducible evidence in Git-tracked artifacts and link to it from
  the ledger. Never put credentials, private environment values, or chat-only
  assumptions in a handoff.
