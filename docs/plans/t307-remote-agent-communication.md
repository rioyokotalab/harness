# T-307 remote agent communication

## Outcome

Prove that existing remote Codex sessions can exchange deliberate prompts with
the Local controller, then package the proven path as one project skill. The
initial targets are the four managed Mac sessions; the transport remains
host-neutral for later managed nodes.

## Phase and scope

- Phase: complete
- Status: same-channel requests passed independently on all four Macs
- Working branch: none; implementation merged in PR #302 at
  `4544f7ddd263c78d9a54d80be339be64636c399c`
- Working set: `AGENTS.md`, `TODO.md`, this plan, one new skill under
  `shared/skills/`, discovery links, and focused tests
- Non-goals: pane transcript capture, credential access, repository mailboxes,
  arbitrary remote execution, unattended agent loops, public app-server
  listeners, or replacement of Codex remote control

## Confirmed facts

1. Local can insert literal text into each detached one-pane Mac
   `harness-codex-resume` session, wait for paste handling, and submit a
   separate `C-m`. The phone remote-control view and tmux TUI show the same
   conversation.
2. Local's Codex TUI is in tmux session `harness`, with its wrapper and exactly
   one `codex.real` descendant on pane `%0`. The wrapper made the pane initially
   look like a shell when only `pane_current_command` was considered.
3. Codex app-server supports thread/turn methods, but `remote-control` is not
   the integration surface for custom clients. A read-only probe showed that a
   second proxy client could not join the already occupied Local control
   socket. That path was abandoned and all probe state was removed.
4. The live Riken experiment succeeded. Local prompted the detached Riken
   session without reading its pane. Riken sent
   `[Agent: Riken Codex] Bidirectional prompt injection from Riken succeeded.`
   through `ssh login`; it appeared in this same Local/phone-visible
   conversation. The credential-free Local helper exact-unlinked itself.
5. A Git mailbox would dirty managed checkouts and is unnecessary. Symmetric
   tmux-over-SSH provides direct visible delivery in both directions.
6. Protected CI passed for the base skill, macOS process-path correction, and
   concurrent-reply serialization. Guarded fleet sync advanced all 11 managed
   remote checkouts to `1179f371654fb28cb62e09e170a807fee0c42dd2`.
7. Sequential installed-skill replies from Aist and Riken arrived intact with
   their required prefixes and matching request IDs. Home and Office accepted
   one transport-level submission each but have not produced an agent-level
   reply. Both sessions remain detached, live, clean/current, and idle by
   value-free process metadata; no retry was made.
8. The owner inspected Home and Office and confirmed on 2026-07-24 that both
   messages were visible and processed; neither Codex attempted the requested
   response. This rules out transport and TUI submission failure for those
   trials and demonstrates nondeterministic instruction compliance.
9. The structured contract merged and synced as
   `57ec794f3ec437026e4bf7f3682b05e4a55d1940`. Aist and Riken each returned one
   correct structured reply. Home and Office omitted theirs even after their
   exact detached panes were replaced with `harness-codex resume --last`,
   proving that startup-loaded policy improves but cannot guarantee compliance.
10. A read-only `codex exec resume --last` trial completed on Home without
    replacing its live TUI. Its unconstrained final wording failed an exact
    format check and was exact-removed without display. This supports a strict
    output-schema fallback rather than parsing free-form model text.
11. The first published fallback was invoked once for
    `t307-home-r3-20260724` after 120 seconds and value-free idle evidence. It
    failed in six seconds before any Local reply appeared, and its `finally`
    cleanup left no private artifact. The timing and unsupported-keyword risk
    make schema validation the leading hypothesis, not a confirmed cause. The
    next iteration removes schema metadata, regex, and length keywords while
    retaining equivalent deterministic checks in the wrapper.
12. Home subsequently reported that it made exactly one response attempt for
    `t307-home-r3-20260724`; the reverse transport failed and submission is
    ambiguous. Office also made exactly one attempt, but `login` and its
    `SSH_AUTH_SOCK` were unavailable and no `status=submitted` was returned.
    Both agents followed policy. The shared failure is the second,
    Mac-to-Local SSH connection, not model compliance or response formatting.
    Neither existing request ID may be retried.
13. A bounded wait plus idle process metadata did not establish that Home's
    original turn had ended. The fallback gate must require explicit owner
    observation of completion without a response attempt; time and idleness
    alone are insufficient.
14. PR #302 passed protected `portable-phase1` CI and merged as
    `4544f7ddd263c78d9a54d80be339be64636c399c`. Guarded fleet sync advanced all
    eleven remote managed checkouts, followed by one standard context refresh
    on each Mac.
15. New same-channel requests completed independently:
    - Aist: `t307-aist-r2-20260724`
    - Home: `t307-home-r4-20260724`
    - Office: `t307-office-r4-20260724`
    - Riken: `t307-riken-r2-20260724`

    Each returned one identified `status=complete responder=exec-request`
    response in Local. Home and Office succeeded despite the reverse
    `login`/agent state that broke their earlier replies.
16. The final value-free audit found every Mac at the merged revision with an
    empty worktree, one detached `harness-codex-resume` session, one live pane
    rooted at `~/harness`, zero `.agent-reply-*` directories, and zero
    `harness-agent-*` tmux buffers.

## Selected protocol

1. Prepare one bounded UTF-8 message beginning `[Agent: NAME Codex]`. The
   case-insensitive name must match the declared source alias. Include a
   request ID when matching a later reply matters.
2. Send the bytes only through stdin to the declared SSH target, with agent and
   X11 forwarding disabled and non-interactive authentication required.
3. On the target, validate the sender prefix and select exactly one live Codex
   pane by session, current path, TTY, and `codex.real` process metadata
   without capturing its contents.
4. Load the bytes into a uniquely named private transient tmux buffer, paste
   them into the pane while deleting the buffer, wait for paste handling, and
   submit a separate `C-m`.
5. Treat a timeout, unreachable host, dead/attached/ambiguous pane, malformed
   prefix, unsafe message, or unexpected native output as a failure rather
   than fabricating delivery.
6. Serialize the complete paste, submit, and settle interval with a private
   current-user advisory lock. Concurrent agents may wait, but their prompt
   bytes must never share the controller input buffer.
7. When a response is acceptance-critical, do not use TUI injection. Send the
   identified request over one Local-to-Mac SSH stdin, process it with one
   schema-constrained `codex exec resume --last` turn in the existing thread,
   return the validated response through the same SSH stdout, and inject it
   into Local. Disable forwarding and do not depend on `login`,
   `SSH_AUTH_SOCK`, or a second connection.

## Decision register

- The owner selected direct injection and authorized a live experiment on
  2026-07-24.
- Every remote-agent message must begin `[Agent: NAME Codex]`. An unprefixed
  message in the owner conversation is treated as owner-originated.
- The prefix is claimed attribution, not cryptographic identity or owner
  authority. Normal repository and authority boundaries still control.
- The passing implementation is symmetric tmux-over-SSH. Do not include the
  failed second-client app-server hypothesis in the skill.
- Never create an autonomous reply loop. Each round must be owner-expected or
  explicitly bounded by the initiating request.
- Required acknowledgements use one machine-readable
  `REPLY_REQUIRED ... max_replies=1` contract. The recipient must send one
  status response even when the requested work is blocked or rejected.
- Configuration cannot make semantic model behavior deterministic. After a
  confirmed omitted response and only while the owner explicitly
  observed the preceding turn finish, the controller may run exactly one
  read-only, schema-constrained resumed-turn fallback and return its result on
  the originating channel as `responder=exec-fallback`.
- Required-response work uses `request` from the start. It returns
  `responder=exec-request` on the Local-to-Mac connection and must not also be
  injected through the TUI.
- A four-Mac simultaneous reply test on 2026-07-24 produced one unprefixed,
  truncated input before a later intact Riken reply. The unprefixed input was
  not attributed. This is evidence that injection must be serialized, not
  evidence of agent identity.

## Execution sequence

1. Initialize `remote-agent-communication` with the system skill-creator.
2. Implement deterministic stdin-only send/receive commands with strict
   sender, size, route, session, pane, TTY, and process validation.
3. Add focused adversarial tests for sender/prefix mismatch, size, unsafe
   route, attachment, pane/process ambiguity, argument privacy, private paste,
   and separate submission.
4. Validate skill metadata and discovery links for Codex and Claude.
5. Run focused tests, `git diff --check`, and the complete phase-one suite.
6. Fetch/integrate contributor work, publish through protected CI, merge, and
   guarded-sync every clean managed checkout.
7. Apply the existing post-sync context refresh with
   `[Agent: Local Codex]` attribution.
8. Repeat installed-script round trips sequentially with Riken, Aist, Home,
   and Office after publishing the serialization fix. Preserve independent
   results and never infer one route proves another.
9. Verify clean/current fleet state and absent temporary artifacts, then mark
   T-307 complete.
10. Replace reverse-SSH response acceptance with one same-channel request on
    Home and Office, using new IDs only. Verify their ordinary TUI processes
    remain live and private response artifacts are absent.

## Safety and recovery

- Never capture or inspect a tmux pane.
- Never inspect, print, hash, copy, or transport credentials.
- Do not use or expose the app-server socket.
- Keep message bytes out of Git, command arguments, shell history, and ordinary
  logs. Bound size and use private files or descriptors.
- Default Mac delivery refuses an attached, multi-pane, dead,
  wrong-directory, or ambiguous session. Local delivery selects its unique
  Codex pane even while the owner is attached because that is the intended
  phone-visible conversation.
- A failed send is retryable only after value-free diagnosis. A successful
  submission must not be retried because delivery is not idempotent.
- A same-channel request returns its response before success. If transport
  fails after remote execution, treat its result as ambiguous and do not
  repeat the same request ID.

## Acceptance gates

- One same-channel request and matching reply complete on every Mac without
  reverse SSH, agent forwarding, pane reads, checkout dirtiness, credential
  access, or residual temporary files.
- Malformed, misidentified, misrouted, oversized, attached, ambiguous, or
  unsafe messages fail closed in focused tests.
- Message bytes do not appear in SSH or tmux process arguments or ordinary
  logs; the transient tmux buffer is deleted as part of paste.
- The skill is discoverable by Codex and Claude, passes `quick_validate.py`,
  and contains only essential workflow/resources.
- Focused tests, the complete phase-one suite, protected CI, guarded fleet
  synchronization, and post-sync agent refresh all pass.

## Next action

None. T-307 is complete. Do not retry the earlier ambiguous Home or Office
request IDs.
