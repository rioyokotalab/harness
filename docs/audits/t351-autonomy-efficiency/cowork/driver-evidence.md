# Driver evidence

## Sandbox and baseline

Codex used detached sandbox `/tmp/harness-t351-codex-sandbox` at exact
`f2ce89ac3ea393cb5a7b882bed1b79fe773974fb`.  `git status --short --branch`
returned only `## HEAD (no branch)`.  The target worktree and Claude sandbox
were not used for driver experiments.  GitHub queries were read-only; no tmux
pane content, credentials, external settings, or live process state changed.

## Commands and results

1. Context baseline:

   ```text
   wc -l -w AGENTS.md TODO.md SELECTED_SKILLS...
   10876 lines 84100 words total
   ```

   `TODO.md` alone is 9,199 lines / 70,828 words.  All 17 shared skill bodies
   total 1,572 lines / 11,621 words.  Cowork's body plus unconditional protocol
   is 746 lines / 5,926 words before task evidence.

2. Clean validation baseline:

   ```text
   env HARNESS_TEST_JOBS=8 /usr/bin/time -f \
     'DRIVER_BASELINE wall=%e user=%U sys=%S maxrss_kb=%M' \
     tests/test-phase1.sh
   ```

   Exit 0; all 82 manifest suites, guarded-delete tests, and phase-one
   integrations passed; native MPI made its declared non-MPI skip.
   `wall=114.77`, `user=148.98`, `sys=157.84`, `maxrss_kb=744832`.
   The longest unrelated focused fixtures were macOS plan/doctor 35.151 s,
   SSH sync 34.911 s, SSH supervisor 34.513 s, Homebrew 31.083 s, and config
   sync 26.620 s.  Many HPC and static suites completed below 0.1 s.

3. Actions history:

   ```text
   gh run list -R rioyokotalab/REPO --limit 500 --json ...
   ```

   Harness hit the 500-result cap over seven days (277 PR, 221 push);
   Students hit it in less than one day (169 CI PR, 161 CI push, 169 boundary);
   Swallow had 279 over five days (145 PR, 133 push).  Rounded elapsed-run
   lower-bound proxies are 1,425, 505, and 284 minutes respectively.  Harness
   is public; Students and Swallow are private.  The account billing endpoint
   returned HTTP 410 and required unavailable `admin:org`; organization Actions
   policy returned HTTP 403 for the same scope.  Billing state is therefore
   unknown beyond the owner's 90% notification.

4. Ruleset readback:

   ```text
   gh api repos/rioyokotalab/REPO/rulesets/ID
   ```

   All four approval counts are zero.  Existing required contexts are
   GitHub-Actions-bound `portable-phase1` (Harness), `Offline checks` and
   `Enforce student folder` (Students), and `Offline checks` (Swallow).
   Repository-owned job names can remain unchanged, avoiding ruleset writes.

5. Primary-source checks:

   - GitHub Actions billing:
     <https://docs.github.com/en/billing/concepts/product-billing/github-actions>
     says public standard-hosted and self-hosted use is free, while private
     standard-hosted jobs consume included minutes.
   - Job conditions:
     <https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-jobs-with-conditions>
     says a conditionally skipped job reports success and does not block a PR
     even when required.
   - Required-check troubleshooting:
     <https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks>
     distinguishes successful job-level skips from workflow/path skips that
     remain pending.
   - Self-hosted security:
     <https://docs.github.com/en/organizations/managing-organization-settings/disabling-or-limiting-github-actions-for-your-organization>
     warns that persistent self-hosted runners can be compromised by
     pull-request code.

6. Parallel-state observations:

   `tmux list-windows` returned exact metadata
   `0|harness|@87`, `1|students|@99`, `2|swallow|@100`, each with one pane and
   zero attached clients; no pane was read.  Canonical repository paths are
   distinct.  Recovery locks are runtime-name scoped, but one monitor lock and
   one short message-transport lock are intentionally global.  The three
   independent T-351 worktrees coexist at the same baseline.  An attempted
   status probe using historical runtime names returned absent/stopped even
   though tmux metadata is live; that is evidence that ad hoc repeated checks
   can be stale or misleading, not evidence of a session failure.  No recovery
   action followed.

7. Cleanup inventory:

   `harness codex-arg0-housekeeping --plan` reported
   `live=10 eligible=64 young=12 unexpected=0 removed=0`.  This was a read-only
   inventory.  Any eventual removal must use the declared lock-aware plan and
   guarded-delete path.

## Critique

The strongest Actions optimization—skipping all trusted-owner hosted
jobs—preserves required GitHub check names but does not itself prove the local
tests ran.  A committed receipt is also owner-authored and therefore audit
evidence, not third-party attestation.  Under the owner's priority it is still
preferable to hundreds of duplicate jobs, but only if receipts bind the exact
tree and repository policy continues to require local validation.  Untrusted
authors must never satisfy the owner condition.

A self-hosted runner would avoid billed minutes but adds registration,
administration, long-lived service maintenance, and a serious untrusted-code
boundary.  It is not the first-line solution.  The run explosion is caused by
checkpoint publication, duplicate `main` triggers, and Students boundary
execution on owner PRs; remove those multipliers first.

Skill splitting alone cannot solve context cost while the root insists on the
full 70,828-word historical board.  Board compaction is the highest-confidence
token win.  Conversely, moving every safety clause out of root policy would
make routing fragile; always-applicable destructive, credential, dirty-work,
and authority boundaries must remain in the compact core.

The clean full suite's 115-second wall time is acceptable once per coherent
release but wasteful for every docs/skill checkpoint.  Changed-path selection
must fail closed for its own files, unknown paths, lifecycle/safety code, and
broad changes.  Cached success cannot be reused across trees, manifests, or
environment contracts.

No evidence supports redesigning healthy live session lifecycle or replacing
the short global message lock.  Ordinary project work already has distinct
repositories; the safer efficiency change is to prohibit routine work from
touching lifecycle locks and to make validators/receipts/temp roots explicitly
project- and worktree-scoped.

After reading Claude's independent evidence, the driver rechecked its strongest
contrary findings:

- Claude correctly found that tracked
  `docs/github-rulesets/harness-main.json` still says one approval and its test
  asserts that stale value.  This does not falsify the live fact: authenticated
  exact readback of rulesets `19127355`, `19716717`, `19734040`, and `19127356`
  returned zero for every repository.  The discrepancy is a confirmed
  repository bug; update the fixture/test to accepted zero without writing the
  live rulesets.
- Five latest merged PRs in each of Students and Swallow were queried by exact
  head and merge commit through the GitHub Git-commit API.  All ten head-tree
  SHA-1 values exactly equal their merge-tree SHA-1 values.  Together with live
  strict-required-check and squash/rebase-only readback, this supports removing
  redundant post-merge `main` runs while binding local receipts to tree rather
  than commit identity.
- The driver accepts Claude's stricter context and latency thresholds, explicit
  validator-file full escalation, post-compaction cold-resume test, and weekly
  unconditional private hosted run.  The weekly run gives independent drift
  detection at a bounded floor of roughly two rounded hosted job-minutes per
  week across Students and Swallow, instead of hundreds per day.
- The driver accepts that local receipts are auditable self-attestation, not an
  independent trust root.  The PR body/trailer must carry the receipt digest,
  but the claim will remain explicitly narrow.

The first reciprocal native window exited zero but produced a structurally
invalid candidate.  Although the prompt prohibited stage edits, the reviewed
tool list still allowed Bash; after Claude's Write tool was denied, it wrote
the candidate path itself while the native command was already redirecting
stdout to the same file.  The resulting bytes contained a wrapper plus a
duplicated partial evidence body.  Protected digests, staged inputs, and the
live co-pilot evidence remained unchanged, and no import ran.  This is safe to
retry only with changed input: a fresh reciprocal stage/seal and no Bash,
Write, or Edit capability, leaving the native stdout redirection as the sole
candidate writer.

## Proposed plan changes

Retain the benchmark with these implementation refinements:

1. Move the current board byte-for-byte to a tracked searchable archive and
   replace it with a sub-250-line active index linking T-351, T-196, T-303, and
   scheduled gates.
2. Keep an always-read root safety/authority core, add a deterministic task
   router, and split only conditional skill procedures/references.  Do not make
   agents read a protocol branch they will not execute.
3. Add a changed-path validation command with an explicit mapping, high-risk
   full-suite escalation, exact-tree local receipts, and explainable cache
   hits.  Unknowns fail closed to full.
4. Publish branch checkpoints without PRs; open one protected PR per coherent
   task.  Remove duplicate `main` CI triggers.
5. In private repositories, preserve exact required job names but conditionally
   skip their runner allocation only when the immutable PR author is
   `rioyokota`.  Keep hosted offline/boundary jobs unchanged for all other
   authors.  Harness may retain or streamline free public CI independently.
6. Do not register a self-hosted runner or change a ruleset in T-351.  Offer
   that only as a later exact administrative option if repository-only changes
   fail measured sustainability.
7. Validate three isolated repository worktrees concurrently; do not mutate or
   message the live Students/Swallow sessions.
8. Tighten B1 to at least 85% median total reduction, at least 50% in every
   scenario, and at least 30% reduction in non-ledger policy/skill words.
   Tighten docs-only to five seconds and skill-only to ten seconds.
9. Add a weekly unconditional private full check and manual dispatch while
   preserving owner-only conditional skips for ordinary PRs.  Include the
   exact-tree local receipt digest in each owner PR body/trailer.
10. Correct the stale tracked Harness approval fixture from one to the already
    selected live zero; never issue a ruleset write.
