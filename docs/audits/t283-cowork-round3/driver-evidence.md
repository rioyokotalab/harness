# Driver evidence

## Sandbox and baseline

Codex used `/tmp/harness-t283-round3-codex`, a no-hardlink detached clone at
`eb36df22821a85cfb3624efb1136c14e528d4857`. A synthetic session and stage were
created only inside that clone. The live session's v3 protected digest manifest
was captured externally before this pass; the live target was not edited.

## Commands and results

Fact: v3's native templates still pass `--add-dir SESSION_DIR` to either
co-pilot, while its own round-2 evidence proves that this authorizes same-UID
overwrites of driver-owned files. `cowork-session digests` detects changed
protected bytes after return but retains only hashes, so it has no bytes from
which to restore an uncommitted overwritten charter, plan, or evidence file.
Calling this detector the “real guarantee” is therefore too broad: it guarantees
post-window comparison only when the external manifest survives, not prevention
or recovery.

Fact: in a synthetic v3 session at `discussing`, the driver copied only
`state.json`, `charter.md`, and `plan.md` into a fresh mode-0700 stage inside the
co-pilot sandbox, copied the evidence template to
`candidate-copilot-evidence.md`, and replaced its standalone TODOs with
synthetic output. The session's complete protected digest manifest was
byte-identical before and after the staged work. Driver-side atomic import of
the candidate into only `copilot-evidence.md` left the session valid and yielded
candidate SHA-256
`9ce0a93a20a00fa3db542ecef567e55098cc63a9a10f99455d3f46f49dea4858`.

Inference: staged exchange materially reduces accidental authority and supplies
recoverable pre-call copies, but the manual prototype is not yet safe enough.
It did not bind the copied inputs to the current session, reject linked or
oversized candidates, constrain the stage layout, prove UTF-8/headings, or
refuse a stale import. A deterministic helper should own those gates.

## Critique

V3 learned the right lesson about same-user permissions but stopped at
detection while retaining the broad write grant that creates the problem. The
skill's role promise (“co-pilot owns one evidence file”) and its native command
actually authorize different scopes (“co-pilot may write the whole session”).
An external hash is useful defense in depth, but it should guard a fallback, not
be the default transport. Conversely, simply removing `--add-dir` without a
validated file handoff would turn a clear protocol into informal copying and
could silently import stale or malformed output.

## Reciprocal critique

Claude's strongest result is accepted: its prototype refusal battery showed a
fresh staged candidate can be imported while stale, hardlinked, symlinked,
oversized, non-UTF-8, TODO-bearing, heading-deficient, and unexpected-layout
cases fail without changing the session. Its `EXDEV` result strengthens the
frozen mechanics: the import temp must be created in the live session directory
before `os.replace`.

One Claude claim needs narrowing. It wrote that staging removes the co-pilot's
“mechanical ability” to touch a protected file because the process cannot name
it. The same evidence says Claude created `/tmp/cp-scratch-*` and
`/tmp/cp-import-proto.py` outside its checkout despite receiving no
`--add-dir`; therefore Claude Code's tool permissions are not an OS filesystem
sandbox, and a same-user process could discover a live path. Staging removes the
explicit live path and normal write workflow, which materially prevents
accidental overwrite, but it is behavioral authority reduction rather than
mechanical confinement. Codex's native `workspace-write` sandbox is stronger,
so the skill must state this product difference instead of claiming identical
enforcement.

I accept the provenance-inversion and reciprocal-integrity caveats. The driver
is authoritative for session inputs, so staged copies may be bound to the
current session by hashes and freshness but cannot independently prove to the
co-pilot that the driver supplied honest content. The protocol should record
the staged input/candidate digests and resolved native command so later review
can trace the bytes without pretending cryptographic authorship.

## Proposed plan changes

1. Add deterministic `stage` and `import-copilot` operations. `stage` creates a
   fresh external real directory containing phase-appropriate immutable input
   copies, an exact manifest of their current session hashes, and a candidate
   evidence template. `import-copilot` revalidates session/stage identity,
   exact layout, unchanged current inputs, bounded UTF-8 candidate structure,
   and atomically changes only `copilot-evidence.md`.
2. Make the native mappings default to the co-pilot sandbox and staged prompt/
   candidate paths, with no live session path or `--add-dir SESSION_DIR`.
3. Require driver review of the candidate before import. Use a new reciprocal
   stage containing both evidence files; the co-pilot returns the complete
   replacement of its owned file.
4. Retain external `digests` only as defense in depth and for an explicitly
   justified direct-write fallback. Describe it as detection, not prevention or
   recovery; preserve stage copies until the discussion phase closes.
5. Test stale/tampered/linked/oversized/malformed candidates, unexpected stage
   entries, failure atomicity, independent and reciprocal modes, and both client
   command shapes.
