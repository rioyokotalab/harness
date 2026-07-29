# Reconciliation

## Evidence accepted

- Students D-016 is reproducible from source: both clients currently receive
  write-capable execution regardless of declared scope.  Both agents accept
  capability-level enforcement and negative tests.
- Students D-017 is reproducible from source: sessions currently bind only to
  project/client.  Both agents accept explicit task binding and cross-task
  non-resume tests.
- Both agents accept tracked project intent `"model": "fable"` and
  `"effortLevel": "high"` when paired with native project-settings-only
  evidence.  A tracked full model ID is rejected because the owner selected the
  Fable alias and the emitted ID is the runtime evidence.
- Both agents accept a dedicated benchmark and mechanical agreement gate for
  new cowork sessions while preserving existing schema-1/2 sessions.
- Both agents accept proportional duration summaries only when proportional
  entries are evidence-backed time slices rather than manufactured findings.
- The first Claude invocation is preserved as failed evidence: `--allowedTools
  ""` did not disable tools.  The corrected documented `--tools ""` invocation
  produced the authoritative independent result.  The reciprocal result also
  used `--tools ""`.

## Disagreements and uncertainty

- Claude proposed subpath capability manifests; Codex rejected them for this
  task because `AgentTask.allowed_roots` defines roots, not subpaths.  The
  accepted closed two-class matrix is read-only versus project-root
  workspace-write, with unknown scopes failing closed.
- Claude proposed byte-preserving migration of nonempty schema-1 sessions.
  That is unsafe: those records contain no task ID, so preserving them as live
  resumable sessions would guess authority.  The accepted migration handles
  only empty schema-1 state and refuses nonempty legacy state.
- Claude's reciprocal command examples named nonexistent files and commands
  because the no-tools prompt summarized rather than inlined all staged bytes.
  They are proposals, not observations, and are rejected.  Actual repository
  tests and commands below are authoritative.
- The cowork helper currently stages charter/plan bytes but a no-tools native
  client cannot read them.  The implementation must either inline a bounded
  benchmark digest/content in the prompt or grant staged-file Read only.  It
  must not repeat the first window's broad tool exposure.
- Whether Claude project settings produce an emitted Fable model under native
  project-only launch is intentionally unresolved until the execution-phase
  disposable receipt.

## Frozen plan

1. Students T-035:
   - create state schema 2 with task-bound `ProjectSession`;
   - migrate only empty schema-1 state and fail closed on nonempty legacy
     sessions/pending outcomes;
   - map analysis/planning-only tasks to native read-only capability;
   - map code/experiment preparation to current project-root workspace-write;
   - retain the separate compute gate;
   - reject read-only tasks with expected artifacts before launching a client;
   - add focused negative and lifecycle tests.
2. Harness T-342:
   - add schema-3 cowork sessions with required `benchmark.md` and explicit
     driver/co-pilot agreement before `ready-for-execution`; keep schema-1/2
     readers valid;
   - require benchmark-first evidence iteration in skill and protocol text;
   - add the owner duration/time-window trigger to `AGENTS.md`, requiring both
     cowork and durable ledger;
   - define proportional summaries as the revised benchmark case 9;
   - set both tracked Claude setting mirrors to Fable/high and extend project
     validators/tests;
   - record cross-project reusable items in Harness T-342 and Students-specific
     implementation in Students T-035.
3. Claude implements candidate patches and tests only in
   `/tmp/t342-claude-box/{students,harness}` using Fable/high.  It iterates on
   distinct test evidence.  Codex reviews and independently applies accepted
   bytes to target worktrees.
4. Run Students focused and full offline gates; run Harness focused tests,
   project policy checks, `tests/test-phase1.sh`, and a project-settings-only
   native Fable receipt.  Iterate only after recording each distinct failure.

## Acceptance gates

- Every case in `artifacts/benchmark.md` passes.
- Students focused tests and `uv run --frozen --no-sync tools/check.sh` pass
  with clean intended diff.
- Harness cowork/config/takeover focused tests, policy validator,
  `tests/test-phase1.sh`, and `git diff --check` pass with clean intended diff.
- The disposable Claude receipt is tool-emitted under project settings without
  CLI model/effort overrides; private user settings remain unchanged.
- Existing schema-1/2 cowork fixtures remain valid while a new schema-3
  fixture cannot execute without both agreement tokens.
- Protected publication is from reviewed commits with no force push; no live
  product settings or external service settings are changed.
