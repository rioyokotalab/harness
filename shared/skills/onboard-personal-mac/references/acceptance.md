# Acceptance, rollback, and publication

For each newly adopted component, exercise plan/apply, fresh-session
acceptance, exact unchanged-only rollback, rollback acceptance, identical
reapply, and final acceptance.

Require all of these before marking the host complete:

- ready `macos-doctor --host HOST`;
- clean/equal public and private Git state with no transfer artifacts;
- correct discovery links and official native Codex ownership;
- managed interactive routing and native batch routing;
- fresh isolated tmux parsing and session behavior; and
- SSH-only private agreement.

After each fresh managed login-shell check, repeat the component no-op plan and
`macos-doctor`; startup-local commands can mutate only when executed.

Record outcomes, transaction locality, validation, exclusions, remaining
authority, and the next Mac boundary in the selected task record. Change
`TODO.md` only when its queue-level summary changes. Publish generic changes
through protected CI; never commit private facts. Complete only after
rollback/reapply and fresh-session gates pass. On interruption, retain the
last verified state and retry-safe next action.
