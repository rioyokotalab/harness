# One-shot safe rollback

Use this transaction only for helper-proven `systemError` with an
assistant-less, side-effect-free tail and exact authority for the named
session. Require `TARGET` to resolve through the closed target map and the
thread's stored CWD to equal its exact repository.

1. Publish the exact root, process, socket, tmux, Git, app-server, and
   unaffected-session identities.
2. Re-run the analyzer and every protected identity gate immediately before
   the write.
3. Invoke
   `harness codex-thread-recovery --recover --name NAME --thread ID --target TARGET`
   exactly once; preserve its request identifier and acknowledgement.
4. If acknowledgement is absent or ambiguous, perform only fresh read-only
   reconciliation. Never retry the request.
5. Independently read the root. Accept the rollback only when it no longer
   reports `systemError`, the rollback is acknowledged, and the same root and
   TUI are retained.
6. If `systemError` remains, never issue a second rollback. Reclassify the
   session as bridge-first at the `SKILL.md` router before any further action.
