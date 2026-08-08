# Nit-002 essential-test review

## Method

`inventory.tsv` is the row-complete inventory of the current manifest, descended
from the 104-suite protected base `14309ce`; its hashes track the reviewed
working bytes as the nightly changes them. It records the declared group and cost, source size,
assertion density, direct impact-map reachability, static time-coupling tokens,
and referenced repository inputs. Regenerate it with:

```sh
python3 docs/audits/nit002-essential-tests/generate-inventory.py \
  --output docs/audits/nit002-essential-tests/inventory.tsv \
  --owner-gaps docs/audits/nit002-essential-tests/owner-gaps.tsv \
  --time-coupling docs/audits/nit002-essential-tests/time-coupling.tsv
```

`owner-gaps.tsv` is the source-like path inventory, and `time-coupling.tsv`
records each elapsed sleep, poll loop, and deterministic child join with its
line and disposition. This keeps the wait-removal pass reviewable without
mistaking policy prose containing “wait” for an executed command.
`matched-darwin-timings.tsv` records the serial, one-job final pass for every
supplied Home over-ten candidate and each owner introduced by decomposition.

The review treats a test as essential when it is the narrow owner of an
observable contract that can fail because of the changed bytes. A passing
history is neutral evidence: a sole lifecycle or safety invariant is retained,
while duplicate syntax scans, historical one-off acceptance artifacts, and
group-only replays are not kept in ordinary validation merely because they
pass. Process `wait` used to reap an already-signalled child is deterministic
synchronization; elapsed sleeps, bounded polling, timeout-based readiness, and
test-run retries are time coupling and must leave retained tests. Tests of a
product's retry or backoff semantics remain legitimate when their fixture uses
a deterministic clock or event.

## Baseline findings

- The manifest estimates 1,529 serial seconds. Thirty-two suites have estimates
  above ten seconds; twenty exceed twenty seconds and four exceed sixty.
- The 104 entry scripts contain 25,714 source lines; sixteen exceed 500 lines
  and 34 exceed 300. The largest is remote-agent communication at 1,074 lines.
  Size alone is not deletion evidence, but these monoliths mix independently
  repairable contracts and make the current one-suite repair boundary too broad.
- Twenty-one suites have no direct impact rule. They can run only because
  discovery expands a coarse group or final validation expands the whole
  manifest. Those broad-only suites account for 308 estimated serial seconds.
- Conversely, `owner-gaps.tsv` identifies 85 executable, configuration, tool,
  profile, or smoke-source paths with no focused owner. The old selector called
  these “R3” and then ran everything, even though the full manifest did not
  necessarily exercise the path (presentation scripts are one example). An
  explicit owner-gap failure is more accurate than unrelated green tests.
- Final validation ignores the changed-path decision and always selects
  `tests/test-phase1.sh`. Discovery expands every selected owner to its entire
  group. Thus both stages deliberately admit unrelated work.
- Hosted CI still schedules an unconditional weekly full suite. That is not an
  explicit request and conflicts with the frozen objective. Pull requests use
  exact final selection; `workflow_dispatch` is the only full-suite hosted
  entry because choosing that action is itself explicit.
- Across all 653 tracked paths that currently have at least one owner, a
  one-path static simulation selected a mean 1.12 exact suites (median one)
  versus 10.16 suites (median thirteen) after old group expansion. Manifest
  estimates fell from a mean 62.57 to 9.57 seconds per path. A hardening-skill
  reference is the clearest amplification: three exact 4-second owners became
  34 group suites estimated at 204 seconds.
- Replaying the exact 40-path Har-428 integration diff through the selector
  explains the reported 60-suite discovery: seven groups expanded sixteen
  exact owners into sixty suites (manifest estimate 290 versus 678 seconds).
  It also exposes `tests/test-housekeeping-interrupt.sh` as an owner gap that
  the 60 green launches hid. Exact routing alone is therefore necessary but
  insufficient; ShellCheck, integration, housekeeping, and onboarding owners
  must also be narrowed as recorded below.
  Those sixteen owners alone consumed 1,460.492 Home suite-seconds in the
  supplied run; phase-one integration, full-repository ShellCheck, and
  housekeeping accounted for 1,172.630 seconds (80.3%) of that occupancy.
- `tests/test-phase1-integration.sh` is only a five-line wrapper around the
  2,045-line integration body in `tests/test-phase1.sh`. The body repeats shell
  and Python syntax checks plus many transactions already owned by focused
  suites. Its remaining generic apply/rollback/tool/runtime contracts have no
  direct selector owner, so they must be extracted or mapped rather than used
  as justification for replaying every component.
- `tests/test-shellcheck.sh` scans every tracked shell file. Home measured it at
  405.888 seconds under the Har-428 run even when most shell files were not
  changed. ShellCheck must receive only changed shell paths in ordinary and
  final validation; a repository scan belongs only to an explicit full audit.
  The current repository has 233 eligible shell sources; only fourteen were
  present in the exact Har-428 diff, a 94.0% reduction before tool startup.
- Static source review found elapsed sleeps in sixteen focused suites. The
  worst patterns are 30–600 second liveness sleepers, 0.01–0.1 second polling
  loops, fixed simulated route delays, and the development-evaluation rerun of
  a failed infrastructure command. These are fixture design problems rather
  than required validation time.
- Three manifest suites—AL session, agent upgrade, and terminfo—exit success
  immediately on Darwin with a textual `SKIP`. The focused runner records that
  as an ordinary pass, which explains why Home's report claimed no skips.
  Platform applicability must be manifest metadata: incompatible owners are
  reported as deferred to the matching platform and are not launched as green
  no-ops. Partial native branches such as affinity remain in their portable
  owner because the rest of their contract still executes.
- ShellCheck likewise exits zero when its required command is absent, and the
  broad integration body always prints a native-MPI skip. An admitted
  ShellCheck owner must fail clearly when the declared tool is missing; native
  MPI remains a separate explicitly requested environment gate rather than a
  ceremonial line in portable full validation.
- Repeated fixture scaffolding is widespread, especially across the personal
  macOS suites, but repeated setup text is not automatically redundant
  behavioral coverage. Runtime reduction should first remove broad admission,
  replace wall-clock synchronization, and select component cases; shared
  fixture extraction is secondary unless matched measurements show it dominates.
- Frozen row dispositions are 54 retain-focused owners, 28 split/narrow
  owners, fourteen assign-owner-or-retire suites, two changed-path incremental
  scans, five historical default retirements, and one extract-then-retire broad
  integration replay.

`home-har428-timings.tsv` preserves the owner's supplied per-suite timing
evidence for the 60-suite Home discovery. Thirty-one of those 60 suites
exceeded ten seconds under that parallel Mac load, and fifteen exceeded thirty
seconds. Their summed per-suite occupancy was 2,745.043 seconds even though
parallel wall time was 426.488 seconds. This is contention evidence, not a
standalone speed measurement: it identifies candidates to split, while later
before/after claims must use matched admission and platform conditions.
The median Home/manifest ratio was 1.94 and the mean 3.26; onboarding was
15.08× its four-second admission estimate. Manifest estimates therefore cannot
prove the ten-percent task budget. Final estimates are refreshed from matched
standalone measurements after broad contention and elapsed waits are removed;
receipts report actual validation wall time for the final percentage.

The one-job Darwin corrective inventory launched all 32 unresolved candidates
once in 174.280 seconds and ran every candidate. It froze three assertion
defects: a stale exact-owner expectation, an invalid SCP-like query assumption,
and a Homebrew status token that the implementation never emitted. Three green
owners still exceeded ten seconds: guarded deletion at 15.993, Python at
12.389, and config migration apply/rollback at 17.465. Repairs were made as one
batch before any rerun. Guarded deletion became 8.394- and 9.379-second owners;
Python became 3.857- and 5.278-second owners; migration retained its 6.968-second
behavioral plan and a 0.061-second apply/rollback source contract.

The literal `wait` audit separately classifies child-process joins. Checkpoint
race workers and simultaneous message receivers, for
example, are joined after deterministic work and do not retry an observation;
removing those joins would leak children. They remain. By contrast, socket/file
readiness loops and fixed sleeps are replaced with pipes or explicit fixture
events. The only test-command retry is the one-time bubblewrap rerun in
`test-development-evaluation.sh`; that historical suite leaves the default
manifest. Recovery tests that deliberately invoke a product a second time
after an injected failure are separate behavioral scenarios, not flaky-test
retries, and remain only where recovery is the owned contract.

Git history was used as secondary evidence, not encoded into the reproducible
row inventory. Seventy-three of 104 suite files have at least one change whose
subject names a fix, stabilization, determinism, portability, race, failure,
repair, or hardening concern (153 such changes total). Many recent entries are
test-fixture portability repairs rather than product regressions. This supports
the owner's observation that Har-427/428 cost was amplified by moving the test
platform: it argues for deterministic fixtures and narrower admission, not for
retaining every historical scenario forever.
The two Office failures in Har-428 fit that pattern: the Personal lock owner
expired on a timer, and synthetic Git maintenance raced fixture cleanup. Their
underlying concurrent-lock and repository-lifecycle contracts remain useful;
timer-based ownership and ambient maintenance do not.
All admitted suites should receive a test-only Git environment with automatic
maintenance disabled. This removes repeated per-fixture configuration, avoids
the Darwin maintenance-lock race across every synthetic repository, and avoids
paying for background work that no test owns.

## Frozen disposition rules

1. Direct owner, unique changed-byte contract: retain and narrow; if measured
   above ten seconds, split by independently selectable contract.
2. Broad-only historical or documentation assertion: remove from the default
   manifest or give it an exact source owner; never retain it as a full-gate
   passenger.
3. Duplicate broad integration assertion: remove after identifying its focused
   owner. Extract a narrow owner for any unique core transaction first.
4. Real-time sleep, polling, or validation retry: replace with an event, injected
   clock/state, or immediate terminal failure before retaining the test.
5. Unknown changed path: fail selection with an owner-gap diagnostic. It must
   not silently trigger every test and must not silently pass.
6. `--stage final` selects the same exact owners as the changed context. Only an
   explicit `--full` request selects the complete manifest.

## Group cost and admission review

| Group | Suites | Estimated seconds | Broad-only | Over ten seconds |
| --- | ---: | ---: | ---: | ---: |
| agent-sessions | 21 | 177 | 3 | 4 |
| backup-schedule | 1 | 31 | 0 | 1 |
| evaluation | 3 | 27 | 2 | 1 |
| final-integration | 1 | 150 | 1 | 1 |
| fleet-control | 14 | 112 | 2 | 4 |
| housekeeping-safety | 4 | 122 | 1 | 2 |
| hpc-environment | 6 | 13 | 2 | 0 |
| hpc-runtime | 15 | 38 | 6 | 0 |
| macos-agent-config | 2 | 20 | 1 | 1 |
| macos-config | 2 | 83 | 0 | 2 |
| macos-homebrew | 1 | 55 | 0 | 1 |
| macos-inventory | 1 | 35 | 0 | 1 |
| macos-planning | 2 | 142 | 0 | 2 |
| macos-profile | 1 | 25 | 0 | 1 |
| macos-python | 1 | 15 | 0 | 1 |
| macos-shell | 4 | 48 | 0 | 3 |
| macos-ssh-supervisor | 1 | 133 | 0 | 1 |
| macos-ssh-sync | 1 | 140 | 0 | 1 |
| macos-terminal | 2 | 9 | 0 | 0 |
| macos-update | 1 | 22 | 0 | 1 |
| portable-shell | 4 | 63 | 1 | 2 |
| shared-ssh | 2 | 34 | 0 | 2 |
| slack | 1 | 8 | 0 | 0 |
| validation-core | 13 | 27 | 2 | 0 |

The group taxonomy is useful for reporting but not admission. The aggregate
shows why group expansion is disproportionate: one changed SSH-sync component
already has one exact 140-second owner, whereas one validation-core change can
expand to thirteen suites. Final and discovery admission therefore use exact
owners; groups remain descriptive metadata only.

## Broad-only suite decisions

| Suite | Decision | Reason |
| --- | --- | --- |
| `test-shellcheck.sh` | incremental | Scan only changed shell sources by default; retain repository scan for explicit full. |
| `test-phase1-integration.sh` | extract, then retire | Duplicate broad replay; preserve only uniquely owned core transactions as focused cases. |
| `test-skill-catalog-budget.sh` | exact owner | The aggregate catalog size changes only with skill entry files. |
| `test-ssh-agent-profile.sh` | exact owner | Unique fixed-versus-forwarded agent socket contract in `shell/profile.sh`. |
| `test-remote-session.sh` | exact owner | Unique direct/tmux/nested shell lifecycle contract. |
| `test-housekeeping-owner-alias.sh` | split and exact owner | Unique immutable archive-owner fallback, but its single 447-line transaction suite is too coarse. |
| `test-projects-pane-layout.sh` | retire duplicate | Its role/label topology is already asserted by the target-map, tmux-config, and managed-session owners. |
| `test-repository-independence.sh` | incremental | Scan changed publishable files and changed symlinks; reserve repository scan for explicit full. |
| `test-claude-takeover.sh` | exact owner | Unique Codex/Claude installation collision and project-scope boundary. |
| `test-local-mpi-profile.sh` | exact owner | Unique local MPI module activation/failure behavior. |
| `test-agent-upgrade.sh` | exact owner | Unique agent replacement, rollback, and unmanaged-state refusal. |
| `test-client-comparison.sh` | retire default | Repeats evaluation validation/plan surfaces and is a benchmark declaration, not a runtime owner. |
| `test-development-evaluation.sh` | retire default | Historical T-336 benchmark acceptance; contains a prohibited test retry and does not own current `evaluation/` selection. |
| `test-t343-fable-retest.sh` | retire default | Frozen one-off retest and accepted-report hash, not a current capability gate. |
| `test-multinode-mpi-readiness.sh` | exact owner | Unique multi-node job and native launcher contract. |
| `test-shared-executable-visibility.sh` | exact owner | Unique boundary, digest, and symlink rejection contract. |
| `test-hpc-project-intake.sh` | exact owner | Unique schema value-minimization and interview-document contract. |
| `test-llm-hpc-next-actions.sh` | retire default | Asserts statuses in a dated completed audit artifact. |
| `test-pytorch-readiness.sh` | exact owner | Unique single-device job and offline environment declaration. |
| `test-venv-readiness.sh` | exact owner | Unique ordinary offline venv launcher contract, distinct from locked-project readiness. |
| `test-checkpoint-restart.sh` | exact owner | Unique checkpoint format, corruption, restart, and scheduler wrapper contract. |

The exact-owner decisions do not imply group admission: one changed source may
legitimately have two distinct owners only when each asserts a different
observable contract. For example, the broad HPC readiness suite currently
duplicates affinity job assertions already owned by `test-affinity-readiness.sh`;
those duplicate affinity assertions should leave the umbrella suite while the
native affinity owner remains.

## Within- and cross-suite redundancy conclusions

- The phase-one integration body performs repository-wide `sh -n`/AST syntax
  checks before executing its own transactions. Focused suites already execute
  the changed programs and ShellCheck provides syntax analysis for changed
  shell sources. Repeating every syntax check in integration has no distinct
  failure decision and will be removed.
- `test-focused-runner.sh` statically reasserts that ShellCheck and selected
  phase-one wrappers appear in the manifest. Manifest parsing already rejects
  absent/unsafe members and the component owns its own executable contract;
  remove those component-presence assertions from the runner owner.
- Nine suites copy the same regex scan for raw recursive deletion into their
  component assertions. Extend the changed-path shell policy owner to perform
  syntax, ShellCheck, and prohibited-deletion scanning once per changed shell
  source; remove the repeated scans from component suites. The explicit full
  mode scans every shell source once.
- `test-hpc-readiness.sh` repeats the affinity wrapper, scheduler headers,
  source-contract marker, task-count exclusion, and unsafe-cleanup scan that
  `test-affinity-readiness.sh` owns while the latter also compiles and runs the
  native gate. The affinity block in the umbrella suite is redundant.
- `test-task-ledger-routing.sh` repeats the live config/index/active-board/source
  invariants already enforced by `tools/harness-ledgers.py validate`, then adds
  frozen historical task states and one archive hash. Move the missing compact
  board/pointer checks into the canonical ledger validator and retire this
  second live-ledger suite; historical task identities are not a current gate.
- `test-client-comparison.sh`, `test-development-evaluation.sh`, and
  `test-t343-fable-retest.sh` validate frozen experiment plans or reports.
  Current `evaluation/` changes already select `test-evaluation.sh`; historical
  benchmark reproduction remains directly runnable but is not a default gate.
  The existing `^evaluation/` rule falsely assigns all 113 tracked evaluation
  paths to `test-evaluation.sh`, even though that suite does not exercise the
  comparison, development-v2, Fable-retest, or frozen-result implementations.
  Replace it with exact current-runtime/corpus rules and explicit no-default-test
  classifications for frozen experiment material.
- Skill budget and skill behavior suites often read the same routed files but
  make different decisions: bounded prompt size versus mandatory safety text.
  Their shared inputs are not redundant assertions. Catalog-wide enumeration
  is separate but should run only when a skill entry changes.
- The personal-macOS suites duplicate substantial repository and private-bundle
  fixture construction. A line-level comparison found only a small set of
  repeated behavioral assertions, mainly malformed bundle, divergence, and
  collision outcomes. The dominant duplication is setup cost. Retain one
  primitive owner for parsing/classification and remove the same assertion from
  higher-level update/control suites as those suites are divided into cases.
- `libexec/harness-macos-bash-hooks` is currently mapped to both the general
  Bash suite and the dedicated hook suite, although the general suite never
  invokes or asserts the hook command. Remove that false second owner.
- Housekeeping and immutable owner-alias suites both exercise archives, but the
  latter uniquely covers relocated/reconstructed owner identity. It is not
  safe to delete; the correct reduction is independently selectable archive,
  worktree, interruption, and owner-alias cases with one fixture per case.
- Sixty-nine suites invoke `bin/harness` and guarded cleanup. That common
  scaffolding is required isolation, not 69 copies of the dispatcher contract.
  Dispatcher behavior remains owned by `test-source-contract.sh`; component
  suites should avoid reasserting generic routing unless their command surface
  is the changed contract.

## Long-owner decomposition matrix

The following contract axes were inspected in each long suite's actual
assertions and fixtures. An axis became a separate executable owner only when
representative narrowing could not bring the owning suite below ten seconds;
otherwise the retained row protects one essential representative for that
axis without multiplying launches. Owners sharing changed bytes remain exact
selector results, not reasons to admit their descriptive group.

| Existing owner | Independently selectable contracts |
| --- | --- |
| Bash startup unify | analysis; apply/idempotence; linked-worktree rollback |
| Remote agent communication | schema/policy; Codex transport; Claude transport; recovery/attribution |
| Reboot recovery | routed policy; status discovery; recovery execution; readiness classification |
| Fleet health | route classification; bounded scheduling; privacy/output |
| Connection monitor | snapshot; route scheduling; recovery authorization |
| macOS agent session | source/allow-list; initial/idempotent layout; dead/orphan recovery; authentication/launchd |
| Housekeeping | branch/archive; hosted retirement; worktree classes; interruption; exact recovery |
| Housekeeping owner alias | publication; reconstructed owner; immutable-input rejection; generation bridge |
| Personal agent | local/read domains; calendar write; operation lock/OAuth boundary |
| Codex resilient | arguments/state; retry clock/backoff; signal/ownership; remote launch |
| Codex runtime isolation | target selection; immutable install/release; launch; rollover/recovery |
| macOS profile | schema; compatibility; immutable payload; Git/private-owner identity |
| macOS inventory | declaration parsing; native command inventory; value minimization; Darwin metadata |
| macOS plan/doctor | profile/host validation; plan classification; doctor diagnostics; tool/formula decisions |
| macOS control | plan; apply; idempotence; collision/rollback |
| macOS Homebrew | formula policy; plan; apply; rollback/refusal |
| macOS Bash | desired links; apply/idempotence; collision; rollback |
| macOS Bash hooks | hook analysis/apply; owner curation; rollback |
| macOS login shell | plan/apply; profile preservation; rollback |
| Agent config | policy rendering; install; replacement; rollback/collision |
| macOS update | preflight; public/private fast-forward; partial recovery; rollback |
| macOS SSH supervisor | install/state; bind/auth classification; watchdog recovery; signal/rollback |
| macOS Python | policy/plan; install/link; collision/rollback |
| macOS SSH sync | plan; pull; push; atomic failure recovery; per-host finalization |
| macOS config sync | plan; publish; consume; divergence/atomic recovery |
| macOS config migration | v1/v2 classification; apply; collision/rollback |
| SSH config mirror/layout | parsing/plan; atomic apply; agent/remote failure; rollback |
| Restic schedule | declarations; scheduler chains; singleton/missing parent; status/cancel |

The onboarding-project wrapper is a separate measured exception to manifest
estimates: Office observed its 67 tests at 21.097 seconds and Home at 60.333
seconds. Its three existing Python modules—producer ledger, consumer protocol,
and consumer validation—are already natural independent suites; the wrapper's
static skill/scaffold checks form a fourth sub-ten-second contract.

## Reduction checkpoint

After exact ownership, historical retirement, representative-contract
narrowing, and lifecycle splitting, the manifest has 109 independently
selectable entries: seven redundant owners left, ten narrow owner entries were
split out of long Mac, onboarding, Python, and guarded-delete contracts, and two
previously untested source families gained owners. Source volume fell from
25,714 to 18,016 lines and declared serial cost from 1,529 to 496 seconds. No entry is estimated above ten seconds,
no suite is reachable only through a group/full expansion, and no source-like
path is ownerless. Static timing review now finds zero elapsed sleeps, polling
loops, or test retries in retained execution. Its thirteen remaining `wait`
tokens are deterministic child reaps after an exact signal, FIFO, process exit,
or concurrent result—not elapsed readiness checks. The serial Darwin inventory
in `matched-darwin-timings.tsv` measured every supplied Mac-slow candidate and
new split independently; all final rows pass between 0.061 and 9.949 seconds.

## Owner-gap closure evidence

The 85 source-like baseline gaps were bounded rather than arbitrary: 53 were smoke sources
or scheduler wrappers, sixteen were generic core `libexec` commands, eight were
tool/source manifests, five were presentation scripts, and the remaining three
were Dependabot, `install.sh`, and the canonical Bash profile.

- Each smoke source/wrapper now maps to its existing CPU, affinity, MPI,
  checkpoint, PyTorch, debugger, venv, scientific-library, or source-contract
  owner. The formerly broad-only HPC suites are directly reachable.
- The broad phase-one replay is gone. Generic core paths map to narrow existing
  owners; repeated archive and transaction permutations are not default validation.
- Tool/source manifests have a one-second schema owner, while presentation
  builders/verifiers have one syntax-and-entry-point owner. The old full suite
  exercised neither family.
- Dependabot maps to Actions sustainability, `install.sh` to scoped client
  installation/replacement contracts, and the canonical Bash profile to Bash
  startup unification.

The generated owner-gap table is now empty. The selector still reports any
future unknown path exactly and cannot let unrelated green suites hide it.
