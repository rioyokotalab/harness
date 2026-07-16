# Project intake for LLM and scientific HPC work

Use this contract to move Q5/Q6 from an owner/project gate to a reproducible
execution plan. Run it through Plan–Interview–Execute and ask one question at a
time. Store the completed manifest in the workload's own repository; public
harness contains only the schema, never project paths, unpublished data
identifiers, or credential values.

The canonical contract is
[`schemas/hpc-project-intake.schema.json`](schemas/hpc-project-intake.schema.json).
`status=ready` means required choices are explicit and consistent. It does not
authorize downloads, a new billing account, publication, or scaling.

## Interview order

1. What project identifier and workload family should this cover?
2. Which declared targets are actually in scope?
3. What smallest project-native correctness command freezes the baseline?
4. Which framework/version and project lock evidence are authoritative?
5. Which language, MPI, library feature, ABI, and threading constraints apply?
6. Which module, uenv, lock, or immutable architecture-matched artifact supplies each target?
7. Are artifact licenses reviewed and external downloads authorized?
8. Which reviewed account/queue/resource shape should the first gate use?
9. Which references identify input, output, checkpoint, and retention boundaries?
10. What numerical, restart, and terminal conditions constitute a pass?
11. Which credential references, if any, resolve at runtime? Record identifiers only—never values, contents, hashes, or copied files.

Validate the completed project manifest against the schema, resolve every
native site command visibly, and run only the smallest correctness gate. Keep
performance deferred until correctness, checkpoint cleanup, and immutable
environment evidence pass. Distributed work remains a separate resource
decision.

Validation requires no installed package: run
`~/harness/tools/hpc-project-intake-validate.py --require-ready MANIFEST`.
The validator refuses symlinks, oversized or duplicate-key JSON, undeclared
fields, invalid types/ranges/patterns, and a draft manifest. It prints only
phase and aggregate item counts, never manifest values.
