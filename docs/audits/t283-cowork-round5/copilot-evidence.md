# Co-pilot evidence

## Sandbox and baseline

Blinded co-pilot (Claude) working only inside sandbox
`/tmp/harness-t283-round5-claude` and the reciprocal stage
`/tmp/harness-t283-round5-claude/stage-reciprocal`. In this reciprocal pass I read
the staged `charter.md`, `plan.md`, projected `state.json`, `stage.json`, and
both revealed evidence files (`copilot-evidence.md`, `driver-evidence.md`), plus
the baseline helper and protocol at
`shared/skills/codex-claude-cowork/{SKILL.md,references/protocol.md,scripts/cowork-session}`.
I did not locate or access any live session.

- Declared common baseline: `f87b019836ad5c5ed4cb9c85ac409d47484e06f2` (charter,
  stage `plan.md`). The sandbox is a detached working tree at that commit. (fact)
- `git status --short` on the sandbox was clean before and after every probe; all
  work is in untracked `scratch/` and stage trees. No tracked file, ref, setting,
  or the live target was touched. (fact)
- Interpreter: `python3 --version` → `Python 3.12.3`. (fact)
- Reciprocal `stage.json`: mode `reciprocal`, phase `discussing`, roles
  driver=codex / copilot=claude, five path-free input hashes. Its `artifacts/`
  holds only `copilot-prompt.md`. (fact)
- Disposable prototype for this round: `scratch/r5-proto/receipt_proto.py` (a
  narrow model of receipt-aware schema-2 semantics) driven by
  `scratch/r5-proto/probe.sh`. Bounded transcript:
  `stage-reciprocal/artifacts/reciprocal-proto.log` (~3.3 KiB). I also grounded
  the two compatibility claims against the **real** helper. (fact)

Preserved independent findings (unchanged, still valid): the current helper has
no receipt of any kind; `import-copilot` prints the candidate SHA-256 only to
stdout (ephemeral); `digests` covers `state.json` + the six driver Markdown files
and excludes `copilot-evidence.md` and `artifacts/`; a post-import candidate
overwrite is invisible to both `check` and `digests` (independent probe 1); a
receipt under shared `artifacts/` is unsealable and co-pilot-writable
(independent probe 2). These drive the receipt design and are not weakened by
anything below.

## Commands and results

All results are in `reciprocal-proto.log`. Labels A–D map to the prompt's
conflicts.

**Real-helper grounding (compatibility tension is real, not modelled).**
Against `shared/.../cowork-session`: a stray top-level `receipts/` →
`unexpected top-level protocol entries: receipts` (exit 1); `schema_version: 2`
→ `unsupported schema version` (exit 1); `schema_version: 1` planning session →
valid (exit 0). So the required top-level `receipts/` my independent pass
selected cannot be added silently: today it breaks every complete round-1..4 v1
session (they lack `receipts/`) and a bare version bump is rejected outright.
(observed)

**A. Legacy v1 vs receipt-aware v2 (prototype).**
- A1: a schema-1 session with no `receipts/` validates. (observed)
- A2: a schema-1 session containing a stray `receipts/` is rejected
  (`unexpected top-level`) — legacy strictness is preserved. (observed)
- A3: a schema-2 session with **zero** receipts validates at `discussing`. (observed)
- A4: a schema-2 `ready-gate` with no `receipts/reciprocal.json` is **refused**
  (`ready phase requires receipts/reciprocal.json`) — a receipt-aware session
  cannot silently omit receipts. (observed)
- A5: a schema-1 `ready-gate` passes with no receipt obligation — old complete
  sessions remain valid provenance. (observed)

**B. Crash-shaped retry / `destination_before_sha256` (prototype).**
- B1: a bound independent import creates `receipts/independent.json`. (observed)
- B2: injecting a hard crash (`os._exit`) after the evidence replace and before
  the receipt create yields exactly the crash shape the prompt names: live
  `copilot-evidence.md` == candidate (`b49e0659…`), **no receipt**. (observed)
- B3: **without** destination binding, retry from B2's state succeeds and mints a
  receipt whose `destination_before_sha256 == candidate_sha256` (`prev==cand:
  True`) — an ambiguous receipt that cannot tell a clean import from a
  post-crash resume. (observed)
- B4: **with** `destination_before_sha256` bound in `stage.json`, the same
  post-crash retry **fails closed** (`destination drift: live b49e0659… != stage
  destination_before 9692a308…`, no receipt). (observed)

**C. Receipt commitments / disclosure (prototype).**
- C1: receipt fields = `schema_version, mode, driver, copilot, phase,
  inputs{name→sha256}, raw_state_sha256, stage_manifest_sha256, candidate_sha256,
  destination_before_sha256`. (observed)
- C2: `grep -rE '/home|/tmp|/Users|/root|scratch|harness-t283'` over every
  produced receipt returned **no match** — receipts carry only roles, phase,
  hashes. (observed)

**D. Failure-atomic receipt create (prototype).** Create is temp-write→fsync→
`os.link(temp,final)`→fsync-dir→unlink(temp), replacing the independent pass's
bare `O_EXCL`.
- D1: crash after the temp is written but before the link leaves **no file at the
  final name** — only a leading-dot temp residue. The final receipt never holds
  partial bytes. (observed)
- D2: crash after the link but before the temp unlink leaves the final receipt as
  **valid JSON with `nlink 2`** plus a temp residue. Content is complete; the
  stray link count and temp are detectable (see critique). (observed)
- D3: after a post-import overwrite of `copilot-evidence.md`, `verify-receipts`
  fails with the live-vs-receipt candidate mismatch printed. (observed)
- D4: appending one byte to a receipt changes exactly its `digests` line
  (`3c8b140c…` → `aba9ca21…`). (observed)
- D5: a second import with the receipt present is refused (`replay refused`)
  before touching evidence. (observed)

## Critique

Addressing the five reciprocal points, accepting/rejecting the driver's specific
proposals with reasons.

**1. Compatibility — I withdraw "required top-level `receipts/` on schema 1" and
adopt an explicit schema-2 gate.** The real-helper grounding shows my independent
location choice, if bolted onto schema 1, invalidates the exact complete v1
predecessors the charter relies on for provenance. The driver's concern is
correct. Between the driver's two options I choose the **session schema bump to 2
with retained v1 support**, not the `artifacts/import-receipts/` subtree:
A-probes show a version-gated helper keeps v1 sessions byte-for-byte valid (A1,
A5), forbids `receipts/` where it does not belong (A2), and still forbids silent
omission at ready phases for v2 (A4). A closed subtree under `artifacts/` is
weaker: `artifacts/` is deliberately open-ended and co-pilot-writable and
`digests` excludes it wholesale (independent probe 2), so enforcing "closed"
inside an intentionally-open directory needs a special case that fights the
existing shared-artifact contract — the driver itself notes calling all
artifacts driver-owned would break that contract. A top-level `receipts/` gated
by `schema_version >= 2` is the smaller, cleaner boundary. `init --predecessor`
keeps validating a v1 predecessor under v1 rules, so round-1..4 provenance is
untouched. (accept driver's compatibility requirement; choose schema bump)

**2. `destination_before_sha256` — accept; it is necessary, not optional.** My
independent pass called evidence-without-receipt "detectable and retry-safe."
B2–B4 sharpen that: it is *detectable* but a naive retry is **not** safe in
independent mode. Reciprocal mode is already stale-rejected because
`copilot-evidence.md` is a staged input, but independent mode has no such guard,
so an unbound retry mints an ambiguous receipt (B3). Binding the destination's
pre-import hash makes both modes fail closed on the crash shape (B4). This is the
single change that converts "retry-safe" from a hopeful claim into an enforced
one. (accept)

**3. Driver's extra commitments — accept both, with a precise reason each.**
- *Full raw live-state SHA-256*: **accept.** My independent receipt committed
  only the *projected* state hash (what the co-pilot saw). The projection drops
  `predecessor.path` and any future withheld field, so a projected-only hash
  cannot bind a change confined to a withheld field. Adding `raw_state_sha256`
  binds the receipt to the complete live state at import, complementing the
  out-of-session `digests` seal. Disclosure is nil: it is a hash, and receipts
  are never among `STAGE_INPUTS`, so no receipt field ever reaches a blinded
  co-pilot. Keep **both** the projected `inputs` hashes (tie to co-pilot-visible
  state and to import freshness) and `raw_state_sha256` (tie to full live state).
- *Exact `stage.json` SHA-256*: **accept** as `stage_manifest_sha256`. It is a
  compact single anchor to the exact manifest that produced the import, and
  `stage.json` is itself path-free by construction (projected/whitelisted), so
  even its preimage is disclosure-safe. Mild redundancy with the enumerated
  `inputs` is acceptable — it lets one field prove which stage was consumed.

**4. Failure-atomic receipt — accept the driver's temp+atomic-create critique,
and state the exact crash limit from D1–D2.** A bare `O_EXCL` open then write can
leave partial bytes at the final name if the process dies mid-write; the driver
is right. temp-write→fsync→`link`→unlink makes the final name appear only fully
formed (D1: a pre-link crash leaves no final file at all, only a temp). The exact
limits, honestly:
- *Content atomicity holds:* the final receipt is never partial.
- *Cross-file atomicity does not exist:* evidence-replace and receipt-create are
  two files; a crash between them (B2) cannot be made atomic — that window is
  covered by `destination_before` retry refusal, not by atomicity.
- *A residue window remains:* a crash after `link` before `unlink(temp)` leaves
  the final with `nlink 2` plus a temp (D2). Both are **detectable** — the
  layout check already rejects a receipt with `nlink != 1`, and a leftover
  `.mode.*.tmp` is an unexpected entry — but they are not auto-repaired. Two
  design notes follow from this: (a) place the temp **outside** the closed
  `receipts/` dir (e.g. session root, same filesystem so `link` stays atomic) so
  a crash residue never makes `receipts/` fail its own closed-set check, and
  import/validate should sweep a stale same-invocation temp before validating;
  (b) rollback must unlink only a receipt this invocation created, then restore
  evidence — never a pre-existing prior receipt. Process rollback (the
  non-crash path) is clean (independent probes 8–9 still hold); crash atomicity
  is bounded to "content-complete + detectable + retry-fails-closed," which is
  what should be claimed. Path absence (no `receipts/`) and mutation are handled:
  absence is legal at discussing (A3), mutation is caught by `verify-receipts`
  (D3) and by `digests` drift (D4).

**5. Seal deviation — I accept only what a manifest supports, and the manifest I
would need was not staged.** The driver reports it wrote `driver-evidence.md`
while the independent Claude process ran and points to `artifacts/seal-deviation.md`.
That artifact is **not** in this reciprocal stage — `stage-reciprocal/artifacts/`
contains only `copilot-prompt.md`. So as a blinded co-pilot I can confirm exactly
one fact: `driver-evidence.md` necessarily changed during the window (it is the
file being authored). I **cannot** verify the accompanying claims ("all staged
inputs and other protected entries stayed unchanged"; "a fresh seal around
validation/import compared clean") because their supporting manifest was withheld
from the stage. That withholding is itself the finding: a seal-deviation claim is
only co-pilot-checkable if its before/after manifest is a staged artifact. The
scratch `seal-before.txt`/`seal-after.txt` in the sandbox are my own prototype's,
not the driver's seal, and must not be conflated with it. Prescription is in the
plan changes: freeze driver evidence before the window and stage the manifest.

Uncertainty / not tested: I injected `os._exit` to model a hard crash but did not
force a real power-loss between `fsync` and directory `fsync`; the durability
ordering is reasoned from the fsync/link sequence, not observed at the block
layer. Single-driver protocol means concurrent importers stay out of scope.

Rejected (unchanged from independent, plus this round):
- Receipt in shared `artifacts/` or `artifacts/import-receipts/` — rejected;
  unsealable in an intentionally-open, co-pilot-writable directory (probe 2).
- Receipt as fields in `state.json` — rejected; fights the fail-closed staging
  projection and the staleness compare.
- One append-only `receipts.jsonl` — rejected; no `O_EXCL`/link replay guard and
  no trivial prior-receipt immutability.
- Bare `O_EXCL` receipt write — now rejected in favor of temp+link (driver point
  4; D1).
- Projected-state-hash **only** in the receipt — rejected; add `raw_state_sha256`
  to bind withheld fields (driver point 3).

## Proposed plan changes

Exact edits to `plan.md`:

1. **Confirmed facts / Steps — compatibility design (was open).** "Store receipts
   under a **closed top-level `receipts/` gated by a session `schema_version`
   bump to 2**. The helper supports both schemas: schema 1 keeps today's exact
   layout and forbids `receipts/` (legacy sessions and `init --predecessor`
   validate unchanged; grounded against the real helper and prototype A1/A2/A5);
   schema 2 permits `receipts/` holding at most `independent.json` and
   `reciprocal.json`. Reject the `artifacts/import-receipts/` subtree: `digests`
   excludes `artifacts/` and it is co-pilot-writable, so a closed set cannot be
   enforced there without breaking the shared-artifact contract (probe 2)."

2. **Steps — ready-phase obligation.** "For schema-2 sessions,
   `ready-for-execution` and later require `receipts/reciprocal.json` to exist and
   `verify-receipts` to pass (A4). `discussing` tolerates 0/1 receipts so the
   first import is not blocked (A3). Schema-1 sessions carry no receipt
   obligation (A5)."

3. **Confirmed facts — receipt fields.** "Fields: `schema_version, mode, driver,
   copilot, phase, inputs{name→projected sha256}, raw_state_sha256,
   stage_manifest_sha256, candidate_sha256, destination_before_sha256`. Keep both
   the projected `inputs` hashes (co-pilot-visible/freshness tie) and
   `raw_state_sha256` (binds withheld fields the projection drops). All fields are
   hashes/roles; no path appears (C2); receipts are never staged, so no field
   reaches a blinded co-pilot."

4. **Steps — bind destination and creation/rollback order.** "Add
   `destination_before_sha256` to `stage.json`. Import order: (a) freshness of
   staged inputs; (b) replay guard — refuse if `receipts/<mode>.json` exists,
   before touching evidence; (c) **verify live `copilot-evidence.md` == staged
   `destination_before_sha256`; fail closed on mismatch** (B4 — prevents the
   ambiguous post-crash receipt of B3); (d) atomic-replace evidence; (e)
   create the receipt failure-atomically: write a temp **outside** `receipts/` on
   the same filesystem, fsync it, `os.link` it to the final name (atomic create,
   fails closed if present), fsync the dir, unlink the temp; (f) revalidate
   layout + receipt. On any exception in (d)–(f): unlink only this invocation's
   receipt if present, restore evidence to the previous bytes, re-raise."

5. **Risks and recovery — precise crash limit (replace "failure-atomic").**
   "Receipt content is atomic (never partial at the final name; D1). Evidence and
   receipt are two files and are **not** cross-file atomic; the crash window is
   made retry-safe by `destination_before` refusal, not by atomicity (B2/B4). A
   crash between `link` and temp-`unlink` leaves the final receipt complete but
   with `nlink 2` plus a temp residue (D2) — both detectable (the `nlink != 1`
   and closed-set layout checks) and reclaimable by a stale-temp sweep, not
   auto-repaired. Claim byte-equality/freshness at import only, never
   cryptographic authorship."

6. **Steps — `verify-receipts` subcommand.** "Add `verify-receipts` (live
   `copilot-evidence.md` SHA-256 vs the latest receipt's `candidate_sha256`,
   reciprocal preferred) and call it from the ready-phase gate (D3). Extend
   `digests` to enumerate the closed `receipts/` set for schema-2 sessions (D4).
   Detection only; neither restores bytes nor proves authorship — pair with the
   existing out-of-session seal and a recoverable preimage."

7. **Steps / Risks — driver-window seal discipline (from point 5).** "Freeze all
   driver-owned Markdown, including `driver-evidence.md`, **before** any co-pilot
   window opens; take and store the `digests` seal before the window and compare
   after, with **no** driver-owned write in between. Make driver evidence
   authoring symmetric — author it in the driver sandbox and import it — so the
   live file is a frozen import target, not edited in place during a window. When
   a deviation is reported, **stage its before/after manifest as an artifact** so
   the blinded co-pilot can verify it; a deviation claim without a staged
   manifest is accepted only for the self-evidently-changed file. Add a focused
   test asserting the reciprocal window refuses to open unless the pre-window
   seal is recorded and `driver-evidence.md` is heading-complete."
