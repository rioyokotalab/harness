# T-351 three-project parallel-isolation benchmark

At epoch `1785425219` (2026-07-31 JST), four processes started together under
four private mode-0700 task roots. Three ran repository-native validation; the
fourth exited intentionally with status 23 to prove one failure does not
cancel or overwrite its peers. No command used tmux input, a recovery helper,
an app-server write, SSH, or Git mutation.

| Repository/probe | Exact revision/tree | Command | Result |
| --- | --- | --- | --- |
| Harness | `c41e690c3c7e8bb1d5d779f0c826976d1f7d80f3` / `664b0d0c78809c5bab7ac407c438a391dad83ba0` | `tests/test-context-routing-benchmark.sh && bin/harness validate --base HEAD` | pass in <1 s; native R0 exact-tree receipt emitted |
| Students | `dafb4a3f2963c2535ae9c4a5ecb133b1238b5598` / `7b32ca4e540c196645572e72fe641575db3cb423` | `uv run --frozen --no-sync tools/check.sh` | 481 tests + 29 subtests passed in 27 s |
| Swallow | `0e9029b1a8ca60a3c6b906bff0a475df7323e555` / `d66d5b3ac5b86d49281078d24ed9f0b3b0bfe63f` | `SW031_NVIDIA_RUNTIME_PLAN_MODE=render-only tests/test-static.sh` | static suite passed in 8 s |
| isolated failure | Harness task root, no repository mutation | `sh -c 'exit 23'` | expected failure at start epoch; all three peers still completed |

Each receipt binds branch, head, tree, command, result, platform, validator
digest, and start/finish epoch. Temporary receipt SHA-256 values were:

- Harness `ca92840b6f045355dfdbb8d115d2654e4e780fa1138015525aa21851db2a8c48`;
- Students `bf0b83b1b5ed049c5c3ad03edbb4cfb1b98b319c3eb0c58d4d81d569db8cd5f5`;
- Swallow `9b8e2568025aaac95fe2b72040a5e38a9e95f42f67b945653cb45769287dccf5`;
- expected failure `903cb475d65ea955eece556caa16c8e31fc24f28499aa0bcd1b111fa2394a59a`.

Before and after snapshots covered each repository's branch, commit, tree, and
porcelain status; known resilient/monitor/recovery lock-directory identities
and mtimes; and value-free `projects` window index/name/ID/PID/CWD/dead
metadata. The paired SHA-256 values were identical:

| Snapshot | Before and after SHA-256 |
| --- | --- |
| repository state | `3d2459e38eac337dcc413b7463668ce1250940ad2d69fb28527c6ebfe406fa43` |
| lifecycle locks | `ca03861933975427806c64a96f6425afb64abe28cc57f17d3a4e85fda14d57c9` |
| tmux metadata | `366542f3c5dda8e6f6c4e9531f8a2b7687ada68932df21cf15bbbfa8a5b9a88e` |

Thus all repositories remained clean and at their original trees, no lifecycle
lock was acquired or changed, no window/process mapping changed, and the
expected failure did not serialize or cancel Students or Swallow. Harness's
native receipt lived only under its Harness runtime root; Students' UV cache
and Swallow's temporary files stayed under their distinct roots. The private
raw logs and receipts are task-owned cleanup inputs after this tracked summary
is committed.
