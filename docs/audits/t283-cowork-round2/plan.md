# Initial plan

## Confirmed facts and assumptions

Confirmed on the driver clone at `7df5f7d`: the canonical `quick_validate.py`,
the focused cowork test, Claude takeover, source contract, public-repo audit,
and `git diff --check` all pass on the untouched v2 baseline; Codex CLI 0.144.6
and Claude Code are installed; both clones resolve to `7df5f7d`. Assumption to
falsify: v2's `require_owned_kind` and exact-set checks make every protocol
entry a self-contained, tamper-evident session artifact. Assumption to
inspect: the co-pilot native mapping grants only the write authority the stated
ownership model permits. Assumption to confirm-or-deny: the documented Codex and
Claude invocation shapes parse as written in the installed clients.

## Steps

1. Independently inspect the v2 skill, protocol, validator, and focused test in
   the driver clone; run every acceptance gate on the untouched baseline.
2. Probe the validator adversarially without touching the live target: hardlink
   a protocol file to an outside user-owned file; overwrite a driver-owned file
   as an unrelated same-uid writer; re-run `check` after each and record whether
   it still reports valid.
3. Verify the real Codex co-pilot invocation shape end-to-end
   (`codex --ask-for-approval never exec --ephemeral --sandbox workspace-write
   --cd ... --add-dir ... --output-last-message ... -`), including that `[PROMPT]`
   accepts `-` from stdin and that `--help` does not mask unknown flags.
4. Confirm the reverse Codex-drives-Claude mapping options exist in installed
   Claude. Do not change configuration or auth.
5. Record observed results, strongest criticism, and exact proposed edits in
   `driver-evidence.md` without exposing it to Codex.
6. Give Codex only the charter, plan, baseline, its sandbox, and its owned
   `copilot-evidence.md`; have it run its independent pass blinded from driver
   evidence. Then reveal both and run one reciprocal critique each.
7. Reconcile only evidenced fixes into a frozen target-edit and validation plan.

## Evidence questions

- Does `require_owned_kind` accept a hardlinked (`st_nlink > 1`) protocol file
  that aliases content outside the session, and does `check` still pass?
- Can the co-pilot, holding workspace-write + `--add-dir SESSION_DIR`, modify a
  driver-owned file, and can any validator phase detect that tampering?
- Is the co-pilot integrity obligation stated as an actionable driver step, or
  only as an abstract "authorship cannot be proven" disclaimer?
- Do `-` stdin, `--ephemeral`, and `--output-last-message` parse in installed
  Codex, and do the reverse Claude options exist?
- Is the `agents/openai.yaml`-only manifest a real symmetry defect or the
  correct consequence of different discovery mechanisms?

## Risks and recovery

Probes could accidentally target the live checkout, alias private content, or
leave throwaway trees. Every command must resolve its working directory first,
use only synthetic public content, and stop on any path mismatch; the
no-hardlink clones keep source edits independent of the target. A failed Codex
call is retry-safe only after inspecting its sandbox and `copilot-evidence.md`
for ambiguous partial writes; absent output is never a successful review.
Throwaway probe trees and the four round sandboxes are removed only through the
guarded manifest workflow; otherwise retained with exact paths.
