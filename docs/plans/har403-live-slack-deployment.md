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
3. Install Personal and Swallow only after their exact dedicated application
   strategy is selected. Install Students as a structured-context adapter to
   its existing runtime, never as a second raw Slack reader.
4. Validate fake-provider behavior, service restart independence, value-free
   doctor output, exact scopes, client parity, and cross-profile denial.
5. Perform one profile-local bounded live read acceptance that returns only
   status/count evidence. Keep every write tool absent.
6. Re-read the old connector state. Revoke only the uniquely replaced Personal
   hosted connector; preserve Students and treat Swallow's absent temporary
   worker as absence only after authoritative inventory.

## Decision register

### D-001 — Personal and Swallow Slack applications

Status: open.

Recommended: create two dedicated Slack applications, one per profile, with
separate credentials and only each declaration's minimum read scopes. This
preserves the agreed profile failure and revocation boundaries. The owner must
complete Slack's unavoidable application installation/authorization without
sharing credentials in chat; Harness can prepare and validate manifests and
consume only encrypted credential-file references afterward.

Alternatives that reuse the Students application or one credential across
Personal and Swallow weaken the accepted isolation contract and require an
explicit redesign rather than silent deployment.

## Revocation invariant

Authorization to revoke does not prove that replacement succeeded. Revocation
is executable only after authoritative replacement readback, exact scope and
identity validation, Codex/Claude parity, rollback health, and a fresh mapping
showing the old connector is unique and unused. An absent, shared, failed, or
ambiguous readback stops without retry.
