# Benchmark

## Identity

Target: T-366 branch/worktree named in the charter. Immutable baseline:
`3d96125514281ef071ba7ce0303185b6e3e8660e`. Live baseline: attached tmux
session `projects` (`$14`) with windows `@87` and `@106` and exact pane/process
identities recorded in `docs/tasks/T-366.md`.

## Observable cases

1. Static target model: exactly six declared locations—Codex Harness at
   `cowork.0`, Claude Harness at `cowork.1`, Codex Personal/Students at
   `codex.0/.1`, Claude Personal/Students at `claude.0/.1`—with exact cwd,
   title, role option, process, and no duplicates or extras.
2. Same-root identity: Harness and Personal can share the Harness cwd while
   launch and recovery require distinct explicit target/session identities;
   latest-by-directory and Claude `--continue` are rejected for same-root
   recovery.
3. Process preservation: `%87`, `%99`, `%108`, and `%109` retain pane IDs and
   PIDs through promotion; `%100` and `%110` remain until their product's
   Personal replacement passes every gate.
4. Resilience: Codex and Claude monitors classify healthy/dead/misordered,
   recover one exact dead pane, reject live/ambiguous/drifted panes, and avoid
   content reads across the mixed-window topology.
5. Remote control and messaging: both Personal replacements are phone-visible
   under distinct identities; existing Harness/Students roots remain valid;
   Local Codex↔Claude messages select `harness:cowork` exactly and reject a
   wrong role, cwd, window, process, or multiplicity.
6. Session UX: exact final window/pane order and even-horizontal layouts;
   `Ctrl-b z` remains functional; one attached client follows session rename;
   `att` resolves only to `tmux attach -t harness` on every managed host.
7. Rollback and non-interference: a synthetic pre-retirement failure restores
   exact source panes; no command reads pane/transcript content; T-363, T-354,
   monitor session topology, unrelated worktrees, and unrelated settings stay
   unchanged.
8. Repository quality: relevant focused suites, `git diff --check`, and
   `tests/test-phase1.sh` pass; release/sync manifests include every changed
   runtime dependency; protected publication and eligible fleet sync complete.

## Evidence and iteration method

Codex and Claude use separate detached sandboxes from the same commit. Each
records exact file/command evidence, bounded output, observations versus
inferences, and concrete criticism. At least one synthetic tmux experiment and
one same-root resolver/recovery experiment are required; prose alone does not
pass. After independent imports, reciprocal critique targets the strongest
claim. Any disagreement affecting identity, recovery, retirement, or remote
control is resolved by a matched deterministic test or remains a stop.

Implementation iterates only against failing benchmark cases. Runtime evidence
uses tmux/process/status metadata and owner phone confirmation, never pane or
transcript content. Preserve raw value-free failure classifications and do not
retry ambiguous launches or submissions.

## Stop condition

Stop before target execution if either native client is unavailable, either
agreement is absent, evidence is stale/unsealed, a safety disagreement remains,
or owner authority no longer matches. Stop before old-pane retirement on any
identity, resume, remote-control, process, monitor, attachment, or rollback
failure. Complete only when all eight cases pass on protected `main` and live
final state, with exact fleet-health and durable handoff evidence.

## Agreement

Pending independent evidence and reciprocal critique.
