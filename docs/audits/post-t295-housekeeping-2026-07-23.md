# Post-T-295 housekeeping — 2026-07-23

## Scope

This checkpoint records routine cleanup after protected T-295 closeout PR #254
at `5d551883648760fcc373973a575a403b18637f44`. It contains no credential
values. The repository started clean on `main` with no stash, auxiliary
worktree, or local task branch.

## Lock-aware arg0 cleanup

Every target was classified by `harness codex-arg0-housekeeping`, quarantined
while locked, and removed by the emitted `harness guarded-delete` manifest.
Each apply verified its retained anchors unchanged and its target absent.

| Node | Before | Removed | Manifest | Quarantine target |
| --- | --- | ---: | --- | --- |
| local | `live=3 eligible=6 young=0 unexpected=0` | 6 | `/home/rioyokota/.codex/tmp/.harness-delete.oodRzV/manifest` | `/home/rioyokota/.codex/tmp/arg0-quarantine-20260722T145805Z-327919` |
| aist | `live=3 eligible=1 young=0 unexpected=0` | 1 | `/Users/rioyokota/.codex/tmp/.harness-delete.CPRO5c/manifest` | `/Users/rioyokota/.codex/tmp/arg0-quarantine-20260722T145832Z-21049` |
| home | `live=3 eligible=1 young=0 unexpected=0` | 1 | `/Users/yokotar/.codex/tmp/.harness-delete.Imjt9Z/manifest` | `/Users/yokotar/.codex/tmp/arg0-quarantine-20260722T145832Z-60556` |
| office | `live=3 eligible=1 young=0 unexpected=0` | 1 | `/Users/yokotar/.codex/tmp/.harness-delete.Mrdt2Z/manifest` | `/Users/yokotar/.codex/tmp/arg0-quarantine-20260722T145832Z-5605` |
| riken | `live=3 eligible=1 young=0 unexpected=0` | 1 | `/Users/yokotar/.codex/tmp/.harness-delete.CdNp0g/manifest` | `/Users/yokotar/.codex/tmp/arg0-quarantine-20260722T145832Z-11118` |

All five post-plans report
`live=3 eligible=0 young=0 unexpected=0 removed=0`. The five manifest
directories are absent. No Codex process was stopped.

## Exact residue checks

- Local `~/run_this.sh` and the Home, Office, and Riken authorization rollback
  and post-state files are absent.
- All four Mac `~/run_this.sh` paths, known guarded-delete manifest directories,
  and `.mac-tunnel-auth.*` temporary state are absent.
- Local Git had only `main`, one primary worktree, no stash, and no merged task
  branch requiring deletion.

## Fleet and next-task state

The 2026-07-23 00:01 JST snapshot reported `2/2` ready for Aist, Home, Office,
Riken, and ABQ. Local, ab, ab2, rc, ri, and t4 were ready. AL rejected the
current noninteractive authentication and remains an external access-state
exception; its completed T-295 terminal acceptance is not invalidated. `web`
remains service-only and outside managed health.

T-273 has no independently eligible workstream: its remaining items are date,
requirement, or selection gated. T-196's next safe action remains querying only
its recorded successor job IDs on or after 2026-07-26. The next owner-selected
task should use T-296.
