# Initial plan

## Confirmed facts and assumptions

Confirmed facts are recorded in `docs/tasks/T-366.md`: exact Git baseline,
live tmux IDs, process identities, current hard-coded assumptions, and owner
authority. No pane or transcript was read. The design assumption to test is
that one client-specific location map can safely represent Harness in
`cowork`, plus Personal and Students in each product window, while explicit
session identities remove same-cwd resume ambiguity.

## Steps

1. Build two detached sandboxes from the immutable baseline and record a
   driver static-analysis/test experiment without changing live state.
2. Stage the charter, plan, benchmark, and bounded prompt for Claude. Claude
   independently inspects the same contracts and runs safe synthetic tests.
3. Import Claude's evidence, perform one reciprocal critique, and resolve the
   strongest disagreement with a matched test or stop for owner review.
4. Freeze ordered implementation, rollback, authority, owner-go, and checks;
   advance through ready-for-execution. The original request is execution go.
5. Implement target/profile, launch/resume, monitor/recovery, communication,
   alias, and synthetic topology changes in the isolated target worktree.
6. Run focused tests, full phase one, protected publication, and guarded fleet
   sync only for clean eligible managed checkouts.
7. Construct and accept provisional Personal Codex and Claude panes without
   touching old panes. Stop on any ambiguous launch or required phone gate.
8. Move exact Harness and Students panes into final windows, rename the
   session, revalidate, then retire only exact Swallow panes and normalize
   layout. Roll back exact moved panes if acceptance fails before retirement.
9. Validate monitors, helper, exact resume, both remote-control surfaces,
   local agent messaging, `att`, attached client, and fleet health; complete
   the ledger and protected closeout.

## Evidence questions

- What is the smallest location schema that rejects duplicate/missing panes
  across mixed windows and preserves existing recovery safety?
- How should Codex and Claude bind exact sessions when Harness and Personal
  share a cwd, without latest-by-directory selection?
- Can remote-control readiness be validated from metadata and native status
  without pane or transcript reads?
- Which commands form a bridge-first, exact-ID tmux transaction with a
  deterministic rollback before old-pane retirement?
- Which current tests and release manifests must change together?

## Risks and recovery

Primary risks are same-root resume confusion, a monitor racing migration,
duplicate phone roots, attached-client disruption, and a partially promoted
tmux topology. Pause monitors only after recording exact owners and only for
the bounded cutover; build replacements first; freeze pane IDs and PIDs; use
new temporary windows; move rather than relaunch accepted processes; rename
last; and retain exact rollback targets until final acceptance. Stop on drift,
failed protected checks, unavailable co-pilot, unconfirmed phone visibility,
or any ambiguous external action.
