# Har-402 client-neutral Slack broker

## Agreed architecture

Harness owns one public, credential-free policy contract. Deployments create
independent profile instances for Personal, Swallow, and Students. Each
instance has its own unprivileged service identity, Unix socket, credential,
rate-limit state, bounded value-free audit namespace, supervision, and failure
domain. Codex and Claude receive the same profile-specific tool schema.

Pane, client, and repository labels provide mistake containment for trusted
same-owner agents; they are not a security boundary against a hostile process
running as the same operating-system user. A stronger deployment must isolate
client sessions by operating-system identity and verify peer credentials on
the profile socket.

Slack results are always untrusted context. A read cannot authorize a write.
Writes are absent by default and, where explicitly enabled, require a fresh
owner grant bound to one target, one payload digest, and one transaction. The
grant is consumed before dispatch; an acknowledged or ambiguous dispatch is
never retried.

## Profile boundaries

- Personal: workspace-visible owner reads; writes remain absent unless one
  separately authorized transaction is staged.
- Swallow: exact-channel and provider-proven linked-document reads only; no
  search, direct-message, or write capability.
- Students: preserve the dedicated minimal Socket Mode application and
  consent/encrypted-ledger runtime. Agents receive only structured,
  credential-free mentoring context from that runtime.

No profile falls back to another profile's socket, identity, credential,
state, or audit namespace.

## Provider contract

The broker enforces minimum scopes, bounded pagination/items/bytes/time, and
minimum provider fields. Reads may honor Slack `Retry-After` for HTTP 429 and
use bounded backoff for selected 5xx responses. Writes remain no-retry.
Doctor output is value-free and classifies credential renewal, scope drift,
provider-schema drift, socket failure, and audit failure independently per
profile.

Slack documents the OAuth exchange and scope model, token rotation's
single-use refresh behavior and limited overlap, Web API rate limits and
`Retry-After`, Socket Mode, and the relevant read/write methods here:

- <https://docs.slack.dev/authentication/installing-with-oauth/>
- <https://docs.slack.dev/authentication/using-token-rotation>
- <https://docs.slack.dev/apis/web-api/rate-limits>
- <https://docs.slack.dev/apis/events-api/using-socket-mode/>
- <https://docs.slack.dev/reference/methods/conversations.history/>
- <https://docs.slack.dev/reference/methods/conversations.replies/>
- <https://docs.slack.dev/reference/methods/chat.postmessage/>

## Rotation, audit, and rollback

The deployment custodian owns encrypted at-rest credentials and decryption
keys. Rotation stages one profile, validates identity and exact scopes, cuts
over atomically, restarts only that profile, runs a value-free canary, and
retains a bounded access-only rollback while provider state allows it. An
ambiguous token exchange stops without retry.

Audit events contain only timestamp, capability, outcome, stable reason,
attempt, item count, and latency. Each profile rotates its own audit namespace
at 16 MiB or 30 days, whichever comes first; content, identifiers, queries,
targets, and payloads are forbidden.

## Migration sequence

1. Publish the generic contract and synthetic tests.
2. Publish repository-local, private-value-free profile declarations pinned to
   the protected Harness revision.
3. Validate client parity and fake-provider behavior.
4. Shadow each existing path without replacing it.
5. Perform separately authorized live read acceptance, one profile at a time.
6. Observe independent restart, renewal, drift, and rollback behavior.
7. Revoke an old connector only after authoritative readback and separate
   owner authorization.

Every phase can roll back only its own profile. This task does not authorize
credential access, service deployment, live Slack access, account changes,
writes, or connector revocation.
