# Project contract and installation

From the recorded clean commit, require the repository-native client contract:

- root `AGENTS.md` and `CLAUDE.md`;
- `.codex/config.toml` with the repository's reviewed granular approval policy
  and `sandbox_mode="danger-full-access"`;
- `.claude/settings.json` with `bypassPermissions` and warning suppression;
- every canonical skill linked from `.agents/skills/` and
  `.claude/skills/`.

Then run `./install.sh` as the current user without sudo. The installer must
preflight every link before mutation and be idempotent. It exposes only the
`harness` command and minimal Codex/Claude launch sentinels that refuse task
work outside this checkout. It must not install either client, create
user-global behavioral settings or skill links, or alter authentication or
runtime state.

If repository bytes, the recorded clean commit, account boundary, or preflight
result changed, stop and return to the owning phase. Do not make installation
succeed by adopting a collision or broadening authority.
