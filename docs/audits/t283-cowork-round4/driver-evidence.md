# Driver evidence

## Sandbox and baseline

Claude driver, sandbox `/tmp/harness-t283-round4-claude`, a detached no-hardlink
clone at `9fed369bcdfd96c15914683820f6113b6a5bb898` (verified with
`git -C … rev-parse HEAD`). All probes ran against the sandbox copy of
`shared/skills/codex-claude-cowork/scripts/cowork-session` and a prototype
`proto-cowork-session` carrying both candidate fixes. Bounded raw output is in
`artifacts/driver-probe-log.md`. Synthetic sessions were built under
`h1work/`, `h2work/`, and `protowork*/`; the live session was never touched.

## Commands and results

Fact (H1, disclosure): `init pred --driver codex` then
`init succ --driver claude --predecessor pred` writes
`predecessor.path = <absolute pred dir>` into the successor `state.json`.
`stage succ … --mode independent` copies `state.json` verbatim, so the staged
`state.json` and `stage.json` the co-pilot receives both carry that absolute
path. A no-predecessor `init` has no `predecessor` key, isolating the leak to
the predecessor block. In the live round-4 session this path is
`…/docs/audits/t283-cowork-round3`, from which the live round-4 audit path is
trivially inferable — information a blinded co-pilot does not need.

Fact (H2, provenance): with a predecessor whose `state.json` says `complete`
but whose `charter.md` still holds standalone `TODO`s, `check --phase complete`
fails ("charter.md still contains an unresolved TODO marker") but
`init --predecessor` succeeds and snapshots `phase: complete`. So
`predecessor_record` trusts the phase field without validating that phase's
required Markdown, while `check`/`advance` do validate it — a real asymmetry.

Fact (prototype, both fixes, five checks passed): (P1) staged `state.json`
retained the `predecessor` block minus `path`, and grep found no predecessor
path anywhere in the stage; (P2) `import-copilot` succeeded and left live
`state.json` byte-identical, so freshness binding survives the projection;
(P3) a staged `state.json` with a mutated `phase` was rejected
("staged input digest mismatch: state.json") with live `copilot-evidence.md`
unchanged; (P4) `init --predecessor` against the inconsistent predecessor was
rejected and, because rejection precedes `root.mkdir`, no successor directory
was created — failure-atomic; (P5) a legitimately advanced `complete`
predecessor was still accepted.

## Critique

Both round-3 hypotheses reproduce as stated. The disclosure is low-severity
(same-user paths, not credentials) but unnecessary and asymmetric with the
skill's blinding goal, so a bounded projection is proportionate. The provenance
gap is an integrity, not confidentiality, issue: the recorded `state_sha256`
and `phase` are advertised as trustworthy provenance yet can describe a
predecessor that never satisfied that phase. Inference to test against Codex:
the minimal disclosure fix should drop only `predecessor.path` (a blacklist)
rather than whitelist state fields, because freshness detection needs the
mutable `phase`/timestamps to stay in the staged projection; over-whitelisting
would blind the staleness check. Open question for Codex: is dropping only the
known `path` field sufficient given the charter's "any future field" concern,
or is a documented projection contract (drop any value that is an absolute
path) worth the extra complexity?

## Proposed plan changes

1. In `stage_session`/`import_copilot`, stage a deterministic path-free
   projection of `state.json` (`staged_state_bytes`: drop
   `predecessor["path"]`, re-serialize canonically) and bind it by its own
   hash; at import, project the live `state.json` identically before the
   equality/digest comparison so freshness binding is preserved.
2. In `predecessor_record`, call `validate_files(pred_root, pred_state["phase"])`
   after `load_state`, so `init --predecessor` refuses a predecessor whose
   phase-required Markdown is missing/inconsistent, before any successor
   directory is created.
3. Add focused adversarial tests: staged state is path-free and no predecessor
   path appears in the stage; projected round-trip import succeeds and is
   stale-detecting; `init --predecessor` rejects an inconsistent predecessor
   with no successor created and still accepts a valid one.
4. Reject broader changes (whitelisting state fields, hashing whole
   predecessor sessions, removing the predecessor block entirely) unless Codex
   shows the narrow fixes are insufficient.
