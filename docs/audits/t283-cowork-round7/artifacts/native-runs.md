# Native co-pilot runs

Resolved client: `claude` version `2.1.207`.

Both passes used the protocol's recognizable native mapping from the detached
Claude worktree:

```text
claude --print --permission-mode dontAsk \
  --allowedTools 'Bash,Read,Glob,Grep' \
  < STAGE/artifacts/copilot-prompt.md \
  > STAGE/candidate-copilot-evidence.md
```

No bypass option or live-session directory was supplied. Independent and
reciprocal processes exited 0. Protected digests and exact stage/seal SHA-256
values matched their externally retained pre-window values before each import.
The helper imported candidate hashes
`9ce4fa5b6bd2955016d8e4d7d5af0e46d3d0e67f29b49c730c7b94fc490a1459`
(independent) and
`82742111d863bdd7ad38422f22363e310bb3ba43983447104e3e2982e887df03`
(reciprocal), with one closed receipt per pass.
