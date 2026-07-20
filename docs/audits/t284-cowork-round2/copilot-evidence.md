# Co-pilot evidence

## Sandbox and baseline

Observation: all work was confined to `/tmp/harness-t284-r2-codex` and its sealed direct-child stage, `/tmp/harness-t284-r2-codex/stage-independent`. No live Claude session, Claude sandbox, remote, service, credential, package, or external seal was accessed.

Baseline verification:

```text
$ pwd
/tmp/harness-t284-r2-codex

$ git rev-parse HEAD
ca875387c232e0da51fdf602a5aa21369720965f

$ git status --porcelain=v1
<empty>
```

The staged state identifies Claude as driver, Codex as co-pilot, phase `discussing`, and staged exchange mode. The stage is schema 3, mode `independent`, with the same roles and phase.

The staged prompt SHA-256 matches `stage.json`:

```text
4233c93796b2ed04b0aaea878aee868acc8ab50f8f62bcddc9a963ee3dbb7626
```

At startup, the real stage candidate was:

```text
candidate_state=unchanged
candidate_bytes=133
candidate_sha256=da32107e44a02377b76bf9e79cea08250357c548157a4adc8125295031c5a4b6
```

That digest equals `destination_before_sha256`. The candidate remained unchanged during the evidence pass because the native Codex output-last-message mechanism, not this process, owns the final candidate write.

One source import generated an untracked bytecode file:

```text
shared/skills/codex-claude-cowork/scripts/__pycache__/cowork-sessioncpython-312.pyc
```

I stopped further experiments, exact-unlinked that single generated file, removed its empty directory non-recursively, and revalidated the baseline. Final status was clean:

```text
$ git status --porcelain=v1
<empty>

$ git rev-parse HEAD
ca875387c232e0da51fdf602a5aa21369720965f
```

## Commands and results

The current cowork skill, complete protocol reference, helper source, staged charter, staged plan, staged state, manifest, and sealed prompt were read from this checkout/stage.

Focused cowork suite:

```text
$ /usr/bin/time tests/test-codex-claude-cowork-skill.sh
Codex-Claude cowork skill tests passed
wall_seconds=11.55 exit_status=0
```

This exercises both role assignments, schema-3 prompt binding, external-seal validation, stage-parent rejection, status immutability and candidate states, import refusal paths, receipts, and schema-2 stage compatibility.

The six required focused-runner invocations were made exactly three times per worker count in requested alternating labels `4,8,4,8,4,8`. Every invocation used a fresh, initially nonexistent directory under `stage-independent/artifacts/runner-logs/`. Git remained clean after the generated ignored artifacts.

| Run | Jobs | Wall time | Result | Failed suites |
|---|---:|---:|---:|---:|
| `run1-j4` | 4 | 23.52s | exit 1 | 7/57 |
| `run2-j8` | 8 | 18.91s | exit 1 | 7/57 |
| `run3-j4` | 4 | 34.81s | exit 1 | 7/57 |
| `run4-j8` | 8 | 25.62s | exit 1 | 7/57 |
| `run5-j4` | 4 | 24.94s | exit 1 | 7/57 |
| `run6-j8` | 8 | 18.96s | exit 1 | 7/57 |

Summary:

- Jobs 4: median 24.94s; range 23.52–34.81s.
- Jobs 8: median 18.96s; range 18.91–25.62s.
- Raw medians favor jobs 8 by 5.98s, approximately 24%.
- Runs 3 and 4 overlapped after the command runner reported their containing sequences drained prematurely. Those two measurements are not matched clean evidence.
- All six runs failed the same seven suites, so none is a clean acceptance run.

Repeated failures:

```text
test-personal-macos-profile.sh
test-tmux-config.sh
test-personal-macos-update.sh
test-personal-macos-config-sync.sh
test-personal-macos-config-migrate.sh
test-ssh-config-mirror.sh
test-fleet-sync.sh
```

Representative causes were `tmux configuration grammar is invalid`, a sandbox-denied synthetic agent socket, and a read-only home-state path in the fleet-sync test. Because some failures are plainly confinement-related while the repeated tmux grammar failure may have another cause, attribution remains unresolved.

Top suite durations:

| Run | Three longest suites |
|---|---|
| `run1-j4` | cowork 11.270s; personal-macos-ssh-sync 11.190s; restic-schedule 9.574s |
| `run2-j8` | cowork 13.826s; personal-macos-ssh-sync 12.903s; restic-schedule 10.373s |
| `run3-j4` | cowork 18.040s; personal-macos-ssh-sync 13.980s; personal-macos-homebrew 12.825s |
| `run4-j8` | cowork 18.655s; personal-macos-ssh-sync 17.737s; personal-macos-update 13.863s |
| `run5-j4` | cowork 12.041s; personal-macos-ssh-sync 11.315s; restic-schedule 9.724s |
| `run6-j8` | cowork 13.819s; personal-macos-ssh-sync 12.977s; restic-schedule 10.352s |

Status findings:

- The complete `status` command cannot be invoked by a blinded co-pilot using only this stage: its required first argument is the withheld live session. The external seal is also intentionally unavailable.
- The helper’s stage reader and candidate-state logic verified the real stage’s startup `unchanged` state without writing it.
- The focused cowork suite independently passed its synthetic transition from `unchanged` with fresh inputs/destination to a post-import state where `candidate_state` remains `ready` but `destination_fresh` is false.
- The final real-stage transition cannot be sampled before this response because output-last-message writes the candidate after generation. The driver must perform that final status observation.
- `status` is read-only by source trace: it loads and validates state, receipts, stage, prompt, seal, candidate, and optional PID reachability, then prints JSON. Its PID check uses signal zero and is explicitly advisory.

Import-readiness trace:

- `candidate_state=ready` only establishes bounded UTF-8 content with the required headings and no standalone unresolved marker.
- `inputs_fresh=true` establishes staged input hash and live projected-input equality.
- `destination_fresh=true` establishes that live co-pilot evidence still equals the staged destination-before digest.
- Successful sealed status also establishes stage layout, prompt digest, roles, and external-seal consistency.
- `next_action` and stage `mode` must agree with receipt sequencing.
- Before import, the driver must additionally compare protected digests and the retained pre-window stage-manifest seal, inspect the complete candidate semantically, and confirm the process result.
- `import-copilot` remains authoritative: it repeats descriptor, ownership, link-count, schema, roles, phase, receipt order, seal, prompt, input, destination, and candidate checks before mutation.

Seal-parent reasoning:

```text
stage       = /tmp/harness-t284-r2-codex/stage-independent
stage.parent= /tmp/harness-t284-r2-codex
```

`seal_location_ok` rejects any resolved seal path relative to either the live session or `stage_root.parent`. Therefore both of these are rejected:

```text
/tmp/harness-t284-r2-codex/seal.json
/tmp/harness-t284-r2-codex/stage-independent/seal.json
```

A seal outside `/tmp/harness-t284-r2-codex` is not relative to the stage parent and satisfies that path condition, subject to the separate session-tree and same-UID reachability requirements. No stage or seal was created to reproduce this rule.

Symmetry findings:

- `init` derives the co-pilot as the other member of `{codex, claude}`; stage, status, import, receipts, and phase transitions use recorded roles without a driver-brand branch.
- The focused suite creates and validates both Codex-driver/Claude-co-pilot and Claude-driver/Codex-co-pilot sessions.
- Functional protocol symmetry is supported.
- Enforcement is intentionally not identical: Codex workspace-write supplies an OS-enforced writable boundary, while the documented Claude CLI permissions are behavioral unless an external platform sandbox is applied. The plan should call this role-neutral protocol symmetry, not identical client confinement.

CI/source trace:

- The current workflow runs the affinity test and then `tests/test-phase1.sh`.
- `test-phase1.sh` invokes the focused manifest once through `tools/run-focused-tests.py`.
- The manifest includes the cowork suite and 56 other focused suites.
- `test-phase1.sh` retains the conditional ShellCheck gate.
- Current source therefore retains focused-suite and ShellCheck coverage without another visible workflow-level duplicate. I did not independently reconstruct every historical removed CI step, so the stronger claim that each formerly duplicated step maps exactly once remains source-supported but not exhaustively history-proven in this pass.

Pre-existing log-directory behavior was established by source trace without a seventh runner invocation. `log_dir.mkdir(..., exist_ok=False)` is outside the existing `try/except ValueError`, so `FileExistsError` escapes as a Python traceback. That is an implementation detail rather than a clean command-line diagnostic.

## Critique

The raw timing direction favors eight workers, but it does not support changing the default. Every run failed, two central samples overlapped, and the longest suites slowed substantially under the contaminated pair. Retaining jobs 4 is the conservative decision until both arms pass in a genuinely sequential, matched environment.

The status fields are individually honest, and the protocol text explicitly warns that candidate and PID states do not authorize import. Nevertheless, the machine surface makes a hazardous partial reading easy: `candidate_state=ready` can coexist with `destination_fresh=false`, as the focused suite deliberately demonstrates. There is no aggregate `import_preconditions` or `import_ready` field.

Adding a simple `import_ready` Boolean would risk overstating what status can prove because semantic review, protected digest comparison, process success, and import-time descriptor checks remain outside it. A named structured field such as `mechanical_import_preconditions` would be safer if the interface is changed. Documentation alone can also be adequate if it presents the required conjunction next to the example command.

The blinded co-pilot cannot exercise the complete real-stage status surface because `status` requires the withheld live-session path. This is consistent with keeping the session secret, but conflicts with a literal requirement that the co-pilot itself monitor real `inputs_fresh` and `destination_fresh`. Monitoring belongs to the driver unless a separately sealed, path-free stage-only status mode is designed.

Prompt binding is supported by the real stage’s matching prompt digest and by the passing focused suite. The independent pass cannot authenticate the external seal because withholding it is part of the confinement model; the driver must perform that comparison.

The direct-child seal rule is sound only under its documented precondition. If callers ever permit nested stages, `stage_root.parent` becomes too narrow and no longer represents the whole co-pilot sandbox. The existing charter correctly requires direct children.

The runner’s pre-existing-directory traceback is poor CLI behavior. Refusing reuse is correct because it preserves attributable logs; the refusal should be deliberate and concise rather than a traceback. Making the directory idempotent would weaken run isolation and is not recommended.

The repeated seven-suite failures also show that worker-count benchmarking needs an explicit clean-run gate. Timing failed workloads can inform diagnostics, but it should not select a production default.

## Proposed plan changes

1. Retain `HARNESS_TEST_JOBS=4`. Do not accept a default change from this pass. Require a new matched experiment in which all focused suites pass, runs are strictly sequential, neither arm overlaps other benchmark work, and at least three alternating samples per arm complete under the same confinement and host conditions.

2. Mark the present concurrency evidence as inconclusive despite the raw jobs-8 median advantage. Preserve the six logs and record the exact contamination: all runs failed the same seven suites, and runs 3/4 overlapped.

3. Diagnose the seven repeated failures before any new concurrency benchmark. Separate sandbox-caused failures (`PermissionError`, read-only home-state path) from the unresolved tmux grammar failures. Do not expand this bounded pass into that diagnosis.

4. Freeze an explicit pre-import checklist requiring all of:

   - successful sealed `status`;
   - expected `next_action` and stage mode;
   - `candidate_state=ready`;
   - `inputs_fresh=true`;
   - `destination_fresh=true`;
   - unchanged protected live-session digests;
   - retained pre-window stage-manifest and external-seal match;
   - successful native co-pilot process exit;
   - semantic inspection of the complete candidate;
   - final `import-copilot` success followed by receipt verification.

   State that PID reachability and candidate state never authorize import.

5. Prefer a documentation/runbook clarification first. If a machine-readable improvement is desired, add a structured `mechanical_import_preconditions` object rather than an unqualified `import_ready` Boolean, and state which non-mechanical gates remain external.

6. Assign real-stage status monitoring to the driver. After output-last-message writes this evidence, the driver should sample status and require `candidate_state=ready`, `inputs_fresh=true`, and `destination_fresh=true` before import. Record that the blinded co-pilot could verify only the stage-local initial state.

7. Preserve role symmetry wording but qualify it: the protocol and helper are symmetric with respect to driver identity; client confinement mechanisms are not identical. Keep Claude-driver and Codex-driver tests in the focused suite.

8. Keep every stage a direct child of the declared co-pilot sandbox. Keep every prompt source and external seal outside the live session and the entire stage-parent sandbox. If nested stages are ever required, add an explicit validated co-pilot-root argument rather than relying on the immediate parent.

9. Keep prompt binding unchanged. Require the driver to compare the retained external seal and pre-window stage-manifest digest after this client window because the co-pilot intentionally cannot authenticate the withheld seal.

10. Change `tools/run-focused-tests.py` so a pre-existing `--log-dir` produces a concise `focused-tests:` diagnostic and exit status 2. Catch the directory-creation error explicitly before starting suites. Continue refusing reuse; do not make an existing log directory idempotent.

11. Retain the current CI shape unless historical inspection finds a missing removed step. Record the independently confirmed current mapping: CI invokes phase one, phase one invokes the focused manifest once, the manifest includes the cowork suite, and phase one retains the ShellCheck gate.

12. Before reconciliation, record as unresolved:

   - the root cause of the repeated tmux-related failures;
   - a valid clean jobs-4/jobs-8 comparison;
   - the driver’s final real-stage status after candidate emission;
   - external-seal and protected-digest comparison;
   - exhaustive historical proof for every removed duplicate CI step.