# Planning and interview

1. Read repository instructions, the ledger, and fleet, storage,
   shell, backup, and recovery documentation.
2. Fetch and reconcile before changes. Require a clean exact source revision;
   preserve unrelated work and never force-push.
3. Run `scripts/onboard-preflight validate HOST`; stop on malformed, reserved,
   service, proxy, existing, or colliding identifiers.
4. Create or resume one stable task with source commit, scope, exclusions,
   facts, decisions, gates, rollback, acceptance, and exact next action.

Run `scripts/onboard-preflight inventory HOST`. It makes one read-only
BatchMode SSH connection, sends the self-contained inventory helper over
standard input, uses a private short-lived capture, and validates schema
and logical identity. Do not substitute shell startup, environment or home
traversal, credential inspection, another alias, or a neighboring probe.

Reconcile inventory with existing site patterns, separate facts from
hypotheses, and plan in order: declarations and fixture; exact-revision
bootstrap; control-plane, shell, Vim, and approved SSH fragments; approved
hidden-state migration; primary snapshot/check/restore; independent encrypted
generation/restore; then idempotence, interaction, non-interaction, and
recovery validation.

Ask exactly one owner question at a time only for safely undiscoverable roots,
hidden-state policy, replica route, or package authority. Recommend a default
and checkpoint each answer. Never request a secret. For Restic, the owner
creates and externally retains one unique mode-0600 password file; validate
only metadata and pass only its path.

Do not create scheduler jobs, cron entries, or schedule declarations.
Scheduling requires stable manual snapshot/check/restore and independent
restore evidence plus separate owner authority.

When decisions are frozen, record `ready-for-go`, summarize execution and
safety gates, and wait for explicit `go`. Do not mutate before it.
