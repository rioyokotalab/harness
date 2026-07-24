# T-307 remote agent communication

## Outcome

Prove that an existing remote Codex session can return a deliberate message to
the Local controller, then package the proven path as one project skill usable
from either side. The initial targets are the four managed Mac sessions; the
protocol should remain host-neutral so later managed nodes can use it.

## Phase and scope

- Phase: interviewing
- Status: one delivery-model decision remains
- Working branch: `task/t-307-remote-agent-communication`
- Working set: `TODO.md`, this plan, one new skill under `shared/skills/`, its
  discovery links, focused tests, and only the smallest supporting harness
  command if a skill-local script cannot satisfy the contract
- Non-goals: pane transcript capture, credential access, repository-backed
  mailboxes, arbitrary remote command execution, unattended agent-to-agent
  task delegation, public app-server listeners, or replacement of Codex remote
  control

## Confirmed facts

1. Local can safely insert literal text into each detached one-pane Mac
   `harness-codex-resume` session, wait for paste handling, and submit it with a
   separate `C-m`. The phone remote-control view and tmux TUI show the same
   conversation.
2. Local is itself attached to a managed Codex 0.145.0 app-server daemon.
   `CODEX_THREAD_ID` is present in this agent process, but is not automatically
   available to a command started later through SSH.
3. The supported `codex remote-control` surface manages and pairs the daemon;
   it is not the documented integration surface for custom protocol clients.
4. Codex app-server can start or steer turns through its bidirectional JSON-RPC
   protocol, but that surface is experimental. Its control socket is local,
   and exposing it across the network would require a separate authenticated
   design.
5. A repository mailbox would dirty the clean managed Mac checkout and create
   merge/concurrency hazards. A current-user state directory avoids both.

## Proposed protocol

1. Create a unique request ID on the controller and record only bounded routing
   metadata in an owner-only Local state directory.
2. Preflight the exact detached remote tmux session without reading its pane.
   Insert a prompt that includes the request ID, reply schema, size limit, and
   exact skill-local reply command; wait, then submit with `C-m`.
3. Let the remote agent write one atomic mode-0600 response in its own
   `${XDG_STATE_HOME:-$HOME/.local/state}/harness/agent-channel/outbox`.
   Replies contain an explicit request ID, sender alias, status, and UTF-8 body.
   They contain no credentials and never modify the repository.
4. Have Local poll the declared host over SSH. Validate the leaf type,
   ownership, link count, permissions, request ID, sender, schema, and byte
   limit before reading the agent-intended body. Refuse symlinks, duplicates,
   stale replies, unexpected senders, or malformed data.
5. Acknowledge only the exact validated response. Retain a compact receipt
   without message contents. Exact-unlink individual acknowledged messages;
   route any multi-message cleanup through guarded deletion.
6. Treat a timeout, unreachable host, dead/attached/ambiguous pane, or malformed
   reply as a durable status rather than fabricating a response.

## Delivery-model decision

### A. Controller-polled mailbox — recommended

The active Local agent polls remote outboxes while work is in progress and
reads validated replies. This uses existing SSH, does not expose or manipulate
the app-server, and is reproducible across Codex versions. It cannot wake an
idle conversation by itself; the owner or active controller must resume/poll.

### B. Direct current-thread injection

Add a Local broker that binds an owner-only thread ID and uses the experimental
app-server protocol to inject a remote reply into the current conversation.
This can wake the phone-visible thread, but introduces thread-lifecycle races,
custom app-server client code, and a new local message-injection authority.
It must never expose the app-server socket or a bearer token to a remote host.

### C. Hybrid

Make the mailbox authoritative and add direct current-thread notification only
after the mailbox passes. This preserves recoverability but retains the
experimental integration and its additional security and maintenance surface.

## Frozen execution sequence after owner go

1. Checkpoint the chosen delivery model and set T-307 to `executing`.
2. Initialize the new skill with the system `skill-creator` tooling and
   generate matching `agents/openai.yaml`.
3. Implement deterministic request, reply, poll, acknowledge, and status
   commands with strict state-root and message validation.
4. Add focused adversarial tests for path, owner, mode, link, schema, sender,
   request-ID, size, duplicate, timeout, and exact-cleanup behavior.
5. Forward-test one Local-to-Riken-to-Local round trip without reading the tmux
   pane. Correct the protocol until the returned request ID and intended reply
   validate.
6. Repeat independent round trips with Aist, Home, and Office. Preserve
   per-host failure evidence and do not infer one route proves another.
7. If model B or C is selected, first validate app-server injection against a
   disposable thread, then add a Local-only broker and test idle-turn and
   active-turn behavior without exposing conversation contents.
8. Run skill validation, source-contract/focused tests, `git diff --check`, and
   the complete phase-one suite.
9. Review the exact diff, fetch/integrate contributor work, publish through
   protected CI, merge, guarded-sync the clean fleet, and use the existing
   post-sync context-refresh rule.
10. Re-run one installed-skill round trip, verify clean/current fleet state and
    absent temporary artifacts, then mark T-307 complete.

## Safety and recovery

- Never capture or inspect a tmux pane. Read only an explicit response artifact
  created for the named request.
- Never inspect, print, hash, copy, or transport credentials.
- Keep app-server sockets local. A direct-injection implementation, if chosen,
  receives validated mailbox data through a Local-only broker.
- Do not place messages in Git, shell history, command arguments, or ordinary
  logs. Bound body size and use private temporary descriptors where needed.
- Do not inject into attached, multi-pane, dead, wrong-directory, or ambiguous
  sessions.
- A failed send leaves the request retryable. A failed validation leaves the
  remote response untouched for diagnosis. An acknowledgement removes only the
  exact validated leaf.

## Acceptance gates

- One request and one matching reply complete on every Mac without pane reads,
  checkout dirtiness, credential access, or residual temporary files.
- Malformed, stale, duplicate, misrouted, oversized, linked, or unsafe replies
  fail closed in focused tests.
- Repeating a request or acknowledgement is deterministic and does not consume
  an unrelated response.
- The skill is discoverable by Codex and Claude, passes `quick_validate.py`,
  and contains only essential workflow/resources.
- Focused tests, the complete phase-one suite, protected CI, guarded fleet
  synchronization, and post-sync agent refresh all pass.

## Next action

Record the owner's delivery-model choice, audit the decision register, set the
phase to `ready-for-go`, and wait for explicit `go`.
