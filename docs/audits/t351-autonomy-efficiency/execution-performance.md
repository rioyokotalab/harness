# T-351 execution-path performance

All retained comparisons use matched local fixtures or the same read-only
Local metadata. Live network timing is reported only as an observation, never
as the causal benchmark for a code change. No benchmark reads tmux pane or
transcript content, submits app-server input, or signals a managed client.

## Continuous tmux monitor

The original monitor rediscovered the complete `/proc` descendant graph once
per process-tree node and ran `ss -xnpH` once per Codex candidate. With three
managed windows, five matched read-only samples took:

`401.953, 410.532, 410.675, 404.941, 419.834 ms`.

The retained monitor takes one metadata-only process snapshot and one
Unix-socket snapshot per cycle, then resolves all three target trees in memory.
It reads command arguments only for the three exact tmux pane owners needed to
identify their supervisors. Five matched samples took:

`43.934, 39.519, 40.008, 42.516, 47.336 ms`.

That is a 9.7x reduction at the medians (410.532 to 42.516 ms). The snapshot
also gives one internally consistent process view to Harness, Students, and
Swallow. Exact target, PID/start-time, process ownership, watcher, app-server,
phone-mirror, and recovery gates remain unchanged; the recovery helper still
revalidates mutable identities before any mutation. The focused monitor and
source-contract suites pass.

## Fleet-health probe scheduling

The original implementation used three fixed parallel batches. A slow probe
in one batch prevented free slots from admitting probes in the next. The
retained implementation uses a FIFO admission queue with at most four active
probes and renders results later in the unchanged canonical order.

A synthetic fixture placed 1.5-second probes in each former batch and shorter
probes around them. The old barriers had a 4.500-second minimum critical path.
Three queue runs took 1.921–1.932 seconds (median 1.925 seconds), reached but
never exceeded four concurrent probes, and proved that later-batch work began
before the delayed first-batch probe ended. Maintenance exclusions, paired
routes, ordinary versus independent SSH options, AL managed-session behavior,
compact output, and failure classification are unchanged. The fleet-health
and source-contract suites pass.

## Interactive backup warning

Interactive shell startup calls the backup-chain warning path. The original
path independently validated and parsed the same private state file for each
field. The retained path validates metadata once, parses all warning fields in
one `awk` pass, detects every duplicate key before querying the scheduler, and
still performs one fresh native scheduler query.

Five healthy Local calls improved from 0.05–0.06 seconds (median 0.05) to
0.03–0.04 seconds (median 0.03). Observed process launches fell from 35 to 22;
the absent-state fast path remained 0.01 seconds and nine launches. Fixtures
cover ybatch, Slurm, PBS, ABCI-Q, and AGE plus duplicate, malformed,
unsafe-mode, missing-job, failed-query, and failed-backup states. The Restic
schedule and Bash startup suites pass.
