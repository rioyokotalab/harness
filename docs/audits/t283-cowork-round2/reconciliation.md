# Reconciliation

## Evidence accepted

Both clients independently reproduced two v2 safety defects on the `7df5f7d`
baseline. F1: `require_owned_kind` rejects symlinked/foreign-owned protocol
entries but not hardlinks, so a current-user hardlink gives a protocol file an
out-of-session alias; both agents observed identical inode, link count 2, and a
`valid` check, and both further showed that rewriting the outside alias mutates
the in-session file while `check` still passes. F2: driver-owned files are mode
`0600` and the co-pilot native mapping grants `--sandbox workspace-write
--add-dir SESSION_DIR`, so a same-UID co-pilot can overwrite any driver-owned
file with no validator failure; ownership and mode do not establish authorship
or integrity. Codex additionally demonstrated a takeover-provenance gap: the
helper offers no `takeover`/`predecessor`/`import`/`resume` operation, so a
cross-product role transfer cannot resume the recorded phase and must start a
disconnected planning session with no provenance link; the driver reproduced
this. Both agents confirmed the native Codex/Claude invocation surfaces are
sound (documented flags, `-` stdin, and global-before-`exec` ordering all parse)
and that the `openai.yaml`-only manifest is a discovery-mechanism difference,
not a role asymmetry.

## Disagreements and uncertainty

No blocking disagreement remains; the reciprocal pass produced a material
*correction* rather than a conflict. The driver initially proposed setting
driver-owned files read-only before granting co-pilot write. Codex empirically
falsified that as a guarantee: as the same UID in a workspace-write sandbox it
set a file `0400`, then re-`chmod 0600` and overwrote it (SHA-256 changed).
Therefore read-only mode is retained only as an advisory accidental-write
tripwire, and the real guarantee is a driver-held digest manifest that is (a)
computed over every protected entry the co-pilot does not own and (b) stored
**outside** `SESSION_DIR`, since an in-session seal could be rewritten together
with its inputs. Residual, non-blocking uncertainty: authorship still cannot be
mechanically proven, and a co-pilot that both mutates a protected file and
recomputes a same-location seal is defeated only by the external manifest — the
frozen plan and documentation state this limit explicitly.

## Frozen plan

Claude is the only target-writing role. The owner's original T-283 instruction
is the go for exactly these changes, confined to the live skill, protocol,
`scripts/cowork-session`, focused test, round-2 exchange files, and the T-283
ledger:

1. F1 — in `require_owned_kind`, require `st_nlink == 1` for every regular
   protocol file (`state.json` and the seven Markdown files); leave directory
   link counts unchecked; the error names the entry and observed link count.
2. F2 — add a `cowork-session digests SESSION_DIR` subcommand that runs the
   layout/identity checks and then prints a deterministic, sorted
   `sha256␠␠name` manifest of the protected set (every top-level entry the
   co-pilot does not own: `state.json` plus all Markdown except
   `copilot-evidence.md`; `artifacts/` contents are excluded as shared/bounded).
   In `SKILL.md` and `references/protocol.md`, require the driver to capture that
   manifest to a path **outside** `SESSION_DIR` immediately before granting the
   co-pilot session-directory write, to re-run `digests` immediately after the
   native client returns and compare against the external manifest, and to treat
   any change to a protected entry as a stop condition. Document that read-only
   mode is only an advisory tripwire and that the sandbox does not enforce
   ownership.
3. Takeover — add `cowork-session init --predecessor SESSION_DIR`, which records
   the predecessor's canonical path, driver, phase, and validated state digest
   in the new session's `state.json` under a `predecessor` block, while still
   starting the new session at `planning` and inheriting no phase or authority.
   In `references/protocol.md` (and briefly `SKILL.md`), distinguish same-role
   process recovery — which may resume the existing validated session — from
   cross-product role transfer — which must start a new planning session with
   explicit predecessor provenance.
4. Focused test — extend `tests/test-codex-claude-cowork-skill.sh` to prove: a
   hardlinked protocol file is rejected; `digests` is deterministic and its
   output is stable across runs; a protected-file mutation is detected by
   comparing an out-of-session manifest even after the writer re-`chmod`s and
   overwrites the file; `copilot-evidence.md` is excluded from the protected set
   and remains writable; `init --predecessor` yields a `planning` session whose
   `predecessor` block names the prior driver and phase; and same-role re-init on
   an existing path is still refused. Add assertions that `SKILL.md`/`protocol.md`
   document the external-manifest and advisory-read-only points.

Rejected / no change: no edit to the native Codex/Claude mappings, no
`openai.yaml` counterpart, and no reversal of the forward-only state machine.
Read-only-before-write is not adopted as a guarantee, only as documented advice.

## Acceptance gates

The canonical `quick_validate.py`, the revised focused cowork test,
`tests/test-claude-takeover.sh`, `tests/test-source-contract.sh`,
`tests/test-public-repo-audit.sh`, `git diff --check`, and the full
`tests/test-phase1.sh` must pass with no weakened safety boundary. The revised
`cowork-session` must still accept this round-2 exchange directory. The final
diff and ledger must contain no credentials, private values, settings, remote,
or package changes and no non-driver target mutation. Both round sandboxes and
throwaway probe trees are retained for later guarded cleanup.
