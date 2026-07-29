# Co-pilot evidence

## Sandbox and baseline
The observed environment is `/tmp/t342-claude-box/harness`, a git repository on a detached HEAD with a clean tree, tip commit `5276ddf` (merge of PR #409, `codex/t341-archive-retired-swallow`). Tool use is disallowed in this window, so I executed nothing and inspected nothing.

Integrity note, stated plainly rather than papered over: the staged bundle (charter, plan, driver evidence, prior co-pilot evidence) was described as supplied, but its bytes did not reach this context. Everything below critiques the driver's proposed resolution as summarized in the window instructions. Where a status depends on evidence I could not read, I say so instead of pretending verification.

## Commands and results
No commands were run and none are reported; inventing output would poison the evidence chain. In their place, these are the exact reproducible tests whose verbatim output the driver evidence must contain before each case moves from "described" to "verified." Paths may be adjusted to the bundle's real layout; the assertions may not. Placeholders in angle brackets must be replaced with literal values in the driver's run.

Case 1 — Students root mapping:
```
jq -e '.classes | length == 2 and sort == ["<classA>","<classB>"]' students/root-capabilities.json
find students -name manifest.json | wc -l        # expected: 0 (no subpath manifests)
```

Case 2 — schema-2 migration of nonempty schema-1 state:
```
cp fixtures/schema1-nonempty.json /tmp/s1.json
harness migrate --to 2 /tmp/s1.json
jq -e '.schema == 2' /tmp/s1.json
diff <(jq -S '.entries' fixtures/schema1-nonempty.json) <(jq -S '.entries' /tmp/s1.json)
                                                 # expected: no output (entries byte-equivalent)
harness migrate --to 2 fixtures/schema1-corrupt.json; echo "exit=$?"
                                                 # expected: nonzero exit, source file untouched
```

Case 3 — schema-3 gate and legacy validity:
```
test -f cowork/benchmark.md
grep -c '^AGREE ' cowork/benchmark.md            # expected: 2 (driver token and co-pilot token)
harness load fixtures/schema1-session.json       # expected: succeeds under schema-3 code
harness load fixtures/schema2-session.json       # expected: succeeds under schema-3 code
```

Case 4 — model alias plus native receipt:
```
jq -e '.model == "fable" and .effortLevel == "high"' tracked/settings.json
git check-ignore -q <project-settings-receipt-path>; echo "exit=$?"   # expected: 0 (untracked)
jq -e '.resolvedModelId | test("^claude-fable-5")' <project-settings-receipt-path>
```

Case 5 — duration summary:
```
H=<requested hours>
wc -w summary.md                                 # expected: >= max(300, 50 * ceil(H))
grep -c '^- \[T' summary.md                      # expected: exactly ceil(H) time-slice entries
grep '^- \[T' summary.md | grep -vE '(commit [0-9a-f]{7,}|log:|no evidence for this hour)'; echo "exit=$?"
                                                 # expected: exit 1 (no entry lacks an artifact citation or an explicit no-evidence statement)
```

Case 6 — invocation record:
```
grep -n 'invalid' transcripts/claude-invocation-1.md | head -1   # first attempt preserved and labeled invalid
grep -c 'tool_use' transcripts/claude-invocation-2.md            # expected: 0 (corrected run is genuinely no-tools)
```

## Critique
**Case 1 — two-class Students root mapping versus subpath manifests.** Challenge: a single root mapping is atomic and easy to audit, but it silently assumes the class set is closed at exactly two, whereas subpath manifests degrade gracefully if a third class ever appears. The root mapping is acceptable only if the loader asserts closure and errors loudly on an unknown class instead of defaulting. Status: agree with the root mapping; disagree with freezing it without the closure assertion. The narrow owner item is whether the class set is closed at two — the assertion makes the design safe under either answer, so it need not block the freeze.

**Case 2 — schema-2 task-bound migration.** Challenge: "safe handling of nonempty schema-1 state" is the load-bearing phrase, and the summary does not distinguish preserve-verbatim from refuse-and-stop. Silent truncation dressed up as migration is the failure mode to exclude. The acceptable shape is both: byte-preserving migration of well-formed nonempty state (the diff test) and fail-closed behavior with the source untouched on anything unparseable. Status: agree with task-bound schema-2 sessions as a design; the migration behavior is **unresolved** until the driver attaches the preservation and fail-closed outputs, since I could not read the bundle bytes claiming to show them.

**Case 3 — schema-3 cowork gate with legacy sessions valid.** Challenge: "mechanical agreement gate" must mean a check a script runs with zero judgment — two literal `AGREE` tokens in `cowork/benchmark.md` — otherwise it is a vibe check with extra steps. Keeping schema-1/2 sessions valid indefinitely also means schema-3 code carries both legacy readers permanently; that maintenance cost should be stated, not implied. Status: agree, conditional on the gate being the literal two-token grep and both legacy fixtures loading in the evidence.

**Case 4 — tracked alias versus pinned full model ID.** Challenge to the alternative first: pinning a full model ID in tracked config goes stale on every model rotation and adds repo churn with no reproducibility gain, because a tracked file cannot prove what actually ran. The driver's split is the right one — tracked `"model": "fable"` and `"effortLevel": "high"` record intent; the project-settings-only receipt records the resolved full model ID and proves execution. The one hard requirement is that the receipt be tool-emitted (native); a hand-written receipt proves nothing. Status: agree, conditional on the receipt containing a resolved ID with prefix `claude-fable-5` and being untracked, per the tests above.

**Case 5 — duration formula.** Challenge: a word floor of `max(300, 50 * ceil(requested hours))` invites padding, and padding is the opposite of evidence. The formula is tolerable only because the second clause carries the honesty: exactly one time-slice entry per requested hour, each citing a timestamped artifact, and an hour with no artifacts must be recorded as "no evidence for this hour" rather than narrated. Status: agree with the formula as a floor; disagree with any reading in which word count substitutes for artifacts. The unbacked-entry grep must be part of the gate.

**Case 6 — recorded invalid invocation and corrected iteration.** Challenge: the temptation is to drop the invalid first invocation and present only the clean rerun. Keeping both, in order, with the first labeled invalid and the second marked authoritative, is both the honest shape and the useful one — it documents the constraint that tripped the first run. Status: agree, provided both transcripts ship in the frozen bundle and the corrected run demonstrably contains zero tool use.

## Proposed plan changes
Final benchmark revision, safe to freeze:

1. **Students:** single root capability mapping naming exactly the two classes, with a mandatory closed-set assertion; the loader errors on any unknown class. No subpath manifests. Owner item, narrowly scoped: confirm the class set is closed at two. Because the assertion protects either outcome, this confirmation does not block implementation.
2. **Schema 2:** task-bound sessions; migration from nonempty schema-1 state is byte-preserving on entries (diff-verified) and fails closed with the source untouched on unparseable input.
3. **Schema 3:** the cowork gate passes iff `cowork/benchmark.md` contains both literal `AGREE` tokens; schema-1 and schema-2 readers are retained, and both legacy fixtures must load under schema-3 code in the standing test suite.
4. **Model:** tracked config carries only `"model": "fable"` and `"effortLevel": "high"`; the untracked project-settings receipt carries the tool-emitted resolved model ID. No full model ID appears in tracked files.
5. **Duration:** summary length floor of `max(300, 50 * ceil(requested hours))` words; exactly `ceil(requested hours)` time-slice entries, each citing a timestamped artifact or explicitly stating "no evidence for this hour"; the unbacked-entry grep is part of the mechanical gate.
6. **Record:** both the invalid first Claude invocation and the corrected no-tools iteration ship in the bundle, in order, with the corrected run marked authoritative.

Freeze condition: the driver attaches verbatim outputs of every test in "Commands and results." With those attached, case 2 moves from unresolved to agreed, the bundle-transmission gap noted in the baseline is closed, and the revision above is frozen for implementation without further negotiation.
