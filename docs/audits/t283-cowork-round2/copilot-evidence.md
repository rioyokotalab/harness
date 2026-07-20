# Co-pilot evidence

## Sandbox and baseline

- **Fact:** The writable co-pilot sandbox is
  `/tmp/harness-t283-round2-codex`. `git rev-parse HEAD` returned
  `7df5f7d2bb8b199c51fd87f00d43467c12b8073e`, the charter's immutable
  baseline. `git branch --show-current` returned no branch name, confirming a
  detached checkout, and `git status --short` returned no output, confirming a
  clean starting tree.
- **Fact:** I read only `charter.md`, `plan.md`, and this co-pilot-owned
  evidence file from the exchange directory. I did not read
  `driver-evidence.md`. I did not fetch because the round charter expressly
  prohibits changing Git refs or network state.

## Commands and results

- **Fact — source trace:** `rg -n
  "require_owned_kind|st_nlink|sha|digest|takeover|predecessor|add-dir" ...`
  found type/UID checks in `require_owned_kind`, but no link-count check, digest
  seal, takeover command, or predecessor field. The helper exposes only
  `init`, `check`, and `advance`. Both documented native mappings use
  `--add-dir SESSION_DIR`; the Codex mapping additionally writes an unspecified
  `CODEX_LAST_MESSAGE_FILE`.
- **Fact — hardlink/alias probe:** I initialized
  `.round2-copilot-probe/hardlink-session`, mechanically filled `charter.md`
  and `plan.md`, moved `plan.md` outside the session, and hardlinked it back.
  `stat -c 'inode=%i links=%h uid=%u path=%n'` reported the same inode
  (`8788033` in this run), link count 2, and current UID for both paths.
  `cowork-session check ... --phase discussing` exited 0. I then used an
  in-place binary write through the outside alias to replace one public
  synthetic evidence string; the session path immediately showed the changed
  bytes, retained the same inode/link count, and the same check again exited 0
  with `valid discussing session`. This directly falsifies the concrete v2
  claim that exact-set + symlink/UID checks make every protocol file
  self-contained or tamper-evident.
- **Inference — integrity boundary:** Rejecting `st_nlink != 1` would close the
  demonstrated outside-alias channel for regular protocol files, but not the
  broader same-UID overwrite problem. Content/identity sealing before granting
  another client session access, followed by verification afterward, is needed
  to make unexpected changes detectable.
- **Fact — takeover probe:** I initialized a Claude-driver session, filled its
  planning inputs, and advanced it to `discussing`. Re-running `init` on that
  path with `--driver codex` exited 1 (`session path already exists`). A new
  Codex-driver session initialized successfully but had phase `planning` and no
  `predecessor_session`; the old session remained Claude-driven at
  `discussing`. `cowork-session --help` lists no takeover/import operation.
- **Inference — takeover contract:** Same-role process replacement can follow
  “resume the first unverified action” in the existing session. Cross-product
  role transfer cannot also resume that recorded phase under the current
  helper: it must start a disconnected planning session. The protocol should
  distinguish those cases and define provenance/revalidation for the latter.

## Critique

The strongest demonstrated weakness is that the exchange validates file type
and ownership but not exclusive identity or content integrity across a
co-pilot access window. A current-user hardlink outside the session passed
validation and allowed undetected mutation through the alias; even rejecting
that alias would leave same-UID overwrites detectable only with a seal. This
matters because a later collaborator cannot reliably attribute or trust a
handoff whose supposedly frozen inputs may have changed without evidence.

## Proposed plan changes

1. In `scripts/cowork-session`, require `st_nlink == 1` for every regular
   protocol file during `check` and `advance`, with an error that names the
   offending entry and observed link count.
2. In `scripts/cowork-session`, add a seal-and-verify operation that records
   file identity and content digests for all entries the other client does not
   own; in `shared/skills/codex-claude-cowork/SKILL.md` and
   `references/protocol.md`, require the driver to create that seal immediately
   before granting session-directory write access and verify it immediately
   after the native client returns, stopping on any protected-entry change.
3. In `references/protocol.md`, distinguish same-role process recovery, which
   may resume the existing validated session, from cross-product role transfer,
   which must initialize a new planning session; add a
   `scripts/cowork-session init --predecessor SESSION_DIR` option that records
   the predecessor's canonical identity, driver, phase, and validated state
   digest so the new session has explicit provenance without inheriting its
   phase or authority.
4. In `tests/test-codex-claude-cowork-skill.sh`, add focused regressions proving
   that a hardlinked protocol file is rejected, protected-file mutation fails
   post-access seal verification, owned co-pilot evidence remains writable,
   same-role recovery keeps the session, and cross-product takeover starts at
   `planning` with validated predecessor provenance.

## Reciprocal critique

The two passes converge on the two highest-impact facts. First, a same-UID
hardlink gives an out-of-session alias to a protocol file while the validator
still reports the session valid; rejecting `st_nlink != 1` for regular protocol
files is therefore necessary. Second, the co-pilot's whole-session write grant
lets a same-UID process overwrite driver-owned files without a validator
failure; file ownership and mode `0600` do not establish authorship or
integrity.

I challenged the weakest part of the driver's proposed mitigation: making
driver-owned files read-only before granting write. In this workspace-write
sandbox, as UID 5035, I created a synthetic file, set mode `0400`, and observed
that a direct shell redirection failed with status 1. The same process then ran
`chmod 0600` and overwrote it successfully; SHA-256 changed from
`b505e5f435b60680d0632a516739f2f7dde3d0aa180c58cb26e709127b903280` to
`5fc9f6bacf41aaf73f28e1807d21db8a41616cd045f922c2006bdbb9de919102`.
Thus read-only mode is, at most, an accidental-write tripwire. The actual
guarantee is a driver-held pre-access digest manifest compared after access,
with the expected manifest kept outside `SESSION_DIR` and every path writable
by the co-pilot; an in-session seal could be rewritten along with its inputs.

The driver's native-command parsing evidence is concrete and resolves my
earlier concern about the Codex output-file placement: the documented options
and stdin form parse, so I agree that the native mappings need no change. I
also agree that an OpenAI-only generated discovery manifest is not itself a
role asymmetry when Claude discovers the same skill from `SKILL.md`.

1. **Accept change 1.** The reproduced outside-alias mutation directly
   justifies rejecting link counts other than one on every regular protocol
   file.
2. **Accept change 2 with a correction.** Add deterministic pre/post digests,
   but treat read-only mode as advisory and keep the expected seal outside all
   co-pilot-writable roots.
3. **Accept change 3 with stronger coverage.** Tests should prove detection
   even after the co-pilot re-`chmod`s and overwrites a protected file, and
   should prove the expected seal is not stored in `SESSION_DIR`.
4. **Reject change 4 as bundled.** No `openai.yaml` or native-mapping change is
   needed, but cross-product takeover should not merely be declared an intended
   consequence of a forward-only machine; the driver's later acceptance of a
   new planning session with explicit predecessor provenance is the necessary
   resolution.
