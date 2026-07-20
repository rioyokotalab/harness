# Validation

## Checks

On the live target after the frozen edits: the canonical
`quick_validate.py shared/skills/codex-claude-cowork` printed `Skill is valid!`;
the revised `tests/test-codex-claude-cowork-skill.sh` passed (including the new
hard-link, digest-determinism, external-manifest tamper-detection,
`copilot-evidence.md` exclusion, predecessor-provenance, and doc-string probes);
`tests/test-claude-takeover.sh`, `tests/test-source-contract.sh`, and
`tests/test-public-repo-audit.sh` passed; and `git diff --check` was clean.

The first full `tests/test-phase1.sh` run on the pre-commit tree passed every
focused suite — including the revised cowork suite — except
`test-tmux-config.sh`, which failed only because `harness tmux-config` requires a
clean committed checkout (`git status --porcelain --untracked-files=normal` must
be empty) and the reviewed round-2 changes were still uncommitted. That is an
intentional prerequisite, not a product-behavior failure.

## Outcome

The individual acceptance gates pass and no safety boundary was weakened. The
umbrella `tests/test-phase1.sh` gate is confirmed from the clean checkpoint
commit that contains only the reviewed round-2 files; that clean rerun result is
recorded in the final evidence commit before the session is advanced to
`complete`. The co-pilot's content-filter refusal and 10-minute timeout were
handled as evidence, with no state change on the timeout and a clean partial
write on the refusal.

## Residual risks

Authorship still cannot be mechanically proven; the digest seal makes unexpected
changes to protected entries *detectable* only when the manifest is held outside
`SESSION_DIR`, and the validator cannot detect a same-user overwrite on its own —
the protocol and `SKILL.md` now state this and require the out-of-session
seal-and-verify. Read-only mode is documented as an advisory tripwire, not a
guarantee. The four round sandboxes and throwaway probe trees are retained for
later guarded cleanup.
