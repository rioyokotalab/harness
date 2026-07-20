# Driver evidence

## Sandbox and baseline

Claude used `/tmp/harness-t283-round2-claude`, a no-hardlink clone detached at
`7df5f7d2bb8b199c51fd87f00d43467c12b8073e`. `git rev-parse HEAD` returned that
commit and `git status --short` was empty, so the clone is the untouched v2
baseline. All probes ran inside the clone or in a throwaway
`/tmp/r2probe-a7n_grc1` scratch tree; the live target was never touched.

## Commands and results

Fact (baseline is green): on the untouched clone the canonical
`quick_validate.py shared/skills/codex-claude-cowork` printed `Skill is valid!`
(exit 0); `tests/test-codex-claude-cowork-skill.sh`, `tests/test-claude-takeover.sh`,
`tests/test-source-contract.sh`, and `tests/test-public-repo-audit.sh` all
passed; `git diff --check` was clean. Round-1 fixes hold.

Fact (F1 — hardlink identity gap): in a throwaway session I ran
`ln -f OUTSIDE/outside.txt SESSION/charter.md` so `charter.md` and an outside
user-owned file share one inode (`ls -li` showed identical inode 8787945 and a
link count of 2). `cowork-session check SESSION` still printed
`valid planning session`. `require_owned_kind` uses `lstat` and checks only
`S_ISREG` plus `st_uid == getuid()`; it never inspects `st_nlink`, so a protocol
file may alias arbitrary user-owned content outside the session. Round 1 closed
symlinks but not hardlinks, which defeat the same "self-contained protocol
entry" goal without ever being a symlink.

Fact (F2 — co-pilot write over-grant / integrity blindness): a fresh session's
driver-owned files were created mode `600` and owned by the current user. An
unrelated same-uid writer (the exact authority the co-pilot receives from
`--sandbox workspace-write --add-dir SESSION_DIR`) overwrote `charter.md` with a
canary; the write succeeded. `cowork-session check` afterward still printed
`valid planning session`, and at `planning` no files are even required. Even at
later phases a clobber that preserves the headings and avoids a standalone
`TODO` line passes. So the co-pilot mechanically can rewrite every driver-owned
file and no validator phase detects it.

Fact (native Codex invocation is sound): `codex --ask-for-approval never exec
--ephemeral --sandbox workspace-write --skip-git-repo-check --cd /tmp --add-dir
/tmp --output-last-message /tmp/x.md --help` exited 0, while
`codex --ask-for-approval never exec --bogusflag-xyz --help` exited 2, proving
`--help` does not mask unknown flags and therefore that `--ephemeral` and
`-o/--output-last-message` genuinely parse. `codex exec --help` documents that
`[PROMPT]` reads from stdin "if `-` is used", so the frozen
`... --output-last-message FILE -` shape with the prompt on stdin is correct.
Round 1's global-before-`exec` `--ask-for-approval` ordering still holds.

Fact (reverse mapping exists): installed Claude `--help` lists `--print`,
`--permission-mode`, `--allowedTools`, `--add-dir`, and the `dontAsk` mode, so
the Codex-drives-Claude mapping parses as written.

Inference (symmetry): `agents/openai.yaml` has no Claude counterpart, but Claude
discovers the skill through `SKILL.md` frontmatter while the OpenAI surface needs
a generated manifest. This is a discovery-mechanism difference, not a
driver/co-pilot role asymmetry; I do not treat it as a defect and recommend
future audits not "balance" it by adding a redundant manifest.

Inference (takeover): the state machine is strictly forward-only, so a flaw
discovered after `ready-for-execution` cannot move the recorded phase back to
`discussing`; the protocol routes such cases to owner review / a new session,
which is acceptable but currently implicit. Low priority.

## Critique

v2's concrete safety claim is that `require_owned_kind` plus the exact top-level
set make each protocol entry a real, self-contained, tamper-evident session
artifact. Two demonstrated facts undercut that: a hardlink aliases outside
content while passing every check (F1), and the co-pilot's own native grant lets
it silently rewrite driver-owned files that the validator cannot re-examine
(F2). Round 1 accurately said authorship "cannot be mechanically proven," but it
never gave the driver an *actionable* integrity step, so the ownership boundary
is neither enforced nor verified. These are the strongest remaining defects; the
native-invocation and symmetry surfaces are, by contrast, already sound.

## Proposed plan changes

1. F1: in `require_owned_kind`, reject any protocol *regular file* whose
   `st_nlink != 1` (state.json and the seven Markdown files). Leave directory
   link counts alone. Add a focused-test probe that hardlinks a protocol file
   and asserts `check` fails.
2. F2: make integrity an actionable, mechanical driver gate. Add a
   `cowork-session digests SESSION_DIR` subcommand that prints a stable
   `sha256  name` manifest of the driver-owned set, and document in `SKILL.md`
   and `protocol.md` that, because `--add-dir SESSION_DIR` grants the co-pilot
   write to the whole exchange directory, the driver must (a) set its owned
   files read-only before each co-pilot invocation and (b) capture `digests`
   before and after and treat any change to a driver-owned file as a stop
   condition. State plainly that the sandbox does not enforce ownership.
3. Add a focused-test assertion that the `digests` subcommand is deterministic
   and that the protocol/SKILL document the read-only + digest-verify gate.
4. Record explicitly (no code change) that the `openai.yaml`-only manifest and
   the forward-only state machine are intended, not defects.

## Reciprocal critique

I read `copilot-evidence.md` after both independent passes. There is no
conflicting result to arbitrate; Codex independently reproduced F1 (identical
inode, link count 2, `check` still `valid`) and F2 (the same-UID overwrite),
which raises my confidence that both are real rather than sandbox artifacts.

I traced Codex's two strongest *additive* claims in my own sandbox rather than
restate my first answer:

- Alias-mutation (accepted, reproduced): after hardlinking `plan.md` to an
  outside file, I rewrote the outside file and the session's `plan.md` showed
  the mutated bytes (`links=2`) while `cowork-session check --phase discussing`
  still printed `valid discussing session`. This strengthens F1 from "aliasing"
  to "undetected mutation through an out-of-session alias," and confirms Codex's
  point that rejecting `st_nlink != 1` closes the alias channel but not the
  same-UID overwrite, which needs a content seal (F2).
- Takeover provenance (accepted, reproduced, upgrades my note): I initialized a
  Claude-driver session, advanced it to `discussing`, and confirmed that
  re-`init` on the same path exits 1 (`session path already exists`) and that
  the helper exposes no `takeover`/`predecessor`/`import`/`resume` operation.
  Codex's distinction — same-role process recovery may resume the existing
  validated session, but cross-product role transfer must start a new planning
  session with explicit predecessor provenance — is more precise and better
  demonstrated than my "forward-only, low priority" framing, so I adopt it.

Convergence on fixes: Codex's "seal-and-verify before granting write, verify
after" is the same mechanism as my `digests` + read-only + before/after compare;
I merge them into one deterministic `digests` subcommand plus the documented
seal/verify gate. I accept adding a minimal `init --predecessor SESSION_DIR`
provenance option for cross-product takeover. I still reject "balancing" the
`openai.yaml` manifest (different discovery mechanisms) and confirm the
native-invocation surface is sound. No blocking disagreement remains.
