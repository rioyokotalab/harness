# Driver execution

## Steps and results

1. Rebased the isolated task branch onto protected `main` at
   `1cb46d47355bb61df4e763f04b11f60310373a39`, preserving independent T-335
   and T-337 work.
2. Implemented the frozen 16-scenario corpus, schema, matched runner,
   containment probes, property graders, focused suite, and evaluation
   documentation.
3. Integrated one bounded Codex fixture-generation worker after independently
   reading every owned file and its exhaustive handoff, then closed the
   worker.
4. Verified all 16 untouched baselines fail and all 16 model-free reference
   solutions pass their hidden graders.
5. Passed corpus validation, runner self-tests, the focused suite, Python
   compilation, ShellCheck, and `git diff --check`.
6. Removed generated Python cache residue through the repository guarded-delete
   plan/apply workflow.

The initial scored client execution and its later correction are recorded
below.

7. Ran the first 32-invocation pilot. The closed-schema aggregate recorded
   Claude 15/16 accepted, Codex 0/16 valid, zero unsafe outcomes, and all 16
   pairs excluded.
8. Diagnosed only normalized metadata and artifacts. Codex had obeyed the
   user-level launch sentinel and declined because the synthetic repository was
   outside its declared `$HOME/harness`; Claude's one apparent failure came
   from Python module state leaking between in-process grader calls.
9. Preserved that aggregate as invalid calibration evidence, assigned the
   corrected run a distinct `-r2` experiment identity, aligned the synthetic
   Codex home/workspace with the sentinel, and moved hidden Python execution
   into isolated one-shot bubblewrap processes with network disabled,
   owner-home hidden, and the workspace read-only.
10. Reran every model-free reference and focused check successfully. The
    corrected scored pilot has not started.

## Deviations

- The fixture implementation was bounded-delegated to a Codex worker because
  the 16 disjoint synthetic seeds were parallelizable. The driver retained and
  independently validated the runner, graders, references, and integration.
- The initial model-free self-test exposed a grader helper that discarded
  keyword arguments. The driver corrected the helper and reran the complete
  self-test successfully before any scored model invocation.
- The first scored pilot exposed two additional instrumentation defects that
  the initial self-test could not exercise: client-global launch guidance and
  cross-workspace Python import caching. The invalid rows are not retried or
  used as comparative evidence; the corrected experiment has a new identity
  and run root.
