# T-314 Local Slack connector recovery

**Phase:** interviewing
**Driver:** Local Codex
**Updated:** 2026-07-27 JST

## Outcome and scope

Restore Local Codex's read-only access to the already-authorized
`RioYokotaLab` Slack workspace, prove that `#swallow` search remains available
across two owner turns, and determine whether the persistent remote-control
app-server lifecycle caused the connector tool loss.

In scope:

- Local's existing Codex 0.145.0 remote-control app server;
- the already-installed and enabled Slack plugin at marketplace revision
  `11c74d6b`;
- both existing supervised Local TUIs, which must be preserved;
- one new Slack-attached chat and two bounded read-only acceptance queries;
- a narrow documentation or launcher-adjacent correction only after causal
  evidence exists.

Out of scope:

- reading, printing, hashing, copying, replacing, or requesting credentials;
- Slack writes, authorization-scope changes, organization administration, or
  broader workspace ingestion;
- plugin reinstall/removal/upgrade, configuration edits, pairing changes, or
  another connector;
- signaling either TUI, changing supervisors, remote-node changes, compute
  jobs, or modifying the Swallow runtime;
- automatically restarting remote control on every TUI launch.

## Confirmed facts

1. Local runs Codex 0.145.0. Native doctor passes configuration, local auth,
   state databases, network reachability, websocket, and persistent app-server
   checks.
2. `slack@openai-curated` and `github@openai-curated` are installed and enabled
   on Local at marketplace revision `11c74d6b`. T4 reports both plugins not
   installed, so T4 did not supply this chat's earlier Slack tool calls.
3. This Local-backed chat successfully listed workspace `RioYokotaLab` and
   returned current `#swallow` search results once. Later workspace and message
   reads returned `unsupported call` at the Codex tool boundary before reaching
   Slack. A new chat and then the exact
   `[@Slack](plugin://slack@openai-curated)` mention did not restore the tools.
4. Local has two independent live supervisors: `swallow-research` with a new
   TUI from 2026-07-27 02:11 JST, and `harness` with its resumed TUI. The
   separate current-user remote-control app server is PID `3676694`, started
   2026-07-22 11:14 JST.
5. `harness-codex-resilient` manages only its foreground TUI and invokes
   `harness-codex-login`; it never starts, stops, or refreshes the app server.
   A fresh TUI therefore does not imply a fresh connector-serving daemon.
6. The current Codex manual documents native `codex remote-control stop` and
   `codex remote-control start`. Existing pairing normally survives ordinary
   server recovery, but pairing is not guaranteed and remains an owner-only
   boundary.
7. `codex remote-control status --json` returned no usable result during one
   read-only probe. It changed no state. Process identity and redacted native
   doctor evidence will therefore be the restart acceptance signals.

## Execution sequence

1. Reconstruct this plan, Harness and Swallow ledgers, both repository states,
   plugin status, both supervisor identities, and the exact old app-server
   process identity. Stop on drift, ambiguity, dirty unrelated state, or a
   missing TUI.
2. Update Swallow's SW-031 handoff with the failed explicit plugin attachment
   and this T-314 recovery pointer. Commit and push both repositories before
   any signal so interruption is recoverable from Git alone.
3. Run native `codex remote-control stop` once. Require a successful exit and
   require only the captured old app-server PID to disappear. Do not signal a
   PID directly, inspect sockets, or touch either TUI.
4. Run native `codex remote-control start` once. Require exactly one
   current-user `app-server --remote-control --listen unix://` process with a
   new PID/start identity. Require redacted doctor to pass app-server,
   websocket, auth, state, and installation checks.
5. Require both pre-existing resilience supervisors and their TUI children to
   remain live. If either changes unexpectedly, stop and reconcile from its
   value-free supervisor state; never replay a prior owner prompt.
6. The owner starts one new chat from `$HOME/harness` and sends the exact Slack
   plugin mention. First acceptance turn: list `RioYokotaLab`, then search only
   `#swallow` for `Qwen3`.
7. On a separate owner turn without reinstalling or restarting anything,
   search `#swallow` for `Megatron`. This distinguishes one-turn lazy tool
   loading from durable chat connector availability.
8. If both turns pass, record causal evidence as “app-server refresh repaired
   the observed state,” not as a general Codex guarantee. Add the smallest
   durable operational guidance: plugin/app changes require one explicit,
   controlled remote-control refresh before starting a plugin-backed chat.
   Do not make ordinary TUI launches restart the shared server.
9. If either turn still returns `unsupported call`, classify the restart
   hypothesis as rejected. Restore/retain the ready server, record a product
   tool-registration blocker, and do not modify the launcher to hide it.

## Safety and recovery

- The stop/start experiment is Local-only. The four Mac app servers, remote
  Linux nodes, schedulers, SSH routes, and external Slack state remain
  untouched.
- This chat's remote-control view may disconnect while the server restarts.
  Both TUI processes are separate and must remain alive. Git checkpoints are
  the recovery source.
- Rollback from a stopped or failed server is the unchanged native
  `codex remote-control start`. If native start fails, preserve the output
  privately, leave both TUIs running, and stop for diagnosis.
- If pairing is not retained, do not run `pair`, inspect a code, or alter
  authorization. Ask the owner to use the native pairing UI, then revalidate.
- Never infer Slack authorization failure from `unsupported call`; only a
  connector-provided authorization result can establish that state.

## Acceptance

- One new Local app-server identity is ready after one native stop/start, with
  both existing supervised TUIs still live.
- Native redacted doctor passes app-server, websocket, auth, state, and
  installation checks.
- The Slack plugin remains installed/enabled at the same revision; no settings,
  credentials, pairing, or external messages changed.
- A Slack-attached new chat lists `RioYokotaLab` and returns a bounded
  `#swallow` `Qwen3` search, then a second turn returns a bounded `Megatron`
  search.
- Harness and Swallow carry exact durable evidence, pass their relevant static
  checks, and are published through their normal protected workflows.

## Decision register

### D-001 — Execute the one-time Local remote-control restart

- **Recommended: yes.** This is the smallest experiment that distinguishes a
  stale persistent app server from a product-level per-turn tool-registration
  defect. It temporarily interrupts remote control but preserves the TUIs and
  has one native start rollback.
- **Alternative: no.** Keep the current server and stop Slack-dependent
  SW-031 work; the cause and Local connector availability remain unresolved.
- Reinstalling the plugin is rejected: exact installed/enabled state already
  passes and reinstall would add mutation without testing the leading
  lifecycle hypothesis.
- **State:** awaiting owner decision and explicit `go`.

## Next action

Ask D-001 only. After the owner selects the recommended restart, checkpoint the
decision, set `ready-for-go`, and wait for a separate explicit `go`. Do not
signal the live server during planning or interviewing.
