# Backup lifecycle phase 2 decision register

## Current gate

This is a design artifact only. T-191's seven first production snapshots are
eligible on Sunday 2026-07-19 and have not run yet. No retention deletion,
prune, recurring check, restore job, replica automation, or scheduler write is
authorized. Keep every snapshot until all seven first jobs and their strictly
future successors complete, private chain state is consistent, full-data checks
pass, and restores from the new production snapshots are independently
verified.

Restic 0.19.1 documents that `forget --dry-run` previews policy selection,
`forget` removes snapshot records, and `prune` subsequently deletes/repackages
unreferenced repository data. Prune locks the repository and can be expensive;
Restic recommends checking the repository afterward. A normal `check` does not
read all pack data, while `--read-data` does; deterministic `n/t` subsets can
cover the repository over several invocations. Sources:

- <https://restic.readthedocs.io/en/stable/060_forget.html>
- <https://restic.readthedocs.io/en/stable/045_working_with_repos.html>
- <https://restic.readthedocs.io/en/v0.19.1/050_restore.html>

## Recommended defaults for the later owner interview

These are recommendations, not decisions or commands to execute.

| Decision | Recommended default | Reason |
|---|---|---|
| Stabilization before retention | Eight consecutive successful weekly chains per node, two verified restores per node, and a current verified independent generation | Retention should not remove evidence while recurrence is new |
| Policy scope | Only snapshots selected by the exact weekly tag and canonical host/path; never an unfiltered repository policy | Preserves manual, migration, and incident snapshots |
| Retention | 12 weekly, 12 monthly, 3 yearly | Generous for small hidden-home control state while bounding long-term growth |
| Forget/prune coupling | Never use `forget --prune`; run and verify them as separate transactions | Creates an inspection/recovery interval and isolates failures |
| Forget preview | Two identical `forget --dry-run` results at least 24 hours apart, with zero intervening backup | Detects grouping/time/filter surprises |
| Prune delay | Seven days after a successful forget, with no backup/restore anomaly | Avoids immediate physical reclamation after a policy mistake |
| Prune limits | Start with default `--max-unused`; use `--max-repack-size` only from measured free-space and duration evidence | Avoids speculative tuning and low-space failure |
| Structural checks | Monthly, explicitly before forget, and after forget/prune | The weekly chain creates a snapshot but intentionally does not run `restic check` |
| Pack-data coverage | Rotate deterministic `--read-data-subset=n/4` monthly; run `--read-data` quarterly and after prune | Guarantees full quarterly coverage without random-subset gaps |
| Restore drills | Quarterly full restore of the latest weekly snapshot to a new scratch directory, plus monthly small sampled restore | Measures recoverability; never restores in place |
| Replica recurrence | Manual monthly immutable generation after checks/restores; schedule only after three clean manual cycles | Preserves the user's manual-first decision and independent evidence |
| Maintenance trigger | Scheduler-native, node-local batch jobs in a distinct namespace; never cron/login/logout/central SSH | Matches the accepted T-191 operational model |
| Collision policy | Maintenance refuses any repository lock or active weekly job; it never calls automated unlock | A stale-looking lock may still represent valid work |

The proposed retention filter must first be rendered as a native read-only plan
and tested against a synthetic repository with the same host/path/tag grouping.
The eventual live dry run should be structurally equivalent to:

```text
restic forget --dry-run --host DECLARED_HOST --tag harness-hidden-home-weekly \
  --keep-weekly 12 --keep-monthly 12 --keep-yearly 3
```

This text deliberately omits repository and password paths from the versioned
document. The existing harness route supplies those paths without reading the
password. Do not add `--keep-tag harness-hidden-home-weekly`: that would keep
every selected weekly snapshot and defeat the proposed policy.

## Phased acceptance gates

### Phase A — production stabilization

1. Monitor only the seven captured T-191 job IDs; never reseed because of queue
   delay.
2. For each admitted run, verify exit success, one new snapshot with the exact
   tag/host/path, one strictly future successor, and healthy private state.
3. Restore each new production snapshot to a new node-local scratch target.
   Never use in-place restore or `restore --delete`.
4. Compare a privately generated source manifest with the restored tree using
   counts, types, paths, sizes, and hashes without publishing hidden names.
5. Repeat through the stabilization threshold above. Any partial backup,
   repository warning, missing successor, or restore mismatch resets that
   node's stability count and blocks later phases only for that node.

### Phase B — read-only policy rehearsal

1. Freeze a synthetic corpus representing weekly, monthly, yearly, manual, and
   incident-tagged snapshots across host/path groups.
2. Unit-test that only the intended weekly group is eligible and at least one
   recovery point remains in every required period.
3. On each live repository, record a private snapshot-ID inventory and run two
   identical dry runs separated by 24 hours with no intervening backup.
4. Reject an empty group, an all-snapshot removal, a changed dry-run result, an
   unknown tag/path/host, a lock, insufficient free space, or an overlap with
   the Sunday chain.

### Phase C — manual forget pilot

1. Select one smallest, healthiest node only after explicit owner approval.
2. Create and verify a fresh independent encrypted replica generation.
3. Re-run the exact dry run and compare its selection to the approved manifest.
4. Execute `forget` without `--prune`, capture only IDs/counts privately, and
   immediately run structural check plus a restore of a kept snapshot.
5. Observe a normal weekly backup and restore during the seven-day hold. Any
   anomaly stops the fleet rollout while unpruned data remains available for
   recovery investigation.

### Phase D — prune pilot and fleet rollout

1. Measure repository size, free space, dry-run repack/delete estimates, and
   previous check/backup duration before choosing a native maintenance request.
2. Run prune in a scheduler-native maintenance window with no other repository
   activity. Never time-kill it merely for running longer than predicted.
3. Run structural and full-data checks, then restore a kept snapshot and compare
   its manifest.
4. Expand one node at a time only after the prior node passes. Scheduling a
   recurring maintenance chain is a separate owner decision after at least
   three successful manual cycles.

## Independent replica and restore design

An independent generation is a byte-for-byte encrypted repository replica, not
a replacement for Restic snapshots. Generate it only from an unlocked source
that passes structural and pack-data checks. Stage to a new generation, compare
the existing repository fingerprint, then atomically promote; never synchronize
with deletion. Retain at least the latest two verified generations until a
retention policy for replicas is separately approved.

Restore drills must use a new scratch target outside the source and repository.
Record scheduler ID, Restic version/architecture, snapshot ID, target filesystem,
start/end time, exit status, file/byte counts, and comparison result privately.
Exact-unlink only the private manifest after successful evidence capture; clean
the restored tree with guarded-delete under its canonical scratch boundary.

## Owner choices still required before execution

1. Accept or revise the 12-weekly/12-monthly/3-yearly policy and eight-week
   stabilization threshold.
2. Select the first pilot node after measured repository size/duration evidence.
3. Accept quarterly full-data checks and restore drills plus monthly deterministic
   quarter checks.
4. Confirm the monthly manual independent-generation cadence and the number of
   generations to retain.
5. Approve the exact first live `forget` command and later the separate exact
   `prune` command. These are distinct destructive authority boundaries.

Until those choices and gates are complete, T-196 remains execution-blocked but
does not block read-only monitoring or unrelated LLM/HPC readiness work.
