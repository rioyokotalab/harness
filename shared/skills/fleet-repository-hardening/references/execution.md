# Protected execution

Prioritize credential exposure, vulnerable runtime dependencies, privileged
workflow injection, absent required CI, and uncontrolled default branches
before efficiency or package freshness.

- Add a focused regression before or with each behavior change.
- Keep Actions permissions read-only by default. Never let a workflow approve
  pull requests unless explicitly required.
- Treat pull-request code as untrusted: never expose secrets or privileged
  self-hosted context to it. Move untrusted event values through environment
  variables instead of interpolating them into shell source.
- Pin third-party Actions by immutable commit.
- For private Actions, skip owner-only hosted jobs only after verifying an
  equivalent protected local gate. Keep mixed, non-owner, and untrusted events
  on isolated hosted checks, and retain scheduled plus manual full validation.
  Never claim savings without run evidence.
- Enable native dependency and secret protection only where the hosting plan
  supports it. For unavailable private-repository secret protection, use a
  credential-free, pinned, reviewed fallback and do not claim provider-wide
  equivalence.
- Never auto-merge dependency updates.
- Require a passing exact CI context before adding it to branch protection.
- Treat an owner-selected required approving-review count of zero as accepted
  policy, not a finding. Never raise it without separate explicit
  authorization for the exact repository and ruleset.
- Preserve stronger repository-specific review rules.
- Apply host changes transactionally and validate one host or route at a time.
- Use only existing narrow non-interactive administrator authority. Otherwise
  stage an exact reviewed helper with impact, rollback, and validation for
  password, root, reboot, TCC, or physical gates.

Fetch immediately before publication and push with an explicit refspec:

```bash
git push origin HEAD:refs/heads/TASK_BRANCH
```

Do not use plain `git push`; `push.default=matching` can publish other local
branches. Never force-push.
