# Fleet policy

Read completely before root `AGENTS.md` selects this route.

## Fleet status

- Get aliases, SSH entries, users, hosts, and operating systems from
  `docs/fleet-inventory.md`. Use `harness fleet-health`, never an SSH loop that
  bypasses target contracts.
- After an unexpected managed-route failure, consult that system's official
  status or maintenance source before classifying; a failed lookup is unknown.
  Report exact maintenance separately and skip probes during a current stop in
  the reviewed registry.
- Run fresh `harness fleet-health` for fleet/runtime work, unexpected route
  failure, before and after control-plane rollout, and at a long-job deadline
  or final handoff. Do not run it for every unrelated repository,
  documentation, or local-test turn. Report failed and unknown checks.
- Compact reports require both `abq` and `abq2` for `abq`; only aist, home,
  office, and riken count as Macs.
- Assess `al` through `harness al-session --status` and multiplexed
  `ssh al true`. Keep `ControlMaster` and `ControlPath`; disabling them tests
  daily authentication instead of the managed route.

## Rollout and managed Mac checkouts

- After a merged control-plane change, guarded `harness fleet-sync` plan/apply
  may advance only clean managed checkouts.
- After fleet sync advances a managed Mac, queue one refresh in its running
  `harness-codex-resume` only if exactly one detached live session and one Codex
  pane rooted at `$HOME/harness` exist. Defer if absent, attached, or ambiguous;
  never read panes, interrupt, or respawn. Insert literal tmux input, wait at
  least one second, and submit `C-m` separately. Prefix `[Agent: Local Codex]`
  and instruct it to read `AGENTS.md` and `TODO.md`; inspect branch, worktree,
  and commits; reconcile the durable next action; and remain idle there.
- On a personal Mac, keep live tunnel-control `~/harness` on clean `main` and
  use another worktree for features. Runtime-script or public Mac-profile drift
  remains fail-closed.
