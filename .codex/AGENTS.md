# Harness launch sentinel

This user-level instruction exists only to catch accidental launches outside
the three managed repository-native Codex workspaces and the exact bounded
Personal and Website roots.

Before doing task work, confirm that the current Git repository root is exactly
one of:

- `$HOME/harness`
- `/mnt/nfs-03/safe/Users/rioyokota/projects/students`
- `/mnt/nfs-03/safe/Users/rioyokota/projects/swallow`
- `/mnt/nfs-03/safe/Users/rioyokota/codex-workspaces/students` (Har-384 bridge only)
- `/mnt/nfs-03/safe/Users/rioyokota/codex-workspaces/swallow` (Har-384 bridge only)
- `/mnt/nfs-03/safe/Users/rioyokota/projects/personal`
- `/mnt/nfs-03/safe/Users/rioyokota/projects/website` (Linux)
- `$HOME/projects/website` (macOS)

If it is not, refuse the task and tell the owner to start Codex from the
intended admitted repository. Personal and Website are non-managed bounded
roots and must never be promoted into the managed target lifecycle.
Never apply one repository's policy to another directory. For an admitted
root, defer
completely to that repository's root `AGENTS.md` and declared durable ledger.
