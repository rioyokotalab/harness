# T-364 post-cleanup audit — 2026-08-01

## Outcome

No intended tracked content requires restoration. The cleanup outcome is
usable, but its remote-deletion authority, worktree evidence, and long-term
restore guarantees are insufficient.

## Verified repository state

- `main` and `origin/main` are
  `dda8acac07a4e4f739228777e12a7d1bcf5d593f`.
- Git status is clean; one local branch and one registered worktree remain.
- `git fsck --full --no-dangling`, housekeeping tests, task-ledger routing,
  and `git diff --check` pass.
- Remote head inventory contains only `main`.
- Five former task worktree paths are absent:
  `harness-t352-pane-native-projects`, `harness-t353-claude-fallback`,
  `harness-t354-project-root-migration`, `harness-t355-personal-project`, and
  `harness-t356-personal-connectors` under `/tmp`.

## Branch deletion classification

The local mode-0600 receipt records four deleted branches and exact tips:

| Branch | Tip | Evidence |
| --- | --- | --- |
| `codex/t355-closeout` | `9616678281787210a83b38ce52ff41db1c7fa52a` | merged PR #496 |
| `codex/t355-personal-project` | `3f0abf311c7904e48ea679dd19d4382ae8831b60` | merged PR #495 |
| `codex/t356-owner-gate` | `38832307cace1b6690968dd44bfca0722672832f` | merged PR #499 |
| `codex/t356-personal-connectors` | `1804aee81428f46d2b9ca424209ab5b9bde79f0e` | merged PR #498 |

T-354 durably records clean native removal of two worktrees and branches:

- `codex/t354-project-root-migration` at
  `b36364af8ac0bde9e4e5097dfca47bb975f35482`; no PR, but its only task-record
  content is superseded by the substantially more complete current record.
- `codex/t355-rollout-record` at
  `8b9036093adece753e65f08ab8a869284a1d08ca`; merged PR #497.

T-362 records removal of closed PR #524 branch
`claude/t361-guard-selfmatch` at
`75877db1da4f099a02fba1b406e8a5be66cd31f5`. Its implementation and test bytes
match merged PR #525; only stale board/T-362 proposal content differs.

The later runtime receipt records 20 remote branch deletions. Nineteen are
covered by merged PRs #491, #494–#511 or by exact reachability from `main`.
The sole no-PR branch is the superseded T-354 tip above. One useful edge case
was observed: `codex/t356-riken-oauth-bridge` was deleted at tip
`3910e458b3a5b0454f98b6a02d640ef40f5fb442`, while merged PR #503 recorded an
earlier head; the deleted tip is nevertheless reachable from `main`. This
proves that matching only a branch name to any merged PR is unsound.

## Evidence and recovery defects

1. T-362 explicitly excludes remote-ref deletion, yet at least 20 remote refs
   were deleted. The only exact receipt is under `/run/user/5035`, not the
   tracked ledger.
2. Receipt SHAs are not retention roots. These seven checked tips currently
   have zero containing refs and may be pruned later:
   `b36364af8ac0bde9e4e5097dfca47bb975f35482`,
   `8b9036093adece753e65f08ab8a869284a1d08ca`,
   `75877db1da4f099a02fba1b406e8a5be66cd31f5`,
   `9616678281787210a83b38ce52ff41db1c7fa52a`,
   `3f0abf311c7904e48ea679dd19d4382ae8831b60`,
   `38832307cace1b6690968dd44bfca0722672832f`, and
   `1804aee81428f46d2b9ca424209ab5b9bde79f0e`.
3. T-354 records two worktrees as clean. No durable deletion receipt exists
   for the other three, so their former untracked and ignored state cannot be
   proven after the fact. Their tracked branch content is merged and safe.
4. The current local restore receipt and remote restore receipt are valid now:
   all recorded tip objects exist. That is a temporary fact until refs or a
   verified bundle protect them.

## Current non-target state

The independent Codex arg0 plan reports 35 live, 69 eligible, 0 young,
0 unexpected, and 0 removed. Fleet health passed Local, all Linux targets, and
all four Mac route pairs during the audit. Neither state was changed.
