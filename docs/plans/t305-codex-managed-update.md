# T-305 managed Codex update

Date: 2026-07-24 JST

## Objective and accepted scope

Eliminate AB's repeated Codex update prompt without weakening the harness's
transactional agent ownership:

1. upgrade the managed Linux Codex release from 0.144.4 to 0.145.0;
2. disable Codex's project startup update check;
3. remove AB's redundant npm-global Codex only after managed 0.145.0 passes;
4. document the harness-managed Linux upgrade route; and
5. validate every managed Linux node and preserve unrelated client state.

The owner accepted this scope after the read-only diagnosis. Authentication,
sessions, histories, credentials, running clients, Macs, and unrelated global
npm packages remain outside mutation scope.

## Diagnosis

AB's interactive tmux shell was not causal. Both `codex` and
`harness-codex` resolved through the stable harness link to the relocated
0.144.4 tree. Codex's own version state advertised 0.145.0. Accepting the
native updater installed `@openai/codex@0.145.0` under Node's global prefix,
but did not create the harness's managed 0.145.0 tree or advance its stable
link. Every restart therefore launched 0.144.4 and offered the same update.

All seven remote managed Linux nodes resolved to harness-managed 0.144.4.
Only AB had the redundant npm-global 0.145.0 installation.

## Release evidence

The npm registry metadata and exact bytes were obtained from OpenAI's official
registry namespace over HTTPS. Each downloaded artifact's SHA-512 matched the
registry `dist.integrity`; its package name, version, OS/CPU declaration, and
expected vendor layout were inspected before adopting its SHA-256.

| Artifact | SHA-256 |
| --- | --- |
| `https://registry.npmjs.org/@openai/codex/-/codex-0.145.0.tgz` | `416399796cac371d1a033b17f34b08ba9b25c8f298a5b9d00e10f72c3b128c8d` |
| `https://registry.npmjs.org/@openai/codex/-/codex-0.145.0-linux-x64.tgz` | `11239480f8e3efd1430f23bbe91c1a397856b8bbe6185ccbaee2382d25e03df2` |
| `https://registry.npmjs.org/@openai/codex/-/codex-0.145.0-linux-arm64.tgz` | `b78c57e172b2f18e5969ae26183253cd3cdd9abb3b424a8f7334f4b5530c2b27` |

The current Codex manual documents `check_for_update_on_startup` as a Boolean
configuration key whose default is true, and documents `codex update` as the
native self-update command when the installed release supports it. The
project setting is therefore the narrow surface for suppressing the
inapplicable offer in this managed checkout.

## Validation history

- Initial branch: `task/t-305-codex-managed-update`
- Base: `dbde6275e4b1815cd688d6caa7f8e42e857336be`
- Focused agent-upgrade, agent-config, Claude-takeover, external-onboarding,
  and source-contract suites pass.
- The first full suite passed 66 shards. Only tmux-config and terminfo refused
  because their real-checkout integration gates require a clean committed task
  branch. This is an expected pre-publication gate, not a behavior failure.
- After the clean checkpoint, all 68 focused shards passed. A later integration
  fixture installed the correct 0.145.0 tree but still tried to mutate its
  former hardcoded 0.144.4 path. The fixture reference is corrected; no
  production behavior failed.
- The corrected clean checkpoint passed all 68 focused shards, guarded-delete,
  and every remaining phase-one integration gate.
- PR #288 passed protected `portable-phase1` and squash-merged as `8ea86f0`.

## Rollout discovery

PR #288 passed protected CI and merged as
`8ea86f05b4685c39a0be401d4fe3d5281ed43dc0`. All eleven remote checkouts
advanced cleanly to that revision with no transfer residue. AB, AB2, RI, RC,
T4, and ABQ completed managed 0.145.0 replacement transactions and now report
an idempotent managed `KEEP`. AB's redundant npm-global launcher and nested
native package were removed by npm after a dry run proved those were its only
targets; unrelated global packages remained identical.

Local already uses the separately managed official standalone 0.145.0 release
and its T-294 NFS wrapper, so its agent plan correctly refused conversion and
Local was retained unchanged.

AL stopped before mutation because its predecessor archive hash differed from
the original transaction evidence. Its 24-entry tree has no links, `.nfs`
residue, extra paths, or content/mode differences from the exact verified
official 0.144.4 arm64 archives. The cause is GNU tar 1.34's site default:
AL uses POSIX format while every other Linux node uses GNU format. POSIX/PAX
archives encode mutable metadata, so the prior tree digest is not stable.

A follow-up change makes both agent tree-digest sites request GNU format
explicitly. The upgrade regression forces `TAR_OPTIONS=--format=posix`, proving
the explicit command-line format remains deterministic even under AL's
effective default. All 68 focused shards, guarded-delete, and every phase-one
integration gate passed on the clean follow-up branch. PR #289 independently
passed protected `portable-phase1` and squash-merged as
`cc0e6d87214fd81d83d27b413dd1430cd80314af`.

## Final rollout

All eleven remote checkouts advanced cleanly to `cc0e6d8` through two guarded
bundle synchronizations. Repeat plans reported exact `KEEP`, aligned
`origin/main`, and no transfer artifacts.

| Host | Managed Codex result | Replacement transaction |
| --- | --- | --- |
| local | retained official standalone 0.145.0 and T-294 wrapper | not applicable |
| ab | managed 0.145.0 `KEEP` | `20260724T021505Z-3972951` |
| ab2 | managed 0.145.0 `KEEP` | `20260724T021647Z-3227048` |
| ri | managed 0.145.0 `KEEP` | `20260724T021701Z-3899735` |
| al | managed 0.145.0 `KEEP` | `20260724T023716Z-143742` |
| rc | managed 0.145.0 `KEEP` | `20260724T021720Z-1794556` |
| t4 | managed 0.145.0 `KEEP` | `20260724T021741Z-3820195` |
| abq | managed 0.145.0 `KEEP` | `20260724T021759Z-251100` |

AL's one-time handover first proved that its old tree and a freshly downloaded
official 0.144.4 arm64 tree had identical relative paths, types, modes, and
contents under a stable GNU archive hash. It then used the same schema-2
prepared/promoted/activated/complete transaction and harness recovery contract
as the normal replacement path. The old tree remains available for exact
rollback. The helper and its mode-0600 private log were exact-unlinked after
independent transaction, tree-hash, stable-link, version, and `KEEP`
validation.

AB's npm uninstall dry run named only `@openai/codex@0.145.0` and its nested
`@openai/codex-linux-x64` package below the declared Node global root. The
trusted npm 11.13.0 removal deleted those two package-owned targets; the
top-level unrelated global package list remained byte-identical, and the
harness-managed launcher continued to report 0.145.0.

Final cleanup removed 24 eligible completed-invocation arg0 directories
through lock-aware quarantine and guarded-delete. Fifteen live directories
(three on Local and three on each Mac) remain; eligible, young, and unexpected
counts are zero. The two official-artifact comparison trees, all temporary
manifests, transfer staging, `run_this.sh`, and private logs are absent.

## Result

T-305 is complete. Starting Codex from `~/harness` no longer offers the native
updater, all project settings carry the reviewed disabled-update policy, and
every remote Linux managed command points at verified 0.145.0. Future Linux
upgrades must update `tools/agents.tsv`, pass protected publication, and use
`harness agent`; do not run `codex update`. Local's standalone update route and
version-scoped NFS wrapper remain separate by design.
