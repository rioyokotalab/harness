# Round-5 client runs

Both native Claude calls used:

```text
claude --print --permission-mode dontAsk \
  --allowedTools Bash,Read,Write,Edit,Glob,Grep \
  < STAGE/artifacts/copilot-prompt.md \
  > STAGE/candidate-copilot-evidence.md
```

They ran from `/tmp/harness-t283-round5-claude` without a live-session path or
`--add-dir`. Independent exited 0 with candidate/import SHA-256
`3fb964ba4df72b4523a326c5b30e8c35a7784f5fefe71fee7ac09bd4b9cff76e`.
Reciprocal exited 0 with candidate/import/live SHA-256
`b7d6096f1275afd4b9f26c724b300524fcbd2f8c59b5d19cdde0a5bdfc947d6c`.
No retry, timeout, permission weakening, or target edit by Claude occurred.

The pre-change stage manifests were
`618fa4260c3f8980c42b210ddf9e71176c0e455f705bcb26c95c8169723a8138`
(independent) and
`2fce65c62a0a19e4be857ef7688a2a58bcedf8f2afb1dfabbcf22dfbff7c6622`
(reciprocal). These old stage-schema hashes are evidence only; new helper output
prints its schema-2 hash for the external seal.
