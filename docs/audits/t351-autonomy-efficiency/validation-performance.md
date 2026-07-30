# T-351 validation performance

## Selection

`harness validate` classifies every changed path through
`tests/validation-impact.tsv`:

- R0 documentation/ledger changes run `git diff --check` plus the named
  contract fixture;
- R1 routed prose/skill changes run small budget and safety-gate fixtures;
- R2 ordinary mapped components run their owning focused suite;
- R3 workflow, policy, selector, validator, manifest, safety, lifecycle,
  credential, cleanup, and unknown changes run the complete phase-one suite.

Clean-tree R0/R1 results may reuse a private content-addressed receipt only when
base, head, tree, changed paths, environment contract, validator/map bytes, and
selected-suite bytes all match. HOME, PATH, and TMPDIR enter as value-free
hashes. Cache lookup, test completion, and receipt publication each recheck the
exact clean-tree identity; cached files must match their advertised content
digest. Receipts state that they are owner self-attestation from the same trust
root, not independent CI. R2/R3 and paths containing lifecycle-sensitive
tokens do not reuse cache. Every validator path is R3.

Measured Local wall times before phase-one overlap were:

| Synthetic diff | Tier | Selected work | Wall time |
| --- | --- | --- | ---: |
| docs/ledger | R0 | diff + task-ledger contract | 0.13 s; exact reuse 0.12 s |
| routed Cowork skill before fast routing | R1 | broad Cowork suite | 17.69 s |
| routed Cowork skill after fast routing | R1 | context budget + gate fixtures | 0.31 s |
| mapped terminfo component | R2 | terminfo owning suite | 1.03 s |
| broad/control plane | R3 | complete suite | see below |

These results meet the frozen five-second docs and ten-second skill ceilings.
Unknown and control-plane probes still select R3.

Three newly phase-routed workflow references also moved from unknown/R3 to
their exact owning contract:

| Routed reference | Three wall samples | Median |
| --- | --- | ---: |
| external-user onboarding | 0.29, 0.28, 0.27 s | 0.28 s |
| mirrored-node onboarding | 0.43, 0.41, 0.40 s | 0.41 s |
| reboot recovery | 0.46, 0.57, 0.45 s | 0.46 s |

Their executable scripts, client configuration, and validator tests remain R3.
The same split now protects hardening and personal-Mac client configuration and
validator changes from being mistaken for prose-only work.

## Complete-suite overlap

The clean baseline at immutable commit
`f2ce89ac3ea393cb5a7b882bed1b79fe773974fb` took 114.77 seconds. The integrated
T-351 tree with 89 registered focused suites but unchanged serial orchestration
took 114.54 seconds, showing that new coverage itself did not materially change
wall time.

Inspection showed two isolated blocks: the parallel focused manifest and the
large temporary integration fixture body. They shared no repository writes or
test roots. Phase one now starts the focused runner in the background, executes
the existing integration fixtures, then joins and checks the focused result
before success. The cleanup trap also joins an outstanding runner before
guarded temporary-root cleanup. No test or assertion was removed.

Matched retained measurements:

| Configuration | Wall | User | System | Max RSS |
| --- | ---: | ---: | ---: | ---: |
| serial, 8 focused workers | 114.54 s | 150.49 s | 159.74 s | 627,924 KiB |
| overlap, 8 focused workers | 72.84 s | 153.61 s | 166.44 s | 785,416 KiB |
| overlap, explicit 7 workers | 72.01 s | 152.62 s | 162.96 s | 619,568 KiB |
| overlap, auto with one reserved CPU | 72.50 s | 152.19 s | 167.65 s | 784,336 KiB |
| overlap, exact tree after remote routing | 72.21 s | not retained | not retained | 516,124 KiB |
| overlap, exact tree after PIE routing | 72.54 s | 151.62 s | 167.71 s | 511,064 KiB |
| overlap, exact tree after task/hardening routing | 73.57 s | 153.07 s | 165.15 s | 620,456 KiB |
| overlap, 91-suite tree after catalog compatibility | 73.69 s | 152.89 s | 168.49 s | not retained |
| overlap, exact tree after policy/onboarding routing | 87.13 s | 160.98 s | 169.00 s | 503,696 KiB |
| overlap plus concurrent ShellCheck, matched candidate median | 65.51 s | approximately unchanged | approximately unchanged | variable |
| exact integrated tree after ShellCheck overlap | 67.19 s | 161.23 s | 165.12 s | 521,212 KiB |
| exact integrated tree after longest-first admission | 56.54 s | 159.22 s | 162.75 s | 516,220 KiB |

The retained automatic route sees eight affinity-visible CPUs and gives seven
to focused suites while integration proceeds. Explicit or legacy worker counts
remain exact and reserve zero. Legacy, explicit one-worker, and automatic
one/two-CPU routes run the focused and ShellCheck gates without integration
overlap, avoiding low-core oversubscription; higher-core automatic behavior is
unchanged. The repeated automatic result is 36.7% faster
than the integrated serial tree and 36.8% faster than the original baseline.
Peak RSS varied substantially between matched runs, so no memory reduction is
claimed; all values remained near the original baseline run's 744,832 KiB.
All exact-tree post-routing runs passed every then-registered suite; the latest
tree contains 91 suites. Only wall time and maximum RSS were requested from the
remote-routing invocation, and maximum RSS was not requested from the latest
catalog-compatibility run, so unavailable values are not inferred.

In the latest run every focused suite completed within 44.07 seconds while the
integration body set the 87.13-second wall time. That one sample is evidence
for where to profile next, not evidence that routing changes caused the
difference from prior 72–74-second samples.

That profile showed the unchanged ShellCheck gate taking about 48 seconds
before the integration body began. A retained two-file change now starts
ShellCheck beside the already independent focused runner, executes the
unchanged integration body, and explicitly joins both gates before success or
guarded temporary-root cleanup. Three matched baseline runs took 76.38, 76.02,
and 80.38 seconds (median 76.38); three candidates took 62.98, 68.54, and 65.51
seconds (median 65.51), a 14.2% wall reduction. All six passed all 91 suites.
POSIX syntax, ShellCheck, focused-runner, source-contract, and diff checks also
passed. No assertion or suite was removed.

CPU time was approximately unchanged and RSS varied too much for a memory
claim. As with the focused runner, a background ShellCheck failure can be
reported only after the independent integration body finishes, but its
diagnostic and nonzero status cannot be lost or converted into success. Each
side reused one exact source tree across its three runs, with only the two
intended files differing between sides. The final integrated T-351 tree still
requires one complete run after the last evidence bytes settle and before
publication. A subsequent clean integrated checkpoint passed all 91 suites in
67.19 seconds with the resource values shown above.

The focused/runtime contracts enforce one canonical focused-runner invocation,
high-core background starts and joins, low-core serialization, one-CPU
automatic reserve, and failure propagation. A background-gate failure may be
reported after the independent integration body finishes, but it can never be
lost or converted into success. Ordinary development normally runs the owning
R0–R2 route, so this delayed R3 failure tradeoff affects only broad/final
validation.

## Gate contention and isolated temporary roots

A later native component profile measured ShellCheck alone at 35.80 seconds.
An attempted `ptrace` profile was stopped and discarded because LeakSanitizer
correctly refuses to execute while traced; no timing from that run was
retained. An initial standalone focused run was also discarded because it
inherited the managed process's live `HARNESS_ROOT`; phase one correctly clears
that variable. With the exact production environment contract, three unchanged
seven-worker focused samples took 50.16, 49.68, and 50.30 seconds. On a clean
detached tree, a complete six-worker sample passed in 60.42 seconds, while the
automatic seven-worker route passed in 57.67 seconds. This does not support
reducing the automatic worker count, so the one-CPU reserve remains.

The first automatic sample used a deliberately long isolated `TMPDIR` and
failed only the AL socket fixture. Repeating that suite alone under the same
path reproduced the failure, while three concurrent instances under short,
independent roots all passed. The cause was deterministic: the longest
filesystem-backed Unix-domain socket name exceeded Linux's 107-byte pathname
limit, so Python could not bind it and the test reported a misleading
five-second readiness timeout. The fixture now retains the caller's canonical
`TMPDIR` whenever the longest projected socket fits in bytes and otherwise
creates its unique guarded root directly under canonical `/tmp`. Cheap ASCII
and multibyte self-checks cover the selection. This changes no product timeout
or assertion and prevents isolated long-root validation from requiring a
false-failure rerun.

The focused runner formerly admitted suites in manifest order, which delayed
the longest personal-macOS and evaluation fixtures until earlier short suites
had drained. The manifest now accepts an optional bounded integer estimate used
only for admission. The runner preserves original indices, canonical result
order, attributable logs, the same worker cap, and identical pass/fail joins,
but admits higher estimates first. Its focused contract proves priority
admission, canonical output, and malformed-estimate refusal. Three matched
unchanged samples took 50.16, 49.68, and 50.30 seconds (median 50.16); three
longest-first samples took 45.77, 46.14, and 45.86 seconds (median 45.86), an
8.6% reduction. All six passed all 91 suites. Median CPU and peak RSS were
effectively unchanged, so the gain is attributed only to a shorter bounded
queue tail.

The first integrated checkpoint after retaining both the long-root fixture
correction and longest-first admission passed all 91 suites in 56.54 seconds,
with 159.22 seconds user, 162.75 seconds system, and 516,220 KiB maximum RSS.
That is 15.9% below the prior 67.19-second exact-tree checkpoint without
claiming a cross-machine or long-term performance change.

An integration-only disposable profiler passed the unchanged fixture body in
30.44 seconds. On the retained longest-first tree, seven focused workers took
56.54 seconds end to end, six took 56.76, and five took 63.56. The six/seven
difference is noise-sized and five materially regresses, so the portable
automatic policy remains seven on this eight-CPU affinity rather than encoding
a machine-specific constant.

Splitting ShellCheck into two 20-file chunks improved its isolated wall from
35.80 to 18.71 seconds, but did not improve the complete critical path. On
clean exact candidates with six focused workers, single-process ShellCheck
passed in 56.76 seconds / 522,452 KiB, while the two-way candidate passed in
57.67 seconds / 794,776 KiB. The candidate was rejected for 1.6% worse wall and
52.1% higher peak RSS. A first disposable attempt also contained a
profiler-only source edit; the runtime-isolation contract rejected it, and that
run was discarded rather than attributed to ShellCheck.

Launcher and selector startup were already below material thresholds: 200
direct `harness version` invocations took 0.51 seconds, 200 invocations through
the current managed link took 1.02 seconds, and one path-explicit validation
plan took 0.06 seconds. No startup rewrite was retained.

The first map encoded the four current task-record IDs and one archive date.
That made the next valid `docs/tasks/T-N.md` or dated full-TODO archive unknown
and therefore R3 until the map itself was edited. The two namespaces now use
closed numeric/date patterns and still select the ledger contract; arbitrary
`docs/` paths remain documentation-only and unknown non-doc paths remain R3.
A synthetic future task selects cacheable R0 in 0.07 seconds. Router output now
derives its classification and protected-set counts instead of printing a
stale constant. The ledger contract discovers every numbered task record,
requires exact equality with board headings, derives the next free ID from the
descending index, validates every indexed source, and requires every archived
task heading and completed-anchor range to be indexed. That broader check
found one stale T-343 plan pointer; it now names the retained Cowork plan. The
dynamic ledger contract passes all 78 index rows.
Every dated full-board archive must also be a regular indexed source, so a
future archive receives the fast route only after durable lookup covers it.

Untracked files under managed source roots now receive the same whitespace
gate as tracked changes. The repository intentionally ignores unknown
top-level local directories, but an ignored top-level file is detected by name
and rejected without opening potentially private bytes; it becomes valid only
after deliberate source tracking, when an unknown path escalates to R3.
