# Initial plan

## Confirmed facts and assumptions

Confirmed: round 2 proved `--add-dir SESSION_DIR` gives a same-UID co-pilot
write access to every exchange file; v3 detects protected changes with an
external digest but does not prevent or recover overwritten uncommitted bytes.
The native clients can receive prompts on stdin and emit final output to a named
file or stdout. Assumption to test: copying a bounded input bundle into the
co-pilot sandbox and importing a validated candidate afterward can eliminate the
normal need for a session write grant while retaining file-mediated discussion.
This is authority reduction, not a claim that a same-user process is an
adversarial OS security boundary.

## Steps

1. Independently trace the v3 mapping, digest coverage, file ownership, and
   failure recovery. Run synthetic direct-write and staged candidate probes.
2. Define a minimal deterministic stage bundle containing immutable copies of
   the state, charter, plan, and phase-appropriate evidence plus their hashes.
   Require a fresh real stage directory outside the live session.
3. Test a candidate import that validates identity, size/UTF-8/headings/TODO,
   checks all staged input hashes against the still-current session, and
   atomically replaces only `copilot-evidence.md`. Refuse stale, linked,
   malformed, or unexpected candidates without changing the session.
4. Run Claude independently with no `--add-dir SESSION_DIR`, using only the
   copied bundle and a local candidate output. Keep the driver evidence blinded.
5. Have the driver validate and import Claude's candidate, then expose both
   evidence files. Repeat staging for reciprocal critique so Claude returns a
   complete replacement of its owned evidence.
6. Reconcile whether to adopt staged exchange as default, retain direct-session
   write only as a sealed fallback, or make no change. Freeze exact target edits
   and acceptance tests before driver execution.

## Evidence questions

- Can both native clients produce their owned evidence inside their sandbox
  without a session `--add-dir` grant?
- Can a deterministic importer reject stale inputs, hard/symlink candidates,
  malformed headings, oversized output, and unexpected stage content before any
  live byte changes?
- Does staging preserve independent blinding and reciprocal full-file updates?
- Does the current digest-only fallback provide recovery, or only detection?
- Which limits are mechanical and which remain same-user behavioral policy?

## Risks and recovery

A model could emit prose that is not importable, a stage could become stale, or
an importer could partially overwrite evidence. Use fresh directories, bounded
regular files, recorded hashes, and atomic replacement; retain the prior
`copilot-evidence.md` until all checks pass. A failed model call changes only its
sandbox and is retry-safe after inspection. A failed import must leave the live
session byte-identical. Sandboxes remain until guarded cleanup.
