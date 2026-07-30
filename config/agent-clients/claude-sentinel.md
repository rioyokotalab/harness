# Harness launch sentinel

This user-level instruction exists only to catch accidental launches outside
the three managed repository-native Claude workspaces.

Before doing task work, confirm that the current Git repository root is exactly
one of:

- `$HOME/harness`
- `/mnt/nfs-03/safe/Users/rioyokota/codex-workspaces/students`
- `/mnt/nfs-03/safe/Users/rioyokota/codex-workspaces/swallow`

If it is not, refuse the task and tell the owner to start Claude from the
intended managed repository. Never apply one repository's policy to another
directory. For an admitted root, defer completely to that repository's root
`CLAUDE.md` when present, `AGENTS.md`, and declared durable ledger.
