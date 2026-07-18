# Contributor CI and merge controls

## Implemented harness gate

`.github/workflows/ci.yml` runs on every `main` push and pull request with only
`contents: read`. It uses the official checkout action pinned to the immutable
v6.0.2 commit and disables persisted Git credentials. It has no secrets,
deployment, model calls, remote-node access, scheduler commands, package
installation, or cache writes outside its ephemeral runner.
Checkout fetches complete public history because the evaluation validator
loads its guidance from the experiment's exact immutable baseline revision; a
shallow checkout may not contain that commit. Later live global-guidance
maintenance does not alter the frozen baseline, corpus, or recorded reports.

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

## Active merge controls

Harness ruleset `19127355` and website ruleset `19127356` are active on
`main`. Both require a pull request, conversation resolution, an up-to-date
branch, linear history, and the repository's GitHub Actions check from
integration `15368`. Force pushes and branch deletion are blocked, there is no
bypass actor, and workflows retain read-only token permissions.

The owner later chose zero required approvals so personal work does not depend
on a second account. An author may therefore merge after the required CI check
passes and conversations are resolved; a review remains optional. PR #4 and
PR #5 in the harness repository exercised this zero-approval path successfully.

The exact restore/update payloads are
[`harness-main.json`](github-rulesets/harness-main.json) and
[`website-main.json`](github-rulesets/website-main.json). They match the live
zero-approval policy, use no bypass actor, and allow only squash or rebase
merges. Relevant official documentation:

- <https://docs.github.com/en/rest/repos/rules?apiVersion=2026-03-10>
- <https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets>
- <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks>

Any future update requires an authenticated repository-Administration write.
Validate the returned ruleset identity and active rules immediately, then test
the required CI path with a bounded PR. Rollback is to disable or delete only
the affected ruleset; the committed workflow remains a read-only signal and
can be reverted with a normal Git revert.
