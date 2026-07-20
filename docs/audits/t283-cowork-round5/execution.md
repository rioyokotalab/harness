# Driver execution

## Steps and results

1. Bumped newly initialized session state to schema 2 while retaining strict
   schema-1 loading. Schema 2 records `exchange_mode`; default `staged` creates
   a real closed `receipts/`, while explicit `direct` forbids stages/receipts.
   The focused legacy fixture completes as schema 1 and initializes a schema-2
   successor with its predecessor provenance intact.
2. Extended stage schema to bind `destination_before_sha256` and print the exact
   path-free `stage.json` SHA-256 for the driver's external pre-window seal.
   Import rejects destination drift before mutation. Schema-2 receipt order is
   enforced at both stage and import.
3. Added path-free independent/reciprocal receipts binding roles, phase,
   projected input hashes, full raw-state hash, exact stage-manifest hash,
   candidate hash, destination-before hash, and import time. A fsynced temporary
   plus atomic same-filesystem hard link creates a complete no-overwrite final;
   ordinary failures remove only this invocation's receipt and restore exact
   evidence.
4. Added closed receipt validation, chain/current-evidence verification,
   `verify-receipts`, phase gates, and receipt enumeration in `digests`. Staged
   schema-2 ready phases require both receipts; direct and schema-1 sessions do
   not.
5. Updated `SKILL.md` and `references/protocol.md` for schema compatibility,
   explicit direct fallback, driver evidence freeze before client invocation,
   external live/stage seals, receipt verification, retry refusal, and the exact
   ordinary-error versus crash-atomicity boundary.
6. Expanded the focused test with legacy/new takeover, staged/direct separation,
   ready gates, manifest/destination binding, two-receipt chain, replay,
   candidate/receipt/destination drift, path absence, digest protection,
   permission failure rollback, retry, receipt hard links, and detectable crash
   residue. Existing staged tests now distinguish the newly added receipt digest
   from changes to pre-existing protected entries.

## Deviations

The independent Claude window was not cleanly sealed because the driver wrote
`driver-evidence.md` while the process ran. This known driver action changed the
only mismatched protected line; the staged inputs and other protected lines
were unchanged, but no co-pilot attribution claim is made from that noisy
comparison. A new import-only seal compared clean. Driver evidence was frozen
before the reciprocal window, whose pre/post protected manifests matched
exactly. Claude correctly noted it could not verify unstaged seal files; future
reciprocal prompts must include the bounded manifests themselves.

The live round-5 session is schema 1 because it was initialized by the pre-
change helper and therefore does not retroactively acquire receipts. All new
schema-2 behaviors were exercised in disposable sessions. External stage-seal
comparison is documented and its exact hash is printed, but the importer does
not yet require a separate driver-held seal file; that remains the strongest
residual for the next adversarial round.
