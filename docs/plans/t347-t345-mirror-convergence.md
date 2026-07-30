# T-347 T-345 mirror convergence

**Phase:** frozen; owner authorized execution
**Driver:** Local Codex
**Updated:** 2026-07-30 JST
**Branch:** `codex/t347-t345-mirror-convergence`
**Working tree:** `/tmp/harness-t347-t345-mirror-convergence`

## Objective

Complete only T-345's recorded phone/tmux mirror convergence after its first
ephemeral worker failed. Reversibly archive the three already classified
noncanonical top-level roots and correct the two canonical name mismatches
through one deterministic, metadata-only app-server transaction. Preserve the
live monitor, helper, project clients, shared app server, failed event, and
private failed-worker log.

The accepted final active mapping is:

| tmux window | canonical root | required phone name |
| --- | --- | --- |
| `harness:0` | `019fa3ae-6ad0-7642-aeca-b7b52421f576` | `harness` |
| `harness:1` | `019f7fea-4f00-7681-910d-81ae99a77143` | `students` |
| `harness:2` | `019fafef-5ebf-72f1-b1ce-2444e7570dc1` | `swallow` |

The frozen archive candidates are:

| classification | exact root |
| --- | --- |
| old exec | `019f6271-667e-7f02-9a4b-4edd2b83b725` |
| retired Swallow | `019fa5a1-7fff-7e92-8e2a-2586c684747f` |
| rejected T-344 provisional | `019fafec-3da4-77d2-a88f-e7abaa380a06` |

## Why this is changed input

Immutable helper event
`13de62583acf5ad5babd684785e636d5bb20d5643ac52b8440cbd93c2155e586`
is terminal `failed/worker-failed`. Its private 72-line log remains unread.
Independent database readback after the event showed all six archive flags
unchanged, both canonical name mismatches unchanged, and no process reference
to any extra root. This plan does not retry that event, relaunch its worker,
or infer its attempted operations from transcript content.

Instead, the changed input is a controller-owned, deterministic operation
journal with one request budget per exact root/operation. It does not start a
Codex worker and cannot consume the failed event. Each operation is reserved
durably before its request. An acknowledged or ambiguous request is never
resent. A failure before request transmission remains provably unattempted.

## Confirmed state

At the planning readback:

1. Protected `main` was clean and aligned with `origin/main` at
   `e04b80aad805fb416105d4601f7f27f3a83c1495`.
2. The project topology was exactly
   `@87/0:harness,@88/1:students,@93/2:swallow`, one pane each. No tmux client
   was attached.
3. Monitor topology was exactly
   `@40/0:tunnel,@95/1:codex,@96/2:helper`, one pane each. Monitor process
   `4116681` reported `healthy=3`; helper process `4140398` reported idle with
   only `failed=1`.
4. Harness, Students, and Swallow resilient supervisors remained running at
   attempt zero. Their recovery watchers were respectively
   `808441/thread-active`, `808488/thread-active`, and
   `2266511/thread-idle`, all with zero recovery and rollback counts.
5. The shared app server remained the previously accepted process `2852569`.
6. Installed native Codex is 0.146.0. Its freshly generated experimental JSON
   schema proves:
   - `thread/read` requires `threadId` and accepts `includeTurns`;
   - `thread/archive` requires only `threadId` and returns an object;
   - `thread/name/set` requires exactly `threadId` and `name` and returns an
     object;
   - thread status is one of `notLoaded`, `idle`, `systemError`, or `active`.
   Generated schema was inspected locally, then its exact 352-entry temporary
   directory was removed through guarded-delete with protected anchors
   unchanged. Its short-lived manifest was exact-unlinked.

Every PID and mutable fact is evidence only and must be revalidated at the
execution gate.

## Authority and exclusions

The owner selected reversible archive for the three frozen extras and
confirmed `go` for all actions needed to complete this task. That authorizes
the exact transaction below.

It does not authorize:

- reading pane, transcript, turn, message, tool, preview, title, or private
  worker-log content;
- reconstructing or replaying a rejected prompt;
- deleting a root, rewriting a rollout, unarchiving, or automatic rollback;
- restarting, stopping, signaling, or replacing the shared app server;
- launching another helper event, worker, TUI, supervisor, or watcher;
- changing a tmux window, attached client, repository setting, credential,
  connector, plugin, MCP server, or unrelated worktree;
- retrying any Mac context refresh, monitor bridge/promotion, helper launch,
  failed event, or ambiguous lifecycle request.

## Private transaction artifacts

Prepare one controller and one journal under a fresh current-user runtime
directory strictly outside the repository:

- directory mode `0700`, current user, real directory, no extra links;
- controller mode `0700`, current user, real regular file, one link;
- journal and result mode `0600`, current user, real regular files, one link;
- fixed SHA-256 of the controller and fixed task Git head recorded in
  `TODO.md` before execution.

The journal is append-only and fsynced. It records only value-free identities,
operation keys, phases, request IDs, timestamps, and result classes. It never
records a thread name returned by the service, rollout content, a socket path,
or response content. The five fixed operation keys, in order, are:

1. `archive-old-exec`;
2. `archive-retired-swallow`;
3. `archive-rejected-t344`;
4. `name-harness`;
5. `name-students`.

Allowed phases are `reserved`, `sent`, `acknowledged`, `ambiguous`,
`refused`, and `verified`. Before sending, append and fsync `reserved`.
Immediately before the socket write append and fsync `sent`. After an explicit
matching response append and fsync `acknowledged`; after same-connection
metadata readback append and fsync `verified`. Any transport loss, malformed
response, mismatched request ID, or process interruption after `sent` records
or implies `ambiguous`. The controller stops and never retries that operation
or any later operation.

## Execution transaction

### 1. Immutable preflight

Require all of the following before opening the app-server connection:

1. exact repository root, clean task branch, and HEAD equal to the pushed task
   checkpoint recorded in `TODO.md`;
2. exact project and monitor window IDs, indices, names, one-pane counts, pane
   IDs, pane PIDs, and current paths;
3. zero or one attached current-user tmux client; if one exists, preserve its
   exact session/window and never move it;
4. exact current-user resilient supervisor, watcher, TUI, root, rollout, and
   reciprocal shared-socket relationships for all three canonical windows;
5. exact live monitor/helper owners and healthy/idle value-free receipts, with
   the helper still at one failed event and zero queued, running, completed,
   ambiguous, or deferred events;
6. the accepted app-server PID/start identity, exact argv, current-user-owned
   Unix control socket, and the expected three project peers;
7. six exact current-user-owned, one-link rollout files under the canonical
   Codex sessions root, with their immutable file identities recorded;
8. all three extras have zero process references and are absent from every
   canonical supervisor/watcher/TUI argv; use exact-ID PID-only matching and
   never enumerate or retain unrelated current-user process arguments;
9. SQLite metadata, read through a read-only connection, shows the three
   canonical and three extra IDs unarchived, exact Harness cwd, and exactly
   the two recorded canonical-name mismatches. Compare names as booleans only;
10. the failed helper event and receipt retain their accepted immutable
    identity, and no worker process exists.

Any mismatch records `refused` before a control connection, watcher signal,
or lifecycle request. A failed query is unknown, not absence.

### 2. Serialization and watcher pause

1. Open and validate the shared mode-0600, current-user-owned, one-link
   `~/.local/state/harness/agent-message.lock`, then acquire its exclusive
   lock.
2. Revalidate the complete immutable preflight while holding the lock.
3. Send one `SIGSTOP` to exact helper process `4140398` after rematching its
   owner, parent, start identity, executable, argv, idle receipt, terminal
   event counts, and absence of children. Immediately before signaling, require
   an idle helper receipt no older than two seconds plus a PID-only zero-child
   readback; wait through at most one 30-second observation interval for this
   fresh-idle gate. Prove the same exact helper is stopped and still childless
   before continuing. This prevents its observer from being frozen around a
   short-lived metadata child or treating an intentionally partial
   five-operation transaction as a new mirror event.
4. Send one `SIGSTOP` to each exact accepted recovery-watcher leaf only:
   Harness `808441`, Students `808488`, and Swallow `2266511`, after matching
   each PID, parent, start identity, executable, argv, and root. Do not signal
   a supervisor, TUI, process group, or app server.
5. Prove the helper and all three exact watcher leaves are stopped and all
   protected supervisors/TUIs/app-server/monitor processes remain live and
   unchanged.
6. Install cleanup before the first signal. On every exit path,
   send at most one `SIGCONT` to each exact watcher that this transaction
   stopped, but only after rematching its immutable identity. Record unknown
   cleanup state and stop if an identity no longer matches. Resume the exact
   helper only after all five operations verify or if no lifecycle request was
   sent. If any request is partial or ambiguous, retain the exact helper in
   `SIGSTOP`, record `held-partial`, and stop; this is safer than allowing an
   unplanned changed-identity worker event.

### 3. One app-server connection

1. Reuse the repository's validated Unix WebSocket transport contract:
   current-user-owned socket, HTTP Upgrade for `ws://localhost/rpc`, no
   per-message compression, bounded frames, and unique request IDs.
2. Open exactly one connection, send `initialize`, require a valid object
   response, then send the `initialized` notification.
3. Read all six exact roots with
   `thread/read({"threadId": ID, "includeTurns": false})`.
4. Retain only value-free fields needed for gates: exact ID equality, cwd
   equality, status type, path identity, empty-turn count, and boolean
   canonical-name equality. Discard preview, source details, and all other
   returned metadata without logging or printing it.
5. Require each canonical root's status to be recognized and not
   `systemError`. Harness or Students may be `active` because this owner turn
   is live. Require each extra to be `idle` or `notLoaded`, with an empty
   returned turns list.
6. Independently scan only rollout record structure for each extra. Parse
   record types, turn IDs, completion/status markers, and side-effect-bearing
   item type names, but never retain or print message, command, tool,
   reasoning, output, or other content. Require no active/incomplete turn and
   no identity change since preflight.

### 4. Fixed lifecycle writes

For each operation in fixed order:

1. revalidate the exact target's database flag/name boolean, process
   non-reference, rollout identity, app-server identity, protected process
   identities, topology, and prior journal phases;
2. append/fsync `reserved`, allocate one unique request ID, append/fsync
   `sent`, then transmit exactly one request;
3. for an archive operation, send
   `thread/archive({"threadId": EXACT_EXTRA_ID})`;
4. for a name operation, send
   `thread/name/set({"threadId": EXACT_CANONICAL_ID, "name": EXACT_ROLE})`;
5. require a matching response ID, no error, and an object result; append and
   fsync `acknowledged`;
6. issue a same-connection `thread/read(includeTurns=false)` for that exact
   root and require archive absence from the active database/list view or
   exact canonical-name equality as appropriate; append/fsync `verified`.

An acknowledged archive or name write remains accepted even if a later
operation fails. There is no automatic compensation. `codex unarchive UUID`
is the documented rollback route for an accepted archive, but this transaction
must not invoke it.

### 5. Close and resume

Close the WebSocket once. Run watcher cleanup and the conditional helper
cleanup above, then release the shared lock. Never reconnect to continue a
partial transaction. A later controller may only reconcile value-free durable
state against this journal; it may not repeat an operation whose `sent`,
`acknowledged`, `ambiguous`, or `verified` phase exists.

## Acceptance

After the one connection is closed and all three exact watchers are running:

1. independent read-only SQLite queries show exactly three unarchived,
   non-subagent, top-level Harness-cwd roots, exactly the three canonical IDs;
2. boolean metadata checks show exact names `harness`, `students`, and
   `swallow`, without printing any title or name;
3. all three archived extras retain saved rollouts and have zero process
   references; no delete occurred;
4. exact project and monitor topology, pane/process/root/socket mappings, and
   any attached-client selection are unchanged;
5. helper status remains idle with historical `failed=1` and no new event;
6. monitor reports `healthy=3` and each resilient watcher reports a recognized
   healthy state with zero recovery/rollback count;
7. two interval-separated monitor/helper/resilient readbacks pass;
8. redacted native doctor reports all checks `ok`, with its private capture
   exact-unlinked;
9. repository validation and protected publication pass; because this is a
   ledger-only closeout, no fleet sync or Mac context refresh is required;
10. fresh `harness fleet-health` is reported for every managed Linux node and
    all four Mac route pairs, respecting recorded maintenance stops.

T-345 closes only if all five operation keys are `verified` and every
acceptance gate passes. Otherwise preserve the journal, private controller,
all accepted partial writes, and exact next safe reconciliation action.

## Rollback and recovery

- Pre-request refusal: no lifecycle write occurred; correct only the changed
  input under a new published plan. The first controller's terminal journal
  is preserved and the changed input must use distinct journal/result paths;
  never reuse or truncate the first receipt.
- Ambiguous request: do not retry, compensate, or reconnect. Preserve the
  journal and reconcile read-only database/app-server state later.
- Accepted archive judged undesirable later: the owner may separately
  authorize exact `codex unarchive UUID`; it is not automatic.
- Accepted name write judged undesirable later: a separately authorized
  one-attempt `thread/name/set` may restore a prior exact name.
- Watcher resume uncertain: do not signal a replacement PID. Preserve the
  journal and diagnose exact current identities read-only.
- Partial lifecycle transaction: keep the exact helper process paused so it
  cannot create a changed-identity mirror event. Resume it only under a
  separately published read-only reconciliation that proves all sent
  operations and establishes the safe next input.
- The historical failed helper event remains terminal in every case.
