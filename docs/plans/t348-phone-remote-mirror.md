# T-348 phone remote-control mirror

**Phase:** provisional bridge accepted; awaiting physical-phone confirmation
**Driver:** Local Codex
**Updated:** 2026-07-30 JST
**Branch:** `codex/t348-phone-mirror`
**Working tree:** `/tmp/harness-t348-phone-mirror`

## Objective

Restore one phone-visible Swallow root and make the Local monitor continuously
require one-to-one parity between the canonical tmux windows and the
phone-eligible remote-control roots:

| tmux window | required active root |
| --- | --- |
| `harness:0` | `harness` |
| `harness:1` | `students` |
| `harness:2` | `swallow` |

The first repair must preserve the current Swallow root and process chain until
a distinct replacement is accepted in both a provisional tmux window and the
owner's phone. It must never rewrite source metadata in SQLite or a rollout.

## Confirmed diagnosis

Read-only discovery on protected `main`
`4b75af573ca4c9b475861f6718bb2b5ed7dbfd12` established:

1. The repository is clean and aligned. The canonical project topology is
   `@87/0:harness,@88/1:students,@93/2:swallow`; the monitor topology is
   `@40/0:tunnel,@95/1:codex,@97/2:helper`.
2. The monitor reports three healthy process/watcher/socket chains. The helper
   is idle with only its immutable historical failed event. One tmux client is
   attached to Students.
3. SQLite contains exactly the three canonical unarchived top-level Harness-cwd
   roots, with exact role names, active-session rollout paths, and existing
   rollout files. Native doctor passes all 18 checks and exactly one managed
   remote-control app server is live.
4. Harness and Students are recorded with interactive source `vscode`.
   Swallow is recorded with source `exec`.
5. Codex's documented `thread/list` default includes only interactive
   `cli` and `vscode` sources. It excludes `exec`. This explains why every
   existing monitor/database check passes while Swallow is absent from the
   phone-facing interactive history.
6. Native Codex exposes no supported phone-device session-list or render-state
   status command. The host can prove remote-control health and interactive
   thread eligibility, but only the owner can prove that a particular row is
   rendered on the physical phone.

No pane, transcript, turn, message, tool, or private helper-log content was
read. No app-server control connection, process signal, tmux mutation,
repository setting, or external write ran during diagnosis.

## Authority and exclusions

The owner's request authorizes planning the narrow repair and reusable monitor
extension. Execution still waits for the separate `go` required by the
repository's Plan-Interview-Execute workflow.

In scope:

- focused Harness implementation, tests, documentation, protected publication,
  and Local monitor/helper activation;
- one bridge-first replacement of only the noninteractive canonical Swallow
  root;
- reversible archive of the retired exact Swallow root after replacement and
  phone acceptance;
- value-free SQLite/process/tmux/app-server metadata checks.

Out of scope:

- pane or transcript reads, rejected-prompt reconstruction or replay;
- direct SQLite or rollout source rewriting;
- deleting a saved root or permanently discarding history;
- signaling or restarting the shared app server;
- moving or detaching the owner's tmux client;
- changing Harness or Students roots, project work, credentials, pairing,
  plugins, connectors, MCP state, settings, or hosting rules;
- claiming physical-phone rendering from local metadata alone.

## Frozen design

### 1. Phone-eligibility receipt

Extend the existing recovery helper's noninterfering SQLite observation. Every
interval it writes one mode-0600 `phone-mirror.json` receipt containing only:

- freshness and one exact managed remote-control process identity;
- exact canonical role count;
- per-role booleans for tmux mapping, unarchived state, exact role name, exact
  Harness cwd, active-session rollout location/existence, and interactive
  source (`cli` or `vscode`);
- exact non-subagent active top-level count and value-free mismatch classes.

The receipt never stores titles, previews, messages, commands, rollout
contents, socket paths, or unrelated root identifiers. Unknown database,
process, path, source, or topology state is unavailable rather than healthy.

### 2. Monitor integration

The tmux monitor remains pane-blind and does not open an app-server control
connection. It reads the fresh helper receipt and adds
`phone_mirror=healthy|degraded|unavailable` to its private receipt and compact
status. Overall health requires:

- the existing three healthy tmux/process/watcher/socket chains;
- exact window order;
- one fresh helper receipt;
- exactly three phone-eligible canonical roots and no extra active top-level
  root.

A source-ineligible canonical root is degraded even when its TUI is healthy.
The helper reserves one deduplicated immutable `phone-mirror-drift` event.
Known terminal or ambiguous events are never retried.

### 3. Initial Swallow bridge

After merged-code preflight, pause automatic helper event execution while the
first repair is controller-owned. Under the shared agent-message lock:

1. revalidate Git, exact current topology, client selection, all three process
   chains, watcher receipts, app-server identity, current three-root metadata,
   and the Swallow `exec` source mismatch;
2. pause only the three exact watcher leaves and open one initialized
   app-server connection;
3. create exactly one new empty root with `thread/start` through the proven
   interactive app-server client path, exact Harness cwd, Sol/high, granular
   approval policy, and disabled sandbox;
4. require exact new identity, source `vscode`, active-session rollout,
   canonical metadata, and an unambiguous acknowledgement; never retry an
   ambiguous start;
5. name it uniquely `swallow-phone-bridge-20260730`, tighten only its validated
   current-user single-link rollout to mode 0600 if installed Codex creates it
   more broadly, and close the connection once;
6. launch exactly one provisional tmux window at free index 3 with distinct
   runtime `swallow-phone-t348`, then submit one generic cold-start instruction
   that reconstructs solely from complete repository instructions, durable
   ledgers, Git, and mutable external state;
7. require an assistant-bearing completed turn without `systemError`, an
   attempt-zero supervisor/watcher/TUI/socket chain, interactive source, and
   inclusion in host `thread/list` under the default interactive-source
   contract.

Every request, launch, input submission, name write, and signal is reserved
before execution. An acknowledged or ambiguous operation is never repeated.

### 4. Physical-phone gate and promotion

Keep old `@93/2:swallow` fully live while provisional index 3 is validated.
The owner must confirm that `swallow-phone-bridge-20260730` appears on the
phone before any old-root name transfer, process retirement, or archive.
Local host eligibility alone does not satisfy this gate.

After that confirmation:

1. rename the old exact root to `swallow-retired-20260730`;
2. rename the accepted new root to `swallow`;
3. stage the old window away from index 2, move the accepted bridge to index 2,
   and promote it by rename only;
4. require the owner's exact tmux client selection to remain unchanged;
5. signal only the old exact real TUI leaf once and require its launcher,
   watcher, supervisor, pane, and window to exit without a second signal;
6. reversibly archive only the retired old root after exact zero-reference and
   inactivity proof;
7. require exact three-root phone-eligibility receipt, exact three-window
   topology, two interval-separated healthy monitor/helper receipts, native
   doctor, focused and complete tests, and fresh fleet health.

The old rollout remains recoverable with native `codex unarchive`. No delete is
authorized.

### 5. Future automatic behavior

Future source/name/archive/path drift produces a deduplicated helper event.
The helper may perform the same bridge-first replacement only for one exact
unattached, idle canonical target with healthy peers and unchanged app-server
identity. Active, attached, multiple-target, unknown, ambiguous, or
physical-phone-only failures remain report-only.

Because Codex has no supported API for the rendered phone list, the monitor's
durable claim is deliberately named **phone eligible**, not **phone rendered**.
If all host gates pass but the phone still omits a root, preserve all live
state and report a product-side remote-control visibility problem for owner
confirmation; do not churn roots automatically.

## Implementation and validation

1. Add failing-first helper and monitor fixtures for the current
   `vscode,vscode,exec` mismatch.
2. Implement private phone-eligibility receipts, compact status, stale/unknown
   refusal, exact source/path/name/archive checks, and deduplicated event
   identity.
3. Extend the worker/controller contract for one source-ineligible canonical
   root and retain every bridge-first, no-replay, no-pane, and non-retry gate.
4. Prove all-interactive healthy state, one `exec` canonical degradation,
   missing/archived/name/path mismatches, extra top-level preservation,
   subagent exclusion, stale receipt refusal, duplicate-event non-retry, and
   actual-phone uncertainty.
5. Run Python 3.6 syntax, ShellCheck where applicable, focused helper/monitor/
   recovery/resilience suites, `git diff --check`, and complete
   `tests/test-phase1.sh`.
6. Fetch again, integrate non-conflicting work, publish through protected
   exact-head CI without changing the owner-selected zero-approval policy, and
   activate only the exact merged code.
7. Execute the initial bridge through the physical-phone gate above.

## Failure and rollback

- Before any app-server request: stop with no live mutation; a corrected
  preflight may retry.
- After a sent/acknowledged/ambiguous request, launch, input, promotion,
  archive, or signal: never retry it. Preserve exact state and reconcile from
  the durable journal.
- Before phone confirmation: preserve both old and provisional chains. Retire
  neither one automatically.
- Phone confirmation fails: leave the old canonical Swallow untouched;
  preserve and uniquely classify the provisional root for a separately frozen
  reversible archive.
- Post-promotion failure: preserve the accepted new root and revert only
  rename/topology operations whose exact acknowledgements and safe preimages
  are known. Never recreate or replay the old task prompt.
- Product-side phone omission with all host eligibility gates healthy:
  report-only; do not restart the app server or create repeated roots.

## Decision register

### D-001 — Repair method

**Selected recommendation:** create a new interactive app-server root and use
bridge-first cold-start recovery. Do not rewrite the existing root's immutable
`exec` source metadata.

### D-002 — Retirement gate

**Selected recommendation:** require explicit physical-phone confirmation of
the provisional root before old Swallow retirement and reversible archive.

### D-003 — Monitor claim

**Selected recommendation:** enforce and report `phone eligible` from
supported host metadata. Do not claim or auto-repair physical rendering when
the product exposes no supported phone-list status API.

### D-004 — Changed-input start after request 5

**Owner-authorized:** send exactly one distinct newly journaled
`thread/start` after the published proven-absent reconciliation. Omit `model`
and `config` from that request and require the returned root and persisted
metadata to resolve to the verified Sol/high defaults. Request ID `5` remains
non-retryable.

**Result:** controller v4 sent the authorized start exactly once as
new-connection request ID `6`, after using request ID `5` only for an exact
read-only loaded-root check. Request ID `6` returned
`thread-start-ambiguous` with no usable root identity. Database, complete
top-level list, and loaded-root reconciliation again prove exactly the
original three roots and no provisional name. The authorization is consumed;
request ID `6` must not be retried.

### D-005 — Experimental-capable handshake after request 6

**Owner-authorized:** send exactly one newly journaled `thread/start` on a new
app-server connection whose initialize request includes
`capabilities.experimentalApi=true`. Retain granular approval, disabled
sandbox, exact Harness cwd, and omitted `model`/`config` fields. Requests `5`
and `6` remain consumed and non-retryable, and every bridge-first and
physical-phone confirmation gate remains unchanged.

**Result:** controller v5 sent the one start as experimental-capable request
`7` and acknowledged root
`019fb1ab-b559-79c2-ad9c-0ee8f426cedc`. Request `9` acknowledged its unique
provisional name. Both operations are consumed and non-retryable. The
controller stopped before launch because Codex 0.145 left model and reasoning
columns null for the empty root and created its current-user, one-link rollout
as mode 0664. The acknowledged response had already validated resolved
Sol/high, granular approval, disabled sandbox, exact cwd, and `vscode`
source. Read-only reconciliation confirms the root remains idle, zero-turn,
loaded, and absent from the default interactive list before its first turn.
All paused processes resumed and all old state is unchanged.

## Next action

Implementation passed complete validation and merged through protected PR
#442 as `c3895805b79c772c0bad58f6b4f792914fa2c89f`; merged-code monitor/helper
activation correctly reports only `interactive_source:swallow`.

The first initialized live `thread/start` was sent as request ID `5` but
returned without a usable acknowledgement or root identity. Database,
all-source top-level list, and loaded-thread readback each proved exactly the
original three roots and no provisional name. The owner has now separately
authorized one changed-input start after reviewing that proven-absent result.

Prelaunch result PR #447 merged as
`4ada98b0c8d53ba28d3254d22098667f663b77e0`. The one-shot launch receipt
acknowledges mode-0600 tightening of only the accepted rollout and provisional
window `@98/3:swallow-phone-bridge-20260730`. Its supervisor, watcher, and TUI
are live at attempt zero against the exact accepted root; the sole owner
client remained on Harness.

The separately journaled generic cold-start paste and delayed submit were each
acknowledged once. Value-free app-server inspection proves one completed
assistant-bearing turn, no error, idle status, exact interactive source/cwd,
exact provisional app-server name, and default interactive-list inclusion.
The database persists resolved model `gpt-5.6-sol`; Codex 0.145 leaves the
reasoning-effort and custom-name columns null, while the acknowledged start
response proves `high` and the live app server returns the exact provisional
name. No pane or transcript content was read and no name request was repeated.

Stop at the physical-phone gate. Preserve old `@93/2:swallow` and provisional
`@98/3` exactly. The owner must confirm that
`swallow-phone-bridge-20260730` appears in phone Remote before any rename,
topology move, process signal, retirement, archive, or promotion. All prior
start, name, launch, paste, and submit operations remain consumed and
non-retryable.
