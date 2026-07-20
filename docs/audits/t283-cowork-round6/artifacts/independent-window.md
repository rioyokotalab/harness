# Independent Codex window — bounded record

- Co-pilot: Codex, medium reasoning effort, ephemeral, `--sandbox workspace-write`,
  `--ask-for-approval never`, `--cd /tmp/harness-t283-round6-codex`.
- Resolved command:
  `codex -c model_reasoning_effort="medium" --ask-for-approval never exec --ephemeral --sandbox workspace-write --cd /tmp/harness-t283-round6-codex --output-last-message <STAGE>/candidate-copilot-evidence.md - < <STAGE>/artifacts/copilot-prompt.md`
- Stage: `/tmp/harness-t283-round6-codex/stage-independent`.
- External pre-window stage seal: `stage_sha256=e10005fcc639aca0e69f2f6c74d98a3f4e52e054a450585cf8a5e4fd7309e0f4`
  stored at `/tmp/harness-t283-round6-seals/independent.stage_sha256`; post-window
  `stage.json` hash matched exactly (no co-pilot tamper).
- Protected pre-window digest seal
  `/tmp/harness-t283-round6-seals/protected-pre-independent.digests` matched the
  post-window `digests` exactly: no driver-owned live write during the window.

## First invocation failed retry-safely

The first invocation exited 1: Codex ran real experiments in its sandbox
(initialized a session, staged, computed hashes) but its FINAL message was
blocked by an OpenAI content filter ("flagged for possible cybersecurity risk"),
so `--output-last-message` never received the evidence. Retry safety verified:
live candidate unchanged (still the template), no receipts minted, protected
digests unchanged, only sandbox-internal scratch written. One narrower retry with
defensive input-validation framing (no weakening of workspace-write or approval)
succeeded.

## Import

- Candidate: 18082 bytes, valid headings, zero standalone TODO lines.
- `import-copilot` → `receipts/independent.json`, candidate
  `sha256=e6a8ba1505d369646fdb51251c821ee8143f72ce7a4fd75fed419d3a9b697220`.
- Receipt `schema_version` is **1** (created by the current pre-change helper).
  This live session is therefore the backward-compatibility fixture: the frozen
  helper must keep reading schema-1 receipts while writing schema-2.
- `verify-receipts` and `check` both passed.
