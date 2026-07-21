# Co-pilot evidence

## Sandbox and baseline

This reciprocal review was confined to `/tmp/harness-t284-r2-codex` and its sealed direct-child stage, `/tmp/harness-t284-r2-codex/stage-reciprocal`. I did not access the live Claude session or sandbox, main checkout, settings, credentials, packages, services, remotes, external seals, or other external systems.

Current baseline:

```text
git_commit=ca875387c232e0da51fdf602a5aa21369720965f
git_status=<clean>
stage_schema=3
stage_mode=reciprocal
driver=claude
copilot=codex
phase=discussing
exchange_mode=staged
```

The reciprocal stage binds the imported independent evidence and prompt:

```text
prompt_sha256=052a2a0b1b13fd4d9e895b3d4a2c37971f75c05bdada315816d5bf6436f68e36
stage_manifest_sha256=8e56c007a8871077ca04188303ed1295af12f5dc7c66e862b2fe025432cf3cc5
imported_copilot_evidence_sha256=d1e3f63c3e999f81e6de88eb79c4261a5256ff830f7195d07a3ffd3b14ce9d00
destination_before_sha256=d1e3f63c3e999f81e6de88eb79c4261a5256ff830f7195d07a3ffd3b14ce9d00
```

The prompt hash matches the staged prompt bytes, and the imported evidence hash matches `destination_before_sha256`.

The independent pass had verified the same Git baseline and a clean final worktree. Its focused cowork suite passed in 11.55 seconds. That is useful functional evidence, but it is only one timing sample and does not establish a clean performance comparison.

## Commands and results

No new full, focused-suite, or concurrency test was run during this reciprocal pass. I read and traced:

```text
stage-reciprocal/charter.md
stage-reciprocal/plan.md
stage-reciprocal/driver-evidence.md
stage-reciprocal/copilot-evidence.md
stage-reciprocal/state.json
stage-reciprocal/stage.json
stage-reciprocal/artifacts/copilot-prompt.md
shared/skills/codex-claude-cowork/scripts/cowork-session
shared/skills/codex-claude-cowork/SKILL.md
shared/skills/codex-claude-cowork/references/protocol.md
tools/run-focused-tests.py
tests/test-focused-runner.sh
tests/test-codex-claude-cowork-skill.sh
tests/test-phase1.sh
tests/focused-suites.tsv
.github/workflows/ci.yml
```

Status and import readiness:

- Claude observed `candidate_state="ready"` together with stale inputs. The existing helper permits that combination because `candidate_state` validates only candidate bytes and required headings; it does not incorporate live-input freshness.
- The existing focused cowork test also establishes the analogous partial state after import: `candidate_state="ready"` while `destination_fresh=false`.
- `status` currently emits `candidate_state`, `inputs_fresh`, and `destination_fresh` as independent sibling fields. The protocol warns that candidate state is advisory, but a machine or hurried operator can still consume the attractive `ready` label alone.
- `import-copilot` remains the authoritative mechanical gate and repeats stronger descriptor, schema, role, receipt-order, prompt, seal, input, destination, and candidate checks before mutation.
- Semantic inspection, native process success, protected-digest comparison, and retained pre-window seal comparison are outside what `status` can establish.

A documentation clarification is necessary but not sufficient. The observed hazardous combination is part of the machine interface, so `status` should also expose a structured, explicitly non-authorizing summary. The smallest safe shape is:

```json
"mechanical_import_preconditions": {
  "candidate_structurally_ready": true,
  "inputs_fresh": false,
  "destination_fresh": true,
  "all_satisfied": false,
  "advisory": true,
  "authorization": "none"
}
```

This object should summarize only the three existing byte/freshness observations. It must not be called `import_ready`, must not include semantic approval, and must always state that it grants no authorization. Seal validation, expected stage mode and receipt order, protected digests, process exit, semantic review, import success, and receipt verification remain separate gates.

Monitoring ownership:

- A blinded co-pilot cannot run the complete real-stage `status` command because the required live-session path is withheld.
- It also cannot authenticate the external seal because that seal is deliberately outside every co-pilot-writable and disclosed tree.
- This is the intended confinement model, not a missing co-pilot capability. Real-window monitoring therefore belongs to the driver in both role assignments.

The smallest symmetric prompt/runbook wording is:

> The driver, which retains the live-session and external-seal paths, runs `status` during and after the native co-pilot window. The blinded co-pilot reports only stage-local observations. Neither candidate state nor PID reachability authorizes import.

Worker evidence:

Claude’s four dirty-tree samples and the independent pass’s six workspace-confined samples point in the same raw direction:

- Claude: jobs 8 was faster in both pairs, but every run failed `test-tmux-config.sh` because the checkout was dirty.
- Independent pass: jobs 8 had a roughly 24% lower raw median, but all six runs failed the same seven suites and the middle jobs-4/jobs-8 pair overlapped.
- Neither set satisfies acceptance. Failed workloads, dirty-tree failures, sandbox-specific denials, overlapping measurements, and small samples cannot select a new production default.
- The frozen default should remain `HARNESS_TEST_JOBS=4`.
- No more concurrency benchmarking belongs in this round. The failure causes and environment must first be corrected; a later, separately bounded benchmark may use strictly sequential alternating samples with every suite passing.

Pre-existing log-directory behavior:

`tools/run-focused-tests.py` currently executes:

```python
log_dir.mkdir(mode=0o700, parents=False, exist_ok=False)
```

outside an exception handler. A pre-existing directory therefore produces a Python traceback. Idempotent reuse is unsafe because old and new logs could be mixed and attribution weakened. Documentation alone would preserve an unnecessarily poor CLI failure.

The smallest implementation is to retain refusal but catch `FileExistsError`:

```python
try:
    log_dir.mkdir(mode=0o700, parents=False, exist_ok=False)
except FileExistsError:
    print(
        f"focused-tests: --log-dir already exists: {log_dir}",
        file=sys.stderr,
    )
    return 2
```

The smallest focused regression belongs in `tests/test-focused-runner.sh`: invoke the runner a second time with the already-created successful `pass-logs` directory, capture its status and stderr, require exact status 2, require the concise `focused-tests: --log-dir already exists:` diagnostic, and reject `Traceback`. No suite should start during that invocation. Existing behavior for a missing parent is outside this exact change.

Stage-parent seal wording:

- The helper rejects seals inside either the live session or `stage_root.parent`.
- This represents the full co-pilot sandbox only when each stage is a direct child of that sandbox.
- The charter, skill, and protocol now state that direct-child precondition and require prompts and external seals outside the entire stage-parent sandbox.
- That wording is sufficient. If nested stages are later required, the helper needs an explicit validated co-pilot-root argument; weakening the current check is not appropriate.
- The path check does not establish general same-UID confinement. The driver must still choose an actually withheld external location.

Current CI coverage:

- The workflow records capabilities, runs `tests/test-affinity-readiness.sh`, and runs `tests/test-phase1.sh`.
- The affinity test is not in `tests/focused-suites.tsv`, so the visible standalone affinity step is not duplicated by the focused manifest.
- `test-phase1.sh` invokes `tools/run-focused-tests.py` once in its normal parallel path.
- The manifest contains the focused runner and cowork suites and has 57 active suite entries.
- `test-phase1.sh` retains the conditional ShellCheck warning/error gate. The workflow’s `shellcheck --version` command records capability; it is not a duplicate lint run.

This confirms the current coverage shape without visible duplicate suite or ShellCheck execution. It does not independently prove the stronger historical claim that every step removed in round 1 maps exactly once; that would require the historical diff or removal manifest.

## Critique

Claude’s stale-input observation strengthens the independent critique. Documentation already says `candidate_state` is advisory, but the machine surface still presents `ready` independently from freshness. A full prose checklist alone is too easy for machine consumers to bypass accidentally. The structured object should be added, but it must remain visibly advisory and non-authorizing; an `import_ready` Boolean would overclaim.

The independent proposal to “prefer documentation first” is therefore rejected. Documentation and the structured object should land together. The object reduces partial reads, while the runbook records the gates that cannot be represented by status.

Both evidence passes agree that driver-owned monitoring is required. Requiring a blinded co-pilot to monitor the real session would either be impossible or would disclose precisely the paths the staged protocol withholds. Symmetry means the same driver/co-pilot responsibility rule applies whichever product occupies each role; it does not mean both roles receive identical information.

The raw worker results consistently favor eight, but neither evidence set is acceptable benchmark evidence. Claude’s claim that the identical dirty-tree failure “does not undermine” the wall-time comparison is too strong: the failed suite is short and balanced, so the direction remains diagnostically interesting, but a failed gate can alter scheduling and critical-path behavior and cannot support a default change. The independent results are more contaminated still because seven suites failed and one pair overlapped. No clean timing conclusion should be drawn.

The focused cowork timings—roughly 9.97, 10.12, 11.55, and 12.10 seconds across different passes—are unmatched single samples. Describing their differences as “expected variance” is an inference, not measured evidence. They support “no gross slowdown observed,” not performance equivalence or regression absence.

Functional protocol symmetry is supported by role-neutral state handling and tests for both driver assignments. Claims of identical client confinement must be rejected: Codex workspace-write provides an enforced writable-root boundary in this workflow, while Claude tool permissions are behavioral unless an additional platform sandbox is present. Role symmetry, helper symmetry, and confinement equivalence are distinct claims.

The pre-existing log-directory traceback is a real CLI defect, not merely a documentation gap. Idempotent reuse would weaken attributable logs; concise exit-2 refusal is the smallest safe correction.

The direct-child seal rule and current documentation are aligned. The remaining limitation is accurately documented: treating the immediate stage parent as the co-pilot root is valid only under the direct-child precondition, and path checks do not prove the seal is unreachable to every same-UID process.

Current CI source supports the claimed present topology. It does not provide exhaustive historical proof for every removed duplicate, so reconciliation should avoid upgrading that narrower source trace into a historical certainty.

## Proposed plan changes

1. Add `stage.mechanical_import_preconditions` to `status`, containing:

   - `candidate_structurally_ready`;
   - `inputs_fresh`;
   - `destination_fresh`;
   - their conjunction as `all_satisfied`;
   - `advisory: true`; and
   - `authorization: "none"`.

   Do not add `import_ready`.

2. Update the status runbook beside the example command to say that the structured object covers only observed candidate structure and freshness. Explicitly require driver review of expected mode/receipt sequencing, native process exit, protected digests, retained stage and external seals, candidate semantics, `import-copilot` success, and receipt verification.

3. Add a focused cowork regression that creates a structurally ready candidate, changes a staged live input, and verifies:

```text
candidate_state=ready
inputs_fresh=false
mechanical_import_preconditions.candidate_structurally_ready=true
mechanical_import_preconditions.inputs_fresh=false
mechanical_import_preconditions.all_satisfied=false
mechanical_import_preconditions.advisory=true
mechanical_import_preconditions.authorization=none
```

Restore the changed fixture input before continuing existing import tests. Also extend the existing post-import assertion so `destination_fresh=false` yields `all_satisfied=false`.

4. Freeze this symmetric monitoring rule:

> The driver, which retains the live-session and external-seal paths, runs `status` during and after the native co-pilot window. The blinded co-pilot reports only stage-local observations. Neither candidate state nor PID reachability authorizes import.

5. Retain `HARNESS_TEST_JOBS=4`. Mark both timing datasets inconclusive and perform no additional concurrency benchmark in this round.

6. Before any later worker-default experiment, diagnose the repeated suite failures and obtain an environment where all focused suites pass. Then use at least three strictly sequential alternating samples per arm under matched host and confinement conditions, with no overlapping benchmark work.

7. Change the focused runner to catch `FileExistsError`, emit:

```text
focused-tests: --log-dir already exists: PATH
```

and return status 2. Continue refusing reuse.

8. Add one `tests/test-focused-runner.sh` case that reuses `pass-logs`, requires exit 2 and the concise diagnostic, rejects a traceback, and confirms the refusal occurs before suite execution.

9. Keep the direct-child stage rule and current seal wording unchanged: every stage is a direct child of the declared co-pilot sandbox, and every prompt source and external seal is outside the live session and the entire stage-parent sandbox. Add an explicit co-pilot-root parameter only if nested stages become a real requirement.

10. Retain the current CI topology. Record only the proven present mapping: affinity remains a separate non-manifest test, phase one invokes the focused manifest once, and phase one retains the conditional ShellCheck gate. Do not claim exhaustive historical one-to-one coverage without the removal diff.

11. In reconciliation, distinguish:

   - role-neutral protocol/helper behavior, which is supported;
   - identical client confinement, which is false without an additional Claude sandbox;
   - clean timing or performance equivalence, which neither pass established;
   - raw jobs-8 direction, which is diagnostically consistent but not acceptance evidence.

12. Keep unresolved for a later bounded task: the tmux failure cause, the workspace-confined suite failures, a passing matched worker benchmark, the driver’s final real-stage status and process result, and the driver-only protected-digest/external-seal comparisons.