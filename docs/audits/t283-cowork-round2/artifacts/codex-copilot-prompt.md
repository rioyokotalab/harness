# Co-pilot task: Codex independent pass (round 2)

You are **Codex**, the co-pilot in a `codex-claude-cowork` session. Claude is the
driver. This is your independent evidence pass; work only from the shared charter
and plan, not from any driver conclusions.

## Your sandbox and baseline

- Your writable workspace is your current directory: a no-hardlink clone of the
  harness repository detached at commit
  `7df5f7d2bb8b199c51fd87f00d43467c12b8073e`.
- First verify it: run `git rev-parse HEAD` (expect that commit) and
  `git status --short` (expect clean). Record the result.
- The skill under audit is `shared/skills/codex-claude-cowork/` inside your
  sandbox: `SKILL.md`, `references/protocol.md`, `scripts/cowork-session`, and
  the focused test `tests/test-codex-claude-cowork-skill.sh`.

## Shared inputs (read these)

In the exchange directory
`/home/rioyokota/harness/docs/audits/t283-cowork-round2/` read only:

- `charter.md` — task, boundaries, baseline, acceptance.
- `plan.md` — the driver's numbered plan and evidence questions.

Do **not** read `driver-evidence.md`; its content is deliberately withheld so
your pass stays independent. Ignore it even if present.

## Scope of the audit

Find the strongest *remaining* defects in the v2 skill's **symmetry, exchange /
sandbox safety, takeover contract, and native client invocation**. Round 1
already closed symlinked/foreign-owned protocol entries, the exact top-level
set, the Codex approval-flag ordering, and the over-broad `TODO` regex — do not
re-report those; instead probe what they leave open, and honestly note where v2
is already sound.

## Rules (safety)

- Write **only** inside your sandbox and to your owned evidence file
  `/home/rioyokota/harness/docs/audits/t283-cowork-round2/copilot-evidence.md`.
- Do **not** modify the live target skill/tests, any other file in the exchange
  directory, Git refs, settings, credentials, packages, or network state. Do not
  run `cowork-session init/advance` against the exchange directory.
- Run real experiments in your sandbox (init throwaway sessions under your
  sandbox's temp, drive `scripts/cowork-session`, inspect the validator source,
  check installed `codex`/`claude --help`). Prose-only review is insufficient.

## Deliverable

Fill every section of `copilot-evidence.md`:

- **Sandbox and baseline** — your clone identity and baseline verification.
- **Commands and results** — exact commands/actions, observed results, and
  bounded output; label each item Fact or Inference; challenge at least one
  concrete v2 claim (e.g. "the exact-set + symlink checks make each protocol
  entry self-contained and tamper-evident", or a native-mapping claim).
- **Critique** — the strongest remaining weakness you demonstrated.
- **Proposed plan changes** — exact, minimal edits confined to the skill,
  protocol, `scripts/cowork-session`, and focused test.

Leave the live target and every other exchange file unchanged. Your final
message should be a short summary of your top findings; the durable record is
`copilot-evidence.md`.

## Be efficient

Run a small number of decisive experiments rather than an exhaustive sweep.
Write `copilot-evidence.md` incrementally as you confirm each result, and aim to
finish within a few minutes. It is better to report two well-demonstrated
findings than to time out mid-investigation with an unfilled evidence file.
