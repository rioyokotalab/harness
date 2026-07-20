# Co-pilot evidence

## Sandbox and baseline

- Fact: all reciprocal probes ran in
  `/tmp/harness-t283-round4-codex`, detached at baseline
  `9fed369bcdfd96c15914683820f6113b6a5bb898`. `git rev-parse HEAD`
  printed that commit and `git status --short --branch` initially printed only
  `## HEAD (no branch)`.
- Fact: I read both revealed files in `stage-reciprocal/` and the complete
  cowork skill and protocol before testing. I used the baseline helper at
  `shared/skills/codex-claude-cowork/scripts/cowork-session` and a throwaway
  patched copy at `scratch-reciprocal-probes/proto-cowork-session`.
- Fact: the prototype changes only staging/import behavior. It accepts exactly
  the current top-level state keys (`schema_version`, `driver`, `copilot`,
  `phase`, `created_at`, `updated_at`, and optional `predecessor`), accepts
  exactly the current predecessor keys (`driver`, `path`, `phase`,
  `state_sha256`), omits `predecessor.path`, rejects unknown/missing keys, and
  deterministically serializes the projection. Both stage and import call the
  same function. Projection is performed before the stage directory is
  created.
- Fact: synthetic sessions, the prototype, seals, and bounded outputs remain
  under `scratch-reciprocal-probes/` for guarded cleanup. I used no live
  session, credential, network, remote, package, external message, or
  recursive/bulk deletion operation. The only candidate deliverable changed is
  this file.

## Commands and results

1. I first settled the factual conflict about the revealed reciprocal bundle:

   ```text
   rg -n '/home/rioyokota/harness|"path"' stage-reciprocal/state.json
   rg -n '/home/rioyokota/harness|"path"' stage-reciprocal/stage.json
   sha256sum stage-reciprocal/state.json
   jq -r '.inputs["state.json"]' stage-reciprocal/stage.json
   ```

   Fact: `state.json` matched at line 8 and contains
   `/home/rioyokota/harness/docs/audits/t283-cowork-round3` as
   `predecessor.path`. The `stage.json` search exited 1 with no match. Its
   `inputs.state.json` value is
   `d86dd35fb7e9fc90f73361fde2eba43887a9a859497ef3a364c9203ee2505615`,
   exactly the SHA-256 of staged `state.json`.

   Inference: my earlier evidence is correct on this point. The staged
   `state.json` directly discloses the absolute path; `stage.json` carries only
   its digest, not the literal path. The driver's statement that both files
   carry the absolute path is false if “carry” means literal disclosure.

2. I made the fail-closed design executable rather than comparing prose:

   ```text
   mkdir -p scratch-reciprocal-probes
   cp shared/skills/codex-claude-cowork/scripts/cowork-session \
     scratch-reciprocal-probes/proto-cowork-session
   chmod 700 scratch-reciprocal-probes/proto-cowork-session
   # Applied the projection described above to the throwaway copy only.
   python3 -m py_compile scratch-reciprocal-probes/proto-cowork-session
   ```

   I then created a predecessor-backed session and an ordinary session using
   the unmodified helper, filled the required discussing-phase files, advanced
   both, and used the prototype for real stage/import round trips:

   ```text
   cowork-session init scratch-reciprocal-probes/pred --driver codex
   cowork-session init scratch-reciprocal-probes/succ --driver claude \
     --predecessor scratch-reciprocal-probes/pred
   perl -pi -e 's/^TODO$/filled synthetic protocol content/' \
     scratch-reciprocal-probes/succ/{charter.md,plan.md}
   cowork-session advance scratch-reciprocal-probes/succ discussing
   proto-cowork-session stage scratch-reciprocal-probes/succ \
     scratch-reciprocal-probes/succ-stage --mode independent
   perl -pi -e 's/^TODO$/synthetic reciprocal candidate/' \
     scratch-reciprocal-probes/succ-stage/candidate-copilot-evidence.md
   proto-cowork-session import-copilot scratch-reciprocal-probes/succ \
     scratch-reciprocal-probes/succ-stage

   cowork-session init scratch-reciprocal-probes/ordinary --driver codex
   # Filled charter/plan and advanced as above.
   proto-cowork-session stage scratch-reciprocal-probes/ordinary \
     scratch-reciprocal-probes/ordinary-stage --mode independent
   proto-cowork-session import-copilot scratch-reciprocal-probes/ordinary \
     scratch-reciprocal-probes/ordinary-stage
   ```

   Fact: both imports exited 0 with candidate SHA-256
   `2458e92ddcd05c54c0da9afd0e546238435ab5082f76e9ffb7f8ac5926c95ef2`.
   The predecessor-backed live state had exactly the current keys
   `copilot,created_at,driver,phase,predecessor,schema_version,updated_at`; its
   predecessor had exactly `driver,path,phase,state_sha256`. The staged state
   retained all of those except `predecessor.path`. The ordinary live and
   staged states had exactly the six current non-predecessor keys.

   I also filled the synthetic driver evidence and ran the reciprocal mode:

   ```text
   proto-cowork-session stage scratch-reciprocal-probes/succ \
     scratch-reciprocal-probes/succ-reciprocal-stage --mode reciprocal
   proto-cowork-session import-copilot scratch-reciprocal-probes/succ \
     scratch-reciprocal-probes/succ-reciprocal-stage
   ```

   Fact: reciprocal stage and import both exited 0. The staged predecessor keys
   were exactly `driver,phase,state_sha256`.

   Conclusion: whitelist-fail-closed does not reject a legitimate session
   using the complete current real schema, with or without a predecessor, and
   it works in both stage modes and import. This directly answers the driver's
   concern that whitelisting would necessarily omit the current mutable phase
   or timestamps: it does not, because those fields are explicitly retained.

3. I re-demonstrated the blacklist's forward-disclosure behavior with the
   unmodified helper:

   ```text
   cowork-session init scratch-reciprocal-probes/blacklist-unknown --driver claude
   # Filled charter/plan, advanced to discussing, then added:
   # "audit_path": "/private/future/live/session"
   cowork-session check scratch-reciprocal-probes/blacklist-unknown \
     --phase discussing
   cowork-session stage scratch-reciprocal-probes/blacklist-unknown \
     scratch-reciprocal-probes/blacklist-unknown-stage --mode independent
   rg -n 'audit_path|/private/future' \
     scratch-reciprocal-probes/blacklist-unknown-stage/state.json
   ```

   Fact: current `check` and `stage` both exited 0, and the staged state
   contained `"audit_path": "/private/future/live/session"`. A projection
   that merely drops `predecessor.path` behaves the same for this new key.

   I ran the matched session through the fail-closed prototype:

   ```text
   proto-cowork-session stage scratch-reciprocal-probes/whitelist-unknown \
     scratch-reciprocal-probes/whitelist-unknown-stage --mode independent
   ```

   Fact: it exited 1 with `state has unexpected or missing keys for staging`.
   Because projection ran before stage creation,
   `whitelist-unknown-stage` did not exist afterward.

4. I measured the brittleness cost with a deliberately benign prospective
   field, not a path:

   ```text
   cowork-session init scratch-reciprocal-probes/future-benign --driver codex
   # Filled charter/plan, advanced, then added:
   # "session_label": "legitimate-v2-metadata"
   cowork-session check scratch-reciprocal-probes/future-benign \
     --phase discussing
   proto-cowork-session stage scratch-reciprocal-probes/future-benign \
     scratch-reciprocal-probes/future-benign-stage --mode independent
   ```

   Fact: the current broad loader/check accepted this additive field. The
   fail-closed projector rejected it with the same unknown-key error and left
   no partial stage.

   Inference: fail-closed does impose a real compatibility cost. A legitimate
   schema addition cannot stage until the projection contract classifies the
   new field and tests are updated. That is not a rejection of a current-schema
   legitimate session; it is a coordinated-upgrade requirement for schema
   evolution. If additive fields are intentionally allowed without a schema
   version change, this policy trades that forward compatibility for blinding.

5. I tested freshness and the external seal on a single path-only live change:

   ```text
   proto-cowork-session digests scratch-reciprocal-probes/succ \
     > scratch-reciprocal-probes/seal-before.txt
   # Changed only live predecessor.path to /private/withheld/new-predecessor.
   proto-cowork-session digests scratch-reciprocal-probes/succ \
     > scratch-reciprocal-probes/seal-after-path.txt
   diff -u scratch-reciprocal-probes/seal-before.txt \
     scratch-reciprocal-probes/seal-after-path.txt
   proto-cowork-session import-copilot scratch-reciprocal-probes/succ \
     scratch-reciprocal-probes/succ-stage
   ```

   Fact: the projected import exited 0. The out-of-session seal comparison
   exited 1, and only the shown `state.json` line changed, from
   `bb4eb722744b2f127fb8f541c82b459ee3c828d631d71afa568f28c049886e22`
   to
   `f63572303f9409990f3e43d4300b4aa3a8584b84030d36be28e485742a365e7a`.
   Thus import intentionally ignored the withheld field while `digests`
   detected the full-state byte change.

   I then changed only retained `predecessor.state_sha256` and retried import:

   ```text
   proto-cowork-session import-copilot scratch-reciprocal-probes/succ \
     scratch-reciprocal-probes/succ-stage
   sha256sum scratch-reciprocal-probes/succ/copilot-evidence.md
   ```

   Fact: import exited 1 with `staged input is stale relative to the live
   session: state.json`. The destination evidence SHA-256 was
   `2458e92ddcd05c54c0da9afd0e546238435ab5082f76e9ffb7f8ac5926c95ef2`
   both before and after refusal. This is concrete detection of retained-field
   staleness with failure-atomic destination behavior.

6. I pressure-tested the word “only” in the freshness claim. On the ordinary
   session I changed no field value, but rewrote live state from indented JSON
   to compact JSON:

   ```text
   proto-cowork-session digests scratch-reciprocal-probes/ordinary \
     > scratch-reciprocal-probes/ordinary-seal-before.txt
   jq -c . scratch-reciprocal-probes/ordinary/state.json \
     > scratch-reciprocal-probes/ordinary/state.json.tmp
   mv scratch-reciprocal-probes/ordinary/state.json.tmp \
     scratch-reciprocal-probes/ordinary/state.json
   proto-cowork-session digests scratch-reciprocal-probes/ordinary \
     > scratch-reciprocal-probes/ordinary-seal-after-format.txt
   proto-cowork-session import-copilot scratch-reciprocal-probes/ordinary \
     scratch-reciprocal-probes/ordinary-stage
   ```

   Fact: import exited 0 because both sides canonicalize the projected object.
   The full seal changed from
   `befbcc547dc71f000d937fe93dde15cd2d445950bb1b760f5fb5d45be08e0844`
   to
   `d2eb309e390b7e81e17ac9dddc653b7bd8cee253b1db47bb196abf5b51e38e58`
   for `state.json`.

   Conclusion: at the semantic field level, projection weakens import-time
   staleness detection for the withheld field and preserves it for retained
   fields. Literally, it also stops detecting representation-only differences
   because canonical reserialization is part of the design. The external
   `digests` seal over full raw `state.json` is the control for both categories.
   It detects change but neither prevents it nor restores a preimage.

## Critique

- Accept: the driver correctly reproduced that raw staged `state.json`
  discloses `predecessor.path`, that a path-free deterministic projection can
  round-trip, and that a retained staged-state mutation is rejected.
- Reject: the driver's claim that staged `stage.json` itself carries the
  absolute path. The revealed file and direct search show only a SHA-256; the
  literal path exists in staged `state.json` alone.
- Reject: the claim that dropping only `predecessor.path` is the preferable
  minimal design. It fixes today's known leak but demonstrably exports a future
  `audit_path`. Keeping phase and timestamps does not require a blacklist; the
  fail-closed whitelist retained and stale-checked them in successful current-
  schema imports.
- Qualify: the driver's statement that freshness “survives” projection is true
  only for the projected semantic state. It is false for the withheld path and
  for raw representation changes. The existing out-of-stage `digests` seal is
  exactly the complementary full-byte change detector, provided the driver
  stores the pre-window manifest outside both session and co-pilot sandbox and
  compares it before import.
- Accept: the driver's predecessor-validation result agrees with my independent
  pass. Calling `validate_files(pred_root, pred_state["phase"])` before
  successor creation rejects a phase/content-inconsistent predecessor and
  accepts a genuinely valid completed predecessor. This validates present
  protocol completeness, not historical authorship or a transactional snapshot.
- Cannot resolve from these experiments: which future fields should be public
  to the co-pilot. That is a schema-policy decision. The conservative behavior
  is to refuse an unclassified field, including a benign one, until its
  confidentiality and freshness treatment is explicit.

I now recommend whitelist-fail-closed. The current-schema compatibility test is
positive, the future-path failure of the blacklist is reproduced, and refusal
turns accidental disclosure into a visible coordinated-upgrade failure. Its
cost is genuine: legitimate schema evolution is brittle until the projector is
updated. That cost should be acknowledged in the protocol and made manageable
by tying the allowed-key set to `schema_version`, rejecting before stage
creation, and adding a focused test whenever the schema changes.

## Proposed plan changes

1. Replace the blacklist proposal with one shared `project_stage_state`
   function used by stage and import. For schema version 1, require exactly the
   six current top-level fields plus optional `predecessor`; require exactly
   `driver,path,phase,state_sha256` in that block; emit all current fields except
   `predecessor.path`; reject unknown or missing keys.
2. Compute and validate the projection before creating a stage, so a fail-
   closed schema refusal leaves no partial directory. Deterministically hash the
   emitted projected bytes in `stage.json` and compare the same projection of
   live state during import.
3. Document import freshness as projected semantic freshness, not raw
   `state.json` equality. Explicitly state that withheld fields and
   representation-only byte changes are outside import's comparison. Retain the
   pre/post `digests` seal over full state as the stop control for those changes,
   plus the existing recoverable-preimage requirement.
4. Add focused tests for predecessor and no-predecessor current-schema sessions
   in both independent and reciprocal modes; fresh import success; staged
   projection tamper refusal; retained live-field stale refusal with unchanged
   destination; path-only live mutation accepted by projected import but caught
   by full digests; and formatting-only mutation handled according to the
   documented semantic contract.
5. Add fail-closed tests for unknown top-level and predecessor keys, including a
   future absolute path and a benign prospective field, and assert refusal
   occurs before stage creation. Require any future schema change to update the
   projection classification and these tests together.
6. Correct the disclosure assertion to distinguish staged `state.json` from
   `stage.json`. Keep the driver's predecessor `validate_files` change and its
   valid/inconsistent/failure-atomic tests, with no claim of historical or
   cross-file transactional provenance.
