# T-354 Swallow migration — frozen plan

Frozen 2026-08-01 10:02 JST. Swallow only; Students stays out of scope until
its own precondition and session state allow it.

Source `/mnt/nfs-03/safe/Users/rioyokota/codex-workspaces/swallow` →
destination `/mnt/nfs-03/safe/Users/rioyokota/projects/swallow`.

## Verified starting facts (2026-08-01, read-only)

- Destination is **absent**. Filesystem has 133 TB free; the tree is 28 MB.
- Source is on `sw034-continuation-20260731` at `81ecc2b`; the only dirty
  entry is untracked `.claude/settings.local.json`.
- Source has **16 registered worktrees**: the main root plus 15 under `/tmp`,
  all still present on disk. Their administrative metadata records the current
  common directory, so a root move breaks every one until repaired.
- Ignored-but-real state lives in `.runtime/`: PBS job scripts, review
  transcripts (`sw031-host-generator-final-review-r1..r6`), and validation
  bundles (`sw037-6f364bb`, `sw038-3209315`, `sw038-485d0c4`). A fresh clone
  would **not** carry these; they must be copied.
- Live consumers: tmux `projects:codex` pane `%100` and `projects:claude` pane
  `%110`, both with cwd in the source root.
- `.claude/settings.local.json` embeds the absolute source path twice.

## Path references that must change

| Location | Owner | Note |
| --- | --- | --- |
| `profiles/codex-session-targets.tsv` | Harness | closed target map |
| `profiles/claude-session-targets.tsv` | Harness | closed target map |
| `tests/test-codex-recovery-helper.sh:398` | Harness | fixture |
| `tests/test-claude-takeover.sh:73` | Harness | fixture |
| `~/.claude/CLAUDE.md:12` | **Owner-global** | Claude launch sentinel |
| `~/.codex/AGENTS.md:12` | **Owner-global** | Codex launch sentinel |
| `~/.codex/config.toml:546` | **Owner-global** | `[projects."…"] trust_level` |
| `<repo>/.claude/settings.local.json` | Untracked local | two absolute paths |

The three owner-global files are a separate authority boundary and are **not**
covered by ordinary task authorization. Without them the new root is refused
by both launch sentinels and loses its Codex trust entry, so the migration
cannot complete. The owner has previously instructed that `CLAUDE.md` is not
to be modified, so this plan does not assume permission.

## Ordered steps

1. **Harness change first, published before anything moves.** Update both
   profile TSVs and both test fixtures to the destination path. Run the owning
   suites (`test-codex-targets.sh`, `test-claude-targets` coverage inside
   `test-tmux-claude-monitor.sh`, `test-codex-recovery-helper.sh`,
   `test-claude-takeover.sh`, `test-tmux-codex-monitor.sh`) plus full phase
   one, then publish through protected `main` and fleet-sync. Rollback: revert
   the commit; nothing on disk has moved yet.
2. **Create the destination by copy, never move.** `cp -a` the entire tree so
   tracked files, ignored `.runtime/` evidence, and `.git` all arrive
   together; the source is preserved untouched until acceptance. Verify with a
   recursive checksum comparison, then `git -C <dest> worktree repair` and
   confirm all 16 registrations resolve.
3. **Owner-global sentinel and trust updates** (requires the separate
   authorization above): add the destination to both launch sentinels and add
   the `[projects."…/projects/swallow"] trust_level = "trusted"` entry. Keep
   the old entries in place during the bridge so both roots stay usable.
4. **Bridge-first pane cutover**, per the managed-Codex policy: open a
   provisional window/pane rooted at the destination with a fresh saved root,
   let it reconstruct the Swallow ledger, and accept root, model, runtime, and
   validation there. The existing `%100`/`%110` panes keep running throughout.
5. **Physical phone-visibility confirmation from the owner** for the new
   Swallow session. This gate cannot be automated.
6. **Promote** the accepted pane by rename-only promotion; retire the old pane
   only afterwards. Never retry an ambiguous launch, promotion, or
   acknowledgement.
7. **Retire the source** only after exact zero-reference proof: no process cwd,
   no worktree pointing at it, no sentinel or config entry left. Removal goes
   through `guarded-bulk-delete`, never a raw recursive delete. Remove the old
   sentinel and trust entries in the same reviewed pass.

## Open decision required before step 2

The 15 `/tmp` worktrees are all still on disk. Choose one:

- **Repair** them against the destination (`git worktree repair`), keeping
  every branch and detached head reachable; or
- **Prune** the stale ones first (`git worktree list` review, then
  `git worktree prune` for any the owner confirms are finished), reducing what
  has to be repaired and verified.

`/tmp` is transient storage, so several may already be abandoned, but that is
the owner's call and not inferable from disk state.

## Stop conditions

Any of these stops the migration and returns it to owner review: a checksum
mismatch after copy, a worktree that will not repair, a sentinel or trust edit
that is refused or unauthorized, an ambiguous provisional launch or promotion,
a live process still holding the source at retirement time, or a failing
Harness suite at step 1.
