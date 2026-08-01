# Reconciliation

## Evidence accepted

Accepted static evidence: current target schemas reject same-root Harness and
Personal; Codex has exact thread selectors; Claude recovery's `--continue` is
unsafe for same-root roles; monitors and Local messaging hard-code `projects`
and single product windows; Local `att` has a special case; and an explicit
location plus exact role-bound session identity is required.

Accepted incident evidence: Claude's inherited `$TMUX` caused its non-isolated
test to mutate and kill the live tmux server. Codex independently confirmed the
server and all recorded pane/monitor/helper PIDs are absent. The independent
receipt validates imported bytes, not the semantics or isolation of the run.

## Disagreements and uncertainty

Claude proposed one combined client-aware profile; Codex selects separate
client maps because existing monitor/recovery ownership and release payloads
are client-specific, while enforcing equivalent location uniqueness in both.
The old Harness Claude exact session UUID is inferred from content-blind
metadata and remains a launch-time acceptance check. The accepted live
baseline no longer exists, so process-preserving promotion is impossible and
the original rollback preimage cannot be restored by pane ID.

For one changed-input launch, select
`f09e496b-a80d-4eff-91a1-7e0b4fab6895`: its session environment was created
later than T-358 lineage `f44a1376-1af5-490f-aace-349bf3ff5594`, and its
transcript metadata was touched last during teardown. Do not automatically try
the older lineage if exact resume fails; stop and return that alternative to
owner review.

## Frozen plan

The owner selected direct final reconstruction. Codex remains sole writer.
Implement separate explicit client/location maps, exact-target launch
validation, exact Claude UUID recovery, mixed-window monitor/recovery
selection, `harness:cowork` message routing, and uniform `att`. Validate and
publish before live rollout. Then reconstruct Harness/Students from recorded
exact roots, create distinct Personal roots in provisional locations, require
metadata and phone acceptance, assemble final windows by exact pane IDs, and
start fresh monitors/helper. Never recreate Swallow or replay a prompt.

## Acceptance gates

Owner review is satisfied by the explicit direct-reconstruction instruction.
Before execution require one sealed read-only reciprocal critique of this
revised benchmark, both role-bound agreements, valid receipts, exact target
identity, clean baseline, and passing protocol check. Live rollout additionally
requires protected publication, exact saved-root preflight, one-shot launch
journals, and physical-phone confirmation for new Personal roots.

The imported reciprocal receipt is valid at evidence SHA-256
`e0b2fe254e551de78dc6935e6d95deb3e92a8530d1d2874820047dc81d166c60`.
Claude explicitly accepted the revised benchmark for Codex-only execution,
subject to recording both agreements and retaining all runtime stop gates;
those agreements now appear verbatim in `benchmark.md`.
