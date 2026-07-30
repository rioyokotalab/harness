# T-351 sustainable private Actions transition

## Decision

Keep GitHub-hosted validation for untrusted contributions, but stop allocating a
private runner for an owner-only pull request whose exact tree was validated
locally. Remove duplicate `main` push workflows, retain one unconditional
weekly/manual hosted gate in each private repository, and use one coherent PR
per task instead of opening PRs for ledger-only checkpoints.

Harness remains publicly hosted and independently validates every pull request,
but it also removes its duplicate post-merge `main` run and retains a weekly
plus manual full gate. This does not change the private-minute allowance; it
removes 678 observed public duplicate runs and eliminates needless post-merge
waiting and hosted work.

This is repository-only and required no organization, billing, ruleset, or
approval-count write. It avoids the security and maintenance burden of a
persistent self-hosted runner while preserving independent hosted execution for
untrusted code.

## Measured baseline

The fixed audit window was
`2026-06-30T14:10:07Z`–`2026-07-30T14:10:07Z`.
Dependabot-only activity was separated.

| Repository | Visibility | Runs/jobs observed | Private rounded non-Dependabot job-minutes |
| --- | --- | --- | ---: |
| Harness | public | 576 PR, 678 push, 2 Dependabot; 2,474.8 wall-minutes | 0 |
| Students | private | 525 PR CI, 480 push CI, 525 boundary, 2 conference, 22 Dependabot | 1,543 |
| Swallow | private | 145 PR, 133 push, 1 Dependabot | 278 |
| Website | public | 43 PR, 17 historical push, 2 Dependabot; 258.4 wall-minutes | 0 |

GitHub documents that standard hosted runners are free in public repositories,
whereas private repositories consume plan allowance and then bill overage:
[Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions).
The run audit therefore distinguishes public wall time from the private minute
pool in the owner's notification.

Three trigger corrections alone remove 1,142 of the observed 1,821 private
minutes (62.7%):

- 522 owner-only Students boundary job-minutes;
- 487 duplicate Students post-merge push job-minutes;
- 133 duplicate Swallow post-merge push job-minutes.

The owner-only Offline jobs now skip as well. The historical query did not bind
every PR's author and event sender, so no unsupported retrospective count is
assigned to that additional saving. Operationally, a normal future owner task
allocates zero private runners in either repository; independent weekly runs
cost roughly one rounded job-minute per repository per week.

A post-transition cancellation audit did not reveal another material trigger
lever. GitHub's bounded search returned the latest 1,000 Students runs in the
fixed window: only one pull-request and two push runs were cancelled. Swallow's
complete 285-run result through the transition contained one cancelled
pull-request run. Both current CI workflows already group by pull-request ref
and cancel superseded work; Students' boundary workflow groups by pull-request
number. The 1,000-result Students cap is reported explicitly, so these counts
are not misrepresented as a complete 30-day denominator. Retain the existing
concurrency configuration and do not add complexity for an already bounded
source of spend.

## Implemented state

Students:

- PR #490, merged as
  `80defa6816969b9644ec81c26accc026ae2edb5e`, removed `push`, retained PR,
  weekly (`17 18 * * 6` UTC), and manual events, and skips both private jobs
  only when PR author and event sender are `rioyokota`.
- PR #491, merged as
  `dafb4a3f2963c2535ae9c4a5ecb133b1238b5598`, recorded closeout with both
  required jobs skipped and no post-merge run.
- The exact merged trees matched the reviewed trees. The local gate passed 481
  tests plus 29 subtests.

Swallow:

- PR #136, merged as
  `6a682e00000c54cd13d18b3bd8eb4820b1c8567d`, removed `push`, retained PR,
  weekly (`43 18 * * 6` UTC), and manual events, and skips the private job only
  when both author and sender are the owner.
- PR #137, merged as
  `0e9029b1a8ca60a3c6b906bff0a475df7323e555`, recorded closeout with the
  required job skipped and no post-merge run.
- The exact merged trees matched the reviewed trees, and the complete
  login-safe static suite passed.

Harness:

- Its task branch retains the required `portable-phase1` pull-request job,
  removes the duplicate `main` push trigger, and adds weekly
  (`11 19 * * 6` UTC) plus manual full runs.
- The final task pull request is the live transition check. Its merge must not
  start a push run; the exact merged tree and run list are reconciled before
  closeout.

### Post-transition readback

At 2026-07-31 03:12 JST, Students remained at closeout head `dafb4a3`.
Swallow had independently advanced through PR #139 to
`1f1951d573eef05ce4055c140088d97ca8328382`. Its owner pull-request run
`30557998116` skipped, and that merge produced no push run. Fresh workflow
content in both private repositories still had pull-request, weekly, and
manual triggers, the owner-only job condition, and no `push` trigger. This is
one later workload observation, not a forecast of future consumption.

At 03:51 JST, Harness task head `eba31ff` also had an empty branch run list.
Its pre-PR checkpoint pushes therefore allocated no runner; the one eventual
protected pull request remains the intended live hosted check.

At 05:13 JST, Students had independently advanced through PRs #492 and #493 to
`009de4e1607292b5a5b2c64a41bf6a06f297fd42`. Runs `30577547728`,
`30577547719`, `30577791707`, and `30577791762` show both CI and the
pull-request-target boundary job skipped for those two owner pull requests.
Neither merge allocated a push run. Fresh default-branch workflow bytes still
contain the owner-only job conditions, pull-request plus weekly/manual CI,
pull-request-target boundary enforcement for other authors, and no CI push
trigger. Swallow remained at PR #139 / `1f1951d`; its same workflow invariants
and no-push-run state were unchanged. These are later operational observations,
not independent attestation or a forecast.

At 06:46 JST, Students had independently advanced again to
`610a9ea06afa91e8df6d4b7350142668640af11f`. Its latest four owner pull
requests each produced skipped CI and boundary jobs, with no intervening push
run. Fresh default-branch workflow bytes still retained exact
pull-request/weekly/manual CI, trusted-base `pull_request_target` enforcement
for other authors, read-only default permissions, and the dual owner/actor
skip. Swallow remained at
`1f1951d573eef05ce4055c140088d97ca8328382`; its workflow bytes and
post-transition no-push state were unchanged. This is another bounded live
observation, not a guarantee about future event volume.

GitHub's job-condition syntax supports this event-specific selection:
[job conditions](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-jobs-with-conditions).
A skipped required job reports success, so the existing required context can
remain unchanged:
[required-check behavior](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks).

## Trust and residual risk

The owner records the exact head tree, command, result, platform, and validator
digest in an owner-authored PR. That is same-trust-root self-attestation, not
independent CI. GitHub does not mechanically validate the receipt when the job
is skipped; owner identity and protected-PR review are the trust boundary.
Weekly scheduled runs provide an independent merged-tree drift-detection
opportunity, but GitHub's best-effort scheduler gives no hard seven-day
completion bound. A direct administrator bypass has the same residual.

Mixed or non-owner events still run all hosted checks, including Students'
trusted-base boundary. No untrusted pull-request code runs on a persistent
self-hosted machine; GitHub explicitly warns about self-hosted runner exposure
to untrusted workflows:
[secure use reference](https://docs.github.com/en/actions/reference/security/secure-use).

Rejected alternatives were:

- a persistent self-hosted runner, because it expands credential, persistence,
  and cleanup risk for untrusted code;
- disabling private Actions, because non-owner validation would disappear;
- moving private repositories or artifacts public, because that changes the
  data boundary;
- workflow-level path filtering for a required workflow, because a skipped
  workflow can leave its required check pending;
- using an HPC/login node as a CI daemon, because scheduler, billing, site
  policy, and untrusted-code isolation become operational dependencies.

Account plan, billing-cycle boundary, payment state, budget, and organization
Actions policy remain unknown: available read-only credentials lack
`admin:org`, and no scope expansion was requested. The repository-only
transition is effective without those facts. Reassess only if non-owner volume
alone begins to approach the allowance; at that point ephemeral isolated
runners or a plan change can be compared against measured demand.
