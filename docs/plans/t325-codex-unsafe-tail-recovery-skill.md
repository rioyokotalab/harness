# T-325 Codex unsafe-tail recovery skill

## Objective

Restore the currently blocked Swallow Codex root with the smallest proven
mutation, correct the watcher-lifecycle gap that allowed recovery monitoring
to disappear unnoticed, and encode the proven project-neutral workflow as a
shared skill.

## Confirmed live state

- Exact tmux window `@59:swallow` has one pane and remains outside the active
  Harness window.
- Supervisor PID `2876863`, launcher PID `2877066`, and real TUI PID
  `2877595` retain their recorded process/session identities and exact root
  `019fa36c-cfa9-7143-ae11-1f538e07bfee`.
- Real TUI PID `2877595` has an established Unix peer to unchanged app-server
  PID `2852569`.
- Resilient status is `running/remote-explicit`, attempt zero, delay zero.
- Recovery watcher PID `2876942` is absent. Its last private value-free state
  reports `unavailable/recovery-check-failed`.
- Fresh app-server metadata reports `systemError`. The published analyzer
  validated the rollout and found exactly one safely recoverable completed,
  assistant-less, side-effect-free tail turn.
- No pane, transcript, rejected prompt, credential, or project payload was
  inspected.

## Authority and boundaries

The owner's request to fix Swallow authorizes the exact safe recovery selected
by the already-published analyzer and the implementation, validation, and
publication needed to prevent recurrence. Ordinary scoped Git publication is
standing-authorized.

Do not:

- replay or reconstruct a rejected prompt;
- read pane or transcript content;
- roll back any turn that is not proven safe by the published analyzer;
- retry an ambiguously acknowledged rollback;
- restart or signal the shared app server;
- mutate Harness, Students, or Swallow project work;
- archive or delete a saved root;
- signal a process group or use `SIGKILL`.

## Execution

1. Publish this plan and exact pre-write identities on an isolated task branch.
2. Revalidate the root as `systemError`, safe-tail count as exactly one, the
   process and socket identities, watcher absence, unaffected sessions, and
   clean/aligned task Git.
3. Invoke one exact `harness codex-thread-recovery --recover` transaction.
   Require an unambiguous `recovered/system-error-safe-tail` result with one
   rolled-back turn. Never retry an ambiguous request.
4. Read the exact root back as non-`systemError`, require the same TUI,
   supervisor, app server, tmux mapping, and unaffected sessions, and confirm
   no prompt was replayed.
5. Reproduce the watcher-loss lifecycle in a deterministic fixture. Amend the
   resilient supervisor so a remote TUI cannot remain reported `running` after
   its watcher exits. Keep safe rollback and every existing fail-closed gate
   unchanged.
6. Build shared skill `recover-codex-unsafe-tail` using the system
   `skill-creator`. The skill must:

   - start from complete repository instructions, ledger, Git, and mutable
     value-free state;
   - distinguish healthy, safe-tail, unsafe-tail, unavailable, and ambiguous
     states;
   - use the narrow safe rollback only when proven;
   - use the fresh-root cutover protocol for unsafe tails while preserving the
     poisoned root;
   - prohibit prompt replay, pane/transcript reads, app-server restart,
     ambiguous retries, broad signals, archive, and deletion;
   - checkpoint exact identities and independent acceptance.

7. Add both project discovery links and deterministic metadata. Run the skill
   validator, focused supervisor/recovery/skill tests, syntax, ShellCheck,
   diff hygiene, and the complete clean-tree phase-one suite.
8. Publish through protected Git, synchronize only clean managed checkouts if
   required, activate the corrected supervisor for Swallow through a separate
   exact process gate, and finish with root/process/socket/doctor/Git,
   residue, and canonical fleet-health readback.

## Failure handling

- Before the rollback request, every failure is read-only and retry-safe after
  fresh reconciliation.
- After a sent rollback without unambiguous acknowledgement, do not retry.
  Reconcile only through fresh read-only app-server state.
- If the analyzer returns unsafe-tail, preserve the existing root and use the
  proven fresh-root cutover rather than weakening analysis.
- If code publication succeeds but live activation is unsafe, leave the
  current recovered process intact and record activation as the next action.
- Never conceal a watcher failure by reporting only the TUI supervisor state.

## Acceptance

- Exact Swallow root is no longer `systemError` and its existing TUI remains
  connected without prompt replay.
- A watcher exit cannot leave remote-explicit resilient status falsely
  `running`; tests prove the corrected lifecycle and existing safety gates.
- The shared skill passes structural validation and is discoverable by Codex
  and Claude.
- Harness, Students, shared app server, project repositories, and preserved
  blocked roots remain outside mutation scope.
- Protected validation and canonical fleet health pass.
