# Driver evidence

## Sandbox and baseline

- Harness driver sandbox: `/tmp/t342-codex-box/harness`, detached clean
  `5276ddf41fba20d0ab299608db587f1fa2a563da`.
- Students driver sandbox: `/tmp/t342-codex-box/students`, detached
  `1376690`; `uv sync --frozen` created only its disposable `.venv`.
- Target task worktrees remained unchanged during discussion.
- The Students T-031/T-033 durable archive identifies D-016
  (scope-to-capability enforcement) and D-017 (cross-task session reuse) as the
  unresolved Claude-relevant findings.

## Commands and results

- `claude --version` returned `2.1.220 (Claude Code)`.
- Installed `claude --help` accepts model aliases including `fable`, names
  full model `claude-fable-5`, and accepts `--effort high`; project-setting
  behavior remains to be measured after the candidate settings exist.
- Harness baseline:
  `tests/test-codex-claude-cowork-skill.sh &&
  tests/test-agent-config.sh && tests/test-claude-takeover.sh` passed.
- Students first focused command
  `uv run --frozen --no-sync pytest -q tests/test_student_worker.py` could not
  spawn pytest because the fresh detached sandbox had no populated
  environment.  This was an environment precondition failure, not a test
  failure.  After distinct setup command `uv sync --frozen`, the exact focused
  command passed 11 tests.
- Source trace confirms `SubprocessNativeAgent._codex_isolation()` always
  selects workspace-write; `_claude_isolation()` always allows
  `Bash,Edit,Read,Write,Glob,Grep`; `_task_prompt()` only describes
  `permitted_scopes`.  `run_worker_once()` selects a saved session by project
  and client and replaces every project session without a task identifier.
- The first Claude independent invocation used `--allowedTools ""`.  Claude
  still used built-in tools, searched the wrong archived T-336 session, and
  returned a wrapped document.  The helper reported candidate state `invalid`
  and refused import because the exact title was missing.  The changed second
  invocation used documented `--tools ""`, a new prompt and stage, and
  Fable/high; it returned a structurally valid 8,219-byte candidate which
  imported with SHA-256
  `c6bafad7bdff02a9747d3b27934802b92b798830b23669b5e61f9e886d83557f`.

## Critique

- D-016 is confirmed.  Prompt text is not a capability boundary.  The mapping
  should be deterministic from declared scopes: `analysis` and `planning`
  read-only; `code_preparation` and `experiment_preparation` project-local
  write; `compute_execution` separately blocked.  Read-only tasks with
  expected artifact IDs are internally inconsistent and should fail before
  native launch.
- Claude correctly asks for tool-level negative tests, but a per-scope path
  manifest would exceed the current task contract, which authorizes a finite
  set of roots rather than subpaths.  The smallest safe change is a two-class
  read-only/workspace-write policy over the already validated project root.
- D-017 is confirmed.  Adding `task_id` to `ProjectSession`, unique by
  `(project, client, task_id)`, allows same-task retry while preventing
  cross-task resume.  Existing state must not be silently rebound to a task.
  A schema-2 state with explicit task binding and a fail-closed schema-1
  migration policy is safer than guessing prior authority.
- Claude's recommendation to pin `claude-fable-5` conflicts with the owner's
  explicit preference for the `fable` default and the native CLI's supported
  alias contract.  Keep `fable`, validate the tracked setting, and preserve a
  native emitted-model receipt so later alias drift is visible.
- Claude correctly identifies filler pressure in one "substantive result" per
  hour.  Preserve the owner's proportional-summary requirement as one
  evidence-backed time-slice entry per requested hour plus a proportional word
  floor; a slice may honestly record a stable blocker or wait state.  Require
  distinct substantive results when they exist, never manufacture them.
- Protocol correction: the driver evidence should have been written before the
  first co-pilot window.  The driver had already completed independent source
  discovery, but did not persist it until after import.  Reciprocal review can
  still challenge both records, but the deviation must remain explicit.

## Proposed plan changes

1. Freeze Students scope semantics as a root-level read-only/workspace-write
   matrix and reject expected artifacts for read-only tasks before launch.
2. Move Students worker state to schema 2 with task-bound sessions.  Refuse
   schema-1 state containing sessions or a pending outcome; accept empty
   schema-1 state as a one-time migration to schema 2.
3. Add negative tests for both native client commands, expected-artifact
   conflict, same-task resume, cross-task non-resume, and legacy-state handling.
4. Add a schema-3 cowork session with `benchmark.md`, agreement fields and
   mechanical transition gates while retaining schema-1/2 validation.
5. Set both tracked project Claude settings mirrors to `"model": "fable"` and
   `"effortLevel": "high"`, extend config/takeover tests and validator checks,
   and obtain a project-settings-only native receipt.
6. Add a Harness root rule: every owner duration/time-window job invokes
   `codex-claude-cowork` and `long-running-task-ledger`, freezes a benchmark
   before execution, and uses evidence iterations.
7. Define the final duration summary as at least
   `max(300, 50 * ceil(requested hours))` words with one evidence-backed
   time-slice item per requested hour, plus outcome, validation, residual
   risks, and next action.  A no-change slice must name the stable
   blocker/wait state and evidence; padding or invented results are forbidden.
