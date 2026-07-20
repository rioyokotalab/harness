# Co-pilot task: finish your own review notes (round 2)

You are **Codex**, the co-pilot. In an earlier step you recorded your verified
findings in your owned evidence file
`/home/rioyokota/harness/docs/audits/t283-cowork-round2/copilot-evidence.md`.
Its first two sections ("Sandbox and baseline", "Commands and results") are
complete; the last two ("Critique" and "Proposed plan changes") still contain a
`TODO` placeholder because the previous run ended early.

This is a straightforward data-integrity and protocol-robustness engineering
review. Using **only** the findings you already wrote in that file (do not open
`driver-evidence.md`; keep your pass independent), replace the two remaining
`TODO` placeholders:

- **Critique**: 2–5 sentences naming the single strongest weakness your
  experiments demonstrated in the `codex-claude-cowork` v2 exchange protocol,
  and why it matters for reliable collaboration hand-offs.
- **Proposed plan changes**: a short numbered list of exact, minimal edits,
  each confined to `shared/skills/codex-claude-cowork/SKILL.md`,
  `references/protocol.md`, `scripts/cowork-session`, or the focused test
  `tests/test-codex-claude-cowork-skill.sh`. Cover the link-count check, the
  seal-and-verify integrity step around granting the other client write access,
  and the takeover-provenance distinction you already documented.

Write only into `copilot-evidence.md`. Do not modify the live target, any other
exchange file, Git refs, settings, credentials, or network state. Leave no
standalone `TODO` line in the file. Your final message should be a one-line
confirmation.
