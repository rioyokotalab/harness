# Private companion

After `go`, restore an absent strict private companion from the
repository-declared SSH locator. If the host declaration is absent, create the
baseline-only profile: `macos-cli-v1`, no capability groups, and no extra
formulae. Validate it, then commit and push only inside the private companion
without printing its revision or private facts.

For every authenticated Git or SSH command, require a current-user-owned agent
socket and verify public and private transports independently. Prefer the
already validated SSH Git transport when HTTPS lacks a credential helper. If
GitHub API authentication is required, use native `gh` login and pause only
for its unavoidable owner device/browser step.

Refuse a locator mismatch, dirty or incompatible companion branch, ambiguous
contributor work, or any route that would expose private values publicly.
