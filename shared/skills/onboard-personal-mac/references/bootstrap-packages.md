# Bootstrap and packages

On a Mac without Codex, begin from the verified public checkout:

```bash
./bin/harness macos-codex-bootstrap --host HOST --apply
```

This bounded bootstrap may install only missing `gh`, `tmux`, a Homebrew
Python providing `tomllib`, pinned `PyYAML` in the dedicated Harness Python
tools virtual environment, and the checksum-pinned official standalone Codex
client in Homebrew's visible bin. It must not edit shell profiles. Refuse an
unexpected existing Python-tools environment and preserve Homebrew Python's
externally managed site-packages. Codex receives the dedicated environment
first on `PATH`. Bootstrap also supplies the declared credential-free private
companion locator and opens the complete onboarding assignment under
`approval_policy=never` and `danger-full-access`. Thereafter invoke
`./bin/harness` from the verified checkout.

For the selected baseline, run
`macos-homebrew --host HOST --plan|--apply`. Permit only the declared formula
allowlist: no casks, services, taps, cleanup, removal, blanket upgrade, or
implicit metadata refresh. Apply only the reviewed dry-run result and never
expand package scope to make an unrelated check pass.
