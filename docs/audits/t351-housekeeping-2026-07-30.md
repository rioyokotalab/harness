# T-351 pre-long-run housekeeping

## Scope

This checkpoint records the owner-authorized cleanup performed before the next
long task. It preserves unrelated work, live Codex processes, retained recovery
evidence, unmerged Git history, and the active `projects` and `monitor` tmux
sessions.

## Verified results

- Primary Git was clean/aligned at
  `73aed2f267b3ce7863db287c4cf16d1d9fe3c238` before an unrelated T-350
  interview checkpoint appeared as an uncommitted `TODO.md` change. That
  owner/peer change was neither staged, edited, nor committed here.
- Codex arg0 housekeeping quarantined and guarded-deleted four eligible
  completed invocation directories. Post-plan is `live=5 eligible=0 young=0
  unexpected=0`.
- Stale PR #377 remained open at exact head
  `9022ac98334f6914f7e78f6dd42a67f7fb960561`; it was closed without merge.
- The sole unmerged worktree branch `codex/t331-ri-archive` has no PR and one
  ledger-only commit,
  `134476b273f92e00bc2a0c985790a11d578ee7bc`. Its two intended outcomes are
  independently reconciled: stale root
  `019fa790-38a5-7ee1-be34-a9aed942e132` is archived with an archive timestamp
  while canonical root `019fa3ae-6ad0-7642-aeca-b7b52421f576` is unarchived;
  current protected code and `profiles/hosts/ri.conf` consume RI's declared
  `SLURM_CONF_SERVER` override. The still-permitted read-only accounting query
  for job `7242` remains in T-196 and was not run. Both local and remote branch
  refs were preserved.
- A current-user `codex-launcher` still has cwd
  `/tmp/harness-t347-t345-controller-v8`. That merged worktree and its Git
  registration were preserved as live.

## Guarded deletion

One immutable guarded manifest deleted 29 exact worktree roots below `/tmp`:
28 clean merged task worktrees plus the reconciled T-331 worktree. The plan
covered 30,549 entries and 353,953,953 logical bytes. A second immutable
manifest deleted only their 29 corresponding Git worktree registration
directories. Both applies verified protected anchors unchanged and every
target absent. Each mode-0600, one-link short-lived manifest was exact-unlinked
after successful verification.

Git now has only the primary checkout, the live held
`harness-t347-t345-controller-v8` worktree, and the active T-351 housekeeping
worktree. No merged branch ref was deleted.

## Remaining ledger action

The obsolete `After official ABQ restoration` queue item should be removed and
this audit linked from `TODO.md` only after the unrelated uncommitted T-350
checkpoint becomes durable or is withdrawn. Do not stage or overwrite that
change to close this housekeeping task.
