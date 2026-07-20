# Driver execution

## Steps and results

Advanced the validated session from `ready-for-execution` to `executing` before
the first target edit. Only Codex changed the target.

1. Helper: stage schema advanced from 2 to 3 while retaining a strict schema-2
   reader. `stage --prompt FILE` now descriptor-reads a current-user-owned,
   single-link regular file with `O_NOFOLLOW|O_NONBLOCK`, a 32 KiB cap, and UTF-8
   validation before stage creation. It copies exact bytes to
   `artifacts/copilot-prompt.md`; `prompt_sha256` is in `stage.json`; load and
   import recheck it. Promptless schema-3 synthetic stages remain supported but
   reject a later unsealed fixed-path prompt. Seal and receipt schemas did not
   change because their existing stage-manifest hash commits the new field.
2. Helper: added deterministic read-only `status` JSON for the live session and
   optional stage/seal/PID. It reports roles, phase, receipts, next action,
   stage and prompt commitments, input/destination freshness, candidate
   byte/hash state, and advisory PID reachability. It neither waits nor writes;
   malformed stage/seal/prompt data fails closed. The final helper successfully
   read this round's retained schema-2 reciprocal stage and reported its
   expected post-advance stale inputs, ready candidate, receipt pair, and exact
   seal hash.
3. Skill/reference: real stages now use a driver-only bounded prompt source
   passed through `stage --prompt`; native client input uses the sealed copy.
   Routine evidence prompts must state time/experiment budgets and record any
   supported explicit model/effort options. Long windows may background the
   recognizable native command and sample `status`; the docs explicitly deny
   that candidate or PID signals prove progress, authorship, correctness, or
   success.
4. Focused tests: added schema-3 prompt/seal assertions, drift refusal before
   live mutation, status read-only snapshots and state transitions, advisory
   reachable/unreachable PID cases, pre-creation symlink refusal, and stage-2
   status/import compatibility. Updated the prior stage-version assertion and
   added documentation/descriptor source contracts.
5. CI: removed the standalone ShellCheck and five standalone suite steps whose
   exact assertions rerun inside `tests/test-phase1.sh`. Kept capability output,
   the independent affinity check, and the complete protected
   `portable-phase1` umbrella job. No test assertion or required job name was
   removed.

Incremental results: helper AST parse passed; CLI help exposes `status` and
`stage --prompt`; canonical quick validation passed; the expanded focused
cowork suite passed; `git diff --check` passed. The focused suite still takes
about ten seconds, so the new coverage did not materially extend its critical
path.

## Deviations

The first default-model/default-effort Claude independent call exceeded the
historical ten-minute wall and was interrupted after 10m08s. It left only the
invalid 15-byte candidate `Execution error`; protected, stage, seal, target, and
sandbox checks proved no other state change, so the narrower retry was safe.
The recorded Sonnet/medium retry finished in about 70s and reciprocal in about
170s, but prompt narrowing and model/effort changed together; no causal product
speed claim is made.

The frozen plan described prompt source failures as stage-creation atomic. The
implementation validates the prompt and seal location before stage creation;
as before, stage creation followed by seal creation is fail-closed but not
cross-file atomic. No receipt schema or reciprocal-addendum change was made.
The four-worker test default remains unchanged pending matched reverse-round
measurements.
