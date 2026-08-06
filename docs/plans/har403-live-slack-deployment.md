# Har-403 live Slack deployment

## Verified starting state

- The Har-402 broker is a protected, provider-free policy core and MCP tool
  schema pinned by all three repository declarations.
- No `/run/harness-slack-broker` runtime, broker service identity, broker unit,
  socket, or installed broker release exists on Local.
- Students has a dedicated encrypted Socket Mode application and root-owned
  rotation path. Its production Slack and student-agent units are disabled.
  This credential domain remains separate and inactive until its own acceptance
  proves structured-context integration cannot contact students unexpectedly.
- Personal's accepted Slack path is the hosted Claude connector. Its ledger
  records Claude ready and Codex unavailable, with revocation requiring both
  hosted-connector disconnect and Slack-workspace authorization removal.
- Swallow's prior access was a temporary connector-backed read worker. No
  persistent local credential or service is declared.
- A fresh fleet preflight passed Local, all declared Linux nodes, and three Mac
  route pairs; both Riken routes failed and are separately tracked by Har-409.

No credential contents, Slack source content, private target values, or
connector settings were read during inventory.

## Required deployment shape

1. Build a revision-pinned stdio MCP bridge and independently supervised Unix
   socket profile services from the protected broker core.
2. Run each service as its declared unprivileged identity. Root owns encrypted
   at-rest credentials and profile-local rotation; clients receive no token.
3. Install Personal and Swallow from the frozen credential topology below.
   Install Students as a credential-free structured-context adapter to its
   existing runtime, never as a second raw Slack reader.
4. Validate fake-provider behavior, service restart independence, value-free
   doctor output, exact scopes, client parity, and cross-profile denial.
5. Perform one profile-local bounded live read acceptance that returns only
   status/count evidence. Keep every write tool absent.
6. Re-read the old connector state. Revoke only the uniquely replaced Personal
   hosted connector; preserve Students and treat Swallow's absent temporary
   worker as absence only after authoritative inventory.

## Decision register

### D-001 — Personal and Swallow Slack applications

Status: selected after owner direction and independent Claude review.

Create two new internal Slack applications, one for Personal and one for
Swallow. Never reuse the Students application or one credential across
profiles.

- Personal uses one user token for read-only owner-visible access and one bot
  token for `chat:write` in the same application. The user token has exactly
  `channels:history`, `groups:history`, `files:read`, `canvases:read`, and
  `users:read`. It has no search, direct-message, reaction, channel-management,
  event, Socket Mode, or write scope. The bot token has only `chat:write` and
  is never loaded into the steady read service.
- Swallow uses one bot token with only the channel-history class needed by the
  exact configured target plus `files:read` and `canvases:read`. It has no user
  token, write, search, direct-message, event, or Socket Mode scope. The app is
  invited only to that exact project channel.
- Students keeps its existing dedicated application. The new profile adapter
  receives only bounded structured context from the Sensei runtime and never
  receives or duplicates a Slack credential.

The owner completes Slack's unavoidable application creation and OAuth grants
locally without sending a credential through chat. Manifests are credential
free. Enrollment accepts a credential only through a local hidden prompt into
the encrypted service-manager store; it never enters an argument, environment,
repository, transcript, or ordinary log.

### D-002 — Custody and rotation

Status: selected after independent review.

Each profile has its own unprivileged service identity, Unix socket, lock,
state, audit, encrypted credential set, supervisor, and failure domain. Root is
the decryption-key custodian. The service manager decrypts only the minimum
credential into a private runtime file for the exact process:

- steady Personal read service: current user access token only;
- transient Personal write service: current bot access token only, after the
  frozen transaction gate;
- steady Swallow read service: current bot access token only;
- profile rotator: client secret and current single-use refresh token only;
- Students adapter: no Slack credential.

Rotators run before expected expiry (nominally eight hours into Slack's
twelve-hour lifetime), at boot, and at resume. A rotation performs one exchange,
stages and validates the new set, atomically cuts over one profile, restarts
only that profile, runs a value-free canary, and retains one bounded rollback
generation. A consumed, lost, or ambiguous refresh exchange stops without
retry and emits `renewal-required` or `repair-required`; it never guesses which
generation is valid. Rotation metadata and content-free audit records are kept
for at most 30 days and 16 MiB per profile.

### D-003 — One-shot writes

Status: selected after independent review.

A write is unavailable from every steady service. A root-launched transient
transaction receives the bot token only after exact target and payload bytes
are frozen, owner authority is current, and a fresh provider readback proves
both target identity and bot membership. It consumes the grant before one
native attempt, never retries an acknowledged or ambiguous attempt, and treats
all provider-returned content as untrusted context incapable of authorizing a
follow-on action.

## Revocation invariant

Authorization to revoke does not prove that replacement succeeded. Revocation
is executable only after authoritative replacement readback, exact scope and
identity validation, Codex/Claude parity, rollback health, and a fresh mapping
showing the old connector is unique and unused. An absent, shared, failed, or
ambiguous readback stops without retry.
