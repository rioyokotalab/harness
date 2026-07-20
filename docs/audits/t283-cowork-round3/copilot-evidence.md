# Co-pilot evidence

## Sandbox and baseline

- Sandbox: `/tmp/harness-t283-round3-claude`, detached HEAD
  `eb36df22821a85cfb3624efb1136c14e528d4857` (`git log --oneline -1` =
  `eb36df2 Record guarded cowork sandbox cleanup`; `git rev-parse HEAD` matches
  the charter baseline). Working tree clean throughout (`git status --short`
  empty before writing this file).
- Copied inputs I was given (blinded pass): `cowork-stage-independent/state.json`
  (`phase: discussing`, `driver: codex`, `copilot: claude`, predecessor =
  completed Claude-driver round 2), `charter.md`, `plan.md`, plus `prompt.md`,
  `terminal.out`, and this candidate file. **No** `driver-evidence.md` and **no**
  live-session path were present (confirmed by `ls` + `grep`); the only grep hit
  for "driver-evidence" is prose inside `charter.md`, not an evidence file. I am
  genuinely blinded to driver evidence and reconciliation.
- All experiments ran in throwaway paths **outside** the repo tree
  (`/tmp/cp-scratch-<pid>/…`, `/tmp/cp-import-proto.py`) built with the skill's
  own `scripts/cowork-session`, so nothing here mutates the copied inputs or the
  git tree. No trees were deleted; scratch is left in place for later guarded
  cleanup.

## Commands and results

Tool under test: `shared/skills/codex-claude-cowork/scripts/cowork-session`
(`init`/`check`/`advance`/`digests`) plus a prototype importer
`/tmp/cp-import-proto.py` implementing plan step 3.

1. **Protected set / seal coverage (fact).** `cowork-session digests LIVE` prints
   sha256 for exactly `state.json` + every driver Markdown file, and *excludes*
   `copilot-evidence.md` and `artifacts/`. Matches `PROTECTED_ENTRIES` in the
   script (lines 152–154). So the seal covers what the co-pilot must not change.

2. **v3 seal = detection, not recovery (fact).** Sealed a `planning` session to
   `seal-before.txt` *outside* the session dir, then simulated a same-UID
   co-pilot overwriting `plan.md` (the round-2 `--add-dir SESSION_DIR` vector).
   Re-running `digests` and `diff` flagged the change (`*** SEAL DIFF DETECTED
   ***`). But the seal stores only a hash, not the pre-image, so the original
   uncommitted bytes are **unrecoverable** from the seal alone. Confirms plan's
   "detects … but does not prevent or recover overwritten uncommitted bytes."

3. **Authority reduction is real (fact).** This entire pass produced complete,
   importable co-pilot evidence with access to only the copied bundle and a
   local candidate output — never a session path or a `--add-dir SESSION_DIR`
   grant. The staged model therefore removes the co-pilot's *mechanical* ability
   to touch any protected file: it cannot overwrite what it cannot name.

4. **Prototype staged importer + refusal battery (fact).** Built a driver-side
   importer that, against a driver-held stage bundle
   (`{state.json,charter.md,plan.md,MANIFEST.sha256}`), checks: stage shape,
   staged-input freshness vs. the *current live* session, candidate
   symlink/hardlink/uid, size bound (64 KiB), UTF-8, required headings, and
   standalone `TODO`; then atomically replaces **only** `copilot-evidence.md`
   via a temp file created inside the live dir + `os.replace`.
   - Valid candidate: imported; `cowork-session digests` before/after showed
     **all protected entries unchanged** (only the co-pilot file moved), and
     `cowork-session check --phase discussing` still passed.
   - Every failure case returned rc=3 and left the live session **byte-identical**
     (protected digests *and* `copilot-evidence.md` sha unchanged):
     `B2 stale-input` (live `plan.md` edited after staging), `B3 hardlink`
     (nlink=2), `B4 symlink`, `B5 TODO-remaining`, `B5 missing-heading`,
     `B6 oversized` (70000 B), `B7 non-UTF8` (0xff), `B8 unexpected-stage`
     (extra `extra.txt`). After the whole battery `check` still reported a valid
     `discussing` session.

5. **Atomicity depends on same-filesystem temp (fact).** `os.replace` of a temp
   created on a *different* filesystem into the live dir raised `OSError errno=18
   (EXDEV)`. So a naive importer that stages its temp beside the (possibly
   other-fs) stage bundle can fail non-atomically; the temp must be created
   inside the live session dir. My prototype does this; the plan does not yet
   say so.

## Critique

Strongest plan claim (its load-bearing thesis): staging *"can eliminate the
normal need for a session write grant while retaining file-mediated
discussion … authority reduction."*

- **Accept, with scope.** Experiment 3–4 confirm the co-pilot's write grant to
  the session is genuinely removable and the round-2 overwrite vector is closed
  *mechanically*, not just detected. This is a real blast-radius reduction, not
  rebranding.
- **But it shifts trust rather than removing it.** (a) The driver still writes
  the co-pilot's bytes into the session, so authority is *centralized in the
  driver*, not eliminated. (b) **Provenance inversion:** because the co-pilot can
  no longer read the true live inputs, it must trust driver-supplied copies. The
  freshness check (Exp. 4) binds *import-time* context — it refuses if live
  inputs advanced — but it cannot prove the candidate prose was *generated from*
  the real inputs; prose is unconstrained. So "blinded independent evidence"
  survives, yet "the co-pilot verified it read the real charter/plan" is weaker
  than under direct read. This is a genuine trade, not a strict win, and the
  plan states it as a near-unqualified benefit.
- **Asymmetry gap.** Plan step 5 says to "repeat staging for reciprocal
  critique," but specifies freshness/atomicity only for the co-pilot→driver
  *import*. The driver→co-pilot re-staging of `driver-evidence.md` for round 2
  has no integrity contract, so the co-pilot cannot confirm the driver evidence
  it critiques is the real, current one.
- **Claim I could not fully test (limitation).** "Both client mappings remain
  usable without `--add-dir SESSION_DIR`": I could not exec the `claude`/`codex`
  CLIs in this blinded single model call, so CLI usability is an *inference* from
  the mapping (replace `--add-dir SESSION_DIR` with `--add-dir COPILOT_SANDBOX`),
  supported only by the fact that this pass itself needed no session grant.

## Reciprocal critique

Reciprocal sandbox: same `/tmp/harness-t283-round3-claude` clone, baseline
`eb36df2…`, tree clean. Unlike the blinded independent pass, this pass received
**both** evidence files (`driver-evidence.md` is now present in the bundle). New
traces ran in `/tmp/cp-recip-<pid>/…`; no tree deleted, no copied input changed.

**Driver's strongest correction — ACCEPTED; my "mechanical" was wrong for
Claude Code.** The driver notes that my Exp. 3 wording ("removes the co-pilot's
*mechanical* ability to touch any protected file … it cannot overwrite what it
cannot name") is contradicted by my own evidence that I created
`/tmp/cp-scratch-*` and `/tmp/cp-import-proto.py` outside the checkout with no
`--add-dir`. That is correct, and I reproduced it here:

- Fact (Test A, `mkdir`/`echo` under `/tmp/cp-recip-$$`): this reciprocal Claude
  process, via Bash and with **no `--add-dir` to any session**, wrote a file
  outside the git work tree (rc=0). `git status --short` stayed empty only
  because the path lies outside the tree, not because the write was blocked.
- Trace: `--add-dir` / `--permission-mode` govern the Read/Edit/Write
  file-permission surface *inside the agent* — a tool-permission layer, not a
  kernel sandbox. When Bash is in `--allowedTools`, the co-pilot's real write
  reach is **not bounded by `--add-dir` at all**: it can (a) discover names
  (`ls /tmp`, neighbouring checkouts, `git rev-parse`) and (b) write to any
  UID-writable path. Absence of disclosure ≠ inability to reach. So removing
  `--add-dir SESSION_DIR` withholds the explicit live path and the frictionless
  Write/Edit channel — real **accidental-write / authority reduction plus
  behavioral policy**, exactly as the driver states — but it is *not* mechanical
  confinement for Claude Code. I retract "mechanical" as applied to Claude.

**Product difference vs Codex — ACCEPTED and sharpened.** `codex exec --sandbox
workspace-write` establishes an OS-enforced sandbox (Linux Landlock+seccomp /
macOS Seatbelt) in which even a shell subprocess cannot write outside the
workspace root plus explicitly declared writable roots. There, dropping
`--add-dir SESSION_DIR` *is* mechanical: a write to the live session fails at the
kernel whether or not the path is discovered. The two mappings are therefore
**not symmetric on this axis**, and the skill's native-mapping section must say
so rather than imply identical enforcement. (Inference: I could not exec either
CLI in this single model call, so the Codex-sandbox behavior is cited from its
documented model, not re-run.)

**Refinement I still hold (partial disagreement with driver's proposal to keep
`digests` "only as defense in depth").** That weighting is right for a *Codex*
co-pilot (kernel-confined, so the seal is genuinely secondary). It is
under-protective for a *Claude* co-pilot: because Claude's confinement is only
behavioral, the driver-held digest seal is the **primary** post-window backstop,
not a fallback. I keep the seal's role **product-dependent**, and add: real
parity for a Claude co-pilot requires wrapping its invocation in an OS/container
sandbox (the protocol reference already contemplates "an OS/container sandbox
around Claude"), which converts behavioral→mechanical. The skill should mandate
that wrapper for the Claude direction *or* explicitly document the residual gap.

**Two-way staged hash/freshness contract — CONVERGED, and confirmed live.**

- Fact (Test C, `ls` of the reciprocal stage): the stage I was actually handed
  contains **no manifest** — `driver-evidence.md` is unbound. So in this very
  round I cannot verify the driver evidence I am critiquing is the current live
  one; I recorded its sha256 (`68b578c6…`) for provenance but cannot check it
  against live. This empirically confirms both my independent "asymmetry gap"
  and the driver's accepted point that staged input/candidate digests must be
  recorded in **both** directions.
- Fact (Test D, `sha256sum -c` on a scratch stage): a stage-time manifest binds
  inputs symmetrically — verification PASSES while a staged `driver-evidence.md`
  is unchanged and FAILS (rc=1) once it advances after staging. The freshness
  check is directionally symmetric; the driver→co-pilot side lacks it today only
  because no manifest is published, not for any technical reason.
- Fact (Test B, `grep` of `add_parser`): today `cowork-session` exposes only
  `init`/`check`/`digests`/`advance` — **no** `stage`, `import`, or freshness
  logic. So the proposed operations are genuinely new and the freshness contract
  currently lives in ad-hoc external prototype code, which is precisely why it
  should become a deterministic subcommand with fixtures. I accept the driver's
  `stage` / `import-copilot` proposal and its EXDEV-derived "temp inside the live
  dir" mechanic.

**Net.** I accept the driver's correction in full on wording and mechanism, and
we converge on: staged exchange as default with no `--add-dir SESSION_DIR`;
deterministic `stage`/`import-copilot` with two-directional recorded digests plus
freshness; and honest documentation of the Claude (behavioral) vs Codex
(mechanical) product difference. The one preserved live disagreement is narrow:
the digest seal's weight is product-dependent — primary backstop for a Claude
co-pilot, secondary for a Codex one — and true Claude parity needs an
OS/container wrapper rather than a claim of equal enforcement.

## Proposed plan changes

1. **Specify atomic-replace mechanics (from Exp. 5):** the importer MUST create
   its temp *inside the live session directory* and `os.replace` onto
   `copilot-evidence.md`; assert same-`st_dev` and fail closed on `EXDEV`. Add
   this to step 3.
2. **Driver-owned stage + single-file return (from Exp. 4):** the stage bundle
   and `MANIFEST.sha256` are produced and held by the *driver*; the importer
   accepts back **only** the one candidate file and refuses any co-pilot-returned
   manifest or unexpected stage entry (the `B8` refusal). Anchor the freshness
   check to the live session, not to the returned bundle.
3. **Make the importer a deterministic subcommand:** fold the Exp. 4 checks
   (shape, freshness, symlink/hardlink/uid, size, UTF-8, headings, TODO,
   atomic replace, post-import `check`) into `cowork-session import` so it is
   testable and identical across runs, instead of ad-hoc driver code. Add the
   refusal battery as fixtures to the phase-1 tests named in the charter.
4. **Close the reciprocal-critique asymmetry (step 5):** define the same
   freshness+integrity contract for the driver→co-pilot direction — the driver
   publishes a hash of the re-staged `driver-evidence.md` so the co-pilot can
   verify it before critiquing (empirically needed: the reciprocal stage in this
   round shipped with no manifest). State explicitly that staging preserves
   blinding but **not** generation-time input fidelity; treat that residual as
   documented same-user behavioral policy, not a mechanical guarantee.
5. **Keep the v3 seal, add real recovery (from Exp. 2), product-weighted:**
   staged import removes the *co-pilot* write vector, but the driver can still
   fat-finger a driver file, so retain the external digest seal for
   driver→session writes — and, because the seal only *detects*, require the
   pre-image be recoverable (commit or copy protected files before the write) so
   recovery, not just detection, exists. Weight the seal by product: it is the
   **primary** backstop for a Claude co-pilot (behavioral confinement) and
   secondary defense-in-depth for a kernel-confined Codex co-pilot.
6. **Record the blinding fact:** the co-pilot pass must assert it received no
   `driver-evidence.md` and no live-session path (as here); make that an
   acceptance check rather than an assumption.
7. **Document the product-enforcement difference (from Test A):** the skill's
   native mapping must state that dropping `--add-dir SESSION_DIR` is mechanical
   confinement for Codex `workspace-write` but only behavioral authority
   reduction for Claude Code, and either mandate an OS/container sandbox around
   the Claude co-pilot for parity or record the residual gap explicitly.
