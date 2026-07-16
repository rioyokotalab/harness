# Queued-job source contract

Scheduler jobs can wait while a clean harness checkout safely fast-forwards for
unrelated work. A job must therefore freeze the files it will execute, not
assume that submission-time `HEAD` will remain current and not forbid every
unrelated successor commit.

At submission, capture the full public revision and export it with the native
scheduler command:

```bash
revision=$(git -C "$HOME/harness" rev-parse HEAD)
# Add HARNESS_EXPECTED_REVISION=$revision through the site's native export flag.
```

Before environment setup or scientific work, the job invokes the tracked gate
with every relevant path explicitly listed:

```bash
"$HOME/harness/tests/smoke/jobs/source-contract.sh" \
  "$HARNESS_EXPECTED_REVISION" \
  tests/smoke/jobs/example-readiness.sh \
  tests/smoke/example.cpp
```

The gate accepts an unrelated successor only when the submitted revision is an
ancestor and each declared regular tracked file has identical committed bytes
and mode with no index or worktree change. It refuses unavailable or
non-ancestor revisions, unsafe/duplicate/missing paths, relevant committed
changes, and local drift. Its output contains only expected/current commit IDs,
path count, and stable pass status.

This contract does not freeze modules, uenvs, containers, datasets, linked
libraries, scheduler configuration, environment values, or external services.
Those require their own version/digest/provenance records. Project jobs should
apply the same principle inside the project repository rather than treating
the personal harness as project source authority.
