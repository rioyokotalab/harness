# Contributor CI and merge controls

## Implemented harness gate

`.github/workflows/ci.yml` runs on every `main` push and pull request with only
`contents: read`. It uses the official checkout action pinned to the immutable
v6.0.2 commit and disables persisted Git credentials. It has no secrets,
deployment, model calls, remote-node access, scheduler commands, package
installation, or cache writes outside its ephemeral runner.
Checkout fetches complete public history because the evaluation validator
compares live guidance with its older frozen baseline revision; a shallow
checkout cannot satisfy that invariant.

The unique required-check candidate is `portable-phase1`. It runs the complete
phase-one integration suite except for two explicitly client/site-specific
checks: the native MPI singleton compile/run and the Codex exec-policy smoke.
GitHub's declared Ubuntu 24.04 image includes the required C/C++ compilers,
ShellCheck, rsync, and archive tools but neither an MPI implementation nor the
declared Codex client. The workflow sets `HARNESS_PORTABLE_CI=1`, which prints
each explicit skip. An unset or zero value retains both mandatory native gates
on the managed nodes, and any other value fails. This prevents generic CI from
pretending to validate an HPC MPI stack or local agent policy while preserving
all credential-free portable filesystem and integration regressions.

The security choices follow GitHub's official guidance to grant read-only
default token access and pin actions to a full commit SHA:

- <https://docs.github.com/en/actions/reference/security/secure-use>
- <https://github.com/actions/checkout/releases/tag/v6.0.2>
- <https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2404-Readme.md>

The first complete hosted validation succeeded as
[Harness CI run 29499772796](https://github.com/rioyokotalab/harness/actions/runs/29499772796).

## Implemented website workflow

The website's unrelated driver work completed before T-251 added and published
`.github/workflows/ci.yml`. It uses the same read-only token, immutable checkout
commit, `ubuntu-24.04`, no secrets, and no deployment. Its `Offline checks` job:

1. Fetches the pinned public harness solely for its guarded-delete helper.
2. Installs the pinned `lftp` package used by the local-mirror test.
3. Validates task metrics, Markdown size, standards, security, and supply-chain
   policy without live-site or online-policy checks.
4. Runs `npm ci` from the committed lockfile and installs its locked Chromium
   browser with Playwright.
5. Runs the 38 local browser tests without a deployment request.

Browser setup needs a version-selected download, so it is not an offline step;
the checks after setup are credential-free and local. Do not use
`pull_request_target`, upload repository contents as artifacts, restore a
mutable dependency cache, or invoke `publish.sh`, `deploy.sh`, SSH, or lftp.

## Frozen merge controls

No GitHub setting was changed as of the 2026-07-17 preflight. After
`portable-phase1` and `Offline checks` succeeded from GitHub Actions integration
`15368`, the owner identified `rioyokota2` as the reviewer for PRs authored by
`rioyokota`. Configure each repository's `main` branch with:

- pull requests required, one non-author approval, stale approvals dismissed,
  and conversation resolution required;
- required status check `portable-phase1` from GitHub Actions, with the branch
  required to be up to date;
- force pushes and branch deletion disabled, linear history required, and
  administrator bypass disabled;
- no required deployment and no write-capable workflow token.

The exact REST payloads are
[`harness-main.json`](github-rulesets/harness-main.json) and
[`website-main.json`](github-rulesets/website-main.json). They use no bypass
actor and allow only squash or rebase merges, matching the linear-history rule.
Before activation, the authenticated owner must confirm at least one of those
merge methods is enabled and that `rioyokota2` has Write or Admin permission in
both repositories. The current unauthenticated process cannot see either
private setting. Relevant official documentation:

- <https://docs.github.com/en/rest/repos/rules?apiVersion=2026-03-10>
- <https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets>
- <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks>

Creation requires an authenticated repository-Administration write. Validate
the returned ruleset identity and the public active rules immediately, then use
one `rioyokota` test PR approved by `rioyokota2` per repository. Rollback is to
disable or delete only the newly created ruleset; the committed workflow remains
a read-only signal and can be reverted with a normal Git revert.
