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

## Deferred website workflow

The website working tree had fresh unrelated ledger edits, so T-194 did not
take over or modify it. Once its driver commits and publishes those edits, add
`.github/workflows/ci.yml` there with the same read-only token, immutable
checkout commit, `ubuntu-24.04`, no secrets, no deployment, and a unique job
name such as `website-offline-ci`. Its steps should be:

1. `python3 tools/security-check.py` (without `--live`).
2. `python3 tools/supply-chain-check.py` (without `--online`).
3. `npm ci --ignore-scripts` using the committed lockfile.
4. `npm run test:browser:install` for the lockfile-selected Playwright browser.
5. `npm test`; the browser test itself must make no live-site or deployment
   request.
6. `python3 tools/task-metrics.py validate` only if the workflow does not
   create or rewrite ledger telemetry.

Browser setup needs a version-selected download, so it is not an offline step;
the checks after setup are credential-free and local. Do not use
`pull_request_target`, upload repository contents as artifacts, restore a
mutable dependency cache, or invoke `publish.sh`, `deploy.sh`, SSH, or lftp.

## Owner-side merge-control proposal

No GitHub setting was changed. After `portable-phase1` has succeeded on the
repository, configure a `main` branch rule with:

- pull requests required, one non-author approval, stale approvals dismissed,
  and conversation resolution required;
- required status check `portable-phase1` from GitHub Actions, with the branch
  required to be up to date;
- force pushes and branch deletion disabled, linear history required, and
  administrator bypass disabled;
- no required deployment and no write-capable workflow token.

For the website, require its distinct `website-offline-ci` only after that
workflow has completed successfully at least once. GitHub notes that a check
must have succeeded recently before it can be selected, and duplicate job
names across workflows can make required checks ambiguous. Relevant official
documentation:

- <https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches>
- <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks>

Rollback is to disable the branch rule or remove only the named required check;
the committed workflow remains a read-only signal and can be reverted with a
normal Git revert. This proposal intentionally does not call the GitHub API or
change repository settings.
