# Co-pilot evidence

## Sandbox and baseline

This is reciprocal run r3, a new run identity. I acknowledge that r2 reached Claude and returned a response with SHA-256 `778d77651b27000cbc412a87f803b3d6eaf6bf876aec46f9d78c61dfd57ab479` but was mechanically invalid (missing top-level title) and was not imported; nothing in this document treats r2 as accepted.

I operated as the Claude co-pilot (Claude Code, model Fable at high effort) restricted to the Read, Grep, and Glob tools. No Bash tool was invoked or attempted in this run, no file was written, no host or service beyond the Claude API was contacted, and the target, exchange, seals, and both sandboxes were not mutated by this role. The mandated end-of-turn `harness fleet-health` snapshot is deliberately omitted: the charter forbids contacting hosts and this role has no execution surface; that omission is recorded here rather than silently dropped.

The exact stage `/tmp/t343-claude-box/reciprocal-stage-r3` was named in the launch prompt, and all eight required files resolved on first read. This confirms the r1 stage-discoverability fix for the read-only case. Exact staged files read completely, with observed line counts from the Read tool:

- `charter.md` (68 lines)
- `plan.md` (92 lines)
- `benchmark.md` (82 lines)
- `driver-evidence.md` (77 lines)
- `copilot-evidence.md` (57 lines; the r1 independent-run document)
- `state.json` (9 lines; schema 3, staged exchange, phase `discussing`, driver codex, co-pilot claude)
- `stage.json` (17 lines; reciprocal mode, phase `discussing`)
- `artifacts/copilot-prompt.md` (52 lines; byte-identical in content to the r3 prompt I received)

Baseline identity: the co-pilot sandbox `/tmp/t343-claude-box/repo` sits at detached, clean `333d67b` per the environment snapshot, consistent with the frozen baseline `333d67b2179906dbaea5c7ea7e763613851e52b8`. Without execution I cannot run `git rev-parse`; baseline identity remains driver-attested and unverified by the co-pilot, which is the expected posture for the read-only authority class defined below.

## Commands and results

No command ran. Zero commands were executed in this run; the tool surface contained no execution capability, so this is a structural property of the run, not an encountered failure. All results below are Read-tool observations of sealed staged bytes.

Stage receipt, echoed exactly from `stage.json`:

- `prompt_sha256`: `b19be707f8b38baccf14a476e2320522f1abbd89c3660eebe2c1ffbc1b4fcf23`
- `destination_before_sha256`: `8b3bcc767897adea0801c19ad4dcd8542bc0d5ad4bb68369e7560ff3fc59a073`
- `inputs.benchmark.md`: `2d1c08892c36b371b5d7eba0862a7684f6c91fa162bdaab439414f23f1bae3d7`
- `inputs.charter.md`: `498e28a960dd6790eb034ef9022934765b1f5b521050bf7c6cd51b197435c74e`
- `inputs.copilot-evidence.md`: `8b3bcc767897adea0801c19ad4dcd8542bc0d5ad4bb68369e7560ff3fc59a073`
- `inputs.driver-evidence.md`: `9e3f8b99681f163fda63cac3f35977a950ffc32d9eeb32f108845bd6323ab775`
- `inputs.plan.md`: `2dfbb2cc100eb21ccca5bef84f8a4dc5e2abe419739744614062f8e8267f16f5`
- `inputs.state.json`: `700aedbbf4ceec611c8be879fcb28b5a295d2d9375fe97bfd73f209b1027d393`

`stage.json` contains no top-level `stage_sha256` field, and I do not invent one. Two derived observations: first, `inputs.copilot-evidence.md` equals `destination_before_sha256`, so the staged destination is the unmutated r1 evidence document — consistent with benchmark case 5's requirement that variants fail before live evidence mutation. Second, r1's proposed change 3 required the evidence to echo "the `stage_sha256` from `stage.json`"; as written, that validator would fail closed on every honest run because the field does not exist. The receipt contract must instead bind to `prompt_sha256` plus the `inputs` digest map, or to a canonical stage digest the tooling itself computes and writes.

## Critique

1. **The r1 independent run is invalid as eight-case reproduction, and I confirm this from the staged bytes.** The r1 document states it never reached the charter, plan, or benchmark and executed zero commands, so it could not have reproduced any of the eight cases it never saw. It remains valid as constrained static evidence (its reading of `tests/test-codex-claude-cowork-skill.sh` — silent `command -v` skips, monkeypatched timeout arithmetic, form-only import validation — is checkable against tracked sources) and is most useful as a live negative result: a co-pilot with a dead execution surface and no benchmark still produced a document satisfying every mechanical import precondition. Mechanically importable prose does not prove execution. That finding motivates the execution-binding amendments and must be retained, not repaired away by relabeling the run a success.

2. **Stage discoverability is fixed for the read-only path; execution-bound Claude remains unproven.** This run resolved all eight staged files immediately from the exact path in the prompt, closing r1's discoverability gap. But this run was read-only by construction, so it provides no evidence that the `EROFS` state-directory failure r1 observed is resolved. A working execution-bound Claude co-pilot has not yet been demonstrated in any run, and no plan step may assume it until one succeeds.

3. **The task-bound handoff packet (driver critique 3) and backward evidence binding (r1 changes 1, 3, 6) are complementary, and the correct join is branching by authority class.** The packet binds forward what a fresh process may do; the evidence contract binds backward what it actually did. Read-only class: a stage receipt (prompt and input digests, as echoed above) plus a read manifest (the file list with observed extents, as recorded above) — this document itself demonstrates that the read-only contract is satisfiable today with no new tooling. Execution class: per-case `command`/`exit`/`output_sha256` records plus mandatory driver reproduction of at least one deterministic record. Applying the execution contract to a read-only run would force fabrication or guaranteed refusal; applying only the read-only contract to an execution run reopens the r1 hole. The driver-evidence test-pass claims illustrate the same point in reverse: they are currently driver-attested prose, and under the amended contract they too would carry reproducible digests.

4. **The r2 failure is itself the retry fixture.** r2's response was received, hashed, judged mechanically invalid for a prompt-side structural omission, not imported, and retried under new identity r3 — no blind replay, durable classification, protected state unchanged, exactly one safe next action. That is benchmark case 6 behavior observed in the wild, at the pre-model transport/format layer, and it should be encoded as a fixture from the recorded r2 artifacts rather than re-simulated.

5. **The proposed post-`go` slice is correctly minimal and correctly repository-local.** The five items (packet schema and negative identity fixtures; canonical stage receipt plus mismatch fixtures; one real nonpersistent fresh-process read-only round trip; the broken-sandbox negative; the r2-derived transport-failure/new-identity retry fixture) each trace to an observed failure or gap from runs r1–r3, and none touches global Claude settings, live systems, or unrelated repositories. Sequencing note: the real fresh-process round trip should use the read-only contract first, since this run proves it achievable; an execution-bound round trip stays deferred behind a demonstrated sandbox-provisioning fix. Benchmark cases 7 and 8 remain correctly outside the slice, per driver plan change 4.

## Proposed plan changes

1. **Amend r1 change 3 (stage receipt).** The receipt requirement binds to `prompt_sha256` and the `inputs` digest map actually present in `stage.json` — or to a canonical stage digest the cowork tooling computes and records — never to a field absent from the sealed stage. Import refuses evidence whose echoed digests mismatch the sealed values; the validator must fail closed on tampering, not on honest runs.

2. **Adopt authority-class branching in the handoff packet and evidence contract.** The packet carries an explicit authority class. Read-only requires the stage receipt plus a complete read manifest and forbids execution records. Execution class requires per-case `command=<argv> exit=<int> output_sha256=<64 hex>` records plus mandatory driver reproduction of at least one deterministic record, and additionally the `git rev-parse HEAD` baseline record from r1 change 6; read-only runs instead record baseline as driver-attested.

3. **Freeze the post-`go` slice to exactly the five repository-local items** enumerated in Critique point 5, with the read-only round trip sequenced before any execution-bound attempt and the r2 artifacts reused as the retry fixture's ground truth.

4. **Retain r1 changes 1, 2, 4, and 5 as amended above** (execution-bound evidence, broken-sandbox negative, no silent native-CLI skips, one real fresh-process round trip), and retain driver plan changes 1–5 unchanged, including the task-scoped launch mapping in preference to any global interactive-profile change.

5. **Acceptance.** Benchmark `t343-claude-handoff-v1` is accepted by the co-pilot with exactly the amendments above, contingent on the owner saying `go`. Global Claude settings, live systems, and unrelated repositories remain out of scope; the frozen cutoff, protected publication path, zero-required-approvals policy, ABQ exclusion, and 16-slice summary contract stand without expansion.
