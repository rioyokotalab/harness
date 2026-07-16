# Local readiness queue diagnosis

This is a read-only snapshot of captured jobs `91220` (T-210 numerical) and
`91240` (T-217 checkpoint/restart). It authorizes no cancellation,
reprioritization, replacement, or direct `sbatch` bypass.

Both jobs are valid one-node, one-task, one-CPU, 2.6 GB, five-minute requests
in `threadripper-3960x`. Both became eligible at submission, have no dependency,
requested node, excluded node, feature, license, or reservation, and use QOS
`normal` with nice 0. Job `91220` reports `Resources`; `91240` reports
`Priority`; neither has a start estimate.

At the snapshot, the four-node/192-CPU partition reported one network-down
node, one mixed node, and two idle nodes. Its job-state aggregate was one
running and three pending. The pending priority order was the protected Sunday
job `90939` (`BeginTime`, six CPUs, start 2026-07-19 00:30), then `91220`, then
`91240`. The controller uses `priority/basic` with backfill, no preemption, and
no reservation. `sprio` cannot decompose priority under that plugin.

The apparent idle capacity does not establish that the wrapper-managed
`thrp_1` requests are runnable: Slurm remains authoritative and reports a
resource/priority wait. The public interface has no residue-free test-only
path for `ybatch`, and direct `sbatch` is refused. Preserve the captured jobs,
poll their exact IDs, and accept only terminal scheduler accounting plus their
private fixed results. Escalate to site support if the ordinary queue state
persists beyond the owner's tolerance; do not duplicate or bypass it.
