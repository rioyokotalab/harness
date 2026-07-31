# Initial plan

## Confirmed facts and assumptions

Confirmed by direct observation at 23:21–23:25 local:

- F1. tmux session `projects` has exactly one window `codex` with 3 panes,
  even-horizontal (50 columns each at 152 width), working directories
  `/home/rioyokota/harness`,
  `/mnt/nfs-03/safe/Users/rioyokota/codex-workspaces/students`,
  `/mnt/nfs-03/safe/Users/rioyokota/codex-workspaces/swallow`; each pane's
  foreground command is currently `sh`.
- F2. `claude` 2.1.220 at `~/.local/bin/claude` supports `--model`,
  `--effort`, and `--fallback-model`.
- F3. harness worktree is clean except three untracked NFS silly-rename files
  `libexec/.nfs*` (open-handle residue; preserved, not deletable safely).
- F4. Repositories exist at: `~/harness`, `codex-workspaces/{students,swallow}`,
  `projects/{personal,website,students,students-recovery}`.
- F5. harness board active tasks are all blocked or time-gated (T-354, T-196,
  T-328, T-303); next free ID is T-358.

Assumptions (to verify or falsify during execution):

- A1. Weekly limit reset at ~04:21 local (owner statement "in 5 hours" at
  ~23:21). Switch-back at 04:25 gives margin.
- A2. Interactive `claude` accepts `/model fable` at its prompt regardless of
  whether fallback engaged; sending it to a non-degraded session is a no-op
  risk-free command.
- A3. Each non-harness repository has its own `TODO.md` and instruction files;
  where absent, survey falls back to git history and open records.
- A4. The three admitted Claude roots for pane launches are exactly the pane
  working directories (per user-level sentinel).

## Steps

1. Ledger: create `docs/tasks/T-358.md`, add board entry, bump next free ID
   to T-359. Validation: board diff review; no other record touched.
2. Cowork protocol: build baseline + two sandboxes, stage independent codex
   pass over the charter/plan/benchmark, import, produce driver evidence
   (including a disposable tmux layout experiment in a scratch session),
   reciprocal stage, reconcile, record both agreement lines, advance
   planning → discussing → ready-for-execution → executing.
   Validation: `cowork-session check` passes at each advance.
3. tmux target execution: preflight capture of live dimensions and the full
   `codex` window fingerprint; `new-window -n claude -P -F '#{pane_id}'` and
   two `split-window -h -P` with `-c` per directory, each running
   `exec claude --model fable --effort high --fallback-model opus` directly
   as the pane command (no residual shell); `select-layout even-horizontal`
   applied idempotently. Validation: C1 argv check via `/proc`, C2 pre/post
   fingerprint compare, immutable pane IDs recorded for the timer.
4. Switch-back timer: detached identity-checked script embedding only the
   three fixed pane IDs; at 04:25 it re-verifies each pane (live, expected
   path, claude/node process; generic shell fails closed), sends literal
   `/model fable` then separate Enter exactly once per surviving pane, logs
   staged outcomes (C3), and records pane titles as advisory application
   evidence only. No unattended C-u/Escape/C-c clearing; a quiet barrier
   stops driver-initiated pane submissions after 04:10. Validation: timer
   PID + start time + script digest recorded; staged log inspected at 04:25+.
5. Repo survey (harness, students, swallow, website, personal): read each
   repo's closest instructions and `TODO.md`; record per-repo issue list
   ranked autonomy > efficiency > safety in `execution.md`.
6. Development iterations per repo under its own policy: small steps, owning
   checks, batched commits; at most one coherent PR per private repository
   this run. Checkpoint each material result in T-358 and `execution.md`.
7. 04:25: confirm switch-back fired. ~05:00 co-pilot read-only challenge of
   the integrated diff. 05:00–05:30 final validation window: frozen
   acceptance checks, `validation.md`, durable and final summaries (7 slices,
   ≥350 words each), handoff block in T-358.

## Evidence questions

- Q1. Does the pane-split sequence produce ≤1-column width variance at the
  current 152-column geometry, and is `even-horizontal` idempotent there?
- Q2. Does `send-keys` of a slash command into an idle interactive claude
  prompt execute reliably without a preceding clear (C-u) — and is C-u safe?
- Q3. Is `--fallback-model` accepted in interactive mode in 2.1.220 (not just
  `--print`)?
- Q4. What is the cheapest per-repo validation that still satisfies each
  repository's own proportional-validation rule?
- Q5. Strongest open question for the co-pilot: what failure modes exist in
  the 04:25 switch-back (pane renumbering, window renaming, claude exited,
  input box non-empty) and which mitigation is cheapest?

## Risks and recovery

- R1. Pane drift if a pane dies overnight → the timer holds immutable pane
  IDs captured at creation and re-verifies identity (path + process) before
  each send; a dead, replaced, or shell pane is skipped fail-closed and the
  miss is recorded. Indices and window names are never used for targeting.
- R2. Fable weekly limit hits this driver session itself → continue the turn
  on native fallback where eligible; for delegated work prefer subagent model
  override to Opus; record limit evidence, never replay prompts blindly.
- R3. A repo's remote requires unavailable authentication → record as blocked
  with exact error; a failed query is unknown, not absence; continue other
  repos.
- R4. Context summarization mid-run → all state recoverable from T-358,
  `execution.md`, and Git; resume contract is the harness board rule.
- R5. Sandbox/stage crash ambiguity → stop that stage, keep seal + stage
  evidence, start a fresh stage; never relaunder or blindly retry.
- R6. NFS latency (see board T-303) may slow `projects/*` repos → prefer
  batched reads, record latency evidence, do not retry unverified paths
  aggressively.
