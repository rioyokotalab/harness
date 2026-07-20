# Co-pilot evidence

## Sandbox and baseline

I worked only in `/tmp/harness-t283-round6-codex`, including disposable helper copies and fixtures under `scratch-round6/`. I made no network calls, installs, or writes outside this sandbox.

Baseline confirmation:

```text
$ git -C /tmp/harness-t283-round6-codex rev-parse HEAD
52c7931469c491b716b19d75745a9a411f9fead0
```

Initial status was detached HEAD with one pre-existing untracked compiler cache:

```text
$ git status --short --branch
## HEAD (no branch)
?? shared/skills/codex-claude-cowork/scripts/__pycache__/
```

I read both reciprocal inputs completely:

```text
$ wc -l stage-reciprocal/driver-evidence.md
104 stage-reciprocal/driver-evidence.md

$ sed -n '1,180p' stage-reciprocal/driver-evidence.md
$ sed -n '1,360p' stage-reciprocal/copilot-evidence.md
```

The driver reports a separate detached sandbox at the same `52c7931` baseline. Its strongest confirmed result agrees with my independent pass: rewriting the unsealed `stage.json` after a crash-shaped evidence replacement can launder that state into a valid-looking receipt, while a protected exact hash of `stage.json` rejects the rewrite before import mutation.

My earlier prototype was `scratch-round6/cowork-session-proto`; its source initially matched the baseline helper at SHA-256:

```text
7ba2aff1d5a4c05e893f0b30257e8f3f69be78f07309e33b36cdcf761d771705
```

For this reciprocal pass I created two further disposable copies:

- `scratch-round6/cowork-session-minseal`, removing only the explicit `stage_schema_version` seal field and its check.
- `scratch-round6/cowork-session-sealfail`, injecting a deterministic failure at external seal publication to test cross-file behavior.

These experiments model path relationships and failures inside one filesystem namespace. They do not establish OS confinement against another process.

## Commands and results

1. The independent pass reproduced the unsealed laundering defect against the baseline helper.

The essential sequence was:

```sh
"$BASE_HELPER" stage "$CURRENT_SESSION" "$CURRENT_STAGE" --mode independent
cp scratch-round6/valid-evidence.md \
  "$CURRENT_STAGE/candidate-copilot-evidence.md"

BEFORE_HASH=$(sha256sum "$CURRENT_SESSION/copilot-evidence.md" | cut -d' ' -f1)
cp scratch-round6/valid-evidence.md "$CURRENT_SESSION/copilot-evidence.md"
AFTER_HASH=$(sha256sum "$CURRENT_SESSION/copilot-evidence.md" | cut -d' ' -f1)
sed -i "s/$BEFORE_HASH/$AFTER_HASH/" "$CURRENT_STAGE/stage.json"

"$BASE_HELPER" import-copilot "$CURRENT_SESSION" "$CURRENT_STAGE"
"$BASE_HELPER" verify-receipts "$CURRENT_SESSION"
```

Observed:

```text
BEFORE_HASH=da32107e44a02377b76bf9e79cea08250357c548157a4adc8125295031c5a4b6
AFTER_HASH=ec0bd5742b824bd28f5ed9239b0634c500de7b70c0ecf88ece11198232a3847c

imported independent co-pilot evidence
sha256=ec0bd5742b824bd28f5ed9239b0634c500de7b70c0ecf88ece11198232a3847c
receipt=receipts/independent.json

valid independent receipt for live co-pilot evidence
sha256=ec0bd5742b824bd28f5ed9239b0634c500de7b70c0ecf88ece11198232a3847c
```

The receipt recorded both candidate and destination-before as the already-replaced evidence hash. This confirms that the unsealed manifest was a co-pilot-controlled trust anchor.

2. I removed `stage_schema_version` from the seal while retaining the driver’s other seven fields.

The disposable edit removed that key from `SEAL_KEYS`, seal creation, and seal validation. The copy compiled:

```text
$ python3 -m py_compile scratch-round6/cowork-session-minseal
[exit 0]
```

I initialized a fresh schema-2 staged session, advanced it to discussion, created a sealed independent stage, inspected both schemas, imported valid evidence, and verified its receipt:

```sh
scratch-round6/cowork-session-minseal init \
  scratch-round6/minseal-session --driver claude
cp stage-independent/charter.md scratch-round6/minseal-session/charter.md
cp stage-independent/plan.md scratch-round6/minseal-session/plan.md
scratch-round6/cowork-session-minseal advance \
  scratch-round6/minseal-session discussing
scratch-round6/cowork-session-minseal stage \
  scratch-round6/minseal-session \
  scratch-round6/copilot-box/minseal-stage \
  --mode independent \
  --seal scratch-round6/external-seals/minseal.json
```

Observed:

```text
initialized /tmp/harness-t283-round6-codex/scratch-round6/minseal-session with claude driving codex
advanced /tmp/harness-t283-round6-codex/scratch-round6/minseal-session to discussing
staged independent exchange: /tmp/harness-t283-round6-codex/scratch-round6/copilot-box/minseal-stage stage_sha256=9ba28ec7c84802718aa48e2f46d355b17ebbc0c89af638052bf7726a00355162
seal keys: copilot, destination_before_sha256, driver, mode, phase, schema_version, stage_manifest_sha256
seal schema_version: 1
stage schema_version: 2
sealed hash matches stage.json: True
```

After placing the valid candidate:

```text
$ scratch-round6/cowork-session-minseal import-copilot \
    scratch-round6/minseal-session \
    scratch-round6/copilot-box/minseal-stage \
    --seal scratch-round6/external-seals/minseal.json
imported independent co-pilot evidence sha256=ec0bd5742b824bd28f5ed9239b0634c500de7b70c0ecf88ece11198232a3847c receipt=receipts/independent.json

$ scratch-round6/cowork-session-minseal verify-receipts \
    scratch-round6/minseal-session
valid independent receipt for live co-pilot evidence sha256=ec0bd5742b824bd28f5ed9239b0634c500de7b70c0ecf88ece11198232a3847c
```

Thus a separate stage-schema field is not required for a valid import. The seal’s `schema_version` identifies the seal schema, while the hashed `stage.json` contains and transitively commits its own `schema_version`.

3. The reduced seal still detected a manifest change.

I created a second stage under the reduced schema, changed one recorded input hash to another syntactically valid SHA-256, and retained the original seal:

```text
tampered input key: charter.md
sealed stage hash: a3ca20976b6c6dfe9fc14546afb069ab0a132219df097a713b53b3be4469b693
before stage hash: a3ca20976b6c6dfe9fc14546afb069ab0a132219df097a713b53b3be4469b693
after stage hash:  5e58818848e5f5cbbb3249e9e888293e65251900ba72e4126a46ebbe97b87bc5
```

Import result:

```text
$ scratch-round6/cowork-session-minseal import-copilot \
    scratch-round6/minseal-tamper-session \
    scratch-round6/copilot-box/minseal-tamper-stage \
    --seal scratch-round6/external-seals/minseal-tamper.json
cowork-session: seal stage manifest hash does not match stage.json
exit=1
```

No receipt was created. Because `stage.json` includes its stage schema, roles, mode, phase, destination-before hash, and per-input hashes, its exact SHA-256 commits all those values. Import separately verifies staged fixed-input bytes against those hashes.

This coverage is deliberately scoped. The seal does not commit the candidate, which must remain writable, or arbitrary `artifacts/` content. It also cannot detect a rewrite of both stage and seal when the attacker can modify the purportedly external seal.

4. A nested stage defeats the current stage-parent location approximation.

The simulated co-pilot root was `scratch-round6/copilot-box`. I placed the stage two levels below it and asked the prototype to write the seal elsewhere inside the same co-pilot root, but outside the stage’s immediate parent:

```sh
mkdir -p scratch-round6/copilot-box/nested/level
scratch-round6/cowork-session-proto stage \
  scratch-round6/base-session \
  scratch-round6/copilot-box/nested/level/stage \
  --mode independent \
  --seal scratch-round6/copilot-box/nested/attacker-writable-seal.json
```

Observed:

```text
staged independent exchange: /tmp/harness-t283-round6-codex/scratch-round6/copilot-box/nested/level/stage stage_sha256=a181d696bbf7d9a70fc0a6ee8306ca36759e7550f84c22c7f8b6349b0afa347c
600 1 scratch-round6/copilot-box/nested/attacker-writable-seal.json
```

Resolved relationship check:

```text
/tmp/harness-t283-round6-codex/scratch-round6/copilot-box
/tmp/harness-t283-round6-codex/scratch-round6/copilot-box/nested/level
/tmp/harness-t283-round6-codex/scratch-round6/copilot-box/nested/attacker-writable-seal.json
under declared co-pilot root: yes
under checked stage parent: no
```

The helper accepted a seal inside the simulated co-pilot sandbox because it only forbade descendants of `stage_root.parent`, which was `.../nested/level`. Therefore the current rule is correct only under an explicit direct-child contract: `STAGE_DIR` must be a direct child of the co-pilot sandbox, making `stage_root.parent` the actual sandbox root.

5. Stage creation followed by external seal publication is not cross-file atomic.

The fault-injection copy raises an `OSError` only when writing `forced-seal.json`, after the normal code has populated the stage and written `stage.json`.

Command:

```sh
scratch-round6/cowork-session-sealfail stage \
  scratch-round6/sealfail-session \
  scratch-round6/copilot-box/sealfail-stage \
  --mode independent \
  --seal scratch-round6/external-seals/forced-seal.json
```

Observed:

```text
exit=1
Traceback (most recent call last):
  ...
  File ".../cowork-session-sealfail", line 661, in stage_session
    write_new_file(
  File ".../cowork-session-sealfail", line 279, in write_new_file
    raise OSError("injected seal publication failure")
OSError: injected seal publication failure
stage_exists=yes
stage_json_exists=yes
seal_exists=no
```

Attempting to import that partial result failed closed:

```text
$ scratch-round6/cowork-session-proto import-copilot \
    scratch-round6/sealfail-session \
    scratch-round6/copilot-box/sealfail-stage \
    --seal scratch-round6/external-seals/forced-seal.json
cowork-session: missing protocol entry: /tmp/harness-t283-round6-codex/scratch-round6/external-seals/forced-seal.json
exit=1
```

This supports the narrow description “stage then seal, with fail-closed import,” not “transactional” or “crash-atomic.” I did not simulate power loss, filesystem corruption, or every possible partial write.

6. Ordinary `verify-receipts` cannot revalidate external seal bytes.

A successful schema-2 receipt recorded:

```text
receipt seal_sha256: ddc02eba6015ba0f0a011723c3bf3a726c79fcdd6e9dca4f84ddd09a703ae335
```

The corresponding external seal was subsequently different:

```text
$ sha256sum scratch-round6/external-seals/valid-seal.json
5caa4079ac4b58a9626a0196ad7fbc5b3a12685cc21d993ed7e65e7b8e8ee3c4  scratch-round6/external-seals/valid-seal.json
```

Yet receipt verification still succeeded:

```text
$ scratch-round6/cowork-session-proto verify-receipts \
    scratch-round6/cases/valid-session
valid independent receipt for live co-pilot evidence sha256=ec0bd5742b824bd28f5ed9239b0634c500de7b70c0ecf88ece11198232a3847c
```

This is expected from the interface: `verify-receipts SESSION_DIR` receives no external seal path. It validates that the receipt contains a well-formed stored commitment and that the internal receipt/evidence chain is consistent; it cannot reopen or compare retained external bytes.

7. Receipt-schema compatibility is distinct from legacy session-schema compatibility.

`scratch-round6/current-session` is a schema-2 session containing an actual receipt written by the baseline pre-change helper:

```text
session schema_version: 2
receipt schema_version: 1
receipt keys: candidate_sha256, copilot, destination_before_sha256, driver, imported_at, inputs, mode, phase, raw_state_sha256, schema_version, stage_manifest_sha256
```

Both the baseline reader and my backward-compatible prototype accepted it:

```text
$ shared/skills/codex-claude-cowork/scripts/cowork-session \
    verify-receipts scratch-round6/current-session
valid independent receipt for live co-pilot evidence sha256=ec0bd5742b824bd28f5ed9239b0634c500de7b70c0ecf88ece11198232a3847c

$ scratch-round6/cowork-session-proto verify-receipts \
    scratch-round6/current-session
valid independent receipt for live co-pilot evidence sha256=ec0bd5742b824bd28f5ed9239b0634c500de7b70c0ecf88ece11198232a3847c
```

The prototype creates receipt schema 2 but explicitly reads both versions:

```text
RECEIPT_SCHEMA_VERSION = 2
SUPPORTED_RECEIPT_SCHEMA_VERSIONS = {1, 2}
```

Therefore merely changing a single strict receipt-version constant from 1 to 2 would break already-created receipts. Supporting strict schema-1 sessions without receipts does not solve this separate compatibility case.

## Critique

**Accepted: external manifest seal.** I accept the driver’s central design. The exact protected SHA-256 of `stage.json` closes the reproduced laundering route. The seal must be required for schema-2 staged creation and import, validated before import mutation, and its exact bytes bound into the resulting receipt.

**Accepted: one seal schema version.** I withdraw my first-pass requirement for an explicit `stage_schema_version`. The run with the seven-key seal succeeded, and manifest tampering was still rejected. `stage.json` already carries its schema version; hashing its exact bytes commits that value transitively. A second stage-schema field is redundant for integrity and creates another duplicated value that must remain synchronized.

The driver’s duplicated mode, role, phase, and destination fields are likewise not cryptographically necessary once the exact manifest hash is checked. They remain reasonable for explicit diagnostics and defensive consistency checks. The cryptographic core could be only the seal schema and exact manifest hash, but the driver’s seven-key schema is still small, path-free, and strict.

**Qualification: “fully detects tampering.”** The minimal seal detects changes to `stage.json`, and import’s existing hash checks extend that protection to the fixed staged inputs. It does not detect arbitrary candidate or artifact changes, prove candidate authorship, bind a filesystem location, or survive an attacker who can rewrite the seal itself. Any “fully detects tampering” claim must be limited to sealed manifest metadata and manifest-bound fixed inputs while the seal remains outside co-pilot write authority.

**Rejected: arbitrary-stage location safety.** I reject the claim that refusing a seal below `stage_root.parent` identifies the co-pilot sandbox for an arbitrary nested stage. The nested-stage run accepted a seal still inside the declared co-pilot tree.

The smallest correction is to require and document that every `STAGE_DIR` is a direct child of the co-pilot sandbox; then its parent is the declared co-pilot root already used by the helper. This is a workflow precondition, not independent discovery or OS enforcement. If the project wants the helper to mechanically validate nested layouts, an explicit `--copilot-root ROOT` argument is necessary and safer, but it is a larger interface change that must be supplied consistently to both `stage` and `import-copilot`.

**Accepted: non-atomic description.** The injected post-stage seal failure left a complete-looking stage and no seal. Import refused it, which is fail-closed, but the two-location write is not atomic. Preflight can prevent known bad paths from creating a stage; it cannot guarantee rollback after later I/O failure or process termination.

**Rejected: ordinary receipt verification revalidates external bytes.** `verify-receipts SESSION_DIR` cannot inspect a path it is not given. The mismatching retained seal and successful verification demonstrate this. The receipt preserves the seal hash; retained external bytes require a separate comparison or an expanded verification interface.

**Accepted only with compatibility refinement: receipt schema bump.** New receipts may use schema 2 and require `seal_sha256`, but the reader must retain an exact schema-1 key set for already-created receipts in schema-2 staged sessions. This is separate from preserving strict schema-1 receipt-free sessions and schema-2 direct sessions.

**Unresolved limits.** I could not dynamically test a genuinely foreign-owned seal as the unprivileged sandbox user. I also did not establish protection against an actual same-UID process, hard power loss, filesystem failure modes beyond injected seal-publication failure, SHA-256 collision, or descriptor/path races. The path experiments establish relationships, not OS confinement.

## Proposed plan changes

1. Adopt the driver’s seven-key seal schema without `stage_schema_version`:

   ```text
   schema_version
   driver
   copilot
   mode
   phase
   destination_before_sha256
   stage_manifest_sha256
   ```

   Require an exact key set, supported seal schema, valid SHA-256 values, metadata equality with `stage.json`, and equality between `stage_manifest_sha256` and the exact retained `stage.json` bytes.

2. Document that `stage_manifest_sha256` transitively binds the stage schema and all other manifest fields. Describe duplicated role/mode/phase/destination fields as explicit consistency checks and diagnostics, not additional cryptographic commitments.

3. Scope the tamper claim precisely: the seal protects the manifest and, through import’s existing checks, fixed staged inputs. It intentionally does not pre-seal the writable candidate or artifacts.

4. Require and document `STAGE_DIR` as a direct child of the co-pilot sandbox, and state that the helper consequently treats `stage_root.parent` as that declared root. Add a nested-stage regression demonstrating why this precondition matters. If direct-child placement cannot be guaranteed by every caller, replace the approximation with required `--copilot-root ROOT` arguments for both staging and import.

5. Keep seal-path preflight before stage creation, but document that later stage/seal publication failure may leave a sealless stage. Such a stage is non-importable and requires exact inspection plus fresh stage/seal paths; do not call the operation atomic or transactional.

6. Create only receipt schema 2 with mandatory `seal_sha256`, while reading receipt schemas 1 and 2 through separate exact allowed-key sets. Preserve the tested case of a schema-2 session containing a pre-change schema-1 receipt.

7. State that `verify-receipts SESSION_DIR` validates the stored seal commitment and internal receipt/evidence chain but does not revalidate external seal bytes. The smallest implementation keeps the interface unchanged and requires a separate retained-seal hash comparison. Optional seal-path arguments would provide stronger integrated verification but are not necessary to close the demonstrated import defect.

8. Use a descriptor-bound seal reader if practical: open without following symlinks, `fstat` and validate that descriptor, then read and hash those same bytes. This narrows an avoidable check/read race but does not replace the external write-authority requirement.

9. Retain the independent-pass edge coverage: omitted or missing seal, altered seal, wrong-stage seal, symlink, hard link, mode mismatch, non-UTF-8, extra key, unsupported seal schema, role/mode/phase/destination mismatch, edited manifest, forbidden placement, valid import, replay, receipt seal hash, receipt-schema-1 compatibility, schema-1 staged behavior, and schema-2 direct behavior.

10. Preserve the explicit limitations: the seal supplies byte-level tamper detection and fail-closed import only while held outside co-pilot write authority. It does not prove authorship, infer the real sandbox boundary, establish OS confinement, restore overwritten evidence, bind stage identity or location, or make evidence/receipt or stage/seal updates crash-atomic.