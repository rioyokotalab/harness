# Driver evidence

## Sandbox and baseline

Read-only reconstruction covered root AGENTS.md, all 4,767 lines of TODO.md,
all 531 lines of README.md, worktree topology, recent history, active T-335,
the frozen evaluator, current matched-client runner, project client settings,
and both native CLI help surfaces. The source and `origin/main` are identical
at `fcadc7ae68182036f1aa128fe3b7bea977cddc4f`; the T-336 worktree starts there.
T-335 is clean/aligned at `fab011bc1f390ae71b02e1f4b6c266c63d07037b`
and remains untouched.

## Commands and results

- `codex --version` -> `codex-cli 0.145.0`.
- `claude --version` -> `2.1.220 (Claude Code)`.
- The current evaluation validates seven frozen task families and its dated
  pilot reports Codex 9/9 and Claude 8/9 with zero safety failures.
- Current README incorrectly says 13 shared skills; root durable state records
  17. It also describes seven backed-up Linux nodes although ABQ now has a
  scheduler-native weekly chain and T-196 records all eight at 2/8.
- Git history from T-181 through T-335 clusters into the nineteen benchmark
  archetypes named in the T-336 ledger. This is a coverage map, not a claim
  that synthetic fixtures reproduce live operational complexity.

## Critique

The old suite is strong on generic coding safety but under-samples the work
that now defines Harness development: fail-closed lifecycle control, explicit
identity/time gates, dual-route health semantics, policy precedence,
cross-client instruction symmetry, portable shell/runtime support, and
transactional preservation. A new suite must add these without grading
wording, using private state, or rewarding memorized current implementation.

## Proposed plan changes

The following initial proposal is superseded by the reconciled plan:

Keep the old corpus byte-stable. The initial proposal used a three-repeat
confirmation, Claude default selection, native-tool framing, and classified
timeouts as stage-closing safety failures. Those clauses are superseded by the
imported critique and reconciled plan: 16 scenarios, three total observations,
per-invocation pinned Codex Sol and Claude Opus 5, a controlled shell-only
surface, separate unsafe/run-invalid outcomes, and stage closure only for
containment or evidence-integrity failure.

## Independent-stage plumbing findings

The first sealed Claude stage had no discoverable exact input path and exposed
only `Read`; Claude correctly returned a blocked report rather than fabricating
a critique. Nothing was imported. The second sealed stage supplied exact paths
and stdout capture, and Claude produced a substantive review, but its candidate
lacked the protocol-required `# Co-pilot evidence` heading so import failed
closed. That review also correctly found that the staged charter/plan described
a process but omitted the exact nineteen-family manifest. No co-pilot evidence
has been imported from either invalid stage.

That intermediate plan had 24 scenarios and 12 families. It was superseded
before model execution by the imported reciprocal review and the frozen
16-scenario/eight-decision-type plan.

## Driver critique of imported independent evidence

Accepted:

- reduce domain-heavy overlap to 16 scenarios balanced across eight decision
  types and obtain three total observations per scenario for the same 96-run
  ceiling;
- add a gate-preserving repair and reward-hack mutations;
- merge overlapping diagnostic cases, remove the meta-contaminated client-
  parity task, and make the act/defer mix explicit and stratified;
- split agent unsafe actions from provider/scaffold run-invalid outcomes and
  stop only on containment/evidence-integrity failure;
- add a one-turn non-interactive contract, fixed synthetic Git identity,
  synthetic fleet names, order/time nulls, hygiene lint, and explicit
  driver-vendor authorship/confounder disclosure;
- label the experiment controlled shell-mediated capability rather than an
  ecological native-tool comparison;
- pin Claude after a native no-tool probe. The probe emitted
  `claude-opus-5[1m]` and canonical `claude-opus-5`; the scored declaration
  now pins `claude-opus-5`.

Accepted with qualification:

- T-335 is out of scope only as mutable live state. Provenance from its pushed
  durable ledger is allowed and now stated explicitly.
- The fleet aliases in Harness are public repository facts rather than private
  values, but synthetic names better resist memorization and are adopted.
- A deterministic three-commit fixture is appropriate for history-shaped
  read-only reasoning; no scenario authorizes source-history mutation.

Rejected or infeasible as stated:

- Putting the entire cloud client in an unshared network namespace would also
  block its provider API transport. The frozen scope instead exposes shell
  only, uses kernel network isolation for Claude's shell and native no-network
  policy for Codex's shell, and disclaims ecological-tool coverage.
- Strictly hiding committed grader source from a same-account cloud client is
  incompatible with these native client/authentication surfaces. No oracle
  bytes enter run roots; graders are property-based and unreferenced; any
  outside-workspace read command is an unsafe action. The residual possibility
  of a model guessing the source path is disclosed rather than falsely claimed
  absent.
- Significance testing and a secondary default-effort arm are not justified at
  16 convenience-sampled scenarios. The report forbids superiority language
  and retains descriptive paired evidence only.

The reciprocal review should now challenge whether these qualifications still
leave a useful and honest controlled benchmark, and whether any accepted
correction is internally inconsistent.
