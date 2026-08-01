# Co-pilot evidence

## Sandbox and baseline

I am the Claude co-pilot launched from the admitted root `/home/rioyokota/harness` (launch sentinel satisfied). Per the changed input I used only the `Read` tool against the staged exchange `/tmp/harness-t366-claude-sandbox/t366-reciprocal-r2`; no Bash, tmux, Git, Glob, Grep, network, message, write, or live-state access occurred, so no `$TMUX` escape vector exists on my side by construction. Because the Bash prohibition prevents the mandatory fresh `date` read, I emit no bracketed timestamps rather than infer one. This request matches the `codex-claude-cowork` skill (reciprocal evidence critique), but the task's explicit Read-only tool restriction is the closer instruction, so no skill references were loaded.

Staged baseline as read: charter, plan, and benchmark all pin immutable Git baseline `3d96125514281ef071b1... (3d96125514281ef071ba7ce0303185b6e3e8660e)`; the benchmark's reconstructed live baseline is "no tmux server and none of the previously recorded pane, product, monitor, or helper PIDs," with destroyed identities held as incident evidence only.

## Commands and results

Exact Read-only evidence actions (one `Read` call per file, full contents, no other paths touched):

1. `Read /tmp/harness-t366-claude-sandbox/t366-reciprocal-r2/charter.md` — 44 lines; destroyed pane/PID identities declared historical only; reconstruction from exact durable session identities; Swallow not recreated; phone visibility confirmation named an owner acceptance gate.
2. `Read .../plan.md` — 57 lines; frozen nine-step plan; risks retain move-not-relaunch, monitors paused only for bounded cutover, rename last, stop on drift/phone-gate/ambiguity.
3. `Read .../benchmark.md` — 71 lines; eight observable cases; case 2 rejects latest-by-directory and Claude `--continue` for same-root recovery; case 3 defines exact-session recovery with launch-once-provisional then move-by-exact-pane-ID; case 5 requires phone-visible distinct identities; Agreement section reads "Pending independent evidence and reciprocal critique."
4. `Read .../driver-evidence.md` — 97 lines; post-incident section records read-only proof of server absence, exact Codex durable roots (`019fa3ae-…576` Harness, `019fb2bc-…271` Students), metadata-only Claude candidates (`f09e496b-…895` Harness, `7b44875e-…4f8` Students), and owner instruction "Reconstruct directly into the final harness topology" as execution go.
5. `Read .../copilot-evidence.md` — 74 lines; prior co-pilot incident record ($TMUX-inherited socket escape, `kill-server` destruction) plus six proposed plan changes including the isolation preamble.
6. `Read .../reconciliation.md` — **failed: file does not exist.** No retry, no alternate path probed. The staged exchange is therefore incomplete relative to the task's own file list.

## Critique

**Process preservation → exact saved-session recovery: adequately replaced.** The charter, benchmark identity section, and case 3 are mutually consistent: destroyed pane/PID identities are evidence only, Harness/Students recover via exact durable session roots, Personal gets new distinct roots, every process launches once into a provisional exact role/location and moves only by exact pane ID, and Swallow is not reconstructed. The driver correctly frames `--resume UUID` as an acceptance test, not proof of semantic continuity, and the benchmark's stop condition ("stop before accepting or moving a provisional pane on any identity, resume … failure") backstops a wrong-candidate resume without retry loops.

**Same-root identity: adequately required.** Case 2 makes distinct explicit target/session identities a hard requirement where Harness and Personal share a cwd, and explicitly rejects both latest-by-directory selection and Claude `--continue` for same-root recovery — exactly the failure mode my baseline Experiment A proved (`harness-claude-pane-recovery` hard-coding `--continue`; profile repository-uniqueness). Driver evidence confirms native `--session-id`/`--resume` support, so the mechanism exists.

**`$TMUX` escape: prevented structurally, not yet textually.** The revision eliminates the incident's actual vector: the co-pilot is confined to Read with no shell, Codex is the sole runtime writer, and there is no pre-existing server to escape into during the sandbox phase. The required synthetic tmux and same-root experiments are already satisfied by pre-incident driver evidence, and the remaining case-7 rollback drill intentionally targets the reconstructed server, bounded to removing only its provisional replacement by exact ID. However, neither the frozen plan nor the benchmark text carries the explicit isolation preamble (`env -u TMUX`, private socket, `set -euo pipefail`, pre-mutation `list-sessions` assertion) from my prior evidence. Because no future synthetic run is mandated, this is a hardening gap, not a live hazard — see proposed changes.

**Phone acceptance: retained.** The charter keeps owner phone visibility confirmation as an acceptance gate; case 5 requires both Personal replacements phone-visible under distinct identities and recovered Harness/Students roots to remain valid; plan step 7 stops on any required phone gate; the evidence method names owner phone confirmation explicitly.

**Residual weaknesses (non-blocking).** (a) The Harness Claude root is a metadata-inferred candidate (`f09e496b…`) that conflicts with the T-358-bound older lineage (`f44a1376…`); the selection rationale is sound and content-blind, but the resolution is not visible to me because `reconciliation.md` is missing. (b) Plan step 8's "retire only exact Swallow panes" is stale under a destroyed server — safe as a no-op, but the wording invites confusion. (c) Case 5 verifies new phone roots are visible but not that stale phone-control roots of destroyed sessions are absent.

**Remaining stop condition.** Exactly one: the agreement is not yet recorded. The benchmark's own stop condition — "stop before target execution if … either agreement is absent" — is currently active, because the Agreement section still reads "Pending" and `reconciliation.md` is absent from the stage. This report supplies the co-pilot agreement; the driver must import it, record the reconciled agreement (including the Harness Claude root-candidate resolution against T-358), and update the benchmark Agreement section before the first target-executing step. All in-benchmark runtime stops (identity/resume/remote-control/rollback failures, phone gate) remain in force thereafter.

**Acceptance.** Subject to that single recording gate, the revised direct-reconstruction benchmark and frozen plan are safe: **the benchmark is accepted for Codex-only execution.**

## Proposed plan changes

1. Record the reconciled agreement: driver imports this evidence, resolves the Harness Claude root selection (`f09e496b…` versus T-358 lineage `f44a1376…`) in `reconciliation.md`, and flips the benchmark Agreement section from "Pending" before any target execution.
2. Freeze the tmux isolation preamble into the evidence method for any future synthetic run: `env -u TMUX tmux -S <private-socket>`, `set -euo pipefail`, and a pre-mutation assertion that `list-sessions` shows only the synthetic session.
3. Amend plan step 8 to state that Swallow retirement is satisfied by absence (no Swallow panes exist post-incident and none are recreated), removing the stale retirement action.
4. Extend case 5 with a stale phone-root check: remote-control roots of destroyed pre-incident sessions must be verified retired or absent, not merely superseded by visible new roots.
5. Treat a failed or wrong-lineage `--resume UUID` for Harness Claude as a single non-retried stop that offers the recorded alternate lineage or a new durable root to the owner — never an automatic second resume attempt.
