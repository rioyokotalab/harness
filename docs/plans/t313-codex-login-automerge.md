# T-313 repository auto-merge and login-node Codex limits

## Outcome and scope

Enable GitHub's repository-level auto-merge capability for Harness, Students,
Swallow, and Website; add a portable Harness Codex launcher that limits Rayon
and Tokio worker pools on Linux login nodes; expose it through the shared shell
policy; and gracefully move the five currently running Local/Mac Codex TUIs
under the published resilient supervisor.

This task does not enable auto-merge on any pull request, change rulesets or
required reviews, submit compute jobs, alter credentials or native Codex
installations, restart remote-control app servers, or apply thread limits on
macOS.

## Confirmed baseline

- GitHub reports `allow_auto_merge=false` on all four repositories. Their
  existing rulesets, required checks, review gates, and merge methods remain
  independent.
- `RAYON_NUM_THREADS=8 TOKIO_WORKER_THREADS=8 codex --version` returns the
  expected Codex 0.145.0 result on Local, AB, AB2, RI, AL, RC, T4, and ABQ.
  The targets expose 8–288 logical CPUs across x86-64 and AArch64.
- The native Codex binary contains both `RAYON_NUM_THREADS` and
  `TOKIO_WORKER_THREADS` runtime symbols. The live version probe establishes
  compatibility, not a general performance claim.
- `shell/common-aliases.sh` currently defines `codex` as a function that invokes
  `harness-codex`. Interactive startup sources this file on every managed
  system.
- Local already runs `harness codex-resilient --run --name harness --last`.
  Each Mac has one detached live `harness-codex-resume` pane running an
  unsupervised Codex client. Their remote-control app servers are separate and
  must remain running.

## Frozen execution order

1. Resolve the one user-facing alias decision below.
2. Add failing focused tests for Linux-only environment injection, argument
   preservation, macOS non-injection, command help/dispatch, and shared alias
   behavior.
3. Add `harness codex-login`, which invokes `bin/harness-codex` with both
   limits set to 8 only on Linux. Keep the ordinary macOS launcher unchanged.
4. Update the shared alias policy and owner documentation. Pass syntax,
   ShellCheck, focused tests, `git diff --check`, and the complete phase-one
   suite.
5. Re-read all four repository settings, enable only `allow_auto_merge` through
   the native GitHub API, and require exact true readback. Do not opt any pull
   request into auto-merge.
6. Publish through protected Harness CI, merge, and guarded-sync all eleven
   clean remote checkouts. Validate the alias and live version command on all
   eight Linux targets.
7. Gracefully stop and respawn each detached Mac pane one at a time under
   `harness codex-resilient --run --name harness-codex-resume --last`, preserving
   both routes and the remote-control app server. Validate exact session,
   supervisor, child, path, and route state before continuing.
8. Schedule Local last: use an external current-user helper to send the
   foreground TUI an interrupt, wait for its exact process/session transition,
   and respawn the same pane under `harness codex-resilient --run --name
   harness --last`. Preserve the remote-control app server. Because this
   controller is that TUI, final validation is resumed from the repository
   ledger after reconnection rather than replaying the request.

## Safety, rollback, and acceptance

- Repository-setting mutation is four exact `PATCH /repos/OWNER/REPO` calls
  changing only `allow_auto_merge`; rollback sets the same field to false.
- The launcher must `exec` the existing policy wrapper, accept no configuration
  or secret input, preserve arguments exactly, and allow an explicitly supplied
  lower thread limit only if the frozen implementation test chooses that
  contract. No global environment or product setting changes.
- A Mac restart proceeds only with one detached live pane, one current-user
  Codex TUI, a clean/current checkout, both routes healthy, and a separate live
  remote-control app server. Stop on ambiguity; never inspect pane contents.
- Local restart is last and must leave a durable next action before signaling
  the current controller. Never replay this owner request after reconnection.
- Acceptance requires exact GitHub setting readback, protected CI, clean
  eleven-node convergence, Linux command/alias validation, five supervised
  TUIs, unchanged live remote-control app servers, zero task helper residue,
  and canonical fleet health.

## Decision register

- **D-001 — Shared command spelling (confirmed):** `codex` always invokes
  `harness codex-resilient --run --name harness --last`. The supervisor launches
  through `harness codex-login`, which applies both eight-thread limits on
  Linux and leaves macOS unrestricted. `harness-codex` remains the explicit
  fresh or unsupervised escape hatch. The owner confirmed this combined
  persistent path and ordered immediate all-node deployment.

## Current checkpoint

**Phase:** complete.

Read-only discovery and live version compatibility checks are complete. D-001
is frozen and the owner gave explicit go. No target state changed before go.
GitHub API authentication identified the owner account, and four exact
repository updates enabled only `allow_auto_merge`; immediate readback is true
for Harness, Students, Swallow, and Website. No pull request was opted in.
The combined launcher, resilient route, common alias, documentation, and
focused coverage are committed as `2b4a437`. The clean four-worker complete
suite passed all 75 focused suites and every integration gate. Protected PR
#332 passed and merged as `12054b9`; a clean full clone synchronized all eleven
remotes after the live Local supervisor's NFS placeholder correctly blocked
the ordinary source checkout. Exact launcher and alias readback passes every
Linux target. T4 and all four Macs now run under the supervisor; Mac remote
control and dual routes remain ready. Local then restarted through the reviewed
handoff, returned under the published supervisor, and released the expected NFS
placeholder without manual removal. Local, T4, and all four Macs report running
managed supervisors. The launcher syntax, ShellCheck gate, and focused Linux
routing test pass.

All eleven remote checkouts independently report clean `main` at exact merge
`12054b9`, aligned `origin/main`, one worktree, and zero stashes. Exact GitHub
readback remains true for all four repository auto-merge capabilities. Two
fresh guarded manifests deleted only the recorded rollout clone and worktree
with protected anchors unchanged; stale worktree metadata was pruned, and the
reviewed restart helper, runner, private value-free log, message, and manifests
are absent. Canonical fleet health passes every Linux node, both ABQ routes,
and both routes for each managed Mac. No pull request was opted into auto-merge,
no remote-control server was restarted directly, and no macOS thread limit was
introduced.
