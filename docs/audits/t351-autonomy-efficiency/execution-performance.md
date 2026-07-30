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

## Connection-monitor route snapshot

The connection monitor formerly probed its ten primary and secondary routes
serially before classifying each pair. It now admits the initial read-only
route probes through a four-slot FIFO queue, records one immutable result per
route, and only then performs the existing pair classification and any
authorized recovery sequentially.

Five matched synthetic samples took 918–925 ms for the serial fixture (median
922 ms) and 291–311 ms for the queue (median 304 ms), a 67.0% critical-path
reduction. The fixture reached but never exceeded four probes, proved that the
fifth route started before the delayed first route ended, observed every route
exactly once, and observed no supervisor recovery or authorization call during
the snapshot. Down-route classification and the focused connection-monitor and
source-contract suites pass. No live monitor cycle was restarted for this
measurement.

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

## Immutable Codex runtime reuse

The runtime release formerly used the complete Harness commit as its directory
identity even though only seven committed files execute after handoff.
Unrelated documentation or test commits therefore created redundant immutable
releases for all three targets. Releases are now keyed by the ordered path,
mode, and Git blob identity of that exact closed seven-file payload. Harness,
Students, and Swallow still have distinct target directories and locks, and
the immutable marker retains the creation commit as provenance.

The first payload-addressed version used seven Git object lookups and seven
file-hash processes. Its initial twelve matched pairs measured a small bounded
cost on cold creation (247.5→262.5 ms, +6.1%) and same-commit warm validation
(194.5→199.5 ms, +2.6%), while the first launch after an unrelated commit
improved from 241.5 to 182.0 ms (−24.6%) and retained one release directory.

The final implementation resolves the seven committed regular blobs in one
`git ls-tree` call and validates all seven release files in one argv-safe
`git hash-object` call. A second twelve-pair comparison against the exact first
payload implementation improved cold creation from 256.5 to 220.0 ms (14.2%),
same-commit validation from 193.5 to 148.0 ms (23.5%), and unrelated-commit
reuse from 197.0 to 158.5 ms (19.5%). Both sides retained exactly one release
with identical payload identity and original creation provenance. Marker,
target, content, mode, ownership, link-count, recovery-worker environment, and
closed-manifest gates remain covered by the runtime, resilient, helper,
target, launcher, and source-contract suites. Legacy commit-addressed releases
are left untouched for processes that may still reference them.
