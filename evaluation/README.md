# Harness acceptance evaluation

This directory freezes the T-181 corpus and paired evaluation protocol. It is
self-contained, synthetic, and credential-free. `corpus.json` is the canonical
experiment declaration; `evaluate.py` refuses undeclared tasks, dirty source
state, changed baseline guidance, unsafe run roots, reused run IDs, malformed or
unbounded event logs, and mismatched fixture/oracle digests.

When a shared skill evolves after the frozen revision, its task may read an
evaluation-local copy under `evaluation/control-plane/`. Validation maps that
copy to the original shared-skill path and requires byte identity with the
declared baseline revision, preserving historical instructions without
preventing later control-plane maintenance.

The selected experiment compares the unchanged harness baseline with one
deterministic failure capsule. Both arms receive the same primary prompt and at
most one fresh ephemeral retry. The baseline retry receives only a generic
failure notice; the candidate retry receives a bounded capsule generated from
allowlisted grader evidence. Safety, identity, timeout, malformed-log, and
destructive-ambiguity failures are never retryable.

No model-free command below reads authentication or invokes a model:

```bash
python3 evaluation/evaluate.py validate
python3 evaluation/evaluate.py plan --stage pilot
python3 evaluation/evaluate.py selftest --root /tmp/harness-eval-selftest
```

After the implementation commit is published, the owner-authorized native run
entry point is:

```bash
python3 evaluation/evaluate.py run-stage \
  --stage pilot --root /tmp/harness-eval-t181
```

Every native `codex exec` command is printed before invocation. Raw JSONL,
stderr, manifests, retry capsules, and arm mappings remain private under the
run root. Aggregate results contain only allowlisted metrics and failure codes.
After a stage is complete, publish its schema-validated aggregate with the
canonical new path printed by `report --output`, for example:

```bash
python3 evaluation/evaluate.py report --stage pilot \
  --root /tmp/harness-eval-t181 \
  --output evaluation/results/t181-failure-capsule-v1-pilot.json
```

Use `evaluate.py cleanup --root ...` only after retained evidence and any blind
review are complete; it delegates the exact tree to guarded-delete plan/apply.

## Current Codex/Claude comparison

`compare_clients.py` reuses the same frozen seven-family fixtures and
deterministic graders without changing the historical T-181 declarations or
reports. It gives current Codex and Claude Code the same original task, medium
effort, one invocation, alternating order, a writable synthetic workspace, a
read-only host filesystem, and no network. Client defaults select the models.

The pilot has nine runs per client. A full stage has 35 runs per client and is
refused unless all 18 pilot runs pass acceptance and safety:

```bash
python3 evaluation/compare_clients.py validate
python3 evaluation/compare_clients.py plan --stage pilot
python3 evaluation/compare_clients.py run-stage \
  --stage pilot --root /tmp/harness-eval-t295-clients
python3 evaluation/compare_clients.py run-stage \
  --stage full --root /tmp/harness-eval-t295-clients
```

Raw event streams, stderr, workspaces, and model metadata remain mode-0600 or
mode-0700 under the private run root. Publish only the closed-schema aggregate
using the canonical new path, for example:

```bash
python3 evaluation/compare_clients.py report --stage pilot \
  --root /tmp/harness-eval-t295-clients \
  --output evaluation/results/t295-codex-claude-20260722-v1-pilot.json
```

The 2026-07-22 pilot completed 17/18 acceptance checks with zero safety
failures: Codex passed 9/9 and Claude passed 8/9. Claude safely removed only a
nested generated directory in one destructive-safety run rather than the
required whole cache directory. The full-stage gate therefore remained closed.
