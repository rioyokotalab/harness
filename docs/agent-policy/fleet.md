# Fleet policy

Read this file completely before the matching action selected by root
`AGENTS.md`.

## Fleet status

- Use `docs/fleet-inventory.md` for logical aliases, SSH entries, usernames,
  hostnames, and operating systems. Use `harness fleet-health`; never replace
  target-specific contracts with an agent-authored SSH loop.
- If a managed route unexpectedly fails, consult that system's official status
  or maintenance source before classifying it. A failed lookup is unknown.
  Report an exact maintenance window separately from readiness and do not probe
  a node whose current stop is already in the reviewed registry.
- Run fresh `harness fleet-health` for fleet/runtime work, unexpected route
  failure, before and after control-plane rollout, and at a long-job deadline
  or final handoff. Do not run it for every unrelated repository,
  documentation, or local-test turn. Report failed and unknown checks.
- In compact reports, `abq` is one Linux node and is ready only when both
  `abq` and `abq2` pass. The Mac total contains only aist, home, office, and
  riken.
- Assess `al` with `harness al-session --status` and normal multiplexed
  `ssh al true`. Do not disable `ControlMaster` or `ControlPath`; that tests new
  daily authentication rather than the managed route.

## Rollout and managed Mac checkouts

- After a merged control-plane change, use guarded `harness fleet-sync`
  plan/apply and advance only clean managed checkouts.
- After fleet sync advances a managed Mac, queue exactly one context-refresh
  instruction in its running `harness-codex-resume` session. Require one
  detached live session and one Codex pane rooted at `$HOME/harness`; never read
  panes, interrupt work, or respawn. Insert literal tmux input, wait at least
  one second, and submit `C-m` separately. Prefix `[Agent: Local Codex]` and
  instruct it to read `AGENTS.md` and `TODO.md`, inspect branch/worktree/commits,
  reconcile the durable next action, and remain idle in the same session. If
  absent, attached, or ambiguous, defer without injecting.
- On a personal Mac, `~/harness` is the live tunnel-control checkout: keep it
  on clean `main` and use a separate worktree for feature work. Any drift in
  runtime-critical scripts or public Mac profile inputs remains fail-closed.
