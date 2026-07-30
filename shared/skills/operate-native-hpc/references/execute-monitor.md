# Execute and monitor

1. Reconstruct the accepted plan from project instructions and the ledger;
   never implicitly clone a project, model, or dataset. Require the frozen
   correct baseline before optimization; harness smokes do not replace project
   tests. Login checks are discovery; workload evidence comes from compute.
2. For a queued version-controlled job, capture the submitted revision. When
   compute starts, verify declared job and source paths retain the same bytes.
   Repository `HEAD` is too strict for unrelated successors and too weak for
   relevant working-tree drift.
3. For a multi-node job, never assume rank-local `TMPDIR`, `SLURM_TMPDIR`, or
   node-local scratch is shared. Use an explicitly reviewed shared boundary or
   stage runtime inputs independently to every node. Before application launch,
   require the expected digest and executability from every intended node.
   Never apply this check to credential or unrelated private-data paths.
4. Before submission, run the native exact-name collision query and require
   its exit status before parsing or counting output. Never let an unchecked
   pipeline turn a scheduler, DNS, or transport failure into zero jobs.
5. Submit or launch the exact `NATIVE` command. Accept only the scheduler
   family's exact success grammar for one job ID, then immediately query that
   ID and match owner and name. Zero wrapper status without a parseable,
   queryable ID is rejected or indeterminate. Capture only that job's output
   path.
6. Monitor only the captured job ID with the native status command; unchanged
   queued state is normal. Cancel only that ID when requested or when a
   verified safety condition requires it.
7. Remove only job-scoped temporary builds and smoke output. Preserve project
   logs, scheduler evidence, and unrelated files.
