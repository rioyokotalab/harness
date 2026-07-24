# T-304 project-scoped agent configuration audit

Date: 2026-07-24 JST

## Outcome

Codex and Claude now receive harness behavior only when started from
`~/harness`. Root `AGENTS.md` contains the self-contained shared and
repository policy; root `CLAUDE.md` imports it. Reviewed permissions live in
`.codex/config.toml` and `.claude/settings.json`. All 13 canonical skills are
exposed through tracked `.agents/skills/` and `.claude/skills/` links.

User scope retains only:

- `~/.codex/AGENTS.md`, linked to the Codex launch sentinel;
- `~/.claude/CLAUDE.md`, linked to the Claude launch sentinel; and
- `~/.local/bin/harness-codex`, the existing managed launcher.

The sentinels refuse task work outside `~/harness` and give the exact restart
command. Legacy global Codex/Claude settings, the global Codex rule link, and
the 39 harness skill links are absent on all 12 systems. Authentication,
sessions, histories, memories, caches, databases, mixed Claude state, client
binaries, vendor `.system` skills, remote control, and tunnels were outside
the transaction and preserved.

## Publication and validation

- PR #285 passed protected `portable-phase1` and squash-merged as `19235ce`.
- The first read-only Local plan exposed a missing strict exception for the
  fleet's declared `~/.local` storage links. No live mutation occurred.
- PR #286 restored the host/profile/ownership/containment gate, added a
  linked-home regression, passed protected CI, and squash-merged as
  `309de20b3617f27bdb2cfe4d7fd1a36f2b56f5c6`.
- The complete clean-tree `tests/test-phase1.sh` suite passed.
- Focused agent-config, fleet, external-onboarding, Claude-takeover, source
  contract, Mac plan, and Mac control suites passed.
- External-user preflight finished with `schema=2`, `links_current=3`,
  `project_links=26/26`, and zero collisions.

## Rollout evidence

Local, AB, and Aist completed apply/rollback/reapply drills before the
remaining sequential rollout. Each final transaction remains available for
unchanged-only rollback:

| Host | Final transaction |
|---|---|
| local | `20260724T012643Z-948116` |
| ab | `20260724T012949Z-2220089` |
| ab2 | `20260724T013047Z-3683752` |
| ri | `20260724T013049Z-3722627` |
| al | `20260724T013055Z-37652` |
| rc | `20260724T013057Z-1634813` |
| t4 | `20260724T013100Z-3030584` |
| abq | `20260724T013103Z-2455570` |
| aist | `20260724T013003Z-36590` |
| home | `20260724T013112Z-59307` |
| office | `20260724T013118Z-25018` |
| riken | `20260724T013126Z-83049` |

The final per-host audit proved:

- clean `main` and exact public revision `309de20`;
- schema-2 doctor ready;
- 13 Codex plus 13 Claude project skill links;
- zero exact legacy harness global skill links;
- absent global harness Codex/Claude settings and global Codex rules;
- current sentinels and launcher; and
- no fleet-sync transfer residue.

## Mac session and connectivity evidence

Each Mac had one `harness-codex-resume` tmux pane running from `~/harness` and
two Codex daemon processes owned by PID 1. Aist's first graceful `/exit`
attempt timed out and stopped without a forceful action. Its attempted
child-only fallback also refused because the pane process was Codex itself.
The exact pane was then replaced with
`harness-codex resume --last` using tmux `respawn-pane`.

The same exact-pane method succeeded on Home, Office, and Riken. All four new
panes report `codex` in `~/harness`; the two pre-existing PID-1 daemon IDs on
each Mac remained identical. Tunnel supervisors remained
`running=yes managed=1 external=0`, and all eight Mac routes plus both ABQ
routes passed after the restarts.

## Rollback

For one host, run the current main checkout's unchanged-only rollback with its
transaction ID:

```bash
cd "$HOME/harness"
./bin/harness agent-config --rollback TRANSACTION_ID
```

Repository rollback requires a separate protected revert. Do not restore
legacy global configuration by hand or modify credential/runtime state.
