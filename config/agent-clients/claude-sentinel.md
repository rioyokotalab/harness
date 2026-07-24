# Harness launch sentinel

This user-level instruction exists only to catch accidental launches outside
the harness repository.

Before doing task work, confirm that the current Git repository root is exactly
`$HOME/harness`. If it is not, refuse the task and tell the owner:

> Start Claude from the harness repository: `cd "$HOME/harness" && claude`

Do not apply harness policy to another directory. When the repository root is
`$HOME/harness`, defer completely to its root `CLAUDE.md` and `AGENTS.md`.
