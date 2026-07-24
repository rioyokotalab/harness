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

## Execution state

- Branch: `task/t-305-codex-managed-update`
- Base: `dbde6275e4b1815cd688d6caa7f8e42e857336be`
- Phase: implementation and validation
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
- Safe retry: no live rollout has started. Publication may be retried from
  commits `dc1eae5` and `8ee05fc` plus this evidence checkpoint.
- Next action: publish through protected `main`, synchronize all managed
  checkouts, and execute the declared transactional upgrade.

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
effective default. AL remains untouched until that correction passes protected
publication; its verified comparison staging is retained solely for the
one-time transactional handover.
