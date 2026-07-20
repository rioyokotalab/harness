# Co-pilot evidence

Independent Claude co-pilot pass. I read only `charter.md` and `plan.md` from the
exchange directory before this pass; I did not read `driver-evidence.md` or any
other driver-owned file. Applying the `codex-claude-cowork` skill's independent
evidence pass (I am the co-pilot; I exercised plan steps in my own sandbox and
own only this file).

## Sandbox and baseline

- Sandbox (mine): `/tmp/harness-t283-round1-claude`, a detached no-hardlink clone.
- Baseline commit verified: `git rev-parse HEAD` = `35ed1db478df4f15471fced4dfc1279f678e462d`
  — matches the charter baseline exactly (`clone_verify_matches_baseline=yes`).
- Working tree clean at start (`git status --porcelain` empty).
- Installed clients (facts): `codex-cli 0.144.6` (`/home/rioyokota/.local/bin/codex`),
  `2.1.207 (Claude Code)` (`/home/rioyokota/.local/bin/claude`). These match the
  versions asserted in `plan.md`.
- Adversarial scratch sessions created under
  `/tmp/harness-t283-round1-claude/cowork-adv.SDo4LU/` (synthetic files only, all
  inside my sandbox). Retained, not deleted, per the no-tree-deletion boundary and
  the skill's "leave a clearly identified sandbox for later safe cleanup" rule.
- No live target, Git ref, credential, network, package, remote, or setting was
  touched. All experiments are local parse/validation checks.

## Commands and results

### Focused test (plan step 2 / acceptance gate) — PASS

```
$ bash tests/test-codex-claude-cowork-skill.sh
Codex-Claude cowork skill tests passed   (EXIT=0)
```

Fact: the focused test passes. Fact (by reading the test, lines 46–51): it only
`grep`s that the mapping *strings* exist in `protocol.md`; it never parses those
flags against the installed `codex`/`claude` CLIs. This is the blind spot that the
experiments below exploit.

### EXP-1 — Reverse native mapping is BROKEN against installed Codex (strongest finding)

`protocol.md` lines 89–94 document the Claude-drives-Codex mapping as:
`codex exec --ephemeral --sandbox workspace-write --ask-for-approval never ...`.

```
$ codex exec --ask-for-approval          # parse-only probe, no execution
error: unexpected argument '--ask-for-approval' found
  tip: to pass '--ask-for-approval' as a value, use '-- --ask-for-approval'
exit=2
$ codex exec --help | grep -i ask-for-approval    -> NOT PRESENT
$ codex --help      | grep -i ask-for-approval     -> "-a, --ask-for-approval <APPROVAL_POLICY>"
```

Fact: in Codex 0.144.6, `--ask-for-approval` is a **top-level `codex`** option, NOT a
`codex exec` subcommand option. The documented reverse mapping therefore fails at
clap argument parsing (exit 2) before any agent runs. Fact: `codex exec --help`
header reads "Run Codex non-interactively", and all other tokens in the mapping DO
exist on `exec` (`-s/--sandbox workspace-write`, `-C/--cd`, `--add-dir`,
`--ephemeral`, `-o/--output-last-message`, `--skip-git-repo-check`).

Inference: exec is already non-interactive, so `--ask-for-approval never` is both
invalid and redundant; removing the token yields a mapping whose every remaining
flag is present in `codex exec --help`.

### EXP-2 — Forward native mapping is VALID (contrast establishes the asymmetry)

```
$ claude --help  ->  --print, --add-dir, --allowedTools/--allowed-tools present;
                     --permission-mode <mode> choices include "dontAsk"
```

Fact: the Codex-drives-Claude mapping (`claude --print --permission-mode dontAsk
--allowedTools ... --add-dir ...`) parses cleanly against Claude 2.1.207; `dontAsk`
is a real choice. Conclusion (fact + fact): the two documented native mappings are
NOT equally usable against the installed clients — the forward one works, the
reverse one errors. This directly contradicts the skill's "Preserve symmetry"
guarantee and its claim to use a "recognizable native CLI mapping" for each product.

### EXP-3 — Validator does NOT reject "unsupported files" (contradicts protocol.md line 29)

`protocol.md` line 29: "The validator rejects missing headings, untouched TODO
markers, role mismatch, skipped phases, backward transitions, and **unsupported
files at completion**."

```
# s2: filled all 7 required files, added UNEXPECTED.md and notes.txt at top level,
# advanced planning->...->complete
$ cowork-session advance s2 complete   -> advanced ... to complete (EXIT=0)
$ cowork-session check   s2            -> valid complete session (CHECK_EXIT=0)
$ ls s2  -> UNEXPECTED.md notes.txt ... all present
```

Fact: two stray top-level files (one named to look like stray notes) passed both
`advance complete` and `check`. Fact (by reading `cowork-session`): `validate_files`
only iterates `REQUIRED_BY_PHASE[phase]`; it never enumerates the directory, so it
is structurally incapable of detecting extra/unsupported files. The reference makes
a claim the tool does not implement.

### EXP-4 — Symlinked exchange file passes validation (documented gap for the focused test)

```
# s1: replaced charter.md with a symlink to an out-of-session file, filled plan.md
$ cowork-session advance s1 discussing  -> advanced ... to discussing (EXIT=0)
```

Fact: the validator follows the symlink (`Path.read_text`) and accepts it. Fact: the
focused test enforces "regular file, not symlink" only for the skill's *own* four
files (`SKILL/PROTOCOL/SESSION/OPENAI`, test lines 35–37), never for the exchange
files. Note: `protocol.md` never actually claims to reject symlinked exchange files,
so this is a real confinement gap but NOT a documented-claim contradiction — see the
`plan.md` critique below.

### EXP-5 — `has_todo` regex misses disguised placeholders (narrows the "rejects untouched TODO markers" claim)

```
# s3 charter contained: "TODO: still need...", "- TODO", "TODOs remain here",
#                        "TODO- placeholder"
$ cowork-session advance s3 discussing  -> advanced ... to discussing (EXIT=0)
```

Fact: the regex `(?m)^\s*TODO(?:\s|$)` only matches a line that is whitespace +
`TODO` + whitespace/end. All four clearly-unresolved placeholders passed. Scope note
(fact): the *template's* standalone `TODO` lines ARE caught, so the intended template
case works; the claim is just broader than the implementation.

### EXP-6 — Claims that DO hold (facts, reported for balance / symmetry evidence)

- `advance codex_session discussing` with unfilled files -> refused
  ("unresolved TODO marker"); `advance ... executing` skipping a phase -> refused
  ("invalid transition"); multi-phase jump -> refused. (Confirmed via focused test + reruns.)
- Role mismatch: editing `state.json` so `driver==copilot` -> `check` refused with
  "state must name different codex and claude roles" (EXIT=1).
- State-machine symmetry: both `--driver codex` and `--driver claude`
  initializations reach `complete` under identical `REQUIRED_BY_PHASE` requirements.
  Fact: the *file/state* layer is genuinely role-symmetric; the asymmetry is entirely
  in the native CLI mapping (EXP-1/EXP-2), not the validator.
- `grep -E "author|owner|by_role" cowork-session` -> none. Ownership ("Neither may
  overwrite the other's evidence") is advisory only. This is consistent with
  `protocol.md` line 30 ("does not prove ... filesystem confinement"), so it is an
  accurate self-description, not a defect.

## Critique

Strongest, evidence-backed criticisms of specific claims:

1. **The reverse native mapping is non-functional (EXP-1).** SKILL.md and
   `protocol.md` promise a "recognizable native CLI mapping" and symmetry, but the
   installed Codex 0.144.6 rejects `codex exec --ask-for-approval never` at parse
   time (exit 2). A Claude driver copy-pasting the documented command gets an
   immediate failure. Because the focused test only greps the string, CI is green
   while the real command is broken — the test provides false assurance.

2. **Asymmetry, not symmetry (EXP-1 + EXP-2).** The forward mapping is valid and the
   reverse is invalid, so the skill's headline "symmetric driver/co-pilot" property
   fails precisely at the client-invocation boundary it most needs to be symmetric.

3. **`protocol.md` overstates the validator (EXP-3).** "rejects ... unsupported files
   at completion" is simply not implemented; the validator cannot see extra files.
   This matters for the charter's "public-repository audit" gate — stray/private
   files could sit in a session and pass `check`.

4. **`plan.md` mis-attributes a claim to the reference.** Plan evidence question 2
   asks whether the validator rejects "symlinked protocol files and unexpected
   top-level files *as the reference claims*." The reference claims neither symlink
   rejection (it never mentions symlinks; EXP-4) — and *does* claim unsupported-file
   rejection but doesn't implement it (EXP-3). The plan should not assert the
   reference claims symlink rejection.

5. **"rejects untouched TODO markers" is narrower than stated (EXP-5).** Fine for the
   exact template, but disguised placeholders pass.

Facts vs inferences: EXP-1..EXP-6 outcomes are observed facts (commands + exit
codes above). "exec is non-interactive so the flag is redundant" and "removing the
token fixes the mapping" are inferences from `codex exec --help` text and the flag
inventory; they must be confirmed by an actual parse-check in the frozen plan, not
assumed.

## Proposed plan changes

Exact, minimal, evidence-linked edits for the driver to reconcile:

1. **Fix the reverse mapping in `references/protocol.md`** (EXP-1). In the
   Claude-drives-Codex block, delete `--ask-for-approval never` (invalid on `codex
   exec`; exec is already non-interactive). If an *explicit* non-interactive approval
   policy is wanted, replace it with a verified config override such as
   `-c approval_policy=never` — but only after a parse-check confirms the key/value on
   0.144.6; otherwise omit it. Keep the reviewed `--sandbox workspace-write`,
   `--cd`, `--add-dir`, `--ephemeral`, `-o/--output-last-message`,
   `--skip-git-repo-check` tokens (all present in `codex exec --help`).

2. **Add an executable mapping check to `tests/test-codex-claude-cowork-skill.sh`**
   so string-grep can no longer pass while the command is broken. Minimal, offline,
   no-execution parse probes: assert `codex exec --help` lists every flag used in the
   reverse mapping (fail if `--ask-for-approval` is used), and assert
   `claude --help` lists `--print`, `--permission-mode`, `--allowedTools`,
   `--add-dir` with `dontAsk` among the permission-mode choices. Gate on
   client presence so the suite still runs where clients are absent.

3. **Correct the "unsupported files" claim (EXP-3).** Either (a) soften
   `protocol.md` line 29 to state the validator checks only *required* files and does
   NOT detect extra/unsupported files, or (b) implement an actual extra-file check in
   `validate_files` (enumerate the directory, reject names outside `TEMPLATES` plus
   `state.json`) and add a test. Prefer (a) as the minimal reversible edit unless the
   public-repo-audit gate needs enforcement.

4. **Rewrite `plan.md` evidence question 2** to match reality: separately ask
   (a) "does the validator detect unexpected top-level files? — reference claims yes,
   observed no (EXP-3)" and (b) "does it follow symlinked exchange files? — reference
   makes no claim; observed it does (EXP-4)." Do not assert the reference claims
   symlink rejection.

5. **Narrow the TODO claim (EXP-5), optional/low-priority.** Either tighten
   `has_todo` (e.g. also flag `^\s*TODO\b`) or reword the reference to "rejects the
   standalone template `TODO` placeholder" so the claim matches behavior.

Reconciliation guidance: items 1 and 2 are the load-bearing, reproducible defects
(matched-baseline observed results) and should be accepted; items 3–5 are
lower-severity accuracy fixes. EXP-4 (symlink) should be preserved as an unresolved
confinement gap rather than asserted as a contradicted claim.

---
Completion status: Independent co-pilot pass complete — reverse Codex mapping
`--ask-for-approval never` fails to parse on installed codex 0.144.6 (exit 2);
forward Claude mapping valid; validator does not detect unsupported files; evidence
written to copilot-evidence.md.

## Reciprocal critique

I read `driver-evidence.md` and re-read this file. There is no conflicting result
to arbitrate: the driver independently reproduced EXP-3 (unsupported files) and
EXP-4 (symlink), and I now reproduce and accept the driver's two distinct
additions. All new probes below are matched to the same baseline `35ed1db` in my
own sandbox `/tmp/harness-t283-round1-claude`; no source was edited (working tree
clean), scratch retained under `cowork-recrit.eM7sSe/`.

### RC-1 — Codex fix `codex --ask-for-approval never exec …`: ACCEPTED, stronger than my delete-the-flag proposal

The driver observed that moving the option before the subcommand parses. I
reproduced this with help-only probes (no Codex agent starts; `--help` prints and
exits, and — as EXP-1/the driver both show — clap still validates misplaced flags
even with `--help` present, so a `--help`-terminated command is a real parse
check):

```
$ codex --ask-for-approval never exec --help                       -> exit 0  ("Run Codex non-interactively")
$ codex exec --ask-for-approval never --help                       -> exit 2  (unexpected argument '--ask-for-approval')
$ codex --ask-for-approval never exec --sandbox workspace-write \
    --ephemeral --skip-git-repo-check --cd /tmp --add-dir /tmp \
    --output-last-message /tmp/last.txt --help                     -> exit 0  (full reassembled mapping)
$ codex --help | grep ask-for-approval  -> "-a, --ask-for-approval <APPROVAL_POLICY>"  (GLOBAL, possible value: never)
$ codex exec --help | grep -c ask-for-approval  -> 0
```

Fact: `--ask-for-approval` is a top-level `codex` option with `never` a documented
value; `codex exec` does not list it; the global-before-subcommand form and the
full reassembled mapping both parse (exit 0). Assessment (accept): the driver's
reorder is strictly better than my proposed change 1 ("delete `--ask-for-approval
never`" / optionally `-c approval_policy=never`). It keeps the documented
non-prompting boundary *visible in the command* rather than relying silently on
`exec`'s implicit non-interactive default, and it needs no config-key verification.
I withdraw my delete-the-token recommendation and my `-c approval_policy=never`
alternative in favor of the driver's native reorder. The reference's own advice
("if the installed client rejects a documented option … inspect current `--help`
and revise the mapping explicitly") is exactly what this fix does.

### RC-2 — Closed top-level set + real `artifacts/`: ACCEPTED over my softening preference

The driver rejected my proposed change 3 preference (option a: soften
`protocol.md` line 29 and leave the validator unchanged) in favor of a closed
top-level set plus an explicit real `artifacts/` directory, arguing accepting
unknown top-level content weakens exchange provenance. To decide this on evidence
rather than taste, I ran a matched static trace that imports the *real*
`cowork-session` constants (`TEMPLATES`, so `ALLOWED_TOP` = the 8 protocol
markdown files + `state.json` + `artifacts`) and compares the current validator
(the softening path) against a prototype of the driver's plan items 2–3:

```
[clean session]                         CURRENT: ACCEPTS   PROPOSED closed-set: ACCEPTS
[bounded log under artifacts/]          CURRENT: ACCEPTS   PROPOSED closed-set: ACCEPTS
[stray top-level .md]                   CURRENT: ACCEPTS   PROPOSED closed-set: REJECTS (unexpected:UNEXPECTED.md)
[stray top-level notes.txt]             CURRENT: ACCEPTS   PROPOSED closed-set: REJECTS (unexpected:notes.txt)
[symlinked state.json]                  CURRENT: ACCEPTS   PROPOSED closed-set: REJECTS (symlink:state.json)
[artifacts/ is symlink to /tmp]         CURRENT: ACCEPTS   PROPOSED closed-set: REJECTS (symlink:artifacts)
```

Fact: the closed-set design accepts a bounded raw log placed under `artifacts/`
(the raw-log use case in `protocol.md` line 44) while rejecting stray top-level
files, a symlinked `state.json`, and a symlinked `artifacts/`; the current
validator accepts all six. This is a *matched* result on the reference's own
constants, so it outranks my earlier taste-based preference under the
reconciliation ordering. The design is therefore a strict safety superset with no
loss of functionality — it distinguishes itself from mere softening precisely on
the provenance/confinement cases the charter's public-repository-audit gate cares
about. I accept the driver's closed-set + real-`artifacts/` design and withdraw my
"prefer (a) softening" recommendation; softening documents the gap honestly but
does not close it. (My proposed change 4, rewriting `plan.md` evidence question 2,
still stands and is unaffected — it is about wording accuracy, not enforcement.)

### RC-3 — Refinement I contribute: `artifacts/` must itself be a real directory

Fact (from the last probe row): a symlinked `artifacts/` is caught only because
the prototype's no-symlink rule is applied to `artifacts` too. The driver's plan
item 2 names "the session root, `state.json`, and every required protocol Markdown
file" as must-be-regular-file/non-symlink but does **not** explicitly name
`artifacts/`. Inference (well-supported by the probe): if `artifacts/` may be a
symlink while item 1 routes "auxiliary prompts/logs only beneath it," a symlinked
`artifacts/ -> elsewhere` re-opens the exact target-escape the symlink rule closes
for `state.json`. So item 2 must be extended to require `artifacts/` to be a real,
current-user-owned directory (not a symlink). Scope note (fact + accurate
self-description): the check is top-level only; contents *under* `artifacts/`
remain an instructional/review gate, consistent with `protocol.md` line 30's
accurate "does not prove … filesystem confinement" caveat and my EXP-6 finding
that authorship cannot be mechanically proven.

### RC-4 — Minor implementation caveat for the closed-set check (cannot fully resolve here)

The driver's item 3 runs the closed-set check "at every check." `write_json_atomic`
briefly creates a `.state.json.<pid>.tmp` sibling before `os.replace`. In
single-process CLI use this temp file is gone before any check reads the
directory, so it is not a live defect; but a robust implementation should ignore
leading-dot temp files (or restrict the closed set to non-dot entries) so a future
concurrent or interrupted write cannot false-reject. I cannot resolve this without
writing the real enforcement code (out of scope for this critique); I flag it so
the frozen plan's item-4 tests include an interrupted-write case, not only extra
files and symlinks.

### Summary of accept/reject/unresolved

- Accept (matched evidence): driver's Codex arg-reorder fix (RC-1); closed
  top-level set + real `artifacts/` over my softening preference (RC-2); the
  driver's TODO-claim narrowing (agrees with my EXP-5 scope note, no conflict).
- Add: extend the no-symlink requirement to `artifacts/` itself (RC-3).
- Unresolved (flagged, not blocking): dot/temp-file tolerance of the closed-set
  enumeration; belongs in the item-4 adversarial tests (RC-4).
- Reject nothing of the driver's additions; I withdraw my earlier delete-the-flag
  and prefer-softening recommendations in their favor.

Corroborating datum: the v1 session validator false-positived on this very file
because a wrapped line began with an indented `TODO`, matching the broad
`^\s*TODO(?:\s|$)` regex on ordinary prose — an observed false positive that
directly supports the reconciled exact-standalone regex fix from EXP-5.

---
Reciprocal-critique status: complete — accepted the driver's `codex
--ask-for-approval never exec …` reorder (matched help probes, exit 0) and the
closed top-level set + real `artifacts/` design over my softening preference
(matched static trace on the reference's own constants); added that `artifacts/`
must itself be a non-symlink directory; flagged temp-file tolerance as unresolved;
working tree clean, no other exchange or target file modified.
