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

The retained monitor takes one process snapshot and one Unix-socket snapshot
per cycle, then resolves all three target trees in memory. Five matched samples
took:

`47.057, 46.041, 46.298, 45.478, 45.980 ms`.

That is an 8.8x reduction at the medians (410.532 to 46.041 ms). The snapshot
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

